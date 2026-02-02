<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="周排班查询"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-3 bg-white mb-2 shadow-sm space-y-2">
      <div class="flex gap-2">
        <input
          v-model="name"
          placeholder="员工姓名"
          class="flex-1 h-9 px-3 bg-gray-50 rounded border border-gray-100 text-sm outline-none"
        />
        <div
          class="flex-1 h-9 px-3 flex items-center bg-gray-50 rounded border border-gray-100 text-sm text-gray-600 truncate"
          @click="showCalendar = true"
        >
          {{ startDate || "开始日期" }}
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
      <!-- Stats -->
      <div
        v-if="days.length > 0"
        class="bg-white rounded-lg p-3 shadow-sm border border-gray-100"
      >
        <div class="text-xs text-gray-500 mb-2">本周合计</div>
        <div class="flex flex-wrap gap-2">
          <span class="px-2 py-1 bg-blue-50 text-blue-600 rounded text-xs"
            >有数据: {{ stats.days }}天</span
          >
          <span class="px-2 py-1 bg-green-50 text-green-600 rounded text-xs"
            >上班: {{ stats.labor }}h</span
          >
          <span class="px-2 py-1 bg-orange-50 text-orange-600 rounded text-xs"
            >休息: {{ stats.break }}h</span
          >
        </div>
      </div>

      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty v-else-if="days.length === 0" description="暂无数据" />

      <div v-else class="space-y-2">
        <div
          v-for="(day, idx) in days"
          :key="idx"
          class="bg-white rounded-lg p-3 shadow-sm border border-gray-100 active:bg-gray-50 transition-colors"
          @click="goToDaily(day.date)"
        >
          <div class="flex justify-between items-center mb-2">
            <div class="font-bold text-gray-800">
              {{ day.date }}
              <span class="text-gray-400 font-normal ml-1">{{
                day.weekday
              }}</span>
            </div>
            <div
              class="text-xs px-2 py-0.5 rounded"
              :class="
                day.has_data
                  ? 'bg-green-50 text-green-600'
                  : 'bg-gray-100 text-gray-400'
              "
            >
              {{ day.has_data ? "有数据" : "无数据" }}
            </div>
          </div>

          <div v-if="day.has_data" class="flex flex-wrap gap-2">
            <span
              class="px-2 py-0.5 bg-gray-50 text-gray-600 rounded text-xs"
              >{{ day.name }}</span
            >
            <span
              class="px-2 py-0.5 bg-blue-50 text-blue-600 rounded text-xs"
              >{{ day.position || "-" }}</span
            >
            <span class="px-2 py-0.5 bg-blue-50 text-blue-600 rounded text-xs"
              >{{ fmtTime(day.shiftStart) }}-{{ fmtTime(day.shiftEnd) }}</span
            >
            <span class="px-2 py-0.5 bg-green-50 text-green-600 rounded text-xs"
              >{{ day.laborHours }}h</span
            >
            <span
              class="px-2 py-0.5 bg-orange-50 text-orange-600 rounded text-xs"
              >休: {{ fmtRange(day.breakTime) }} ({{ day.breakHours }}h)</span
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
import { ref, computed } from "vue";
import api from "@/api";
import { useRouter } from "vue-router";
import { showToast } from "vant";

const router = useRouter();
const loading = ref(false);
const name = ref("");
const startDate = ref("");
const showCalendar = ref(false);
const days = ref<any[]>([]);

const stats = computed(() => {
  let d = 0,
    l = 0,
    b = 0;
  days.value.forEach((day) => {
    if (day.has_data) {
      d++;
      l += parseFloat(day.laborHours) || 0;
      b += parseFloat(day.breakHours) || 0;
    }
  });
  return { days: d, labor: l.toFixed(2), break: b.toFixed(2) };
});

const onConfirmDate = (value: Date) => {
  const y = value.getFullYear();
  const m = String(value.getMonth() + 1).padStart(2, "0");
  const d = String(value.getDate()).padStart(2, "0");
  startDate.value = `${y}-${m}-${d}`;
  showCalendar.value = false;
};

const query = async () => {
  if (!startDate.value) return showToast("请选择开始日期");
  loading.value = true;
  try {
    const res = await api.get("/staff/weekly-schedule", {
      params: { name: name.value, start_date: startDate.value },
    });
    days.value = res.data?.weekly_schedule || [];
  } finally {
    loading.value = false;
  }
};

const goToDaily = (date: string) => {
  if (date) router.push(`/daily?date=${date}`);
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
