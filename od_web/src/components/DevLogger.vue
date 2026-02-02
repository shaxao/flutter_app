<template>
  <!-- Floating Button -->
  <div
    v-if="enabled && !expanded"
    class="fixed bottom-24 right-4 z-[9999] w-14 h-14 rounded-full bg-gradient-to-br from-purple-500 to-pink-500 dark:from-purple-600 dark:to-pink-600 shadow-lg shadow-purple-500/50 dark:shadow-purple-900/50 flex items-center justify-center cursor-move active:scale-95 transition-transform"
    @touchstart="handleTouchStart"
    @touchmove="handleTouchMove"
    @touchend="handleTouchEnd"
    @click="toggleExpand"
    :style="{ transform: `translate(${position.x}px, ${position.y}px)` }"
  >
    <van-icon name="chart-trending-o" class="text-white text-xl" />
    <div v-if="logs.length > 0" class="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-red-500 text-white text-xs flex items-center justify-center font-bold">
      {{ logs.length > 99 ? '99+' : logs.length }}
    </div>
  </div>

  <!-- Expanded Panel -->
  <div
    v-if="enabled && expanded"
    class="fixed inset-4 z-[9999] bg-white dark:bg-[#1C1917] rounded-3xl shadow-2xl border border-gray-200 dark:border-gray-800 flex flex-col overflow-hidden"
  >
    <!-- Header -->
    <div class="flex items-center justify-between p-4 border-b border-gray-200 dark:border-gray-800 bg-gradient-to-r from-purple-500 to-pink-500 dark:from-purple-600 dark:to-pink-600">
      <div class="flex items-center gap-2">
        <van-icon name="chart-trending-o" class="text-white text-xl" />
        <div>
          <h3 class="text-white font-bold">开发者日志</h3>
          <p class="text-white/80 text-xs">实时请求监控</p>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <van-button
          size="mini"
          round
          plain
          class="!bg-white/20 !border-white/30 !text-white"
          @click="clearLogs"
        >
          清空
        </van-button>
        <van-icon name="cross" class="text-white text-xl cursor-pointer" @click="toggleExpand" />
      </div>
    </div>

    <!-- Logs Content -->
    <div class="flex-1 overflow-y-auto p-4 bg-gray-50 dark:bg-[#0C0A09]">
      <div v-if="logs.length === 0" class="flex flex-col items-center justify-center h-full text-gray-400 dark:text-gray-600">
        <van-icon name="info-o" size="48" class="mb-2" />
        <p class="text-sm">暂无日志记录</p>
      </div>
      <div v-else class="space-y-2">
        <div
          v-for="(log, index) in reversedLogs"
          :key="index"
          class="bg-white dark:bg-[#1C1917] rounded-xl p-3 border border-gray-200 dark:border-gray-800 shadow-sm cursor-pointer hover:border-purple-500 dark:hover:border-purple-600 transition-colors"
          @click="viewLogDetail(log)"
        >
          <div class="flex items-start justify-between mb-2">
            <div class="flex items-center gap-2">
              <span
                class="px-2 py-0.5 rounded-full text-xs font-bold"
                :class="getMethodClass(log.method)"
              >
                {{ log.method }}
              </span>
              <span
                class="px-2 py-0.5 rounded-full text-xs font-bold"
                :class="getStatusClass(log.status)"
              >
                {{ log.status }}
              </span>
            </div>
            <span class="text-xs text-gray-400 dark:text-gray-600">{{ log.time }}</span>
          </div>
          <div class="text-sm font-mono text-gray-700 dark:text-gray-300 break-all mb-1">
            {{ log.url }}
          </div>
          <div v-if="log.duration" class="text-xs text-gray-500 dark:text-gray-500">
            耗时: {{ log.duration }}ms
          </div>
          <div class="text-xs text-purple-500 dark:text-purple-400 mt-1">
            点击查看详情 →
          </div>
        </div>
      </div>
    </div>

    <!-- Footer Stats -->
    <div class="p-3 border-t border-gray-200 dark:border-gray-800 bg-white dark:bg-[#1C1917]">
      <div class="flex justify-around text-center">
        <div>
          <div class="text-xs text-gray-500 dark:text-gray-400">总请求</div>
          <div class="text-lg font-bold text-gray-800 dark:text-gray-100">{{ logs.length }}</div>
        </div>
        <div>
          <div class="text-xs text-gray-500 dark:text-gray-400">成功</div>
          <div class="text-lg font-bold text-emerald-500">{{ successCount }}</div>
        </div>
        <div>
          <div class="text-xs text-gray-500 dark:text-gray-400">失败</div>
          <div class="text-lg font-bold text-red-500">{{ errorCount }}</div>
        </div>
      </div>
    </div>

    <!-- Log Detail Dialog -->
    <van-popup
      v-model:show="showLogDetail"
      position="bottom"
      round
      style="height: 80%"
      closeable
    >
      <div v-if="selectedLog" class="p-4 h-full flex flex-col">
        <h3 class="text-lg font-bold mb-4 text-center dark:text-white">请求详情</h3>
        
        <div class="flex-1 overflow-y-auto space-y-4">
          <!-- Basic Info -->
          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
            <div class="flex items-center gap-2 mb-2">
              <span
                class="px-2 py-0.5 rounded-full text-xs font-bold"
                :class="getMethodClass(selectedLog.method)"
              >
                {{ selectedLog.method }}
              </span>
              <span
                class="px-2 py-0.5 rounded-full text-xs font-bold"
                :class="getStatusClass(selectedLog.status)"
              >
                {{ selectedLog.status }}
              </span>
            </div>
            <div class="text-sm font-mono text-gray-700 dark:text-gray-300 break-all mb-2">
              {{ selectedLog.url }}
            </div>
            <div class="flex justify-between text-xs text-gray-500 dark:text-gray-400">
              <span>时间: {{ selectedLog.time }}</span>
              <span v-if="selectedLog.duration">耗时: {{ selectedLog.duration }}ms</span>
            </div>
          </div>

          <!-- Request Data -->
          <div v-if="selectedLog.requestData" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
            <div class="font-bold text-sm mb-2 text-gray-700 dark:text-gray-300">请求数据</div>
            <pre class="text-xs bg-white dark:bg-gray-900 p-2 rounded overflow-x-auto text-gray-800 dark:text-gray-200">{{ formatJSON(selectedLog.requestData) }}</pre>
          </div>

          <!-- Response Data -->
          <div v-if="selectedLog.responseData" class="bg-gray-50 dark:bg-gray-800 rounded-lg p-3">
            <div class="font-bold text-sm mb-2 text-gray-700 dark:text-gray-300">响应数据</div>
            <pre class="text-xs bg-white dark:bg-gray-900 p-2 rounded overflow-x-auto text-gray-800 dark:text-gray-200">{{ formatJSON(selectedLog.responseData) }}</pre>
          </div>
        </div>
      </div>
    </van-popup>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { showConfirmDialog } from 'vant'

