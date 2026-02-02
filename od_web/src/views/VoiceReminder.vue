<template>
  <div
    class="pb-24 min-h-screen relative overflow-hidden bg-[#F7F8FA] dark:bg-[#0C0A09] transition-colors duration-300"
  >
    <!-- Background Decor -->
    <div
      class="absolute -top-20 -right-20 w-72 h-72 bg-emerald-100/50 dark:bg-emerald-900/20 rounded-full mix-blend-multiply dark:mix-blend-screen filter blur-3xl opacity-60 pointer-events-none"
    ></div>
    <div
      class="absolute top-10 -left-20 w-72 h-72 bg-teal-100/50 dark:bg-teal-900/20 rounded-full mix-blend-multiply dark:mix-blend-screen filter blur-3xl opacity-60 pointer-events-none"
    ></div>

    <div class="p-5 relative z-10">
      <!-- Header -->
      <div class="flex justify-between items-center mb-6 pt-2">
        <div>
          <h1
            class="text-2xl font-bold text-gray-800 dark:text-gray-100 tracking-tight"
          >
            语音提醒
          </h1>
          <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
            餐厅食材过期关注事项管理
          </p>
        </div>
        <div class="flex gap-2">
          <div
            class="w-10 h-10 rounded-2xl bg-white dark:bg-gray-800 shadow-sm flex items-center justify-center active:scale-95 transition-transform border border-gray-100 dark:border-gray-700"
            @click="showBatchPopup = true"
          >
            <van-icon name="descending" size="20" class="text-blue-500" />
          </div>
          <div
            class="w-10 h-10 rounded-2xl bg-white dark:bg-gray-800 shadow-sm flex items-center justify-center active:scale-95 transition-transform border border-gray-100 dark:border-gray-700 text-red-400"
            @click="clearAllReminders"
            v-if="reminders.length > 0"
          >
            <van-icon name="delete-o" size="20" />
          </div>
          <div
            class="w-10 h-10 rounded-2xl bg-white dark:bg-gray-800 shadow-sm flex items-center justify-center active:scale-95 transition-transform border border-gray-100 dark:border-gray-700"
            @click="showAddPopup = true"
          >
            <van-icon name="plus" size="20" class="text-emerald-500" />
          </div>
        </div>
      </div>

      <!-- Reminder List -->
      <div class="space-y-4">
        <!-- System Status Panel -->
        <div
          class="bg-white/40 dark:bg-white/5 backdrop-blur-md rounded-3xl p-4 border border-white/20 mb-6 shadow-sm"
        >
          <div class="flex items-center justify-between mb-3">
            <h4
              class="text-xs font-bold text-gray-400 uppercase tracking-widest"
            >
              系统运行状态
            </h4>
            <div class="text-[10px] text-gray-400">
              上次检查: {{ lastCheckTime }}
            </div>
          </div>
          <div class="flex flex-wrap gap-2 mb-3">
            <span
              v-if="pushStatus === 'subscribed'"
              class="px-2 py-0.5 rounded-full bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 text-[10px] font-bold"
              >推送正常</span
            >
            <span
              v-else
              @click="fixPush"
              class="px-2 py-0.5 rounded-full bg-red-100 dark:bg-red-900/30 text-red-600 dark:text-red-400 text-[10px] font-bold animate-pulse cursor-pointer"
              >推送异常 (点击修复)</span
            >

            <span
              v-if="isAudioUnlocked"
              class="px-2 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 text-[10px] font-bold"
              >语音已解锁</span
            >
            <span
              v-else
              class="px-2 py-0.5 rounded-full bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 text-[10px] font-bold animate-pulse"
              >语音待解锁</span
            >

            <span
              v-if="schedulerStatus.isPlaying"
              class="px-2 py-0.5 rounded-full bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 text-[10px] font-bold"
              >调度器运行中</span
            >
            <span
              v-else
              class="px-2 py-0.5 rounded-full bg-gray-100 dark:bg-gray-900/30 text-gray-600 dark:text-gray-400 text-[10px] font-bold"
              >调度器未启动</span
            >
          </div>
          <div class="text-[10px] text-gray-500 space-y-1">
            <div>已调度提醒: {{ schedulerStatus.scheduledCount }} 个</div>
            <div>保活音频: {{ schedulerStatus.keepAliveStatus }}</div>
            <div>音频上下文: {{ schedulerStatus.audioContextState }}</div>
          </div>
        </div>
        <p class="text-[10px] text-gray-500 leading-relaxed">
          <van-icon name="warning-o" class="mr-1" />
          iOS 系统要求：必须安装到主屏幕使用，且首次进入需点击任意位置解锁语音。
          <span class="text-blue-500 underline ml-2" @click="fetchLogs"
            >查看推送日志</span
          >
          <span class="text-red-400 underline ml-2" @click="resetSystem"
            >重置系统</span
          >
        </p>

        <div v-if="loading" class="flex justify-center py-10">
          <van-loading type="spinner" color="#10B981" />
        </div>

        <div
          v-else-if="reminders.length === 0"
          class="flex flex-col items-center justify-center py-20 opacity-40"
        >
          <van-icon name="bell" size="48" class="text-gray-300" />
          <p class="text-sm mt-2">暂无提醒任务</p>
        </div>

        <div
          v-for="item in sortedReminders"
          :key="item.id"
          class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-xl rounded-3xl p-5 shadow-sm border border-white dark:border-gray-800 flex items-center justify-between group active:scale-[0.98] transition-all"
        >
          <div class="flex-1 min-w-0 mr-4">
            <div class="flex items-center gap-2 mb-1">
              <span
                class="text-lg font-bold text-emerald-600 dark:text-emerald-400 font-mono"
                >{{ item.time }}</span
              >
              <span
                v-if="!item.enabled"
                class="px-1.5 py-0.5 rounded-md bg-gray-100 dark:bg-gray-800 text-[10px] text-gray-400"
                >已禁用</span
              >
            </div>
            <p
              class="text-sm text-gray-700 dark:text-gray-300 truncate font-medium"
            >
              {{ item.content }}
            </p>
          </div>

          <div class="flex items-center gap-3">
            <van-switch
              v-model="item.enabled"
              size="18px"
              active-color="#10B981"
              @update:model-value="toggleReminder(item)"
              @click.stop
            />
            <div class="flex gap-2">
              <div
                class="p-2 rounded-xl bg-gray-50 dark:bg-gray-800 text-gray-400 active:text-blue-500"
                @click.stop="openEdit(item)"
              >
                <van-icon name="edit" />
              </div>
              <div
                class="p-2 rounded-xl bg-gray-50 dark:bg-gray-800 text-gray-400 active:text-emerald-500"
                @click.stop="copyContent(item.content)"
              >
                <van-icon name="description" />
              </div>
              <div
                class="p-2 rounded-xl bg-gray-50 dark:bg-gray-800 text-gray-400 active:text-red-500"
                @click.stop="deleteReminder(item.id)"
              >
                <van-icon name="delete-o" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Voice Test Section -->
      <div
        class="mt-8 bg-emerald-50/50 dark:bg-emerald-900/10 rounded-3xl p-4 border border-emerald-100/50 dark:border-emerald-900/20"
      >
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <van-icon name="volume-o" class="text-emerald-500" />
            <span
              class="text-xs font-medium text-emerald-700 dark:text-emerald-400"
              >语音播报与推送测试</span
            >
          </div>
          <div class="flex gap-2">
            <van-button
              size="mini"
              plain
              round
              type="primary"
              color="#10B981"
              @click="testVoice"
              >语音测试</van-button
            >
            <van-button
              size="mini"
              plain
              round
              type="primary"
              color="#3B82F6"
              @click="sendTestPush"
              >推送测试</van-button
            >
          </div>
        </div>
        <p
          class="text-[10px] text-emerald-600/60 dark:text-emerald-400/40 mt-2"
        >
          如果无法听到声音，请点击测试并确保已开启设备音量。系统将优先使用本地
          TTS。
        </p>
      </div>
    </div>

    <!-- Add/Edit Popup - Redesigned with Soft UI Evolution -->
    <van-popup
      v-model:show="showAddPopup"
      position="bottom"
      round
      safe-area-inset-bottom
      :style="{
        background: 'transparent',
        boxShadow: 'none'
      }"
      :overlay-style="{
        background: 'rgba(0, 0, 0, 0.6)',
        backdropFilter: 'blur(8px)'
      }"
    >
      <div class="bg-white dark:bg-[#1C1917] rounded-t-[32px] shadow-2xl pb-safe">
        <!-- Header with drag indicator -->
        <div class="pt-3 pb-4 px-6">
          <div class="w-10 h-1 bg-gray-300 dark:bg-gray-700 rounded-full mx-auto mb-4"></div>
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-xl font-bold text-gray-900 dark:text-white tracking-tight">
                {{ editingId ? "修改提醒" : "新建提醒" }}
              </h3>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                {{ editingId ? "编辑提醒任务详情" : "创建新的语音提醒任务" }}
              </p>
            </div>
            <button
              @click="closeAddPopup"
              class="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center active:scale-95 transition-transform"
            >
              <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <!-- Form Content -->
        <div class="px-6 pb-6 space-y-5 max-h-[70vh] overflow-y-auto">
          <!-- Time Input -->
          <div class="space-y-2">
            <label class="text-sm font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-2">
              <svg class="w-4 h-4 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              提醒时间
            </label>
            <button
              @click="showTimePicker = true"
              class="w-full px-4 py-3.5 bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-blue-950/30 dark:to-indigo-950/30 border-2 border-blue-100 dark:border-blue-900/50 rounded-2xl text-left transition-all duration-200 hover:border-blue-300 dark:hover:border-blue-700 active:scale-[0.98] group"
            >
              <div class="flex items-center justify-between">
                <span class="text-base font-semibold text-gray-900 dark:text-white">
                  {{ newTime || '点击选择时间' }}
                </span>
                <svg class="w-5 h-5 text-blue-500 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </button>
          </div>

          <!-- Content Input -->
          <div class="space-y-2">
            <label class="text-sm font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-2">
              <svg class="w-4 h-4 text-orange-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              提醒内容
            </label>
            <textarea
              v-model="newContent"
              placeholder="例如：蜗牛 14点"
              rows="3"
              class="w-full px-4 py-3 bg-gray-50 dark:bg-gray-800/50 border-2 border-gray-200 dark:border-gray-700 rounded-2xl text-gray-900 dark:text-white placeholder-gray-400 focus:border-blue-400 dark:focus:border-blue-600 focus:ring-4 focus:ring-blue-100 dark:focus:ring-blue-900/30 transition-all duration-200 resize-none"
            ></textarea>
          </div>

          <!-- Reminder Type -->
          <div class="space-y-3">
            <label class="text-sm font-semibold text-gray-700 dark:text-gray-300 flex items-center gap-2">
              <svg class="w-4 h-4 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
              </svg>
              提醒方式
            </label>
            <div class="grid grid-cols-3 gap-2">
              <button
                @click="reminderType = 'system'"
                :class="[
                  'px-3 py-3 rounded-xl border-2 transition-all duration-200 active:scale-95',
                  reminderType === 'system'
                    ? 'bg-blue-500 border-blue-500 text-white shadow-lg shadow-blue-500/30'
                    : 'bg-white dark:bg-gray-800 border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:border-blue-300 dark:hover:border-blue-700'
                ]"
              >
                <svg class="w-5 h-5 mx-auto mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                <div class="text-xs font-medium">系统通知</div>
              </button>
              <button
                @click="reminderType = 'ai_voice'"
                :class="[
                  'px-3 py-3 rounded-xl border-2 transition-all duration-200 active:scale-95',
                  reminderType === 'ai_voice'
                    ? 'bg-blue-500 border-blue-500 text-white shadow-lg shadow-blue-500/30'
                    : 'bg-white dark:bg-gray-800 border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:border-blue-300 dark:hover:border-blue-700'
                ]"
              >
                <svg class="w-5 h-5 mx-auto mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                </svg>
                <div class="text-xs font-medium">AI语音</div>
              </button>
              <button
                @click="reminderType = 'custom_audio'"
                :class="[
                  'px-3 py-3 rounded-xl border-2 transition-all duration-200 active:scale-95',
                  reminderType === 'custom_audio'
                    ? 'bg-blue-500 border-blue-500 text-white shadow-lg shadow-blue-500/30'
                    : 'bg-white dark:bg-gray-800 border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:border-blue-300 dark:hover:border-blue-700'
                ]"
              >
                <svg class="w-5 h-5 mx-auto mb-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3" />
                </svg>
                <div class="text-xs font-medium">自定义</div>
              </button>
            </div>
            <p class="text-xs text-gray-500 dark:text-gray-400 px-1">
              <span v-if="reminderType === 'system'">📱 仅发送系统通知，不播放语音</span>
              <span v-else-if="reminderType === 'ai_voice'">🤖 使用 AI 生成自然语音播报</span>
              <span v-else>🎵 使用您上传的自定义音频文件</span>
            </p>
          </div>

          <!-- AI Voice Model -->
          <div v-if="reminderType === 'ai_voice'" class="space-y-2">
            <label class="text-sm font-semibold text-gray-700 dark:text-gray-300">语音模型</label>
            <button
              @click="showModelPicker = true"
              class="w-full px-4 py-3.5 bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-950/30 dark:to-pink-950/30 border-2 border-purple-100 dark:border-purple-900/50 rounded-2xl text-left transition-all duration-200 hover:border-purple-300 dark:hover:border-purple-700 active:scale-[0.98] group"
            >
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-gray-900 dark:text-white">
                  <span v-if="voiceModel === 'tts-1'">TTS-1 (标准音质)</span>
                  <span v-else-if="voiceModel === 'tts-1-hd'">TTS-1-HD (高清音质)</span>
                  <span v-else>{{ voiceModel }}</span>
                </span>
                <svg class="w-5 h-5 text-purple-500 group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </div>
            </button>
          </div>

          <!-- Custom Audio Upload -->
          <div v-if="reminderType === 'custom_audio'" class="space-y-2">
            <label class="text-sm font-semibold text-gray-700 dark:text-gray-300">音频文件</label>
            <div class="border-2 border-dashed border-gray-300 dark:border-gray-700 rounded-2xl p-6 text-center hover:border-blue-400 dark:hover:border-blue-600 transition-colors">
              <van-uploader
                :max-count="1"
                accept="audio/*"
                :after-read="handleAudioUpload"
                class="inline-block"
              >
                <div class="cursor-pointer">
                  <svg v-if="!audioFilePath" class="w-12 h-12 mx-auto text-gray-400 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                  <svg v-else class="w-12 h-12 mx-auto text-green-500 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  <p class="text-sm font-medium text-gray-700 dark:text-gray-300">
                    {{ audioFilePath ? '✓ 音频已上传' : '点击上传音频文件' }}
                  </p>
                  <p class="text-xs text-gray-500 mt-1">支持 MP3, WAV, OGG, M4A, AAC</p>
                </div>
              </van-uploader>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="px-6 pb-6 pt-4 border-t border-gray-100 dark:border-gray-800 flex gap-3">
          <button
            @click="closeAddPopup"
            class="flex-1 px-6 py-3.5 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-2xl font-semibold transition-all duration-200 hover:bg-gray-200 dark:hover:bg-gray-700 active:scale-95"
          >
            取消
          </button>
          <button
            @click="saveReminder"
            class="flex-[2] px-6 py-3.5 bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700 text-white rounded-2xl font-semibold shadow-lg shadow-blue-500/30 transition-all duration-200 active:scale-95 flex items-center justify-center gap-2"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
            {{ editingId ? "保存修改" : "确定添加" }}
          </button>
        </div>
      </div>
    </van-popup>

    <!-- Time Picker - Redesigned -->
    <van-popup
      v-model:show="showTimePicker"
      position="bottom"
      round
      :style="{
        background: 'transparent',
        boxShadow: 'none'
      }"
      :overlay-style="{
        background: 'rgba(0, 0, 0, 0.6)',
        backdropFilter: 'blur(8px)'
      }"
    >
      <div class="bg-white dark:bg-[#1C1917] rounded-t-[32px] shadow-2xl">
        <!-- Header -->
        <div class="px-6 pt-6 pb-4 border-b border-gray-100 dark:border-gray-800">
          <div class="w-10 h-1 bg-gray-300 dark:bg-gray-700 rounded-full mx-auto mb-4"></div>
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-bold text-gray-900 dark:text-white">选择提醒时间</h3>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">设置语音提醒的触发时间</p>
            </div>
            <div class="flex items-center gap-2">
              <button
                @click="showTimePicker = false"
                class="px-4 py-2 text-sm font-medium text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white transition-colors"
              >
                取消
              </button>
              <button
                @click="onTimeConfirm({ selectedValues: currentTime })"
                class="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white text-sm font-semibold rounded-xl transition-all duration-200 active:scale-95"
              >
                确定
              </button>
            </div>
          </div>
        </div>
        
        <!-- Time Picker -->
        <van-time-picker
          v-model="currentTime"
          :columns-type="['hour', 'minute']"
          class="custom-time-picker"
        />
      </div>
    </van-popup>

    <!-- Model Picker - Redesigned -->
    <van-popup
      v-model:show="showModelPicker"
      position="bottom"
      round
      :style="{
        background: 'transparent',
        boxShadow: 'none'
      }"
      :overlay-style="{
        background: 'rgba(0, 0, 0, 0.6)',
        backdropFilter: 'blur(8px)'
      }"
    >
      <div class="bg-white dark:bg-[#1C1917] rounded-t-[32px] shadow-2xl">
        <!-- Header -->
        <div class="px-6 pt-6 pb-4 border-b border-gray-100 dark:border-gray-800">
          <div class="w-10 h-1 bg-gray-300 dark:bg-gray-700 rounded-full mx-auto mb-4"></div>
          <div class="flex items-center justify-between">
            <div>
              <h3 class="text-lg font-bold text-gray-900 dark:text-white">选择语音模型</h3>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">不同模型的音质和速度不同</p>
            </div>
            <button
              @click="showModelPicker = false"
              class="w-8 h-8 rounded-full bg-gray-100 dark:bg-gray-800 flex items-center justify-center active:scale-95 transition-transform"
            >
              <svg class="w-4 h-4 text-gray-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>
        
        <!-- Model Picker -->
        <van-picker
          :columns="ttsModels.map((m) => ({ text: m.name, value: m.id }))"
          @confirm="onModelPickerConfirm"
          @cancel="showModelPicker = false"
          :show-toolbar="false"
          class="custom-picker"
        />
        
        <!-- Action Buttons -->
        <div class="px-6 pb-6 pt-4 border-t border-gray-100 dark:border-gray-800 flex gap-3">
          <button
            @click="showModelPicker = false"
            class="flex-1 px-6 py-3 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-2xl font-semibold transition-all duration-200 hover:bg-gray-200 dark:hover:bg-gray-700 active:scale-95"
          >
            取消
          </button>
          <button
            @click="onModelPickerConfirm({ selectedOptions: [{ value: voiceModel }] })"
            class="flex-1 px-6 py-3 bg-gradient-to-r from-purple-500 to-purple-600 hover:from-purple-600 hover:to-purple-700 text-white rounded-2xl font-semibold shadow-lg shadow-purple-500/30 transition-all duration-200 active:scale-95"
          >
            确定
          </button>
        </div>
      </div>
    </van-popup>

    <!-- Audio Activation Overlay -->
    <div
      v-if="showAudioOverlay"
      class="fixed inset-0 z-[10000] bg-black/80 backdrop-blur-xl flex flex-col items-center justify-center p-10 text-center"
    >
      <div
        class="w-24 h-24 bg-emerald-500 rounded-full flex items-center justify-center mb-8 shadow-2xl shadow-emerald-500/50 animate-pulse"
      >
        <van-icon name="volume-o" size="48" class="text-white" />
      </div>
      <h2 class="text-2xl font-black text-white mb-4 tracking-tight">
        确认开启语音提醒
      </h2>
      <p class="text-sm text-white/60 mb-10 leading-relaxed">
        iOS 系统安全性要求：<br />
        必须通过点击授权才能在后台播报提醒语音
      </p>
      <van-button
        type="primary"
        color="linear-gradient(to right, #10B981, #059669)"
        round
        block
        size="large"
        class="font-bold h-14 shadow-lg shadow-emerald-500/30"
        @click="activateAudio"
      >
        立即授权并进入
      </van-button>
    </div>

    <!-- Push Logs Popup -->
    <van-popup
      v-model:show="showLogs"
      position="right"
      style="width: 80%; height: 100%; padding: 20px"
    >
      <div class="flex justify-between items-center mb-4">
        <h3 class="font-bold">推送日志 (最近20条)</h3>
        <van-icon
          name="replay"
          @click="fetchLogs"
          class="active:rotate-180 transition-transform"
        />
      </div>
      <div
        v-if="pushLogs.length === 0"
        class="text-center py-10 text-gray-400 text-xs"
      >
        暂无推送记录
      </div>
      <div
        v-for="(log, i) in pushLogs"
        :key="i"
        class="mb-3 text-xs border-b pb-2"
      >
        <div class="flex justify-between font-mono">
          <span>{{ log.time }}</span>
          <span
            :class="
              log.status === 'Success' ? 'text-emerald-500' : 'text-red-500'
            "
            >{{ log.status }}</span
          >
        </div>
        <div class="text-gray-400 break-all mt-1">
          {{ log.message || log.endpoint }}
        </div>
      </div>
      <van-button
        block
        plain
        size="small"
        @click="showLogs = false"
        class="mt-4"
        >关闭</van-button
      >
    </van-popup>

    <!-- Batch Import Popup -->
    <van-popup
      v-model:show="showBatchPopup"
      position="bottom"
      round
      safe-area-inset-bottom
      class="bg-white dark:bg-[#1C1917]"
      style="padding-bottom: 120px !important"
    >
      <div class="px-5 pt-6 pb-2">
        <h3 class="text-lg font-bold text-gray-800 dark:text-gray-100 mb-2">
          批量导入提醒
        </h3>
        <p class="text-xs text-gray-400 mb-6">
          格式：每行一个“事项 时间”，如：蜗牛 14点
        </p>

        <van-field
          v-model="batchText"
          type="textarea"
          rows="6"
          placeholder="蜗牛 14点&#10;面包 15:30"
          class="rounded-2xl bg-gray-50/50 dark:bg-gray-800/50 border border-gray-100 dark:border-gray-800 mb-6"
        />

        <div class="flex gap-3">
          <van-button
            block
            round
            class="flex-1 !bg-gray-100 dark:!bg-gray-800 !text-gray-500 !border-0"
            @click="showBatchPopup = false"
            >取消</van-button
          >
          <van-button
            block
            round
            type="primary"
            color="#3B82F6"
            class="flex-[2] shadow-lg shadow-blue-500/20"
            @click="processBatchImport"
            >开始导入</van-button
          >
        </div>
      </div>
    </van-popup>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import { showToast, showConfirmDialog, showSuccessToast } from "vant";
