<template>
  <div>
    <div class="page-header">
      <div class="page-title">上报异常</div>
      <div class="page-sub">发现问题请及时上报，负责人会尽快处理</div>
    </div>

    <!-- 上报表单 -->
    <div class="form-card">
      <div class="form-card-title">新建异常上报</div>
      <div class="form-grid">
        <div class="form-item">
          <label>异常类型 *</label>
          <div class="type-select">
            <div v-for="t in types" :key="t.val" :class="['type-opt', { active: form.anomalyType===t.val }]" @click="form.anomalyType=t.val">
              <div :class="['type-icon', t.color]">{{ t.icon }}</div>
              <span>{{ t.label }}</span>
            </div>
          </div>
        </div>
        <div class="form-item">
          <label>所在区域 *</label>
          <select v-model="form.zoneId">
            <option :value="null">请选择</option>
            <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.zoneName }}</option>
          </select>
        </div>
        <div class="form-item full">
          <label>问题描述 *</label>
          <textarea v-model="form.description" placeholder="详细描述发现的问题，包括位置、严重程度、影响范围等..."></textarea>
        </div>
      </div>
      <button class="btn-submit" @click="submit" :disabled="submitting">
        {{ submitting ? '上报中...' : '确认上报' }}
      </button>
    </div>

    <!-- 我的上报历史 -->
    <div class="section-title-bar">我的上报历史</div>

    <div class="card">
      <div v-if="myAnomalies.length===0" class="empty-tip">暂无上报记录</div>
      <div v-for="a in myAnomalies" :key="a.id" class="anomaly-row">
        <div class="anomaly-left">
          <div :class="['type-badge', typeBadge(a.anomalyType)]">{{ typeLabel(a.anomalyType) }}</div>
          <div class="anomaly-body">
            <div class="anomaly-title">{{ a.zoneName }} · {{ a.description }}</div>
            <div v-if="a.handleNote" class="handle-note">处理结果：{{ a.handleNote }}</div>
            <div class="anomaly-time">{{ fmtDT(a.createTime) }}</div>
          </div>
        </div>
        <span :class="['badge', statusBadge(a.status)]">{{ statusLabel(a.status) }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { anomalyApi, zoneApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const zones = ref([])
const myAnomalies = ref([])
const submitting = ref(false)

const types = [
  { val: 'PEST', label: '病虫害', icon: '🐛', color: 'ic-red' },
  { val: 'DEVICE', label: '设备损坏', icon: '🔧', color: 'ic-orange' },
  { val: 'GROWTH', label: '生长异常', icon: '🌱', color: 'ic-blue' },
  { val: 'OTHER', label: '其他', icon: '📋', color: 'ic-gray' },
]

const form = ref({ anomalyType: 'PEST', zoneId: null, description: '' })

onMounted(async () => {
  const [r1, r2] = await Promise.all([
    zoneApi.listAll(),
    anomalyApi.listByReporter(userInfo.id),
  ])
  if (r1.data.code === 200) zones.value = r1.data.data || []
  if (r2.data.code === 200) myAnomalies.value = r2.data.data || []
})

async function submit() {
  if (!form.value.zoneId) { alert('请选择所在区域'); return }
  if (!form.value.description.trim()) { alert('请填写问题描述'); return }
  submitting.value = true
  try {
    await anomalyApi.add({ ...form.value, reporterId: userInfo.id })
    alert('上报成功！负责人将尽快处理。')
    form.value = { anomalyType: 'PEST', zoneId: null, description: '' }
    const res = await anomalyApi.listByReporter(userInfo.id)
    if (res.data.code === 200) myAnomalies.value = res.data.data || []
  } catch (e) { alert('上报失败，请重试') }
  finally { submitting.value = false }
}

const typeLabel = t => ({ PEST: '病虫害', DEVICE: '设备损坏', GROWTH: '生长异常', OTHER: '其他' }[t] || t)
const typeBadge = t => ({ PEST: 'tb-red', DEVICE: 'tb-orange', GROWTH: 'tb-blue', OTHER: 'tb-gray' }[t] || 'tb-gray')
const statusLabel = s => ({ PENDING: '待处理', PROCESSING: '处理中', RESOLVED: '已解决', ESCALATED: '已上报' }[s] || s)
const statusBadge = s => ({ PENDING: 'badge-warn', PROCESSING: 'badge-info', RESOLVED: 'badge-ok', ESCALATED: 'badge-danger' }[s] || '')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : ''
</script>

<style scoped>
.page-header { margin-bottom:20px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.form-card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); padding:24px; margin-bottom:20px; }
.form-card-title { font-size:15px; font-weight:600; margin-bottom:18px; }
.form-grid { display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-bottom:16px; }
.form-item.full { grid-column:1/-1; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:8px; font-weight:500; }
.form-item select { width:100%; padding:9px 12px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.form-item select:focus { border-color:var(--color-primary); }
.form-item textarea { width:100%; padding:10px 12px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; height:100px; resize:none; line-height:1.6; }
.form-item textarea:focus { border-color:var(--color-primary); }
.type-select { display:flex; gap:10px; flex-wrap:wrap; }
.type-opt { display:flex; flex-direction:column; align-items:center; gap:6px; padding:12px 16px; border:1.5px solid var(--color-border); border-radius:var(--radius-md); cursor:pointer; min-width:80px; transition:var(--transition); }
.type-opt:hover { border-color:#aaa; }
.type-opt.active { border-color:var(--color-primary); background:#e8f5f0; }
.type-opt span { font-size:12px; color:var(--color-text-regular); }
.type-opt.active span { color:var(--color-primary); font-weight:600; }
.type-icon { font-size:22px; }
.btn-submit { width:100%; padding:12px; background:var(--color-primary); color:#fff; border:none; border-radius:var(--radius-md); font-size:14px; font-weight:600; cursor:pointer; transition:var(--transition); }
.btn-submit:hover:not(:disabled) { background:var(--color-primary-hover); }
.btn-submit:disabled { background:#aaa; cursor:not-allowed; }
.section-title-bar { font-size:14px; font-weight:600; margin-bottom:12px; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.anomaly-row { display:flex; align-items:flex-start; justify-content:space-between; padding:14px 20px; border-bottom:1px solid #f5f5f5; gap:12px; }
.anomaly-row:last-child { border-bottom:none; }
.anomaly-left { display:flex; align-items:flex-start; gap:10px; flex:1; }
.anomaly-body { flex:1; }
.anomaly-title { font-size:13px; font-weight:500; }
.handle-note { font-size:12px; color:var(--color-primary); margin-top:3px; }
.anomaly-time { font-size:11px; color:var(--color-text-muted); margin-top:3px; }
.type-badge { display:inline-block; font-size:11px; padding:3px 8px; border-radius:6px; font-weight:600; white-space:nowrap; flex-shrink:0; }
.tb-red { background:#fde8e8; color:#d32f2f; }
.tb-orange { background:#fff3e0; color:#f57c00; }
.tb-blue { background:#e8f0fe; color:#1a73e8; }
.tb-gray { background:#f0f0f0; color:#666; }
.badge { display:inline-block; font-size:11px; padding:2px 8px; border-radius:20px; font-weight:500; flex-shrink:0; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-info { background:#e8f0fe; color:#1a73e8; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
</style>
