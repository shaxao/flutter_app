// Background Voice Service - 专门处理锁屏/后台语音播放

class BackgroundVoiceService {
  constructor() {
    this.audioContext = null;
    this.keepAliveAudio = null;
    this.mediaSession = null;
    this.wakeLock = null;
    this.isBackgroundMode = false;

    // 音频缓存
    this.audioCache = new Map();
    this.preloadedAudios = new Map();

    // 播放策略优先级
    this.playbackStrategies = [
      'mediaSessionAudio',    // 最高优先级：Media Session API
      'keepAliveAudio',       // 保活音频
      'webAudioAPI',          // Web Audio API
      'htmlAudio',            // HTML Audio
      'speechSynthesis',      // 语音合成（最后备选）
    ];

    this.init();
  }

  async init() {
    console.log('[BackgroundVoice] Initializing background voice service...');

    // 1. 设置 Media Session API（关键！）
    await this.setupMediaSession();

    // 2. 创建保活音频
    await this.createKeepAliveAudio();

    // 3. 设置页面可见性监听
    this.setupVisibilityListener();

    // 4. 设置唤醒锁
    await this.requestWakeLock();

    console.log('[BackgroundVoice] Background voice service initialized');
  }

  async setupMediaSession() {
    if (!('mediaSession' in navigator)) {
      console.warn('[BackgroundVoice] Media Session API not supported');
      return;
    }

    try {
      this.mediaSession = navigator.mediaSession;

      // 设置媒体元数据
      this.mediaSession.metadata = new MediaMetadata({
        title: '食材过期提醒',
        artist: 'VoiceFlow智能助手',
        album: '语音提醒系统',
        artwork: [
          { src: '/icons/Icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/Icon-512.png', sizes: '512x512', type: 'image/png' }
        ]
      });

      // 设置播放状态
      this.mediaSession.playbackState = 'playing';

      // 设置动作处理器
      this.mediaSession.setActionHandler('play', () => {
        console.log('[BackgroundVoice] Media Session play action');
        this.resumeKeepAlive();
      });

      this.mediaSession.setActionHandler('pause', () => {
        console.log('[BackgroundVoice] Media Session pause action');
        // 不真正暂停，保持活跃状态
      });

      console.log('[BackgroundVoice] Media Session API setup complete');
    } catch (error) {
      console.error('[BackgroundVoice] Media Session setup failed:', error);
    }
  }

  async createKeepAliveAudio() {
    try {
      // 创建一个极短的静音音频文件（Base64编码）
      const silentAudioData = 'data:audio/wav;base64,UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqFbF1fdJivrJBhNjVgodDbq2EcBj+a2/LDciUFLIHO8tiJNwgZaLvt559NEAxQp+PwtmMcBjiR1/LMeSwFJHfH8N2QQAoUXrTp66hVFApGn+DyvmwhBSuBzvLZiTYIG2m98OScTgwOUarm7blmGgU7k9n1unEiBC13yO/eizEIHWq+8+OWT';

      this.keepAliveAudio = new Audio(silentAudioData);
      this.keepAliveAudio.loop = true;
      this.keepAliveAudio.volume = 0.01; // 极低音量
      this.keepAliveAudio.preload = 'auto';

      // 设置音频属性以保持后台播放
      this.keepAliveAudio.setAttribute('playsinline', '');
      this.keepAliveAudio.setAttribute('webkit-playsinline', '');

      // 监听音频事件
      this.keepAliveAudio.addEventListener('ended', () => {
        console.log('[BackgroundVoice] Keep-alive audio ended, restarting...');
        this.resumeKeepAlive();
      });

      this.keepAliveAudio.addEventListener('pause', () => {
        console.log('[BackgroundVoice] Keep-alive audio paused, resuming...');
        setTimeout(() => this.resumeKeepAlive(), 100);
      });

      console.log('[BackgroundVoice] Keep-alive audio created');
    } catch (error) {
      console.error('[BackgroundVoice] Failed to create keep-alive audio:', error);
    }
  }

  async resumeKeepAlive() {
    if (!this.keepAliveAudio) return;

    try {
      await this.keepAliveAudio.play();
      console.log('[BackgroundVoice] Keep-alive audio resumed');
    } catch (error) {
      console.warn('[BackgroundVoice] Keep-alive audio play failed:', error);
    }
  }

  setupVisibilityListener() {
    document.addEventListener('visibilitychange', () => {
      this.isBackgroundMode = document.hidden;
      console.log(`[BackgroundVoice] Page visibility changed: ${this.isBackgroundMode ? 'background' : 'foreground'}`);

      if (this.isBackgroundMode) {
        // 进入后台，确保保活音频运行
        this.resumeKeepAlive();
      }
    });
  }