import api from "@/api";
import voiceService from "@/services/voice";
import reminderManager from "@/services/reminder";
import audioScheduler from "@/services/audioScheduler";

interface Reminder {
  id: number;
  time: string;
  content: string;
  enabled: boolean;
  reminder_type?: "system" | "ai_voice" | "custom_audio";
  voice_model?: string;
  audio_file_path?: string;
}

import pushService from "@/services/push";

const route = useRoute();
const reminders = ref<Reminder[]>([]);
const pushStatus = ref(pushService.subscriptionStatus);
const isAudioUnlocked = ref(false);
const showAudioOverlay = ref(true);
const wakeLock = ref<any>(null);
const schedulerStatus = ref({
  isPlaying: false,
  scheduledCount: 0,
  audioContextState: "unknown",
  keepAliveStatus: "not-started",
});

// Request Wake Lock to prevent process suspension
const requestWakeLock = async () => {
  if ("wakeLock" in navigator) {
    try {
      wakeLock.value = await (navigator as any).wakeLock.request("screen");
      console.log("Wake Lock is active");
      wakeLock.value.addEventListener("release", () => {
        console.log("Wake Lock was released");
      });
    } catch (err: any) {
      console.error(`${err.name}, ${err.message}`);
    }
  }
};
const lastCheckTime = ref("等待检查...");
const pushLogs = ref<any[]>([]);
const showLogs = ref(false);
const loading = ref(false);
const showAddPopup = ref(false);
const showTimePicker = ref(false);
const showBatchPopup = ref(false);
const editingId = ref<number | null>(null);

