<template>
  <transition name="slide-up">
    <div
      v-if="needRefresh || versionMismatch"
      class="fixed bottom-24 left-1/2 transform -translate-x-1/2 z-[1000] bg-white/90 dark:bg-[#1C1917]/90 backdrop-blur-xl px-5 py-4 rounded-[2rem] shadow-2xl w-[92%] max-w-md border border-white/50 dark:border-indigo-900/30"
    >
      <!-- 更新提示状态 -->
      <div v-if="!updating" class="flex items-center gap-4">
        <div
          class="w-10 h-10 rounded-2xl bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center flex-shrink-0"
        >
          <van-icon
            name="info-o"
            class="text-indigo-600 dark:text-indigo-400 text-lg"
          />
        </div>

        <div class="flex-1 min-w-0">
          <div class="font-bold text-gray-800 dark:text-gray-100 text-sm">
            系统版本更新
          </div>
          <div
            class="text-gray-500 dark:text-gray-400 text-[11px] mt-0.5 truncate"
          >
            发现新功能，立即更新体验！
          </div>
        </div>

        <div class="flex gap-2">
          <button
            @click="close"
            class="px-3 py-1.5 rounded-xl text-[11px] font-bold text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
          >
            稍后
          </button>
          <button
            @click="handleUpdate"
            class="bg-indigo-600 text-white text-[11px] px-4 py-1.5 rounded-xl font-bold shadow-lg shadow-indigo-500/20 active:scale-95 transition-all"
          >
            立即更新
          </button>
        </div>
      </div>

      <!-- 更新进度状态 -->
      <div v-else class="space-y-3">
        <div class="flex items-center gap-3">
          <div
            class="w-10 h-10 rounded-2xl bg-indigo-100 dark:bg-indigo-900/30 flex items-center justify-center flex-shrink-0"
          >
            <van-loading size="20px" color="#4f46e5" />
          </div>

          <div class="flex-1 min-w-0">
            <div class="font-bold text-gray-800 dark:text-gray-100 text-sm">
              {{ updateStatus }}
            </div>
            <div class="text-gray-500 dark:text-gray-400 text-[11px] mt-0.5">
              {{ updateTip }}
            </div>
          </div>
        </div>

        <!-- 进度条 -->
        <div
          class="relative h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden"
        >
          <div
            class="absolute inset-y-0 left-0 bg-gradient-to-r from-indigo-500 to-indigo-600 rounded-full transition-all duration-500 ease-out"
            :style="{ width: `${progress}%` }"
          >
            <div class="absolute inset-0 bg-white/20 animate-shimmer"></div>
          </div>
        </div>

        <!-- 进度百分比 -->
        <div class="flex items-center justify-between text-[10px]">
          <span class="text-gray-500 dark:text-gray-400">{{
            progressText
          }}</span>
          <span class="text-indigo-600 dark:text-indigo-400 font-bold"
            >{{ progress }}%</span
          >
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup lang="ts">
import { useRegisterSW } from "virtual:pwa-register/vue";
import { toRefs, ref } from "vue";
import { showFailToast } from "vant";

const props = defineProps<{
  versionMismatch?: boolean;
}>();

const { versionMismatch } = toRefs(props);
const updating = ref(false);
const progress = ref(0);
const updateStatus = ref("准备更新");
const updateTip = ref("正在初始化...");
const progressText = ref("开始更新");

const { needRefresh, updateServiceWorker } = useRegisterSW();

const close = () => {
  needRefresh.value = false;
  emit("close");
};

const emit = defineEmits(["close"]);

// 模拟进度更新（因为实际 SW 更新无法获取真实进度）
const simulateProgress = () => {
  const stages = [
    {
      progress: 15,
      status: "检查更新",
      tip: "正在验证新版本...",
      text: "连接服务器",
    },
    {
      progress: 30,
      status: "下载资源",
      tip: "正在下载新版本文件...",
      text: "下载中",
    },
    {
      progress: 50,
      status: "安装更新",
      tip: "正在安装新版本...",
      text: "安装中",
    },
    {
      progress: 70,
      status: "清理缓存",
      tip: "正在清理旧版本缓存...",
      text: "清理中",
    },
    {
      progress: 85,
      status: "激活版本",
      tip: "正在激活新版本...",
      text: "激活中",
    },
    {
      progress: 95,
      status: "即将完成",
      tip: "马上就好...",
      text: "最后一步",
    },
  ];

  let currentStage = 0;
  const interval = setInterval(() => {
    if (currentStage < stages.length) {
      const stage = stages[currentStage];
      if (stage) {
        progress.value = stage.progress;
        updateStatus.value = stage.status;
        updateTip.value = stage.tip;
        progressText.value = stage.text;
      }
      currentStage++;
    } else {
      clearInterval(interval);
    }
  }, 400); // 每个阶段 400ms，总共约 2.4 秒

  return interval;
};

const handleUpdate = async () => {
  if (updating.value) return;
  updating.value = true;
  progress.value = 0;

  // 启动进度模拟
  const progressInterval = simulateProgress();

  try {
    if (versionMismatch?.value) {
      // Force skip waiting for PWA
      if ("serviceWorker" in navigator) {
        const reg = await navigator.serviceWorker.getRegistration();
        if (reg) {
          if (reg.waiting) {
            reg.waiting.postMessage({ type: "SKIP_WAITING" });
          }

          // 等待一小段时间让进度动画完成
          await new Promise((resolve) => setTimeout(resolve, 800));

          // Unregister to ensure a clean state for the new version
          await reg.unregister();

          // 完成进度
          progress.value = 100;
          updateStatus.value = "更新完成";
          updateTip.value = "正在重启应用...";
          progressText.value = "完成";

          await new Promise((resolve) => setTimeout(resolve, 500));

          // Hard reload to bypass cache and reinstall SW
          window.location.reload();
          return;
        }
      }

      progress.value = 100;
      updateStatus.value = "更新完成";
      updateTip.value = "正在重启应用...";
      await new Promise((resolve) => setTimeout(resolve, 500));
      window.location.reload();
    } else {
      // 等待 SW 更新
      await updateServiceWorker();

      // 完成进度
      progress.value = 100;
      updateStatus.value = "更新完成";
      updateTip.value = "正在重启应用...";
      progressText.value = "完成";

      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  } catch (e) {
    console.error("Update failed:", e);
    clearInterval(progressInterval);
    showFailToast("更新失败，请手动刷新");
    updating.value = false;
    progress.value = 0;
  }
};
</script>

<style scoped>
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

.slide-up-enter-from,
.slide-up-leave-to {
  opacity: 0;
  transform: translate(-50%, 20px);
}

@keyframes shimmer {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(100%);
  }
}

.animate-shimmer {
  animation: shimmer 1.5s infinite;
}
</style>
