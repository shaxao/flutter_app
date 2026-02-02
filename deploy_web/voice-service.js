// Flutter Web Voice Service - Based on od_web implementation

class FlutterWebVoiceService {
  constructor() {
    this.synth = typeof window !== 'undefined' ? window.speechSynthesis : null;
    this.isUnlocked = false;
    this.keepAliveAudio = null;
    this.keepAliveRetryCount = 0;
    this.MAX_KEEP_ALIVE_RETRIES = 10;

    // Platform detection
    this.isIOS = typeof navigator !== 'undefined' && /iPad|iPhone|iPod/.test(navigator.userAgent);
    this.isAndroid = typeof navigator !== 'undefined' && /Android/.test(navigator.userAgent);
    this.supportsPushManager = typeof window !== 'undefined' && 'PushManager' in window;
    this.supportsMediaSession = typeof navigator !== 'undefined' && 'mediaSession' in navigator;

    // Audio cache for TTS
    this.audioCache = new Map();
    this.maxCacheSize = 50;
    this.cacheExpiryMs = 30 * 60 * 1000; // 30 minutes

    // Performance metrics
    this.performanceMetrics = {
      totalSpeakCalls: 0,
      successfulSpeaks: 0,
      failedSpeaks: 0,
      cacheHits: 0,
      cacheMisses: 0,
      averageLatency: 0,
      latencies: []
    };

    console.log(`[VoiceService] Initialized on platform: iOS=${this.isIOS}, Android=${this.isAndroid}`);
  }

  /**
   * Unlocks audio on first user interaction to comply with browser policies
   * and starts a silent keep-alive loop.
   */
  unlock() {
    if (this.isUnlocked) return;

    console.log(`[VoiceService] Unlocking on platform: iOS=${this.isIOS}, Android=${this.isAndroid}`);

    // 1. Prime SpeechSynthesis (if available)
    if (this.synth) {
      const silent = new SpeechSynthesisUtterance(' ');
      silent.volume = 0;
      this.synth.speak(silent);
    } else {
      console.warn('[VoiceService] SpeechSynthesis not available');
    }

    // 2. Prime Audio context
    if (typeof window !== 'undefined' && (window.AudioContext || window.webkitAudioContext)) {
      const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      if (audioCtx.state === 'suspended') {
        audioCtx.resume();
      }
    }

    this.isUnlocked = true;
    this.startKeepAlive();

    // Set up Media Session for background stability (if supported)
    if (this.supportsMediaSession) {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: '语音提醒系统',
        artist: '萨莉亚',
        album: '后台运行中',
        artwork: [
          { src: '/icons/Icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icons/Icon-512.png', sizes: '512x512', type: 'image/png' }
        ]
      });

      // iOS specific: media session handlers to prevent suspension
      const handlers = [
        ['play', () => this.startKeepAlive()],
        ['pause', () => { }],
        ['nexttrack', () => { }],
        ['previoustrack', () => { }]
      ];

