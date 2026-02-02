import axios from 'axios'
import { showNotify } from 'vant'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 60000, // 60s timeout for AI recognition
})

// Request interceptor
api.interceptors.request.use((config) => {
  // Fix for menu system using /api/menu instead of /api/v1/menu
  if (config.url?.startsWith('/menu/') && config.baseURL?.endsWith('/v1')) {
    config.baseURL = config.baseURL.slice(0, -3)
  }
  return config
})

// Response interceptor
api.interceptors.response.use(
  (response) => response,
  (error) => {
    const msg = error.response?.data?.detail || error.message || '网络请求失败'
    showNotify({ type: 'danger', message: msg })
    return Promise.reject(error)
  }
)

export default api
