// Lockscreen Voice Service - 专门解决锁屏语音播放问题

class LockscreenVoiceService {
  constructor() {
    this.isLocked = false;
    this.pendingVoice = null;
    this.audioContext = null;
    this.mediaSource = null;
    this.wakeLock = null;
    this.notificationAudio = null;

    // 检测设备类型
    this.isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
    this.isAndroid = /Android/.test(navigator.userAgent);
    this.isMobile = this.isIOS || this.isAndroid;

    console.log(`[LockscreenVoice] Device: iOS=${this.isIOS}, Android=${this.isAndroid}, Mobile=${this.isMobile}`);

    this.init();
  }

  async init() {
    console.log('[LockscreenVoice] Initializing lockscreen voice service...');

    // 1. 设置页面可见性监听
    this.setupVisibilityListener();

    // 2. 设置屏幕方向锁定
    await this.setupScreenLock();

    // 3. 创建专用的通知音频
    await this.createNotificationAudio();

    // 4. 设置Service Worker消息监听
    this.setupServiceWorkerListener();

    // 5. 设置用户交互监听
    this.setupUserInteractionListener();

    console.log('[LockscreenVoice] Lockscreen voice service initialized');
  }

  setupVisibilityListener() {
    document.addEventListener('visibilitychange', () => {
      this.isLocked = document.hidden;
      console.log(`[LockscreenVoice] Screen state: ${this.isLocked ? 'LOCKED/BACKGROUND' : 'ACTIVE'}`);

      if (!this.isLocked && this.pendingVoice) {
        // 屏幕解锁时播放待播放的语音
        console.log('[LockscreenVoice] Screen unlocked, playing pending voice...');
        this.playVoiceImmediate(this.pendingVoice);
        this.pendingVoice = null;
      }
    });
  }

  async setupScreenLock() {
    // 尝试获取屏幕唤醒锁
    if ('wakeLock' in navigator) {
      try {
        this.wakeLock = await navigator.wakeLock.request('screen');
        console.log('[LockscreenVoice] Screen wake lock acquired');

        this.wakeLock.addEventListener('release', () => {
          console.log('[LockscreenVoice] Screen wake lock released');
        });
      } catch (error) {
        console.warn('[LockscreenVoice] Wake lock failed:', error);
      }
    }
  }

  async createNotificationAudio() {
    try {
      // 创建一个专门用于通知的音频元素
      this.notificationAudio = new Audio();
      this.notificationAudio.preload = 'auto';
      this.notificationAudio.volume = 1.0;

      // 设置音频属性以支持后台播放
      this.notificationAudio.setAttribute('playsinline', '');
      this.notificationAudio.setAttribute('webkit-playsinline', '');

      // 监听音频事件
      this.notificationAudio.addEventListener('canplaythrough', () => {
        console.log('[LockscreenVoice] Notification audio ready');
      });

      this.notificationAudio.addEventListener('ended', () => {
        console.log('[LockscreenVoice] Notification audio ended');
      });

      console.log('[LockscreenVoice] Notification audio created');
    } catch (error) {
      console.error('[LockscreenVoice] Failed to create notification audio:', error);
    }
  }

  setupServiceWorkerListener() {
    // 监听Service Worker消息
    navigator.serviceWorker.addEventListener('message', (event) => {
      if (event.data && event.data.type === 'PLAY_LOCKSCREEN_VOICE') {
        console.log('[LockscreenVoice] Received lockscreen voice request:', event.data);
        this.handleLockscreenVoiceRequest(event.data.payload);
      }
    });
  }

  setupUserInteractionListener() {
    // 在用户交互时预热音频系统
    const interactionEvents = ['touchstart', 'touchend', 'click', 'keydown'];

    const warmupAudio = () => {
      this.warmupAudioSystem();
      // 只需要预热一次
      interactionEvents.forEach(event => {
        document.removeEventListener(event, warmupAudio);
      });
    };

    interactionEvents.forEach(event => {
      document.addEventListener(event, warmupAudio, { once: true });
    });
  }