interface Log {
  time: string
  method: string
  url: string
  status: number
  duration?: number
  requestData?: any
  responseData?: any
}

const enabled = ref(false)
const expanded = ref(false)
const logs = ref<Log[]>([])
const position = ref({ x: 0, y: 0 })
const touchStart = ref({ x: 0, y: 0, posX: 0, posY: 0 })
const isDragging = ref(false)
const selectedLog = ref<Log | null>(null)
const showLogDetail = ref(false)

const reversedLogs = computed(() => [...logs.value].reverse())
const successCount = computed(() => logs.value.filter(l => l.status >= 200 && l.status < 300).length)
const errorCount = computed(() => logs.value.filter(l => l.status >= 400).length)

const toggleExpand = () => {
  if (!isDragging.value) {
    expanded.value = !expanded.value
  }
}

const handleTouchStart = (e: TouchEvent) => {
  const touch = e.touches[0]
  if (!touch) return
  touchStart.value = {
    x: touch.clientX,
    y: touch.clientY,
    posX: position.value.x,
    posY: position.value.y
  }
  isDragging.value = false
}

const handleTouchMove = (e: TouchEvent) => {
  e.preventDefault()
  const touch = e.touches[0]
  if (!touch) return
  const deltaX = touch.clientX - touchStart.value.x
  const deltaY = touch.clientY - touchStart.value.y
  
  if (Math.abs(deltaX) > 5 || Math.abs(deltaY) > 5) {
    isDragging.value = true
  }
  
  position.value = {
    x: touchStart.value.posX + deltaX,
    y: touchStart.value.posY + deltaY
  }
}

