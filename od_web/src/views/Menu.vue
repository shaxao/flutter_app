<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="菜单管理"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    >
      <template #right>
        <van-icon name="replay" size="18" @click="loadTree" />
      </template>
    </van-nav-bar>

    <!-- Controls -->
    <van-collapse v-model="activeControls" accordion class="bg-white dark:bg-[#1C1917]">
      <van-collapse-item title="导入/设置" name="1" class="dark:text-gray-100">
        <div class="space-y-3">
          <div class="flex gap-2">
            <van-field
              v-model="pathCtrl"
              placeholder="Markdown路径"
              class="bg-gray-50 rounded px-2 py-1 flex-1"
              :border="false"
            />
            <van-uploader :after-read="onFileSelect" accept=".md,.txt">
              <van-button size="small" icon="desktop-o">选择</van-button>
            </van-uploader>
          </div>
          <div class="flex gap-2 items-center">
            <van-field
              v-model="cuisineCtrl"
              placeholder="菜系"
              class="bg-gray-50 rounded px-2 py-1 w-32"
              :border="false"
            />
            <div class="flex-1"></div>
            <van-button
              size="small"
              type="primary"
              :loading="importing"
              @click="importFile"
              >开始导入</van-button
            >
          </div>
          <div class="flex gap-2 mt-2 pt-2 border-t border-gray-100">
            <van-button size="small" icon="apps-o" to="/menu/category"
              >分类管理</van-button
            >
            <van-button size="small" icon="fire-o" to="/menu/ingredient"
              >配料管理</van-button
            >
          </div>
        </div>
      </van-collapse-item>
    </van-collapse>

    <!-- Search -->
    <div class="p-3 bg-white dark:bg-[#1C1917] shadow-sm mb-2 border-b border-gray-100 dark:border-gray-800">
      <van-search
        v-model="search"
        placeholder="搜索菜品名称..."
        @update:model-value="filterTree"
        class="dark:bg-gray-800"
      />
    </div>

    <!-- Tree List -->
    <div class="px-3 space-y-3">
      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty v-else-if="filteredData.length === 0" description="暂无数据" />

      <div
        v-for="cu in filteredData"
        :key="cu.id"
        class="bg-white dark:bg-[#1C1917] rounded-lg shadow-sm overflow-hidden border border-gray-100 dark:border-gray-800"
      >
        <div
          class="px-4 py-3 bg-blue-50/50 dark:bg-blue-900/30 font-bold text-lg text-blue-800 dark:text-blue-300 border-b border-blue-100 dark:border-blue-800"
        >
          {{ cu.name }}
        </div>

        <van-collapse v-model="activeCats[cu.id]" :border="false">
          <van-collapse-item
            v-for="cat in cu.categories"
            :key="cat.id"
            :name="cat.id"
            :title="cat.name"
            icon="folder-o"
          >
            <template #value>
              <van-icon
                name="plus"
                @click.stop="openDishDialog(null, cat.id)"
              />
            </template>

            <div class="space-y-2">
              <div
                v-for="dish in cat.dishes"
                :key="dish.id"
                class="bg-gray-50 dark:bg-gray-800 rounded overflow-hidden"
              >
                <!-- Dish Header Row -->
                <div
                  class="flex items-center justify-between p-2 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors cursor-pointer"
                  @click="toggleDish(dish)"
                >
                  <div class="flex-1">
                    <div class="font-medium text-gray-800 dark:text-gray-100">{{ dish.name }}</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400" v-if="dish.code">
                      编码: {{ dish.code }}
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <span
                      v-if="dish.price"
                      class="text-green-600 font-bold text-sm"
                      >¥{{ dish.price }}</span
                    >
                    <!-- Expand Icon -->
                    <van-icon
                      :name="
                        expandedDishes.has(dish.id) ? 'arrow-up' : 'arrow-down'
                      "
                      class="text-gray-400 p-1"
                    />
                    <!-- Actions -->
                    <van-icon
                      name="edit"
                      class="text-blue-500 p-1"
                      @click.stop="openDishDialog(dish, cat.id)"
                    />
                    <van-icon
                      name="delete"
                      class="text-red-500 p-1"
                      @click.stop="confirmDeleteDish(dish)"
                    />
                  </div>
                </div>

                <!-- Expanded Content -->
                <div
                  v-if="expandedDishes.has(dish.id)"
                  class="px-4 pb-2 border-t border-gray-100 dark:border-gray-700 bg-white dark:bg-[#1C1917]"
                >
                  <div
                    class="flex justify-between items-center py-2 border-b border-dashed border-gray-100 dark:border-gray-700 mb-2"
                  >
                    <span class="text-xs font-bold text-gray-500 dark:text-gray-400"
                      >配料列表</span
                    >
                    <!-- Optional: Quick Edit Button inside -->
                    <!-- <van-button size="mini" plain type="primary" @click.stop="openDishDialog(dish, cat.id)">编辑配料</van-button> -->
                  </div>

                  <van-loading
                    v-if="dishLoading.has(dish.id)"
                    size="small"
                    vertical
                    class="py-2"
                    >加载中...</van-loading
                  >
                  <div
                    v-else-if="
                      !dishIngredients[dish.id] ||
                      dishIngredients[dish.id]?.length === 0
                    "
                    class="text-xs text-gray-400 py-2 text-center"
                  >
                    暂无配料信息
                  </div>
                  <div v-else class="space-y-1">
                    <RecipeNode
                      v-for="it in dishIngredients[dish.id]"
                      :key="it.id"
                      :name="it.ingredient_name"
                      :amount="it.amount"
                      :unit="it.unit"
                      :linked-version-id="it.linked_version_id"
                    />
                  </div>
                </div>
              </div>
            </div>
          </van-collapse-item>
        </van-collapse>
      </div>
    </div>

    <van-floating-bubble
      icon="plus"
      axis="xy"
      magnetic="x"
      @click="onAddFabClick"
    />

    <!-- Dish Dialog -->
    <van-popup
      v-model:show="showDishForm"
      position="bottom"
      round
      style="height: 80%"
      closeable
    >
      <div class="p-4 h-full flex flex-col">
        <h3 class="text-lg font-bold mb-4 text-center">
          {{ editingDish ? "编辑菜品" : "新增菜品" }}
        </h3>

        <div class="flex-1 overflow-y-auto space-y-3 px-1">
          <van-field
            v-model="form.name"
            label="名称"
            placeholder="请输入菜品名称"
            required
            :rules="[{ required: true }]"
          />
          <van-field v-model="form.code" label="编码" placeholder="可选" />
          <van-field
            v-model="form.price"
            label="价格"
            type="number"
            placeholder="0.0"
          />
          <van-field
            v-model="form.description"
            label="描述"
            type="textarea"
            rows="2"
            placeholder="菜品描述"
          />

          <div class="flex justify-between items-center mt-4 mb-2">
            <span class="font-bold text-sm">配料信息</span>
            <van-button
              size="mini"
              plain
              type="primary"
              @click="showIngredientSelector = true"
              >添加配料</van-button
            >
          </div>

          <div
            v-if="form.items.length === 0"
            class="text-center text-gray-400 text-xs py-4 bg-gray-50 rounded"
          >
            暂无配料
          </div>
          <div v-else class="space-y-2">
            <div
              v-for="(it, idx) in form.items"
              :key="idx"
              class="flex gap-2 items-center bg-gray-50 p-2 rounded"
            >
              <span class="flex-1 text-sm truncate">{{
                it.ingredient_name
              }}</span>
              <input
                v-model="it.amount"
                type="number"
                class="w-16 px-1 py-0.5 rounded border text-sm text-center"
              />
              <input
                v-model="it.unit"
                class="w-12 px-1 py-0.5 rounded border text-sm text-center"
              />
              <van-icon
                name="cross"
                class="text-red-500"
                @click="form.items.splice(idx, 1)"
              />
            </div>
          </div>
        </div>

        <div class="pt-4 mt-auto">
          <van-button
            block
            type="primary"
            :loading="formSaving"
            @click="saveDish"
            >保存</van-button
          >
        </div>
      </div>
    </van-popup>

    <!-- Ingredient Selector Dialog -->
    <van-popup
      v-model:show="showIngredientSelector"
      round
      position="bottom"
      style="height: 60%"
    >
      <div class="p-4 h-full flex flex-col">
        <van-search
          v-model="ingSearch"
          placeholder="搜索原材料"
          @search="loadIngredients"
        />
        <div class="flex-1 overflow-y-auto">
          <van-checkbox-group v-model="selectedIngIds">
            <van-cell-group :border="false">
              <van-cell
                v-for="ing in ingOptions"
                :key="ing.id"
                clickable
                :title="ing.name"
                :label="`库存:${ing.stock} ${ing.default_unit || ''}`"
                @click="toggleIng(ing.id)"
              >
                <template #right-icon>
                  <van-checkbox :name="ing.id" />
                </template>
              </van-cell>
            </van-cell-group>
          </van-checkbox-group>
        </div>
        <div class="pt-2">
          <van-button block type="primary" @click="confirmAddIngredients"
            >添加选中 ({{ selectedIngIds.length }})</van-button
          >
        </div>
      </div>
    </van-popup>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from "vue";
