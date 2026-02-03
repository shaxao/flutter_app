import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'cache_management_system.dart';

/// 音频配置 - 定义语音合成参数
class AudioConfig {
  final String voice;           // 音色
  final double rate;           // 语速 (0.5 - 2.0)
  final double pitch;          // 音调 (0.5 - 2.0)
  final double volume;         // 音量 (0.0 - 1.0)
  final String language;       // 语言
  final AudioFormat format;    // 音频格式
  final int quality;          // 音质等级 (1-5)

  const AudioConfig({
    required this.voice,
    required this.rate,
    required this.pitch,
    required this.volume,
    required this.language,
    required this.format,
    required this.quality,
  });

  /// 默认配置
  factory AudioConfig.defaultConfig() {
    return const AudioConfig(
      voice: 'default',
      rate: 1.0,
      pitch: 1.0,
      volume: 0.8,
      language: 'zh-CN',
      format: AudioFormat.mp3,
      quality: 3,
    );
  }

  /// 高质量配置
  factory AudioConfig.highQuality() {
    return const AudioConfig(
      voice: 'premium',
      rate: 0.9,
      pitch: 1.0,
      volume: 0.8,
      language: 'zh-CN',
      format: AudioFormat.aac,
      quality: 5,
    );
  }

  /// 快速配置（低质量但生成快）
  factory AudioConfig.fast() {
    return const AudioConfig(
      voice: 'default',
      rate: 1.2,
      pitch: 1.0,
      volume: 0.8,
      language: 'zh-CN',
      format: AudioFormat.mp3,
      quality: 1,
    );
  }

  /// 验证配置参数
  bool isValid() {
    return rate >= 0.5 && rate <= 2.0 &&
           pitch >= 0.5 && pitch <= 2.0 &&
           volume >= 0.0 && volume <= 1.0 &&
           quality >= 1 && quality <= 5 &&
           language.isNotEmpty &&
           voice.isNotEmpty;
  }

  /// 生成配置哈希（用于缓存键）
  String get configHash {
    final configString = '$voice|$rate|$pitch|$volume|$language|${format.name}|$quality';
    final bytes = utf8.encode(configString);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12); // 取前12位作为配置哈希
  }

  /// 复制并修改配置
  AudioConfig copyWith({
    String? voice,
    double? rate,
    double? pitch,
    double? volume,
    String? language,
    AudioFormat? format,
    int? quality,
  }) {
    return AudioConfig(
      voice: voice ?? this.voice,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      volume: volume ?? this.volume,
      language: language ?? this.language,
      format: format ?? this.format,
      quality: quality ?? this.quality,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'voice': voice,
      'rate': rate,
      'pitch': pitch,
      'volume': volume,
      'language': language,
      'format': format.name,
      'quality': quality,
    };
  }

  /// 从JSON创建
  factory AudioConfig.fromJson(Map<String, dynamic> json) {
    return AudioConfig(
      voice: json['voice'] ?? 'default',
      rate: (json['rate'] ?? 1.0).toDouble(),
      pitch: (json['pitch'] ?? 1.0).toDouble(),
      volume: (json['volume'] ?? 0.8).toDouble(),
      language: json['language'] ?? 'zh-CN',
      format: AudioFormat.values.firstWhere(
        (f) => f.name == json['format'],
        orElse: () => AudioFormat.mp3,
      ),
      quality: json['quality'] ?? 3,
    );
  }

  @override
  String toString() {
    return 'AudioConfig(voice: $voice, rate: $rate, language: $language, format: ${format.name})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AudioConfig && other.configHash == configHash;
  }

  @override
  int get hashCode => configHash.hashCode;
}

/// 音频格式枚举
enum AudioFormat {
  mp3('mp3', 'audio/mpeg', '.mp3'),
  aac('aac', 'audio/aac', '.aac'),
  wav('wav', 'audio/wav', '.wav'),
  m4a('m4a', 'audio/mp4', '.m4a'),
  caf('caf', 'audio/x-caf', '.caf'); // iOS推荐格式

  const AudioFormat(this.name, this.mimeType, this.extension);

  final String name;
  final String mimeType;
  final String extension;

