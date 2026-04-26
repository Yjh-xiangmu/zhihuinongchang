<template>
  <div class="shell">
    <div class="topbar">
      <div class="topbar-left">
        <div class="topbar-title">智慧农场管理系统</div>
        <div class="topbar-sub">农场管理员 · 王建国</div>
      </div>
      <button class="logout-btn" @click="$router.push('/')">退出系统</button>
    </div>
    <div class="layout">
      <div class="sidebar">
        <div class="nav-item active">全场看板</div>
        <div class="nav-item">种植区域</div>
        <div class="nav-item">预警中心</div>
        <div class="nav-item">产量报告</div>
        <div class="nav-item">追溯查询</div>
        <div class="nav-item">账号管理</div>
        <div class="nav-item">AI 建议</div>
      </div>
      <div class="main">
        <router-view></router-view>
      </div>
    </div>
  </div>
</template>

<style scoped>
.shell { height: 100vh; background: var(--color-bg-body); display: flex; flex-direction: column; overflow: hidden; }

.topbar {
  background: var(--color-bg-surface);
  padding: 16px 24px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: var(--shadow-sm);
  z-index: 10;
}
.topbar-left { display: flex; align-items: baseline; gap: 12px; }
.topbar-title { font-size: 16px; font-weight: 600; color: var(--color-text-primary); letter-spacing: 0.5px; }
.topbar-sub { font-size: 12px; color: var(--color-text-muted); }

.logout-btn {
  font-size: 13px;
  padding: 6px 14px;
  cursor: pointer;
  border: 1px solid var(--color-border);
  background: var(--color-bg-surface);
  color: var(--color-text-regular);
  border-radius: var(--radius-md);
  transition: var(--transition);
}
.logout-btn:hover { background: var(--color-bg-hover); color: var(--color-text-primary); }

.layout { display: flex; flex: 1; overflow: hidden; }

.sidebar {
  width: 140px;
  background: var(--color-bg-surface);
  padding: 16px 8px;
  flex-shrink: 0;
  box-shadow: var(--shadow-sm);
  z-index: 5;
}
.nav-item {
  padding: 12px 16px;
  font-size: 13px;
  color: var(--color-text-regular);
  cursor: pointer;
  border-radius: var(--radius-md);
  margin-bottom: 4px;
  transition: var(--transition);
}
.nav-item:hover { background: var(--color-bg-hover); color: var(--color-text-primary); }
.nav-item.active {
  background: #e8f5f0;
  color: var(--color-primary);
  font-weight: 600;
}

.main { flex: 1; padding: 24px; overflow-y: auto; }
</style>