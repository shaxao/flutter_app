<template>
  <div
    class="p-4 pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="报班识别助手"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="dark:bg-[#1C1917]/80 dark:text-white"
    />

    <div class="mt-4">
      <van-field
        v-model="inputText"
        rows="6"
        autosize
        type="textarea"
        placeholder="请粘贴微信群员工报班文本..."
        class="rounded-xl shadow-sm mb-4"
      />

      <div class="flex gap-3 mb-4">
        <van-button
          block
          plain
          type="primary"
          :loading="loading"
          @click="recognize"
          class="flex-1"
        >
          识别
        </van-button>
        <van-button
          block
          type="primary"
          :loading="loading"
          @click="confirm"
          class="flex-1"
        >
          确认排班
        </van-button>
      </div>

      <div
        v-if="Object.keys(scheduleData).length > 0"
        class="bg-white rounded-xl shadow-sm p-4"
      >
        <h3 class="font-bold text-gray-700 mb-3">识别结果</h3>
        <div
          v-for="(days, name) in scheduleData"
          :key="name"
          class="mb-4 last:mb-0 border-b last:border-0 pb-2"
        >
          <div class="font-bold text-primary mb-2">{{ name }}</div>
          <div class="grid grid-cols-2 gap-2 text-sm">
            <div
              v-for="i in 7"
              :key="i"
              class="flex justify-between p-1 bg-gray-50 rounded"
            >
              <span class="text-gray-500">第{{ i }}天</span>
              <span class="font-medium">
                {{ days[`startTime${i}`] || "-" }} ~
                {{ days[`endTime${i}`] || "-" }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <van-empty v-else description="暂无识别数据" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import axios from "axios";
import { showToast, showSuccessToast, showFailToast } from "vant";

const inputText = ref("");
const loading = ref(false);
const scheduleData = ref<any>({});

// Independent Axios instance for external service
const aiApi = axios.create({
  baseURL: "https://paiban.saliya.top",
});

const recognize = async () => {
  if (!inputText.value) {
    showToast("请先粘贴文本");
    return;
  }

  loading.value = true;
  try {
    const resp = await aiApi.post("/api/recognize", { data: inputText.value });
    scheduleData.value = resp.data;
    showSuccessToast("识别完成");
  } catch (e) {
    showFailToast("识别失败");
  } finally {
    loading.value = false;
  }
};

const confirm = async () => {
  if (Object.keys(scheduleData.value).length === 0) {
    showToast("无数据可提交");
    return;
  }

  loading.value = true;
  try {
    const resp = await aiApi.post("/api/confirm", scheduleData.value);
    if (resp.data.success) {
      showSuccessToast("排班提交成功");
    } else {
      showFailToast("提交失败");
    }
  } catch (e) {
    showFailToast("提交失败");
  } finally {
    loading.value = false;
  }
};
</script>
