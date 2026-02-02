import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue'),
    meta: { title: '首页' }
  },
  {
    path: '/settings',
    name: 'Settings',
    component: () => import('@/views/Settings.vue'),
    meta: { title: '设置' }
  },
  {
    path: '/ledger',
    name: 'Ledger',
    component: () => import('@/views/Ledger.vue'),
    meta: { title: '台账生产' }
  },
  {
    path: '/revenue',
    name: 'Revenue',
    component: () => import('@/views/Revenue.vue'),
    meta: { title: '营业额' }
  },
  {
    path: '/borrow',
    name: 'Borrow',
    component: () => import('@/views/Borrow.vue'),
    meta: { title: '借货统计' }
  },
  {
    path: '/products',
    name: 'Products',
    component: () => import('@/views/Products.vue'),
    meta: { title: '商品销售分析' }
  },
  {
    path: '/order',
    name: 'Order',
    component: () => import('@/views/Order.vue'),
    meta: { title: '订货管理' }
  },
  {
    path: '/attendance',
    name: 'Attendance',
    component: () => import('@/views/Attendance.vue'),
    meta: { title: '员工考勤' }
  },
  {
    path: '/sales',
    name: 'Sales',
    component: () => import('@/views/Sales.vue'),
    meta: { title: '周销售计划' }
  },
  {
    path: '/weekly',
    name: 'Weekly',
    component: () => import('@/views/Weekly.vue'),
    meta: { title: '周排班查询' }
  },
  {
    path: '/daily',
    name: 'Daily',
    component: () => import('@/views/Daily.vue'),
    meta: { title: '当日排班' }
  },
  {
    path: '/schedule-ai',
    name: 'ScheduleAI',
    component: () => import('@/views/ScheduleAI.vue'),
    meta: { title: '报班识别助手' }
  },
  {
    path: '/menu',
    name: 'Menu',
    component: () => import('@/views/Menu.vue'),
    meta: { title: '菜单管理' }
  },
  {
    path: '/menu/ingredient',
    name: 'Ingredient',
    component: () => import('@/views/Ingredient.vue'),
    meta: { title: '配料管理' }
  },
  {
    path: '/nutrition',
    name: 'Nutrition',
    component: () => import('@/views/Nutrition.vue'),
    meta: { title: '营养数据管理' }
  },
  {
    path: '/reminder',
    name: 'VoiceReminder',
    component: () => import('@/views/VoiceReminder.vue'),
    meta: { title: '语音提醒' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, _from, next) => {
  document.title = `${to.meta.title} - 萨利亚管理系统` || '萨利亚管理系统'
  next()
})

export default router
