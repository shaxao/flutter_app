<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 dark:from-[#0C0A09] dark:to-[#1C1917] pb-20 transition-colors duration-300">
    <van-pull-refresh v-model="refreshing" @refresh="onRefresh">
      <div class="p-5">
        <!-- Header -->
        <div class="flex justify-between items-center mb-6 pt-2">
          <div>
            <h1 class="text-2xl font-bold text-gray-800 dark:text-gray-100 tracking-tight">营业额仪表盘</h1>
            <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">实时数据监控</p>
          </div>
          <div class="text-xs text-gray-400 dark:text-gray-500">
            更新于 {{ lastUpdated }}
          </div>
        </div>

        <!-- Main Stats Cards -->
        <div class="grid grid-cols-2 gap-4 mb-6">
          <!-- Total Sales Card -->
          <div class="relative overflow-hidden rounded-3xl bg-gradient-to-br from-emerald-500 to-teal-600 dark:from-emerald-600 dark:to-teal-700 p-6 text-white shadow-xl shadow-emerald-500/20 dark:shadow-emerald-900/30">
            <div class="absolute -right-8 -top-8 w-32 h-32 bg-white/10 rounded-full blur-2xl"></div>
            <div class="relative z-10">
              <div class="flex items-center gap-2 mb-2">
                <div class="w-8 h-8 rounded-lg bg-white/20 flex items-center justify-center backdrop-blur-sm">
                  <van-icon name="gold-coin-o" class="text-white" />
                </div>
                <span class="text-sm opacity-90">总销售额</span>
              </div>
              <div class="text-3xl font-bold mb-1">¥{{ formatNumber(totalSales) }}</div>
              <div class="text-xs opacity-75">今日累计收入</div>
            </div>
          </div>

          <!-- Achievement Rate Card -->
          <div class="relative overflow-hidden rounded-3xl bg-white dark:bg-[#1C1917] p-6 shadow-lg border border-gray-100 dark:border-gray-800">
            <div class="absolute -right-8 -top-8 w-32 h-32 bg-gradient-to-br from-blue-100 to-purple-100 dark:from-blue-900/20 dark:to-purple-900/20 rounded-full blur-2xl"></div>
            <div class="relative z-10">
              <div class="flex items-center gap-2 mb-2">
                <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-blue-500 to-purple-500 flex items-center justify-center">
                  <van-icon name="chart-trending-o" class="text-white text-sm" />
                </div>
                <span class="text-sm text-gray-600 dark:text-gray-400">达成率</span>
              </div>
              <div class="text-3xl font-bold mb-1" :class="Number(achievementRate) >= 100 ? 'text-emerald-500' : 'text-orange-500'">
                {{ achievementRate }}%
              </div>
              <div class="text-xs text-gray-400 dark:text-gray-500">目标: ¥{{ formatNumber(planTotal) }}</div>
            </div>
          </div>
        </div>

        <!-- Chart Card -->
        <div class="bg-white dark:bg-[#1C1917] rounded-3xl p-6 shadow-lg mb-6 border border-gray-100 dark:border-gray-800">
          <div class="flex justify-between items-center mb-6">
            <div>
              <h3 class="text-lg font-bold text-gray-800 dark:text-gray-100">时段销售趋势</h3>
              <p class="text-xs text-gray-400 dark:text-gray-500 mt-1">实时 vs 计划对比</p>
            </div>
            <div class="flex gap-3 text-xs">
              <div class="flex items-center gap-1">
                <span class="w-3 h-3 rounded-full bg-gradient-to-r from-blue-500 to-cyan-500"></span>
                <span class="text-gray-600 dark:text-gray-400">实际</span>
              </div>
              <div class="flex items-center gap-1">
                <span class="w-3 h-3 rounded-full bg-gray-300 dark:bg-gray-600"></span>
                <span class="text-gray-600 dark:text-gray-400">计划</span>
              </div>
            </div>
          </div>
          <div ref="chartRef" class="w-full h-72"></div>
        </div>

        <!-- Stats Grid -->
        <div class="grid grid-cols-3 gap-4 mb-6">
          <div class="bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-blue-900/20 dark:to-cyan-900/20 rounded-2xl p-4 border border-blue-100 dark:border-blue-900/30">
            <div class="text-xs text-blue-600 dark:text-blue-400 mb-1">今日预算</div>
            <div class="text-lg font-bold text-gray-800 dark:text-gray-100">¥{{ formatNumber(planTotal) }}</div>
          </div>
          <div class="bg-gradient-to-br from-emerald-50 to-teal-50 dark:from-emerald-900/20 dark:to-teal-900/20 rounded-2xl p-4 border border-emerald-100 dark:border-emerald-900/30">
            <div class="text-xs text-emerald-600 dark:text-emerald-400 mb-1">实际营收</div>
            <div class="text-lg font-bold text-gray-800 dark:text-gray-100">¥{{ formatNumber(totalSales) }}</div>
          </div>
          <div class="bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-900/20 dark:to-pink-900/20 rounded-2xl p-4 border border-purple-100 dark:border-purple-900/30">
            <div class="text-xs text-purple-600 dark:text-purple-400 mb-1">数据状态</div>
            <div class="text-sm font-bold text-gray-800 dark:text-gray-100">{{ loading ? '更新中' : '已同步' }}</div>
          </div>
        </div>
      </div>
    </van-pull-refresh>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed, onUnmounted } from 'vue'
