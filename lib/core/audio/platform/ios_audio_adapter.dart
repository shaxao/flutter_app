import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../audio_playback_system.dart';
import '../audio_config.dart';

/// iOS平台音频适配器
class IOSAudioAdapter extends BaseAudioAdapter {
  static const MethodChannel _channel = MethodChannel('audio_playback/ios');
  
  AudioPlayer? _audioPlayer;
  bool _initialized = false;
  bool _audioSessionActive = false;

  @override
  String get platformName => 'ios';

  @override
  bool get isSupported => Platform.isIOS;

  @override
  List<PlaybackStrategy> get supportedStrategies => [
    PlaybackStrategy.backgroundAudio,
    PlaybackStrategy.mediaSessionAudio,
    PlaybackStrategy.customNotificationSound,
    PlaybackStrategy.systemTTS,
  ];

  /// 初始化iOS适配器
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

      // 初始化原生iOS音频功能
      await _initializeNativeAudio();

      _initialized = true;
      print('✅ iOS音频适配器初始化完成');
    } catch (e) {
      print('❌ iOS音频适配器初始化失败: $e');
      setError('初始化失败: $e');
    }
  }

  /// 初始化原生iOS音频功能
  Future<void> _initializeNativeAudio() async {
    try {
      // 使用现有的AudioSessionManager
      await _channel.invokeMethod('initializeAudioSession');
      print('✅ iOS音频会话初始化完成');
    } catch (e) {
      print('⚠️ 原生iOS音频初始化失败: $e');
      // 不抛出异常，允许使用AudioPlayer作为备选方案
    }
  }

  /// 激活音频会话
  Future<bool> _activateAudioSession() async {
    if (_audioSessionActive) return true;

    try {
      final result = await _channel.invokeMethod('activateAudioSession');
      _audioSessionActive = result == true;
      
      if (_audioSessionActive) {
        print('🎵 iOS音频会话已激活');
      } else {
        print('❌ iOS音频会话激活失败');
      }
      
      return _audioSessionActive;
    } catch (e) {
      print('❌ 激活音频会话异常: $e');
      return false;
    }
  }

  @override
  Future<PlaybackResult> playAudio(
    String filePath, {
    PlaybackConfig? config,
  }) async {
    if (!_initialized) await initialize();

    config ??= PlaybackConfig.defaultConfig();

    // 激活音频会话
    if (!await _activateAudioSession()) {
      setError('无法激活音频会话');
      return PlaybackResult.permissionDenied;
    }

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
      case PlaybackStrategy.backgroundAudio:
        return await _playAsBackgroundAudio(filePath, config);
      
      case PlaybackStrategy.mediaSessionAudio:
        return await _playWithMediaSession(filePath, config);
      
      case PlaybackStrategy.customNotificationSound:
        return await _playAsNotificationSound(filePath, config);
      
      case PlaybackStrategy.systemTTS:
        return await _playWithSystemTTS(filePath, config);
      
      default:
        return PlaybackResult.notSupported;
    }
  }

  /// 后台音频播放（iOS主要策略）
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

      // 使用原生iOS方法播放后台音频
      final result = await _channel.invokeMethod('playBackgroundAudio', {
        'filePath': filePath,
        'volume': config.volume,
        'forceBackground': config.forceBackground,
      });

      if (result == true) {
        print('🎵 iOS后台音频播放成功');
        return PlaybackResult.success;
      } else {
        print('❌ iOS后台音频播放失败');
        // 降级到AudioPlayer
        return await _playWithAudioPlayer(filePath, config);
      }
    } catch (e) {
      print('❌ iOS后台音频播放异常: $e');
      // 降级到AudioPlayer
      return await _playWithAudioPlayer(filePath, config);
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

      // 设置Media Session信息
      await _channel.invokeMethod('setupMediaSession', {
        'title': '语音提醒',
        'artist': '提醒系统',
        'duration': 10.0, // 估计时长
      });

      // 播放音频
      return await _playWithAudioPlayer(filePath, config);
    } catch (e) {
      print('❌ iOS Media Session播放异常: $e');
      return PlaybackResult.failed;
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

      // iOS的通知声音播放
      final result = await _channel.invokeMethod('playNotificationSound', {
        'filePath': filePath,
        'volume': config.volume,
      });

      if (result == true) {
        print('🔔 iOS通知铃声播放成功');
        return PlaybackResult.success;
      } else {
        return PlaybackResult.failed;
      }
    } catch (e) {
      print('❌ iOS通知铃声播放异常: $e');
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

      // 使用iOS原生TTS
      final result = await _channel.invokeMethod('playWithTTS', {
        'text': '语音提醒', // 实际应该从AudioFile.metadata获取
        'volume': config.volume,
        'rate': 0.5,
        'pitch': 1.0,
      });

      if (result == true) {
        print('🗣️ iOS系统TTS播放成功');
        return PlaybackResult.success;
      } else {
        return PlaybackResult.failed;
      }
    } catch (e) {
      print('❌ iOS系统TTS播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 使用AudioPlayer播放（备选方案）
  Future<PlaybackResult> _playWithAudioPlayer(
    String filePath,
    PlaybackConfig config,
  ) async {
    try {
      // 设置iOS音频上下文
      await _audioPlayer!.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: [
            AVAudioSessionOptions.defaultToSpeaker,
            AVAudioSessionOptions.duckOthers,
          ],
        ),
      ));

      // 播放音频文件
      await _audioPlayer!.play(DeviceFileSource(filePath), volume: config.volume);
      
      print('🎵 iOS AudioPlayer播放启动');
      return PlaybackResult.success;
    } catch (e) {
      print('❌ iOS AudioPlayer播放异常: $e');
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
      
      print('⏹️ iOS音频播放已停止');
    } catch (e) {
      print('❌ 停止播放失败: $e');
    }
  }

  /// 停用音频会话
  Future<void> _deactivateAudioSession() async {
    if (!_audioSessionActive) return;

    try {
      await _channel.invokeMethod('deactivateAudioSession');
      _audioSessionActive = false;
      print('🔇 iOS音频会话已停用');
    } catch (e) {
      print('❌ 停用音频会话失败: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      
      await _deactivateAudioSession();
      await _channel.invokeMethod('dispose');
      _initialized = false;
      
      await super.dispose();
      print('✅ iOS音频适配器资源已释放');
    } catch (e) {
      print('❌ iOS适配器释放失败: $e');
    }
  }
}