import { showToast, showConfirmDialog, showNotify } from "vant";
import api from "@/api";
import RecipeNode from "@/components/RecipeNode.vue";

// State
const loading = ref(false);
const tree = ref<any[]>([]);
const search = ref("");
const filteredData = ref<any[]>([]);
const activeControls = ref<string[]>([]);
const activeCats = reactive<Record<number, any[]>>({}); // Using object for multiple cuisines

// Expansion State
const expandedDishes = reactive(new Set<number>());
const dishIngredients = reactive<Record<number, any[]>>({});
const dishLoading = reactive(new Set<number>());

// Import
const pathCtrl = ref("");
const cuisineCtrl = ref("菜单");
const importing = ref(false);
const selectedFile = ref<File | null>(null);

// Dish Form
const showDishForm = ref(false);
const editingDish = ref<any>(null);
const currentCatId = ref<number | null>(null);
const formSaving = ref(false);
const form = reactive({
  name: "",
  code: "",
  price: "",
  description: "",
  items: [] as any[],
});

// Ingredient Selector
const showIngredientSelector = ref(false);
const ingSearch = ref("");
const ingOptions = ref<any[]>([]);
const selectedIngIds = ref<number[]>([]);

onMounted(() => {
  loadTree();
});

const loadTree = async () => {
  loading.value = true;
  try {
    const res = await api.get("/menu/tree");
    tree.value = res.data.data || [];
    // Initialize activeCats for all cuisines to ensure v-model works
    tree.value.forEach((cu: any) => {
      if (activeCats[cu.id] === undefined) {
        activeCats[cu.id] = [];
      }
    });
    filterTree();
  } catch (e) {
    showNotify({ type: "danger", message: "加载失败" });
  } finally {
    loading.value = false;
  }
};