const newTime = ref("");
const newContent = ref("");
const batchText = ref("");
const currentTime = ref(["12", "00"]);

// 新增：提醒方式相关
const reminderType = ref<"system" | "ai_voice" | "custom_audio">("ai_voice");
const voiceModel = ref("tts-1");
const audioFilePath = ref("");
const showModelPicker = ref(false);
const ttsModels = ref<any[]>([]);

const sortedReminders = computed(() => {
  return [...reminders.value].sort((a, b) => a.time.localeCompare(b.time));
});

const activateAudio = async () => {
  console.log("[VoiceReminder] 1. Activation started");

  // STEP 1: Close overlay IMMEDIATELY
  isAudioUnlocked.value = true;
  showAudioOverlay.value = false;
  console.log("[VoiceReminder] 2. Overlay closed");

  // STEP 2: Start background tasks immediately (don't wait)
  console.log("[VoiceReminder] 3. Starting background tasks");

  try {
    // Unlock voice service
    voiceService.unlock();
    console.log("[VoiceReminder] 4. Voice unlocked");

    // Speak confirmation (non-blocking)
    voiceService.speak("语音提醒已开启").catch((e) => {
      console.warn("[VoiceReminder] Speak failed:", e);
    });

    showToast("语音服务已激活");

    // Initialize and start audio scheduler
    console.log("[VoiceReminder] 5. Initializing audio scheduler...");
    await audioScheduler.init();
    console.log("[VoiceReminder] 6. Audio scheduler initialized");

    await audioScheduler.start();
    console.log("[VoiceReminder] 7. Audio scheduler started");

    // Update status immediately
    updateSchedulerStatus();

    // Sync reminders in background (non-blocking)
    syncRemindersToScheduler()
      .then(() => {
        console.log("[VoiceReminder] Background audio generation complete");
        showToast("所有提醒音频已准备就绪");
      })
      .catch((e) => {
        console.error("[VoiceReminder] Sync error:", e);
      });

    // Request wake lock (non-blocking)
    requestWakeLock().catch((e) => {
      console.warn("[VoiceReminder] Wake lock failed:", e);
    });
  } catch (e) {
    console.error("[VoiceReminder] Activation error:", e);
    showToast("音频调度器启动失败，将使用实时播放");
  }
};

