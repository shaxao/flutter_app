// VoiceFlow Service Worker for Web Push Notifications

const CACHE_NAME = 'voiceflow-v1';
const urlsToCache = [
  '/',
  '/main.dart.js',
  '/flutter.js',
  '/favicon.png',
];

// Install event
self.addEventListener('install', (event) => {
  console.log('Service Worker installing...');
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('Opened cache');
        return cache.addAll(urlsToCache);
      })
  );
});

// Fetch event
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request)
      .then((response) => {
        // Return cached version or fetch from network
        return response || fetch(event.request);
      }
      )
  );
});

// Push event - Handle incoming push notifications
self.addEventListener('push', (event) => {
  console.log('Push event received:', event);

  let data = {};
  if (event.data) {
    try {
      data = event.data.json();
    } catch (e) {
      data = { title: 'VoiceFlow', body: event.data.text() };
    }
  }

  const title = data.title || 'VoiceFlow 提醒';
  const options = {
    body: data.body || '您有新的提醒',
    icon: '/favicon.png',
    badge: '/favicon.png',
    tag: 'voiceflow-reminder',
    requireInteraction: true,
    actions: [
      {
        action: 'view',
        title: '查看',
        icon: '/favicon.png'
      },
      {
        action: 'dismiss',
        title: '忽略'
      }
    ],
    data: data
  };

  event.waitUntil(
    self.registration.showNotification(title, options)
      .then(() => {
        console.log('Notification shown successfully');

        // 如果是语音提醒，尝试播放语音
        if (data.type === 'voice_reminder') {
          playVoiceReminder(data.body);
        }
      })
      .catch((error) => {
        console.error('Error showing notification:', error);
      })
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  console.log('Notification clicked:', event);

  event.notification.close();

  if (event.action === 'view') {
    // Open the app
    event.waitUntil(
      clients.openWindow('/')
    );
  } else if (event.action === 'dismiss') {
    // Just close the notification
    return;
  } else {
    // Default action - open the app
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Background sync for offline functionality
self.addEventListener('sync', (event) => {
  console.log('Background sync:', event.tag);

  if (event.tag === 'background-sync') {
    event.waitUntil(doBackgroundSync());
  }
});

// Function to play voice reminder
function playVoiceReminder(text) {
  try {
    // Check if Speech Synthesis is available
    if ('speechSynthesis' in self) {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'zh-CN';
      utterance.rate = 0.8;
      utterance.pitch = 1.0;
      utterance.volume = 1.0;

      // Find Chinese voice
      const voices = speechSynthesis.getVoices();
      const chineseVoice = voices.find(voice => voice.lang.startsWith('zh'));
      if (chineseVoice) {
        utterance.voice = chineseVoice;
      }

      speechSynthesis.speak(utterance);
      console.log('Voice reminder played:', text);
    } else {
      console.log('Speech Synthesis not available');
    }
  } catch (error) {
    console.error('Error playing voice reminder:', error);
  }
}

// Background sync function
async function doBackgroundSync() {
  try {
    // Sync any pending data
    console.log('Performing background sync...');

    // You can add logic here to sync reminders, send analytics, etc.

  } catch (error) {
    console.error('Background sync failed:', error);
  }
}

// Message event - Handle messages from the main thread
self.addEventListener('message', (event) => {
  console.log('Service Worker received message:', event.data);

  if (event.data && event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
});

console.log('VoiceFlow Service Worker loaded successfully');