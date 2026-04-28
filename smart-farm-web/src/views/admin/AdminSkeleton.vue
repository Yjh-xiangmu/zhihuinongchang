<template>
  <div class="shell">
    <div class="topbar">
      <div class="topbar-left">
        <div class="logo-dot"></div>
        <div>
          <div class="topbar-title">智慧农场管理系统</div>
          <div class="topbar-sub">农场管理员 · {{ userInfo.realName }}</div>
        </div>
      </div>
      <button class="logout-btn" @click="logout">退出系统</button>
    </div>
    <div class="layout">
      <div class="sidebar">
        <router-link class="nav-item" to="/admin/dashboard" active-class="active">全场看板</router-link>
        <router-link class="nav-item" to="/admin/zones"     active-class="active">种植区域</router-link>
        <router-link class="nav-item" to="/admin/alerts"    active-class="active">预警中心</router-link>
        <router-link class="nav-item" to="/admin/report"    active-class="active">产量报告</router-link>
        <router-link class="nav-item" to="/admin/trace"     active-class="active">追溯查询</router-link>
        <router-link class="nav-item" to="/admin/accounts"  active-class="active">账号管理</router-link>
        <div class="nav-divider"></div>
        <router-link class="nav-item nav-ai" to="/admin/ai" active-class="active">
          <span class="ai-dot">✦</span> AI 助手
        </router-link>
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
.logout-btn { font-size:12px; padding:6px 14px; cursor:pointer; border:1px solid var(--color-border); background:#fff; color:var(--color-text-regular); border-radius:var(--radius-md); transition:var(--transition); }
.logout-btn:hover { background:var(--color-bg-hover); }
.layout { display:flex; flex:1; overflow:hidden; }
.sidebar { width:130px; background:#fff; padding:12px 8px; flex-shrink:0; border-right:1px solid var(--color-border); display:flex; flex-direction:column; gap:2px; }
.nav-item { display:block; padding:10px 14px; font-size:13px; color:var(--color-text-regular); cursor:pointer; border-radius:var(--radius-md); text-decoration:none; transition:var(--transition); }
.nav-item:hover { background:var(--color-bg-hover); color:var(--color-text-primary); }
.nav-item.active { background:#e8f5f0; color:var(--color-primary); font-weight:600; }
.nav-divider { height:1px; background:var(--color-border); margin:6px 8px; }
.nav-ai { display:flex; align-items:center; gap:6px; }
.nav-ai.active { background:linear-gradient(135deg,#f0eeff,#e8f5f0); color:#534AB7; }
.ai-dot { font-size:10px; color:#534AB7; }
.main { flex:1; padding:20px 24px; overflow-y:auto; }
</style>