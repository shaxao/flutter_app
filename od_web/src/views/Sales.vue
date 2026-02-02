<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="周销售计划"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-3 bg-white dark:bg-[#1C1917] mb-2 shadow-sm border-b border-gray-100 dark:border-gray-800">
      <div class="flex gap-2">
        <div
          class="flex-1 h-9 px-3 flex items-center bg-gray-50 dark:bg-gray-800 rounded border border-gray-100 dark:border-gray-700 text-sm text-gray-600 dark:text-gray-300"
          @click="showCalendar = true"
        >
          <van-icon name="calendar-o" class="mr-2 text-gray-400 dark:text-gray-500" />
          {{ startDate || "开始日期(YYYY-MM-DD)" }}
        </div>
        <van-button
          type="primary"
          class="w-20"
          :loading="loading"
          @click="query"
          >查询</van-button
        >
      </div>
    </div>

    <!-- Weekly Summary -->
    <div v-if="weekly.total_week_sales" class="px-3 mb-3">
      <div class="bg-white dark:bg-[#1C1917] rounded-lg p-3 shadow-sm border border-gray-100 dark:border-gray-800">
        <div class="text-sm font-bold text-gray-700 dark:text-gray-200 mb-2 flex items-center">
          <van-icon name="chart-trending-o" class="mr-1 text-blue-500 dark:text-blue-400" />
          本周总计
        </div>
        <div class="flex flex-wrap gap-2">
          <span class="px-2 py-1 bg-blue-50 text-blue-600 rounded text-xs"
            >早: {{ weekly.total_morning_sales }}</span
          >
          <span class="px-2 py-1 bg-orange-50 text-orange-600 rounded text-xs"
            >晚: {{ weekly.total_evening_sales }}</span
          >
          <span
            class="px-2 py-1 bg-gray-100 text-gray-600 rounded text-xs font-bold"
            >总: {{ weekly.total_week_sales }}</span
          >
        </div>
      </div>
    </div>

    <!-- Daily List -->
    <div class="px-3 space-y-3">
      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty v-else-if="daily.length === 0" description="暂无数据" />

      <div
        v-for="(day, idx) in daily"
        :key="idx"
        class="bg-white dark:bg-[#1C1917] rounded-lg p-3 shadow-sm border border-gray-100 dark:border-gray-800"
      >
        <div class="flex justify-between items-center mb-2">
          <div class="font-bold text-gray-800 dark:text-gray-100">
            {{ day.date }}
            <span class="text-xs font-normal text-gray-400 dark:text-gray-500 ml-1">{{
              day.weekday
            }}</span>
          </div>
          <div
            class="text-xs font-bold bg-gray-100 dark:bg-gray-800 px-2 py-1 rounded text-gray-600 dark:text-gray-300"
          >
            {{ day.total_sales }}
          </div>
        </div>

        <div class="flex gap-2 mb-2">
          <span class="px-2 py-0.5 bg-blue-50 text-blue-600 rounded text-xs"
            >早: {{ day.morning_sales }}</span
          >
          <span class="px-2 py-0.5 bg-orange-50 text-orange-600 rounded text-xs"
            >晚: {{ day.evening_sales }}</span
          >
        </div>

        <!-- Progress Bar -->
        <div class="h-2.5 bg-gray-100 dark:bg-gray-800 rounded-full flex overflow-hidden">
          <div
            class="bg-blue-400 h-full transition-all duration-500"
            :style="{
              width: getRatio(day.morning_sales, day.total_sales) + '%',
            }"
          ></div>
          <div
            class="bg-orange-400 h-full transition-all duration-500"
            :style="{
              width: getRatio(day.evening_sales, day.total_sales) + '%',
            }"
          ></div>
        </div>
      </div>
    </div>

    <van-calendar
      v-model:show="showCalendar"
      @confirm="onConfirmDate"
      :min-date="new Date(2020, 0, 1)"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import api from "@/api";
import { showToast } from "vant";

const loading = ref(false);
const startDate = ref("");
const showCalendar = ref(false);
const daily = ref<any[]>([]);
const weekly = ref<any>({});

const onConfirmDate = (value: Date) => {
  const y = value.getFullYear();
  const m = String(value.getMonth() + 1).padStart(2, "0");
  const d = String(value.getDate()).padStart(2, "0");
  startDate.value = `${y}-${m}-${d}`;
  showCalendar.value = false;
};

const query = async () => {
  if (!startDate.value) return showToast("请选择日期");
  loading.value = true;
  try {
    const res = await api.get("/weekly-sales-summary", {
      params: { start_date: startDate.value },
    });
    const data = res.data || {};
    daily.value = data.daily_sales_summary || [];
    weekly.value = data.weekly_summary || {};
  } finally {
    loading.value = false;
  }
};

const getRatio = (val: any, total: any) => {
  const v = parseFloat(val) || 0;
  const t = parseFloat(total) || 1;
  if (t <= 0) return 0;
  return (v / t) * 100;
};
</script>
