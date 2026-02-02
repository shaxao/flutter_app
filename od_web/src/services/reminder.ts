import api from '@/api'
import voiceService from './voice'

interface Reminder {
  id: number
  time: string
  content: string
  enabled: boolean
}

class ReminderManager {
  private reminders: Reminder[] = []
  private worker: Worker | null = null
  private lastTriggeredMinute: string = ''
  private preloadedReminders: Set<string> = new Set() // Track preloaded reminders

  async init() {
    this.loadFromCache()
    await this.refreshReminders()
    this.startWorker()

    // Refresh when page becomes visible again
    document.addEventListener('visibilitychange', () => {
      if (document.visibilityState === 'visible') {
        this.refreshReminders()
      }
    })

    console.log('Reminder Manager initialized with Web Worker & Visibility Listener')
  }

  private loadFromCache() {
    const cached = localStorage.getItem('voice_reminders_cache')
    if (cached) {
      try {
        this.reminders = JSON.parse(cached)
        console.log('Loaded reminders from cache')
      } catch (e) {
        console.error('Failed to parse cached reminders', e)
      }
    }
  }

  async refreshReminders() {
    try {
      const res = await api.get('/voice-reminders')
      this.reminders = res.data
      localStorage.setItem('voice_reminders_cache', JSON.stringify(this.reminders))
    } catch (e) {
      console.error('Failed to fetch reminders for background task', e)
    }
  }

  /**
   * Get upcoming reminders within the specified time window
   * @param minutes - Number of minutes to look ahead
   * @returns Array of upcoming reminders
   */
  getUpcomingReminders(minutes: number): Reminder[] {
    const now = new Date()
    const upcoming: Reminder[] = []

    for (const reminder of this.reminders) {
      if (!reminder.enabled) continue

      const [hours, mins] = reminder.time.split(':').map(Number)
      if (hours === undefined || mins === undefined) continue

      const reminderTime = new Date()
      reminderTime.setHours(hours, mins, 0, 0)

      // Calculate time difference in minutes
      const diffMs = reminderTime.getTime() - now.getTime()
      const diffMins = Math.floor(diffMs / 60000)

      // Check if within the time window (0 to minutes ahead)
      if (diffMins >= 0 && diffMins <= minutes) {
        upcoming.push(reminder)
      }
    }

    return upcoming
  }

  /**
   * Schedule audio preloading for upcoming reminders
   */
  private async schedulePreload() {
    // Get reminders coming up in the next 2 minutes
    const upcoming = this.getUpcomingReminders(2)

    for (const reminder of upcoming) {
      const reminderKey = `${reminder.time}-${reminder.content}`

      // Skip if already preloaded
      if (this.preloadedReminders.has(reminderKey)) {
        continue
      }

      // Preload audio 1 minute before
      const [hours, mins] = reminder.time.split(':').map(Number)
      if (hours === undefined || mins === undefined) continue

      const reminderTime = new Date()
      reminderTime.setHours(hours, mins, 0, 0)

      const now = new Date()
      const diffMs = reminderTime.getTime() - now.getTime()
      const diffMins = Math.floor(diffMs / 60000)

      // Preload if 1-2 minutes away
      if (diffMins >= 1 && diffMins <= 2) {
        console.log(`[ReminderManager] Preloading audio for reminder at ${reminder.time}`)
        await voiceService.preloadAudio(`提醒事项：${reminder.content}`)
        this.preloadedReminders.add(reminderKey)
      }
    }

    // Clean up old preloaded markers (older than 5 minutes)
    const cleanupTime = new Date()
    cleanupTime.setMinutes(cleanupTime.getMinutes() - 5)

    for (const key of this.preloadedReminders) {
      const [time] = key.split('-')
      if (time) {
        const [hours, mins] = time.split(':').map(Number)
        if (hours !== undefined && mins !== undefined) {
          const reminderTime = new Date()
          reminderTime.setHours(hours, mins, 0, 0)

          if (reminderTime < cleanupTime) {
            this.preloadedReminders.delete(key)
          }
        }
      }
    }
  }

  private startWorker() {
    if (this.worker) this.worker.terminate()

    try {
      this.worker = new Worker(new URL('./timer.worker.ts', import.meta.url))
      this.worker.onmessage = (e) => {
        if (e.data === 'tick') {
          this.checkAndTrigger()
          // Dispatch a custom event for the UI to listen to
          window.dispatchEvent(new CustomEvent('reminder-tick', {
            detail: { time: new Date().toLocaleTimeString() }
          }))
        }
      }
      this.worker.postMessage('start')
    } catch (err) {
      console.error('Failed to start Web Worker, falling back to setInterval', err)
      this.startFallbackChecking()
    }
  }

  private startFallbackChecking() {
    setInterval(() => this.checkAndTrigger(), 30000)
  }

  private checkAndTrigger() {
    const now = new Date()
    const currentHM = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`

    // Schedule preloading for upcoming reminders
    this.schedulePreload()

    // Avoid double triggering in the same minute
    if (currentHM === this.lastTriggeredMinute) return

    const matches = this.reminders.filter(r => r.enabled && r.time === currentHM)

    if (matches.length > 0) {
      this.lastTriggeredMinute = currentHM
      matches.forEach(reminder => {
        console.log(`Triggering reminder: ${reminder.content}`)

        // 1. Voice
        voiceService.speak(`提醒事项：${reminder.content}`)

        // 2. Notification (if in background or supported)
        this.showNotification(reminder.content)
      })

      // Refresh list after triggering to get latest status if updated elsewhere
      this.refreshReminders()
    }

    // Clean up expired cache periodically
    voiceService.clearExpiredCache()
  }

  private async showNotification(content: string) {
    if (!('Notification' in window)) return

    if (Notification.permission === 'granted') {
      // Use ServiceWorker for more reliable background notifications if available
      if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
        const reg = await navigator.serviceWorker.ready
        reg.showNotification('🔔 食材过期提醒', {
          body: `${content}\n\n👆 点击此通知播放语音提醒`,
          icon: '/pwa-192x192.png',
          badge: '/pwa-192x192.png',
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
        } as any)
      } else {
        // Fallback to standard Notification
        const notification = new Notification('🔔 食材过期提醒', {
          body: `${content}\n\n👆 点击此通知播放语音提醒`,
          icon: '/pwa-192x192.png',
          tag: 'reminder-' + Date.now(),
          requireInteraction: true,
          silent: false,
          data: {
            url: `/?autoSpeak=${encodeURIComponent(content)}`,
            content: content
          }
        } as any)

        // Handle notification click
        notification.onclick = () => {
          window.focus()
          window.location.href = `/?autoSpeak=${encodeURIComponent(content)}`
          notification.close()
        }
      }
    }
  }

  stop() {
    if (this.worker) {
      this.worker.terminate()
      this.worker = null
    }
  }
}

export default new ReminderManager()
