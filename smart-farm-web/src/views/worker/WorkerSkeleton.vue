<template>
  <div class="shell">
    <div class="topbar">
      <div class="topbar-left">
        <div class="logo-dot"></div>
        <div>
          <div class="topbar-title">智慧农场 · 工作端</div>
          <div class="topbar-sub">员工 · {{ userInfo.realName }}</div>
        </div>
      </div>
      <button class="logout-btn" @click="logout">退出</button>
    </div>
    <div class="layout">
      <div class="sidebar">
        <router-link class="nav-item" to="/worker/tasks"    active-class="active">今日任务</router-link>
        <router-link class="nav-item" to="/worker/records"  active-class="active">我的记录</router-link>
        <router-link class="nav-item" to="/worker/anomaly"  active-class="active">上报异常</router-link>
        <router-link class="nav-item" to="/worker/messages" active-class="active">消息通知</router-link>
      </div>
      <div class="main">
        <router-view></router-view>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
const router = useRouter()
const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
function logout() {
  localStorage.removeItem('userInfo')
  router.push('/')
}
</script>

<style scoped>
.shell { height:100vh; display:flex; flex-direction:column; overflow:hidden; background:var(--color-bg-body); }
.topbar { background:#fff; padding:12px 24px; display:flex; align-items:center; justify-content:space-between; box-shadow:0 1px 4px rgba(0,0,0,0.06); z-index:10; flex-shrink:0; }
.topbar-left { display:flex; align-items:center; gap:12px; }
.logo-dot { width:32px; height:32px; background:var(--color-primary); border-radius:8px; flex-shrink:0; }
.topbar-title { font-size:15px; font-weight:600; color:var(--color-text-primary); }
.topbar-sub { font-size:12px; color:var(--color-text-muted); }
.logout-btn { font-size:12px; padding:6px 14px; cursor:pointer; border:1px solid var(--color-border); background:#fff; color:var(--color-text-regular); border-radius:var(--radius-md); }
.layout { display:flex; flex:1; overflow:hidden; }
.sidebar { width:110px; background:#fff; padding:12px 8px; flex-shrink:0; border-right:1px solid var(--color-border); display:flex; flex-direction:column; gap:2px; }
.nav-item { display:block; padding:10px 14px; font-size:13px; color:var(--color-text-regular); cursor:pointer; border-radius:var(--radius-md); text-decoration:none; transition:var(--transition); }
.nav-item:hover { background:var(--color-bg-hover); }
.nav-item.active { background:#e8f5f0; color:var(--color-primary); font-weight:600; }
.main { flex:1; padding:20px 24px; overflow-y:auto; }
</style>