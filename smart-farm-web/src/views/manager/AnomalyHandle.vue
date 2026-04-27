<template>
  <div>
    <div class="page-header">
      <div class="page-title">异常处理</div>
      <div class="page-sub">处理员工上报的异常，或将重大问题升级给管理员</div>
    </div>

    <div class="tab-row">
      <span v-for="t in tabs" :key="t.val" :class="['tab',{active:filterStatus===t.val}]" @click="filterStatus=t.val">
        {{ t.label }} <span class="tab-count">{{ countByStatus(t.val) }}</span>
      </span>
    </div>

    <div class="card">
      <div v-if="filtered.length===0" class="empty-tip">暂无异常记录</div>
      <div v-for="a in filtered" :key="a.id" class="anomaly-row">
        <div class="anomaly-left">
          <div :class="['type-badge', typeBadge(a.anomalyType)]">{{ typeLabel(a.anomalyType) }}</div>
          <div class="anomaly-body">
            <div class="anomaly-title">{{ a.zoneName }} · {{ a.description }}</div>
            <div class="anomaly-meta">
              上报人：{{ a.reporterName }} · {{ fmtDT(a.createTime) }}
            </div>
            <div v-if="a.handleNote" class="handle-note">处理备注：{{ a.handleNote }}</div>
          </div>
        </div>
        <div class="anomaly-right">
          <span :class="['badge', statusBadge(a.status)]">{{ statusLabel(a.status) }}</span>
          <template v-if="a.status==='PENDING'||a.status==='PROCESSING'">
            <button class="btn-sm resolve" @click="quickResolve(a)">标记解决</button>
            <button class="btn-sm escalate" @click="escalate(a)">上报管理员</button>
          </template>
          <button v-if="a.status==='PENDING'" class="btn-sm" @click="openHandle(a)">填写处理</button>
        </div>
      </div>
    </div>

    <!-- 处理弹窗 -->
    <div v-if="showModal" class="modal-mask" @click.self="showModal=false">
      <div class="modal-box">
        <div class="modal-title">填写处理方案</div>
        <div class="preview-box">
          <span :class="['type-badge', typeBadge(current.anomalyType)]">{{ typeLabel(current.anomalyType) }}</span>
          {{ current.description }}
        </div>
        <div class="form-item">
          <label>处理结果 *</label>
          <select v-model="handleForm.status">
            <option value="PROCESSING">处理中</option>
            <option value="RESOLVED">已解决</option>
            <option value="ESCALATED">上报管理员</option>
          </select>
        </div>
        <div class="form-item">
          <label>处理备注</label>
          <textarea v-model="handleForm.handleNote" placeholder="说明处理方案、使用药剂、处理结果等..."></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showModal=false">取消</button>
          <button class="btn-primary" @click="submitHandle">确认提交</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { anomalyApi, zoneApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const anomalies = ref([])
const zones = ref([])
const filterStatus = ref('PENDING')
const showModal = ref(false)
const current = ref({})
const handleForm = ref({ status: 'RESOLVED', handleNote: '' })

const tabs = [
  { val: 'PENDING', label: '待处理' },
  { val: 'PROCESSING', label: '处理中' },
  { val: 'RESOLVED', label: '已解决' },
  { val: 'ESCALATED', label: '已上报' },
  { val: '', label: '全部' },
]

onMounted(async () => {
  const res = await zoneApi.listByManager(userInfo.id)
  if (res.data.code === 200) {
    zones.value = res.data.data || []
    await loadAnomalies()
  }
})

async function loadAnomalies() {
  const all = []
  for (const z of zones.value) {
    const res = await anomalyApi.listByZone(z.id)
    if (res.data.code === 200) all.push(...(res.data.data || []))
  }
  anomalies.value = all.sort((a, b) => new Date(b.createTime) - new Date(a.createTime))
}

const filtered = computed(() =>
  filterStatus.value ? anomalies.value.filter(a => a.status === filterStatus.value) : anomalies.value
)
const countByStatus = s => s ? anomalies.value.filter(a => a.status === s).length : anomalies.value.length

function openHandle(a) {
  current.value = a
  handleForm.value = { status: 'RESOLVED', handleNote: '' }
  showModal.value = true
}

async function quickResolve(a) {
  await anomalyApi.handle({ id: a.id, status: 'RESOLVED', handleNote: '已处理完毕', handlerId: userInfo.id })
  await loadAnomalies()
}

async function escalate(a) {
  if (!confirm(`确认将此异常上报给农场管理员？`)) return
  await anomalyApi.handle({ id: a.id, status: 'ESCALATED', handleNote: '情况复杂，已上报管理员', handlerId: userInfo.id })
  await loadAnomalies()
}

async function submitHandle() {
  await anomalyApi.handle({ id: current.value.id, status: handleForm.value.status, handleNote: handleForm.value.handleNote, handlerId: userInfo.id })
  showModal.value = false
  await loadAnomalies()
}

const typeLabel = t => ({ PEST: '病虫害', DEVICE: '设备损坏', GROWTH: '生长异常', OTHER: '其他' }[t] || t)
const typeBadge = t => ({ PEST: 'tb-red', DEVICE: 'tb-orange', GROWTH: 'tb-blue', OTHER: 'tb-gray' }[t] || 'tb-gray')
const statusLabel = s => ({ PENDING: '待处理', PROCESSING: '处理中', RESOLVED: '已解决', ESCALATED: '已上报' }[s] || s)
const statusBadge = s => ({ PENDING: 'badge-warn', PROCESSING: 'badge-info', RESOLVED: 'badge-ok', ESCALATED: 'badge-danger' }[s] || '')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : ''
</script>

<style scoped>
.page-header { margin-bottom:16px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.tab-row { display:flex; gap:4px; margin-bottom:16px; border-bottom:1px solid var(--color-border); }
.tab { padding:8px 16px; font-size:13px; color:var(--color-text-regular); cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-1px; transition:var(--transition); }
.tab:hover { color:var(--color-text-primary); }
.tab.active { color:#534AB7; border-bottom-color:#534AB7; font-weight:600; }
.tab-count { font-size:11px; background:#f0f0f0; border-radius:10px; padding:1px 6px; margin-left:4px; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.anomaly-row { display:flex; align-items:flex-start; justify-content:space-between; padding:14px 20px; border-bottom:1px solid #f5f5f5; gap:12px; }
.anomaly-row:last-child { border-bottom:none; }
.anomaly-row:hover { background:#fafffe; }
.anomaly-left { display:flex; align-items:flex-start; gap:10px; flex:1; min-width:0; }
.anomaly-body { flex:1; }
.anomaly-title { font-size:13px; font-weight:500; }
.anomaly-meta { font-size:12px; color:var(--color-text-muted); margin-top:3px; }
.handle-note { font-size:12px; color:var(--color-primary); margin-top:3px; }
.anomaly-right { display:flex; align-items:center; gap:6px; flex-shrink:0; flex-wrap:wrap; justify-content:flex-end; }
.type-badge { display:inline-block; font-size:11px; padding:3px 8px; border-radius:6px; font-weight:600; white-space:nowrap; flex-shrink:0; }
.tb-red { background:#fde8e8; color:#d32f2f; }
.tb-orange { background:#fff3e0; color:#f57c00; }
.tb-blue { background:#e8f0fe; color:#1a73e8; }
.tb-gray { background:#f0f0f0; color:#666; }
.badge { display:inline-block; font-size:11px; padding:2px 8px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-info { background:#e8f0fe; color:#1a73e8; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
.btn-sm { font-size:12px; padding:4px 10px; background:transparent; border-radius:var(--radius-md); cursor:pointer; white-space:nowrap; border:1px solid var(--color-border); color:var(--color-text-regular); }
.btn-sm.resolve { border-color:#1D9E75; color:#1D9E75; }
.btn-sm.escalate { border-color:#f44336; color:#f44336; }
.preview-box { background:#f7f8fa; border-radius:8px; padding:10px 12px; font-size:13px; margin-bottom:16px; display:flex; gap:8px; align-items:flex-start; }
.btn-primary { padding:8px 18px; background:#534AB7; color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
.modal-mask { position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:100; display:flex; align-items:center; justify-content:center; }
.modal-box { background:#fff; border-radius:16px; padding:28px; width:440px; box-shadow:0 8px 32px rgba(0,0,0,0.12); }
.modal-title { font-size:16px; font-weight:600; margin-bottom:16px; }
.form-item { margin-bottom:14px; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:5px; }
.form-item select, .form-item textarea { width:100%; padding:8px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.form-item textarea { height:80px; resize:none; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
.btn-cancel { padding:8px 18px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
</style>
