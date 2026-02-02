<template>
  <div 
    v-if="logger.isEnabled.value"
    class="fixed z-[9999] flex flex-col bg-white dark:bg-[#1C1917] border border-gray-200 dark:border-gray-800 shadow-2xl rounded-tl-2xl transition-shadow duration-300"
    :class="isMinimized ? 'w-auto h-auto rounded-xl' : 'w-[600px] h-[500px] max-w-[95vw] max-h-[80vh] rounded-xl'"
    :style="positionStyle"
  >
    <!-- Header (Draggable) -->
    <div 
      class="flex items-center justify-between px-4 py-2 bg-gray-50 dark:bg-gray-800/50 border-b border-gray-200 dark:border-gray-800 rounded-t-xl cursor-move select-none"
      @mousedown="startDrag"
      @touchstart="startDrag"
    >
      <div class="flex items-center gap-3">
        <div class="flex items-center gap-2">
           <div class="w-2.5 h-2.5 rounded-full" :class="logger.isPaused.value ? 'bg-amber-500' : 'bg-green-500 animate-pulse'"></div>
           <span class="text-sm font-bold text-gray-700 dark:text-gray-200">DevLogs</span>
        </div>
        <div v-if="!isMinimized && memoryUsage" class="text-xs text-gray-400 font-mono bg-gray-200 dark:bg-gray-700 px-1.5 py-0.5 rounded">
           MEM: {{ memoryUsage }}
        </div>
      </div>
      <div class="flex items-center gap-2">
        <van-icon :name="isMinimized ? 'expand-o' : 'shrink'" class="text-gray-500 hover:text-gray-700 dark:text-gray-200 cursor-pointer" @click.stop="toggleMinimize" />
      </div>
    </div>

    <!-- Content (when not minimized) -->
    <div v-if="!isMinimized" class="flex-1 flex flex-col min-h-0">
      <!-- Toolbar -->
      <div class="flex items-center justify-between px-3 py-2 border-b border-gray-100 dark:border-gray-800 gap-2 overflow-x-auto">
        <div class="flex gap-2">
           <button 
             v-for="f in filters" 
             :key="f.value"
             class="px-3 py-1.5 text-xs font-bold rounded-full transition-all duration-300 flex items-center gap-1.5 shadow-sm active:scale-95"
             :class="getFilterClass(f.value)"
             @click="activeFilter = f.value"
           >
             <span class="w-1.5 h-1.5 rounded-full" :class="getFilterDotClass(f.value)"></span>
             {{ f.label }}
           </button>
        </div>
        <div class="flex gap-1 bg-gray-100 dark:bg-gray-800 p-1 rounded-lg">
           <button 
             class="p-1.5 rounded-md transition-all duration-200 hover:bg-white dark:hover:bg-gray-700 hover:shadow-sm group relative" 
             title="Clear" 
             @click.stop="logger.clear()"
           >
             <van-icon name="delete-o" class="text-gray-500 dark:text-gray-400 group-hover:text-rose-500 transition-colors" />
           </button>
           <button 
             class="p-1.5 rounded-md transition-all duration-200 hover:bg-white dark:hover:bg-gray-700 hover:shadow-sm group" 
             :title="logger.isPaused.value ? 'Resume' : 'Pause'" 
             @click.stop="logger.isPaused.value = !logger.isPaused.value"
           >
             <van-icon 
               :name="logger.isPaused.value ? 'play-circle-o' : 'pause-circle-o'" 
               class="text-gray-500 dark:text-gray-400 transition-colors"
               :class="logger.isPaused.value ? 'group-hover:text-emerald-500' : 'group-hover:text-amber-500'"
             />
           </button>
           <button 
             class="p-1.5 rounded-md transition-all duration-200 hover:bg-white dark:hover:bg-gray-700 hover:shadow-sm group" 
             title="Export" 
             @click.stop="exportLogs"
           >
             <van-icon name="down" class="text-gray-500 dark:text-gray-400 group-hover:text-blue-500 transition-colors" />
           </button>
        </div>
      </div>

      <!-- Log List -->
      <div class="flex-1 overflow-y-auto p-2 space-y-2 font-mono text-xs">
        <div v-if="filteredLogs.length === 0" class="text-center py-10 text-gray-400">
           No logs captured
        </div>
        <div 
          v-for="log in filteredLogs" 
          :key="log.id" 
          class="bg-white dark:bg-gray-900 border rounded-lg overflow-hidden transition-all"
          :class="getLogBorderClass(log)"
        >
          <!-- Log Header -->
          <div 
            class="flex items-center justify-between px-3 py-2 cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-800"
            @click="toggleExpand(log.id)"
          >
             <div class="flex items-center gap-2 min-w-0">
                <span 
                  class="px-1.5 py-0.5 rounded text-[10px] font-bold uppercase shrink-0 w-12 text-center"
                  :class="getMethodClass(log.method)"
                >
                  {{ log.method }}
                </span>
                <span class="truncate text-gray-600 dark:text-gray-300" :title="log.url">{{ getShortUrl(log.url) }}</span>
             </div>
             <div class="flex items-center gap-2 shrink-0">
                <span v-if="log.status" class="font-bold" :class="getStatusClass(log.status)">{{ log.status }}</span>
                <span v-if="log.duration" class="text-gray-400">{{ log.duration }}ms</span>
                <span class="text-[10px] text-gray-300">{{ formatTime(log.timestamp) }}</span>
             </div>
          </div>

          <!-- Log Details -->
          <div v-if="expandedLogs.has(log.id)" class="px-3 py-2 border-t border-gray-100 dark:border-gray-800 bg-gray-50 dark:bg-black/20">
             <div class="grid grid-cols-1 gap-2">
                <div v-if="log.headers">
                   <div class="text-[10px] font-bold text-gray-400 mb-1">HEADERS</div>
                   <pre class="whitespace-pre-wrap break-all text-gray-600 dark:text-gray-400">{{ log.headers }}</pre>
                </div>
                <div v-if="log.body">
                   <div class="text-[10px] font-bold text-gray-400 mb-1">PAYLOAD</div>
                   <pre class="whitespace-pre-wrap break-all text-blue-600 dark:text-blue-400">{{ formatJson(log.body) }}</pre>
                </div>
                <div v-if="log.response">
                   <div class="text-[10px] font-bold text-gray-400 mb-1">RESPONSE</div>
                   <pre class="whitespace-pre-wrap break-all text-green-600 dark:text-green-400">{{ formatJson(log.response) }}</pre>
                </div>
                <div v-if="log.error">
                   <div class="text-[10px] font-bold text-red-400 mb-1">ERROR</div>
                   <pre class="whitespace-pre-wrap break-all text-red-600 dark:text-red-400">{{ log.error }}</pre>
                </div>
             </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, reactive } from 'vue'
