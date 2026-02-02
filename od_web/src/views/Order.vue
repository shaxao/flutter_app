<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <!-- Header -->
    <van-nav-bar
      title="订货管理"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <!-- Controls & Filters -->
    <div class="p-3 bg-white dark:bg-[#1C1917] mb-2 shadow-sm border-b border-gray-100 dark:border-gray-800">
      <van-search
        v-model="searchText"
        placeholder="搜索商品编号或名称"
        @update:model-value="onSearch"
        class="dark:bg-gray-800"
      />

      <div class="flex justify-between items-center mt-2 px-1">
        <span class="text-xs text-gray-500 dark:text-gray-400">{{ statusText }}</span>
        <van-button
          size="mini"
          type="primary"
          variant="text"
          @click="showControls = !showControls"
        >
          {{ showControls ? "隐藏操作" : "显示操作" }}
        </van-button>
      </div>

      <transition name="van-fade">
        <div v-if="showControls" class="mt-3 p-3 bg-gray-50 dark:bg-gray-800 rounded-lg">
          <!-- Actions Row 1 -->
          <div class="flex flex-wrap gap-2 mb-3">
            <van-button size="small" icon="description" @click="copyOrderColumn"
              >复制数量</van-button
            >
            <van-uploader :after-read="handleExcelUpload" accept=".xlsx,.xls">
              <van-button size="small" type="primary" plain icon="upgrade"
                >导入Excel</van-button
              >
            </van-uploader>
            <van-button size="small" @click="toggleSort">
              {{ isSorted ? "恢复原序" : "按排序顺序" }}
            </van-button>
            <van-button
              size="small"
              plain
              type="primary"
              @click="showSortTextDialog = true"
            >
              粘贴排序
            </van-button>
            <van-uploader :after-read="handleSortFileUpload" accept=".txt">
              <van-button size="small" variant="text">上传排序文件</van-button>
            </van-uploader>
            <van-button
              size="small"
              type="primary"
              :loading="saving"
              @click="saveOrder"
            >
              保存数据
            </van-button>
          </div>

          <!-- Date Filters -->
          <div
            class="flex flex-wrap items-center gap-2 p-2 bg-white dark:bg-[#1C1917] rounded border border-gray-100 dark:border-gray-700"
          >
            <van-dropdown-menu class="h-8">
              <van-dropdown-item
                v-model="dateMode"
                :options="dateModeOptions"
              />
            </van-dropdown-menu>

            <template v-if="dateMode === 0">
              <div
                class="flex-1 h-8 px-2 flex items-center bg-gray-100 dark:bg-gray-800 rounded text-sm text-gray-600 dark:text-gray-300 truncate"
                @click="showCalendar = true"
              >
                {{ chooseDate || "选择日期" }}
              </div>
              <van-button size="small" plain type="primary" @click="loadByDate"
                >查询</van-button
              >
              <van-button size="small" plain @click="saveToDate"
                >保存到日期</van-button
              >
            </template>

            <template v-else>
              <div
                class="flex-1 h-8 px-2 flex items-center bg-gray-100 dark:bg-gray-800 rounded text-sm text-gray-600 dark:text-gray-300 truncate"
                @click="showRangeCalendar = true"
              >
                {{
                  startDate && endDate
                    ? `${startDate} - ${endDate}`
                    : "选择范围"
                }}
              </div>
              <van-button size="small" plain type="primary" @click="loadRange"
                >查询范围</van-button
              >
            </template>
          </div>
        </div>
      </transition>
    </div>

    <!-- Data List -->
    <div class="px-3">
      <van-empty
        v-if="viewItems.length === 0 && !loading"
        description="暂无数据"
      />
      <div v-else class="space-y-3">
        <transition-group name="list" tag="div">
          <div
            v-for="(item, index) in viewItems"
            :key="item.rid || index"
            class="bg-white dark:bg-[#1C1917] rounded-xl p-3 shadow-sm border border-gray-100 dark:border-gray-800"
          >
            <!-- Header -->
            <div class="flex justify-between items-start mb-2">
              <div class="font-bold text-gray-800 dark:text-gray-100 text-base leading-tight">
                {{ item.product_name }}
              </div>
              <div
                class="px-2 py-1 rounded text-xs font-bold"
                :class="
                  item.qtyVal && parseFloat(item.qtyVal) > 0
                    ? 'bg-green-100 text-green-700'
                    : 'bg-gray-100 text-gray-400'
                "
              >
                {{ formatCompact(item.isBoxUnit ? item.initBox : item.qtyVal) }}
              </div>
            </div>

            <!-- Meta -->
            <div
              class="flex justify-between items-center text-xs text-gray-500 dark:text-gray-400 mb-2"
            >
              <div class="truncate pr-2">
                ID: {{ item.product_id }} | 规格: {{ item.spec }}
              </div>
              <div
                class="text-blue-500 dark:text-blue-400 cursor-pointer whitespace-nowrap"
                @click="toggleDetail(item.rid)"
              >
                {{ detailExpanded.has(item.rid) ? "收起" : "查看更多" }}
              </div>
            </div>

            <!-- Tags -->
            <div class="flex flex-wrap gap-2 mb-2">
              <span
                v-if="item.unit"
                class="px-2 py-0.5 bg-blue-50 text-blue-600 rounded-full text-xs flex items-center"
              >
                <van-icon name="bag-o" class="mr-1" /> {{ item.unit }}
              </span>
              <span
                v-if="item.limit"
                class="px-2 py-0.5 bg-orange-50 text-orange-600 rounded-full text-xs flex items-center"
              >
                <van-icon name="flag-o" class="mr-1" /> {{ item.limit }}
              </span>
            </div>

            <!-- Details -->
            <div
              v-if="detailExpanded.has(item.rid)"
              class="mb-3 p-2 bg-gray-50 dark:bg-gray-800 rounded text-xs text-green-700 dark:text-green-400"
            >
              每箱规格: {{ item.upb > 0 ? item.upb : "-" }}
            </div>

            <!-- Input Action -->
            <div class="flex items-center gap-2">
              <van-field
                v-model="item.qtyVal"
                placeholder="库存量"
                type="number"
                class="bg-gray-50 dark:bg-gray-800 rounded-lg py-1 px-2 flex-1"
                :border="false"
                @update:model-value="(val) => onQtyChanged(item, val)"
              />
              <div
                class="h-8 w-20 flex items-center justify-center rounded-lg border cursor-pointer transition-colors select-none"
                :class="
                  confirmationStatus[item.rid]
                    ? 'bg-green-50 dark:bg-green-900/30 border-green-500 dark:border-green-600 text-green-700 dark:text-green-400'
                    : 'bg-gray-50 dark:bg-gray-800 border-gray-300 dark:border-gray-700 text-gray-400 dark:text-gray-500'
                "
                @click="toggleConfirm(item.rid)"
              >
                <span class="text-xs">
                  {{ confirmationStatus[item.rid] ? "✓ 已确认" : "○ 未确认" }}
                </span>
              </div>
            </div>

            <div class="mt-2 text-xs text-gray-400 dark:text-gray-500 flex justify-end">
              {{ item.isBoxUnit ? "订货(箱)" : "订货数量" }}
            </div>
          </div>
        </transition-group>
      </div>
    </div>

    <!-- Calendar Dialogs -->
    <van-calendar v-model:show="showCalendar" @confirm="onConfirmDate" />
    <van-calendar
      v-model:show="showRangeCalendar"
      type="range"
      @confirm="onConfirmRange"
      :min-date="new Date(2020, 0, 1)"
      :max-date="new Date(2030, 11, 31)"
    />

    <!-- Sort Text Dialog -->
    <van-dialog
      v-model:show="showSortTextDialog"
      title="粘贴排序文本"
      show-cancel-button
      @confirm="saveSortText"
    >
      <van-field
        v-model="sortTextEdit"
        rows="10"
        autosize
        type="textarea"
        placeholder="每行一个商品名称"
        class="bg-gray-50 dark:bg-gray-800 m-2 rounded"
      />
    </van-dialog>

    <van-loading
      v-if="loading"
      vertical
      class="fixed inset-0 flex items-center justify-center bg-white/50 z-50"
    >
      加载中...
    </van-loading>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import { showToast, showNotify } from "vant";