import * as echarts from 'echarts'
import api from '@/api'
import { showToast } from 'vant'

const loading = ref(false)
const refreshing = ref(false)
const chartRef = ref<HTMLElement | null>(null)
const chartInstance = ref<echarts.ECharts | null>(null)
const timer = ref<any>(null)

const totalSales = ref(0)
const planTotal = ref(0)
const lastUpdated = ref('--:--')
const hourlyData = ref<{ hour: string, actual: number | null, plan: number }[]>([])

const achievementRate = computed(() => {
  if (planTotal.value === 0) return '0.00'
  return ((totalSales.value / planTotal.value) * 100).toFixed(2)
})

const formatNumber = (num: number) => {
  return num.toLocaleString('zh-CN', { minimumFractionDigits: 0, maximumFractionDigits: 0 })
}

const onRefresh = async () => {
  await fetchData()
  refreshing.value = false
}

const fetchData = async () => {
  loading.value = true
  try {
    const now = new Date()
    lastUpdated.value = `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`

    const resRevenue = await api.get('/revenue')
    let currentTotal = 0
    if (resRevenue.data && resRevenue.data.revenue) {
       const parts = String(resRevenue.data.revenue).split(',')
       const val = parseFloat(parts[0]?.trim() || '0')
       if (!isNaN(val)) currentTotal = val
    }
    totalSales.value = currentTotal

    const todayStr = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0') + '-' + String(now.getDate()).padStart(2, '0')
    const resPlan = await api.get('/staff/daily-schedule', { params: { date: todayStr } }) 
    const salesPlan = resPlan.data.salesPlan || {}
    
    let pTotal = 0
    Object.values(salesPlan).forEach((v: any) => {
       const cleanVal = String(v).replace(/,/g, '')
       const val = parseFloat(cleanVal)
       if (!isNaN(val)) pTotal += val
    })
    planTotal.value = pTotal

    updateHourlyData(currentTotal, salesPlan)

  } catch (e) {
    console.error(e)
    showToast('数据加载失败')
  } finally {
    loading.value = false
  }
}