const filterTree = () => {
  const q = search.value.trim();
  if (!q) {
    filteredData.value = tree.value;
    return;
  }
  const out: any[] = [];
  tree.value.forEach((cu: any) => {
    const cats: any[] = [];
    const cuCats = cu.categories || [];
    cuCats.forEach((cat: any) => {
      const dishes = (cat.dishes || []).filter((d: any) =>
        (d.name || "").includes(q)
      );
      if (dishes.length) {
        cats.push({ ...cat, dishes });
        // Auto expand
        if (!activeCats[cu.id]) activeCats[cu.id] = [];
        if (!activeCats[cu.id]!.includes(cat.id))
          activeCats[cu.id]!.push(cat.id);
      }
    });
    if (cats.length) {
      out.push({ ...cu, categories: cats });
    }
  });
  filteredData.value = out;
};

const toggleDish = async (dish: any) => {
  if (expandedDishes.has(dish.id)) {
    expandedDishes.delete(dish.id);
  } else {
    expandedDishes.add(dish.id);
    if (!dishIngredients[dish.id]) {
      await fetchDishIngredients(dish);
    }
  }
};

const fetchDishIngredients = async (dish: any) => {
  const versions = dish.versions || [];
  if (versions.length === 0) return;

  const active = versions.find((v: any) => v.active) || versions[0];
  if (!active) return;

  dishLoading.add(dish.id);
  try {
    const res = await api.get(`/menu/recipes/${active.id}/items`);
    dishIngredients[dish.id] = res.data.data || [];
  } catch (e) {
    showNotify({ type: "warning", message: "加载配料失败" });
  } finally {
    dishLoading.delete(dish.id);
  }
};

// Import
const onFileSelect = (file: any) => {
  selectedFile.value = file.file;
  pathCtrl.value = file.file.name;
};

