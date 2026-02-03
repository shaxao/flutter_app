import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'audio_generation_engine.dart';
import 'cache_management_system.dart';
import 'audio_config.dart';
import 'platform/audio_adapter_factory.dart';

/// 播放结果枚举
enum PlaybackResult {
  success,           // 播放成功
  failed,           // 播放失败
  notSupported,     // 平台不支持
  fileNotFound,     // 文件不存在
  permissionDenied, // 权限被拒绝
  interrupted,      // 播放被中断
}

/// 播放状态枚举
enum PlaybackState {
  idle,      // 空闲
  loading,   // 加载中
  playing,   // 播放中
  paused,    // 暂停
  stopped,   // 停止
  completed, // 完成
  error,     // 错误
}

/// 播放状态信息
class PlaybackStatus {
  final PlaybackState state;
  final PlaybackStrategy? strategy;
  final Duration? position;
  final Duration? duration;
  final String? error;
  final DateTime timestamp;

  const PlaybackStatus({
    required this.state,
    this.strategy,
    this.position,
    this.duration,
    this.error,
    required this.timestamp,
  });

  /// 创建错误状态
  factory PlaybackStatus.error(String error) => PlaybackStatus(
    state: PlaybackState.error,
    error: error,
    timestamp: DateTime.now(),
  );

  /// 创建成功状态
  factory PlaybackStatus.success(PlaybackStrategy strategy) => PlaybackStatus(
    state: PlaybackState.completed,
    strategy: strategy,
    timestamp: DateTime.now(),
  );
}

/// 平台音频适配器接口
abstract class AudioAdapter {
  /// 平台名称
  String get platformName;

  /// 是否支持该平台
  bool get isSupported;

  /// 支持的播放策略
  List<PlaybackStrategy> get supportedStrategies;

  /// 播放音频文件
  Future<PlaybackResult> playAudio(
    String filePath, {
    PlaybackConfig? config,
  });

  /// 停止播放
  Future<void> stopPlayback();

  /// 获取播放状态
  PlaybackStatus get currentStatus;

  /// 播放状态流
  Stream<PlaybackStatus> get statusStream;

  /// 释放资源
  Future<void> dispose();
}

/// 跨平台音频播放系统
class AudioPlaybackSystem {
  static AudioPlaybackSystem? _instance;
  factory AudioPlaybackSystem() => _instance ??= AudioPlaybackSystem._internal();
  AudioPlaybackSystem._internal();

  final Map<String, AudioAdapter> _adapters = {};
  AudioAdapter? _currentAdapter;
  bool _initialized = false;

  /// 重置实例（仅用于测试）
  static void resetForTesting() {
    _instance = null;
  }

  /// 初始化播放系统
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 使用工厂创建平台特定的适配器
      final adapter = await AudioAdapterFactory.createAdapter();
      
      if (adapter != null) {
        registerAdapter(adapter);
      }

      // 选择最佳适配器
      _selectBestAdapter();

