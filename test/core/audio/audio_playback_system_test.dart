import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math';
import '../../../lib/core/audio/audio_playback_system.dart';
import '../../../lib/core/audio/audio_generation_engine.dart';
import '../../../lib/core/audio/audio_config.dart';

void main() {
  group('AudioPlaybackSystem Tests', () {
    late AudioPlaybackSystem playbackSystem;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      _setupMockMethodChannels();
    });

    setUp(() async {
      // 重置单例状态
      AudioPlaybackSystem.resetForTesting();
      playbackSystem = AudioPlaybackSystem();
      await playbackSystem.initialize();
    });

    tearDown(() async {
      await playbackSystem.dispose();
    });

    group('Unit Tests - Basic Functionality', () {
      test('should initialize successfully', () async {
        final newSystem = AudioPlaybackSystem();
        await newSystem.initialize();
        
        final systemInfo = newSystem.getSystemInfo();
        expect(systemInfo, isNotNull);
        expect(systemInfo['initialized'], isTrue);
        
        await newSystem.dispose();
      });

      test('should register and select adapters', () async {
        final mockAdapter = MockAudioAdapter();
        playbackSystem.registerAdapter(mockAdapter);
        
        final systemInfo = playbackSystem.getSystemInfo();
        expect(systemInfo['availableAdapters'], contains('mock'));
      });

      test('should handle playback configuration', () async {
        final config = PlaybackConfig.defaultConfig();
        expect(config.volume, equals(1.0));
        expect(config.useNotificationSound, isTrue);
        
        final backgroundConfig = PlaybackConfig.background();
        expect(backgroundConfig.forceBackground, isTrue);
        
        final notificationConfig = PlaybackConfig.notification();
        expect(notificationConfig.useNotificationSound, isTrue);
      });

      test('should handle file not found', () async {
        // 添加模拟适配器以便测试文件检查逻辑
        final mockAdapter = MockAudioAdapter();
        playbackSystem.registerAdapter(mockAdapter);
        
        // 创建一个不存在的文件路径，不实际创建文件
        final audioFile = AudioFile(
          filePath: '/definitely/non/existent/path/test.mp3',
          contentHash: 'non_existent_hash',
          config: AudioConfig.defaultConfig(),
          fileSize: 50000,
          duration: const Duration(seconds: 3),
          createdAt: DateTime.now(),
          metadata: {'test': true},
        );
        
        final result = await playbackSystem.playAudio(audioFile);
        expect(result, equals(PlaybackResult.fileNotFound));
      });

      test('should handle no adapter available', () async {
        // 创建没有适配器的播放系统
        AudioPlaybackSystem.resetForTesting();
        final emptySystem = AudioPlaybackSystem();
        await emptySystem.initialize();
        
        final audioFile = _createTestAudioFile();
        final result = await emptySystem.playAudio(audioFile);
        expect(result, equals(PlaybackResult.notSupported));
        
        await emptySystem.dispose();
      });

      test('should get system information', () async {
        final systemInfo = playbackSystem.getSystemInfo();
        
        expect(systemInfo, containsPair('initialized', isA<bool>()));
        expect(systemInfo, containsPair('availableAdapters', isA<List>()));
        expect(systemInfo, containsPair('platform', isA<String>()));
      });
    });

    group('Property Tests - Feature: dynamic-audio-reminder-system', () {
      /// Property 8: 跨平台播放兼容性
      /// 对于任何目标平台（Android、iOS、Web），音频播放系统应该能够使用平台原生方法成功播放音频文件
      test('Property 8: Cross-platform playback compatibility', () async {
        final random = Random(42);
        
        // 创建模拟适配器用于测试
        final mockAdapter = MockAudioAdapter();
        playbackSystem.registerAdapter(mockAdapter);
        
        // 测试不同的音频文件和配置组合
        for (int i = 0; i < 20; i++) {
          final audioFile = _createRandomTestAudioFile(random, seed: i);
          final config = _createRandomPlaybackConfig(random);
          
          // 尝试播放音频
          final result = await playbackSystem.playAudio(audioFile, config: config);
          
          // 验证播放结果
          expect(result, isIn([
            PlaybackResult.success,
            PlaybackResult.failed,
            PlaybackResult.notSupported,
            PlaybackResult.fileNotFound,
            PlaybackResult.permissionDenied,
          ]), reason: 'Should return valid PlaybackResult');
          
          // 如果适配器支持该策略，应该能够播放
          if (mockAdapter.supportedStrategies.any((strategy) => 
              config.strategies.contains(strategy))) {
            // Mock适配器应该返回成功
            expect(result, equals(PlaybackResult.success),
              reason: 'Should succeed when adapter supports the strategy');
          }
        }
        
        print('✅ 跨平台播放兼容性测试完成');
      }, timeout: const Timeout(Duration(minutes: 1)));

      /// Property 9: 降级播放策略
      /// 对于任何播放请求，如果首选策略失败，系统应该自动尝试备选策略，
      /// 直到找到可用的播放方法或所有策略都失败
      test('Property 9: Fallback playback strategy', () async {
        final random = Random(123);
        
        // 创建支持部分策略的模拟适配器
        final partialAdapter = PartialMockAudioAdapter([
          PlaybackStrategy.backgroundAudio,
          PlaybackStrategy.systemTTS,
        ]);
        playbackSystem.registerAdapter(partialAdapter);
        
        for (int i = 0; i < 15; i++) {
          final audioFile = _createRandomTestAudioFile(random, seed: i + 100);
          
          // 创建包含不支持策略的配置
          final config = PlaybackConfig(
            strategies: [
              PlaybackStrategy.customNotificationSound, // 不支持
              PlaybackStrategy.mediaSessionAudio,       // 不支持
              PlaybackStrategy.backgroundAudio,         // 支持
              PlaybackStrategy.systemTTS,              // 支持
            ],
            maxRetryAttempts: 3,
            retryDelay: const Duration(seconds: 1),
            enableFallback: true,
          );
          
          final result = await playbackSystem.playAudio(audioFile, config: config);
          
          // 应该成功，因为有支持的备选策略
          expect(result, equals(PlaybackResult.success),
            reason: 'Should succeed using fallback strategy');
          
          // 验证使用了支持的策略
          final status = playbackSystem.currentStatus;
          expect(status?.strategy, isIn([
            PlaybackStrategy.backgroundAudio,
            PlaybackStrategy.systemTTS,
          ]), reason: 'Should use supported fallback strategy');
        }
        
        // 测试所有策略都不支持的情况
        final unsupportedConfig = PlaybackConfig(
          strategies: [
            PlaybackStrategy.customNotificationSound,
            PlaybackStrategy.mediaSessionAudio,
            PlaybackStrategy.webAudioAPI,
          ],
          maxRetryAttempts: 3,
          retryDelay: const Duration(seconds: 1),
          enableFallback: true,
        );
        
        final audioFile = _createTestAudioFile();
        final result = await playbackSystem.playAudio(audioFile, config: unsupportedConfig);
        
        expect(result, equals(PlaybackResult.failed),
          reason: 'Should fail when no strategies are supported');
        
        print('✅ 降级播放策略测试完成');
      }, timeout: const Timeout(Duration(minutes: 1)));

      /// Property 13: 播放状态监控
      /// 对于任何音频播放操作，系统应该正确跟踪播放状态并适当处理播放错误
      test('Property 13: Playback status monitoring', () async {
        final mockAdapter = MockAudioAdapter();
        playbackSystem.registerAdapter(mockAdapter);
        
        final audioFile = _createTestAudioFile();
        
        // 监听状态变化
        final statusUpdates = <PlaybackStatus>[];
        final subscription = playbackSystem.statusStream?.listen((status) {
          statusUpdates.add(status);
        });
        
        try {
          // 开始播放
          final result = await playbackSystem.playAudio(audioFile);
          expect(result, equals(PlaybackResult.success));
          
          // 等待状态更新
          await Future.delayed(const Duration(milliseconds: 100));
          
          // 验证状态监控
          expect(statusUpdates, isNotEmpty, reason: 'Should receive status updates');
          
          // 验证最终状态
          final finalStatus = playbackSystem.currentStatus;
          expect(finalStatus, isNotNull, reason: 'Should have current status');
          expect(finalStatus!.state, isIn([
            PlaybackState.playing,
            PlaybackState.completed,
          ]), reason: 'Should have valid playback state');
          
          // 测试错误处理
          mockAdapter.simulateError('Test error');
          await Future.delayed(const Duration(milliseconds: 50));
          
          final errorStatus = playbackSystem.currentStatus;
          expect(errorStatus?.state, equals(PlaybackState.error),
            reason: 'Should handle error state');
          expect(errorStatus?.error, isNotNull,
            reason: 'Should provide error information');
          
        } finally {
          await subscription?.cancel();
        }
        
        print('✅ 播放状态监控测试完成');
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('Adapter Tests', () {
      test('should handle adapter initialization failure', () async {
        final failingAdapter = FailingMockAudioAdapter();
        playbackSystem.registerAdapter(failingAdapter);
        
        final audioFile = _createTestAudioFile();
        final result = await playbackSystem.playAudio(audioFile);
        
        expect(result, equals(PlaybackResult.failed));
      });

      test('should support strategy checking', () async {
        final mockAdapter = MockAudioAdapter();
        playbackSystem.registerAdapter(mockAdapter);
        
        expect(playbackSystem.supportsStrategy(PlaybackStrategy.backgroundAudio), isTrue);
        expect(playbackSystem.supportsStrategy(PlaybackStrategy.webAudioAPI), isFalse);
      });

      test('should handle concurrent playback requests', () async {
        final mockAdapter = MockAudioAdapter();
        playbackSystem.registerAdapter(mockAdapter);
        
        final audioFiles = List.generate(5, (i) => _createTestAudioFile(contentHash: 'hash$i'));
        
        // 并发播放请求
        final futures = audioFiles.map((file) => playbackSystem.playAudio(file));
        final results = await Future.wait(futures);
        
        // 所有请求都应该有结果
        expect(results.length, equals(5));
        expect(results.every((result) => result != null), isTrue);
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle stop playback without active playback', () async {
        // 没有活跃播放时停止播放应该正常工作
        await expectLater(playbackSystem.stopPlayback(), completes);
      });

      test('should handle dispose without initialization', () async {
        AudioPlaybackSystem.resetForTesting();
        final uninitializedSystem = AudioPlaybackSystem();
        
        // 未初始化的系统应该能够正常释放
        await expectLater(uninitializedSystem.dispose(), completes);
      });

      test('should handle cached audio playback', () async {
        final mockAdapter = MockAudioAdapter();
        playbackSystem.registerAdapter(mockAdapter);
        
        // 测试缓存音频播放
        final result = await playbackSystem.playCachedAudio(
          'non_existent_hash',
          AudioConfig.defaultConfig(),
        );
        
        expect(result, equals(PlaybackResult.fileNotFound));
      });
    });
  });
}

/// 创建测试用的音频文件
AudioFile _createTestAudioFile({String? filePath, String? contentHash}) {
  final path = filePath ?? '/tmp/test_audio/test.mp3';
  final hash = contentHash ?? 'test_content_hash';
  
  // 创建实际的测试文件
  try {
    final file = File(path);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    file.writeAsBytesSync([0xFF, 0xFB, 0x90, 0x00]); // 简单的MP3头
  } catch (e) {
    print('Warning: Could not create test file: $e');
  }
  
  return AudioFile(
    filePath: path,
    contentHash: hash,
    config: AudioConfig.defaultConfig(),
    fileSize: 50000,
    duration: const Duration(seconds: 3),
    createdAt: DateTime.now(),
    metadata: {'test': true},
  );
}

/// 创建随机测试音频文件
AudioFile _createRandomTestAudioFile(Random random, {int? seed}) {
  final contentHashes = ['hash1', 'hash2', 'hash3', 'hash4', 'hash5'];
  final hashIndex = seed ?? random.nextInt(contentHashes.length);
  final contentHash = '${contentHashes[hashIndex % contentHashes.length]}_$seed';
  
  final filePath = '/tmp/test_audio/$contentHash.mp3';
  
  // 创建实际的测试文件
  try {
    final file = File(filePath);
    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    file.writeAsBytesSync([0xFF, 0xFB, 0x90, 0x00]); // 简单的MP3头
  } catch (e) {
    print('Warning: Could not create test file: $e');
  }
  
  return AudioFile(
    filePath: filePath,
    contentHash: contentHash,
    config: AudioConfig.defaultConfig(),
    fileSize: 30000 + random.nextInt(70000),
    duration: Duration(seconds: 2 + random.nextInt(4)),
    createdAt: DateTime.now(),
    metadata: {'test': true, 'seed': seed},
  );
}

/// 创建随机播放配置
PlaybackConfig _createRandomPlaybackConfig(Random random) {
  final strategies = [
    PlaybackStrategy.customNotificationSound,
    PlaybackStrategy.mediaSessionAudio,
    PlaybackStrategy.backgroundAudio,
    PlaybackStrategy.systemTTS,
  ];
  
  // 随机选择1-3个策略
  final strategyCount = 1 + random.nextInt(3);
  final selectedStrategies = <PlaybackStrategy>[];
  
  for (int i = 0; i < strategyCount; i++) {
    final strategy = strategies[random.nextInt(strategies.length)];
    if (!selectedStrategies.contains(strategy)) {
      selectedStrategies.add(strategy);
    }
  }
  
  return PlaybackConfig(
    strategies: selectedStrategies,
    maxRetryAttempts: 3,
    retryDelay: const Duration(seconds: 1),
    enableFallback: true,
    volume: 0.5 + random.nextDouble() * 0.5,
    forceBackground: random.nextBool(),
    useNotificationSound: random.nextBool(),
  );
}

/// 模拟音频适配器
class MockAudioAdapter extends BaseAudioAdapter {
  @override
  String get platformName => 'mock';

  @override
  bool get isSupported => true;

  @override
  List<PlaybackStrategy> get supportedStrategies => [
    PlaybackStrategy.backgroundAudio,
    PlaybackStrategy.mediaSessionAudio,
    PlaybackStrategy.systemTTS,
  ];

  @override
  Future<PlaybackResult> playAudio(String filePath, {PlaybackConfig? config}) async {
    // 模拟播放过程
    updateStatus(PlaybackStatus(
      state: PlaybackState.loading,
      timestamp: DateTime.now(),
    ));
    
    await Future.delayed(const Duration(milliseconds: 10));
    
    updateStatus(PlaybackStatus(
      state: PlaybackState.playing,
      strategy: PlaybackStrategy.backgroundAudio,
      timestamp: DateTime.now(),
    ));
    
    await Future.delayed(const Duration(milliseconds: 10));
    
    updateStatus(PlaybackStatus(
      state: PlaybackState.completed,
      strategy: PlaybackStrategy.backgroundAudio,
      timestamp: DateTime.now(),
    ));
    
    return PlaybackResult.success;
  }

  @override
  Future<void> stopPlayback() async {
    updateStatus(PlaybackStatus(
      state: PlaybackState.stopped,
      timestamp: DateTime.now(),
    ));
  }

  void simulateError(String error) {
    setError(error);
  }
}

/// 部分支持的模拟适配器
class PartialMockAudioAdapter extends BaseAudioAdapter {
  final List<PlaybackStrategy> _supportedStrategies;

  PartialMockAudioAdapter(this._supportedStrategies);

  @override
  String get platformName => 'partial_mock';

  @override
  bool get isSupported => true;

  @override
  List<PlaybackStrategy> get supportedStrategies => _supportedStrategies;

  @override
  Future<PlaybackResult> playAudio(String filePath, {PlaybackConfig? config}) async {
    config ??= PlaybackConfig.defaultConfig();
    
    // 查找支持的策略
    PlaybackStrategy? supportedStrategy;
    for (final strategy in config.strategies) {
      if (_supportedStrategies.contains(strategy)) {
        supportedStrategy = strategy;
        break;
      }
    }
    
    if (supportedStrategy == null) {
      setError('没有支持的播放策略');
      return PlaybackResult.failed; // 改为返回failed而不是notSupported
    }
    
    // 模拟播放
    setSuccess(supportedStrategy);
    return PlaybackResult.success;
  }

  @override
  Future<void> stopPlayback() async {
    updateStatus(PlaybackStatus(
      state: PlaybackState.stopped,
      timestamp: DateTime.now(),
    ));
  }
}

/// 失败的模拟适配器
class FailingMockAudioAdapter extends BaseAudioAdapter {
  @override
  String get platformName => 'failing_mock';

  @override
  bool get isSupported => true;

  @override
  List<PlaybackStrategy> get supportedStrategies => [PlaybackStrategy.backgroundAudio];

  @override
  Future<PlaybackResult> playAudio(String filePath, {PlaybackConfig? config}) async {
    setError('模拟播放失败');
    return PlaybackResult.failed;
  }

  @override
  Future<void> stopPlayback() async {}
}

/// 设置测试用的Mock Method Channels
void _setupMockMethodChannels() {
  // Mock path_provider
  const MethodChannel('plugins.flutter.io/path_provider').setMockMethodCallHandler((call) async {
    switch (call.method) {
      case 'getApplicationDocumentsDirectory':
        return '/tmp/test_audio_cache';
      default:
        return null;
    }
  });
  
  // Mock audio playback channels
  const MethodChannel('audio_playback/android').setMockMethodCallHandler((call) async {
    return true; // 模拟成功
  });
  
  const MethodChannel('audio_playback/ios').setMockMethodCallHandler((call) async {
    return true; // 模拟成功
  });
}