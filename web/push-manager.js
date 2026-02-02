// VoiceFlow Web Push Manager

class VoiceFlowPushManager {
  constructor() {
    this.registration = null;
    this.subscription = null;
    this.publicKey = null;
  }

  // Initialize push notifications
  async initialize() {
    try {
      console.log('Initializing VoiceFlow Push Manager...');

      // Check if service workers are supported
      if (!('serviceWorker' in navigator)) {
        throw new Error('Service Workers not supported');
      }

      // Check if push messaging is supported
      if (!('PushManager' in window)) {
        throw new Error('Push messaging not supported');
      }

      // Register service worker
      await this.registerServiceWorker();

      // Get VAPID public key from server
      await this.fetchVapidPublicKey();

      // Subscribe to push notifications
      await this.subscribeToPush();

      console.log('✅ VoiceFlow Push Manager initialized successfully');
      return true;
    } catch (error) {
      console.error('❌ Failed to initialize push manager:', error);
      return false;
    }
  }

  // Register service worker
  async registerServiceWorker() {
    try {
      this.registration = await navigator.serviceWorker.register('/sw.js');
      console.log('✅ Service Worker registered:', this.registration);

      // Wait for service worker to be ready
      await navigator.serviceWorker.ready;
      console.log('✅ Service Worker ready');
    } catch (error) {
      console.error('❌ Service Worker registration failed:', error);
      throw error;
    }
  }

  // Fetch VAPID public key from server
  async fetchVapidPublicKey() {
    try {
      const baseUrl = window.location.origin.includes('localhost')
        ? 'https://service.muhuo.site'
        : 'https://service.muhuo.site';

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
  async subscribeToPush() {
    try {
      if (!this.registration || !this.publicKey) {
        throw new Error('Service Worker or VAPID key not ready');
      }

      // Check if already subscribed
      this.subscription = await this.registration.pushManager.getSubscription();

      if (this.subscription) {
        console.log('✅ Already subscribed to push notifications');
        await this.sendSubscriptionToServer();
        return;
      }

      // Request notification permission
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') {
        throw new Error('Notification permission denied');
      }

      // Convert VAPID key to Uint8Array
      const applicationServerKey = this.urlBase64ToUint8Array(this.publicKey);

      // Subscribe to push manager
      this.subscription = await this.registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: applicationServerKey
      });

      console.log('✅ Subscribed to push notifications');

      // Send subscription to server
      await this.sendSubscriptionToServer();
    } catch (error) {
      console.error('❌ Failed to subscribe to push notifications:', error);
      throw error;
    }
  }

  // Send subscription to server
  async sendSubscriptionToServer() {
    try {
      if (!this.subscription) {
        throw new Error('No subscription available');
      }

      const baseUrl = window.location.origin.includes('localhost')
        ? 'https://service.muhuo.site'
        : 'https://service.muhuo.site';

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
      const baseUrl = window.location.origin.includes('localhost')
        ? 'https://service.muhuo.site'
        : 'https://service.muhuo.site';

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

  // Reset VAPID keys
  async resetVapidKeys() {
    try {
      const baseUrl = window.location.origin.includes('localhost')
        ? 'https://service.muhuo.site'
        : 'https://service.muhuo.site';

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

      // Reinitialize
      await this.initialize();
    } catch (error) {
      console.error('❌ Failed to reset VAPID keys:', error);
      throw error;
    }
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
}

// Global instance
window.voiceFlowPushManager = new VoiceFlowPushManager();

// Auto-initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, initializing push manager...');
  window.voiceFlowPushManager.initialize().catch(console.error);
});

// Export for Flutter Web
window.initializeWebPush = () => window.voiceFlowPushManager.initialize();
window.testWebPush = () => window.voiceFlowPushManager.testPush();
window.resetWebPushKeys = () => window.voiceFlowPushManager.resetVapidKeys();