const updateHourlyData = (currentTotal: number, salesPlan: any) => {
  const now = new Date()
  const currentHour = now.getHours()
  const dateKey = now.toISOString().split('T')[0] || ''
  
  const historyKey = 'revenue_history_v1'
  let history = JSON.parse(localStorage.getItem(historyKey) || '{}')
  
  const yesterday = new Date(now)
  yesterday.setDate(yesterday.getDate() - 1)
  const yesterdayKey = yesterday.toISOString().split('T')[0] || ''
  
  const newHistory: Record<string, any> = {}
  if (history && history[dateKey]) newHistory[dateKey] = history[dateKey]
  if (history && history[yesterdayKey]) newHistory[yesterdayKey] = history[yesterdayKey]
  
  if (!newHistory[dateKey]) newHistory[dateKey] = {}
  
  if (currentTotal > 0) {
     if (newHistory[dateKey]) newHistory[dateKey][currentHour] = currentTotal
  }
  
  localStorage.setItem(historyKey, JSON.stringify(newHistory))
  history = newHistory

  const hours = Array.from({length: 16}, (_, i) => i + 8)
  
  const newData = hours.map(h => {
    const planStr = String(salesPlan[h] || '0').replace(/,/g, '')
    const planVal = parseFloat(planStr) || 0
    
    let actualVal: number | null = null
    
    if (h <= currentHour) {
       let valH = 0
       if (h === currentHour) {
         valH = currentTotal
       } else {
         valH = (history[dateKey] && history[dateKey][h]) || 0
       }
       
       let valPrev = 0
       if (h === 8) {
         valPrev = 0
       } else {
         valPrev = (history[dateKey] && history[dateKey][h-1]) || 0
       }
       
       if (valH > 0) {
          let diff = valH - valPrev
          if (diff < 0) diff = 0
          actualVal = diff
       }
    }
    
    return {
       hour: `${h}时`,
       actual: actualVal,
       plan: planVal
    }
  })
  
  hourlyData.value = newData
  renderChart()
}

const renderChart = () => {
  if (!chartRef.value) return
  
  if (!chartInstance.value) {
    chartInstance.value = echarts.init(chartRef.value)
  }

  // Check if dark mode
  const isDark = document.documentElement.classList.contains('dark')
  
  const option = {
    tooltip: {
      trigger: 'axis',
      backgroundColor: isDark ? 'rgba(28, 25, 23, 0.95)' : 'rgba(255, 255, 255, 0.95)',
      borderColor: isDark ? '#374151' : '#e5e7eb',
      textStyle: {
        color: isDark ? '#e5e7eb' : '#374151'
      },
      formatter: (params: any[]) => {
        let res = `${params[0].name}<br/>`
        params.forEach(p => {
           const val = p.value !== undefined && p.value !== null ? `¥${p.value}` : '-'
           res += `${p.marker} ${p.seriesName}: ${val}<br/>`
        })
        return res
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: hourlyData.value.map(i => i.hour),
      axisLine: { lineStyle: { color: isDark ? '#374151' : '#e5e7eb' } },
      axisLabel: { 
        color: isDark ? '#9ca3af' : '#6b7280',
        fontSize: 11
      }
    },
    yAxis: {
      type: 'value',
      splitLine: { lineStyle: { type: 'dashed', color: isDark ? '#1f2937' : '#f3f4f6' } },
      axisLabel: {
         color: isDark ? '#6b7280' : '#9ca3af',
         fontSize: 11
      }
    },
    series: [
      {
        name: '实际',
        type: 'line',
        data: hourlyData.value.map(i => i.actual),
        smooth: true,
        showSymbol: true,
        symbol: 'circle',
        symbolSize: 8,
        itemStyle: { 
          color: '#3b82f6',
          borderWidth: 2,
          borderColor: '#fff'
        },
        lineStyle: { width: 3 },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(59, 130, 246, 0.3)' },
            { offset: 1, color: 'rgba(59, 130, 246, 0.05)' }
          ])
        }
      },
      {
        name: '计划',
        type: 'line',
        data: hourlyData.value.map(i => i.plan),
        smooth: true,
        showSymbol: true,
        symbol: 'circle',
        symbolSize: 6,
        itemStyle: { 
          color: isDark ? '#6b7280' : '#9ca3af'
        },
        lineStyle: { width: 2, type: 'dashed' }
      }
    ]
  }
  
  chartInstance.value.setOption(option)
}

onMounted(() => {
  fetchData()
  
  timer.value = setInterval(() => {
    fetchData()
  }, 5 * 60 * 1000)
  
  window.addEventListener('resize', handleResize)
})

const handleResize = () => {
  chartInstance.value?.resize()
}

onUnmounted(() => {
  if (timer.value) clearInterval(timer.value)
  window.removeEventListener('resize', handleResize)
  chartInstance.value?.dispose()
})
</script>
