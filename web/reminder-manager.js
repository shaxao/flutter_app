// Flutter Web Reminder Manager - Based on od_web implementation

class FlutterWebReminderManager {
  constructor() {
    this.reminders = [];
    this.worker = null;
    this.lastTriggeredMinute = '';
    this.preloadedReminders = new Set(); // Track preloaded reminders
    this.broadcastChannel = null;
  }

  async init() {
    this.loadFromCache();
    await this.refreshReminders();
    this.startWorker();
    this.setupBroadcastChannel();

    // Refresh when page becomes visible again
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        this.refreshReminders();
      }
    });

    console.log('[ReminderManager] Reminder Manager initialized with Web Worker & Visibility Listener');
  }

  setupBroadcastChannel() {
    try {
      this.broadcastChannel = new BroadcastChannel('reminder-channel');
      this.broadcastChannel.onmessage = (event) => {
        console.log('[ReminderManager] BroadcastChannel message:', event.data);

        if (event.data.type === 'PUSH_RECEIVED_WAKE_UP') {
          this.handlePushWakeUp(event.data.payload);
        }
      };
      console.log('[ReminderManager] BroadcastChannel setup complete');
    } catch (error) {
      console.error('[ReminderManager] BroadcastChannel setup failed:', error);
    }
  }

  handlePushWakeUp(payload) {
    console.log('[ReminderManager] Handling push wake-up:', payload);

    // Trigger voice playback
    if (window.flutterVoiceService && payload.body) {
      window.flutterVoiceService.speak(`提醒事项：${payload.body}`);
    }
  }

  loadFromCache() {
    const cached = localStorage.getItem('flutter_voice_reminders_cache');
    if (cached) {
      try {
        this.reminders = JSON.parse(cached);
        console.log('[ReminderManager] Loaded reminders from cache');
      } catch (e) {
        console.error('[ReminderManager] Failed to parse cached reminders', e);
      }
    }
  }

  async refreshReminders() {
    try {
      const baseUrl = 'https://service.muhuo.site';
      const response = await fetch(`${baseUrl}/api/v1/voice-reminders`);

      if (response.ok) {
        const data = await response.json();
        this.reminders = data;
        localStorage.setItem('flutter_voice_reminders_cache', JSON.stringify(this.reminders));
        console.log('[ReminderManager] Reminders refreshed from server');
      } else {
        console.warn('[ReminderManager] Failed to fetch reminders, using cache');
      }
    } catch (e) {
      console.error('[ReminderManager] Failed to fetch reminders for background task', e);
    }
  }

  /**
   * Get upcoming reminders within the specified time window
   */
  getUpcomingReminders(minutes) {
    const now = new Date();
    const upcoming = [];

    for (const reminder of this.reminders) {
      if (!reminder.enabled) continue;

      const [hours, mins] = reminder.time.split(':').map(Number);
      if (hours === undefined || mins === undefined) continue;

      const reminderTime = new Date();
      reminderTime.setHours(hours, mins, 0, 0);

      // Calculate time difference in minutes
      const diffMs = reminderTime.getTime() - now.getTime();
      const diffMins = Math.floor(diffMs / 60000);

      // Check if within the time window (0 to minutes ahead)
      if (diffMins >= 0 && diffMins <= minutes) {
        upcoming.push(reminder);
      }
    }

    return upcoming;
  }

  /**
   * Schedule audio preloading for upcoming reminders
   */
  async schedulePreload() {
    // Get reminders coming up in the next 2 minutes
    const upcoming = this.getUpcomingReminders(2);

    for (const reminder of upcoming) {
      const reminderKey = `${reminder.time}-${reminder.content}`;

      // Skip if already preloaded
      if (this.preloadedReminders.has(reminderKey)) {
        continue;
      }

      // Preload audio 1 minute before
      const [hours, mins] = reminder.time.split(':').map(Number);
      if (hours === undefined || mins === undefined) continue;

      const reminderTime = new Date();
      reminderTime.setHours(hours, mins, 0, 0);

      const now = new Date();
      const diffMs = reminderTime.getTime() - now.getTime();
      const diffMins = Math.floor(diffMs / 60000);

      // Preload if 1-2 minutes away
      if (diffMins >= 1 && diffMins <= 2) {
        console.log(`[ReminderManager] Preloading audio for reminder at ${reminder.time}`);
        if (window.flutterVoiceService) {
          await window.flutterVoiceService.preloadAudio(`提醒事项：${reminder.content}`);
        }
        this.preloadedReminders.add(reminderKey);
      }
    }

    // Clean up old preloaded markers (older than 5 minutes)
    const cleanupTime = new Date();
    cleanupTime.setMinutes(cleanupTime.getMinutes() - 5);

    for (const key of this.preloadedReminders) {
      const [time] = key.split('-');
      if (time) {
        const [hours, mins] = time.split(':').map(Number);
        if (hours !== undefined && mins !== undefined) {
          const reminderTime = new Date();
          reminderTime.setHours(hours, mins, 0, 0);

          if (reminderTime < cleanupTime) {
            this.preloadedReminders.delete(key);
          }
        }
      }
    }
  }

  startWorker() {
    if (this.worker) this.worker.terminate();

    try {
      this.worker = new Worker('/timer.worker.js');
      this.worker.onmessage = (e) => {
        if (e.data === 'tick') {
          this.checkAndTrigger();
          // Dispatch a custom event for the UI to listen to
          window.dispatchEvent(new CustomEvent('reminder-tick', {
            detail: { time: new Date().toLocaleTimeString() }
          }));
        }
      };
      this.worker.postMessage('start');
      console.log('[ReminderManager] Web Worker started successfully');
    } catch (err) {
      console.error('[ReminderManager] Failed to start Web Worker, falling back to setInterval', err);
      this.startFallbackChecking();
    }
  }

  startFallbackChecking() {
    setInterval(() => this.checkAndTrigger(), 30000);
    console.log('[ReminderManager] Fallback timer started');
  }

  checkAndTrigger() {
    const now = new Date();
    const currentHM = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

    // Schedule preloading for upcoming reminders
    this.schedulePreload();

    // Avoid double triggering in the same minute
    if (currentHM === this.lastTriggeredMinute) return;

    const matches = this.reminders.filter(r => r.enabled && r.time === currentHM);

    if (matches.length > 0) {
      this.lastTriggeredMinute = currentHM;
      matches.forEach(reminder => {
        console.log(`[ReminderManager] Triggering reminder: ${reminder.content}`);

        // 1. Voice
        if (window.flutterVoiceService) {
          window.flutterVoiceService.speak(`提醒事项：${reminder.content}`);
        }

        // 2. Notification (if in background or supported)
        this.showNotification(reminder.content);

        // 3. Notify Flutter app
        if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
          window.flutter_inappwebview.callHandler('onReminderTriggered', {
            id: reminder.id,
            content: reminder.content,
            time: reminder.time
          });
        }
      });

      // Refresh list after triggering to get latest status if updated elsewhere
      this.refreshReminders();
    }

    // Clean up expired cache periodically
    if (window.flutterVoiceService) {
      window.flutterVoiceService.clearExpiredCache();
    }
  }

  async showNotification(content) {
    if (!('Notification' in window)) return;

    if (Notification.permission === 'granted') {
      // Use ServiceWorker for more reliable background notifications if available
      if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
        const reg = await navigator.serviceWorker.ready;
        reg.showNotification('🔔 食材过期提醒', {
          body: `${content}\n\n👆 点击此通知播放语音提醒`,
          icon: '/icons/Icon-192.png',
          badge: '/icons/Icon-192.png',
          tag: 'reminder-' + Date.now(),
          renotify: true,
          requireInteraction: true, // 通知不会自动消失
          vibrate: [200, 100, 200, 100, 200, 100, 200], // 持续振动
          silent: false, // 允许声音
          data: {
            url: `/?autoSpeak=${encodeURIComponent(content)}`,
            content: content
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
      } else {
        // Fallback to standard Notification
        const notification = new Notification('🔔 食材过期提醒', {
          body: `${content}\n\n👆 点击此通知播放语音提醒`,
          icon: '/icons/Icon-192.png',
          tag: 'reminder-' + Date.now(),
          requireInteraction: true,
          silent: false,
          data: {
            url: `/?autoSpeak=${encodeURIComponent(content)}`,
            content: content
          }
        });

        // Handle notification click
        notification.onclick = () => {
          window.focus();
          if (window.flutterVoiceService) {
            window.flutterVoiceService.speak(`提醒事项：${content}`);
          }
          notification.close();
        };
      }
    }
  }

  stop() {
    if (this.worker) {
      this.worker.terminate();
      this.worker = null;
    }

    if (this.broadcastChannel) {
      this.broadcastChannel.close();
      this.broadcastChannel = null;
    }
  }

  // Get reminder statistics
  getStats() {
    const now = new Date();
    const currentHM = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

    return {
      totalReminders: this.reminders.length,
      enabledReminders: this.reminders.filter(r => r.enabled).length,
      upcomingReminders: this.getUpcomingReminders(60).length,
      preloadedCount: this.preloadedReminders.size,
      currentTime: currentHM,
      lastTriggered: this.lastTriggeredMinute,
      workerActive: !!this.worker
    };
  }
}

// Global instance
window.flutterReminderManager = new FlutterWebReminderManager();

// Auto-initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
  console.log('[ReminderManager] DOM loaded, initializing reminder manager...');
  window.flutterReminderManager.init().catch(console.error);
});

// Export functions for Flutter Web
window.initializeReminderManager = () => window.flutterReminderManager.init();
window.refreshReminders = () => window.flutterReminderManager.refreshReminders();
window.getReminderStats = () => window.flutterReminderManager.getStats();
window.stopReminderManager = () => window.flutterReminderManager.stop();