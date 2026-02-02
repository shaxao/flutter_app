/**
 * Audio Scheduler for background playback
 * Uses continuous audio playback to keep the app alive and schedule reminders
 */

interface ScheduledAudio {
  id: string
  time: string // HH:mm format
  audioUrl: string
  content: string
  enabled: boolean
}

class AudioScheduler {
  private audioContext: AudioContext | null = null
  private scheduledAudios: Map<string, ScheduledAudio> = new Map()
  private masterGainNode: GainNode | null = null
  private isPlaying = false
  private checkInterval: number | null = null
  private currentAudio: HTMLAudioElement | null = null

  /**
   * Initialize the audio scheduler
   */
  async init() {
    try {
      if (typeof window === 'undefined') return

      // Create AudioContext
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)()

      console.log('[AudioScheduler] AudioContext created, state:', this.audioContext.state)

      // CRITICAL: Resume AudioContext immediately after creation
      // iOS PWA requires this to be done in response to user interaction
      if (this.audioContext.state === 'suspended') {
        console.log('[AudioScheduler] AudioContext is suspended, attempting resume...')
        await this.audioContext.resume()
        console.log('[AudioScheduler] AudioContext resumed, new state:', this.audioContext.state)
      }

      // Create master gain node for volume control
      this.masterGainNode = this.audioContext.createGain()
      this.masterGainNode.connect(this.audioContext.destination)

      console.log('[AudioScheduler] Initialized successfully')
    } catch (e) {
      console.error('[AudioScheduler] Init failed:', e)
      // Don't throw, just log
    }
  }

  /**
   * Start continuous playback to keep audio session alive
   */
  async start() {
    try {
      if (this.isPlaying) {
        console.log('[AudioScheduler] Already playing')
        return
      }

      console.log('[AudioScheduler] Starting...')

      // Resume audio context if suspended
      if (this.audioContext && this.audioContext.state === 'suspended') {
        console.log('[AudioScheduler] Resuming suspended audio context')
        await this.audioContext.resume()
      }

      this.isPlaying = true
      console.log('[AudioScheduler] Set isPlaying = true')

      // Start the keep-alive audio loop (await it to ensure it starts)
      await this.startKeepAliveLoop()

      // Start checking for scheduled reminders
      this.startScheduleChecker()

      console.log('[AudioScheduler] Started continuous playback, status:', this.getStatus())
    } catch (e) {
      console.error('[AudioScheduler] Start failed:', e)
      // Don't throw, just log
    }
  }

  /**
   * Start a silent audio loop to keep the session alive
   */
  private async startKeepAliveLoop() {
    console.log('[AudioScheduler] Starting keep-alive loop')

    // CRITICAL: Resume AudioContext before playing audio
    if (this.audioContext && this.audioContext.state === 'suspended') {
      console.log('[AudioScheduler] AudioContext suspended before play, resuming...')
      try {
        await this.audioContext.resume()
        console.log('[AudioScheduler] AudioContext resumed successfully, state:', this.audioContext.state)
      } catch (e) {
        console.error('[AudioScheduler] Failed to resume AudioContext:', e)
      }
    }

    // Use a very quiet looping audio to maintain the audio session
    const silentMp3 = 'data:audio/mp3;base64,SUQzBAAAAAABAFRYWFgAAAASAAADbWFqb3JfYnJhbmQAZGFzaABUWFhYAAAAEwAAA21pbm9yX3ZlcnNpb24AMABUWFhYAAAAHAAAA2NvbXBhdGlibGVfYnJhbmRzAGlzbzZtcDQxAFRTU0UAAAAPAAADTGF2ZjYwLjMuMTAwAAAAAAAAAAAAAAD/80MUAAAAAAnSBAAABGZlZWQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAf/zQxQBAAAACdIEAAAEZmVlZAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB'

    if (!this.currentAudio) {
      console.log('[AudioScheduler] Creating new keep-alive audio element')
      this.currentAudio = new Audio(silentMp3)
      this.currentAudio.loop = true
      this.currentAudio.volume = 0.05 // iOS requires audible volume

      // Add event listeners for debugging
      this.currentAudio.onplay = () => {
        console.log('[AudioScheduler] Keep-alive audio started playing')
        // Check AudioContext state when audio starts
        if (this.audioContext) {
          console.log('[AudioScheduler] AudioContext state on play:', this.audioContext.state)
        }
      }
      this.currentAudio.onpause = () => {
        console.log('[AudioScheduler] Keep-alive audio paused')
        // Try to resume if paused unexpectedly
        if (this.isPlaying) {
          console.log('[AudioScheduler] Unexpected pause, attempting to resume...')
          setTimeout(() => {
            this.currentAudio?.play().catch(e => {
              console.error('[AudioScheduler] Failed to resume after pause:', e)
            })
          }, 100)
        }
      }
      this.currentAudio.onerror = (e) => console.error('[AudioScheduler] Keep-alive audio error:', e)

      // Set up Media Session
      if ('mediaSession' in navigator) {
        navigator.mediaSession.metadata = new MediaMetadata({
          title: '语音提醒待命中',
          artist: '萨莉亚餐饮',
          album: '后台运行',
          artwork: [
            { src: '/pwa-192x192.png', sizes: '192x192', type: 'image/png' }
          ]
        })
        console.log('[AudioScheduler] Media Session metadata set')
      }
    } else {
      console.log('[AudioScheduler] Reusing existing keep-alive audio element')
    }

    // CRITICAL: Play audio and handle promise
    try {
      await this.currentAudio.play()
      console.log('[AudioScheduler] Keep-alive audio play() succeeded')
    } catch (e) {
      console.error('[AudioScheduler] Failed to start keep-alive:', e)
      // Try one more time after a short delay
      setTimeout(async () => {
        try {
          if (this.audioContext && this.audioContext.state === 'suspended') {
            await this.audioContext.resume()
          }
          await this.currentAudio?.play()
          console.log('[AudioScheduler] Keep-alive audio play() succeeded on retry')
        } catch (retryError) {
          console.error('[AudioScheduler] Keep-alive retry also failed:', retryError)
        }
      }, 500)
    }
  }

  /**
   * Start checking for scheduled reminders every second
   */
  private startScheduleChecker() {
    if (this.checkInterval) {
      console.log('[AudioScheduler] Clearing existing check interval')
      clearInterval(this.checkInterval)
    }

    console.log('[AudioScheduler] Starting schedule checker (1 second interval)')
    this.checkInterval = window.setInterval(() => {
      this.checkAndPlayScheduled()
    }, 1000) // Check every second for precise timing

    console.log('[AudioScheduler] Schedule checker started with interval ID:', this.checkInterval)
  }

  /**
   * Check if any scheduled audio should play now
   */
  private checkAndPlayScheduled() {
    const now = new Date()
    const currentHM = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`
    const currentSeconds = now.getSeconds()

    // Log every 10 seconds for debugging
    if (currentSeconds % 10 === 0) {
      console.log(`[AudioScheduler] Checking at ${currentHM}:${currentSeconds}, scheduled count: ${this.scheduledAudios.size}, isPlaying: ${this.isPlaying}`)

      // Log all scheduled audios
      if (this.scheduledAudios.size > 0) {
        console.log('[AudioScheduler] Scheduled audios:', Array.from(this.scheduledAudios.values()).map(s => `${s.time} - ${s.content} (enabled: ${s.enabled})`))
      }
    }

    // Only trigger at the start of the minute (0-2 seconds)
    if (currentSeconds > 2) return

    console.log(`[AudioScheduler] Checking for matches at ${currentHM}:${currentSeconds}`)

    for (const [id, scheduled] of this.scheduledAudios.entries()) {
      console.log(`[AudioScheduler] Checking ${id}: time=${scheduled.time}, enabled=${scheduled.enabled}, match=${scheduled.time === currentHM}`)

      if (scheduled.enabled && scheduled.time === currentHM) {
        console.log(`[AudioScheduler] ✓ MATCH! Playing scheduled audio: ${scheduled.content}`)
        this.playScheduledAudio(scheduled)

        // Show notification
        this.showNotification(scheduled.content)

        // Disable to prevent repeated playback in the same minute
        scheduled.enabled = false

        // Re-enable after 1 minute
        setTimeout(() => {
          const audio = this.scheduledAudios.get(id)
          if (audio) {
            audio.enabled = true
            console.log(`[AudioScheduler] Re-enabled ${id}`)
          }
        }, 61000)
      }
    }
  }

  /**
   * Play a scheduled audio
   */
  private async playScheduledAudio(scheduled: ScheduledAudio) {
    try {
      // Pause keep-alive temporarily
      if (this.currentAudio) {
        this.currentAudio.volume = 0.01 // Lower volume during reminder
      }

      // Update Media Session
      if ('mediaSession' in navigator) {
        navigator.mediaSession.metadata = new MediaMetadata({
          title: scheduled.content,
          artist: '系统提醒',
          album: '萨莉亚语音助手',
          artwork: [
            { src: '/pwa-192x192.png', sizes: '192x192', type: 'image/png' }
          ]
        })
      }

      // Play the reminder audio
      const reminderAudio = new Audio(scheduled.audioUrl)
      reminderAudio.volume = 1.0

      await reminderAudio.play()

      // Wait for audio to finish
      await new Promise<void>((resolve) => {
        reminderAudio.onended = () => resolve()
        reminderAudio.onerror = () => resolve()

        // Timeout after 30 seconds
        setTimeout(() => resolve(), 30000)
      })

      // Restore keep-alive volume
      if (this.currentAudio) {
        this.currentAudio.volume = 0.05
      }

      // Restore Media Session
      if ('mediaSession' in navigator) {
        navigator.mediaSession.metadata = new MediaMetadata({
          title: '语音提醒待命中',
          artist: '萨莉亚餐饮',
          album: '后台运行',
          artwork: [
            { src: '/pwa-192x192.png', sizes: '192x192', type: 'image/png' }
          ]
        })
      }

      console.log('[AudioScheduler] Finished playing scheduled audio')
    } catch (e) {
      console.error('[AudioScheduler] Error playing scheduled audio:', e)
    }
  }

  /**
   * Schedule an audio for playback
   * @param id - Unique identifier
   * @param time - Time in HH:mm format
   * @param audioUrl - URL to the audio file
   * @param content - Reminder content
   */
  scheduleAudio(id: string, time: string, audioUrl: string, content: string) {
    this.scheduledAudios.set(id, {
      id,
      time,
      audioUrl,
      content,
      enabled: true
    })
    console.log(`[AudioScheduler] ✓ Scheduled audio for ${time}: ${content}`)
    console.log(`[AudioScheduler] Total scheduled: ${this.scheduledAudios.size}`)
  }

  /**
   * Remove a scheduled audio
   */
  removeScheduled(id: string) {
    this.scheduledAudios.delete(id)
    console.log(`[AudioScheduler] Removed scheduled audio: ${id}`)
  }

  /**
   * Clear all scheduled audios
   */
  clearAll() {
    this.scheduledAudios.clear()
    console.log('[AudioScheduler] Cleared all scheduled audios')
  }

  /**
   * Get all scheduled audios
   */
  getScheduled(): ScheduledAudio[] {
    return Array.from(this.scheduledAudios.values())
  }

  /**
   * Stop the scheduler
   */
  stop() {
    this.isPlaying = false

    if (this.checkInterval) {
      clearInterval(this.checkInterval)
      this.checkInterval = null
    }

    if (this.currentAudio) {
      this.currentAudio.pause()
      this.currentAudio = null
    }

    console.log('[AudioScheduler] Stopped')
  }

  /**
   * Get scheduler status
   */
  getStatus() {
    return {
      isPlaying: this.isPlaying,
      scheduledCount: this.scheduledAudios.size,
      audioContextState: this.audioContext?.state || 'unknown',
      keepAliveStatus: this.currentAudio ? (this.currentAudio.paused ? 'paused' : 'playing') : 'not-started'
    }
  }

  /**
   * Show notification for a reminder
   */
  private async showNotification(content: string) {
    if (!('Notification' in window)) {
      console.log('[AudioScheduler] Notifications not supported')
      return
    }

    if (Notification.permission !== 'granted') {
      console.log('[AudioScheduler] Notification permission not granted')
      return
    }

    try {
      // Use ServiceWorker for more reliable background notifications if available
      if ('serviceWorker' in navigator && navigator.serviceWorker.controller) {
        const reg = await navigator.serviceWorker.ready
        await reg.showNotification('🔔 食材过期提醒', {
          body: `${content}\n\n👆 点击此通知播放语音提醒`,
          icon: '/pwa-192x192.png',
          badge: '/pwa-192x192.png',
          tag: 'reminder-' + Date.now(),
          renotify: true,
          requireInteraction: true,
          silent: false,
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
        console.log('[AudioScheduler] Notification sent via ServiceWorker')
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

        console.log('[AudioScheduler] Notification sent via standard API')
      }
    } catch (e) {
      console.error('[AudioScheduler] Failed to show notification:', e)
    }
  }
}

export default new AudioScheduler()
