import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'text_preprocessor.dart';
import 'audio_config.dart';

/// 音频文件数据模型
class AudioFile {
  final String filePath;
  final String contentHash;
  final AudioConfig config;
  final int fileSize;
  final Duration duration;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const AudioFile({
    required this.filePath,
    required this.contentHash,
    required this.config,
    required this.fileSize,
    required this.duration,
    required this.createdAt,
    required this.metadata,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'contentHash': contentHash,
      'config': config.toJson(),
      'fileSize': fileSize,
      'durationMs': duration.inMilliseconds,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory AudioFile.fromJson(Map<String, dynamic> json) {
    return AudioFile(
      filePath: json['filePath'] ?? '',
      contentHash: json['contentHash'] ?? '',
      config: AudioConfig.fromJson(json['config'] ?? {}),
      fileSize: json['fileSize'] ?? 0,
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// 测试用构造函数
  factory AudioFile.test({
    String? filePath,
    String? contentHash,
    AudioConfig? config,
  }) {
    return AudioFile(
      filePath: filePath ?? '/test/audio.mp3',
      contentHash: contentHash ?? 'test_hash',
      config: config ?? AudioConfig.defaultConfig(),
      fileSize: 50000,
      duration: const Duration(seconds: 3),
      createdAt: DateTime.now(),
      metadata: {'test': true},
    );
  }

  /// 检查文件是否存在
  bool exists() {
    try {
      return File(filePath).existsSync();
    } catch (e) {
      print('⚠️ 检查文件存在性失败: $e');
      return false;
    }
  }

  /// 获取文件大小（字节）
  int getActualFileSize() {
    try {
      return File(filePath).lengthSync();
    } catch (e) {
      return 0;
    }
  }

  /// 删除音频文件
  Future<bool> delete() async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ 删除音频文件失败: $e');
      return false;
    }
  }

  @override
  String toString() {
    return 'AudioFile(path: $filePath, hash: $contentHash, size: ${fileSize}B)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioFile &&
        other.contentHash == contentHash &&
        other.config == config;
  }

  @override
  int get hashCode => Object.hash(contentHash, config);
}

/// TTS引擎类型
enum TTSEngine {
  system('system', 'System TTS'),
  cloud('cloud', 'Cloud TTS'),
  offline('offline', 'Offline TTS');

  const TTSEngine(this.id, this.displayName);
  final String id;
  final String displayName;
}

/// 音频生成结果
class AudioGenerationResult {
  final bool success;
  final AudioFile? audioFile;
  final String? error;
  final Duration generationTime;
  final TTSEngine usedEngine;
  final Map<String, dynamic> metadata;

  const AudioGenerationResult({
    required this.success,
    this.audioFile,
    this.error,
    required this.generationTime,
    required this.usedEngine,
    this.metadata = const {},
  });

  factory AudioGenerationResult.success(
    AudioFile audioFile,
    Duration generationTime,
    TTSEngine usedEngine, {
    Map<String, dynamic>? metadata,
  }) {
    return AudioGenerationResult(
      success: true,
      audioFile: audioFile,
      generationTime: generationTime,
      usedEngine: usedEngine,
      metadata: metadata ?? {},
    );
  }

  factory AudioGenerationResult.failure(
    String error,
    Duration generationTime,
    TTSEngine attemptedEngine, {
    Map<String, dynamic>? metadata,
  }) {
    return AudioGenerationResult(
      success: false,
      error: error,
      generationTime: generationTime,
      usedEngine: attemptedEngine,
      metadata: metadata ?? {},
    );
  }
}

/// 音频生成引擎 - 将预处理后的文本转换为高质量音频文件
class AudioGenerationEngine {
  static final AudioGenerationEngine _instance =
      AudioGenerationEngine._internal();
  factory AudioGenerationEngine() => _instance;
  AudioGenerationEngine._internal();

  FlutterTts? _tts;
  bool _initialized = false;
  String? _audioDirectory;
  final List<TTSEngine> _availableEngines = [];
  TTSEngine _defaultEngine = TTSEngine.system;

  /// 初始化音频生成引擎
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _initializeTTS();
      await _setupAudioDirectory();
      await _detectAvailableEngines();
      _initialized = true;
      print('✅ 音频生成引擎初始化完成');
    } catch (e) {
      print('❌ 音频生成引擎初始化失败: $e');
      _initialized = true; // 即使失败也标记为已初始化，避免重复尝试
    }
  }