import * as XLSX from "xlsx";
import api from "@/api";

// --- State ---
const loading = ref(false);
const saving = ref(false);
const items = ref<any[]>([]);
const viewItems = ref<any[]>([]);
const statusText = ref("");
const searchText = ref("");
const showControls = ref(true);
const detailExpanded = reactive(new Set<number>());
const confirmationStatus = reactive<Record<number, boolean>>({});

// Sorting
const sortOrder = ref<string[]>([]);
const isSorted = ref(false);
const originalView = ref<any[]>([]);
const showSortTextDialog = ref(false);
const sortTextEdit = ref("");

// Date
const dateMode = ref(0); // 0: single, 1: range
const dateModeOptions = [
  { text: "按具体日期", value: 0 },
  { text: "按日期范围", value: 1 },
];
const showCalendar = ref(false);
const showRangeCalendar = ref(false);
const chooseDate = ref("");
const startDate = ref("");
const endDate = ref("");

// --- Lifecycle ---
onMounted(() => {
  loadSortOrder();
  loadSavedItems();
  // Try restore local UI state if needed (skipping for MVP complexity)
});

// --- Methods ---

// 1. Data Loading
const loadSavedItems = async () => {
  loading.value = true;
  try {
    const res = await api.get("/order/items");
    items.value = (res.data.items || []).map((i: any) =>
      normalizeItem(i, items.value.length)
    );
    viewItems.value = [...items.value];
    statusText.value = `共 ${viewItems.value.length} 条记录`;
    normalizeViewItems();
  } catch (e) {
    console.error(e);
  } finally {
    loading.value = false;
  }
};

