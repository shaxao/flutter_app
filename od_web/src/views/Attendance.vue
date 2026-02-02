<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="员工考勤"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-3 bg-white mb-2 shadow-sm space-y-2">
      <div
        class="h-9 px-3 flex items-center bg-gray-50 rounded border border-gray-100 text-sm text-gray-600"
        @click="showPicker = true"
      >
        <van-icon name="clock-o" class="mr-2 text-gray-400" />
        {{ yearMonth || "选择年月(YYYYMM)" }}
      </div>

      <div class="flex gap-2">
        <input
          v-model="name"
          placeholder="姓名"
          class="flex-1 h-9 px-3 bg-gray-50 rounded border border-gray-100 text-sm outline-none"
        />
        <input
          v-model="code"
          placeholder="工号"
          class="flex-1 h-9 px-3 bg-gray-50 rounded border border-gray-100 text-sm outline-none"
        />
        <van-button
          type="primary"
          class="w-16"
          :loading="loading"
          @click="query"
          >查询</van-button
        >
      </div>
    </div>

    <div class="px-3">
      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty v-else-if="days.length === 0" description="暂无数据" />

      <div
        v-else
        class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-hidden"
      >
        <van-cell
          v-for="(day, idx) in days"
          :key="idx"
          :title="`${day.date} ${day.weekday}`"
          :value="day.has_data ? '有数据' : '无数据'"
          :value-class="
            day.has_data ? 'text-green-600 font-bold' : 'text-gray-400'
          "
        />
      </div>
    </div>

    <van-popup v-model:show="showPicker" position="bottom">
      <van-date-picker
        v-model="pickerValue"
        title="选择年月"
        :min-date="new Date(2020, 0, 1)"
        :max-date="new Date(2030, 11, 1)"
        :columns-type="['year', 'month']"
        @confirm="onConfirmDate"
        @cancel="showPicker = false"
      />
    </van-popup>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import api from "@/api";
import { showToast } from "vant";

const loading = ref(false);
const yearMonth = ref("");
const name = ref("");
const code = ref("");
const days = ref<any[]>([]);

const showPicker = ref(false);
const pickerValue = ref<string[]>([]);

const onConfirmDate = ({ selectedValues }: any) => {
  yearMonth.value = selectedValues.join("");
  showPicker.value = false;
};

const query = async () => {
  if (!yearMonth.value) return showToast("请选择年月");
  loading.value = true;
  try {
    const res = await api.get("/attendance", {
      params: {
        year_month: yearMonth.value,
        name: name.value,
        code: code.value,
      },
    });
    days.value = res.data?.daily_attendance || [];
  } finally {
    loading.value = false;
  }
};
</script>