import logger from '@/services/logger'
import type { LogEntry } from '@/services/logger'

const isMinimized = ref(false)
const activeFilter = ref('all')
const expandedLogs = ref(new Set<string>())
const memoryUsage = ref('')
let memInterval: any = null

// Dragging Logic
const position = reactive({ x: window.innerWidth - 620, y: window.innerHeight - 520 })
const isDragging = ref(false)
const dragOffset = reactive({ x: 0, y: 0 })

const positionStyle = computed(() => ({
  left: `${position.x}px`,
  top: `${position.y}px`,
  right: 'auto',
  bottom: 'auto'
}))

const startDrag = (e: MouseEvent | TouchEvent) => {
  // Prevent drag if clicking on controls
  if ((e.target as HTMLElement).closest('.van-icon')) return

  isDragging.value = true
  
  let clientX: number
  let clientY: number
  
  // Use type guard to safely check for touches
  const touchEvent = e as TouchEvent
  if ('touches' in e && touchEvent.touches && touchEvent.touches.length > 0) {
    const touch = touchEvent.touches[0]
    if (touch) {
      clientX = touch.clientX
      clientY = touch.clientY
    } else {
      return
    }
  } else {
    // Fallback to mouse event properties
    const mouseE = e as MouseEvent
    clientX = mouseE.clientX
    clientY = mouseE.clientY
  }
  
  dragOffset.x = clientX - position.x
  dragOffset.y = clientY - position.y
  
  document.addEventListener('mousemove', onDrag)
  document.addEventListener('mouseup', stopDrag)
  document.addEventListener('touchmove', onDrag, { passive: false })
  document.addEventListener('touchend', stopDrag)
}

const onDrag = (e: MouseEvent | TouchEvent) => {
  if (!isDragging.value) return
  e.preventDefault()
  
  let clientX: number
  let clientY: number
  
  // Use type guard to safely check for touches
  const touchEvent = e as TouchEvent
  if ('touches' in e && touchEvent.touches && touchEvent.touches.length > 0) {
    const touch = touchEvent.touches[0]
    if (touch) {
      clientX = touch.clientX
      clientY = touch.clientY
    } else {
      return
    }
  } else {
    // Fallback to mouse event properties
    const mouseE = e as MouseEvent
    clientX = mouseE.clientX
    clientY = mouseE.clientY
  }
  
  // Boundary checks
  let newX = clientX - dragOffset.x
  let newY = clientY - dragOffset.y
  
  const maxW = window.innerWidth - (isMinimized.value ? 200 : 600)
  const maxH = window.innerHeight - (isMinimized.value ? 60 : 500)
  
  position.x = Math.min(Math.max(0, newX), Math.max(0, maxW))
  position.y = Math.min(Math.max(0, newY), Math.max(0, maxH))
}

const stopDrag = () => {
  isDragging.value = false
  document.removeEventListener('mousemove', onDrag)
  document.removeEventListener('mouseup', stopDrag)
  document.removeEventListener('touchmove', onDrag)
  document.removeEventListener('touchend', stopDrag)
}