const loadByDate = async () => {
  if (!chooseDate.value) return showToast("请选择日期");
  loading.value = true;
  try {
    const res = await api.get("/order/items", {
      params: { date: chooseDate.value },
    });
    items.value = (res.data.items || []).map((i: any) =>
      normalizeItem(i, items.value.length)
    );
    viewItems.value = [...items.value];
    statusText.value = `${chooseDate.value} 共 ${viewItems.value.length} 条`;
    normalizeViewItems();
  } finally {
    loading.value = false;
  }
};

const loadRange = async () => {
  if (!startDate.value || !endDate.value) return showToast("请选择范围");
  loading.value = true;
  try {
    const res = await api.get("/order/items-range", {
      params: { start: startDate.value, end: endDate.value },
    });
    const data = res.data.data || [];
    const merged: any[] = [];
    data.forEach((entry: any) => {
      const d = entry.date;
      const list = entry.items || [];
      list.forEach((it: any) => {
        merged.push({ ...it, date: d });
      });
    });
    // Sort by date
    merged.sort((a, b) => (a.date || "").localeCompare(b.date || ""));
    items.value = merged.map((i, idx) => normalizeItem(i, idx));
    viewItems.value = [...items.value];
    statusText.value = `范围 ${startDate.value} - ${endDate.value} 共 ${viewItems.value.length} 条`;
    normalizeViewItems();
  } finally {
    loading.value = false;
  }
};

const saveOrder = async () => {
  saving.value = true;
  try {
    // Sync viewItems changes back to items (simple here since they share refs if not filtered/sorted destructively)
    // Actually we should create a map
    const byId: Record<string, any> = {};
    items.value.forEach((it) => {
      const k = String(it.product_id || it.rid);
      byId[k] = it;
    });

    viewItems.value.forEach((vm) => {
      const k = String(vm.product_id || vm.rid);
      if (byId[k]) {
        byId[k].qtyVal = vm.qtyVal;
        byId[k].initBox = vm.initBox;
      }
    });

    const payload = Object.values(byId);
    await api.post("/order/items", { items: payload });

    // Save snapshot
    const today = new Date().toISOString().split("T")[0];
    const key = `history_${today}`;
    await api.post("/order/save", {
      key,
      data: {
        displayData: viewItems.value,
        isSorted: isSorted.value,
        confirmationStatus: confirmationStatus, // simple object
      },
    });

    showToast("保存成功");
  } catch (e) {
    showNotify({ type: "danger", message: "保存失败" });
  } finally {
    saving.value = false;
  }
};

const saveToDate = async () => {
  if (!chooseDate.value) return showToast("请选择日期");
  saving.value = true;
  try {
    await api.post(
      "/order/items",
      { items: items.value },
      { params: { date: chooseDate.value } }
    );
    showToast("已保存到指定日期");
  } finally {
    saving.value = false;
  }
};