/**
 * Generate and schedule audio for a single reminder
 */
const scheduleReminderAudio = async (reminder: Reminder) => {
  if (!reminder.enabled) return;

  try {
    const reminderText = `提醒事项：${reminder.content}`;

    // Generate audio with timeout
    const timeoutPromise = new Promise((_, reject) =>
      setTimeout(() => reject(new Error("Timeout")), 10000)
    );

    const generatePromise = voiceService.preloadAudio(reminderText);

    await Promise.race([generatePromise, timeoutPromise]);

    // Get cached audio and schedule
    const cached = voiceService.getCachedAudio(reminderText);
    if (cached) {
      audioScheduler.scheduleAudio(
        `reminder-${reminder.id}`,
        reminder.time,
        cached.url,
        reminder.content
      );
      console.log(
        `[VoiceReminder] Scheduled audio for ${reminder.time}: ${reminder.content}`
      );
      return true;
    }
  } catch (e) {
    console.error(
      `[VoiceReminder] Failed to schedule reminder ${reminder.id}:`,
      e
    );
  }
  return false;
};

/**
 * Sync all reminders to audio scheduler
 * Pre-generate audio for each reminder
 */
const syncRemindersToScheduler = async () => {
  console.log("[VoiceReminder] Syncing reminders to scheduler...");

  // Limit to first 10 reminders to avoid long wait
  const remindersToSync = reminders.value.filter((r) => r.enabled).slice(0, 10);

  if (remindersToSync.length === 0) {
    console.log("[VoiceReminder] No enabled reminders to sync");
    return;
  }

  // Process reminders with timeout for each
  const promises = remindersToSync.map(async (reminder) => {
    try {
      // Add timeout for each reminder (10 seconds max)
      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Timeout")), 10000)
      );

      const generatePromise = (async () => {
        const reminderText = `提醒事项：${reminder.content}`;
        const audioKey = await voiceService.preloadAudio(reminderText);

        if (audioKey) {
          const cached = voiceService.getCachedAudio(reminderText);
          if (cached) {
            audioScheduler.scheduleAudio(
              `reminder-${reminder.id}`,
              reminder.time,
              cached.url,
              reminder.content
            );
            console.log(
              `[VoiceReminder] Scheduled audio for ${reminder.time}: ${reminder.content}`
            );
            return true;
          }
        }
        return false;
      })();

      await Promise.race([generatePromise, timeoutPromise]);
    } catch (e) {
      console.warn(
        `[VoiceReminder] Failed to schedule reminder ${reminder.id}:`,
        e
      );
      // Continue with other reminders even if one fails
    }
  });

  // Wait for all with overall timeout of 30 seconds
  try {
    await Promise.race([
      Promise.allSettled(promises),
      new Promise((_, reject) =>
        setTimeout(() => reject(new Error("Overall timeout")), 30000)
      ),
    ]);
  } catch (e) {
    console.warn(
      "[VoiceReminder] Sync timed out, some reminders may not be scheduled"
    );
  }

  console.log("[VoiceReminder] Sync complete");
};

