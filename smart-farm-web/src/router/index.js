import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../views/login/LoginView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'login',
      component: LoginView
    },
    {
      path: '/admin',
      component: () => import('../views/admin/AdminSkeleton.vue'),
      children: [
        { path: '',        redirect: '/admin/dashboard' },
        { path: 'dashboard', component: () => import('../views/admin/AdminHome.vue') },
        { path: 'zones',     component: () => import('../views/admin/ZoneManage.vue') },
        { path: 'alerts',    component: () => import('../views/admin/AlertCenter.vue') },
        { path: 'report',    component: () => import('../views/admin/YieldReport.vue') },
        { path: 'trace',     component: () => import('../views/admin/TraceQuery.vue') },
        { path: 'accounts',  component: () => import('../views/admin/AccountManage.vue') },
        { path: 'ai', component: () => import('../views/common/AiAssistant.vue') },
      ]
    },
    {
      path: '/manager',
      component: () => import('../views/manager/ManagerSkeleton.vue'),
      children: [
        { path: '',        redirect: '/manager/home' },
        { path: 'home',    component: () => import('../views/manager/ManagerHome.vue') },
        { path: 'tasks',   component: () => import('../views/manager/TaskManage.vue') },
        { path: 'audit',   component: () => import('../views/manager/RecordAudit.vue') },
        { path: 'timeline',component: () => import('../views/manager/GrowthTimeline.vue') },
        { path: 'anomaly', component: () => import('../views/manager/AnomalyHandle.vue') },
        { path: 'report',  component: () => import('../views/manager/WeeklyReport.vue') },
        { path: 'ai', component: () => import('../views/common/AiAssistant.vue') },
      ]
    },
    {
      path: '/worker',
      component: () => import('../views/worker/WorkerSkeleton.vue'),
      children: [
        { path: '',        redirect: '/worker/tasks' },
        { path: 'tasks',   component: () => import('../views/worker/WorkerHome.vue') },
        { path: 'records', component: () => import('../views/worker/MyRecords.vue') },
        { path: 'anomaly', component: () => import('../views/worker/ReportAnomaly.vue') },
        { path: 'messages',component: () => import('../views/worker/MyMessages.vue') },
        { path: 'ai', component: () => import('../views/common/AiAssistant.vue') },
      ]
    }
  ]
})

// 路由守卫：未登录跳回首页
router.beforeEach((to) => {
  if (to.path !== '/') {
    const user = localStorage.getItem('userInfo')
    if (!user) return '/'
  }
})

export default router