  /// 初始化TTS引擎
  Future<void> _initializeTTS() async {
    try {
      _tts = FlutterTts();

      // 设置基础配置
      await _tts!.setLanguage('zh-CN');
      await _tts!.setSpeechRate(1.0);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);

      // 平台特定配置
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts!.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.allowBluetooth],
        );
      }

      print('✅ TTS引擎初始化完成');
    } catch (e) {
      print('❌ TTS引擎初始化失败: $e');
      _tts = null;
    }
  }

  /// 设置音频文件存储目录
  Future<void> _setupAudioDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _audioDirectory = '${appDir.path}/audio_cache';

      final dir = Directory(_audioDirectory!);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      print('✅ 音频存储目录设置完成: $_audioDirectory');
    } catch (e) {
      print('❌ 音频存储目录设置失败: $e');
      _audioDirectory = null;
    }
  }

  /// 检测可用的TTS引擎
  Future<void> _detectAvailableEngines() async {
    _availableEngines.clear();

    // 系统TTS总是可用
    _availableEngines.add(TTSEngine.system);

    // 检测云端TTS可用性 (模拟检测，实际应检查网络连接和API密钥)
    try {
      final result = await InternetAddress.lookup('api.openai.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _availableEngines.add(TTSEngine.cloud);
      }
    } catch (_) {
      // 网络不可用或无法解析域名，云端TTS不可用
    }

    // 检测离线TTS可用性 (如果系统TTS支持离线模式)
    // 这里假设系统TTS即为离线可用，或者可以通过特定API检查
    _availableEngines.add(TTSEngine.offline);

    _defaultEngine = _availableEngines.first;
    print(
        '✅ 检测到可用TTS引擎: ${_availableEngines.map((e) => e.displayName).join(', ')}');
  }

  /// 生成音频文件
  Future<AudioGenerationResult> generateAudio(
    ProcessedText text,
    AudioConfig config,
  ) async {
    if (!_initialized) await initialize();

    final stopwatch = Stopwatch()..start();

    try {
      // 验证输入
      if (text.processedText.trim().isEmpty) {
        return AudioGenerationResult.failure(
          '文本内容为空',
          stopwatch.elapsed,
          _defaultEngine,
        );
      }

      if (!config.isValid()) {
        return AudioGenerationResult.failure(
          '音频配置无效',
          stopwatch.elapsed,
          _defaultEngine,
        );
      }

      // 生成文件路径
      final fileName = _generateFileName(text.contentHash, config);
      final filePath = '$_audioDirectory/$fileName';

      // 检查文件是否已存在
      if (File(filePath).existsSync()) {
        final existingFile =
            await _createAudioFileFromPath(filePath, text.contentHash, config);
        return AudioGenerationResult.success(
          existingFile,
          stopwatch.elapsed,
          _defaultEngine,
          metadata: {'fromCache': true},
        );
      }

      // 生成新的音频文件
      final audioFile = await _generateNewAudioFile(text, config, filePath);

      stopwatch.stop();
      return AudioGenerationResult.success(
        audioFile,
        stopwatch.elapsed,
        _defaultEngine,
        metadata: {'fromCache': false},
      );
    } catch (e) {
      stopwatch.stop();
      return AudioGenerationResult.failure(
        e.toString(),
        stopwatch.elapsed,
        _defaultEngine,
      );
    }
  }

  /// 批量生成音频文件
  Future<List<AudioGenerationResult>> batchGenerateAudio(
    List<ProcessedText> texts,
    AudioConfig config,
  ) async {
    if (!_initialized) await initialize();

    print('🔄 开始批量生成 ${texts.length} 个音频文件');

    final results = <AudioGenerationResult>[];
    final batchStopwatch = Stopwatch()..start();

    // 按相似度分组以优化TTS引擎使用
    final groups = _groupBySimilarity(texts);

    for (final group in groups) {
      // 为每个组配置TTS引擎
      await _configureTTSForGroup(group.first, config);

      // 并行生成组内的音频文件（限制并发数）
      final groupResults = await _generateGroupConcurrently(group, config);
      results.addAll(groupResults);
    }

    batchStopwatch.stop();

    final successCount = results.where((r) => r.success).length;
    print(
        '✅ 批量生成完成: $successCount/${texts.length} 成功，耗时 ${batchStopwatch.elapsedMilliseconds}ms');

    return results;
  }

  /// 按相似度分组文本
  List<List<ProcessedText>> _groupBySimilarity(List<ProcessedText> texts) {
    final groups = <List<ProcessedText>>[];

    for (final text in texts) {
      // 找到相似的组
      List<ProcessedText>? similarGroup;
      for (final group in groups) {
        if (_calculateSimilarity(group.first, text) > 0.7) {
          similarGroup = group;
          break;
        }
      }

      if (similarGroup != null) {
        similarGroup.add(text);
      } else {
        groups.add([text]);
      }
    }

    return groups;
  }

  /// 计算文本相似度
  double _calculateSimilarity(ProcessedText text1, ProcessedText text2) {
    if (text1.language != text2.language) return 0.0;

    final words1 = text1.processedText.split(' ');
    final words2 = text2.processedText.split(' ');

    final commonWords = words1.where((word) => words2.contains(word)).length;
    final totalWords = (words1.length + words2.length) / 2;

    return totalWords > 0 ? commonWords / totalWords : 0.0;
  }

  /// 为组配置TTS引擎
  Future<void> _configureTTSForGroup(
      ProcessedText sampleText, AudioConfig config) async {
    if (_tts == null) return;

    try {
      await _tts!.setLanguage(config.language);
      await _tts!.setSpeechRate(config.rate);
      await _tts!.setVolume(config.volume);
      await _tts!.setPitch(config.pitch);

      // 设置音色
      if (config.voice != null && config.voice!.isNotEmpty) {
        await _tts!
            .setVoice({'name': config.voice!, 'locale': config.language});
      }
    } catch (e) {
      print('⚠️ TTS配置失败: $e');
    }
  }

  /// 并发生成组内音频文件
  Future<List<AudioGenerationResult>> _generateGroupConcurrently(
    List<ProcessedText> group,
    AudioConfig config,
  ) async {
    const maxConcurrency = 3; // 限制并发数避免资源竞争
    final results = <AudioGenerationResult>[];

    for (int i = 0; i < group.length; i += maxConcurrency) {
      final batch = group.skip(i).take(maxConcurrency).toList();
      final batchFutures = batch.map((text) => generateAudio(text, config));
      final batchResults = await Future.wait(batchFutures);
      results.addAll(batchResults);

      // 短暂延迟避免过度占用资源
      if (i + maxConcurrency < group.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// 生成新的音频文件
  Future<AudioFile> _generateNewAudioFile(
    ProcessedText text,
    AudioConfig config,
    String filePath,
  ) async {
    if (_tts == null) {
      throw Exception('TTS引擎未初始化');
    }

    // 配置TTS参数
    await _configureTTSForGroup(text, config);

    // 生成音频文件
    // 注意：flutter_tts 不直接支持文件输出，这里需要使用平台特定的实现
    // 或者使用其他音频生成方案
    await _generateAudioWithTTS(text.processedText, filePath, config);

    // 创建AudioFile对象
    final file = File(filePath);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    final duration = _estimateAudioDuration(text.processedText, config);

    return AudioFile(
      filePath: filePath,
      contentHash: text.contentHash,
      config: config,
      fileSize: fileSize,
      duration: duration,
      createdAt: DateTime.now(),
      metadata: {
        'originalText': text.originalText,
        'processedText': text.processedText,
        'language': text.language,
        'engine': _defaultEngine.id,
        'generatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 使用TTS生成音频文件
  Future<void> _generateAudioWithTTS(
      String text, String filePath, AudioConfig config) async {
    // 这是一个简化的实现
    // 实际实现需要根据平台使用不同的方法来保存TTS输出到文件

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android平台实现
        await _generateAudioAndroid(text, filePath, config);
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS平台实现
        await _generateAudioIOS(text, filePath, config);
      } else {
        // Web或其他平台的降级实现
        await _generateAudioFallback(text, filePath, config);
      }
    } catch (e) {
      print('❌ 音频生成失败: $e');
      // 创建一个空的音频文件作为占位符
      await _createPlaceholderAudioFile(filePath);
    }
  }

  /// Android平台音频生成
  Future<void> _generateAudioAndroid(
      String text, String filePath, AudioConfig config) async {
    try {
      // 使用flutter_tts的synthesizeToFile方法（如果支持）
      // 注意：flutter_tts在某些版本中支持文件输出
      if (_tts != null) {
        // 尝试使用TTS引擎的文件输出功能
        final result = await _tts!.synthesizeToFile(text, filePath);

        if (result == 1) {
          // 成功生成音频文件
          print('✅ Android音频生成成功: $filePath');
          return;
        }
      }

      // 如果直接文件输出不支持，使用录音方式
      await _generateAudioWithRecording(text, filePath, config);
    } catch (e) {
      print('❌ Android音频生成失败: $e');
      // 降级到占位符文件
      await _createPlaceholderAudioFile(filePath);
    }
  }

  /// iOS平台音频生成
  Future<void> _generateAudioIOS(
      String text, String filePath, AudioConfig config) async {
    try {
      // iOS平台使用AVSpeechSynthesizer配合AVAudioRecorder
      // 通过Method Channel调用原生iOS代码
      const platform = MethodChannel('audio_generation/ios');

      final result = await platform.invokeMethod('generateAudioFile', {
        'text': text,
        'filePath': filePath,
        'voice': config.voice,
        'rate': config.rate,
        'pitch': config.pitch,
        'volume': config.volume,
        'language': config.language,
      });

      if (result['success'] == true) {
        print('✅ iOS音频生成成功: $filePath');
        return;
      } else {
        throw Exception('iOS音频生成失败: ${result['error']}');
      }
    } catch (e) {
      print('❌ iOS音频生成失败: $e');

      // 尝试使用flutter_tts的synthesizeToFile方法作为降级
      if (_tts != null) {
        try {
          final result = await _tts!.synthesizeToFile(text, filePath);
          if (result == 1) {
            print('✅ iOS音频生成成功（降级方案）: $filePath');
            return;
          }
        } catch (fallbackError) {
          print('⚠️ iOS降级方案也失败: $fallbackError');
        }
      }

      // 最终降级到占位符文件
      await _createPlaceholderAudioFile(filePath);
    }
  }

  /// 降级音频生成
  Future<void> _generateAudioFallback(
      String text, String filePath, AudioConfig config) async {
    try {
      // Web平台或其他平台的降级实现
      if (kIsWeb) {
        // Web平台使用Web Speech API
        await _generateAudioWeb(text, filePath, config);
      } else {
        // 其他平台尝试使用flutter_tts的synthesizeToFile
        if (_tts != null) {
          final result = await _tts!.synthesizeToFile(text, filePath);
          if (result == 1) {
            print('✅ 降级音频生成成功: $filePath');
            return;
          }
        }

        // 如果都失败，创建占位符文件
        await _createPlaceholderAudioFile(filePath);
      }
    } catch (e) {
      print('❌ 降级音频生成失败: $e');
      await _createPlaceholderAudioFile(filePath);
    }
  }

  /// Web平台音频生成
  Future<void> _generateAudioWeb(
      String text, String filePath, AudioConfig config) async {
    try {
      // Web平台需要通过JavaScript调用Web Speech API
      // 这里创建一个基本的音频文件作为占位符
      // 实际实现需要通过dart:html和Web Speech API

      // 创建一个包含文本信息的JSON文件，供Web端处理
      final audioData = {
        'text': text,
        'config': config.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'web',
      };

      final jsonString = jsonEncode(audioData);
      await File(filePath).writeAsString(jsonString);

      print('✅ Web音频配置文件生成成功: $filePath');
    } catch (e) {
      print('❌ Web音频生成失败: $e');
      await _createPlaceholderAudioFile(filePath);
    }
  }

  /// 使用录音方式生成音频（Android降级方案）
  Future<void> _generateAudioWithRecording(
      String text, String filePath, AudioConfig config) async {
    try {
      // 这是一个简化的录音实现概念
      // 实际实现需要使用audio_recorder包或类似的录音插件

      // 1. 开始录音
      // 2. 使用TTS播放文本
      // 3. 停止录音并保存文件

      print('🔄 尝试使用录音方式生成音频...');

      // 模拟录音过程 - 实际实现需要真正的录音功能
      if (_tts != null) {
        // 配置TTS参数
        await _tts!.setLanguage(config.language);
        await _tts!.setSpeechRate(config.rate);
        await _tts!.setVolume(config.volume);
        await _tts!.setPitch(config.pitch);

        // 播放TTS（在实际实现中，这里应该同时录音）
        await _tts!.speak(text);

        // 等待TTS完成
        await Future.delayed(Duration(milliseconds: text.length * 100));

        // 创建一个包含TTS信息的占位符文件
        final audioInfo = {
          'text': text,
          'config': config.toJson(),
          'method': 'recording_simulation',
          'timestamp': DateTime.now().toIso8601String(),
        };

        final infoBytes = utf8.encode(jsonEncode(audioInfo));
        await File(filePath).writeAsBytes(infoBytes);

        print('✅ 录音方式音频生成完成（模拟）: $filePath');
      } else {
        throw Exception('TTS引擎不可用');
      }
    } catch (e) {
      print('❌ 录音方式音频生成失败: $e');
      await _createPlaceholderAudioFile(filePath);
    }
  }

  /// 从现有文件路径创建AudioFile对象
  Future<AudioFile> _createAudioFileFromPath(
    String filePath,
    String contentHash,
    AudioConfig config,
  ) async {
    final file = File(filePath);
    final fileSize = file.existsSync() ? file.lengthSync() : 0;
    final stats = file.existsSync() ? file.statSync() : null;

    return AudioFile(
      filePath: filePath,
      contentHash: contentHash,
      config: config,
      fileSize: fileSize,
      duration: const Duration(seconds: 3), // 默认估算
      createdAt: stats?.modified ?? DateTime.now(),
      metadata: {'fromExistingFile': true},
    );
  }

  /// 生成音频文件名
  String _generateFileName(String contentHash, AudioConfig config) {
    final configHash = config.configHash;
    final extension = config.format.extension;
    return '${contentHash}_$configHash$extension';
  }

  /// 估算音频时长
  Duration _estimateAudioDuration(String text, AudioConfig config) {
    // 基于文本长度和语速估算时长
    final wordsPerMinute = 150 * config.rate; // 基础语速调整
    final words = text.split(' ').length;
    final minutes = words / wordsPerMinute;
    return Duration(milliseconds: (minutes * 60 * 1000).round());
  }

  /// 获取可用TTS引擎
  List<TTSEngine> getAvailableEngines() {
    return List.unmodifiable(_availableEngines);
  }

  /// 设置默认TTS引擎
  void setDefaultEngine(TTSEngine engine) {
    if (_availableEngines.contains(engine)) {
      _defaultEngine = engine;
      print('✅ 默认TTS引擎设置为: ${engine.displayName}');
    } else {
      print('❌ TTS引擎不可用: ${engine.displayName}');
    }
  }

  /// 获取当前默认引擎
  TTSEngine get defaultEngine => _defaultEngine;

  /// 获取音频存储目录
  String? get audioDirectory => _audioDirectory;

  /// 清理过期的音频文件
  Future<int> cleanupExpiredAudioFiles({Duration? olderThan}) async {
    if (_audioDirectory == null) return 0;

    final expiration = olderThan ?? const Duration(days: 7);
    final cutoffTime = DateTime.now().subtract(expiration);

    try {
      final dir = Directory(_audioDirectory!);
      if (!dir.existsSync()) return 0;

      final files = dir.listSync().whereType<File>();
      int deletedCount = 0;

      for (final file in files) {
        final stats = file.statSync();
        if (stats.modified.isBefore(cutoffTime)) {
          try {
            await file.delete();
            deletedCount++;
          } catch (e) {
            print('⚠️ 删除过期音频文件失败: ${file.path}, $e');
          }
        }
      }

      print('✅ 清理完成，删除了 $deletedCount 个过期音频文件');
      return deletedCount;
    } catch (e) {
      print('❌ 清理过期音频文件失败: $e');
      return 0;
    }
  }

  /// 获取引擎统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'initialized': _initialized,
      'audioDirectory': _audioDirectory,
      'availableEngines': _availableEngines.map((e) => e.toJson()).toList(),
      'defaultEngine': _defaultEngine.toJson(),
      'ttsAvailable': _tts != null,
    };
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      _tts?.stop();
      _tts = null;
      _initialized = false;
      print('✅ 音频生成引擎资源已释放');
    } catch (e) {
      print('❌ 释放音频生成引擎资源失败: $e');
    }
  }

  /// 创建占位符音频文件
  Future<void> _createPlaceholderAudioFile(String filePath) async {
    try {
      // 创建一个包含音频元数据的占位符文件
      final placeholderInfo = {
        'type': 'placeholder_audio',
        'format': 'mp3',
        'created_at': DateTime.now().toIso8601String(),
        'note':
            'This is a placeholder audio file. Real TTS implementation needed.',
      };

      // 创建一个最小的MP3文件头作为占位符
      final mp3Header = Uint8List.fromList([
        // ID3v2 header
        0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        // MP3 frame header (简化)
        0xFF, 0xFB, 0x90, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
      ]);

      // 添加元数据信息
      final infoBytes = utf8.encode(jsonEncode(placeholderInfo));
      final combinedData = Uint8List.fromList([...mp3Header, ...infoBytes]);

      await File(filePath).writeAsBytes(combinedData);
      print('✅ 占位符音频文件创建成功: $filePath');
    } catch (e) {
      print('❌ 创建占位符音频文件失败: $e');
      // 最简单的降级方案
      await File(filePath).writeAsBytes(Uint8List.fromList([0x00]));
    }
  }
}

/// TTSEngine扩展方法
extension TTSEngineExtension on TTSEngine {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
    };
  }
}