      for (const [action, handler] of handlers) {
        try {
          navigator.mediaSession.setActionHandler(action, handler);
        } catch (e) {
          console.warn(`Failed to set media session handler ${action}:`, e);
        }
      }
    } else {
      console.warn('[VoiceService] Media Session API not supported');
    }

    console.log('[VoiceService] Voice Service unlocked & Keep-alive started');
  }

  /**
   * Checks if the page is currently in background/hidden mode
   */
  isBackgroundMode() {
    return typeof document !== 'undefined' && document.visibilityState === 'hidden';
  }

  /**
   * Get platform and compatibility information
   */
  getPlatformInfo() {
    return {
      platform: this.isIOS ? 'iOS' : this.isAndroid ? 'Android' : 'Other',
      isIOS: this.isIOS,
      isAndroid: this.isAndroid,
      capabilities: {
        speechSynthesis: this.synth !== null,
        pushManager: this.supportsPushManager,
        mediaSession: this.supportsMediaSession,
        audioContext: typeof window !== 'undefined' && !!(window.AudioContext || window.webkitAudioContext),
        notification: typeof window !== 'undefined' && 'Notification' in window,
        serviceWorker: typeof navigator !== 'undefined' && 'serviceWorker' in navigator
      },
      recommendations: this.getRecommendations()
    };
  }

  /**
   * Get platform-specific recommendations
   */
  getRecommendations() {
    const recommendations = [];

    if (this.isIOS) {
      recommendations.push('iOS 系统：请确保已将应用添加到主屏幕');
      recommendations.push('iOS 系统：首次使用需点击授权按钮解锁语音');
      if (!this.supportsMediaSession) {
        recommendations.push('您的 iOS 版本可能不支持 Media Session API，后台播放可能受限');
      }
    }

    if (!this.supportsPushManager) {
      recommendations.push('您的浏览器不支持推送通知，后台提醒功能将受限');
    }

    if (!this.synth) {
      recommendations.push('您的浏览器不支持本地语音合成，将仅使用在线 TTS');
    }

    return recommendations;
  }

  /**
   * Preload audio for a reminder
   */
  async preloadAudio(text, config) {
    if (!text) return null;

    // Check if already cached
    if (this.audioCache.has(text)) {
      console.log(`[VoiceService] Audio already cached for "${text}"`);
      return text;
    }

    const url = config?.apiUrl || localStorage.getItem('openai_api_url') || '';
    const key = config?.apiKey || localStorage.getItem('openai_api_key');

    if (!key) {
      console.warn('[VoiceService] Cannot preload: OpenAI Key missing');
      return null;
    }

    try {
      console.log(`[VoiceService] Preloading audio for "${text}"`);
      const blob = await this.generateOpenAIAudio(text, url, key, config);
      this.setCachedAudio(text, blob);
      return text;
    } catch (e) {
      console.error('[VoiceService] Preload failed:', e);
      return null;
    }
  }

  /**
   * Set cached audio
   */
  setCachedAudio(text, blob) {
    // Clean up old cache if at limit
    if (this.audioCache.size >= this.maxCacheSize) {
      const firstKey = this.audioCache.keys().next().value;
      const entry = this.audioCache.get(firstKey);
      if (entry && entry.url) {
        URL.revokeObjectURL(entry.url);
      }
      this.audioCache.delete(firstKey);
    }

    const url = URL.createObjectURL(blob);
    this.audioCache.set(text, {
      url: url,
      blob: blob,
      timestamp: Date.now()
    });
  }

  /**
   * Get cached audio for a reminder
   */
  getCachedAudio(text) {
    const entry = this.audioCache.get(text);
    if (entry) {
      // Check if expired
      if (Date.now() - entry.timestamp > this.cacheExpiryMs) {
        URL.revokeObjectURL(entry.url);
        this.audioCache.delete(text);
        return null;
      }
      return entry;
    }
    return null;
  }

  /**
   * Clear expired cache entries
   */
  clearExpiredCache() {
    const now = Date.now();
    for (const [key, entry] of this.audioCache.entries()) {
      if (now - entry.timestamp > this.cacheExpiryMs) {
        URL.revokeObjectURL(entry.url);
        this.audioCache.delete(key);
      }
    }
  }

  /**
   * Plays a silent audio loop to prevent the OS from killing the PWA process
   */
  startKeepAlive() {
    if (this.keepAliveAudio && !this.keepAliveAudio.paused) {
      console.log('[VoiceService] Keep-alive already running');
      return;
    }

    // Standard 5s silent mp3 for more stability
    const silentMp3 = 'data:audio/mp3;base64,SUQzBAAAAAABAFRYWFgAAAASAAADbWFqb3JfYnJhbmQAZGFzaABUWFhYAAAAEwAAA21pbm9yX3ZlcnNpb24AMABUWFhYAAAAHAAAA2NvbXBhdGlibGVfYnJhbmRzAGlzbzZtcDQxAFRTU0UAAAAPAAADTGF2ZjYwLjMuMTAwAAAAAAAAAAAAAAD/80MUAAAAAAnSBAAABGZlZWQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf/zQxQBAAAACdIEAAAEZmVlZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB';

    if (!this.keepAliveAudio) {
      this.keepAliveAudio = new Audio(silentMp3);
      this.keepAliveAudio.loop = true;

      // iOS requires slightly higher volume to be "meaningful"
      this.keepAliveAudio.volume = this.isIOS ? 0.05 : 0.01;

      // Auto-resume if iOS kills it
      this.keepAliveAudio.onpause = () => {
        if (this.isUnlocked && this.keepAliveRetryCount < this.MAX_KEEP_ALIVE_RETRIES) {
          this.keepAliveRetryCount++;
          console.log(`[VoiceService] Keep-alive paused, attempting resume (retry ${this.keepAliveRetryCount}/${this.MAX_KEEP_ALIVE_RETRIES})`);
          setTimeout(() => {
            this.keepAliveAudio?.play().catch((e) => {
              console.warn('[VoiceService] Keep-alive resume failed:', e);
            });
          }, 100);
        } else if (this.keepAliveRetryCount >= this.MAX_KEEP_ALIVE_RETRIES) {
          console.error('[VoiceService] Keep-alive retry limit reached, stopping attempts');
        }
      };

      // Reset retry counter when successfully playing
      this.keepAliveAudio.onplay = () => {
        this.keepAliveRetryCount = 0;
        console.log('[VoiceService] Keep-alive playing successfully');
      };
    }

    this.keepAliveAudio.play().catch(e => {
      console.warn('[VoiceService] Keep-alive audio failed to play:', e);
    });
  }

  /**
   * Main speak function
   */
  async speak(text, config, retryCount = 0) {
    if (!text) return;

    const startTime = Date.now();
    this.performanceMetrics.totalSpeakCalls++;

    console.log(`[VoiceService] Starting speak: "${text}" (attempt ${retryCount + 1})`);

    // Ensure keep-alive is running
    if (this.isUnlocked) {
      this.startKeepAlive();
    }

    // iOS Lock Screen / Background Optimization:
    // If the page is hidden, system TTS (SpeechSynthesis) is almost certainly blocked.
    // We skip the 2s timeout and go straight to OpenAI TTS (Audio element) which is allowed during active media sessions.
    const isBackground = this.isBackgroundMode();

    if (isBackground) {
      console.log('[VoiceService] Background detected, skipping Local TTS and using OpenAI fallback...');
    } else {
      // 1. Try Local TTS
      try {
        console.log('[VoiceService] Attempting Local TTS...');
        const success = await this.speakLocal(text);
        if (success) {
          const latency = Date.now() - startTime;
          this.recordSuccess(latency);
          console.log('[VoiceService] Local TTS Success');
          return;
        }
        console.log('[VoiceService] Local TTS returned false, falling back...');
      } catch (e) {
        console.warn('[VoiceService] Local TTS Exception:', e);
      }
    }

    // 2. Fallback to OpenAI TTS
    const url = config?.apiUrl || localStorage.getItem('openai_api_url') || '';
    const key = config?.apiKey || localStorage.getItem('openai_api_key');

    if (key) {
      try {
        console.log('[VoiceService] Attempting OpenAI TTS...');
        // Update Media Session metadata to show the reminder content on lock screen
        if ('mediaSession' in navigator) {
          navigator.mediaSession.metadata = new MediaMetadata({
            title: text,
            artist: '系统提醒',
            album: '萨莉亚语音助手',
            artwork: [
              { src: '/icons/Icon-192.png', sizes: '192x192', type: 'image/png' }
            ]
          });
        }

        await this.speakOpenAI(text, url, key, config);
        const latency = Date.now() - startTime;
        this.recordSuccess(latency);
        console.log('[VoiceService] OpenAI TTS Success');
      } catch (e) {
        this.performanceMetrics.failedSpeaks++;
        console.error('[VoiceService] OpenAI TTS Error:', e);

        // Retry logic: if first attempt failed, try once more
        if (retryCount < 1) {
          console.log('[VoiceService] Retrying after OpenAI TTS failure...');
          await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second
          return this.speak(text, config, retryCount + 1);
        }

        // If OpenAI failed after retry, try SpeechSynthesis as last resort (if not in background)
        if (!isBackground) {
          console.log('[VoiceService] OpenAI failed, attempting SpeechSynthesis as last resort...');
          try {
            const success = await this.speakLocal(text);
            if (success) {
              console.log('[VoiceService] SpeechSynthesis fallback succeeded');
              return;
            }
          } catch (localError) {
            console.error('[VoiceService] SpeechSynthesis fallback also failed:', localError);
          }
        }

        // All methods failed - log detailed error
        console.error('[VoiceService] All TTS methods failed for text:', text);
        this.logError('VOICE_PLAYBACK_FAILED', e, {
          isBackground,
          hasKeepAlive: this.keepAliveAudio !== null && !this.keepAliveAudio.paused,
          reminderContent: text,
          retryCount
        });
      } finally {
        // Restore keep-alive metadata after speaking
        setTimeout(() => this.updateMediaSessionMetadata(), 2000);
      }
    } else {
      console.warn('[VoiceService] OpenAI Key missing, cannot fallback.');

      // If no OpenAI key and in foreground, try local TTS
      if (!isBackground) {
        console.log('[VoiceService] No OpenAI key, trying SpeechSynthesis...');
        try {
          const success = await this.speakLocal(text);
          if (!success) {
            console.error('[VoiceService] SpeechSynthesis failed and no OpenAI key available');
          }
        } catch (e) {
          console.error('[VoiceService] SpeechSynthesis error:', e);
        }
      }
    }
  }

  /**
   * Log error with context
   */
  logError(type, error, context) {
    const errorLog = {
      type,
      timestamp: Date.now(),
      error: {
        message: error.message,
        stack: error.stack
      },
      context
    };
    console.error('[VoiceService] Error Log:', errorLog);

    // Store in localStorage for debugging (keep last 10 errors)
    try {
      const logs = JSON.parse(localStorage.getItem('voice_error_logs') || '[]');
      logs.unshift(errorLog);
      localStorage.setItem('voice_error_logs', JSON.stringify(logs.slice(0, 10)));
    } catch (e) {
      console.warn('[VoiceService] Failed to store error log:', e);
    }
  }

  /**
   * Record successful speak operation
   */
  recordSuccess(latency) {
    this.performanceMetrics.successfulSpeaks++;
    this.performanceMetrics.latencies.push(latency);

    // Keep only last 100 latencies
    if (this.performanceMetrics.latencies.length > 100) {
      this.performanceMetrics.latencies.shift();
    }

    // Calculate average latency
    const sum = this.performanceMetrics.latencies.reduce((a, b) => a + b, 0);
    this.performanceMetrics.averageLatency = sum / this.performanceMetrics.latencies.length;
  }

  /**
   * Get performance statistics
   */
  getPerformanceStats() {
    const cacheHitRate = this.performanceMetrics.totalSpeakCalls > 0
      ? (this.performanceMetrics.cacheHits / this.performanceMetrics.totalSpeakCalls * 100).toFixed(2)
      : '0.00';

    return {
      voice: {
        totalCalls: this.performanceMetrics.totalSpeakCalls,
        successful: this.performanceMetrics.successfulSpeaks,
        failed: this.performanceMetrics.failedSpeaks,
        successRate: this.performanceMetrics.totalSpeakCalls > 0
          ? ((this.performanceMetrics.successfulSpeaks / this.performanceMetrics.totalSpeakCalls) * 100).toFixed(2) + '%'
          : '0%',
        averageLatency: Math.round(this.performanceMetrics.averageLatency) + 'ms',
        minLatency: this.performanceMetrics.latencies.length > 0
          ? Math.min(...this.performanceMetrics.latencies) + 'ms'
          : 'N/A',
        maxLatency: this.performanceMetrics.latencies.length > 0
          ? Math.max(...this.performanceMetrics.latencies) + 'ms'
          : 'N/A'
      },
      cache: {
        size: this.audioCache.size,
        maxSize: this.maxCacheSize,
        hitRate: cacheHitRate + '%'
      }
    };
  }

  updateMediaSessionMetadata() {
    if ('mediaSession' in navigator) {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: '语音提醒系统',
        artist: '萨莉亚',
        album: '后台运行中',
        artwork: [
          { src: '/icons/Icon-192.png', sizes: '192x192', type: 'image/png' }
        ]
      });
    }
  }

  speakLocal(text) {
    return new Promise((resolve) => {
      if (!this.synth) return resolve(false);

      const utter = new SpeechSynthesisUtterance(text);
      utter.lang = 'zh-CN';

      // Background timeout: if no start event within 2s, consider it blocked
      const timeout = setTimeout(() => {
        console.warn('[VoiceService] Local TTS timed out (likely background blocked)');
        this.synth?.cancel();
        resolve(false);
      }, 2000);

      utter.onstart = () => {
        clearTimeout(timeout);
      };

      utter.onend = () => {
        clearTimeout(timeout);
        resolve(true);
      };

      utter.onerror = (e) => {
        clearTimeout(timeout);
        console.error('[VoiceService] SpeechSynthesis error', e);
        resolve(false);
      };

      this.synth.speak(utter);
    });
  }

  /**
   * Generate audio using OpenAI TTS API
   */
  async generateOpenAIAudio(text, baseUrl, key, config) {
    // Clean up baseUrl: if it ends with /chat/completions, remove that part
    let apiBase = baseUrl.replace(/\/chat\/completions\/?$/, '').replace(/\/+$/, '');
    if (!apiBase) apiBase = 'https://api.openai.com/v1';

    const url = `${apiBase}/audio/speech`;
    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${key}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: config?.model || 'tts-1',
        input: text,
        voice: config?.voice || 'alloy'
      })
    });

    if (!response.ok) throw new Error(`OpenAI TTS error: ${response.statusText}`);

    return await response.blob();
  }

  async speakOpenAI(text, baseUrl, key, config) {
    // Check cache first
    const cached = this.getCachedAudio(text);
    let audioUrl;

    if (cached) {
      this.performanceMetrics.cacheHits++;
      console.log('[VoiceService] Using cached audio');
      audioUrl = cached.url;
    } else {
      this.performanceMetrics.cacheMisses++;
      console.log('[VoiceService] Generating new audio');
      const blob = await this.generateOpenAIAudio(text, baseUrl, key, config);

      // Cache for future use
      this.setCachedAudio(text, blob);

      audioUrl = URL.createObjectURL(blob);
    }

    const audio = new Audio(audioUrl);
    await audio.play();

    // Clean up if not cached
    if (!cached) {
      audio.onended = () => {
        // Don't revoke URL immediately as it might be in cache
        // Cache will handle cleanup
      };
    }
  }
}

// Global instance
window.flutterVoiceService = new FlutterWebVoiceService();

// Auto-unlock on first user interaction
document.addEventListener('click', () => {
  window.flutterVoiceService.unlock();
}, { once: true });

document.addEventListener('touchstart', () => {
  window.flutterVoiceService.unlock();
}, { once: true });

// Export functions for Flutter Web
window.unlockVoiceService = () => window.flutterVoiceService.unlock();
window.speakText = (text, config) => window.flutterVoiceService.speak(text, config);
window.preloadVoiceAudio = (text, config) => window.flutterVoiceService.preloadAudio(text, config);
window.getVoicePlatformInfo = () => window.flutterVoiceService.getPlatformInfo();
window.getVoicePerformanceStats = () => window.flutterVoiceService.getPerformanceStats();
window.clearVoiceCache = () => window.flutterVoiceService.clearExpiredCache();