  async warmupAudioSystem() {
    try {
      console.log('[LockscreenVoice] Warming up audio system...');

      // 预热AudioContext
      if (!this.audioContext) {
        this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
      }

      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }

      // 预热通知音频
      if (this.notificationAudio) {
        this.notificationAudio.volume = 0.01;
        try {
          await this.notificationAudio.play();
          this.notificationAudio.pause();
          this.notificationAudio.volume = 1.0;
        } catch (e) {
          console.warn('[LockscreenVoice] Audio warmup play failed:', e);
        }
      }

      console.log('[LockscreenVoice] Audio system warmed up');
    } catch (error) {
      console.error('[LockscreenVoice] Audio warmup failed:', error);
    }
  }

  async handleLockscreenVoiceRequest(payload) {
    const text = payload.text || payload.body || payload.content;
    if (!text) return;

    console.log(`[LockscreenVoice] Handling lockscreen voice: "${text}"`);

    if (this.isLocked) {
      // 锁屏状态：使用特殊策略
      await this.playLockscreenVoice(text);
    } else {
      // 非锁屏状态：直接播放
      await this.playVoiceImmediate(text);
    }
  }

  async playLockscreenVoice(text) {
    console.log(`[LockscreenVoice] Playing lockscreen voice: "${text}"`);

    // 策略1: 尝试通过通知音频播放
    const success1 = await this.tryNotificationAudioPlay(text);
    if (success1) return;

    // 策略2: 尝试通过振动 + 通知提示用户
    await this.tryVibrateAndNotify(text);

    // 策略3: 保存为待播放，等待屏幕解锁
    this.pendingVoice = text;
    console.log('[LockscreenVoice] Voice saved as pending for screen unlock');
  }

  async tryNotificationAudioPlay(text) {
    try {
      console.log('[LockscreenVoice] Trying notification audio play...');

      // 获取TTS音频
      const audioUrl = await this.getTTSAudio(text);
      if (!audioUrl) return false;

      // 设置音频源
      this.notificationAudio.src = audioUrl;

      // 尝试播放
      await this.notificationAudio.play();

      console.log('[LockscreenVoice] Notification audio play successful');
      return true;

    } catch (error) {
      console.warn('[LockscreenVoice] Notification audio play failed:', error);
      return false;
    }
  }

  async tryVibrateAndNotify(text) {
    try {
      console.log('[LockscreenVoice] Trying vibrate and notify...');

      // 强烈振动提醒
      if ('vibrate' in navigator) {
        navigator.vibrate([500, 200, 500, 200, 500, 200, 500]);
      }

      // 显示持久通知
      if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
        const registration = await navigator.serviceWorker.ready;

        await registration.showNotification('🔊 语音提醒 - 请解锁屏幕', {
          body: `${text}\n\n👆 点击播放语音或解锁屏幕自动播放`,
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          tag: 'lockscreen-voice-' + Date.now(),
          requireInteraction: true,
          persistent: true,
          vibrate: [500, 200, 500, 200, 500],
          data: {
            action: 'play_voice',
            text: text,
            timestamp: Date.now()
          },
          actions: [
            {
              action: 'play',
              title: '🔊 播放语音'
            },
            {
              action: 'dismiss',
              title: '关闭'
            }
          ]
        });

        console.log('[LockscreenVoice] Persistent notification shown');
      }

    } catch (error) {
      console.error('[LockscreenVoice] Vibrate and notify failed:', error);
    }
  }

  async playVoiceImmediate(text) {
    try {
      console.log(`[LockscreenVoice] Playing voice immediately: "${text}"`);

      // 尝试多种播放方式
      const strategies = [
        () => this.tryTTSAudioPlay(text),
        () => this.trySpeechSynthesis(text),
        () => this.tryWebAudioPlay(text)
      ];

      for (const strategy of strategies) {
        try {
          const success = await strategy();
          if (success) {
            console.log('[LockscreenVoice] Voice play successful');
            return;
          }
        } catch (error) {
          console.warn('[LockscreenVoice] Strategy failed:', error);
        }
      }

      console.error('[LockscreenVoice] All voice play strategies failed');

    } catch (error) {
      console.error('[LockscreenVoice] Voice play failed:', error);
    }
  }

  async tryTTSAudioPlay(text) {
    try {
      const audioUrl = await this.getTTSAudio(text);
      if (!audioUrl) return false;

      const audio = new Audio(audioUrl);
      audio.volume = 1.0;
      await audio.play();

      return new Promise((resolve) => {
        audio.addEventListener('ended', () => resolve(true));
        audio.addEventListener('error', () => resolve(false));
        setTimeout(() => resolve(false), 30000);
      });

    } catch (error) {
      console.warn('[LockscreenVoice] TTS audio play failed:', error);
      return false;
    }
  }

  async trySpeechSynthesis(text) {
    if (!('speechSynthesis' in window)) return false;

    try {
      return new Promise((resolve) => {
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.volume = 1.0;
        utterance.rate = 1.0;
        utterance.lang = 'zh-CN';

        utterance.onend = () => resolve(true);
        utterance.onerror = () => resolve(false);

        speechSynthesis.speak(utterance);

        setTimeout(() => resolve(false), 30000);
      });

    } catch (error) {
      console.warn('[LockscreenVoice] Speech synthesis failed:', error);
      return false;
    }
  }

  async tryWebAudioPlay(text) {
    try {
      if (!this.audioContext) return false;

      const audioUrl = await this.getTTSAudio(text);
      if (!audioUrl) return false;

      const response = await fetch(audioUrl);
      const arrayBuffer = await response.arrayBuffer();
      const audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer);

      const source = this.audioContext.createBufferSource();
      source.buffer = audioBuffer;
      source.connect(this.audioContext.destination);
      source.start();

      return new Promise((resolve) => {
        source.addEventListener('ended', () => resolve(true));
        setTimeout(() => resolve(false), 30000);
      });

    } catch (error) {
      console.warn('[LockscreenVoice] Web audio play failed:', error);
      return false;
    }
  }

  async getTTSAudio(text) {
    try {
      const response = await fetch('https://service.muhuo.site/api/v1/tts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          text: text,
          voice_model: 'tts-1',
          format: 'wav'
        })
      });

      if (response.ok) {
        const blob = await response.blob();
        return URL.createObjectURL(blob);
      }

      return null;

    } catch (error) {
      console.error('[LockscreenVoice] TTS API failed:', error);
      return null;
    }
  }

  // 公共接口
  async speak(text) {
    if (this.isLocked) {
      await this.playLockscreenVoice(text);
    } else {
      await this.playVoiceImmediate(text);
    }
  }

  // 强制播放（忽略锁屏状态）
  async forceSpeak(text) {
    await this.playVoiceImmediate(text);
  }

  // 获取状态
  getStatus() {
    return {
      isLocked: this.isLocked,
      hasPendingVoice: !!this.pendingVoice,
      audioContextState: this.audioContext?.state || 'none',
      hasWakeLock: !!this.wakeLock,
      deviceType: {
        isIOS: this.isIOS,
        isAndroid: this.isAndroid,
        isMobile: this.isMobile
      }
    };
  }
}

// 全局实例
window.lockscreenVoiceService = new LockscreenVoiceService();

// 导出函数
window.speakLockscreen = (text) => {
  return window.lockscreenVoiceService.speak(text);
};

window.forceSpeakLockscreen = (text) => {
  return window.lockscreenVoiceService.forceSpeak(text);
};

console.log('[LockscreenVoice] Lockscreen Voice Service loaded');