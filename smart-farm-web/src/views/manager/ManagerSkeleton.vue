<template>
  <div class="shell">
    <div class="topbar">
      <div>
        <div class="topbar-title">A区 · 大棚1号</div>
        <div class="topbar-sub">区域负责人 · 李明 · 西红柿 · 第42天</div>
      </div>
      <button class="logout-btn" @click="$router.push('/')">退出</button>
    </div>

    <div class="layout">
      <div class="sidebar">
        <div class="nav-item active">区域总览</div>
        <div class="nav-item">任务管理</div>
        <div class="nav-item">记录审核</div>
        <div class="nav-item">生长时间轴</div>
        <div class="nav-item">异常处理</div>
        <div class="nav-item">周报生成</div>
      </div>

      <div class="main">
        <router-view></router-view>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* 样式复用管理员的，但修改高亮颜色 */
.shell { height: 100vh; display: flex; flex-direction: column; }
.topbar { background: #fff; border-bottom: 0.5px solid #eee; padding: 12px 16px; display: flex; justify-content: space-between; align-items: center;}
.topbar-title { font-size: 14px; font-weight: 500; }
.topbar-sub { font-size: 12px; color: #888; }
.layout { display: flex; flex: 1; overflow: hidden; }
.sidebar { width: 110px; background: #fff; border-right: 0.5px solid #eee; padding: 12px 0; }
.nav-item { padding: 8px 12px; font-size: 12px; color: #666; cursor: pointer; }
.nav-item.active {
  background: #f4f4fb;
  color: #534AB7; /* 负责人主题色 */
  font-weight: 500;
  border-left: 2px solid #534AB7;
}
.main { flex: 1; padding: 14px; overflow-y: auto; background: #fdfdfd; }
.logout-btn { font-size: 11px; padding: 3px 8px; cursor: pointer; border: 0.5px solid #ddd; background: #fff; border-radius: 4px; }
</style>