const handleTouchEnd = () => {
  setTimeout(() => {
    isDragging.value = false
  }, 100)
}

const addLog = (log: Log) => {
  logs.value.push(log)
  if (logs.value.length > 100) {
    logs.value.shift()
  }
}

const viewLogDetail = (log: Log) => {
  selectedLog.value = log
  showLogDetail.value = true
}

const formatJSON = (data: any) => {
  try {
    return JSON.stringify(data, null, 2)
  } catch (e) {
    return String(data)
  }
}

const clearLogs = async () => {
  try {
    await showConfirmDialog({
      title: '清空日志',
      message: '确定要清空所有日志吗？',
    })
    logs.value = []
  } catch (e) {
    // Cancelled
  }
}

const getMethodClass = (method: string) => {
  const classes: Record<string, string> = {
    GET: 'bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-400',
    POST: 'bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400',
    PUT: 'bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400',
    DELETE: 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400',
    PATCH: 'bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-400',
  }
  return classes[method] || 'bg-gray-100 text-gray-600 dark:bg-gray-900/30 dark:text-gray-400'
}

const getStatusClass = (status: number) => {
  if (status >= 200 && status < 300) {
    return 'bg-emerald-100 text-emerald-600 dark:bg-emerald-900/30 dark:text-emerald-400'
  } else if (status >= 400) {
    return 'bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400'
  }
  return 'bg-gray-100 text-gray-600 dark:bg-gray-900/30 dark:text-gray-400'
}

// Intercept axios requests
import api from '@/api'

let axiosInterceptorId: number | null = null

const setupAxiosInterceptor = () => {
  if (axiosInterceptorId !== null) return
  
  // Request interceptor
  api.interceptors.request.use((config) => {
    if (enabled.value) {
      const timestamp = +new Date();
      (config as any).__startTime = timestamp;
      (config as any).__requestData = config.data;
    }
    return config
  })
  
  // Response interceptor
  const resId = api.interceptors.response.use(
    (response) => {
      if (enabled.value) {
        const startTime = (response.config as any).__startTime || +new Date()
        const duration = +new Date() - startTime
        const now = new Date()
        const time = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`
        
        addLog({
          time,
          method: (response.config.method || 'GET').toUpperCase(),
          url: response.config.url || '',
          status: response.status,
          duration,
          requestData: (response.config as any).__requestData,
          responseData: response.data
        })
      }
      return response
    },
    (error) => {
      if (enabled.value) {
        const startTime = (error.config as any)?.__startTime || +new Date()
        const duration = +new Date() - startTime
        const now = new Date()
        const time = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}:${String(now.getSeconds()).padStart(2, '0')}`
        
        addLog({
          time,
          method: (error.config?.method || 'GET').toUpperCase(),
          url: error.config?.url || '',
          status: error.response?.status || 0,
          duration,
          requestData: (error.config as any)?.__requestData,
          responseData: error.response?.data
        })
      }
      return Promise.reject(error)
    }
  )
  
  axiosInterceptorId = resId
}

const removeAxiosInterceptor = () => {
  if (axiosInterceptorId !== null) {
    api.interceptors.response.eject(axiosInterceptorId)
    axiosInterceptorId = null
  }
}

onMounted(() => {
  // Check if debug mode is enabled
  enabled.value = localStorage.getItem('debug_mode') === 'true'
  
  if (enabled.value) {
    setupAxiosInterceptor()
  }
  
  // Listen for debug mode changes
  window.addEventListener('storage', (e) => {
    if (e.key === 'debug_mode') {
      const newValue = e.newValue === 'true'
      enabled.value = newValue
      if (newValue) {
        setupAxiosInterceptor()
      } else {
        removeAxiosInterceptor()
      }
    }
  })
})

onUnmounted(() => {
  removeAxiosInterceptor()
})
</script>
