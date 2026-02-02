<template>
  <div
    class="pb-20 bg-gray-50 dark:bg-[#0C0A09] min-h-screen transition-colors duration-300"
  >
    <van-nav-bar
      title="商品销售分析"
      left-arrow
      @click-left="$router.back()"
      fixed
      placeholder
      class="bg-white/80 dark:bg-[#1C1917]/80 backdrop-blur-md dark:text-white"
    />

    <!-- Controls -->
    <div class="p-3 bg-white dark:bg-[#1C1917] mb-2 shadow-sm border-b border-gray-100 dark:border-gray-800">
      <div class="flex justify-between items-center mb-2">
        <span class="text-xs text-gray-500 dark:text-gray-400">{{ statusText }}</span>
        <span class="text-xs font-bold text-gray-700 dark:text-gray-200"
          >销售总额: ¥{{ fmtCurrency(salesTotal) }}</span
        >
      </div>

      <div class="flex gap-2 items-center mb-2">
        <van-button
          size="mini"
          type="primary"
          variant="text"
          @click="showControls = !showControls"
        >
          {{ showControls ? "隐藏操作" : "显示操作" }}
        </van-button>
        <div class="flex-1"></div>
        <van-button
          size="mini"
          plain
          @click="onlyIngredients = !onlyIngredients"
        >
          {{ onlyIngredients ? "显示销售商品" : "仅显示原材料" }}
        </van-button>
      </div>

      <transition name="van-fade">
        <div v-if="showControls" class="bg-gray-50 dark:bg-gray-800 p-3 rounded-lg space-y-3">
          <div class="flex items-center gap-2">
            <van-dropdown-menu class="h-8 flex-1">
              <van-dropdown-item
                v-model="mode"
                :options="[
                  { text: '按具体日期', value: 0 },
                  { text: '按起止日期', value: 3 },
                ]"
              />
            </van-dropdown-menu>
          </div>

          <van-search
            v-model="searchText"
            placeholder="搜索编号或名称"
            @update:model-value="onSearch"
            background="transparent"
            class="px-0 py-0"
          />

          <div v-if="mode === 0" class="flex gap-2">
            <div
              class="flex-1 h-8 px-2 flex items-center bg-white dark:bg-[#1C1917] rounded border border-gray-200 dark:border-gray-700 text-sm text-gray-600 dark:text-gray-300"
              @click="showCalendar = true"
            >
              {{ chooseDate || "查询日期(YYYY-MM-DD)" }}
            </div>
          </div>
          <div v-else class="flex gap-2">
            <div
              class="flex-1 h-8 px-2 flex items-center bg-white dark:bg-[#1C1917] rounded border border-gray-200 dark:border-gray-700 text-sm text-gray-600 dark:text-gray-300 truncate"
              @click="showRangeCalendar = true"
            >
              {{
                startDate && endDate ? `${startDate} - ${endDate}` : "选择范围"
              }}
            </div>
          </div>

          <div class="flex gap-2">
            <van-button
              size="small"
              type="primary"
              plain
              block
              class="flex-1"
              @click="loadData"
              :loading="loading"
              >查询</van-button
            >
            <van-button size="small" plain block class="flex-1" @click="reset"
              >重置</van-button
            >
          </div>

          <van-collapse v-model="filterCollapse" :border="false">
            <van-collapse-item title="批量筛选" name="1">
              <van-field
                v-model="filterText"
                rows="3"
                type="textarea"
                placeholder="例：\n金枪鱼色拉\n牛肉饭"
                class="bg-white rounded border border-gray-200 p-2"
              />
              <div class="flex gap-2 mt-2">
                <van-button
                  size="small"
                  type="primary"
                  plain
                  block
                  @click="applyFilter"
                  >应用筛选</van-button
                >
                <van-button size="small" plain block @click="clearFilter"
                  >清空</van-button
                >
              </div>
            </van-collapse-item>
          </van-collapse>

          <div class="flex gap-2 items-center">
            <van-field
              v-model="ingSearchText"
              placeholder="搜索原材料名称或单位"
              class="bg-white rounded border border-gray-200 py-1 px-2 flex-1"
              :border="false"
              @update:model-value="onIngSearch"
            />
            <van-button size="small" plain @click="clearIngSearch"
              >清空</van-button
            >
          </div>

          <div v-if="errorText" class="text-red-500 text-xs">
            {{ errorText }}
          </div>
        </div>
      </transition>
    </div>

    <!-- Content -->
    <div class="px-3">
      <van-loading v-if="loading" vertical class="py-10">加载中...</van-loading>
      <van-empty
        v-else-if="viewItems.length === 0 && !loading"
        description="暂无数据"
      />

      <div v-else class="space-y-3">
        <!-- Product List -->
        <template v-if="!onlyIngredients">
          <div
            v-for="(item, idx) in viewItems"
            :key="idx"
            class="bg-white dark:bg-[#1C1917] rounded-lg shadow-sm p-3 border border-gray-100 dark:border-gray-800"
          >
            <div class="flex justify-between items-start mb-2">
              <div class="font-bold text-gray-800 dark:text-gray-100">{{ item.product_name }}</div>
              <div class="text-xs bg-blue-50 text-blue-600 px-2 py-1 rounded">
                销量: {{ item.sales_number }}
              </div>
            </div>

            <div class="text-xs text-gray-500 dark:text-gray-400 mb-2 space-y-1">
              <div>编号: {{ item.product_id }} | 价格: ¥{{ item.price }}</div>
              <div>日均: {{ item.avg_sales_per_day }}</div>
            </div>

            <div class="flex justify-end">
              <span
                class="text-xs text-blue-500 dark:text-blue-400 cursor-pointer flex items-center"
                @click="toggleExpand(idx)"
              >
                {{ expanded.has(idx) ? "收起" : "查看详情" }}
                <van-icon
                  :name="expanded.has(idx) ? 'arrow-up' : 'arrow-down'"
                  class="ml-1"
                />
              </span>
            </div>

            <transition name="van-slide-down">
              <div
                v-if="expanded.has(idx)"
                class="mt-2 pt-2 border-t border-gray-100 dark:border-gray-800 text-xs text-gray-600 dark:text-gray-300 bg-gray-50/50 dark:bg-gray-800/50 rounded p-2"
              >
                <div class="font-bold mb-1">菜谱制作方法</div>
                <div
                  v-for="(line, li) in getRecipeLines(item)"
                  :key="li"
                  class="pl-2 mb-1"
                >
                  - {{ line }}
                </div>

                <div class="font-bold mt-2 mb-1">关键指标</div>
                <div class="grid grid-cols-2 gap-x-2 gap-y-1 pl-2 mb-2">
                  <template v-for="(v, k) in item.details || {}" :key="k">
                    <span class="text-gray-400">{{ k }}:</span>
                    <span>{{ v }}</span>
                  </template>
                </div>

                <div v-if="getTrace(item).length" class="mt-2">
                  <div class="font-bold mb-1">配方分解步骤</div>
                  <div
                    v-for="(step, si) in getTrace(item)"
                    :key="si"
                    class="pl-2 mb-1 flex items-start gap-1"
                  >
                    <span
                      class="bg-blue-100 text-blue-700 px-1 rounded text-[10px]"
                      >{{ step.depth }}</span
                    >
                    <span>
                      源: {{ step.source?.name }} {{ step.source?.amount
                      }}{{ step.source?.unit }} → 派生:
                      {{ step.derived?.name }} {{ step.derived?.amount
                      }}{{ step.derived?.unit }}
                    </span>
                  </div>
                </div>
              </div>
            </transition>
          </div>
        </template>

        <!-- Ingredient Aggregation -->
        <div class="bg-white dark:bg-[#1C1917] rounded-lg shadow-sm p-3 border border-gray-100 dark:border-gray-800">
          <div class="font-bold text-gray-800 dark:text-gray-100 mb-3 flex items-center gap-2">
            <van-icon name="chart-trending-o" class="text-green-600 dark:text-green-400" />
            原材料使用统计 (基于当前筛选)
          </div>

          <van-empty
            v-if="ingAggView.length === 0"
            description="暂无原材料数据"
            image-size="60"
          />
          <div v-else class="space-y-2">
            <div
              v-for="(ing, ii) in ingAggView"
              :key="ii"
              class="flex justify-between items-center p-2 bg-gray-50 dark:bg-gray-800 rounded text-sm"
            >
              <span class="font-medium text-gray-700 dark:text-gray-200">{{ ing.name }}</span>
              <span class="text-gray-500 dark:text-gray-400">
                {{ ing.total }}
                <span class="text-xs bg-gray-200 px-1 rounded">{{
                  ing.unit
                }}</span>
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Calendars -->
    <van-calendar
      v-model:show="showCalendar"
      @confirm="onConfirmDate"
      :min-date="new Date(2020, 0, 1)"
    />
    <van-calendar
      v-model:show="showRangeCalendar"
      type="range"
      @confirm="onConfirmRange"
      :min-date="new Date(2020, 0, 1)"
      :max-date="new Date(2030, 11, 31)"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive } from "vue";
