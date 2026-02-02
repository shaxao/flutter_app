import api from '@/api'

class PushService {
  private publicVapidKey: string | null = null
  public subscriptionStatus = 'pending' // pending, subscribed, denied, unsupported

  async init() {
    if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
      this.subscriptionStatus = 'unsupported'
      console.warn('Push messaging is not supported')
      return
    }

    try {
      // 1. Get VAPID public key from backend
      const res = await api.get('/vapid-public-key')
      this.publicVapidKey = res.data.publicKey

      // 2. Check current permission
      if (Notification.permission === 'denied') {
        this.subscriptionStatus = 'denied'
        return
      }

      // 3. Try to subscribe/refresh
      await this.subscribeUser()
    } catch (err) {
      console.error('Push Service Init Error:', err)
      this.subscriptionStatus = 'error'
    }
  }

  async subscribeUser(force = false) {
    try {
      // Check notification permission first
      if (Notification.permission === 'denied') {
        console.warn('[PushService] Notification permission denied')
        this.subscriptionStatus = 'denied'
        return false
      }

      if (Notification.permission === 'default') {
        console.log('[PushService] Notification permission not granted yet')
        this.subscriptionStatus = 'pending'
        return false
      }

      const registration = await navigator.serviceWorker.ready
      let subscription = await registration.pushManager.getSubscription()

      // If key changed or force, unsubscribe and re-subscribe
      if (subscription && force) {
        await subscription.unsubscribe()
        subscription = null
      }

      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.urlBase64ToUint8Array(this.publicVapidKey!)
        })
      }

      console.log('User is subscribed:', subscription)
      this.subscriptionStatus = 'subscribed'

      // 4. Send subscription to backend
      await api.post('/push-subscriptions', subscription)
      return true
    } catch (err) {
      console.error('Failed to subscribe the user: ', err)
      this.subscriptionStatus = 'error'
      return false
    }
  }

  private urlBase64ToUint8Array(base64String: string) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding)
      .replace(/-/g, '+')
      .replace(/_/g, '/')

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}

export default new PushService()
