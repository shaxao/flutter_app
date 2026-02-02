// Flutter Web Push Manager - Based on od_web implementation

class FlutterWebPushManager {
  constructor() {
    this.registration = null;
    this.subscription = null;
    this.publicKey = null;
    this.subscriptionStatus = 'pending'; // pending, subscribed, denied, unsupported
    this.broadcastChannel = null;
  }

  // Initialize push notifications
  async init() {
    try {
      console.log('[PushManager] Initializing Flutter Web Push Manager...');

      if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
        this.subscriptionStatus = 'unsupported';
        console.warn('[PushManager] Push messaging is not supported');
        return false;
      }

      // 1. Get VAPID public key from backend
      await this.fetchVapidPublicKey();

      // 2. Check current permission
      if (Notification.permission === 'denied') {
        this.subscriptionStatus = 'denied';
        console.warn('[PushManager] Notification permission denied');
        return false;
      }

      // 3. Register service worker with immediate activation
      await this.registerServiceWorker();

      // 4. Try to subscribe/refresh
      await this.subscribeUser();

      // 5. Setup BroadcastChannel for background communication
      this.setupBroadcastChannel();

      console.log('✅ Flutter Web Push Manager initialized successfully');
      return true;
    } catch (error) {
      console.error('❌ Failed to initialize push manager:', error);
      this.subscriptionStatus = 'error';
      return false;
    }
  }

  // Register service worker with immediate activation
  async registerServiceWorker() {
    try {
      this.registration = await navigator.serviceWorker.register('/sw.js');
      console.log('✅ Service Worker registered:', this.registration);

      // Send SKIP_WAITING message for immediate activation
      if (this.registration.waiting) {
        this.registration.waiting.postMessage({ type: 'SKIP_WAITING' });
      }

      // Wait for service worker to be ready
      await navigator.serviceWorker.ready;
      console.log('✅ Service Worker ready');

      // Setup message listener for service worker messages
      navigator.serviceWorker.addEventListener('message', (event) => {
        console.log('[PushManager] Received message from SW:', event.data);

        if (event.data.type === 'PUSH_RECEIVED_WAKE_UP') {
          this.handlePushWakeUp(event.data.payload);
        } else if (event.data.type === 'NOTIFICATION_CLICKED') {
          this.handleNotificationClick(event.data.payload);
        }
      });

    } catch (error) {
      console.error('❌ Service Worker registration failed:', error);
      throw error;
    }
  }

  // Setup BroadcastChannel for robust background communication
  setupBroadcastChannel() {
    try {
      this.broadcastChannel = new BroadcastChannel('reminder-channel');
      this.broadcastChannel.onmessage = (event) => {
        console.log('[PushManager] BroadcastChannel message:', event.data);

        if (event.data.type === 'PUSH_RECEIVED_WAKE_UP') {
          this.handlePushWakeUp(event.data.payload);
        }
      };
      console.log('✅ BroadcastChannel setup complete');
    } catch (error) {
      console.error('❌ BroadcastChannel setup failed:', error);
    }
  }

  // Handle push wake-up from service worker
  handlePushWakeUp(payload) {
    console.log('[PushManager] Handling push wake-up:', payload);

    // Trigger voice playback if Flutter voice service is available
    if (window.flutterVoiceService && payload.body) {
      window.flutterVoiceService.speak(`提醒事项：${payload.body}`);
    }

    // Notify Flutter app about the push
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      window.flutter_inappwebview.callHandler('onPushReceived', payload);
    }
  }

  // Handle notification click from service worker
  handleNotificationClick(payload) {
    console.log('[PushManager] Handling notification click:', payload);

    // Trigger voice playback
    if (window.flutterVoiceService && payload.content) {
      window.flutterVoiceService.speak(`提醒事项：${payload.content}`);
    }
  }

  // Fetch VAPID public key from server
  async fetchVapidPublicKey() {
    try {
      const baseUrl = 'https://service.muhuo.site';
      const response = await fetch(`${baseUrl}/api/v1/vapid-public-key`);

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      this.publicKey = data.publicKey;
      console.log('✅ VAPID public key fetched');
    } catch (error) {
      console.error('❌ Failed to fetch VAPID public key:', error);
      throw error;
    }
  }

  // Subscribe to push notifications
  async subscribeUser(force = false) {
    try {
      // Check notification permission first
      if (Notification.permission === 'denied') {
        console.warn('[PushManager] Notification permission denied');
        this.subscriptionStatus = 'denied';
        return false;
      }

      if (Notification.permission === 'default') {
        console.log('[PushManager] Requesting notification permission...');
        const permission = await Notification.requestPermission();
        if (permission !== 'granted') {
          this.subscriptionStatus = 'denied';
          return false;
        }
      }

      const registration = await navigator.serviceWorker.ready;
      let subscription = await registration.pushManager.getSubscription();

      // If key changed or force, unsubscribe and re-subscribe
      if (subscription && force) {
        await subscription.unsubscribe();
        subscription = null;
      }

      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.urlBase64ToUint8Array(this.publicKey)
        });
      }

      this.subscription = subscription;
      console.log('✅ User is subscribed:', subscription);
      this.subscriptionStatus = 'subscribed';

      // Send subscription to backend
      await this.sendSubscriptionToServer();
      return true;
    } catch (err) {
      console.error('❌ Failed to subscribe the user: ', err);
      this.subscriptionStatus = 'error';
      return false;
    }
  }

  // Send subscription to server
  async sendSubscriptionToServer() {
    try {
      if (!this.subscription) {
        throw new Error('No subscription available');
      }

      const baseUrl = 'https://service.muhuo.site';
      const subscriptionData = {
        endpoint: this.subscription.endpoint,
        keys: {
          p256dh: this.arrayBufferToBase64(this.subscription.getKey('p256dh')),
          auth: this.arrayBufferToBase64(this.subscription.getKey('auth'))
        }
      };

      const response = await fetch(`${baseUrl}/api/v1/push-subscriptions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(subscriptionData)
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      console.log('✅ Subscription sent to server');
    } catch (error) {
      console.error('❌ Failed to send subscription to server:', error);
      throw error;
    }
  }

  // Test push notification
  async testPush() {
    try {
      const baseUrl = 'https://service.muhuo.site';
      const response = await fetch(`${baseUrl}/api/v1/test-push`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const result = await response.json();
      console.log('✅ Test push sent:', result);
      return result;
    } catch (error) {
      console.error('❌ Failed to send test push:', error);
      throw error;
    }
  }

  // Reset VAPID keys and re-subscribe
  async resetVapidKeys() {
    try {
      const baseUrl = 'https://service.muhuo.site';
      const response = await fetch(`${baseUrl}/api/v1/vapid-keys`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      console.log('✅ VAPID keys reset');

      // Clear current subscription
      if (this.subscription) {
        await this.subscription.unsubscribe();
        this.subscription = null;
      }

      // Reinitialize
      await this.init();
    } catch (error) {
      console.error('❌ Failed to reset VAPID keys:', error);
      throw error;
    }
  }

  // Get subscription status
  getStatus() {
    return {
      status: this.subscriptionStatus,
      hasSubscription: !!this.subscription,
      hasPublicKey: !!this.publicKey,
      notificationPermission: Notification.permission,
      serviceWorkerSupported: 'serviceWorker' in navigator,
      pushManagerSupported: 'PushManager' in window
    };
  }

  // Utility function to convert VAPID key
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4);
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/');

    const rawData = window.atob(base64);
    const outputArray = new Uint8Array(rawData.length);

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i);
    }
    return outputArray;
  }

  // Utility function to convert ArrayBuffer to Base64
  arrayBufferToBase64(buffer) {
    const bytes = new Uint8Array(buffer);
    let binary = '';
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return window.btoa(binary);
  }

  // Cleanup
  destroy() {
    if (this.broadcastChannel) {
      this.broadcastChannel.close();
      this.broadcastChannel = null;
    }
  }
}

// Global instance
window.flutterWebPushManager = new FlutterWebPushManager();

// Auto-initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
  console.log('[PushManager] DOM loaded, initializing push manager...');
  window.flutterWebPushManager.init().catch(console.error);
});

// Export functions for Flutter Web
window.initializeWebPush = () => window.flutterWebPushManager.init();
window.testWebPush = () => window.flutterWebPushManager.testPush();
window.resetWebPushKeys = () => window.flutterWebPushManager.resetVapidKeys();
window.getWebPushStatus = () => window.flutterWebPushManager.getStatus();