<template>
  <div class="bg-[#FAF5FF] dark:bg-[#0C0A09] transition-colors duration-200">
    <!-- Background Decor -->
    <div
      class="absolute top-0 left-0 w-full h-[200px] bg-gradient-to-b from-violet-100/40 to-transparent dark:from-violet-900/10 pointer-events-none"
    ></div>

    <div class="p-5 relative z-0 pb-6">
      <!-- Skeleton Loading -->
      <div v-if="loadingRevenue && !revenue" class="space-y-8 pt-2">
        <div class="flex justify-between items-center">
          <van-skeleton title :row="1" class="!p-0 w-32" />
          <van-skeleton avatar avatar-size="40px" class="!p-0" />
        </div>
        <van-skeleton-paragraph row-width="100%" class="!h-48 rounded-3xl" />
        <div class="grid grid-cols-2 gap-4">
          <van-skeleton-paragraph
            v-for="i in 6"
            :key="i"
            row-width="100%"
            class="!h-32 rounded-2xl"
          />
        </div>
      </div>

      <template v-else>
        <!-- Header -->
        <header class="mb-8 pt-2">
          <div class="flex justify-between items-center mb-6">
            <div>
              <p
                class="text-[#4C1D95] dark:text-violet-300 text-xs font-medium mb-1 tracking-wide uppercase"
              >
                {{ currentDate }}
              </p>
              <h1
                class="text-2xl font-bold text-[#0F172A] dark:text-white tracking-tight"
              >
                你好，<span class="text-gradient dark:text-gradient-dark"
                  >店长</span
                >
              </h1>
            </div>
            <div class="flex items-center gap-3">
              <button
                class="w-10 h-10 rounded-full bg-white dark:bg-gray-800 flex items-center justify-center border border-gray-200 dark:border-gray-700 cursor-pointer transition-colors duration-150 hover:bg-gray-50 dark:hover:bg-gray-700 active:scale-95"
                @click="toggleDark()"
                :aria-label="isDark ? '切换到亮色模式' : '切换到暗色模式'"
              >
                <!-- Sun Icon (Light Mode) -->
                <svg
                  v-if="isDark"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-5 h-5 text-gray-300"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z"
                  />
                </svg>
                <!-- Moon Icon (Dark Mode) -->
                <svg
                  v-else
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-5 h-5 text-gray-600"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z"
                  />
                </svg>
              </button>
              <div
                class="w-10 h-10 rounded-full bg-white dark:bg-gray-800 flex items-center justify-center border border-gray-200 dark:border-gray-700"
              >
                <van-icon
                  name="manager-o"
                  class="text-gray-600 dark:text-gray-300"
                />
              </div>
            </div>
          </div>

          <!-- Revenue Card -->
          <div
            class="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#7C3AED] to-[#6D28D9] dark:from-[#5B21B6] dark:to-[#4C1D95] p-6 text-white cursor-pointer hover-lift"
            @click="$router.push('/revenue')"
          >
            <div class="relative z-10">
              <div class="flex justify-between items-start mb-6">
                <div class="flex items-center gap-3">
                  <div
                    class="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center"
                  >
                    <van-icon
                      name="chart-trending-o"
                      class="text-white text-xl"
                    />
                  </div>
                  <span class="text-white/90 text-sm font-medium"
                    >今日营业额</span
                  >
                </div>
                <van-button
                  round
                  size="mini"
                  class="!bg-white/20 !border-0 !text-white !px-3 !h-7 hover:!bg-white/30 transition-colors duration-150"
                  @click.stop="fetchRevenue"
                  :loading="loadingRevenue"
                >
                  刷新
                </van-button>
              </div>

              <div class="flex items-baseline gap-2 mb-4">
                <span class="text-4xl font-bold tracking-tight">{{
                  revenue || "0.00"
                }}</span>
                <span class="text-sm text-white/80">元</span>
              </div>

              <div class="flex items-center gap-2 text-xs text-white/70">
                <span
                  class="w-1.5 h-1.5 rounded-full bg-green-400 animate-pulse"
                ></span>
                <span>实时更新于 {{ updateTime }}</span>
              </div>
            </div>
          </div>
        </header>

        <!-- Menu Grid -->
        <div class="grid grid-cols-2 gap-4">
          <div
            v-for="item in menuItems"
            :key="item.route"
            class="group relative bg-white dark:bg-[#1C1917] rounded-xl p-4 border border-gray-200 dark:border-gray-800 cursor-pointer hover-lift"
            @click="$router.push(item.route)"
          >
            <div class="flex items-start justify-between mb-4 relative z-10">
              <div
                :class="[
                  'w-12 h-12 rounded-xl flex items-center justify-center text-2xl transition-smooth group-hover:scale-105',
                  item.bgClass,
                  item.textClass,
                ]"
              >
                <van-icon :name="item.icon" />
              </div>
            </div>

            <div class="relative z-10">
              <h3
                class="font-semibold text-[#0F172A] dark:text-white text-[15px] mb-1 transition-colors duration-150 group-hover:text-[#7C3AED] dark:group-hover:text-[#A78BFA]"
              >
                {{ item.title }}
              </h3>
              <p class="text-xs text-[#475569] dark:text-gray-400 line-clamp-1">
                {{ item.desc }}
              </p>
            </div>

            <!-- Hover Arrow -->
            <div
              class="absolute top-4 right-4 opacity-0 transition-smooth group-hover:opacity-100"
            >
              <van-icon
                name="arrow"
                class="text-gray-400 dark:text-gray-600 text-xs"
              />
            </div>
          </div>
        </div>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from "vue";