const fetchLogs = async () => {
  try {
    const res = await api.get("/push-logs");
    pushLogs.value = res.data;
    showLogs.value = true;
  } catch (e) {
    showToast("获取日志失败");
  }
};

const fetchReminders = async () => {
  loading.value = true;
  try {
    const res = await api.get("/voice-reminders");
    reminders.value = res.data;
  } catch (e) {
    showToast("获取提醒列表失败");
  } finally {
    loading.value = false;
  }
};

const onTimeConfirm = ({ selectedValues }: any) => {
  newTime.value = selectedValues.join(":");
  showTimePicker.value = false;
};

const saveReminder = async () => {
  if (!newTime.value || !newContent.value) {
    showToast("请完整填写时间和内容");
    return;
  }

  // 验证自定义音频
  if (reminderType.value === "custom_audio" && !audioFilePath.value) {
    showToast("请上传音频文件");
    return;
  }

  try {
    let savedReminder: Reminder;

    const reminderData = {
      time: newTime.value,
      content: newContent.value,
      reminder_type: reminderType.value,
      voice_model: voiceModel.value,
      audio_file_path: audioFilePath.value || null,
    };

    if (editingId.value) {
      const res = await api.patch(
        `/voice-reminders/${editingId.value}`,
        reminderData
      );
      const idx = reminders.value.findIndex((r) => r.id === editingId.value);
      if (idx !== -1) reminders.value[idx] = res.data;
      savedReminder = res.data;
      showSuccessToast("已修改提醒");
    } else {
      const res = await api.post("/voice-reminders", reminderData);
      reminders.value.push(res.data);
      savedReminder = res.data;
      showSuccessToast("已添加提醒");
    }

    showAddPopup.value = false;
    newTime.value = "";
    newContent.value = "";
    reminderType.value = "ai_voice";
    voiceModel.value = "tts-1";
    audioFilePath.value = "";
    editingId.value = null;

    // Refresh background manager
    reminderManager.refreshReminders();

    // Unlock voice service on first user action
    voiceService.unlock();

    // Schedule only this reminder's audio if unlocked (non-blocking)
    if (isAudioUnlocked.value && savedReminder.reminder_type === "ai_voice") {
      scheduleReminderAudio(savedReminder)
        .then((success) => {
          if (success) {
            showToast("提醒音频已准备就绪");
          }
        })
        .catch((e) => {
          console.error("[VoiceReminder] Failed to schedule audio:", e);
        });
    }
  } catch (e) {
    showToast(editingId.value ? "修改失败" : "添加失败");
  }
};

