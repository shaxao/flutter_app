import { ref } from 'vue'

export interface LogEntry {
  id: string
  timestamp: number
  type: 'request' | 'response' | 'error'
  method?: string
  url: string
  status?: number
  duration?: number
  headers?: any
  body?: any
  response?: any
  error?: any
}

interface XHRExtended extends XMLHttpRequest {
  _url?: string
  _method?: string
  _startTime?: number
}

class LoggerService {
  private static instance: LoggerService
  logs = ref<LogEntry[]>([])
  isEnabled = ref(false)
  isPaused = ref(false)
  maxLogs = 1000

  private constructor() {
    this.loadSettings()
  }

  static getInstance(): LoggerService {
    if (!LoggerService.instance) {
      LoggerService.instance = new LoggerService()
    }
    return LoggerService.instance
  }

  loadSettings() {
    const saved = localStorage.getItem('dev_logger_enabled')
    this.isEnabled.value = saved === 'true'
    if (this.isEnabled.value) {
      this.initInterceptors()
    }
  }

  toggle(enabled: boolean) {
    this.isEnabled.value = enabled
    localStorage.setItem('dev_logger_enabled', String(enabled))
    if (enabled) {
      this.initInterceptors()
    } else {
      // Ideally we would remove interceptors, but monkey-patching is hard to undo cleanly without keeping original refs.
      // Since this is dev mode, we can just stop collecting logs.
    }
  }

  clear() {
    this.logs.value = []
  }

  addLog(entry: Omit<LogEntry, 'id' | 'timestamp'>) {
    if (!this.isEnabled.value || this.isPaused.value) return

    const newEntry: LogEntry = {
      id: Math.random().toString(36).substring(7),
      timestamp: Date.now(),
      ...entry
    }

    this.logs.value.unshift(newEntry)
    if (this.logs.value.length > this.maxLogs) {
      this.logs.value.pop()
    }
  }

  private initInterceptors() {
    // Prevent double init
    if ((window as any).__logger_intercepted) return
    (window as any).__logger_intercepted = true

    this.interceptFetch()
    this.interceptXHR()
  }

  private interceptFetch() {
    const originalFetch = window.fetch
    window.fetch = async (...args) => {
      const startTime = Date.now()
      const [resource, config] = args
      const url = resource.toString()
      const method = config?.method || 'GET'

      this.addLog({
        type: 'request',
        method,
        url,
        headers: config?.headers,
        body: config?.body
      })

      try {
        const response = await originalFetch(...args)
        const clone = response.clone()
        const duration = Date.now() - startTime

        let resBody = null
        try {
          const contentType = clone.headers.get('content-type')
          if (contentType && contentType.includes('application/json')) {
            resBody = await clone.json()
          } else {
            resBody = await clone.text()
          }
        } catch (e) {
          resBody = '[Unable to read body]'
        }

        this.addLog({
          type: 'response',
          method,
          url,
          status: response.status,
          duration,
          headers: Object.fromEntries(clone.headers.entries()),
          response: resBody
        })

        return response
      } catch (error) {
        const duration = Date.now() - startTime
        this.addLog({
          type: 'error',
          method,
          url,
          duration,
          error: String(error)
        })
        throw error
      }
    }
  }

  private interceptXHR() {
    const originalOpen = XMLHttpRequest.prototype.open
    const originalSend = XMLHttpRequest.prototype.send
    const self = this

    XMLHttpRequest.prototype.open = function (this: XHRExtended, method: string, url: string | URL) {
      this._url = url.toString()
      this._method = method
      this._startTime = Date.now()
      return originalOpen.apply(this, arguments as any)
    }

    XMLHttpRequest.prototype.send = function (this: XHRExtended, body) {
      if (self.isEnabled.value && !self.isPaused.value) {
        self.addLog({
          type: 'request',
          method: this._method,
          url: this._url || 'Unknown',
          body: body
        })
      }

      this.addEventListener('load', () => {
        if (self.isEnabled.value && !self.isPaused.value) {
          const duration = Date.now() - (this._startTime || Date.now())
          let responseData = this.response
          try {
            if (this.responseType === '' || this.responseType === 'text') {
              responseData = JSON.parse(this.responseText)
            }
          } catch (e) {
            // keep original
          }

          self.addLog({
            type: 'response',
            method: this._method,
            url: this._url || 'Unknown',
            status: this.status,
            duration,
            response: responseData
          })
        }
      })

      this.addEventListener('error', () => {
        if (self.isEnabled.value && !self.isPaused.value) {
          const duration = Date.now() - (this._startTime || Date.now())
          self.addLog({
            type: 'error',
            method: this._method,
            url: this._url || 'Unknown',
            duration,
            error: 'Network Error'
          })
        }
      })

      return originalSend.apply(this, arguments as any)
    }
  }
}

export default LoggerService.getInstance()
