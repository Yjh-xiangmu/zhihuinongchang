<template>
  <div class="shell">
    <div class="topbar">
      <div>
        <div class="topbar-title">智慧农场 · 工作端</div>
        <div class="topbar-sub">员工 · 小王 · A区大棚1号</div>
      </div>
      <button class="logout-btn" @click="$router.push('/')">退出</button>
    </div>

    <div class="layout">
      <div class="sidebar">
        <div class="nav-item active">今日任务</div>
        <div class="nav-item">生长记录</div>
        <div class="nav-item">异常上报</div>
        <div class="nav-item">个人消息</div>
      </div>

      <div class="main">
        <router-view></router-view>
      </div>
    </div>
  </div>
</template>

<style scoped>
.shell { height: 100vh; display: flex; flex-direction: column; }
.topbar { background: #fff; border-bottom: 0.5px solid #eee; padding: 10px 14px; display: flex; justify-content: space-between; align-items: center; }
.topbar-title { font-size: 14px; font-weight: 500; }
.topbar-sub { font-size: 11px; color: #666; }
.layout { display: flex; flex: 1; }
.sidebar { width: 120px; background: #fff; border-right: 0.5px solid #eee; padding: 12px 0; }
.nav-item { padding: 10px 16px; font-size: 12px; color: #5f6368; cursor: pointer; }
.nav-item.active {
  background: #e1f5ee;
  color: #1D9E75;
  font-weight: 500;
  border-left: 2px solid #1D9E75;
}
.main { flex: 1; padding: 16px; background: #fdfdfd; overflow-y: auto; }
.logout-btn { font-size: 11px; padding: 3px 8px; cursor: pointer; border: 0.5px solid #ddd; background: #fff; border-radius: 4px; }
</style>