      _initialized = true;
      print('✅ 音频播放系统初始化完成');
    } catch (e) {
      print('❌ 音频播放系统初始化失败: $e');
      _initialized = true; // 即使失败也标记为已初始化
    }
  }

  /// 注册音频适配器
  void registerAdapter(AudioAdapter adapter) {
    _adapters[adapter.platformName] = adapter;
    print('📱 注册音频适配器: ${adapter.platformName}');
    
    // 重新选择最佳适配器
    _selectBestAdapter();
  }

  /// 选择最佳适配器
  void _selectBestAdapter() {
    // 如果已经有适配器注册，优先选择支持的适配器
    if (_adapters.isNotEmpty) {
      // 首先尝试选择支持的适配器
      _currentAdapter = _adapters.values.where((adapter) => adapter.isSupported).firstOrNull;
      
      if (_currentAdapter != null) {
        print('🎵 选择音频适配器: ${_currentAdapter!.platformName}');
        return;
      }
    }

    // 如果没有注册的适配器，尝试选择平台特定的适配器
    String platformName;
    if (kIsWeb) {
      platformName = 'web';
    } else if (Platform.isAndroid) {
      platformName = 'android';
    } else if (Platform.isIOS) {
      platformName = 'ios';
    } else {
      platformName = 'unknown';
    }

    _currentAdapter = _adapters[platformName];
    
    if (_currentAdapter == null) {
      // 如果没有找到平台特定的适配器，选择第一个可用的
      _currentAdapter = _adapters.values.where((adapter) => adapter.isSupported).firstOrNull;
    }

    if (_currentAdapter != null) {
      print('🎵 选择音频适配器: ${_currentAdapter!.platformName}');
    } else {
      print('⚠️ 没有找到可用的音频适配器');
    }
  }

  /// 播放音频文件
  Future<PlaybackResult> playAudio(
    AudioFile audioFile, {
    PlaybackConfig? config,
  }) async {
    if (!_initialized) await initialize();

    config ??= PlaybackConfig.defaultConfig();

    if (_currentAdapter == null) {
      print('❌ 没有可用的音频适配器');
      return PlaybackResult.notSupported;
    }

    try {
      print('🎵 开始播放音频: ${audioFile.filePath}');
      
      // 检查文件是否存在
      final file = File(audioFile.filePath);
      if (!file.existsSync()) {
        print('❌ 音频文件不存在: ${audioFile.filePath}');
        return PlaybackResult.fileNotFound;
      }

      // 使用当前适配器播放
      final result = await _currentAdapter!.playAudio(
        audioFile.filePath,
        config: config,
      );

      if (result == PlaybackResult.success) {
        print('✅ 音频播放成功');
      } else {
        print('❌ 音频播放失败: $result');
      }

      return result;
    } catch (e) {
      print('❌ 音频播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 播放缓存的音频
  Future<PlaybackResult> playCachedAudio(
    String contentHash,
    AudioConfig audioConfig, {
    PlaybackConfig? playbackConfig,
  }) async {
    if (!_initialized) await initialize();

    try {
      // 从缓存获取音频文件
      final cacheSystem = CacheManagementSystem();
      final cachedFile = await cacheSystem.getCachedAudio(contentHash, audioConfig);

      if (cachedFile == null) {
        print('❌ 缓存中未找到音频文件: $contentHash');
        return PlaybackResult.fileNotFound;
      }

      return await playAudio(cachedFile, config: playbackConfig);
    } catch (e) {
      print('❌ 播放缓存音频异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 停止播放
  Future<void> stopPlayback() async {
    if (_currentAdapter != null) {
      await _currentAdapter!.stopPlayback();
      print('⏹️ 停止音频播放');
    }
  }

  /// 获取当前播放状态
  PlaybackStatus? get currentStatus => _currentAdapter?.currentStatus;

  /// 播放状态流
  Stream<PlaybackStatus>? get statusStream => _currentAdapter?.statusStream;

  /// 获取支持的播放策略
  List<PlaybackStrategy> get supportedStrategies {
    return _currentAdapter?.supportedStrategies ?? [];
  }

  /// 检查是否支持特定策略
  bool supportsStrategy(PlaybackStrategy strategy) {
    return supportedStrategies.contains(strategy);
  }

  /// 获取系统信息
  Map<String, dynamic> getSystemInfo() {
    return {
      'initialized': _initialized,
      'currentAdapter': _currentAdapter?.platformName,
      'availableAdapters': _adapters.keys.toList(),
      'supportedStrategies': supportedStrategies.map((s) => s.toString()).toList(),
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
    };
  }

  /// 释放资源
  Future<void> dispose() async {
    if (_currentAdapter != null) {
      await _currentAdapter!.dispose();
    }
    
    for (final adapter in _adapters.values) {
      await adapter.dispose();
    }
    
    _adapters.clear();
    _currentAdapter = null;
    _initialized = false;
    
    print('✅ 音频播放系统资源已释放');
  }
}

/// 基础音频适配器实现
abstract class BaseAudioAdapter implements AudioAdapter {
  PlaybackStatus _currentStatus = PlaybackStatus(
    state: PlaybackState.idle,
    timestamp: DateTime.now(),
  );

  final StreamController<PlaybackStatus> _statusController = StreamController<PlaybackStatus>.broadcast();

  @override
  PlaybackStatus get currentStatus => _currentStatus;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  /// 更新播放状态
  void updateStatus(PlaybackStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// 创建错误状态
  void setError(String error) {
    updateStatus(PlaybackStatus.error(error));
  }

  /// 创建成功状态
  void setSuccess(PlaybackStrategy strategy) {
    updateStatus(PlaybackStatus.success(strategy));
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }
}