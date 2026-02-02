import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

/// 移动端语音合成服务实现
class VoiceServicePlatform {
  FlutterTts? _tts;
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _initializeMobileTTS();
      _initialized = true;
    } catch (e) {
      print('语音服务初始化失败: $e');
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
      
      // iOS 特定配置
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          await _tts!.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
              IosTextToSpeechAudioCategoryOptions.duckOthers,
            ],
            IosTextToSpeechAudioMode.voicePrompt,
          );
        } catch (e) {
          print('iOS Audio Category 设置失败: $e');
        }
      }
      
      print('移动端 TTS 已初始化');
    } catch (e) {
      print('移动端 TTS 初始化失败: $e');
    }
  }
  
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();
    
    try {
      if (_tts != null) {
        await _tts!.speak(text);
      }
    } catch (e) {
      print('语音播放失败: $e');
    }
  }
  
  Future<void> stop() async {
    try {
      if (_tts != null) {
        await _tts!.stop();
      }
    } catch (e) {
      print('停止语音失败: $e');
    }
  }
  
  Future<void> pause() async {
    try {
      if (_tts != null) {
        await _tts!.pause();
      }
    } catch (e) {
      print('暂停语音失败: $e');
    }
  }
}