  /// 获取平台推荐格式
  static AudioFormat getPlatformRecommended() {
    // 根据平台返回推荐格式
    // iOS: CAF或AAC, Android: MP3或AAC, Web: MP3
    return AudioFormat.mp3; // 默认使用MP3，兼容性最好
  }

  /// 是否支持流式播放
  bool get supportsStreaming {
    switch (this) {
      case AudioFormat.mp3:
      case AudioFormat.aac:
        return true;
      case AudioFormat.wav:
      case AudioFormat.m4a:
      case AudioFormat.caf:
        return false;
    }
  }

  /// 获取预期文件大小（每秒音频的大小，单位：字节）
  int get bytesPerSecond {
    switch (this) {
      case AudioFormat.mp3:
        return 16000; // 128kbps
      case AudioFormat.aac:
        return 12000; // 96kbps
      case AudioFormat.wav:
        return 176400; // 1411kbps (44.1kHz, 16bit, stereo)
      case AudioFormat.m4a:
        return 12000; // 96kbps
      case AudioFormat.caf:
        return 12000; // 96kbps
    }
  }
}

/// 用户偏好设置
class UserPreferences {
  final String preferredVoice;
  final double preferredRate;
  final double preferredVolume;
  final String preferredLanguage;
  final bool enablePreloading;
  final PlaybackMode preferredPlaybackMode;
  final List<PlaybackStrategy> playbackStrategies;
  final AudioFormat preferredFormat;
  final int preferredQuality;

  const UserPreferences({
    required this.preferredVoice,
    required this.preferredRate,
    required this.preferredVolume,
    required this.preferredLanguage,
    required this.enablePreloading,
    required this.preferredPlaybackMode,
    required this.playbackStrategies,
    required this.preferredFormat,
    required this.preferredQuality,
  });

  /// 默认用户偏好
  factory UserPreferences.defaultPreferences() {
    return const UserPreferences(
      preferredVoice: 'default',
      preferredRate: 1.0,
      preferredVolume: 0.8,
      preferredLanguage: 'zh-CN',
      enablePreloading: true,
      preferredPlaybackMode: PlaybackMode.notification,
      playbackStrategies: [
        PlaybackStrategy.customNotificationSound,
        PlaybackStrategy.mediaSessionAudio,
        PlaybackStrategy.backgroundAudio,
        PlaybackStrategy.systemTTS,
      ],
      preferredFormat: AudioFormat.mp3,
      preferredQuality: 3,
    );
  }

  /// 转换为AudioConfig
  AudioConfig toAudioConfig() {
    return AudioConfig(
      voice: preferredVoice,
      rate: preferredRate,
      pitch: 1.0, // 默认音调
      volume: preferredVolume,
      language: preferredLanguage,
      format: preferredFormat,
      quality: preferredQuality,
    );
  }

  /// 复制并修改偏好
  UserPreferences copyWith({
    String? preferredVoice,
    double? preferredRate,
    double? preferredVolume,
    String? preferredLanguage,
    bool? enablePreloading,
    PlaybackMode? preferredPlaybackMode,
    List<PlaybackStrategy>? playbackStrategies,
    AudioFormat? preferredFormat,
    int? preferredQuality,
  }) {
    return UserPreferences(
      preferredVoice: preferredVoice ?? this.preferredVoice,
      preferredRate: preferredRate ?? this.preferredRate,
      preferredVolume: preferredVolume ?? this.preferredVolume,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      enablePreloading: enablePreloading ?? this.enablePreloading,
      preferredPlaybackMode: preferredPlaybackMode ?? this.preferredPlaybackMode,
      playbackStrategies: playbackStrategies ?? this.playbackStrategies,
      preferredFormat: preferredFormat ?? this.preferredFormat,
      preferredQuality: preferredQuality ?? this.preferredQuality,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'preferredVoice': preferredVoice,
      'preferredRate': preferredRate,
      'preferredVolume': preferredVolume,
      'preferredLanguage': preferredLanguage,
      'enablePreloading': enablePreloading,
      'preferredPlaybackMode': preferredPlaybackMode.name,
      'playbackStrategies': playbackStrategies.map((s) => s.name).toList(),
      'preferredFormat': preferredFormat.name,
      'preferredQuality': preferredQuality,
    };
  }