const openEdit = (item: Reminder) => {
  editingId.value = item.id;
  newTime.value = item.time;
  newContent.value = item.content;
  currentTime.value = item.time.split(":");
  reminderType.value = item.reminder_type || "ai_voice";
  voiceModel.value = item.voice_model || "tts-1";
  audioFilePath.value = item.audio_file_path || "";
  showAddPopup.value = true;
};

const closeAddPopup = () => {
  showAddPopup.value = false;
  editingId.value = null;
  newTime.value = "";
  newContent.value = "";
  reminderType.value = "ai_voice";
  voiceModel.value = "tts-1";
  audioFilePath.value = "";
};

const processBatchImport = async () => {
  if (!batchText.value.trim()) return;

  const lines = batchText.value
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => l);
  const items: { time: string; content: string }[] = [];
  const errors: string[] = [];

  lines.forEach((line, index) => {
    // Regex to match "Content HH:mm" or "Content HH点" or "Content HH"
    // Examples: "蜗牛 14点", "面包 15:30", "可乐 10"
    const match = line.match(
      /^(.+?)\s+(\d{1,2}(?:[:点]\d{1,2})?|(\d{1,2})点?)$/
    );

    if (match) {
      const content = match[1] ? match[1].trim() : "未知事项";
      let timeRaw = match[2] ? match[2].replace("点", ":").trim() : "00:00";

      // If only HH is provided (e.g. "14"), convert to "14:00"
      if (!timeRaw.includes(":")) {
        timeRaw = `${timeRaw.padStart(2, "0")}:00`;
      } else {
        const parts = timeRaw.split(":");
        timeRaw = `${(parts[0] || "00").padStart(2, "0")}:${(
          parts[1] || "00"
        ).padEnd(2, "0")}`;
      }

      // Final check for HH:mm format
      if (/^\d{2}:\d{2}$/.test(timeRaw)) {
        items.push({ time: timeRaw, content });
      } else {
        errors.push(`第 ${index + 1} 行格式有误: ${line}`);
      }
    } else {
      errors.push(`第 ${index + 1} 行格式有误: ${line}`);
    }
  });

  if (errors.length > 0) {
    showConfirmDialog({
      title: "格式错误",
      message: errors.join("\n"),
      confirmButtonText: "知道了",
    });
    return;
  }

  if (items.length === 0) {
    showToast("未识别到有效的提醒事项");
    return;
  }

  try {
    const res = await api.post("/voice-reminders/batch", { items });
    reminders.value.push(...res.data);
    showBatchPopup.value = false;
    batchText.value = "";
    showSuccessToast(`成功导入 ${items.length} 条提醒`);
    reminderManager.refreshReminders();
    voiceService.unlock();
  } catch (e) {
    showToast("批量导入失败");
  }
};

const toggleReminder = async (item: Reminder) => {
  try {
    await api.patch(`/voice-reminders/${item.id}`, {
      enabled: item.enabled,
    });
    reminderManager.refreshReminders();
  } catch (e) {
    item.enabled = !item.enabled;
    showToast("操作失败");
  }
};