// 2. Excel Import
const handleExcelUpload = async (file: any) => {
  loading.value = true;
  try {
    const f = file.file;
    const buffer = await f.arrayBuffer();
    const wb = XLSX.read(buffer, { type: "array" });
    const firstSheetName = wb.SheetNames[0];
    if (!firstSheetName) throw new Error("Excel无工作表");
    const ws = wb.Sheets[firstSheetName];
    if (!ws) throw new Error("工作表为空");
    const json = XLSX.utils.sheet_to_json(ws!, { header: 1 }) as any[][];

    if (!json || json.length === 0) throw new Error("Excel为空");

    // Parse header
    const header = (json[0] || []).map((h: any) => String(h).toLowerCase());
    const idxId = header.findIndex(
      (h) => h.includes("编号") || h.includes("id")
    );
    const idxName = header.findIndex(
      (h) => h.includes("名称") || h.includes("品名") || h.includes("name")
    );
    const idxSpec = header.findIndex(
      (h) => h.includes("规格") || h.includes("spec")
    );
    const idxQty = header.findIndex(
      (h) => h.includes("库存") || h.includes("数量") || h.includes("qty")
    );
    const idxUnit = header.findIndex(
      (h) => h.includes("单位") || h.includes("unit")
    );
    const idxLimit = header.findIndex(
      (h) => h.includes("限定") || h.includes("店")
    );

    const out: any[] = [];
    for (let r = 1; r < json.length; r++) {
      const row = json[r];
      if (!row || row.length === 0) continue;

      const pid = idxId >= 0 ? String(row[idxId] || "") : "";
      const pname = idxName >= 0 ? String(row[idxName] || "") : "";
      if (!pid && !pname) continue;

      const spec = idxSpec >= 0 ? String(row[idxSpec] || "") : "";
      const qty = idxQty >= 0 ? String(row[idxQty] || "") : "";
      const unit = idxUnit >= 0 ? String(row[idxUnit] || "") : "";
      const limit = idxLimit >= 0 ? String(row[idxLimit] || "") : "";

      const upb = parseUpb(spec);
      const isBox = unit.includes("箱") || upb > 1;
      const qtyVal = sanitizeNumber(qty);
      const initBox = isBox && upb > 0 ? computeBoxes(qtyVal, upb) : qtyVal;

      out.push({
        rid: r - 1,
        product_id: pid,
        product_name: pname,
        spec,
        quantity: qty,
        unit,
        limit,
        upb,
        isBoxUnit: isBox,
        qtyVal,
        initBox,
      });
    }

    items.value = out;
    viewItems.value = [...items.value];
    statusText.value = `共 ${viewItems.value.length} 条记录`;
    normalizeViewItems();

    // Upload file backup
    const formData = new FormData();
    formData.append("file", f);
    await api.post("/upload/excel", formData);

    // Auto Save
    if (chooseDate.value) {
      await api.post(
        "/order/items",
        { items: items.value },
        { params: { date: chooseDate.value } }
      );
    } else {
      await api.post("/order/items", { items: items.value });
    }

    showToast("导入成功");
  } catch (e: any) {
    showNotify({ type: "danger", message: "导入失败: " + e.message });
  } finally {
    loading.value = false;
  }
};

// 3. Sorting Logic
const loadSortOrder = async () => {
  try {
    const res = await api.get("/sort-order");
    sortOrder.value = (res.data.order || []).map(String);
    sortTextEdit.value = sortOrder.value.join("\n");
  } catch (_) {}
};

const toggleSort = async () => {
  if (!items.value.length) return;
  await loadSortOrder();

  if (!isSorted.value) {
    originalView.value = [...viewItems.value];
    applySort();
    isSorted.value = true;
    showToast("已排序");
  } else {
    viewItems.value = [...originalView.value];
    isSorted.value = false;
    showToast("已恢复");
  }
};

const applySort = () => {
  const enriched = viewItems.value.map((item, i) => {
    return {
      item,
      paixu: getPaixuIndex(item.product_name || item.name || ""),
      orig: i,
    };
  });

  enriched.sort((a, b) => {
    if (a.paixu !== b.paixu) return a.paixu - b.paixu;
    return a.orig - b.orig;
  });

  viewItems.value = enriched.map((e) => e.item);
};

const getPaixuIndex = (name: string) => {
  if (!sortOrder.value.length) return 999999;
  const nName = normName(name);
  const exact = sortOrder.value.findIndex((x) => normName(x) === nName);
  if (exact >= 0) return exact;

  for (let i = 0; i < sortOrder.value.length; i++) {
    const it = normName(sortOrder.value[i] || "");
    if (nName.includes(it) || it.includes(nName)) return i;
  }
  return 999999;
};

const normName = (s: string) => {
  return String(s)
    .trim()
    .replace(/^\d+\s*秒以上\s*/, "")
    .replace(/[\s\u3000]/g, "")
    .replace(/[，。、：:；;（）()【】\[\]\-_/\\]/g, "");
};

const saveSortText = async () => {
  try {
    await api.post("/sort-order", { text: sortTextEdit.value });
    await loadSortOrder();
    showToast("已保存排序文本");
  } catch (e) {
    showToast("保存失败");
  }
};

const handleSortFileUpload = async (file: any) => {
  const formData = new FormData();
  formData.append("file", file.file);
  try {
    await api.post("/upload/sort-file", formData);
    await loadSortOrder();
    showToast("排序文件已更新");
  } catch (e) {
    showToast("上传失败");
  }
};