const importFile = async () => {
  importing.value = true;
  const cuisine = cuisineCtrl.value.trim() || "默认";
  try {
    if (selectedFile.value) {
      const fd = new FormData();
      fd.append("file", selectedFile.value);
      fd.append("cuisine", cuisine);
      await api.post("/menu/import-upload", fd);
    } else if (pathCtrl.value) {
      await api.post("/menu/import-file", { path: pathCtrl.value, cuisine });
    } else {
      return showToast("请选择文件");
    }
    showToast("导入成功");
    await loadTree();
  } catch (e: any) {
    showNotify({ type: "danger", message: "导入失败: " + e.message });
  } finally {
    importing.value = false;
    selectedFile.value = null;
  }
};

// Dish Logic
const onAddFabClick = () => {
  if (tree.value.length && tree.value[0]?.categories?.length) {
    openDishDialog(null, tree.value[0].categories[0].id);
  } else {
    showToast("请先创建或导入分类");
  }
};

const openDishDialog = async (dish: any, catId: number) => {
  editingDish.value = dish;
  currentCatId.value = catId;

  // Reset form
  form.name = dish?.name || "";
  form.code = dish?.code || "";
  form.price = dish?.price || "";
  form.description = dish?.description || "";
  form.items = [];

  if (dish) {
    // Load existing items
    const versions = dish.versions || [];
    if (versions.length) {
      const active = versions.find((v: any) => v.active) || versions[0];
      try {
        const res = await api.get(`/menu/recipes/${active.id}/items`);
        let data: any[] = [];
        if (Array.isArray(res.data)) data = res.data;
        else if (res.data && Array.isArray(res.data.data)) data = res.data.data;

        form.items = data.map((e: any) => ({
          ingredient_name: e.ingredient_name,
          amount: e.amount,
          unit: e.unit,
        }));
      } catch (e) {
        console.error(e);
      }
    }
  }

  showDishForm.value = true;
};

const confirmDeleteDish = (dish: any) => {
  showConfirmDialog({
    title: "确认删除",
    message: `确定要删除 "${dish.name}" 吗？`,
  })
    .then(async () => {
      try {
        await api.delete(`/menu/dishes/${dish.id}`);
        showToast("已删除");
        loadTree();
      } catch (e) {
        showToast("删除失败");
      }
    })
    .catch(() => {});
};

const saveDish = async () => {
  if (!form.name) return showToast("请输入名称");
  formSaving.value = true;
  try {
    const payloadData = {
      name: form.name,
      code: form.code,
      price: parseFloat(form.price) || 0,
      description: form.description,
      category_id: currentCatId.value,
    };
    const itemsPayload = form.items.map((e) => ({
      name: e.ingredient_name,
      amount: parseFloat(e.amount) || 0,
      unit: e.unit,
    }));

    if (!editingDish.value) {
      // Create
      await api.post("/menu/dishes/create-with-items", {
        ...payloadData,
        items: itemsPayload,
      });
    } else {
      // Update info
      await api.put(`/menu/dishes/${editingDish.value.id}`, payloadData);
      // Update recipe items
      const versions = editingDish.value.versions || [];
      if (versions.length) {
        const active = versions.find((v: any) => v.active) || versions[0];
        await api.put(`/menu/recipes/${active.id}/items`, {
          items: itemsPayload,
        });
      }
    }
    showToast("保存成功");
    showDishForm.value = false;
    loadTree();
  } catch (e: any) {
    showNotify({ type: "danger", message: "保存失败: " + e.message });
  } finally {
    formSaving.value = false;
  }
};

// Ingredients Selector
const loadIngredients = async (val: string) => {
  try {
    const res = await api.get("/menu/ingredients", { params: { name: val } });
    ingOptions.value = res.data.data || [];
  } catch (e) {}
};

const toggleIng = (id: number) => {
  if (selectedIngIds.value.includes(id)) {
    selectedIngIds.value = selectedIngIds.value.filter((x) => x !== id);
  } else {
    selectedIngIds.value.push(id);
  }
};

const confirmAddIngredients = () => {
  const selected = ingOptions.value.filter((o) =>
    selectedIngIds.value.includes(o.id)
  );
  selected.forEach((s) => {
    // Avoid dups
    if (!form.items.find((x) => x.ingredient_name === s.name)) {
      form.items.push({
        ingredient_name: s.name,
        amount: 1,
        unit: s.default_unit || "g",
      });
    }
  });
  showIngredientSelector.value = false;
  selectedIngIds.value = [];
  ingOptions.value = [];
  ingSearch.value = "";
};

// Watcher for selector opening to load initial list
import { watch } from "vue";
watch(showIngredientSelector, (v) => {
  if (v && ingOptions.value.length === 0) loadIngredients("");
});
</script>