  /// 从JSON创建
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      preferredVoice: json['preferredVoice'] ?? 'default',
      preferredRate: (json['preferredRate'] ?? 1.0).toDouble(),
      preferredVolume: (json['preferredVolume'] ?? 0.8).toDouble(),
      preferredLanguage: json['preferredLanguage'] ?? 'zh-CN',
      enablePreloading: json['enablePreloading'] ?? true,
      preferredPlaybackMode: PlaybackMode.values.firstWhere(
        (m) => m.name == json['preferredPlaybackMode'],
        orElse: () => PlaybackMode.notification,
      ),
      playbackStrategies: (json['playbackStrategies'] as List<dynamic>?)
          ?.map((s) => PlaybackStrategy.values.firstWhere(
                (strategy) => strategy.name == s,
                orElse: () => PlaybackStrategy.systemTTS,
              ))
          .toList() ?? [PlaybackStrategy.systemTTS],
      preferredFormat: AudioFormat.values.firstWhere(
        (f) => f.name == json['preferredFormat'],
        orElse: () => AudioFormat.mp3,
      ),
      preferredQuality: json['preferredQuality'] ?? 3,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(voice: $preferredVoice, rate: $preferredRate, language: $preferredLanguage)';
  }
}

/// 播放模式枚举
enum PlaybackMode {
  notification,    // 作为通知铃声播放
  media,          // 作为媒体文件播放
  alarm,          // 作为闹钟播放
}

/// 播放策略枚举
enum PlaybackStrategy {
  customNotificationSound,  // 自定义通知铃声
  mediaSessionAudio,       // Media Session API
  backgroundAudio,         // 后台音频播放
  webAudioAPI,            // Web Audio API
  htmlAudio,              // HTML Audio
  systemTTS,              // 系统TTS (降级)
}

/// 系统配置
class SystemConfig {
  final AudioConfig defaultAudioConfig;
  final CacheConfig cacheConfig;
  final PlaybackConfig playbackConfig;
  final Map<String, dynamic> platformSpecificConfig;

  const SystemConfig({
    required this.defaultAudioConfig,
    required this.cacheConfig,
    required this.playbackConfig,
    required this.platformSpecificConfig,
  });

  /// 默认系统配置
  factory SystemConfig.defaultConfig() {
    return SystemConfig(
      defaultAudioConfig: AudioConfig.defaultConfig(),
      cacheConfig: CacheConfig.defaultConfig(),
      playbackConfig: PlaybackConfig.defaultConfig(),
      platformSpecificConfig: const {},
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'defaultAudioConfig': defaultAudioConfig.toJson(),
      'cacheConfig': cacheConfig.toJson(),
      'playbackConfig': playbackConfig.toJson(),
      'platformSpecificConfig': platformSpecificConfig,
    };
  }

  /// 从JSON创建
  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      defaultAudioConfig: AudioConfig.fromJson(json['defaultAudioConfig'] ?? {}),
      cacheConfig: CacheConfig.fromJson(json['cacheConfig'] ?? {}),
      playbackConfig: PlaybackConfig.fromJson(json['playbackConfig'] ?? {}),
      platformSpecificConfig: Map<String, dynamic>.from(json['platformSpecificConfig'] ?? {}),
    );
  }
}

/// 播放配置
class PlaybackConfig {
  final List<PlaybackStrategy> strategies;  // 播放策略优先级
  final int maxRetryAttempts;              // 最大重试次数
  final Duration retryDelay;               // 重试延迟
  final bool enableFallback;               // 是否启用降级播放
  final double volume;                     // 音量 (0.0-1.0)
  final bool forceBackground;              // 强制后台播放
  final bool useNotificationSound;         // 使用通知铃声
  final Duration timeout;                  // 播放超时

  const PlaybackConfig({
    required this.strategies,
    required this.maxRetryAttempts,
    required this.retryDelay,
    required this.enableFallback,
    this.volume = 1.0,
    this.forceBackground = false,
    this.useNotificationSound = true,
    this.timeout = const Duration(seconds: 30),
  });

  /// 默认播放配置
  factory PlaybackConfig.defaultConfig() {
    return const PlaybackConfig(
      strategies: [
        PlaybackStrategy.customNotificationSound,
        PlaybackStrategy.mediaSessionAudio,
        PlaybackStrategy.backgroundAudio,
        PlaybackStrategy.systemTTS,
      ],
      maxRetryAttempts: 3,
      retryDelay: Duration(seconds: 1),
      enableFallback: true,
    );
  }