import { useNow, useDateFormat, useDark, useToggle } from "@vueuse/core";
import api from "@/api";

const loadingRevenue = ref(false);
const revenue = ref("");
const updateTime = ref("--:--");
const now = useNow();
const currentDate = useDateFormat(now, "YYYY年MM月DD日 dddd");

// Configure dark mode with class strategy
const isDark = useDark({
  selector: "html",
  attribute: "class",
  valueDark: "dark",
  valueLight: "",
});
const toggleDark = useToggle(isDark);

const menuItems = [
  {
    title: "借货统计",
    desc: "门店借货管理",
    icon: "revoke",
    route: "/borrow",
    bgClass: "bg-orange-50 dark:bg-orange-900/30",
    textClass: "text-orange-500",
  },
  {
    title: "销售分析",
    desc: "商品销售明细",
    icon: "chart-trending-o",
    route: "/products",
    bgClass: "bg-blue-50 dark:bg-blue-900/30",
    textClass: "text-blue-500",
  },
  {
    title: "订货管理",
    desc: "导入与排序",
    icon: "shopping-cart-o",
    route: "/order",
    bgClass: "bg-green-50 dark:bg-green-900/30",
    textClass: "text-green-500",
  },
  {
    title: "台账生产",
    desc: "图片识别生成",
    icon: "orders-o",
    route: "/ledger",
    bgClass: "bg-indigo-50 dark:bg-indigo-900/30",
    textClass: "text-indigo-500",
  },
  {
    title: "员工考勤",
    desc: "考勤查询",
    icon: "manager-o",
    route: "/attendance",
    bgClass: "bg-purple-50 dark:bg-purple-900/30",
    textClass: "text-purple-500",
  },
  {
    title: "周销售计划",
    desc: "分时段汇总",
    icon: "calendar-o",
    route: "/sales",
    bgClass: "bg-pink-50 dark:bg-pink-900/30",
    textClass: "text-pink-500",
  },
  {
    title: "周排班查询",
    desc: "按姓名日期",
    icon: "clock-o",
    route: "/weekly",
    bgClass: "bg-teal-50 dark:bg-teal-900/30",
    textClass: "text-teal-500",
  },
  {
    title: "当日排班",
    desc: "当天排班表",
    icon: "todo-list-o",
    route: "/daily",
    bgClass: "bg-cyan-50 dark:bg-cyan-900/30",
    textClass: "text-cyan-500",
  },
  {
    title: "报班助手",
    desc: "AI 识别文本",
    icon: "chat-o",
    route: "/schedule-ai",
    bgClass: "bg-rose-50 dark:bg-rose-900/30",
    textClass: "text-rose-500",
  },
  {
    title: "语音提醒",
    desc: "食材过期管理",
    icon: "volume-o",
    route: "/reminder",
    bgClass:
      "bg-gradient-to-tr from-emerald-400/20 to-teal-400/20 dark:from-emerald-500/10 dark:to-teal-500/10",
    textClass: "text-emerald-600 dark:text-emerald-400",
  },
  {
    title: "菜单管理",
    desc: "菜谱查看",
    icon: "shop-o",
    route: "/menu",
    bgClass: "bg-yellow-50 dark:bg-yellow-900/30",
    textClass: "text-yellow-500",
  },
  {
    title: "系统设置",
    desc: "接口配置",
    icon: "setting-o",
    route: "/settings",
    bgClass: "bg-gray-50 dark:bg-gray-800",
    textClass: "text-gray-500 dark:text-gray-400",
  },
];

const fetchRevenue = async () => {
  loadingRevenue.value = true;
  try {
    const resp = await api.get("/revenue");
    revenue.value = resp.data.revenue;
    updateTime.value = useDateFormat(new Date(), "HH:mm").value;
  } catch (e) {
    // Silent fail
  } finally {
    loadingRevenue.value = false;
  }
};

onMounted(() => {
  fetchRevenue();
  updateTime.value = useDateFormat(new Date(), "HH:mm").value;
});
</script>

<style scoped>
.text-gradient {
  background: linear-gradient(135deg, #7c3aed 0%, #6d28d9 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.text-gradient-dark {
  background: linear-gradient(135deg, #a78bfa 0%, #c084fc 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}
</style>
