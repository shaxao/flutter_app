import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../audio_playback_system.dart';
import '../audio_config.dart';

/// Android平台音频适配器
class AndroidAudioAdapter extends BaseAudioAdapter {
  static const MethodChannel _channel = MethodChannel('audio_playback/android');
  
  AudioPlayer? _audioPlayer;
  bool _initialized = false;

  @override
  String get platformName => 'android';

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  List<PlaybackStrategy> get supportedStrategies => [
    PlaybackStrategy.customNotificationSound,
    PlaybackStrategy.backgroundAudio,
    PlaybackStrategy.mediaSessionAudio,
    PlaybackStrategy.systemTTS,
  ];

  /// 初始化Android适配器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 初始化AudioPlayer
      _audioPlayer = AudioPlayer();
      
      // 设置音频播放完成监听
      _audioPlayer!.onPlayerComplete.listen((_) {
        updateStatus(PlaybackStatus(
          state: PlaybackState.completed,
          timestamp: DateTime.now(),
        ));
      });

      // 设置播放状态监听
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        PlaybackState playbackState;
        switch (state) {
          case PlayerState.playing:
            playbackState = PlaybackState.playing;
            break;
          case PlayerState.paused:
            playbackState = PlaybackState.paused;
            break;
          case PlayerState.stopped:
            playbackState = PlaybackState.stopped;
            break;
          case PlayerState.completed:
            playbackState = PlaybackState.completed;
            break;
          default:
            playbackState = PlaybackState.idle;
        }

        updateStatus(PlaybackStatus(
          state: playbackState,
          timestamp: DateTime.now(),
        ));
      });

      // 初始化原生Android音频功能
      await _initializeNativeAudio();

      _initialized = true;
      print('✅ Android音频适配器初始化完成');
    } catch (e) {
      print('❌ Android音频适配器初始化失败: $e');
      setError('初始化失败: $e');
    }
  }

  /// 初始化原生Android音频功能
  Future<void> _initializeNativeAudio() async {
    try {
      await _channel.invokeMethod('initialize');
    } catch (e) {
      print('⚠️ 原生Android音频初始化失败: $e');
      // 不抛出异常，允许使用AudioPlayer作为备选方案
    }
  }

  @override
  Future<PlaybackResult> playAudio(
    String filePath, {
    PlaybackConfig? config,
  }) async {
    if (!_initialized) await initialize();

    config ??= PlaybackConfig.defaultConfig();

    // 按策略优先级尝试播放
    for (final strategy in config.strategies) {
      if (!supportedStrategies.contains(strategy)) continue;

      try {
        final result = await _playWithStrategy(filePath, strategy, config);
        if (result == PlaybackResult.success) {
          setSuccess(strategy);
          return result;
        }
      } catch (e) {
        print('⚠️ 策略 $strategy 播放失败: $e');
        continue;
      }
    }

    setError('所有播放策略都失败了');
    return PlaybackResult.failed;
  }

  /// 使用特定策略播放音频
  Future<PlaybackResult> _playWithStrategy(
    String filePath,
    PlaybackStrategy strategy,
    PlaybackConfig config,
  ) async {
    switch (strategy) {
      case PlaybackStrategy.customNotificationSound:
        return await _playAsNotificationSound(filePath, config);
      
      case PlaybackStrategy.backgroundAudio:
        return await _playAsBackgroundAudio(filePath, config);
      
      case PlaybackStrategy.mediaSessionAudio:
        return await _playWithMediaSession(filePath, config);
      
      case PlaybackStrategy.systemTTS:
        return await _playWithSystemTTS(filePath, config);
      
      default:
        return PlaybackResult.notSupported;
    }
  }

  /// 作为通知铃声播放
  Future<PlaybackResult> _playAsNotificationSound(
    String filePath,
    PlaybackConfig config,
  ) async {
    try {
      updateStatus(PlaybackStatus(
        state: PlaybackState.loading,
        strategy: PlaybackStrategy.customNotificationSound,
        timestamp: DateTime.now(),
      ));

      // 使用原生方法播放通知声音
      final result = await _channel.invokeMethod('playNotificationSound', {
        'filePath': filePath,
        'volume': config.volume,
      });

      if (result == true) {
        print('🔔 通知铃声播放成功');
        return PlaybackResult.success;
      } else {
        print('❌ 通知铃声播放失败');
        return PlaybackResult.failed;
      }
    } catch (e) {
      print('❌ 通知铃声播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 后台音频播放
  Future<PlaybackResult> _playAsBackgroundAudio(
    String filePath,
    PlaybackConfig config,
  ) async {
    try {
      updateStatus(PlaybackStatus(
        state: PlaybackState.loading,
        strategy: PlaybackStrategy.backgroundAudio,
        timestamp: DateTime.now(),
      ));

      // 设置音频会话为播放模式
      await _audioPlayer!.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.notificationRingtone,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));

      // 播放音频文件
      await _audioPlayer!.play(DeviceFileSource(filePath), volume: config.volume);
      
      print('🎵 后台音频播放启动');
      return PlaybackResult.success;
    } catch (e) {
      print('❌ 后台音频播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 使用Media Session播放
  Future<PlaybackResult> _playWithMediaSession(
    String filePath,
    PlaybackConfig config,
  ) async {
    try {
      updateStatus(PlaybackStatus(
        state: PlaybackState.loading,
        strategy: PlaybackStrategy.mediaSessionAudio,
        timestamp: DateTime.now(),
      ));

      // 使用原生方法启用Media Session
      await _channel.invokeMethod('enableMediaSession', {
        'title': '语音提醒',
        'artist': '提醒系统',
      });

      // 播放音频
      await _audioPlayer!.play(DeviceFileSource(filePath), volume: config.volume);
      
      print('📱 Media Session音频播放启动');
      return PlaybackResult.success;
    } catch (e) {
      print('❌ Media Session播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 使用系统TTS播放（降级策略）
  Future<PlaybackResult> _playWithSystemTTS(
    String filePath,
    PlaybackConfig config,
  ) async {
    try {
      updateStatus(PlaybackStatus(
        state: PlaybackState.loading,
        strategy: PlaybackStrategy.systemTTS,
        timestamp: DateTime.now(),
      ));

      // 这里应该从音频文件的metadata中获取原始文本
      // 作为降级策略，使用系统TTS播放
      final result = await _channel.invokeMethod('playWithTTS', {
        'text': '语音提醒', // 实际应该从AudioFile.metadata获取
        'volume': config.volume,
      });

      if (result == true) {
        print('🗣️ 系统TTS播放成功');
        return PlaybackResult.success;
      } else {
        return PlaybackResult.failed;
      }
    } catch (e) {
      print('❌ 系统TTS播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  @override
  Future<void> stopPlayback() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
      
      // 停止原生播放
      await _channel.invokeMethod('stopPlayback');
      
      updateStatus(PlaybackStatus(
        state: PlaybackState.stopped,
        timestamp: DateTime.now(),
      ));
      
      print('⏹️ Android音频播放已停止');
    } catch (e) {
      print('❌ 停止播放失败: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      
      await _channel.invokeMethod('dispose');
      _initialized = false;
      
      await super.dispose();
      print('✅ Android音频适配器资源已释放');
    } catch (e) {
      print('❌ Android适配器释放失败: $e');
    }
  }
}