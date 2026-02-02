import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// 移动端语音合成服务实现 - 支持锁屏播放
class VoiceServicePlatform {
  FlutterTts? _tts;
  AudioPlayer? _audioPlayer;
  bool _initialized = false;
  bool _isBackgroundMode = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _initializeMobileTTS();
      await _initializeAudioPlayer();
      await _setupAudioSession();
      _initialized = true;
      print('✅ 移动端语音服务初始化完成');
    } catch (e) {
      print('❌ 语音服务初始化失败: $e');
      _initialized = true;
    }
  }
  
  Future<void> _initializeMobileTTS() async {
    try {
      _tts = FlutterTts();
      
      // 基础配置
      await _tts!.setLanguage('zh-CN');
      await _tts!.setSpeechRate(0.5);
      await _tts!.setVolume(1.0);
      await _tts!.setPitch(1.0);
      
      // iOS 特定配置 - 关键：支持后台播放
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          // 设置音频类别为播放模式，支持后台和锁屏播放
          await _tts!.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              IosTextToSpeechAudioCategoryOptions.duckOthers,
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker, // 强制使用扬声器
            ],
            IosTextToSpeechAudioMode.voicePrompt, // 语音提示模式
          );
          
          print('✅ iOS Audio Category 已设置为后台播放模式');
        } catch (e) {
          print('❌ iOS Audio Category 设置失败: $e');
        }
      }
      
      // 设置TTS事件监听
      _tts!.setStartHandler(() {
        print('🔊 TTS开始播放');
      });
      
      _tts!.setCompletionHandler(() {
        print('✅ TTS播放完成');
      });
      
      _tts!.setErrorHandler((msg) {
        print('❌ TTS播放错误: $msg');
      });
      
      print('✅ 移动端 TTS 已初始化');
    } catch (e) {
      print('❌ 移动端 TTS 初始化失败: $e');
    }
  }
  
  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();
      
      // 设置音频播放器为全局模式（支持后台播放）
      await _audioPlayer!.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.allowBluetooth,
              AVAudioSessionOptions.allowBluetoothA2DP,
              AVAudioSessionOptions.defaultToSpeaker,
              AVAudioSessionOptions.mixWithOthers,
            ],
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.voiceCommunication,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );
      
      print('✅ 音频播放器已初始化');
    } catch (e) {
      print('❌ 音频播放器初始化失败: $e');
    }
  }
  
  Future<void> _setupAudioSession() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        // 使用平台通道设置iOS音频会话
        const platform = MethodChannel('voiceflow/audio_session');
        await platform.invokeMethod('setupBackgroundAudio');
        print('✅ iOS音频会话已设置为后台模式');
      } catch (e) {
        print('⚠️ iOS音频会话设置失败，将使用默认配置: $e');
      }
    }
  }
  
  /// 主要的语音播放方法 - 支持锁屏播放
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();
    
    try {
      print('🔊 开始播放语音: "$text"');
      
      // 策略1: 尝试直接使用TTS播放
      if (_tts != null) {
        await _activateAudioSession();
        await _tts!.speak(text);
        return;
      }
      
      // 策略2: 如果TTS不可用，尝试使用预录音频
      await _playPrerecordedAudio(text);
      
    } catch (e) {
      print('❌ 语音播放失败: $e');
      // 最后备选：系统提示音
      await _playSystemSound();
    }
  }
  
  /// 激活音频会话（确保后台播放权限）
  Future<void> _activateAudioSession() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        const platform = MethodChannel('voiceflow/audio_session');
        await platform.invokeMethod('activateAudioSession');
      } catch (e) {
        print('⚠️ 激活音频会话失败，继续使用默认配置: $e');
        // 不抛出错误，继续执行
      }
    }
  }
  
  /// 播放预录音频（备选方案）
  Future<void> _playPrerecordedAudio(String text) async {
    try {
      if (_audioPlayer != null) {
        // 这里可以播放预录的提示音或者从服务器获取TTS音频
        // 暂时播放一个提示音
        await _audioPlayer!.play(AssetSource('sounds/reminder_beep.mp3'));
        print('✅ 预录音频播放完成');
      }
    } catch (e) {
      print('❌ 预录音频播放失败: $e');
    }
  }
  
  /// 播放系统提示音（最后备选）
  Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      print('✅ 系统提示音播放完成');
    } catch (e) {
      print('❌ 系统提示音播放失败: $e');
    }
  }
  
  /// 锁屏状态下的语音播放（特殊处理）
  Future<void> speakInLockscreen(String text) async {
    print('🔒 锁屏状态语音播放: "$text"');
    
    try {
      // 1. 设置后台模式标志
      _isBackgroundMode = true;
      
      // 2. 尝试播放语音
      await speak(text);
      
      // 3. 如果是iOS，尝试使用原生方法（如果可用）
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          const platform = MethodChannel('voiceflow/voice');
          await platform.invokeMethod('speakInBackground', {'text': text});
        } catch (e) {
          print('⚠️ 原生语音播放不可用，使用Flutter TTS: $e');
          // 继续使用Flutter TTS，不抛出错误
        }
      }
      
    } catch (e) {
      print('❌ 锁屏语音播放失败: $e');
      // 确保至少尝试基础语音播放
      try {
        await speak(text);
      } catch (e2) {
        print('❌ 基础语音播放也失败: $e2');
      }
    } finally {
      _isBackgroundMode = false;
    }
  }
  
  /// 发送带语音播放功能的本地通知
  Future<void> _sendVoiceNotification(String text) async {
    try {
      const platform = MethodChannel('voiceflow/notifications');
      await platform.invokeMethod('showVoiceNotification', {
        'title': '🔊 语音提醒',
        'body': text,
        'playVoice': true,
        'voiceText': text,
      });
      print('✅ 语音通知已发送');
    } catch (e) {
      print('❌ 发送语音通知失败: $e');
    }
  }
  
  Future<void> stop() async {
    try {
      if (_tts != null) {
        await _tts!.stop();
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
    } catch (e) {
      print('❌ 停止语音失败: $e');
    }
  }
  
  Future<void> pause() async {
    try {
      if (_tts != null) {
        await _tts!.pause();
      }
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
      }
    } catch (e) {
      print('❌ 暂停语音失败: $e');
    }
  }
  
  /// 检查是否支持后台播放
  Future<bool> isBackgroundPlaybackSupported() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        const platform = MethodChannel('voiceflow/audio_session');
        final result = await platform.invokeMethod('checkBackgroundAudioPermission');
        return result == true;
      } catch (e) {
        print('❌ 检查后台播放权限失败，假设支持: $e');
        return true; // 假设支持，避免阻塞功能
      }
    }
    return true; // Android默认支持
  }
  
  /// 请求后台音频播放权限
  Future<bool> requestBackgroundAudioPermission() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        const platform = MethodChannel('voiceflow/audio_session');
        final result = await platform.invokeMethod('requestBackgroundAudioPermission');
        return result == true;
      } catch (e) {
        print('❌ 请求后台音频权限失败，假设已授权: $e');
        return true; // 假设已授权，避免阻塞功能
      }
    }
    return true;
  }
  
  /// 获取语音服务状态
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'ttsAvailable': _tts != null,
      'audioPlayerAvailable': _audioPlayer != null,
      'isBackgroundMode': _isBackgroundMode,
      'platform': defaultTargetPlatform.toString(),
    };
  }
}