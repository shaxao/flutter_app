<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="台账生产"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-3 space-y-3">
      <!-- Server File Notice -->
      <div
        v-if="serverFiles"
        class="bg-blue-50 dark:bg-blue-900/30 border border-blue-100 dark:border-blue-800 p-3 rounded-lg flex items-start gap-2"
      >
        <van-icon name="info-o" class="text-blue-500 dark:text-blue-400 mt-0.5" />
        <div class="text-xs text-blue-700 dark:text-blue-300 leading-tight">
          检测到服务器已存在模板，将默认使用已激活的进货表与换算表。
        </div>
      </div>

      <!-- Main Actions -->
      <div class="bg-white dark:bg-[#1C1917] p-3 rounded-xl shadow-sm space-y-3">
        <!-- Image Upload & Recognize -->
        <div class="grid grid-cols-2 gap-3">
          <van-uploader
            v-model="fileList"
            :max-count="1"
            :after-read="afterReadImage"
            accept="image/*"
            class="w-full"
            preview-size="100%"
          >
            <div
              class="w-full h-24 bg-gray-50 dark:bg-gray-800 border border-dashed border-gray-300 dark:border-gray-700 rounded-lg flex flex-col items-center justify-center text-gray-500 dark:text-gray-400"
            >
              <van-icon name="photograph" size="24" class="mb-1" />
              <span class="text-xs">上传送货单</span>
            </div>
          </van-uploader>

          <div
            class="w-full h-24 bg-primary/10 dark:bg-primary/20 border border-primary/20 dark:border-primary/30 rounded-lg flex flex-col items-center justify-center text-primary dark:text-purple-400 active:bg-primary/20 transition-colors cursor-pointer"
            @click="startRecognition"
          >
            <van-icon name="scan" size="24" class="mb-1" />
            <span class="text-xs font-bold">开始识别</span>
          </div>
        </div>

        <!-- Templates -->
        <div class="flex flex-wrap gap-2">
          <van-uploader accept=".xlsx,.xls,.csv" :after-read="onTemplateSelect">
            <van-button size="small" icon="description" plain
              >上传进货表</van-button
            >
          </van-uploader>
          <van-uploader
            accept=".xlsx,.xls,.csv"
            :after-read="onConversionSelect"
          >
            <van-button size="small" icon="exchange" plain
              >上传换算表(可选)</van-button
            >
          </van-uploader>
        </div>

        <div class="text-xs text-gray-500 dark:text-gray-400 space-y-1 pl-1">
          <div v-if="templateFile">已选进货表: {{ templateFile.name }}</div>
          <div v-if="conversionFile">已选换算表: {{ conversionFile.name }}</div>
        </div>

        <!-- Generation Actions -->
        <div class="grid grid-cols-2 gap-3 pt-2 border-t border-gray-100 dark:border-gray-800">
          <van-button
            block
            type="primary"
            @click="processLedger(false)"
            :loading="processing"
            >生成台账</van-button
          >
          <van-button
            block
            plain
            type="primary"
            @click="processLedger(true)"
            :loading="processing"
            >预览生成</van-button
          >
        </div>

        <!-- Download Links -->
        <div v-if="downloadUrl" class="flex gap-2">
          <van-button size="small" block plain icon="link-o" @click="copyLink"
            >复制下载链接</van-button
          >
          <van-button size="small" block plain icon="down" @click="testDownload"
            >测试下载</van-button
          >
        </div>

        <div class="text-right text-xs text-gray-400 dark:text-gray-500">{{ statusText }}</div>
      </div>

      <!-- Settings (Collapsible) -->
      <van-collapse
        v-model="activeCollapse"
        :border="false"
        class="rounded-xl overflow-hidden shadow-sm bg-white dark:bg-[#1C1917]"
      >
        <van-collapse-item title="API 设置" name="settings">
          <div class="space-y-2">
            <van-field
              v-model="apiUrl"
              label="API URL"
              placeholder="https://api.openai.com..."
              class="bg-gray-50 rounded p-2"
            />
            <van-field
              v-model="apiKey"
              label="API Key"
              type="password"
              placeholder="sk-..."
              class="bg-gray-50 rounded p-2"
            />
          </div>
        </van-collapse-item>
      </van-collapse>

      <!-- Last Upload Summary -->
      <div
        v-if="lastUploadSummary"
        class="bg-gray-100 dark:bg-gray-800 p-3 rounded-lg text-xs space-y-1 text-gray-600 dark:text-gray-300"
      >
        <div class="font-bold mb-1">最近上传记录</div>
        <div>状态: {{ translateStatus(lastUploadSummary.status) }}</div>
        <div>
          已处理: {{ lastUploadSummary.loaded }} / 失败:
          {{ lastUploadSummary.failed }}
        </div>
        <div>时间: {{ formatTime(lastUploadSummary.time) }}</div>
        <div class="truncate text-gray-400 dark:text-gray-500">{{ lastUploadSummary.path }}</div>
      </div>

      <!-- Poll Log -->
      <div
        v-if="pollLog.length > 0"
        class="bg-white dark:bg-[#1C1917] rounded-xl shadow-sm overflow-hidden"
      >
        <div
          class="px-3 py-2 bg-gray-50 dark:bg-gray-800 font-bold text-xs text-gray-600 dark:text-gray-300 border-b border-gray-100 dark:border-gray-800"
        >
          上传日志
        </div>
        <div class="max-h-40 overflow-y-auto p-2 space-y-2">
          <div
            v-for="(log, i) in pollLog"
            :key="i"
            class="text-xs flex justify-between"
          >
            <span :class="getStatusColor(log.status)">{{
              translateStatus(log.status)
            }}</span>
            <span class="text-gray-400 dark:text-gray-500"
              >处理:{{ log.loaded }} 失败:{{ log.failed }}</span
            >
          </div>
        </div>
      </div>

      <!-- Recognition Results -->
      <div v-if="items.length > 0" class="space-y-2">
        <div class="px-2 text-xs font-bold text-gray-500 dark:text-gray-400">
          识别结果 ({{ items.length }})
        </div>
        <div
          v-for="(item, index) in items"
          :key="index"
          class="bg-white dark:bg-[#1C1917] p-3 rounded-lg shadow-sm flex justify-between items-start"
        >
          <div>
            <div class="font-bold text-gray-800 dark:text-gray-100">{{ item.product_code }}</div>
            <div class="text-xs text-gray-500 dark:text-gray-400 mt-1">
              生产日期: {{ item.production_date }}
            </div>
          </div>
          <div class="text-right text-sm">
            <div>
              <span class="text-gray-400 dark:text-gray-500 text-xs">拆:</span>
              {{ item.piece_count }}
            </div>
            <div>
              <span class="text-gray-400 dark:text-gray-500 text-xs">箱:</span>
              {{ item.box_count }}
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Loading Overlay -->
    <van-overlay
      :show="recognizing"
      class="flex items-center justify-center flex-col z-50"
    >
      <div class="bg-white dark:bg-[#1C1917] p-6 rounded-2xl flex flex-col items-center w-64">
        <van-loading type="spinner" color="#0052D9" size="30px" vertical>
          <span class="mt-4 text-gray-600 dark:text-gray-300 font-medium text-sm"
            >正在识别中...</span
          >
        </van-loading>
        <div class="w-full bg-gray-100 dark:bg-gray-800 h-1.5 mt-4 rounded-full overflow-hidden">
          <div
            class="h-full bg-primary transition-all duration-300"
            :style="{ width: progress + '%' }"
          ></div>
        </div>
        <div class="text-xs text-gray-400 dark:text-gray-500 mt-2">{{ progress }}%</div>
      </div>
    </van-overlay>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from "vue";