  /// 后台播放配置
  factory PlaybackConfig.background() {
    return const PlaybackConfig(
      strategies: [
        PlaybackStrategy.backgroundAudio,
        PlaybackStrategy.mediaSessionAudio,
        PlaybackStrategy.customNotificationSound,
        PlaybackStrategy.systemTTS,
      ],
      maxRetryAttempts: 3,
      retryDelay: Duration(seconds: 1),
      enableFallback: true,
      forceBackground: true,
    );
  }

  /// 通知播放配置
  factory PlaybackConfig.notification() {
    return const PlaybackConfig(
      strategies: [
        PlaybackStrategy.customNotificationSound,
        PlaybackStrategy.backgroundAudio,
        PlaybackStrategy.systemTTS,
      ],
      maxRetryAttempts: 3,
      retryDelay: Duration(seconds: 1),
      enableFallback: true,
      useNotificationSound: true,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'strategies': strategies.map((s) => s.name).toList(),
      'maxRetryAttempts': maxRetryAttempts,
      'retryDelaySeconds': retryDelay.inSeconds,
      'enableFallback': enableFallback,
      'volume': volume,
      'forceBackground': forceBackground,
      'useNotificationSound': useNotificationSound,
      'timeoutSeconds': timeout.inSeconds,
    };
  }

  /// 从JSON创建
  factory PlaybackConfig.fromJson(Map<String, dynamic> json) {
    return PlaybackConfig(
      strategies: (json['strategies'] as List<dynamic>?)
          ?.map((s) => PlaybackStrategy.values.firstWhere(
                (strategy) => strategy.name == s,
                orElse: () => PlaybackStrategy.systemTTS,
              ))
          .toList() ?? [PlaybackStrategy.systemTTS],
      maxRetryAttempts: json['maxRetryAttempts'] ?? 3,
      retryDelay: Duration(seconds: json['retryDelaySeconds'] ?? 1),
      enableFallback: json['enableFallback'] ?? true,
      volume: (json['volume'] ?? 1.0).toDouble(),
      forceBackground: json['forceBackground'] ?? false,
      useNotificationSound: json['useNotificationSound'] ?? true,
      timeout: Duration(seconds: json['timeoutSeconds'] ?? 30),
    );
  }
}

/// 配置管理器
class ConfigManager {
  static final ConfigManager _instance = ConfigManager._internal();
  factory ConfigManager() => _instance;
  ConfigManager._internal();

  SystemConfig _systemConfig = SystemConfig.defaultConfig();
  UserPreferences _userPreferences = UserPreferences.defaultPreferences();

  /// 获取系统配置
  SystemConfig get systemConfig => _systemConfig;

  /// 获取用户偏好
  UserPreferences get userPreferences => _userPreferences;

  /// 更新系统配置
  void updateSystemConfig(SystemConfig config) {
    _systemConfig = config;
    _notifyConfigChanged();
  }

  /// 更新用户偏好
  void updateUserPreferences(UserPreferences preferences) {
    _userPreferences = preferences;
    _notifyConfigChanged();
  }

  /// 获取当前音频配置（合并系统配置和用户偏好）
  AudioConfig getCurrentAudioConfig() {
    return _userPreferences.toAudioConfig();
  }

  /// 验证配置
  bool validateConfig() {
    return getCurrentAudioConfig().isValid();
  }

  /// 重置为默认配置
  void resetToDefaults() {
    _systemConfig = SystemConfig.defaultConfig();
    _userPreferences = UserPreferences.defaultPreferences();
    _notifyConfigChanged();
  }

  /// 配置变更通知（可以扩展为事件系统）
  void _notifyConfigChanged() {
    print('✅ 配置已更新');
  }

  /// 获取配置统计信息
  Map<String, dynamic> getConfigStatistics() {
    return {
      'audioConfig': getCurrentAudioConfig().toJson(),
      'cacheConfig': _systemConfig.cacheConfig.toJson(),
      'playbackConfig': _systemConfig.playbackConfig.toJson(),
      'userPreferences': _userPreferences.toJson(),
      'isValid': validateConfig(),
    };
  }
}