  async requestWakeLock() {
    if ('wakeLock' in navigator) {
      try {
        this.wakeLock = await navigator.wakeLock.request('screen');
        console.log('[BackgroundVoice] Wake lock acquired');

        this.wakeLock.addEventListener('release', () => {
          console.log('[BackgroundVoice] Wake lock released');
        });
      } catch (error) {
        console.warn('[BackgroundVoice] Wake lock request failed:', error);
      }
    }
  }

  // 核心方法：后台语音播放
  async speakInBackground(text, options = {}) {
    console.log(`[BackgroundVoice] Speaking in background: "${text}"`);

    // 确保保活音频运行
    await this.resumeKeepAlive();

    // 尝试多种播放策略
    for (const strategy of this.playbackStrategies) {
      try {
        const success = await this.tryPlaybackStrategy(strategy, text, options);
        if (success) {
          console.log(`[BackgroundVoice] Successfully played using ${strategy}`);
          return true;
        }
      } catch (error) {
        console.warn(`[BackgroundVoice] Strategy ${strategy} failed:`, error);
      }
    }

    console.error('[BackgroundVoice] All playback strategies failed');
    return false;
  }

  async tryPlaybackStrategy(strategy, text, options) {
    switch (strategy) {
      case 'mediaSessionAudio':
        return await this.playWithMediaSession(text, options);

      case 'keepAliveAudio':
        return await this.playWithKeepAliveAudio(text, options);

      case 'webAudioAPI':
        return await this.playWithWebAudio(text, options);

      case 'htmlAudio':
        return await this.playWithHTMLAudio(text, options);

      case 'speechSynthesis':
        return await this.playWithSpeechSynthesis(text, options);

      default:
        return false;
    }
  }

  async playWithMediaSession(text, options) {
    if (!this.mediaSession) return false;

    try {
      // 获取TTS音频URL
      const audioUrl = await this.getTTSAudioUrl(text, options);
      if (!audioUrl) return false;

      // 创建音频元素
      const audio = new Audio(audioUrl);
      audio.volume = options.volume || 1.0;

      // 更新Media Session元数据
      this.mediaSession.metadata = new MediaMetadata({
        title: '食材过期提醒',
        artist: 'VoiceFlow智能助手',
        album: text.substring(0, 50),
        artwork: [
          { src: '/icons/Icon-192.png', sizes: '192x192', type: 'image/png' }
        ]
      });

      // 播放音频
      await audio.play();

      return new Promise((resolve) => {
        audio.addEventListener('ended', () => {
          console.log('[BackgroundVoice] Media Session audio ended');
          resolve(true);
        });

        audio.addEventListener('error', (e) => {
          console.error('[BackgroundVoice] Media Session audio error:', e);
          resolve(false);
        });
      });

    } catch (error) {
      console.error('[BackgroundVoice] Media Session playback failed:', error);
      return false;
    }
  }

  async playWithKeepAliveAudio(text, options) {
    if (!this.keepAliveAudio) return false;

    try {
      // 获取TTS音频URL
      const audioUrl = await this.getTTSAudioUrl(text, options);
      if (!audioUrl) return false;

      // 暂时停止保活音频
      this.keepAliveAudio.pause();

      // 更换音频源
      const originalSrc = this.keepAliveAudio.src;
      this.keepAliveAudio.src = audioUrl;
      this.keepAliveAudio.loop = false;
      this.keepAliveAudio.volume = options.volume || 1.0;

      await this.keepAliveAudio.play();

      return new Promise((resolve) => {
        const onEnded = () => {
          console.log('[BackgroundVoice] Keep-alive audio TTS ended');

          // 恢复保活音频
          this.keepAliveAudio.src = originalSrc;
          this.keepAliveAudio.loop = true;
          this.keepAliveAudio.volume = 0.01;
          this.resumeKeepAlive();

          this.keepAliveAudio.removeEventListener('ended', onEnded);
          resolve(true);
        };

        this.keepAliveAudio.addEventListener('ended', onEnded);

        setTimeout(() => {
          this.keepAliveAudio.removeEventListener('ended', onEnded);
          resolve(false);
        }, 30000); // 30秒超时
      });

    } catch (error) {
      console.error('[BackgroundVoice] Keep-alive audio playback failed:', error);
      return false;
    }
  }

  async playWithWebAudio(text, options) {
    try {
      if (!this.audioContext) {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      }

      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }

      const audioUrl = await this.getTTSAudioUrl(text, options);
      if (!audioUrl) return false;

      const response = await fetch(audioUrl);
      const arrayBuffer = await response.arrayBuffer();
      const audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer);

      const source = this.audioContext.createBufferSource();
      const gainNode = this.audioContext.createGain();