const deleteReminder = async (id: number) => {
  try {
    await showConfirmDialog({
      title: "确认删除",
      message: "确定要删除这条提醒吗？",
    });
    await api.delete(`/voice-reminders/${id}`);
    reminders.value = reminders.value.filter((r) => r.id !== id);
    reminderManager.refreshReminders();

    // Remove from audio scheduler
    audioScheduler.removeScheduled(`reminder-${id}`);

    showSuccessToast("已删除");
  } catch (e) {
    if (e !== "cancel") showToast("删除失败");
  }
};

const clearAllReminders = async () => {
  try {
    await showConfirmDialog({
      title: "确认清空",
      message: "确定要清空所有提醒任务吗？",
    });
    await api.delete("/voice-reminders");
    reminders.value = [];
    reminderManager.refreshReminders();

    // Clear all from audio scheduler
    audioScheduler.clearAll();

    showSuccessToast("已全部清空");
  } catch (e) {
    if (e !== "cancel") showToast("清空失败");
  }
};

const copyContent = (content: string) => {
  navigator.clipboard
    .writeText(content)
    .then(() => {
      showSuccessToast("内容已复制");
    })
    .catch(() => {
      showToast("复制失败");
    });
};

const testVoice = () => {
  voiceService.unlock();
  isAudioUnlocked.value = true;
  voiceService.speak("语音提醒功能测试成功，祝您工作愉快。");

  // Request notification permission if not granted
  if ("Notification" in window && Notification.permission === "default") {
    Notification.requestPermission().then(() => {
      pushService.subscribeUser();
      pushStatus.value = pushService.subscriptionStatus;
    });
  }
};

const fixPush = async () => {
  // Step 1: Check if notifications are supported
  if (!('Notification' in window)) {
    showToast("您的浏览器不支持通知功能");
    return;
  }

  // Step 2: Check current permission status
  const currentPermission = Notification.permission;
  console.log("[VoiceReminder] Current notification permission:", currentPermission);

  // Step 3: If permission is default (not asked yet), request it
  if (currentPermission === 'default') {
    showToast("请在弹出的对话框中允许通知权限");
    
    try {
      const permission = await Notification.requestPermission();
      console.log("[VoiceReminder] Permission result:", permission);
      
      if (permission === 'denied') {
        showConfirmDialog({
          title: '通知权限被拒绝',
          message: 'iOS PWA 需要通知权限才能发送提醒。\n\n请按以下步骤操作：\n1. 打开 iOS 设置\n2. 找到 Safari\n3. 点击"通知"\n4. 允许通知权限\n5. 返回应用重试',
          confirmButtonText: '我知道了',
          showCancelButton: false
        });
        return;
      }
      
      if (permission !== 'granted') {
        showToast("未获得通知权限");
        return;
      }
    } catch (error) {
      console.error("[VoiceReminder] Permission request error:", error);
      showToast("请求权限时出错");
      return;
    }
  }

  // Step 4: If permission is denied, show instructions
  if (currentPermission === 'denied') {
    showConfirmDialog({
      title: '通知权限已被拒绝',
      message: 'iOS PWA 需要通知权限才能发送提醒。\n\n请按以下步骤操作：\n1. 打开 iOS 设置\n2. 找到 Safari 浏览器\n3. 点击"通知"\n4. 允许通知权限\n5. 完全关闭并重新打开此应用\n\n注意：必须从主屏幕图标打开应用',
      confirmButtonText: '我知道了',
      showCancelButton: false
    });
    return;
  }

  // Step 5: Permission is granted, try to subscribe
  showToast("正在订阅推送服务...");
  const success = await pushService.subscribeUser(true);
  pushStatus.value = pushService.subscriptionStatus;
  
  if (success) {
    showSuccessToast("推送订阅成功！");
    // Perform a check immediately
    performPushCheck();
  } else {
    showToast("订阅失败，请稍后重试");
  }
};

const resetSystem = async () => {
  try {
    await showConfirmDialog({
      title: "重置提醒系统",
      message: "这将删除服务器推送密钥并注销当前订阅，需要您重新授权。确定吗？",
    });

    await api.delete("/vapid-keys");
    await pushService.subscribeUser(true);
    pushStatus.value = pushService.subscriptionStatus;
    showSuccessToast("系统已重置，请重新开启语音");
    window.location.reload();
  } catch (e) {
    // Cancelled
  }
};

const sendTestPush = async () => {
  try {
    const res = await api.post("/test-push");
    showSuccessToast(`已向 ${res.data.count} 台设备发送测试推送`);
  } catch (e: any) {
    showToast(e.response?.data?.error || "发送失败，请确保已订阅推送");
  }
};

const handleReminderTick = (event: any) => {
  lastCheckTime.value = event.detail.time;
};