import { showToast } from "vant";
import api from "@/api";

// State
const loading = ref(false);
const items = ref<any[]>([]);
const viewItems = ref<any[]>([]);
const ingAgg = ref<any[]>([]);
const ingAggView = ref<any[]>([]);
const statusText = ref("");
const errorText = ref("");
const salesTotal = ref(0.0);

const showControls = ref(true);
const mode = ref(0);
const searchText = ref("");
const chooseDate = ref("");
const startDate = ref("");
const endDate = ref("");

const filterCollapse = ref([]);
const filterText = ref("");
const onlyIngredients = ref(false);

const ingSearchText = ref("");
const expanded = reactive(new Set<number>());

// Calendar
const showCalendar = ref(false);
const showRangeCalendar = ref(false);

// Caches
const dishVersionMap = new Map<string, number>();
const recipeItemsCache = new Map<number, any[]>();
const recipeItemsCacheTs = new Map<number, number>();
let dishMapUpdatedAt = 0;

// Methods
const loadData = async () => {
  loading.value = true;
  errorText.value = "";
  try {
    const payload: any = { seldate: mode.value };
    if (mode.value === 0) {
      if (!chooseDate.value) throw new Error("请选择查询日期");
      payload.chooseData = chooseDate.value.replace(/-/g, "");
    } else {
      if (!startDate.value || !endDate.value) throw new Error("请选择起止日期");
      payload.custom_start_date = startDate.value.replace(/-/g, "");
      payload.custom_end_date = endDate.value.replace(/-/g, "");
    }

    const res = await api.post("/products", payload);
    const raw = res.data;

    // Parse Items
    let parsed: any[] = [];
    if (Array.isArray(raw)) parsed = raw;
    else if (raw.data && Array.isArray(raw.data)) parsed = raw.data;
    else if (raw.data?.items && Array.isArray(raw.data.items))
      parsed = raw.data.items;
    else if (raw.items && Array.isArray(raw.items)) parsed = raw.items;

    items.value = parsed;
    viewItems.value = [...parsed];
    statusText.value = `共 ${viewItems.value.length} 条记录`;

    // Total Price
    let tp = String(raw.total_price_num || raw.data?.total_price_num || "");
    let tpVal = parseFloat(tp) || 0;
    if (tpVal > 0) salesTotal.value = tpVal;
    else computeSalesTotal();

    invalidateRecipeCache();
    await computeIngredientsFromMenu();
  } catch (e: any) {
    errorText.value = e.message || "加载失败";
    items.value = [];
    viewItems.value = [];
    ingAgg.value = [];
    statusText.value = "";
    salesTotal.value = 0;
  } finally {
    loading.value = false;
  }
};

