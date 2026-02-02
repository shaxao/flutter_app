import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// 语音合成服务 - 支持后台和锁屏播报
class VoiceService {
  static final VoiceService instance = VoiceService._();
  VoiceService._();
  
  FlutterTts? _tts;
  html.SpeechSynthesis? _webSpeechSynthesis;
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      if (kIsWeb) {
        await _initializeWebTTS();
      } else {
        await _initializeMobileTTS();
      }
      _initialized = true;
    } catch (e) {
      print('语音服务初始化失败: $e');
      _initialized = true; // 标记为已初始化，避免重复尝试
    }
  }
  
  Future<void> _initializeWebTTS() async {
    try {
      // 检查浏览器是否支持语音合成
      if (html.window.speechSynthesis != null) {
        _webSpeechSynthesis = html.window.speechSynthesis;
        
        // 等待语音列表加载
        final voices = _webSpeechSynthesis!.getVoices();
        if (voices.isEmpty) {
          // 某些浏览器需要异步加载语音列表
          await Future.delayed(const Duration(milliseconds: 100));
        }
        
        print('✅ Web 语音合成已初始化，可用语音: ${_webSpeechSynthesis!.getVoices().length} 个');
      } else {
        print('❌ 浏览器不支持语音合成');
      }
    } catch (e) {
      print('Web TTS 初始化失败: $e');
    }
  }
  
  Future<void> _initializeMobileTTS() async {
    try {
      _tts = FlutterTts();
      
      // 基础配置
      await _tts!.setLanguage('zh-CN');
      await _tts!.setSpeechRate(0.5); // 语速
      await _tts!.setVolume(1.0); // 音量
      await _tts!.setPitch(1.0); // 音调
      
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
  
  /// 播报文本
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();
    
    try {
      if (kIsWeb) {
        await _speakWeb(text);
      } else {
        await _speakMobile(text);
      }
    } catch (e) {
      print('语音播放失败: $e');
    }
  }
  
  Future<void> _speakWeb(String text) async {
    try {
      if (_webSpeechSynthesis == null) {
        print('❌ Web 语音合成不可用，显示文本提示');
        _showSpeechFallback(text);
        return;
      }
      
      // 停止当前播放
      _webSpeechSynthesis!.cancel();
      
      // 创建语音合成请求
      final utterance = html.SpeechSynthesisUtterance(text);
      
      // 设置语音参数
      utterance.lang = 'zh-CN';
      utterance.rate = 0.8;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      
      // 获取语音列表
      final voices = _webSpeechSynthesis!.getVoices();
      print('可用语音数量: ${voices.length}');
      
      // 查找中文语音
      html.SpeechSynthesisVoice? chineseVoice;
      for (final voice in voices) {
        if (voice.lang?.startsWith('zh') == true) {
          chineseVoice = voice;
          print('找到中文语音: ${voice.name} (${voice.lang})');
          break;
        }
      }
      
      if (chineseVoice != null) {
        utterance.voice = chineseVoice;
      } else if (voices.isNotEmpty) {
        utterance.voice = voices.first;
        print('使用默认语音: ${voices.first.name}');
      }
      
      // 设置事件监听
      utterance.onStart.listen((event) {
        print('🎤 开始语音播放: $text');
      });
      
      utterance.onEnd.listen((event) {
        print('✅ 语音播放完成');
      });
      
      utterance.onError.listen((event) {
        print('❌ 语音播放错误，显示备用提示');
        _showSpeechFallback(text);
      });
      
      // 开始播放
      _webSpeechSynthesis!.speak(utterance);
      print('🔊 语音播放指令已发送');
      
    } catch (e) {
      print('❌ Web 语音播放失败: $e');
      _showSpeechFallback(text);
    }
  }
  
  void _showSpeechFallback(String text) {
    // 创建一个语音提示框
    final speechBox = html.DivElement()
      ..className = 'flutter-speech-box'
      ..style.cssText = '''
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 24px 32px;
        border-radius: 16px;
        box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        z-index: 10001;
        max-width: 400px;
        text-align: center;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        animation: speechFadeIn 0.3s ease-out;
        backdrop-filter: blur(10px);
      '''
      ..innerHtml = '''
        <div style="display: flex; align-items: center; justify-content: center; margin-bottom: 16px;">
          <div style="width: 16px; height: 16px; background: #10b981; border-radius: 50%; margin-right: 12px; animation: pulse 1.5s infinite;"></div>
          <div style="font-weight: 700; font-size: 18px;">🎤 语音播报</div>
        </div>
        <div style="font-size: 16px; line-height: 1.6; opacity: 0.95; font-weight: 500;">$text</div>
      ''';
    
    // 添加动画样式
    final style = html.StyleElement()
      ..text = '''
        @keyframes speechFadeIn {
          from { opacity: 0; transform: translate(-50%, -50%) scale(0.8); }
          to { opacity: 1; transform: translate(-50%, -50%) scale(1); }
        }
        @keyframes pulse {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.7; transform: scale(1.1); }
        }
      ''';
    
    html.document.head?.append(style);
    html.document.body?.append(speechBox);
    
    // 4秒后移除
    Future.delayed(const Duration(seconds: 4), () {
      speechBox.style.animation = 'speechFadeIn 0.3s ease-in reverse';
      Future.delayed(const Duration(milliseconds: 300), () {
        speechBox.remove();
        style.remove();
      });
    });
    
    print('语音备用提示已显示: $text');
  }
  
  Future<void> _speakMobile(String text) async {
    if (_tts != null) {
      await _tts!.speak(text);
    }
  }
  
  /// 停止播报
  Future<void> stop() async {
    try {
      if (kIsWeb) {
        _webSpeechSynthesis?.cancel();
      } else {
        if (_tts != null) {
          await _tts!.stop();
        }
      }
    } catch (e) {
      print('停止语音失败: $e');
    }
  }
  
  /// 暂停播报
  Future<void> pause() async {
    if (kIsWeb) {
      _webSpeechSynthesis?.pause();
    } else {
      if (_tts != null) {
        await _tts!.pause();
      }
    }
  }
  
  /// 检查并播报提醒（后台任务调用）
  static Future<void> checkAndPlayReminders() async {
    // TODO: 从数据库读取当前时间的提醒
    // TODO: 调用 speak() 播报
    
    final now = DateTime.now();
    print('Checking reminders at: $now');
    
    // 示例：播报提醒
    await instance.speak('您有新的排班提醒');
  }
  
  /// 播报提醒内容
  Future<void> speakReminder({
    required String type,
    required String content,
  }) async {
    String message = '';
    
    switch (type) {
      case 'shift_start':
        message = '上班提醒：$content';
        break;
      case 'shift_end':
        message = '下班提醒：$content';
        break;
      case 'break':
        message = '休息提醒：$content';
        break;
      case 'custom':
        message = content;
        break;
      default:
        message = content;
    }
    
    await speak(message);
  }
}