import { showToast, showSuccessToast, showFailToast } from "vant";
import api from "@/api";

// --- State ---
const activeCollapse = ref([""]);
const serverFiles = ref<any>(null);
const fileList = ref<any[]>([]);
const imageFile = ref<File | null>(null);
const templateFile = ref<File | null>(null);
const conversionFile = ref<File | null>(null);

const apiUrl = ref("");
const apiKey = ref("");

const recognizing = ref(false);
const processing = ref(false);
const progress = ref(0);
const items = ref<any[]>([]);
const statusText = ref("");
const downloadUrl = ref("");
const lastGeneratedPath = ref("");

const pollLog = ref<any[]>([]);
const lastUploadSummary = ref<any>(null);

// --- Lifecycle ---
onMounted(() => {
  loadSettings();
  checkServerFiles();
  loadHistory();
});

watch([apiUrl, apiKey], () => {
  localStorage.setItem("openai_api_url", apiUrl.value);
  localStorage.setItem("openai_api_key", apiKey.value);
});

// --- Methods ---

const loadSettings = () => {
  apiUrl.value =
    localStorage.getItem("openai_api_url") ||
    "https://api.openai.com/v1/chat/completions";
  apiKey.value = localStorage.getItem("openai_api_key") || "";
};

const checkServerFiles = async () => {
  try {
    const res = await api.get("/ledger/files");
    serverFiles.value = res.data;
  } catch (_) {}
};

const loadHistory = () => {
  const s = localStorage.getItem("external_upload_last");
  if (s) {
    try {
      lastUploadSummary.value = JSON.parse(s);
    } catch (_) {}
  }
};

// 1. Image Handling
const afterReadImage = (file: any) => {
  imageFile.value = file.file;
};

const startRecognition = async () => {
  if (!imageFile.value) return showToast("请先上传图片");
  recognizing.value = true;
  progress.value = 0;
  items.value = [];

  // Fake progress
  const timer = setInterval(() => {
    if (progress.value < 90)
      progress.value += Math.floor(Math.random() * 5) + 1;
  }, 200);

  try {
    const fd = new FormData();
    fd.append("file", imageFile.value);
    fd.append("api_url", apiUrl.value);
    fd.append("api_key", apiKey.value);

    const res = await api.post("/ledger/image-recognize", fd);
    clearInterval(timer);
    progress.value = 100;

    setTimeout(() => {
      recognizing.value = false;
      items.value = res.data.items || [];
      statusText.value = `识别到 ${items.value.length} 条`;
      showSuccessToast("识别完成");
    }, 500);
  } catch (e) {
    clearInterval(timer);
    recognizing.value = false;
    showFailToast("识别失败");
  }
};

