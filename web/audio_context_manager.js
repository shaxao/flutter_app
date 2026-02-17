// VoiceFlow Audio Context Manager
// Handles high-priority alarm playback using AudioContext
// Works in conjunction with Service Worker and Web Worker

class AudioContextManager {
  constructor() {
    this.audioContext = null;
    this.gainNode = null;
    this.sourceNode = null;
    this.audioBuffer = null;
    this.isUnlocked = false;
    this.isPlaying = false;
    
    this.init();
  }

  init() {
    // Create AudioContext (cross-browser)
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    this.audioContext = new AudioContext();
    
    // Create GainNode for volume control (fade-in)
    this.gainNode = this.audioContext.createGain();
    this.gainNode.connect(this.audioContext.destination);
    
    // Listen for unlock interaction
    ['click', 'touchstart', 'keydown'].forEach(event => {
      document.addEventListener(event, this.unlock.bind(this), { once: true });
    });
    
    // Listen for Service Worker messages
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.addEventListener('message', this.handleMessage.bind(this));
    }
    
    // Listen for BroadcastChannel
    const channel = new BroadcastChannel('reminder-channel');
    channel.onmessage = (event) => {
      if (event.data && event.data.type === 'PLAY_ALARM') {
        this.playAlarm(event.data.url, event.data.fadeInDuration || 5);
      } else if (event.data && event.data.type === 'STOP_ALARM') {
        this.stopAlarm();
      }
    };
    
    console.log('[AudioContextManager] Initialized');
  }

  async unlock() {
    if (this.isUnlocked) return;
    
    try {
      if (this.audioContext.state === 'suspended') {
        await this.audioContext.resume();
      }
      
      // Play a silent buffer to fully unlock iOS
      const buffer = this.audioContext.createBuffer(1, 1, 22050);
      const source = this.audioContext.createBufferSource();
      source.buffer = buffer;
      source.connect(this.audioContext.destination);
      source.start(0);
      
      this.isUnlocked = true;
      console.log('[AudioContextManager] AudioContext unlocked');
      
      // Remove listeners
      ['click', 'touchstart', 'keydown'].forEach(event => {
        document.removeEventListener(event, this.unlock.bind(this));
      });
    } catch (e) {
      console.error('[AudioContextManager] Unlock failed:', e);
    }
  }

  handleMessage(event) {
    console.log('[AudioContextManager] Received message:', event.data);
    if (event.data && event.data.type === 'PLAY_ALARM') {
      this.playAlarm(event.data.url, event.data.fadeInDuration);
    } else if (event.data && event.data.type === 'STOP_ALARM') {
      this.stopAlarm();
    }
  }

  async loadAudio(url) {
    try {
      const response = await fetch(url);
      const arrayBuffer = await response.arrayBuffer();
      this.audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer);
      console.log('[AudioContextManager] Audio loaded:', url);
    } catch (e) {
      console.error('[AudioContextManager] Failed to load audio:', e);
      throw e;
    }
  }

  async playAlarm(url, fadeInDuration = 5) {
    if (this.isPlaying) return;
    
    try {
      if (!this.isUnlocked) {
        console.warn('[AudioContextManager] AudioContext not unlocked, attempting resume...');
        await this.audioContext.resume();
      }

      if (url) {
        await this.loadAudio(url);
      } else if (!this.audioBuffer) {
        console.error('[AudioContextManager] No audio URL or buffer available');
        return;
      }

      this.stopAlarm(false); // Stop any existing but don't clear buffer

      this.sourceNode = this.audioContext.createBufferSource();
      this.sourceNode.buffer = this.audioBuffer;
      this.sourceNode.loop = true; // Loop playback
      this.sourceNode.connect(this.gainNode);

      // Handle Fade In
      const currentTime = this.audioContext.currentTime;
      this.gainNode.gain.setValueAtTime(0, currentTime);
      this.gainNode.gain.linearRampToValueAtTime(1.0, currentTime + fadeInDuration);

      this.sourceNode.start(0);
      this.isPlaying = true;
      console.log(`[AudioContextManager] Alarm playing (Fade in: ${fadeInDuration}s)`);

    } catch (e) {
      console.error('[AudioContextManager] Playback failed:', e);
    }
  }

  stopAlarm(clearBuffer = true) {
    if (this.sourceNode) {
      try {
        this.sourceNode.stop();
        this.sourceNode.disconnect();
      } catch (e) {
        // Ignore if already stopped
      }
      this.sourceNode = null;
    }
    
    if (clearBuffer) {
      this.audioBuffer = null;
    }
    
    this.isPlaying = false;
    console.log('[AudioContextManager] Alarm stopped');
  }
}

// Export instance
window.audioContextManager = new AudioContextManager();
