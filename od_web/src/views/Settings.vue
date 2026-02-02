<template>
  <div class="min-h-screen bg-gray-50 dark:bg-[#0C0A09] p-4 pb-20 transition-colors duration-300">
    <div class="flex justify-between items-center mb-4">
      <h1 class="text-xl font-bold text-gray-800 dark:text-gray-100">系统设置</h1>
      <van-icon name="question-o" size="20" class="text-primary dark:text-blue-400" @click="startGuide" />
    </div>

    <van-cell-group inset title="外部上传配置 (可选)" class="mb-4 !mx-0 shadow-sm dark:!bg-[#1C1917]" id="guide-ext-token">
      <van-field
        v-model="extToken"
        label="Token"
        placeholder="请输入上传 Token"
        label-align="top"
        class="dark:!bg-[#1C1917] dark:!text-gray-100"
      />
      <van-field
        v-model="extCookie"
        label="Cookie"
        placeholder="请输入 Cookie (如有)"
        label-align="top"
        class="dark:!bg-[#1C1917] dark:!text-gray-100"
      />
      <van-field
        v-model="extUa"
        label="User Agent"
        placeholder="请输入 User Agent"
        label-align="top"
        class="dark:!bg-[#1C1917] dark:!text-gray-100"
      />
    </van-cell-group>

    <van-cell-group inset title="OpenAI 配置 (可选)" class="mb-4 !mx-0 shadow-sm dark:!bg-[#1C1917]" id="guide-openai">
      <van-field
        v-model="openaiUrl"
        label="API URL"
        placeholder="https://api.openai.com/v1/chat/completions"
        label-align="top"
        class="dark:!bg-[#1C1917] dark:!text-gray-100"
      />
      <van-field
        v-model="openaiKey"
        type="password"
        label="API Key"
        placeholder="sk-..."
        label-align="top"
        class="dark:!bg-[#1C1917] dark:!text-gray-100"
      />
    </van-cell-group>

    <van-cell-group inset title="开发选项" class="mb-4 !mx-0 shadow-sm dark:!bg-[#1C1917]">
      <van-cell title="调试模式" center class="dark:!bg-[#1C1917] dark:!text-gray-100">
        <template #right-icon>
          <van-switch v-model="debugMode" size="20px" @change="toggleDebugMode" />
        </template>
      </van-cell>
      <van-cell title="清除缓存" is-link @click="clearCache" class="dark:!bg-[#1C1917] dark:!text-gray-100" />
      <van-cell title="版本信息" :value="appVersion" class="dark:!bg-[#1C1917] dark:!text-gray-100" />
    </van-cell-group>
    
    <div class="mt-8 px-2" id="guide-save">
      <van-button type="primary" block round @click="saveSettings">
        保存配置
      </van-button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { showSuccessToast, showConfirmDialog, showToast } from 'vant'
import { driver } from "driver.js"
import "driver.js/dist/driver.css"

const extToken = ref('')
const extCookie = ref('')
const extUa = ref('')
const openaiUrl = ref('')
const openaiKey = ref('')
const debugMode = ref(false)
const appVersion = ref('1.2.46')

onMounted(() => {
  extToken.value = localStorage.getItem('ext_token') || ''
  extCookie.value = localStorage.getItem('ext_cookie') || ''
  extUa.value = localStorage.getItem('ext_ua') || ''
  openaiUrl.value = localStorage.getItem('openai_api_url') || ''
  openaiKey.value = localStorage.getItem('openai_api_key') || ''
  debugMode.value = localStorage.getItem('debug_mode') === 'true'

  // Auto start guide if first time
  if (!localStorage.getItem('guide_shown')) {
    setTimeout(startGuide, 500)
  }
})

const toggleDebugMode = (value: boolean) => {
  localStorage.setItem('debug_mode', value ? 'true' : 'false')
  showToast(value ? '调试模式已开启' : '调试模式已关闭')
}

const clearCache = async () => {
  try {
    await showConfirmDialog({
      title: '清除缓存',
      message: '确定要清除所有缓存数据吗？',
    })
    
    // Clear specific cache keys
    const keysToKeep = ['ext_token', 'ext_cookie', 'ext_ua', 'openai_api_url', 'openai_api_key', 'debug_mode']
    const allKeys = Object.keys(localStorage)
    allKeys.forEach(key => {
      if (!keysToKeep.includes(key)) {
        localStorage.removeItem(key)
      }
    })
    
    showSuccessToast('缓存已清除')
  } catch (e) {
    // User cancelled
  }
}

const startGuide = () => {
  const driverObj = driver({
    showProgress: true,
    nextBtnText: '下一步',
    prevBtnText: '上一步',
    doneBtnText: '完成',
    steps: [
      { 
        element: '#guide-ext-token', 
        popover: { 
          title: '外部上传配置', 
          description: '可选项。配置 Token 后，生成的台账将自动上传到外部系统。' 
        } 
      },
      { 
        element: '#guide-openai', 
        popover: { 
          title: 'AI 助手配置', 
          description: '可选项。配置 OpenAI 兼容接口后，可使用图片智能识别功能。' 
        } 
      },
      { 
        element: '#guide-save', 
        popover: { 
          title: '保存生效', 
          description: '配置完成后，别忘了点击保存哦！' 
        } 
      },
    ],
    onDestroyed: () => {
      localStorage.setItem('guide_shown', 'true')
    }
  })

  driverObj.drive()
}

const saveSettings = () => {
  localStorage.setItem('ext_token', extToken.value)
  localStorage.setItem('ext_cookie', extCookie.value)
  localStorage.setItem('ext_ua', extUa.value)
  localStorage.setItem('openai_api_url', openaiUrl.value)
  localStorage.setItem('openai_api_key', openaiKey.value)
  
  showSuccessToast('保存成功')
}
</script>