// 2. Template Handling
const onTemplateSelect = (file: any) => {
  templateFile.value = file.file;
  showToast(`已选进货表: ${file.file.name}`);
};

const onConversionSelect = (file: any) => {
  conversionFile.value = file.file;
  showToast(`已选换算表: ${file.file.name}`);
};

// 3. Processing
const processLedger = async (dryRun: boolean) => {
  if (items.value.length === 0) return showToast("无识别数据");

  processing.value = true;
  try {
    let res: any;

    if (!templateFile.value) {
      // Simple process
      res = await api.post("/ledger/process", {
        items: items.value,
        dry_run: dryRun,
      });
    } else {
      // With templates
      const fd = new FormData();
      fd.append("template", templateFile.value);
      if (conversionFile.value) fd.append("conversion", conversionFile.value);
      fd.append("items", JSON.stringify(items.value));
      if (dryRun) fd.append("dry_run", "1");

      res = await api.post("/ledger/process-upload", fd);
    }

    const data = res.data;
    const meta = data.meta || {};
    const updated = meta.updatedRows || 0;
    const deleted = meta.deletedRows || 0;

    if (dryRun) {
      statusText.value = `预览: 有效${updated}行, 移除${deleted}行`;
      showToast("预览完成");
    } else {
      const saved = data.saved;
      const path = data.path;
      lastGeneratedPath.value = path;
      statusText.value = saved ? `已生成: ${path}` : "生成失败";

      if (saved && path) {
        downloadUrl.value = `/api/v1/ledger/download?path=${encodeURIComponent(
          path
        )}`;
        // Start external upload flow
        pollLog.value = [];
        uploadToGov(path);
      }

      if (data.errors && data.errors.length) {
        showToast(`部分记录存在问题 ${data.errors.length} 条`);
      }
    }
  } catch (e) {
    showFailToast("处理失败");
  } finally {
    processing.value = false;
  }
};

// 4. External Upload
const uploadToGov = async (path: string) => {
  // Mock settings for now, assuming user sets them in "Settings" page or we use defaults
  // In real app, we should probably read from localStorage too
  const token = localStorage.getItem("ext_token") || "";
  // If token missing, maybe skip or warn. For now we proceed as if backend handles it or fails.

  try {
    const res = await api.post("/ledger/external-upload", {
      path,
      token: token || "default_token", // Fallback
      cookie: localStorage.getItem("ext_cookie") || "",
      user_agent: localStorage.getItem("ext_ua") || "Apifox/1.0.0",
    });

    const ok = res.data.ok;
    const upstreamId = res.data.upstream?.content;
    statusText.value = ok ? `已上传, ID: ${upstreamId || "-"}` : "上传启动失败";

    if (ok) {
      pollStatus(token);
    }
  } catch (e) {
    statusText.value = "上传请求失败";
  }
};

const pollStatus = async (token: string) => {
  let attempts = 0;
  while (attempts < 20) {
    await new Promise((r) => setTimeout(r, 3000));
    try {
      const res = await api.get("/ledger/external-upload/status", {
        params: { token },
      });
      const st = res.data;
      const status = st.status;
      const sum = st.sum || {};

      const logEntry = {
        status,
        loaded: sum.loaded || 0,
        failed: sum.failed || 0,
        time: new Date().toLocaleTimeString(),
      };
      pollLog.value.unshift(logEntry);

      if (status === "success") {
        showSuccessToast("上传成功");
        saveHistory("success", logEntry);
        break;
      }
      attempts++;
    } catch (e) {
      break;
    }
  }
};

const saveHistory = (status: string, log: any) => {
  const summary = {
    status,
    loaded: log.loaded,
    failed: log.failed,
    path: lastGeneratedPath.value,
    time: new Date().toISOString(),
  };
  lastUploadSummary.value = summary;
  localStorage.setItem("external_upload_last", JSON.stringify(summary));
};

// Helpers
const copyLink = async () => {
  try {
    const absUrl = window.location.origin + downloadUrl.value;
    await navigator.clipboard.writeText(absUrl);
    showToast("已复制");
  } catch (e) {
    showToast("复制失败");
  }
};

const testDownload = () => {
  if (downloadUrl.value) {
    window.location.href = downloadUrl.value;
  }
};

const formatTime = (iso: string) => {
  if (!iso) return "-";
  return new Date(iso).toLocaleString();
};

const getStatusColor = (s: string) => {
  if (s === "success") return "text-green-600 font-bold";
  if (s === "processing") return "text-blue-600";
  return "text-gray-500";
};

const translateStatus = (s: string) => {
  const map: Record<string, string> = {
    success: "成功",
    processing: "处理中",
    failed: "失败",
    pending: "等待中",
  };
  return map[s] || s;
};
</script>