// 4. Utils & Helpers
const normalizeItem = (m: any, idx: number) => {
  // Ensure basic fields
  m.rid = m.rid !== undefined ? m.rid : idx;
  const spec = String(m.spec || "");
  m.upb = m.upb || parseUpb(spec);
  const unit = String(m.unit || m.point || "");
  m.unit = unit;
  m.limit = String(m.limit || m.dian || "");
  m.qtyVal = sanitizeNumber(String(m.qtyVal || m.quantity || "0"));
  m.isBoxUnit = m.isBoxUnit === true || unit.includes("箱") || m.upb > 1;

  if (m.isBoxUnit && m.upb > 0) {
    m.initBox = computeBoxes(m.qtyVal, m.upb);
  } else {
    m.initBox = m.qtyVal;
  }
  return m;
};

const normalizeViewItems = () => {
  // Re-run normalize on current view items just in case
  viewItems.value = viewItems.value.map((it, i) =>
    normalizeItem(it, it.rid ?? i)
  );
};

const parseUpb = (spec: string) => {
  const s = spec.replace(/\s+/g, "");
  const parts = s.split("*");
  for (let i = parts.length - 1; i >= 0; i--) {
    const m = (parts[i] || "").match(/(\d{1,4})/);
    if (m) return parseInt(m[1]!, 10);
  }
  return 0;
};

const sanitizeNumber = (s: string) => {
  return s.replace(/,/g, "").trim();
};

const computeBoxes = (qtyStr: string, upb: number) => {
  const v = parseFloat(qtyStr) || 0;
  if (upb <= 0) return qtyStr;
  const boxes = v / upb;
  return boxes.toFixed(4).replace(/0+$/, "").replace(/\.$/, "");
};

const formatCompact = (s: string) => {
  const v = parseFloat(String(s).replace(/,/g, "")) || 0;
  if (v >= 1000000) return (v / 1000000).toFixed(1) + "M";
  if (v >= 1000) return (v / 1000).toFixed(1) + "k";
  return String(s);
};

const onQtyChanged = (item: any, val: string) => {
  const s = val.replace(/[^0-9.]/g, "");
  item.qtyVal = s;
  if (item.isBoxUnit && item.upb > 0) {
    item.initBox = computeBoxes(s, item.upb);
  } else {
    item.initBox = s;
  }
  // Sync items
  const found = items.value.find((x) => x.rid === item.rid);
  if (found) {
    found.qtyVal = item.qtyVal;
    found.initBox = item.initBox;
  }
};

// Search
let searchTimer: any;
const onSearch = (val: string) => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    const q = val.trim().toLowerCase();
    if (!q) {
      viewItems.value = [...items.value];
    } else {
      viewItems.value = items.value.filter((it) => {
        const id = String(it.product_id || "").toLowerCase();
        const nm = String(it.product_name || "").toLowerCase();
        return id.includes(q) || nm.includes(q);
      });
    }
    if (isSorted.value) applySort();
    statusText.value = `共 ${viewItems.value.length} 条记录`;
  }, 300);
};

// Calendar Events
const onConfirmDate = (value: Date) => {
  const y = value.getFullYear();
  const m = String(value.getMonth() + 1).padStart(2, "0");
  const d = String(value.getDate()).padStart(2, "0");
  chooseDate.value = `${y}-${m}-${d}`;
  showCalendar.value = false;
};

const onConfirmRange = (values: Date[]) => {
  if (!values || values.length < 2 || !values[0] || !values[1]) return;
  const [start, end] = values;
  const fmt = (v: Date) => {
    const y = v.getFullYear();
    const m = String(v.getMonth() + 1).padStart(2, "0");
    const d = String(v.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  };
  startDate.value = fmt(start);
  endDate.value = fmt(end);
  showRangeCalendar.value = false;
};

// Copy
const copyOrderColumn = async () => {
  const lines = viewItems.value
    .map((m) => {
      return m.isBoxUnit ? m.initBox || "" : m.qtyVal || "";
    })
    .filter((x) => x)
    .join("\n");

  if (!lines) return showToast("无数据");

  try {
    await navigator.clipboard.writeText(lines);
    showToast(`已复制 ${lines.split("\n").length} 行`);
  } catch (e) {
    showToast("复制失败");
  }
};

const toggleDetail = (rid: number) => {
  if (detailExpanded.has(rid)) detailExpanded.delete(rid);
  else detailExpanded.add(rid);
};

const toggleConfirm = (rid: number) => {
  confirmationStatus[rid] = !confirmationStatus[rid];
};
</script>

<style scoped>
.list-move,
.list-enter-active,
.list-leave-active {
  transition: all 0.3s ease;
}
.list-enter-from,
.list-leave-to {
  opacity: 0;
  transform: translateY(10px);
}
.list-leave-active {
  position: absolute;
}
</style>
