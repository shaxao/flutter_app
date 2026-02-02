<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="借货统计"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-3 bg-white dark:bg-[#1C1917] mb-2 shadow-sm border-b border-gray-100 dark:border-gray-800 space-y-2">
      <div class="flex gap-2">
        <van-search
          v-model="search"
          placeholder="搜索借货人、货物名称"
          class="flex-1 px-0 py-0 dark:bg-gray-800"
          background="transparent"
        />
        <van-dropdown-menu class="h-8">
          <van-dropdown-item v-model="statusFilter" :options="statusOptions" />
        </van-dropdown-menu>
      </div>

      <div class="flex justify-between items-center text-xs text-gray-500 dark:text-gray-400 px-1">
        <span>总记录: {{ records.length }}</span>
        <span
          >待还:
          {{ records.filter((r) => r.status === "pending").length }}</span
        >
        <span
          >已还:
          {{ records.filter((r) => r.status === "returned").length }}</span
        >
      </div>
    </div>

    <div class="px-3 space-y-3">
      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty
        v-else-if="filteredRecords.length === 0"
        description="暂无数据"
      />

      <div v-else class="space-y-3">
        <div
          v-for="r in filteredRecords"
          :key="r.id"
          class="bg-white dark:bg-[#1C1917] rounded-lg p-3 shadow-sm border border-gray-100 dark:border-gray-800"
        >
          <div class="flex justify-between items-start mb-2">
            <div class="font-bold text-gray-800 dark:text-gray-100">
              {{ r.borrower }}
              <span class="text-xs font-normal text-gray-500 dark:text-gray-400"
                >({{ r.borrowUnit }})</span
              >
            </div>
            <div
              class="text-xs px-2 py-1 rounded"
              :class="getStatusClass(r.status)"
            >
              {{ getStatusText(r.status) }}
            </div>
          </div>

          <div class="text-xs text-gray-500 dark:text-gray-400 mb-2 space-y-1">
            <div>日期: {{ r.borrowDate }}</div>
            <div>来源: {{ r.sourceUnit }} - {{ r.sourcePerson }}</div>
          </div>

          <div class="flex justify-end gap-2 mb-2">
            <van-button
              size="mini"
              type="primary"
              plain
              @click="openReturnDialog(r)"
              >还货</van-button
            >
            <van-button size="mini" type="danger" plain @click="deleteRecord(r)"
              >删除</van-button
            >
            <van-button size="mini" plain @click="toggleExpand(r.id)">{{
              expanded.has(r.id) ? "收起" : "明细"
            }}</van-button>
          </div>

          <transition name="van-slide-down">
            <div
              v-if="expanded.has(r.id)"
              class="bg-gray-50 dark:bg-gray-800 rounded p-2 text-sm space-y-2"
            >
              <div
                v-for="item in r.items"
                :key="item.id"
                class="border-b border-gray-200 dark:border-gray-700 last:border-0 pb-2 last:pb-0"
              >
                <div class="flex justify-between">
                  <span class="font-medium dark:text-gray-200"
                    >{{ item.name }} ({{ item.spec }})</span
                  >
                  <van-button
                    size="mini"
                    plain
                    type="primary"
                    class="h-6"
                    @click="returnSingleItem(r, item)"
                    >还此项</van-button
                  >
                </div>
                <div class="text-xs text-gray-500 dark:text-gray-400 mt-1 flex justify-between">
                  <span>数量: {{ item.quantity }}</span>
                  <span>已还: {{ item.returnedQuantity }}</span>
                </div>
              </div>
            </div>
          </transition>
        </div>
      </div>
    </div>

    <van-floating-bubble
      icon="plus"
      axis="xy"
      magnetic="x"
      @click="showAddDialog = true"
    />

    <!-- Add Dialog -->
    <van-popup
      v-model:show="showAddDialog"
      position="bottom"
      round
      style="height: 80%"
      closeable
      class="dark:bg-[#1C1917]"
    >
      <div class="p-4 h-full flex flex-col">
        <h3 class="text-lg font-bold mb-4 text-center dark:text-white">新增借货记录</h3>
        <div class="flex-1 overflow-y-auto space-y-3 px-1">
          <van-field
            v-model="form.borrower"
            label="借货人"
            placeholder="请输入"
          />
          <van-field
            v-model="form.borrowDate"
            label="日期"
            placeholder="YYYY-MM-DD"
            @click="showFormCalendar = true"
            readonly
          />
          <van-field
            v-model="form.borrowUnit"
            label="借出单位"
            placeholder="请输入"
          />
          <van-field
            v-model="form.sourceUnit"
            label="来源单位"
            placeholder="请输入"
          />
          <van-field
            v-model="form.sourcePerson"
            label="来源人"
            placeholder="请输入"
          />

          <div class="font-bold text-sm mt-4 mb-2 flex justify-between">
            <span>商品列表</span>
            <van-button
              size="mini"
              icon="plus"
              type="primary"
              plain
              @click="addFormItem"
              >添加</van-button
            >
          </div>

          <div
            v-for="(it, idx) in form.items"
            :key="idx"
            class="bg-gray-50 dark:bg-gray-800 p-2 rounded relative"
          >
            <van-icon
              name="cross"
              class="absolute top-1 right-1 text-gray-400 dark:text-gray-500 p-1"
              @click="form.items.splice(idx, 1)"
            />
            <div class="grid grid-cols-2 gap-2">
              <input
                v-model="it.name"
                placeholder="名称"
                class="bg-white dark:bg-gray-900 dark:text-gray-200 px-2 py-1 rounded text-sm border border-gray-200 dark:border-gray-700"
              />
              <input
                v-model="it.spec"
                placeholder="规格"
                class="bg-white dark:bg-gray-900 dark:text-gray-200 px-2 py-1 rounded text-sm border border-gray-200 dark:border-gray-700"
              />
              <input
                v-model="it.qty"
                type="number"
                placeholder="数量"
                class="bg-white dark:bg-gray-900 dark:text-gray-200 px-2 py-1 rounded text-sm border border-gray-200 dark:border-gray-700 col-span-2"
              />
            </div>
          </div>
        </div>
        <div class="pt-4">
          <van-button
            block
            type="primary"
            @click="submitAdd"
            :loading="submitting"
            >保存</van-button
          >
        </div>
      </div>
    </van-popup>

    <!-- Return Dialog -->
    <van-popup
      v-model:show="showReturnDialog"
      position="bottom"
      round
      style="height: 60%"
      closeable
      class="dark:bg-[#1C1917]"
    >
      <div class="p-4 h-full flex flex-col">
        <h3 class="text-lg font-bold mb-4 text-center dark:text-white">确认还货</h3>
        <div class="flex-1 overflow-y-auto space-y-3 px-1" v-if="returnTarget">
          <div
            v-for="it in returnTarget.items"
            :key="it.id"
            class="flex items-center justify-between"
          >
            <div class="flex-1">
              <div class="text-sm dark:text-gray-200">{{ it.name }}</div>
              <div class="text-xs text-gray-500 dark:text-gray-400">
                借:{{ it.quantity }} 已还:{{ it.returnedQuantity }}
              </div>
            </div>
            <div class="w-20">
              <input
                v-model="returnQtyMap[it.id]"
                type="number"
                placeholder="归还数"
                class="w-full bg-gray-50 dark:bg-gray-800 dark:text-gray-200 border dark:border-gray-700 rounded px-2 py-1 text-sm"
              />
            </div>
          </div>

          <van-field
            v-model="returnDate"
            label="还货日期"
            placeholder="YYYY-MM-DD"
            @click="showReturnCalendar = true"
            readonly
          />
          <van-field v-model="returnNotes" label="备注" placeholder="选填" />
        </div>
        <div class="pt-4">
          <van-button
            block
            type="primary"
            @click="submitReturn"
            :loading="submitting"
            >确认归还</van-button
          >
        </div>
      </div>
    </van-popup>

    <!-- Single Item Return Dialog -->
    <van-dialog
      v-model:show="showSingleReturnDialog"
      title="归还此项"
      show-cancel-button
      @confirm="submitSingleReturn"
    >
      <div class="p-4">
        <div class="text-center mb-2">{{ singleReturnItem?.name }}</div>
        <van-field
          v-model="singleReturnQty"
          type="number"
          label="归还数量"
          placeholder="请输入"
          class="bg-gray-50 rounded"
        />
      </div>
    </van-dialog>

    <van-calendar
      v-model:show="showFormCalendar"
      @confirm="
        (d) => {
          form.borrowDate = fmtDate(d);
          showFormCalendar = false;
        }
      "
    />
    <van-calendar
      v-model:show="showReturnCalendar"
      @confirm="
        (d) => {
          returnDate = fmtDate(d);
          showReturnCalendar = false;
        }
      "
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from "vue";
import { showToast, showConfirmDialog, showNotify } from "vant";
import api from "@/api";

const loading = ref(false);
const submitting = ref(false);
const records = ref<any[]>([]);
const search = ref("");
const statusFilter = ref("all");
const statusOptions = [
  { text: "全部状态", value: "all" },
  { text: "待还货", value: "pending" },
  { text: "部分还货", value: "partial" },
  { text: "已还货", value: "returned" },
];
const expanded = reactive(new Set<number>());

// Add Form
const showAddDialog = ref(false);
const showFormCalendar = ref(false);
const form = reactive({
  borrower: "",
  borrowDate: "",
  borrowUnit: "",
  sourceUnit: "",
  sourcePerson: "",
  items: [{ name: "", spec: "", qty: "" }],
});

// Return Form
const showReturnDialog = ref(false);
const showReturnCalendar = ref(false);
const returnTarget = ref<any>(null);
const returnQtyMap = reactive<Record<number, string>>({});
const returnDate = ref("");
const returnNotes = ref("");

// Single Return
const showSingleReturnDialog = ref(false);
const singleReturnTarget = ref<any>(null);
const singleReturnItem = ref<any>(null);
const singleReturnQty = ref("");

onMounted(() => {
  loadData();
  form.borrowDate = fmtDate(new Date());
});

const loadData = async () => {
  loading.value = true;
  try {
    const res = await api.get("/borrow/records");
    records.value = res.data || [];
  } finally {
    loading.value = false;
  }
};

const filteredRecords = computed(() => {
  let list = records.value;
  if (statusFilter.value !== "all") {
    list = list.filter((r) => (r.status || "pending") === statusFilter.value);
  }
  const q = search.value.trim().toLowerCase();
  if (q) {
    list = list.filter((r) => {
      const b = (r.borrower || "").toLowerCase();
      const items = r.items || [];
      const hasItem = items.some((it: any) =>
        (it.name || "").toLowerCase().includes(q)
      );
      return b.includes(q) || hasItem;
    });
  }
  return list;
});

const toggleExpand = (id: number) => {
  if (expanded.has(id)) expanded.delete(id);
  else expanded.add(id);
};

const getStatusText = (s: string) => {
  const map: any = {
    pending: "待还货",
    partial: "部分还货",
    returned: "已还货",
  };
  return map[s] || s;
};

const getStatusClass = (s: string) => {
  if (s === "returned") return "bg-gray-100 text-gray-500";
  if (s === "partial") return "bg-orange-50 text-orange-600";
  return "bg-blue-50 text-blue-600";
};

// Add Logic
const addFormItem = () => {
  form.items.push({ name: "", spec: "", qty: "" });
};

const submitAdd = async () => {
  if (!form.borrower || !form.borrowDate) return showToast("请填写基本信息");
  const itemsPayload = form.items
    .filter((i) => i.name && parseFloat(i.qty) > 0)
    .map((i) => ({
      name: i.name,
      spec: i.spec,
      quantity: parseFloat(i.qty),
      returnedQuantity: 0,
    }));

  if (itemsPayload.length === 0) return showToast("请添加有效商品");

  submitting.value = true;
  try {
    await api.post("/borrow/records", {
      ...form,
      items: itemsPayload,
    });
    showToast("添加成功");
    showAddDialog.value = false;
    // Reset
    form.borrower = "";
    form.items = [{ name: "", spec: "", qty: "" }];
    loadData();
  } catch (e) {
    showNotify({ type: "danger", message: "添加失败" });
  } finally {
    submitting.value = false;
  }
};

const deleteRecord = (r: any) => {
  showConfirmDialog({ title: "确认删除", message: "确定要删除此记录吗？" })
    .then(async () => {
      await api.delete(`/borrow/records/${r.id}`);
      showToast("已删除");
      loadData();
    })
    .catch(() => {});
};

// Return Logic
const openReturnDialog = (r: any) => {
  returnTarget.value = r;
  returnDate.value = fmtDate(new Date());
  returnNotes.value = "";
  // Reset map
  for (const k in returnQtyMap) delete returnQtyMap[k];
  showReturnDialog.value = true;
};

const submitReturn = async () => {
  if (!returnTarget.value) return;
  const returns: any[] = [];
  returnTarget.value.items.forEach((it: any) => {
    const q = parseFloat(returnQtyMap[it.id] || "0") || 0;
    if (q > 0) {
      returns.push({ itemId: it.id, qty: q });
    }
  });

  if (returns.length === 0) return showToast("请输入归还数量");

  submitting.value = true;
  try {
    await api.post(`/borrow/records/${returnTarget.value.id}/return`, {
      returns,
      returnDate: returnDate.value,
      returnNotes: returnNotes.value,
    });
    showToast("归还成功");
    showReturnDialog.value = false;
    loadData();
  } catch (e) {
    showNotify({ type: "danger", message: "操作失败" });
  } finally {
    submitting.value = false;
  }
};

// Single Item Return
const returnSingleItem = (r: any, item: any) => {
  singleReturnTarget.value = r;
  singleReturnItem.value = item;
  singleReturnQty.value = "";
  showSingleReturnDialog.value = true;
};

const submitSingleReturn = async () => {
  const qty = parseFloat(singleReturnQty.value) || 0;
  if (qty <= 0) return;
  try {
    await api.post(`/borrow/records/${singleReturnTarget.value.id}/return`, {
      returns: [{ itemId: singleReturnItem.value.id, qty }],
    });
    showToast("归还成功");
    loadData();
  } catch (e) {
    showNotify({ type: "danger", message: "操作失败" });
  }
};

const fmtDate = (d: Date) => {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const da = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${da}`;
};
</script>
