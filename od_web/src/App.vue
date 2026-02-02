<template>
  <div
    class="fixed inset-0 flex flex-col bg-[#FAF5FF] dark:bg-[#0C0A09] transition-colors duration-200"
  >
    <SplashScreen :show="showSplash" />
    <ReloadPrompt
      :versionMismatch="versionMismatch"
      @close="versionMismatch = false"
    />
    <DevLogger />

    <!-- 主内容区域 - 可滚动，不会覆盖底部导航 -->
    <div class="flex-1 overflow-y-auto overflow-x-hidden">
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </div>

    <!-- 底部导航 - 固定在底部，高z-index -->
    <van-tabbar
      v-model="active"
      route
      :fixed="false"
      safe-area-inset-bottom
      class="!bg-white dark:!bg-[#1C1917] !border-t !border-gray-200 dark:!border-gray-800 shrink-0"
      style="z-index: 9999"
    >
      <van-tabbar-item replace to="/" icon="home-o" class="dark:text-gray-400"
        >首页</van-tabbar-item
      >
      <van-tabbar-item
        replace
        to="/ledger"
        icon="apps-o"
        class="dark:text-gray-400"
        >台账</van-tabbar-item
      >
      <van-tabbar-item
        replace
        to="/revenue"
        icon="chart-trending-o"
        class="dark:text-gray-400"
        >营业额</van-tabbar-item
      >
      <van-tabbar-item
        replace
        to="/settings"
        icon="setting-o"
        class="dark:text-gray-400"
        >设置</van-tabbar-item
      >
    </van-tabbar>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import SplashScreen from "@/components/SplashScreen.vue";
import ReloadPrompt from "@/components/ReloadPrompt.vue";
import DevLogger from "@/components/DevLogger.vue";

const active = ref(0);
const showSplash = ref(true);
const versionMismatch = ref(false);

// 版本检查函数
const checkVersion = async () => {
  try {
    // 获取当前本地存储的版本
    const localVersion = localStorage.getItem("app_version");

    // 获取服务器版本（添加时间戳防止缓存）
    const response = await fetch(`/version.json?t=${Date.now()}`);
    const data = await response.json();
    const serverVersion = data.version;

    console.log("Version check:", { localVersion, serverVersion });

    // 如果本地有版本且与服务器版本不同，提示更新
    if (localVersion && localVersion !== serverVersion) {
      console.log("Version mismatch detected, showing update prompt");
      versionMismatch.value = true;
    }

    // 更新本地版本
    localStorage.setItem("app_version", serverVersion);
  } catch (error) {
    console.error("Version check failed:", error);
  }
};

onMounted(() => {
  // 启动画面
  setTimeout(() => {
    showSplash.value = false;
  }, 2500);

  // 首次检查版本
  checkVersion();

  // 每 5 分钟检查一次版本
  setInterval(() => {
    checkVersion();
  }, 5 * 60 * 1000);
});
</script>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* 确保暗夜模式正确应用到 Vant 组件 */
:root.dark {
  --van-tabbar-background: #1c1917;
  --van-tabbar-item-text-color: #9ca3af;
  --van-tabbar-item-active-color: #7c3aed;
  --van-tabbar-item-active-background: transparent;
}
</style>
