import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/audio/audio_config.dart';
import '../../../lib/core/audio/cache_management_system.dart';

void main() {
  group('AudioConfig', () {
    test('应该创建默认配置', () {
      final config = AudioConfig.defaultConfig();

      expect(config.voice, equals('default'));
      expect(config.rate, equals(1.0));
      expect(config.pitch, equals(1.0));
      expect(config.volume, equals(0.8));
      expect(config.language, equals('zh-CN'));
      expect(config.format, equals(AudioFormat.mp3));
      expect(config.quality, equals(3));
      expect(config.isValid(), isTrue);
    });

    test('应该创建高质量配置', () {
      final config = AudioConfig.highQuality();

      expect(config.voice, equals('premium'));
      expect(config.rate, equals(0.9));
      expect(config.quality, equals(5));
      expect(config.format, equals(AudioFormat.aac));
      expect(config.isValid(), isTrue);
    });

    test('应该创建快速配置', () {
      final config = AudioConfig.fast();

      expect(config.rate, equals(1.2));
      expect(config.quality, equals(1));
      expect(config.isValid(), isTrue);
    });

    test('应该验证配置参数', () {
      // 有效配置
      final validConfig = AudioConfig.defaultConfig();
      expect(validConfig.isValid(), isTrue);

      // 无效语速
      final invalidRate = validConfig.copyWith(rate: 3.0);
      expect(invalidRate.isValid(), isFalse);

      // 无效音调
      final invalidPitch = validConfig.copyWith(pitch: 0.3);
      expect(invalidPitch.isValid(), isFalse);

      // 无效音量
      final invalidVolume = validConfig.copyWith(volume: 1.5);
      expect(invalidVolume.isValid(), isFalse);

      // 无效质量
      final invalidQuality = validConfig.copyWith(quality: 6);
      expect(invalidQuality.isValid(), isFalse);
    });

    test('应该生成一致的配置哈希', () {
      final config1 = AudioConfig.defaultConfig();
      final config2 = AudioConfig.defaultConfig();

      expect(config1.configHash, equals(config2.configHash));
      expect(config1.configHash.length, equals(12));
    });

    test('不同配置应该生成不同哈希', () {
      final config1 = AudioConfig.defaultConfig();
      final config2 = config1.copyWith(rate: 1.5);

      expect(config1.configHash, isNot(equals(config2.configHash)));
    });

    test('应该正确复制并修改配置', () {
      final original = AudioConfig.defaultConfig();
      final modified = original.copyWith(
        rate: 1.5,
        volume: 0.9,
        language: 'en-US',
      );

      expect(modified.rate, equals(1.5));
      expect(modified.volume, equals(0.9));
      expect(modified.language, equals('en-US'));
      // 其他属性应该保持不变
      expect(modified.voice, equals(original.voice));
      expect(modified.pitch, equals(original.pitch));
      expect(modified.format, equals(original.format));
      expect(modified.quality, equals(original.quality));
    });

    test('应该正确序列化和反序列化', () {
      final original = AudioConfig(
        voice: 'test-voice',
        rate: 1.2,
        pitch: 0.9,
        volume: 0.7,
        language: 'en-US',
        format: AudioFormat.aac,
        quality: 4,
      );

      final json = original.toJson();
      final restored = AudioConfig.fromJson(json);

      expect(restored.voice, equals(original.voice));
      expect(restored.rate, equals(original.rate));
      expect(restored.pitch, equals(original.pitch));
      expect(restored.volume, equals(original.volume));
      expect(restored.language, equals(original.language));
      expect(restored.format, equals(original.format));
      expect(restored.quality, equals(original.quality));
      expect(restored.configHash, equals(original.configHash));
    });

    test('应该处理JSON反序列化的默认值', () {
      final config = AudioConfig.fromJson({});

      expect(config.voice, equals('default'));
      expect(config.rate, equals(1.0));
      expect(config.pitch, equals(1.0));
      expect(config.volume, equals(0.8));
      expect(config.language, equals('zh-CN'));
      expect(config.format, equals(AudioFormat.mp3));
      expect(config.quality, equals(3));
    });

    test('相等性比较应该基于配置哈希', () {
      final config1 = AudioConfig.defaultConfig();
      final config2 = AudioConfig.defaultConfig();
      final config3 = config1.copyWith(rate: 1.5);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1.hashCode, isNot(equals(config3.hashCode)));
    });
  });

  group('AudioFormat', () {
    test('应该有正确的属性', () {
      expect(AudioFormat.mp3.name, equals('mp3'));
      expect(AudioFormat.mp3.mimeType, equals('audio/mpeg'));
      expect(AudioFormat.mp3.extension, equals('.mp3'));

      expect(AudioFormat.aac.name, equals('aac'));
      expect(AudioFormat.aac.mimeType, equals('audio/aac'));
      expect(AudioFormat.aac.extension, equals('.aac'));
    });

    test('应该正确判断流式播放支持', () {
      expect(AudioFormat.mp3.supportsStreaming, isTrue);
      expect(AudioFormat.aac.supportsStreaming, isTrue);
      expect(AudioFormat.wav.supportsStreaming, isFalse);
      expect(AudioFormat.caf.supportsStreaming, isFalse);
    });

    test('应该返回合理的文件大小估算', () {
      expect(AudioFormat.mp3.bytesPerSecond, equals(16000));
      expect(AudioFormat.aac.bytesPerSecond, equals(12000));
      expect(AudioFormat.wav.bytesPerSecond, equals(176400));
    });

    test('应该返回平台推荐格式', () {
      final recommended = AudioFormat.getPlatformRecommended();
      expect(recommended, equals(AudioFormat.mp3));
    });
  });

  group('UserPreferences', () {
    test('应该创建默认偏好', () {
      final prefs = UserPreferences.defaultPreferences();

      expect(prefs.preferredVoice, equals('default'));
      expect(prefs.preferredRate, equals(1.0));
      expect(prefs.preferredVolume, equals(0.8));
      expect(prefs.preferredLanguage, equals('zh-CN'));
      expect(prefs.enablePreloading, isTrue);
      expect(prefs.preferredPlaybackMode, equals(PlaybackMode.notification));
      expect(prefs.playbackStrategies.isNotEmpty, isTrue);
      expect(prefs.preferredFormat, equals(AudioFormat.mp3));
      expect(prefs.preferredQuality, equals(3));
    });

    test('应该转换为AudioConfig', () {
      final prefs = UserPreferences.defaultPreferences();
      final audioConfig = prefs.toAudioConfig();

      expect(audioConfig.voice, equals(prefs.preferredVoice));
      expect(audioConfig.rate, equals(prefs.preferredRate));
      expect(audioConfig.volume, equals(prefs.preferredVolume));
      expect(audioConfig.language, equals(prefs.preferredLanguage));
      expect(audioConfig.format, equals(prefs.preferredFormat));
      expect(audioConfig.quality, equals(prefs.preferredQuality));
    });

    test('应该正确复制并修改偏好', () {
      final original = UserPreferences.defaultPreferences();
      final modified = original.copyWith(
        preferredVoice: 'premium',
        preferredRate: 1.2,
        enablePreloading: false,
      );

      expect(modified.preferredVoice, equals('premium'));
      expect(modified.preferredRate, equals(1.2));
      expect(modified.enablePreloading, isFalse);
      // 其他属性应该保持不变
      expect(modified.preferredVolume, equals(original.preferredVolume));
      expect(modified.preferredLanguage, equals(original.preferredLanguage));
    });

    test('应该正确序列化和反序列化', () {
      final original = UserPreferences(
        preferredVoice: 'test-voice',
        preferredRate: 1.3,
        preferredVolume: 0.9,
        preferredLanguage: 'en-US',
        enablePreloading: false,
        preferredPlaybackMode: PlaybackMode.media,
        playbackStrategies: [
          PlaybackStrategy.mediaSessionAudio,
          PlaybackStrategy.systemTTS
        ],
        preferredFormat: AudioFormat.aac,
        preferredQuality: 4,
      );

      final json = original.toJson();
      final restored = UserPreferences.fromJson(json);

      expect(restored.preferredVoice, equals(original.preferredVoice));
      expect(restored.preferredRate, equals(original.preferredRate));
      expect(restored.preferredVolume, equals(original.preferredVolume));
      expect(restored.preferredLanguage, equals(original.preferredLanguage));
      expect(restored.enablePreloading, equals(original.enablePreloading));
      expect(restored.preferredPlaybackMode,
          equals(original.preferredPlaybackMode));
      expect(restored.playbackStrategies, equals(original.playbackStrategies));
      expect(restored.preferredFormat, equals(original.preferredFormat));
      expect(restored.preferredQuality, equals(original.preferredQuality));
    });
  });

  group('CacheConfig', () {
    test('应该创建默认缓存配置', () {
      final config = CacheConfig.defaultConfig();

      expect(config.maxMemoryCacheSize, equals(50));
      expect(config.maxDiskCacheSize, equals(200));
      expect(config.cacheExpiration, equals(const Duration(days: 7)));
      expect(config.maxCacheEntries, equals(1000));
      expect(config.enablePreloading, isTrue);
    });

    test('应该正确序列化和反序列化', () {
      final original = CacheConfig.defaultConfig();
      final json = original.toJson();
      final restored = CacheConfig.fromJson(json);

      expect(restored.maxMemoryCacheSize, equals(original.maxMemoryCacheSize));
      expect(restored.maxDiskCacheSize, equals(original.maxDiskCacheSize));
      expect(restored.cacheExpiration, equals(original.cacheExpiration));
      expect(restored.maxCacheEntries, equals(original.maxCacheEntries));
      expect(restored.enablePreloading, equals(original.enablePreloading));
    });
  });

  group('PlaybackConfig', () {
    test('应该创建默认播放配置', () {
      final config = PlaybackConfig.defaultConfig();

      expect(config.strategies.isNotEmpty, isTrue);
      expect(config.strategies.first,
          equals(PlaybackStrategy.customNotificationSound));
      expect(config.maxRetryAttempts, equals(3));
      expect(config.retryDelay, equals(const Duration(seconds: 1)));
      expect(config.enableFallback, isTrue);
    });

    test('应该正确序列化和反序列化', () {
      final original = PlaybackConfig.defaultConfig();
      final json = original.toJson();
      final restored = PlaybackConfig.fromJson(json);

      expect(restored.strategies, equals(original.strategies));
      expect(restored.maxRetryAttempts, equals(original.maxRetryAttempts));
      expect(restored.retryDelay, equals(original.retryDelay));
      expect(restored.enableFallback, equals(original.enableFallback));
    });
  });

  group('SystemConfig', () {
    test('应该创建默认系统配置', () {
      final config = SystemConfig.defaultConfig();

      expect(config.defaultAudioConfig, isA<AudioConfig>());
      expect(config.cacheConfig, isA<CacheConfig>());
      expect(config.playbackConfig, isA<PlaybackConfig>());
      expect(config.platformSpecificConfig, isA<Map<String, dynamic>>());
    });

    test('应该正确序列化和反序列化', () {
      final original = SystemConfig.defaultConfig();
      final json = original.toJson();
      final restored = SystemConfig.fromJson(json);

      expect(restored.defaultAudioConfig.voice,
          equals(original.defaultAudioConfig.voice));
      expect(restored.cacheConfig.maxMemoryCacheSize,
          equals(original.cacheConfig.maxMemoryCacheSize));
      expect(restored.playbackConfig.maxRetryAttempts,
          equals(original.playbackConfig.maxRetryAttempts));
    });
  });

  group('ConfigManager', () {
    late ConfigManager manager;

    setUp(() {
      manager = ConfigManager();
      manager.resetToDefaults(); // 确保每个测试开始时都是默认状态
    });

    test('应该返回默认配置', () {
      final systemConfig = manager.systemConfig;
      final userPrefs = manager.userPreferences;

      expect(systemConfig, isA<SystemConfig>());
      expect(userPrefs, isA<UserPreferences>());
    });

    test('应该更新系统配置', () {
      final newConfig = SystemConfig.defaultConfig();
      manager.updateSystemConfig(newConfig);

      expect(manager.systemConfig, equals(newConfig));
    });

    test('应该更新用户偏好', () {
      final newPrefs = UserPreferences.defaultPreferences().copyWith(
        preferredVoice: 'updated-voice',
      );
      manager.updateUserPreferences(newPrefs);

      expect(manager.userPreferences.preferredVoice, equals('updated-voice'));
    });

    test('应该获取当前音频配置', () {
      final audioConfig = manager.getCurrentAudioConfig();

      expect(audioConfig, isA<AudioConfig>());
      expect(audioConfig.isValid(), isTrue);
    });

    test('应该验证配置', () {
      expect(manager.validateConfig(), isTrue);

      // 设置无效配置
      final invalidPrefs = UserPreferences.defaultPreferences().copyWith(
        preferredRate: 5.0, // 无效的语速
      );
      manager.updateUserPreferences(invalidPrefs);

      expect(manager.validateConfig(), isFalse);
    });

    test('应该重置为默认配置', () {
      // 修改配置
      final customPrefs = UserPreferences.defaultPreferences().copyWith(
        preferredVoice: 'custom',
      );
      manager.updateUserPreferences(customPrefs);

      // 重置
      manager.resetToDefaults();

      expect(manager.userPreferences.preferredVoice, equals('default'));
    });

    test('应该返回配置统计信息', () {
      final stats = manager.getConfigStatistics();

      expect(stats['audioConfig'], isA<Map<String, dynamic>>());
      expect(stats['cacheConfig'], isA<Map<String, dynamic>>());
      expect(stats['playbackConfig'], isA<Map<String, dynamic>>());
      expect(stats['userPreferences'], isA<Map<String, dynamic>>());
      expect(stats['isValid'], isA<bool>());
    });

    test('ConfigManager应该是单例', () {
      final manager1 = ConfigManager();
      final manager2 = ConfigManager();

      expect(identical(manager1, manager2), isTrue);
    });
  });

  group('枚举测试', () {
    test('PlaybackMode应该有正确的值', () {
      expect(PlaybackMode.values.length, equals(3));
      expect(PlaybackMode.values, contains(PlaybackMode.notification));
      expect(PlaybackMode.values, contains(PlaybackMode.media));
      expect(PlaybackMode.values, contains(PlaybackMode.alarm));
    });

    test('PlaybackStrategy应该有正确的值', () {
      expect(PlaybackStrategy.values.length, equals(6));
      expect(PlaybackStrategy.values,
          contains(PlaybackStrategy.customNotificationSound));
      expect(PlaybackStrategy.values, contains(PlaybackStrategy.systemTTS));
    });
  });

  group('边界条件测试', () {
    test('应该处理极端配置值', () {
      final extremeConfig = AudioConfig(
        voice: '',
        rate: 0.5, // 最小值
        pitch: 2.0, // 最大值
        volume: 0.0, // 最小值
        language: '',
        format: AudioFormat.mp3,
        quality: 1, // 最小值
      );

      // 应该被标记为无效（因为voice和language为空）
      expect(extremeConfig.isValid(), isFalse);
    });

    test('应该处理边界值配置', () {
      final boundaryConfig = AudioConfig(
        voice: 'test',
        rate: 0.5, // 边界最小值
        pitch: 2.0, // 边界最大值
        volume: 1.0, // 边界最大值
        language: 'zh-CN',
        format: AudioFormat.mp3,
        quality: 5, // 边界最大值
      );

      expect(boundaryConfig.isValid(), isTrue);
    });
  });
}