// 执行推送状态检查
const performPushCheck = async () => {
  try {
    // Update check time
    const now = new Date();
    lastCheckTime.value = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}`;
    
    // Check notification permission
    if ('Notification' in window) {
      const permission = Notification.permission;
      console.log("[VoiceReminder] Push check - Permission:", permission);
      
      if (permission === 'granted') {
        // Check if we have an active subscription
        if ('serviceWorker' in navigator) {
          const registration = await navigator.serviceWorker.ready;
          const subscription = await registration.pushManager.getSubscription();
          
          if (subscription) {
            pushStatus.value = 'subscribed';
            console.log("[VoiceReminder] Push check - Subscription active");
          } else {
            pushStatus.value = 'pending';
            console.log("[VoiceReminder] Push check - No subscription found");
          }
        }
      } else if (permission === 'denied') {
        pushStatus.value = 'denied';
      } else {
        pushStatus.value = 'pending';
      }
    }
  } catch (error) {
    console.error("[VoiceReminder] Push check error:", error);
  }
};

const handleSWMessage = (event: MessageEvent) => {
  if (event.data && event.data.type === "PUSH_RECEIVED_WAKE_UP") {
    const data = event.data.payload;
    console.log(
      "[VoiceReminder] Received PUSH_RECEIVED_WAKE_UP via ServiceWorker postMessage:",
      data
    );

    // Ensure Keep-Alive is running before speaking
    if (isAudioUnlocked.value) {
      voiceService.unlock(); // This will start Keep-Alive if not running
    }

    if (data && data.body) {
      voiceService.speak(`系统提醒：${data.body}`);
    }
  }
  if (event.data && event.data.type === "NOTIFICATION_CLICKED") {
    const payload = event.data.payload;
    if (payload && payload.body) {
      voiceService.unlock();
      voiceService.speak(`提醒事项：${payload.body}`);
    }
  }
};

const updateSchedulerStatus = () => {
  schedulerStatus.value = audioScheduler.getStatus();
};

// 获取 TTS 模型列表
const fetchTTSModels = async () => {
  try {
    const res = await api.get("/tts-models");
    ttsModels.value = res.data.models;
  } catch (e) {
    console.error("[VoiceReminder] Failed to fetch TTS models:", e);
  }
};

// 处理音频上传
const handleAudioUpload = async (file: any) => {
  const formData = new FormData();
  formData.append("file", file.file);

  try {
    showToast("正在上传音频...");
    const res = await api.post("/voice-reminders/upload-audio", formData, {
      headers: { "Content-Type": "multipart/form-data" },
    });
    audioFilePath.value = res.data.file_path;
    showSuccessToast("音频上传成功");
  } catch (e: any) {
    console.error("[VoiceReminder] Audio upload failed:", e);
    showToast(e.response?.data?.error || "音频上传失败");
  }
};

// 模型选择确认
const onModelPickerConfirm = (value: any) => {
  voiceModel.value = value.selectedOptions[0].value;
  showModelPicker.value = false;
};

onMounted(() => {
  fetchReminders();
  fetchTTSModels(); // 获取 TTS 模型列表

  // Perform initial push status check
  performPushCheck();
  
  // Check push status every 30 seconds
  const checkInterval = setInterval(performPushCheck, 30000);

  // Handle autoSpeak from URL (notification click)
  const autoSpeakText = route.query.autoSpeak as string;
  if (autoSpeakText) {
    console.log("[VoiceReminder] AutoSpeak detected:", autoSpeakText);

    // Clear the URL parameter to avoid loop
    const router = useRouter();
    router.replace({ query: {} }).catch(() => {});

    // Ensure audio is unlocked
    if (!isAudioUnlocked.value) {
      isAudioUnlocked.value = true;
      showAudioOverlay.value = false;
      voiceService.unlock();
    }

    // Play the reminder after a short delay
    setTimeout(() => {
      voiceService.speak(`提醒事项：${autoSpeakText}`).catch((e) => {
        console.warn("[VoiceReminder] AutoSpeak failed:", e);
      });
    }, 500);
  }

  // Update scheduler status every 5 seconds
  updateSchedulerStatus();
  const statusInterval = setInterval(updateSchedulerStatus, 5000);

  // Re-request wake lock when page becomes visible again
  document.addEventListener("visibilitychange", async () => {
    if (wakeLock.value !== null && document.visibilityState === "visible") {
      await requestWakeLock();
    }
  });

  // Listen for timer ticks
  window.addEventListener("reminder-tick", handleReminderTick);

  // Listen for BroadcastChannel (More robust for background)
  const channel = new BroadcastChannel("reminder-channel");
  channel.onmessage = (event) => {
    if (event.data && event.data.type === "PUSH_RECEIVED_WAKE_UP") {
      const data = event.data.payload;
      console.log(
        "[VoiceReminder] Received PUSH_RECEIVED_WAKE_UP via BroadcastChannel:",
        data
      );

      // Ensure Keep-Alive is running before speaking
      if (isAudioUnlocked.value) {
        voiceService.unlock(); // This will start Keep-Alive if not running
      }

      if (data && data.body) {
        voiceService.speak(`系统提醒：${data.body}`);
      }
    }
  };

  // Listen for messages from Service Worker
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.addEventListener("message", handleSWMessage);
  }

  // Cleanup on unmount
  onUnmounted(() => {
    clearInterval(statusInterval);
    clearInterval(checkInterval);
    window.removeEventListener("reminder-tick", handleReminderTick);
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.removeEventListener("message", handleSWMessage);
    }
  });
});
</script>

<style scoped>
.van-switch--on {
  background-color: #10b981;
}

/* Custom Time Picker Styling */
.custom-time-picker {
  padding: 20px 0;
}

.custom-time-picker :deep(.van-picker-column) {
  font-size: 18px;
  font-weight: 600;
}

.custom-time-picker :deep(.van-picker-column__item) {
  color: #9ca3af;
  transition: all 0.2s;
}

.custom-time-picker :deep(.van-picker-column__item--selected) {
  color: #2563eb;
  font-size: 20px;
}

/* Dark mode for time picker */
.dark .custom-time-picker :deep(.van-picker-column__item) {
  color: #6b7280;
}

.dark .custom-time-picker :deep(.van-picker-column__item--selected) {
  color: #3b82f6;
}

/* Custom Picker Styling */
.custom-picker {
  padding: 20px 0;
}

.custom-picker :deep(.van-picker-column) {
  font-size: 16px;
  font-weight: 500;
}

.custom-picker :deep(.van-picker-column__item) {
  color: #9ca3af;
  transition: all 0.2s;
}

.custom-picker :deep(.van-picker-column__item--selected) {
  color: #8b5cf6;
  font-size: 18px;
  font-weight: 600;
}

/* Dark mode for picker */
.dark .custom-picker :deep(.van-picker-column__item) {
  color: #6b7280;
}

.dark .custom-picker :deep(.van-picker-column__item--selected) {
  color: #a78bfa;
}

/* Smooth animations */
@media (prefers-reduced-motion: no-preference) {
  button,
  .van-popup {
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
  }
}

/* Respect reduced motion preference */
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
</style>
