<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="配料管理"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-3 bg-white mb-2 shadow-sm flex gap-2">
      <van-search
        v-model="search"
        placeholder="搜索配料名称"
        class="flex-1 px-0 py-0"
        background="transparent"
      />
      <van-button
        type="primary"
        size="small"
        icon="plus"
        @click="openDialog(null)"
        >新增</van-button
      >
    </div>

    <div class="px-3 space-y-2">
      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty v-else-if="filteredList.length === 0" description="暂无数据" />

      <div
        v-for="item in filteredList"
        :key="item.id"
        class="bg-white p-3 rounded-lg shadow-sm border border-gray-100 flex justify-between items-center"
      >
        <div>
          <div class="font-bold text-gray-800">{{ item.name }}</div>
          <div class="text-xs text-gray-500">
            单位: {{ item.default_unit || "-" }} | 库存: {{ item.stock }}
          </div>
        </div>
        <div class="flex gap-2">
          <van-icon
            name="edit"
            class="text-blue-500 p-2 bg-blue-50 rounded-full"
            @click="openDialog(item)"
          />
          <van-icon
            name="delete"
            class="text-red-500 p-2 bg-red-50 rounded-full"
            @click="deleteItem(item)"
          />
        </div>
      </div>
    </div>

    <van-dialog
      v-model:show="showDialog"
      :title="editingId ? '编辑配料' : '新增配料'"
      show-cancel-button
      @confirm="saveItem"
    >
      <div class="p-4 space-y-3">
        <van-field
          v-model="form.name"
          label="名称"
          placeholder="请输入"
          class="bg-gray-50 rounded"
        />
        <van-field
          v-model="form.unit"
          label="单位"
          placeholder="如: g, ml, 个"
          class="bg-gray-50 rounded"
        />
        <van-field
          v-model="form.stock"
          type="number"
          label="库存"
          placeholder="0"
          class="bg-gray-50 rounded"
        />
        <van-field
          v-model="form.price"
          type="number"
          label="单价"
          placeholder="0.0"
          class="bg-gray-50 rounded"
        />
      </div>
    </van-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, computed } from "vue";
import { showToast, showConfirmDialog, showNotify } from "vant";
import api from "@/api";

const loading = ref(false);
const list = ref<any[]>([]);
const search = ref("");
const showDialog = ref(false);
const editingId = ref<number | null>(null);
const form = reactive({ name: "", unit: "", stock: "", price: "" });

onMounted(() => {
  loadData();
});

const loadData = async () => {
  loading.value = true;
  try {
    const res = await api.get("/menu/ingredients");
    list.value = res.data.data || [];
  } finally {
    loading.value = false;
  }
};

const filteredList = computed(() => {
  const q = search.value.trim().toLowerCase();
  if (!q) return list.value;
  return list.value.filter((i) => (i.name || "").toLowerCase().includes(q));
});

const openDialog = (item: any) => {
  if (item) {
    editingId.value = item.id;
    form.name = item.name;
    form.unit = item.default_unit || "";
    form.stock = String(item.stock || 0);
    form.price = String(item.price || 0);
  } else {
    editingId.value = null;
    form.name = "";
    form.unit = "";
    form.stock = "";
    form.price = "";
  }
  showDialog.value = true;
};

const saveItem = async () => {
  if (!form.name) return showToast("请输入名称");
  try {
    const payload = {
      name: form.name,
      default_unit: form.unit,
      stock: parseFloat(form.stock) || 0,
      price: parseFloat(form.price) || 0,
    };

    if (editingId.value) {
      await api.put(`/menu/ingredients/${editingId.value}`, payload);
    } else {
      await api.post("/menu/ingredients", payload);
    }
    showToast("保存成功");
    loadData();
  } catch (e) {
    showNotify({ type: "danger", message: "保存失败" });
  }
};

const deleteItem = (item: any) => {
  showConfirmDialog({ title: "删除", message: `确定删除 "${item.name}" 吗?` })
    .then(async () => {
      try {
        await api.delete(`/menu/ingredients/${item.id}`);
        showToast("已删除");
        loadData();
      } catch (e) {
        showToast("删除失败");
      }
    })
    .catch(() => {});
};
</script>