const filters = [
  { label: 'All', value: 'all' },
  { label: 'XHR/Fetch', value: 'xhr' },
  { label: 'Errors', value: 'error' },
]

const filteredLogs = computed(() => {
  const all = logger.logs.value
  if (activeFilter.value === 'all') return all
  if (activeFilter.value === 'error') return all.filter(l => l.type === 'error' || (l.status && l.status >= 400))
  if (activeFilter.value === 'xhr') return all.filter(l => l.type !== 'error')
  return all
})

const getFilterClass = (val: string) => {
  if (activeFilter.value === val) {
    // Active State: Vibrant Gradient
    switch (val) {
      case 'all': return 'bg-gradient-to-r from-violet-600 to-indigo-600 text-white shadow-lg shadow-indigo-500/40 border-0'
      case 'xhr': return 'bg-gradient-to-r from-cyan-600 to-blue-600 text-white shadow-lg shadow-cyan-500/40 border-0'
      case 'error': return 'bg-gradient-to-r from-rose-600 to-red-700 text-white shadow-lg shadow-rose-500/40 border-0'
    }
  }
  // Inactive State: High contrast text on neutral bg
  return 'bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-white font-bold border border-gray-200 dark:border-gray-700 hover:bg-gray-200 dark:hover:bg-gray-700'
}

const getFilterDotClass = (val: string) => {
  if (activeFilter.value === val) return 'bg-white/90'
  switch (val) {
      case 'all': return 'bg-indigo-500'
      case 'xhr': return 'bg-cyan-500'
      case 'error': return 'bg-rose-500'
      default: return 'bg-gray-400'
  }
}

const toggleMinimize = () => {
  isMinimized.value = !isMinimized.value
}

const toggleExpand = (id: string) => {
  if (expandedLogs.value.has(id)) {
    expandedLogs.value.delete(id)
  } else {
    expandedLogs.value.add(id)
  }
}

const getShortUrl = (url: string) => {
  try {
    const u = new URL(url)
    return u.pathname + u.search
  } catch {
    return url
  }
}

const formatTime = (ts: number) => {
  return new Date(ts).toLocaleTimeString('en-GB', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' })
}

const formatJson = (data: any) => {
  try {
    if (typeof data === 'string') {
        // Try parsing string as JSON
        try {
            return JSON.stringify(JSON.parse(data), null, 2)
        } catch {
            return data
        }
    }
    return JSON.stringify(data, null, 2)
  } catch {
    return String(data)
  }
}

const getLogBorderClass = (log: LogEntry) => {
  if (log.type === 'error' || (log.status && log.status >= 400)) return 'border-red-200 dark:border-red-900/50'
  if (log.type === 'response') return 'border-green-200 dark:border-green-900/50'
  return 'border-gray-100 dark:border-gray-800'
}

const getMethodClass = (method?: string) => {
  const m = (method || '').toUpperCase()
  switch (m) {
    case 'GET': return 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
    case 'POST': return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
    case 'PUT': return 'bg-orange-100 text-orange-700 dark:bg-orange-900/30 dark:text-orange-300'
    case 'DELETE': return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300'
    default: return 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300'
  }
}

const getStatusClass = (status?: number) => {
  if (!status) return ''
  if (status >= 500) return 'text-red-600 dark:text-red-400'
  if (status >= 400) return 'text-orange-600 dark:text-orange-400'
  if (status >= 300) return 'text-blue-600 dark:text-blue-400'
  return 'text-green-600 dark:text-green-400'
}

const exportLogs = () => {
  const blob = new Blob([JSON.stringify(logger.logs.value, null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `dev-logs-${Date.now()}.json`
  a.click()
  URL.revokeObjectURL(url)
}

const updateMemory = () => {
  const perf = window.performance as any
  if (perf && perf.memory) {
    const used = perf.memory.usedJSHeapSize
    memoryUsage.value = (used / 1024 / 1024).toFixed(1) + ' MB'
  } else {
    memoryUsage.value = 'N/A'
  }
}

onMounted(() => {
  // Initial position: Bottom Right
  position.x = window.innerWidth - 620
  position.y = window.innerHeight - 520
  if (position.x < 0) position.x = 20
  if (position.y < 0) position.y = 20
  
  updateMemory()
  memInterval = setInterval(updateMemory, 2000)
})

onUnmounted(() => {
  if (memInterval) clearInterval(memInterval)
})
</script>

<style scoped>
/* Scrollbar */
::-webkit-scrollbar {
  width: 4px;
  height: 4px;
}
::-webkit-scrollbar-track {
  background: transparent;
}
::-webkit-scrollbar-thumb {
  background: #E5E7EB;
  border-radius: 2px;
}
.dark ::-webkit-scrollbar-thumb {
  background: #374151;
}
</style>