      source.buffer = audioBuffer;
      gainNode.gain.value = options.volume || 1.0;

      source.connect(gainNode);
      gainNode.connect(this.audioContext.destination);

      source.start();

      return new Promise((resolve) => {
        source.addEventListener('ended', () => {
          console.log('[BackgroundVoice] Web Audio playback ended');
          resolve(true);
        });

        setTimeout(() => resolve(false), 30000);
      });

    } catch (error) {
      console.error('[BackgroundVoice] Web Audio playback failed:', error);
      return false;
    }
  }

  async playWithHTMLAudio(text, options) {
    try {
      const audioUrl = await this.getTTSAudioUrl(text, options);
      if (!audioUrl) return false;

      const audio = new Audio(audioUrl);
      audio.volume = options.volume || 1.0;
      audio.preload = 'auto';

      await audio.play();

      return new Promise((resolve) => {
        audio.addEventListener('ended', () => {
          console.log('[BackgroundVoice] HTML Audio playback ended');
          resolve(true);
        });

        audio.addEventListener('error', (e) => {
          console.error('[BackgroundVoice] HTML Audio error:', e);
          resolve(false);
        });

        setTimeout(() => resolve(false), 30000);
      });

    } catch (error) {
      console.error('[BackgroundVoice] HTML Audio playback failed:', error);
      return false;
    }
  }

  async playWithSpeechSynthesis(text, options) {
    if (!('speechSynthesis' in window)) return false;

    try {
      return new Promise((resolve) => {
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.volume = options.volume || 1.0;
        utterance.rate = options.rate || 1.0;
        utterance.pitch = options.pitch || 1.0;
        utterance.lang = 'zh-CN';

        utterance.onend = () => {
          console.log('[BackgroundVoice] Speech Synthesis ended');
          resolve(true);
        };

        utterance.onerror = (e) => {
          console.error('[BackgroundVoice] Speech Synthesis error:', e);
          resolve(false);
        };

        speechSynthesis.speak(utterance);

        setTimeout(() => resolve(false), 30000);
      });

    } catch (error) {
      console.error('[BackgroundVoice] Speech Synthesis failed:', error);
      return false;
    }
  }

  async getTTSAudioUrl(text, options = {}) {
    try {
      // 检查缓存
      const cacheKey = `${text}-${JSON.stringify(options)}`;
      if (this.audioCache.has(cacheKey)) {
        return this.audioCache.get(cacheKey);
      }

      // 调用后端TTS API
      const response = await fetch('https://service.muhuo.site/api/v1/tts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: text,
          voice_model: options.voiceModel || 'tts-1',
          format: 'mp3'
        })
      });

      if (response.ok) {
        const blob = await response.blob();
        const audioUrl = URL.createObjectURL(blob);

        // 缓存音频URL
        this.audioCache.set(cacheKey, audioUrl);

        // 清理过期缓存
        if (this.audioCache.size > 50) {
          const firstKey = this.audioCache.keys().next().value;
          URL.revokeObjectURL(this.audioCache.get(firstKey));
          this.audioCache.delete(firstKey);
        }

        return audioUrl;
      }

      return null;

    } catch (error) {
      console.error('[BackgroundVoice] TTS API failed:', error);
      return null;
    }
  }

  // 预加载音频（提前准备）
  async preloadAudio(text, options = {}) {
    try {
      const audioUrl = await this.getTTSAudioUrl(text, options);
      if (audioUrl) {
        const audio = new Audio(audioUrl);
        audio.preload = 'auto';
        this.preloadedAudios.set(text, audio);
        console.log(`[BackgroundVoice] Preloaded audio for: "${text}"`);
      }
    } catch (error) {
      console.error('[BackgroundVoice] Preload failed:', error);
    }
  }

  // 清理资源
  cleanup() {
    if (this.keepAliveAudio) {
      this.keepAliveAudio.pause();
      this.keepAliveAudio = null;
    }

    if (this.audioContext) {
      this.audioContext.close();
      this.audioContext = null;
    }

    if (this.wakeLock) {
      this.wakeLock.release();
      this.wakeLock = null;
    }

    // 清理缓存
    for (const url of this.audioCache.values()) {
      URL.revokeObjectURL(url);
    }
    this.audioCache.clear();
    this.preloadedAudios.clear();
  }
}

// 全局实例
window.backgroundVoiceService = new BackgroundVoiceService();

// 导出函数供其他模块使用
window.speakInBackground = (text, options) => {
  return window.backgroundVoiceService.speakInBackground(text, options);
};

window.preloadBackgroundAudio = (text, options) => {
  return window.backgroundVoiceService.preloadAudio(text, options);
};

console.log('[BackgroundVoice] Background Voice Service loaded');