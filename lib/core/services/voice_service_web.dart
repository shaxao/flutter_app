import 'dart:html' as html;

/// Web端语音合成服务实现
class VoiceServicePlatform {
  html.SpeechSynthesis? _webSpeechSynthesis;
  bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await _initializeWebTTS();
      _initialized = true;
    } catch (e) {
      print('语音服务初始化失败: $e');
      _initialized = true;
    }
  }
  
  Future<void> _initializeWebTTS() async {
    try {
      if (html.window.speechSynthesis != null) {
        _webSpeechSynthesis = html.window.speechSynthesis;
        
        final voices = _webSpeechSynthesis!.getVoices();
        if (voices.isEmpty) {
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
  
  Future<void> speak(String text) async {
    if (!_initialized) await initialize();
    
    try {
      if (_webSpeechSynthesis == null) {
        print('❌ Web 语音合成不可用，显示文本提示');
        _showSpeechFallback(text);
        return;
      }
      
      _webSpeechSynthesis!.cancel();
      
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = 'zh-CN';
      utterance.rate = 1.0; // 调整语速为正常
      utterance.pitch = 1.0;
      utterance.volume = 1.0;
      
      final voices = _webSpeechSynthesis!.getVoices();
      html.SpeechSynthesisVoice? chineseVoice;
      
      // 优先寻找 Google 中文语音，其次是其他中文语音
      try {
          chineseVoice = voices.firstWhere((voice) => 
            voice.name != null && voice.name!.contains('Google') && voice.lang != null && voice.lang!.contains('zh-CN'),
            orElse: () => voices.firstWhere((voice) => 
                voice.lang != null && (voice.lang == 'zh-CN' || voice.lang == 'zh_CN'),
                orElse: () => voices.firstWhere((voice) => 
                    voice.lang != null && voice.lang!.startsWith('zh'),
                    orElse: () => voices.first
                )
            )
          );
      } catch (e) {
         // Fallback if no voices found or filtering fails
         if (voices.isNotEmpty) chineseVoice = voices.first;
      }

      if (chineseVoice != null) {
        utterance.voice = chineseVoice;
        print('✅ 使用语音: ${chineseVoice.name}');
      }
      
      utterance.onError.listen((event) {
        String errorMsg = 'Unknown';
        try {
          // Temporarily use dynamic to access error property to avoid type issues
          final dynamic dynamicEvent = event;
          errorMsg = dynamicEvent.error?.toString() ?? 'Unknown';
        } catch (_) {}
        
        print('❌ TTS 播放错误: $errorMsg');
        _showSpeechFallback(text, isError: true);
      });
      
      _webSpeechSynthesis!.speak(utterance);
    } catch (e) {
      print('❌ Web 语音播放异常: $e');
      _showSpeechFallback(text, isError: true);
    }
  }
  
  void _showSpeechFallback(String text, {bool isError = false}) {
    final speechBox = html.DivElement()
      ..className = 'flutter-speech-box'
      ..style.cssText = '''
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: linear-gradient(135deg, ${isError ? '#ef4444 0%, #b91c1c' : '#667eea 0%, #764ba2'} 100%);
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
        cursor: ${isError ? 'pointer' : 'default'};
      '''
      ..innerHtml = '''
        <div style="display: flex; align-items: center; justify-content: center; margin-bottom: 16px;">
          <div style="width: 16px; height: 16px; background: ${isError ? '#ffffff' : '#10b981'}; border-radius: 50%; margin-right: 12px; animation: pulse 1.5s infinite;"></div>
          <div style="font-weight: 700; font-size: 18px;">${isError ? '⚠️ 点击重试播放' : '🎤 语音播报'}</div>
        </div>
        <div style="font-size: 16px; line-height: 1.6; opacity: 0.95; font-weight: 500;">$text</div>
        ${isError ? '<div style="font-size: 12px; margin-top: 8px; opacity: 0.8;">(浏览器自动播放受限，请点击此处手动播放)</div>' : ''}
      ''';
    
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
    
    if (isError) {
      speechBox.onClick.listen((_) {
        speechBox.remove();
        style.remove();
        speak(text); // Retry with user gesture
      });
      
      // Auto-close error after 10s to prevent stuck UI
      Future.delayed(const Duration(seconds: 10), () {
        if (speechBox.isConnected == true) {
           speechBox.remove();
           style.remove();
        }
      });
    } else {
      Future.delayed(const Duration(seconds: 4), () {
        speechBox.style.animation = 'speechFadeIn 0.3s ease-in reverse';
        Future.delayed(const Duration(milliseconds: 300), () {
          speechBox.remove();
          style.remove();
        });
      });
    }
  }
  
  Future<void> stop() async {
    try {
      _webSpeechSynthesis?.cancel();
    } catch (e) {
      print('停止语音失败: $e');
    }
  }
  
  Future<void> pause() async {
    try {
      _webSpeechSynthesis?.pause();
    } catch (e) {
      print('暂停语音失败: $e');
    }
  }
}