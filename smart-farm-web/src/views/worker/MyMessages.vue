<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">消息通知</div>
        <div class="page-sub">任务提醒、审核结果等系统消息</div>
      </div>
      <button v-if="unread > 0" class="btn-readall" @click="markAllRead">全部标记已读（{{ unread }}）</button>
    </div>

    <div class="card">
      <div v-if="loading" class="empty-tip">加载中...</div>
      <div v-else-if="notifications.length===0" class="empty-tip">暂无消息</div>
      <div
        v-for="n in notifications"
        :key="n.id"
        :class="['notif-row', { unread: n.isRead===0 }]"
        @click="markRead(n)"
      >
        <div :class="['notif-icon', typeColor(n.type)]">{{ typeIcon(n.type) }}</div>
        <div class="notif-body">
          <div class="notif-title">
            {{ n.title }}
            <span v-if="n.isRead===0" class="unread-dot"></span>
          </div>
          <div class="notif-content">{{ n.content }}</div>
          <div class="notif-time">{{ fmtDT(n.createTime) }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { notificationApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const notifications = ref([])
const loading = ref(false)

const unread = computed(() => notifications.value.filter(n => n.isRead === 0).length)

onMounted(async () => {
  loading.value = true
  try {
    const res = await notificationApi.list(userInfo.id)
    if (res.data.code === 200) notifications.value = res.data.data || []
  } finally { loading.value = false }
})

async function markRead(n) {
  if (n.isRead === 1) return
  await notificationApi.markRead(n.id)
  n.isRead = 1
}

async function markAllRead() {
  await notificationApi.markAllRead(userInfo.id)
  notifications.value.forEach(n => n.isRead = 1)
}

const typeIcon = t => ({ AUDIT_PASS: '✅', AUDIT_REJECT: '❌', TASK_TIMEOUT: '⏰', TASK_NEW: '📋', ANOMALY: '🔔' }[t] || '📩')
const typeColor = t => ({ AUDIT_PASS: 'ic-green', AUDIT_REJECT: 'ic-red', TASK_TIMEOUT: 'ic-orange', TASK_NEW: 'ic-blue', ANOMALY: 'ic-green' }[t] || 'ic-gray')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : ''
</script>

<style scoped>
.page-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:20px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.btn-readall { font-size:12px; padding:7px 14px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; color:var(--color-text-regular); white-space:nowrap; }
.btn-readall:hover { background:var(--color-bg-hover); }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.empty-tip { text-align:center; padding:60px; color:var(--color-text-muted); font-size:14px; }
.notif-row { display:flex; align-items:flex-start; gap:14px; padding:16px 20px; border-bottom:1px solid #f5f5f5; cursor:pointer; transition:var(--transition); }
.notif-row:last-child { border-bottom:none; }
.notif-row:hover { background:var(--color-bg-hover); }
.notif-row.unread { background:#fffef8; }
.notif-icon { width:40px; height:40px; border-radius:50%; display:flex; align-items:center; justify-content:center; font-size:18px; flex-shrink:0; }
.ic-green { background:#e8f5f0; }
.ic-red { background:#fde8e8; }
.ic-orange { background:#fff3e0; }
.ic-blue { background:#e8f0fe; }
.ic-gray { background:#f0f0f0; }
.notif-body { flex:1; }
.notif-title { font-size:14px; font-weight:500; color:var(--color-text-primary); display:flex; align-items:center; gap:8px; margin-bottom:4px; }
.unread-dot { width:7px; height:7px; border-radius:50%; background:var(--color-primary); flex-shrink:0; }
.notif-content { font-size:13px; color:var(--color-text-regular); line-height:1.5; }
.notif-time { font-size:11px; color:var(--color-text-muted); margin-top:6px; }
</style>
