<template>
  <div class="w-full">
    <!-- Trigger Field -->
    <div 
      class="flex items-center justify-between h-9 px-3 bg-gray-50 dark:bg-gray-800 rounded border border-gray-100 dark:border-gray-700 cursor-pointer transition-colors duration-300"
      @click="openSelect"
    >
      <div class="flex items-center min-w-0 flex-1">
        <span v-if="selectedEmployee" class="text-sm text-gray-800 dark:text-gray-200 truncate">
          {{ selectedEmployee.name }} <span class="text-gray-400 text-xs ml-1">({{ selectedEmployee.id }})</span>
        </span>
        <span v-else class="text-sm text-gray-400 dark:text-gray-500">选择员工</span>
      </div>
      <div class="flex items-center ml-2">
        <van-icon v-if="selectedEmployee" name="clear" class="text-gray-400 hover:text-gray-500 p-1" @click.stop="clearSelection" />
        <van-icon name="arrow-down" class="text-gray-300 dark:text-gray-600 text-xs" />
      </div>
    </div>

    <!-- Selection Popup -->
    <van-popup 
      v-model:show="showPopup" 
      position="bottom" 
      round 
      teleport="body"
      class="h-[70vh] flex flex-col bg-white dark:bg-[#1C1917]"
      :lock-scroll="false"
      safe-area-inset-bottom
    >
      <!-- Header -->
      <div class="flex-shrink-0 px-4 py-3 border-b border-gray-100 dark:border-gray-800 flex items-center gap-3">
        <div class="flex-1 relative">
          <van-icon name="search" class="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 z-10" />
          <input 
            v-model="searchQuery" 
            placeholder="搜索姓名或工号" 
            class="w-full h-9 pl-9 pr-3 bg-gray-50 dark:bg-gray-800 rounded-lg text-sm text-gray-800 dark:text-gray-200 placeholder-gray-400 dark:placeholder-gray-600 outline-none transition-colors"
          />
        </div>
        <span class="text-blue-600 text-sm font-medium cursor-pointer" @click="showPopup = false">取消</span>
      </div>

      <!-- List Content -->
      <div class="flex-1 overflow-y-auto min-h-0 touch-auto overscroll-contain" style="-webkit-overflow-scrolling: touch;">
        <!-- Loading State -->
        <div v-if="loading" class="py-10 flex flex-col items-center justify-center text-gray-400">
          <van-loading size="24px" class="mb-2" />
          <span class="text-xs">加载员工数据...</span>
        </div>

        <!-- Error State -->
        <div v-else-if="error" class="py-10 flex flex-col items-center justify-center text-red-500">
          <van-icon name="warning-o" size="32" class="mb-2" />
          <span class="text-xs">{{ error }}</span>
          <button class="mt-3 px-4 py-1.5 bg-red-50 dark:bg-red-900/20 rounded-full text-xs text-red-600 dark:text-red-400" @click="fetchEmployees">重试</button>
        </div>

        <!-- Empty State -->
        <div v-else-if="filteredList.length === 0" class="py-10 flex flex-col items-center justify-center text-gray-400">
          <van-icon name="search" size="32" class="mb-2 opacity-50" />
          <span class="text-xs">未找到相关员工</span>
        </div>

        <!-- Data List -->
        <div v-else class="py-2">
          <div 
            v-for="item in filteredList" 
            :key="item.id"
            class="px-4 py-3 active:bg-gray-50 dark:active:bg-gray-800 flex items-center justify-between transition-colors cursor-pointer border-b border-gray-50 dark:border-gray-800/50 last:border-0"
            @click="selectItem(item)"
          >
            <div class="flex flex-col">
              <span class="text-sm font-medium text-gray-800 dark:text-gray-200" :class="{'text-blue-600 dark:text-blue-400': isSelected(item)}">
                {{ item.name }}
              </span>
              <span class="text-xs text-gray-400 mt-0.5">{{ item.id }}</span>
            </div>
            <van-icon v-if="isSelected(item)" name="success" class="text-blue-600 dark:text-blue-400" />
          </div>
        </div>
      </div>
    </van-popup>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import api from '@/api'

interface Employee {
  id: string
  name: string
}

const props = defineProps<{
  modelValue?: string // Employee ID
  initialName?: string // Optional initial name for display if list not loaded
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'select', employee: Employee | null): void
}>()

const showPopup = ref(false)
const searchQuery = ref('')
const loading = ref(false)
const error = ref('')
const list = ref<Employee[]>([])

// Compute selected employee object from modelValue
const selectedEmployee = computed(() => {
  if (!props.modelValue) return null
  const found = list.value.find(e => e.id === props.modelValue)
  if (found) return found
  // If we have a value but list isn't loaded or item not found, 
  // rely on initialName if provided, otherwise show ID
  if (props.initialName) return { id: props.modelValue, name: props.initialName }
  return { id: props.modelValue, name: props.modelValue }
})

const filteredList = computed(() => {
  const q = searchQuery.value.trim().toLowerCase()
  if (!q) return list.value
  return list.value.filter(item => 
    item.name.toLowerCase().includes(q) || 
    item.id.toLowerCase().includes(q)
  )
})

const isSelected = (item: Employee) => {
  return item.id === props.modelValue
}

const fetchEmployees = async () => {
  loading.value = true
  error.value = ''
  try {
    const res = await api.get('/employees')
    if (res.data.code === 200) {
      list.value = res.data.data || []
    } else {
      throw new Error(res.data.message || '获取失败')
    }
  } catch (e: any) {
    console.error(e)
    error.value = e.message || '网络请求错误'
  } finally {
    loading.value = false
  }
}

const openSelect = () => {
  showPopup.value = true
  if (list.value.length === 0 && !loading.value) {
    fetchEmployees()
  }
}

const selectItem = (item: Employee) => {
  emit('update:modelValue', item.id)
  emit('select', item)
  showPopup.value = false
}

const clearSelection = () => {
  emit('update:modelValue', '')
  emit('select', null)
}

// Initial fetch if needed, or wait for user interaction?
// User requirement: "在组件挂载时，调用后端API".
onMounted(() => {
  fetchEmployees()
})
</script>

<style scoped>
/* Custom scrollbar for webkit */
::-webkit-scrollbar {
  width: 4px;
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