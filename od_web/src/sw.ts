/// <reference lib="webworker" />
import { precacheAndRoute, cleanupOutdatedCaches } from 'workbox-precaching'

declare let self: ServiceWorkerGlobalScope

// 立即清理过期缓存，加快更新速度
cleanupOutdatedCaches()
precacheAndRoute(self.__WB_MANIFEST)

// Allow the service worker to skip waiting and take control immediately
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SKIP_WAITING') {
    console.log('[SW] Received SKIP_WAITING message, activating immediately')
    self.skipWaiting()
  }
})

// Take control of all clients immediately and clear old caches
self.addEventListener('activate', (event) => {
  console.log('[SW] Activating new service worker')
  event.waitUntil(
    Promise.all([
      // 立即接管所有客户端
      self.clients.claim(),
      // 清理旧版本的所有缓存
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            // 保留 workbox 预缓存，删除其他旧缓存
            if (!cacheName.startsWith('workbox-precache')) {
              console.log('[SW] Deleting old cache:', cacheName)
              return caches.delete(cacheName)
            }
          })
        )
      })
    ]).then(() => {
      console.log('[SW] Service worker activated and ready')
    })
  )
})

// 安装时立即激活，不等待
self.addEventListener('install', () => {
  console.log('[SW] Installing new service worker')
  // 强制跳过等待，立即激活
  self.skipWaiting()
})

// Handle Push Notifications
self.addEventListener('push', (event) => {
  console.log('[SW] Push received:', event)

  let data: any = { title: '系统提醒', body: '您有一条新提醒' }
  if (event.data) {
    try {
      data = event.data.json()
    } catch (e) {
      data.body = event.data.text()
    }
  }

  const options = {
    body: `${data.body || '提醒内容为空'}\n\n👆 点击此通知播放语音提醒`,
    icon: '/pwa-192x192.png',
    badge: '/pwa-192x192.png',
    vibrate: [200, 100, 200, 100, 200, 100, 200], // 持续振动模式
    tag: 'reminder-' + Date.now(),
    renotify: true,
    requireInteraction: true, // Keep notification until user interacts
    silent: false, // 允许声音
    data: {
      url: data.body ? `/?autoSpeak=${encodeURIComponent(data.body)}` : '/',
      type: data.type,
      body: data.body,
      content: data.body
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
  }

  // iOS 必须在 push 事件中同步调用 showNotification，不能异步太久
  // Execute all three operations in parallel for maximum reliability
  const notificationPromise = self.registration.showNotification(
    '🔔 食材过期提醒',
    options
  ).then(() => {
    console.log('[SW] Notification displayed successfully')
  }).catch((e) => {
    console.error('[SW] Failed to show notification:', e)
    throw e
  })

  // Use BroadcastChannel as it's more robust for background wake-up
  const broadcastPromise = (async () => {
    try {
      const channel = new BroadcastChannel('reminder-channel')
      channel.postMessage({
        type: 'PUSH_RECEIVED_WAKE_UP',
        payload: data
      })
      channel.close()
      console.log('[SW] BroadcastChannel message sent')
    } catch (e) {
      console.error('[SW] BroadcastChannel failed:', e)
    }
  })()

  // Also keep the old postMessage for maximum compatibility
  const clientsPromise = self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true
  }).then((clients) => {
    console.log(`[SW] Found ${clients.length} client(s)`)
    clients.forEach((client) => {
      client.postMessage({
        type: 'PUSH_RECEIVED_WAKE_UP',
        payload: data
      })
    })
  }).catch((e) => {
    console.error('[SW] Failed to send postMessage to clients:', e)
  })

  event.waitUntil(
    Promise.all([notificationPromise, broadcastPromise, clientsPromise])
  )
})

// Handle Notification Click
self.addEventListener('notificationclick', (event) => {
  console.log('[SW] Notification clicked:', event.notification.data, 'action:', event.action)
  event.notification.close()

  const data = event.notification.data || {}
  const reminderContent = data.content || data.body || ''
  const targetUrl = data.url || '/'

  // Handle action buttons
  if (event.action === 'dismiss') {
    console.log('[SW] User dismissed notification')
    return
  }

  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      console.log(`[SW] Found ${clientList.length} client(s) for notification click`)

      // Try to find an existing window to focus
      if (clientList && clientList.length > 0) {
        let client = clientList[0]

        // Prefer a focused window if available
        for (let i = 0; i < clientList.length; i++) {
          const c = clientList[i]
          if (c && c.focused) {
            client = c
            break
          }
        }

        if (client) {
          console.log('[SW] Focusing existing window and sending message')
          // Send message to the client to trigger voice playback
          client.postMessage({
            type: 'NOTIFICATION_CLICKED',
            payload: {
              content: reminderContent,
              body: reminderContent
            }
          })

          // Navigate to the target URL if specified
          if (targetUrl && targetUrl !== '/') {
            return client.navigate(targetUrl).then(() => client.focus())
          }

          return client.focus()
        }
      }

      // No existing window, open a new one with autoSpeak parameter
      const url = reminderContent
        ? `/?autoSpeak=${encodeURIComponent(reminderContent)}`
        : targetUrl

      console.log('[SW] Opening new window:', url)
      return self.clients.openWindow(url)
    }).catch((e) => {
      console.error('[SW] Error handling notification click:', e)
    })
  )
})
