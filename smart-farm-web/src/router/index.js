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
        { path: '', component: () => import('../views/admin/AdminHome.vue') }
      ]
    },
    {
      path: '/manager',
      component: () => import('../views/manager/ManagerSkeleton.vue'),
      children: [
        { path: '', component: () => import('../views/manager/ManagerHome.vue') }
      ]
    },
    {
      path: '/worker',
      component: () => import('../views/worker/WorkerSkeleton.vue'),
      children: [
        { path: '', component: () => import('../views/worker/WorkerHome.vue') }
      ]
    }
  ]
})

export default router