import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import '../audio_playback_system.dart';
import '../audio_config.dart';

/// Web平台音频适配器
class WebAudioAdapter extends BaseAudioAdapter {
  html.AudioElement? _audioElement;
  bool _initialized = false;
  bool _userInteractionRequired = true;

  @override
  String get platformName => 'web';

  @override
  bool get isSupported => kIsWeb;

  @override
  List<PlaybackStrategy> get supportedStrategies => [
    PlaybackStrategy.mediaSessionAudio,
    PlaybackStrategy.backgroundAudio,
    PlaybackStrategy.webAudioAPI,
    PlaybackStrategy.htmlAudio,
    PlaybackStrategy.systemTTS,
  ];

  /// 初始化Web适配器
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 检查浏览器支持
      _checkBrowserSupport();
      
      // 初始化Media Session API
      await _initializeMediaSession();
      
      // 设置用户交互监听
      _setupUserInteractionListener();
      
      _initialized = true;
      print('✅ Web音频适配器初始化完成');
    } catch (e) {
      print('❌ Web音频适配器初始化失败: $e');
      setError('初始化失败: $e');
    }
  }

  /// 检查浏览器支持
  void _checkBrowserSupport() {
    final navigator = html.window.navigator;
    
    // 检查Media Session API支持
    if (js.context.hasProperty('navigator') && 
        js.context['navigator'].hasProperty('mediaSession')) {
      print('✅ 浏览器支持Media Session API');
    } else {
      print('⚠️ 浏览器不支持Media Session API');
    }
    
    // 检查Service Worker支持
    if (navigator.serviceWorker != null) {
      print('✅ 浏览器支持Service Worker');
    } else {
      print('⚠️ 浏览器不支持Service Worker');
    }
    
    // 检查Web Audio API支持
    if (js.context.hasProperty('AudioContext') || 
        js.context.hasProperty('webkitAudioContext')) {
      print('✅ 浏览器支持Web Audio API');
    } else {
      print('⚠️ 浏览器不支持Web Audio API');
    }
  }

  /// 初始化Media Session API
  Future<void> _initializeMediaSession() async {
    try {
      if (js.context.hasProperty('navigator') && 
          js.context['navigator'].hasProperty('mediaSession')) {
        
        // 设置Media Session metadata
        js.context.callMethod('eval', ['''
          if ('mediaSession' in navigator) {
            navigator.mediaSession.metadata = new MediaMetadata({
              title: '语音提醒',
              artist: '提醒系统',
              album: '语音提醒',
            });
          }
        ''']);
        
        print('✅ Media Session API初始化完成');
      }
    } catch (e) {
      print('⚠️ Media Session API初始化失败: $e');
    }
  }

  /// 设置用户交互监听
  void _setupUserInteractionListener() {
    // 监听用户交互以解除音频播放限制
    html.document.addEventListener('click', (_) {
      _userInteractionRequired = false;
    });
    
    html.document.addEventListener('touchstart', (_) {
      _userInteractionRequired = false;
    });
  }

  @override
  Future<PlaybackResult> playAudio(
    String filePath, {
    PlaybackConfig? config,
  }) async {
    if (!_initialized) await initialize();

    config ??= PlaybackConfig.defaultConfig();

    // 检查用户交互要求
    if (_userInteractionRequired) {
      print('⚠️ 需要用户交互才能播放音频');
      setError('需要用户交互');
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
      case PlaybackStrategy.mediaSessionAudio:
        return await _playWithMediaSession(filePath, config);
      
      case PlaybackStrategy.backgroundAudio:
        return await _playAsBackgroundAudio(filePath, config);
      
      case PlaybackStrategy.webAudioAPI:
        return await _playWithWebAudioAPI(filePath, config);
      
      case PlaybackStrategy.htmlAudio:
        return await _playWithHTMLAudio(filePath, config);
      
      case PlaybackStrategy.systemTTS:
        return await _playWithSystemTTS(filePath, config);
      
      default:
        return PlaybackResult.notSupported;
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

      // 创建音频元素
      _audioElement = html.AudioElement(filePath);
      _audioElement!.volume = config.volume;
      _audioElement!.preload = 'auto';

      // 设置Media Session
      js.context.callMethod('eval', ['''
        if ('mediaSession' in navigator) {
          navigator.mediaSession.playbackState = 'playing';
          navigator.mediaSession.setActionHandler('play', function() {
            console.log('Media Session: play');
          });
          navigator.mediaSession.setActionHandler('pause', function() {
            console.log('Media Session: pause');
          });
        }
      ''']);

      // 播放音频
      await _audioElement!.play();
      
      // 设置播放完成监听
      _audioElement!.onEnded.listen((_) {
        updateStatus(PlaybackStatus(
          state: PlaybackState.completed,
          strategy: PlaybackStrategy.mediaSessionAudio,
          timestamp: DateTime.now(),
        ));
      });

      print('📱 Web Media Session播放成功');
      return PlaybackResult.success;
    } catch (e) {
      print('❌ Web Media Session播放异常: $e');
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

      // 通过Service Worker播放后台音频
      if (html.window.navigator.serviceWorker != null) {
        final registration = await html.window.navigator.serviceWorker!.ready;
        
        // 发送播放消息到Service Worker
        registration.active?.postMessage({
          'type': 'PLAY_AUDIO',
          'filePath': filePath,
          'volume': config.volume,
        });

        print('🔄 已发送后台音频播放请求到Service Worker');
        return PlaybackResult.success;
      } else {
        // 降级到HTML Audio
        return await _playWithHTMLAudio(filePath, config);
      }
    } catch (e) {
      print('❌ Web后台音频播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 使用Web Audio API播放
  Future<PlaybackResult> _playWithWebAudioAPI(
    String filePath,
    PlaybackConfig config,
  ) async {
    try {
      updateStatus(PlaybackStatus(
        state: PlaybackState.loading,
        strategy: PlaybackStrategy.webAudioAPI,
        timestamp: DateTime.now(),
      ));

      // 使用Web Audio API播放
      js.context.callMethod('eval', ['''
        (async function() {
          try {
            const audioContext = new (window.AudioContext || window.webkitAudioContext)();
            const response = await fetch('$filePath');
            const arrayBuffer = await response.arrayBuffer();
            const audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
            
            const source = audioContext.createBufferSource();
            const gainNode = audioContext.createGain();
            
            source.buffer = audioBuffer;
            gainNode.gain.value = ${config.volume};
            
            source.connect(gainNode);
            gainNode.connect(audioContext.destination);
            
            source.start(0);
            
            source.onended = function() {
              console.log('Web Audio API播放完成');
            };
            
            return true;
          } catch (error) {
            console.error('Web Audio API播放失败:', error);
            return false;
          }
        })();
      ''']);

      print('🎵 Web Audio API播放启动');
      return PlaybackResult.success;
    } catch (e) {
      print('❌ Web Audio API播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  /// 使用HTML Audio播放
  Future<PlaybackResult> _playWithHTMLAudio(
    String filePath,
    PlaybackConfig config,
  ) async {
    try {
      updateStatus(PlaybackStatus(
        state: PlaybackState.loading,
        strategy: PlaybackStrategy.htmlAudio,
        timestamp: DateTime.now(),
      ));

      // 创建并播放HTML Audio元素
      _audioElement = html.AudioElement(filePath);
      _audioElement!.volume = config.volume;
      _audioElement!.preload = 'auto';

      // 设置播放完成监听
      _audioElement!.onEnded.listen((_) {
        updateStatus(PlaybackStatus(
          state: PlaybackState.completed,
          strategy: PlaybackStrategy.htmlAudio,
          timestamp: DateTime.now(),
        ));
      });

      // 设置错误监听
      _audioElement!.onError.listen((error) {
        setError('HTML Audio播放错误: $error');
      });

      await _audioElement!.play();
      
      print('🎵 HTML Audio播放成功');
      return PlaybackResult.success;
    } catch (e) {
      print('❌ HTML Audio播放异常: $e');
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

      // 使用Web Speech API
      if (js.context.hasProperty('speechSynthesis')) {
        js.context.callMethod('eval', ['''
          const utterance = new SpeechSynthesisUtterance('语音提醒');
          utterance.volume = ${config.volume};
          utterance.rate = 1.0;
          utterance.pitch = 1.0;
          
          utterance.onend = function() {
            console.log('Web TTS播放完成');
          };
          
          speechSynthesis.speak(utterance);
        ''']);

        print('🗣️ Web TTS播放成功');
        return PlaybackResult.success;
      } else {
        print('❌ 浏览器不支持Speech Synthesis API');
        return PlaybackResult.notSupported;
      }
    } catch (e) {
      print('❌ Web TTS播放异常: $e');
      return PlaybackResult.failed;
    }
  }

  @override
  Future<void> stopPlayback() async {
    try {
      if (_audioElement != null) {
        _audioElement!.pause();
        _audioElement!.currentTime = 0;
        _audioElement = null;
      }

      // 停止TTS
      if (js.context.hasProperty('speechSynthesis')) {
        js.context.callMethod('eval', ['speechSynthesis.cancel();']);
      }

      // 通知Service Worker停止播放
      if (html.window.navigator.serviceWorker != null) {
        final registration = await html.window.navigator.serviceWorker!.ready;
        registration.active?.postMessage({
          'type': 'STOP_AUDIO',
        });
      }

      updateStatus(PlaybackStatus(
        state: PlaybackState.stopped,
        timestamp: DateTime.now(),
      ));
      
      print('⏹️ Web音频播放已停止');
    } catch (e) {
      print('❌ 停止播放失败: $e');
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await stopPlayback();
      _initialized = false;
      
      await super.dispose();
      print('✅ Web音频适配器资源已释放');
    } catch (e) {
      print('❌ Web适配器释放失败: $e');
    }
  }
}