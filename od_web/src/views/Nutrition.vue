<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="营养数据管理"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <div class="p-4 space-y-4">
      <!-- Single Edit -->
      <div class="bg-white rounded-lg p-4 shadow-sm">
        <h3 class="font-bold text-gray-800 mb-3">单项录入/更新</h3>
        <van-cell-group inset>
          <van-field
            v-model="form.name"
            label="原料名称"
            placeholder="请输入"
          />
          <van-field
            v-model="form.cal"
            type="number"
            label="热量"
            placeholder="每100g"
          />
          <van-field
            v-model="form.pro"
            type="number"
            label="蛋白质"
            placeholder="每100g"
          />
          <van-field
            v-model="form.fat"
            type="number"
            label="脂肪"
            placeholder="每100g"
          />
          <van-field
            v-model="form.carb"
            type="number"
            label="碳水"
            placeholder="每100g"
          />
        </van-cell-group>
        <div class="mt-4">
          <van-button block type="primary" :loading="saving" @click="saveSingle"
            >保存</van-button
          >
        </div>
      </div>

      <!-- Batch Import -->
      <div class="bg-white rounded-lg p-4 shadow-sm">
        <h3 class="font-bold text-gray-800 mb-2">批量导入</h3>
        <div class="text-xs text-gray-500 mb-2">
          格式：名称,热量,蛋白,脂肪,碳水 (每行一条)
        </div>
        <van-field
          v-model="batchText"
          type="textarea"
          rows="6"
          placeholder="示例：&#10;菠菜,23,2.9,0.4,3.6&#10;牛肉,125,20,4,0"
          class="bg-gray-50 rounded border border-gray-200 mb-3"
        />
        <van-button
          block
          plain
          type="primary"
          :loading="saving"
          @click="saveBatch"
          >批量导入</van-button
        >
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from "vue";
import { showToast, showNotify } from "vant";
import api from "@/api";

const saving = ref(false);
const form = reactive({
  name: "",
  cal: "",
  pro: "",
  fat: "",
  carb: "",
});
const batchText = ref("");

const saveSingle = async () => {
  if (!form.name) return showToast("请输入名称");
  saving.value = true;
  try {
    await api.post("/menu/nutrition", {
      name: form.name,
      calories_per_100g: form.cal,
      protein_per_100g: form.pro,
      fat_per_100g: form.fat,
      carbs_per_100g: form.carb,
    });
    showToast("保存成功");
    // Reset
    form.name = "";
    form.cal = "";
    form.pro = "";
    form.fat = "";
    form.carb = "";
  } catch (e) {
    showNotify({ type: "danger", message: "保存失败" });
  } finally {
    saving.value = false;
  }
};

const saveBatch = async () => {
  if (!batchText.value.trim()) return;
  saving.value = true;
  try {
    const lines = batchText.value.split("\n").filter((l) => l.trim());
    const items = lines
      .map((l) => {
        const p = l.split(/,|，/);
        if (p.length < 5) return null;
        return {
          name: (p[0] || "").trim(),
          calories_per_100g: (p[1] || "").trim(),
          protein_per_100g: (p[2] || "").trim(),
          fat_per_100g: (p[3] || "").trim(),
          carbs_per_100g: (p[4] || "").trim(),
        };
      })
      .filter((x) => x);

    if (items.length === 0) return showToast("无有效数据");

    await api.post("/menu/nutrition/batch", { items });
    showToast(`成功导入 ${items.length} 条`);
    batchText.value = "";
  } catch (e) {
    showNotify({ type: "danger", message: "导入失败" });
  } finally {
    saving.value = false;
  }
};
</script>