const computeSalesTotal = () => {
  let sum = 0;
  viewItems.value.forEach((m) => {
    let v = 0;
    const candidates = [m["总销售金额"], m.total_sales_amount, m.sales_total];
    for (const c of candidates) {
      const n = parseNumber(c);
      if (n > 0) {
        v = n;
        break;
      }
    }
    if (v <= 0) {
      const price = parseNumber(m.price);
      const qty = parseNumber(m.sales_number);
      if (price > 0 && qty > 0) v = price * qty;
    }
    sum += v;
  });
  salesTotal.value = sum;
};

const computeIngredientsFromMenu = async () => {
  const agg: Record<string, number> = {};
  try {
    await ensureDishVersionMap();
    for (const p of viewItems.value) {
      const sales = parseNumber(p.sales_number);
      if (sales <= 0) continue;
      const dishName = String(p.product_name || "");
      const items = await getRecipeItemsByDishName(dishName);
      for (const it of items) {
        const name = String(it.ingredient_name || it.name || "");
        const unit = String(it.unit || "");
        const amt = parseNumber(it.amount);
        if (!name || !unit || amt <= 0) continue;
        const key = `${name}|${unit}`;
        agg[key] = (agg[key] || 0) + amt * sales;
      }
    }
    ingAgg.value = Object.entries(agg).map(([k, v]) => {
      const [name, unit] = k.split("|");
      return { name, unit, total: parseFloat(v.toFixed(2)) };
    });
    applyIngSearch();
  } catch (e) {
    console.warn("Fallback to local recipe", e);
    computeIngredientsLocalFallback();
  }
};

