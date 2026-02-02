<template>
  <div class="py-1">
    <div class="flex items-center text-sm group">
       <!-- Icon for toggle -->
       <div 
         v-if="canExpand" 
         class="w-5 h-5 flex items-center justify-center cursor-pointer hover:bg-gray-100 rounded mr-1"
         @click.stop="toggle"
       >
          <van-icon :name="expanded ? 'arrow-down' : 'arrow-right'" class="text-gray-400 text-xs" />
       </div>
       <div v-else class="w-5 mr-1"></div> <!-- Spacer -->

       <!-- Name -->
       <span 
         class="flex-1 truncate" 
         :class="canExpand ? 'text-blue-600 cursor-pointer hover:underline' : 'text-gray-700'"
         @click="canExpand ? toggle() : null"
       >
          {{ name }}
          <span v-if="linkedVersionId" class="text-xs text-gray-400 ml-1">
             (关联{{ isLoop ? '·循环' : '' }})
          </span>
       </span>

       <!-- Amount -->
       <span class="text-gray-500 font-medium text-xs ml-2">{{ amount }} {{ unit }}</span>
    </div>

    <!-- Children -->
    <div v-if="expanded && canExpand" class="pl-3 ml-2.5 border-l border-dashed border-gray-200 mt-1">
       <van-loading v-if="loading" size="small" type="spinner" class="py-1" />
       <div v-else-if="items.length === 0" class="text-xs text-gray-400 py-1">无配料信息</div>
       <div v-else>
          <RecipeNode
            v-for="sub in items"
            :key="sub.id"
            :name="sub.ingredient_name"
            :amount="sub.amount"
            :unit="sub.unit"
            :linked-version-id="sub.linked_version_id"
            :visited-ids="nextVisitedIds"
          />
       </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import api from '@/api'
import { showNotify } from 'vant'

const props = defineProps<{
  name: string
  amount: number | string
  unit: string
  linkedVersionId?: number | null
  visitedIds?: number[]
}>()

const expanded = ref(false)
const loading = ref(false)
const items = ref<any[]>([])
const loaded = ref(false)

const isLoop = computed(() => {
  return props.linkedVersionId && props.visitedIds?.includes(props.linkedVersionId)
})

const canExpand = computed(() => {
  return !!props.linkedVersionId && !isLoop.value
})

const nextVisitedIds = computed(() => {
  if (!props.linkedVersionId) return props.visitedIds
  return [...(props.visitedIds || []), props.linkedVersionId]
})

const toggle = async () => {
  if (!canExpand.value) return
  expanded.value = !expanded.value
  
  if (expanded.value && !loaded.value) {
    loading.value = true
    try {
      const res = await api.get(`/menu/recipes/${props.linkedVersionId}/items`)
      items.value = res.data.data || []
      loaded.value = true
    } catch (e) {
      showNotify({ type: 'warning', message: '加载关联配方失败' })
      expanded.value = false // collapse on error
    } finally {
      loading.value = false
    }
  }
}
</script>
