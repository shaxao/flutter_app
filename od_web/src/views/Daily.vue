<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="当日排班"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-3 bg-white dark:bg-[#1C1917] mb-2 shadow-sm border-b border-gray-100 dark:border-gray-800 space-y-2">
      <div class="flex gap-2">
        <div
          class="flex-1 h-9 px-3 flex items-center bg-gray-50 dark:bg-gray-800 rounded border border-gray-100 dark:border-gray-700 text-sm text-gray-600 dark:text-gray-300"
          @click="showCalendar = true"
        >
          {{ date || "选择日期" }}
        </div>
        <van-button
          type="primary"
          class="w-16"
          :loading="loading"
          @click="query"
          >查询</van-button
        >
      </div>
    </div>

    <div class="px-3 space-y-3">
      <!-- Meta Stats -->
      <div
        v-if="meta.planTotal"
        class="bg-white dark:bg-[#1C1917] rounded-lg p-3 shadow-sm border border-gray-100 dark:border-gray-800"
      >
        <div class="flex flex-wrap gap-2 mb-2">
          <span class="px-2 py-1 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded text-xs"
            >计划销售额: {{ meta.planTotal }}</span
          >
          <span class="px-2 py-1 bg-green-50 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded text-xs"
            >总工时: {{ meta.laborHoursTotal }}h</span
          >
          <span class="px-2 py-1 bg-orange-50 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400 rounded text-xs"
            >人时销售: {{ meta.salesPerLaborHour }}</span
          >
        </div>

        <div v-if="meta.salesPlan" class="pt-2 border-t border-gray-100 dark:border-gray-800 mt-2">
          <div class="text-xs text-gray-500 dark:text-gray-400 mb-1">每小时计划销售额</div>
          <div class="flex flex-wrap gap-1">
            <span
              v-for="(v, k) in sortedSalesPlan"
              :key="k"
              class="px-1.5 py-0.5 bg-gray-50 dark:bg-gray-800 text-gray-600 dark:text-gray-300 rounded text-[10px]"
            >
              {{ k }}: {{ v }}
            </span>
          </div>
        </div>
      </div>

      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty v-else-if="staff.length === 0" description="暂无数据" />

      <div v-else class="space-y-2">
        <div
          v-for="(s, idx) in staff"
          :key="idx"
          class="bg-white dark:bg-[#1C1917] rounded-lg p-3 shadow-sm border border-gray-100 dark:border-gray-800"
        >
          <div class="font-bold text-gray-800 dark:text-gray-100 mb-2">
            {{ s.name || "未命名" }}
          </div>
          <div class="flex flex-wrap gap-2">
            <span
              class="px-2 py-0.5 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded text-xs"
              >{{ s.position || "-" }}</span
            >
            <span class="px-2 py-0.5 bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 rounded text-xs"
              >{{ fmtTime(s.shiftStart) }}-{{ fmtTime(s.shiftEnd) }}</span
            >
            <span class="px-2 py-0.5 bg-green-50 dark:bg-green-900/30 text-green-600 dark:text-green-400 rounded text-xs"
              >{{ s.laborHours }}h</span
            >
            <span class="px-2 py-0.5 bg-gray-50 dark:bg-gray-800 text-gray-500 dark:text-gray-400 rounded text-xs"
              >休: {{ fmtRange(s.breakTime) }}</span
            >
            <span
              class="px-2 py-0.5 bg-orange-50 dark:bg-orange-900/30 text-orange-600 dark:text-orange-400 rounded text-xs"
              >休时长: {{ s.breakHours }}h</span
            >
          </div>
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
import { ref, onMounted, computed } from "vue";
import { useRoute } from "vue-router";
import api from "@/api";
import { showToast } from "vant";

const route = useRoute();
const loading = ref(false);
const date = ref("");
const showCalendar = ref(false);
const staff = ref<any[]>([]);
const meta = ref<any>({});

const sortedSalesPlan = computed(() => {
  const plan = meta.value.salesPlan || {};
  const keys = Object.keys(plan).sort();
  const out: any = {};
  keys.forEach((k) => (out[k] = plan[k]));
  return out;
});

onMounted(() => {
  if (route.query.date) {
    date.value = String(route.query.date);
    query();
  }
});

const onConfirmDate = (value: Date) => {
  const y = value.getFullYear();
  const m = String(value.getMonth() + 1).padStart(2, "0");
  const d = String(value.getDate()).padStart(2, "0");
  date.value = `${y}-${m}-${d}`;
  showCalendar.value = false;
};

const query = async () => {
  if (!date.value) return showToast("请选择日期");
  loading.value = true;
  try {
    const res = await api.get("/staff/daily-schedule", {
      params: { date: date.value },
    });
    const data = res.data || {};
    staff.value = data.staff || [];
    meta.value = data;
  } finally {
    loading.value = false;
  }
};

const fmtTime = (v: any) => {
  if (!v) return "";
  const s = String(v).replace(/:/g, "");
  if (s.length < 4) return s;
  return s.substring(0, 2) + ":" + s.substring(2, 4);
};

const fmtRange = (v: any) => {
  if (!v) return "-";
  const s = String(v);
  if (!s.includes("-")) return fmtTime(s);
  const [a, b] = s.split("-");
  return `${fmtTime(a)}-${fmtTime(b)}`;
};
</script>