const computeIngredientsLocalFallback = () => {
  const agg: Record<string, number> = {};
  for (const p of viewItems.value) {
    const sales = parseNumber(p.sales_number);
    if (sales <= 0) continue;
    const recipe = p.recipe || {};
    const ings =
      (recipe.ingredients_expanded?.length
        ? recipe.ingredients_expanded
        : recipe.ingredients) || [];
    for (const ing of ings) {
      const name = String(ing.name || "");
      const unit = String(ing.unit || "");
      const amt = parseNumber(ing.amount);
      if (!name || !unit || amt <= 0) continue;
      const key = `${name}|${unit}`;
      agg[key] = (agg[key] || 0) + amt * sales;
    }
  }
  ingAgg.value = Object.entries(agg).map(([k, v]) => {
    const [name, unit] = k.split("|");
    return { name, unit, total: parseFloat(v.toFixed(2)) };
  });
  applyIngSearch();
};

// Helpers
const parseNumber = (v: any) => {
  if (v == null) return 0;
  const s = String(v).replace(/,/g, "").trim();
  return parseFloat(s) || 0;
};

const fmtCurrency = (v: number) => {
  return v.toLocaleString("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
};

const ensureDishVersionMap = async () => {
  if (dishVersionMap.size > 0 && Date.now() - dishMapUpdatedAt < 5 * 60 * 1000)
    return;
  const res = await api.get("/menu/tree");
  const data = res.data.data || [];
  dishVersionMap.clear();
  data.forEach((cu: any) => {
    (cu.categories || []).forEach((cat: any) => {
      (cat.dishes || []).forEach((d: any) => {
        const active =
          (d.versions || []).find((v: any) => v.active) || d.versions?.[0];
        if (active) dishVersionMap.set(d.name, active.id);
      });
    });
  });
  dishMapUpdatedAt = Date.now();
};

const getRecipeItemsByDishName = async (name: string) => {
  const vid = dishVersionMap.get(name);
  if (!vid) return [];
  if (recipeItemsCache.has(vid)) {
    const ts = recipeItemsCacheTs.get(vid) || 0;
    if (Date.now() - ts < 60 * 1000) return recipeItemsCache.get(vid) || [];
  }
  const res = await api.get(`/menu/recipes/${vid}/items`);
  const items = res.data.data || [];
  recipeItemsCache.set(vid, items);
  recipeItemsCacheTs.set(vid, Date.now());
  return items;
};

const invalidateRecipeCache = () => {
  recipeItemsCache.clear();
  recipeItemsCacheTs.clear();
};

// Search & Filter
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
    statusText.value = `共 ${viewItems.value.length} 条记录`;
    expanded.clear();
    invalidateRecipeCache();
    computeIngredientsFromMenu();
    computeSalesTotal();
  }, 300);
};

const applyFilter = () => {
  const lines = filterText.value
    .split("\n")
    .map((s) => s.trim())
    .filter((s) => s);
  if (lines.length === 0) {
    viewItems.value = [...items.value];
  } else {
    viewItems.value = items.value.filter((it) => {
      const nm = String(it.product_name || "");
      return lines.some((l) => nm.includes(l));
    });
  }
  statusText.value = `共 ${viewItems.value.length} 条记录`;
  expanded.clear();
  invalidateRecipeCache();
  computeIngredientsFromMenu();
  computeSalesTotal();
  showToast(`已筛选 ${viewItems.value.length} 条`);
};

const clearFilter = () => {
  filterText.value = "";
  applyFilter();
};

let ingSearchTimer: any;
const onIngSearch = (_val: string) => {
  clearTimeout(ingSearchTimer);
  ingSearchTimer = setTimeout(applyIngSearch, 300);
};

const applyIngSearch = () => {
  const q = ingSearchText.value.trim().toLowerCase();
  if (!q) {
    ingAggView.value = [...ingAgg.value];
  } else {
    ingAggView.value = ingAgg.value.filter(
      (m) =>
        m.name.toLowerCase().includes(q) || m.unit.toLowerCase().includes(q)
    );
  }
};

const clearIngSearch = () => {
  ingSearchText.value = "";
  applyIngSearch();
};

const reset = () => {
  items.value = [];
  viewItems.value = [];
  ingAgg.value = [];
  statusText.value = "";
  errorText.value = "";
  salesTotal.value = 0;
  expanded.clear();
  chooseDate.value = "";
  startDate.value = "";
  endDate.value = "";
  searchText.value = "";
  filterText.value = "";
  ingSearchText.value = "";
};

const toggleExpand = (idx: number) => {
  if (expanded.has(idx)) expanded.delete(idx);
  else expanded.add(idx);
};

const getRecipeLines = (item: any) => {
  return item.recipe?.lines || [];
};

const getTrace = (item: any) => {
  return item.recipe?.trace || [];
};

// Calendar
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
</script>
