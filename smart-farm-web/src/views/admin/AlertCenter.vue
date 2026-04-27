<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">预警中心</div>
        <div class="page-sub">汇总全场异常上报与系统预警</div>
      </div>
      <div class="filter-row">
        <select v-model="filterStatus" @change="applyFilter">
          <option value="">全部状态</option>
          <option value="PENDING">待处理</option>
          <option value="PROCESSING">处理中</option>
          <option value="RESOLVED">已解决</option>
          <option value="ESCALATED">已上报</option>
        </select>
        <select v-model="filterType" @change="applyFilter">
          <option value="">全部类型</option>
          <option value="PEST">病虫害</option>
          <option value="DEVICE">设备损坏</option>
          <option value="GROWTH">生长异常</option>
          <option value="OTHER">其他</option>
        </select>
      </div>
    </div>

    <!-- 统计条 -->
    <div class="stat-row">
      <div class="stat-chip" :class="{ active: filterStatus==='' }" @click="filterStatus='';applyFilter()">
        全部 <strong>{{ all.length }}</strong>
      </div>
      <div class="stat-chip warn" :class="{ active: filterStatus==='PENDING' }" @click="filterStatus='PENDING';applyFilter()">
        待处理 <strong>{{ all.filter(a=>a.status==='PENDING').length }}</strong>
      </div>
      <div class="stat-chip info" :class="{ active: filterStatus==='PROCESSING' }" @click="filterStatus='PROCESSING';applyFilter()">
        处理中 <strong>{{ all.filter(a=>a.status==='PROCESSING').length }}</strong>
      </div>
      <div class="stat-chip ok" :class="{ active: filterStatus==='RESOLVED' }" @click="filterStatus='RESOLVED';applyFilter()">
        已解决 <strong>{{ all.filter(a=>a.status==='RESOLVED').length }}</strong>
      </div>
    </div>

    <div class="card">
      <div v-if="list.length===0" class="empty-tip">暂无异常记录</div>
      <div v-for="a in list" :key="a.id" class="anomaly-row">
        <div class="anomaly-left">
          <div :class="['type-badge', typeBadge(a.anomalyType)]">{{ typeLabel(a.anomalyType) }}</div>
          <div class="anomaly-body">
            <div class="anomaly-title">{{ a.zoneName }} · {{ a.description }}</div>
            <div class="anomaly-meta">
              上报人：{{ a.reporterName }} &nbsp;|&nbsp; {{ fmtDT(a.createTime) }}
              <span v-if="a.handleNote"> &nbsp;|&nbsp; 处理备注：{{ a.handleNote }}</span>
            </div>
          </div>
        </div>
        <div class="anomaly-right">
          <span :class="['badge', statusBadge(a.status)]">{{ statusLabel(a.status) }}</span>
          <button v-if="a.status==='PENDING'||a.status==='PROCESSING'" class="btn-sm" @click="openHandle(a)">处理</button>
        </div>
      </div>
    </div>

    <!-- 处理弹窗 -->
    <div v-if="showModal" class="modal-mask" @click.self="showModal=false">
      <div class="modal-box">
        <div class="modal-title">处理异常</div>
        <div class="anomaly-preview">
          <span :class="['type-badge', typeBadge(current.anomalyType)]">{{ typeLabel(current.anomalyType) }}</span>
          {{ current.zoneName }} — {{ current.description }}
        </div>
        <div class="form-item">
          <label>处理结果</label>
          <select v-model="handleForm.status">
            <option value="PROCESSING">处理中</option>
            <option value="RESOLVED">标记已解决</option>
            <option value="ESCALATED">上报管理层</option>
          </select>
        </div>
        <div class="form-item">
          <label>处理备注</label>
          <textarea v-model="handleForm.handleNote" placeholder="说明处理方案或结果..."></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showModal=false">取消</button>
          <button class="btn-primary" @click="submitHandle">确认</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { anomalyApi } from '@/api.js'

const all = ref([])
const list = ref([])
const filterStatus = ref('')
const filterType = ref('')
const showModal = ref(false)
const current = ref({})
const handleForm = ref({ status:'RESOLVED', handleNote:'' })
const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')

onMounted(async () => {
  const res = await anomalyApi.listAll()
  if (res.data.code === 200) { all.value = res.data.data || []; applyFilter() }
})

function applyFilter() {
  list.value = all.value.filter(a => {
    if (filterStatus.value && a.status !== filterStatus.value) return false
    if (filterType.value && a.anomalyType !== filterType.value) return false
    return true
  })
}

function openHandle(a) {
  current.value = a
  handleForm.value = { status: 'RESOLVED', handleNote: '' }
  showModal.value = true
}

async function submitHandle() {
  await anomalyApi.handle({ id: current.value.id, status: handleForm.value.status, handleNote: handleForm.value.handleNote, handlerId: userInfo.id })
  showModal.value = false
  const res = await anomalyApi.listAll()
  if (res.data.code === 200) { all.value = res.data.data || []; applyFilter() }
}

const typeLabel = t => ({ PEST:'病虫害', DEVICE:'设备损坏', GROWTH:'生长异常', OTHER:'其他' }[t]||t)
const typeBadge = t => ({ PEST:'tb-red', DEVICE:'tb-orange', GROWTH:'tb-blue', OTHER:'tb-gray' }[t]||'tb-gray')
const statusLabel = s => ({ PENDING:'待处理', PROCESSING:'处理中', RESOLVED:'已解决', ESCALATED:'已上报' }[s]||s)
const statusBadge = s => ({ PENDING:'badge-warn', PROCESSING:'badge-info', RESOLVED:'badge-ok', ESCALATED:'badge-danger' }[s]||'')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN',{month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}) : ''
</script>

<style scoped>
.page-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:16px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.filter-row { display:flex; gap:8px; }
.filter-row select { padding:6px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.stat-row { display:flex; gap:10px; margin-bottom:16px; flex-wrap:wrap; }
.stat-chip { padding:6px 16px; border-radius:20px; font-size:13px; cursor:pointer; border:1px solid var(--color-border); background:#fff; color:var(--color-text-regular); transition:var(--transition); }
.stat-chip strong { margin-left:4px; }
.stat-chip:hover, .stat-chip.active { border-color: var(--color-primary); background:#e8f5f0; color:var(--color-primary); }
.stat-chip.warn:hover, .stat-chip.warn.active { border-color:#f77234; background:#fff3e0; color:#f77234; }
.stat-chip.info:hover, .stat-chip.info.active { border-color:#1a73e8; background:#e8f0fe; color:#1a73e8; }
.stat-chip.ok:hover, .stat-chip.ok.active { border-color:#1D9E75; background:#e8f5f0; color:#1D9E75; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.anomaly-row { display:flex; align-items:center; justify-content:space-between; padding:14px 20px; border-bottom:1px solid #f5f5f5; gap:12px; }
.anomaly-row:last-child { border-bottom:none; }
.anomaly-row:hover { background:#fafffe; }
.anomaly-left { display:flex; align-items:flex-start; gap:12px; flex:1; min-width:0; }
.anomaly-body { flex:1; }
.anomaly-title { font-size:13px; font-weight:500; color:var(--color-text-primary); }
.anomaly-meta { font-size:12px; color:var(--color-text-muted); margin-top:3px; }
.anomaly-right { display:flex; align-items:center; gap:8px; flex-shrink:0; }
.anomaly-preview { background:#f7f8fa; border-radius:8px; padding:10px 12px; font-size:13px; margin-bottom:16px; display:flex; gap:8px; align-items:center; }
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
.btn-sm { font-size:12px; padding:4px 12px; border:1px solid var(--color-primary); color:var(--color-primary); background:transparent; border-radius:var(--radius-md); cursor:pointer; white-space:nowrap; }
.btn-primary { padding:8px 18px; background:var(--color-primary); color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; font-weight:500; }
.modal-mask { position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:100; display:flex; align-items:center; justify-content:center; }
.modal-box { background:#fff; border-radius:16px; padding:28px; width:460px; box-shadow:0 8px 32px rgba(0,0,0,0.12); }
.modal-title { font-size:16px; font-weight:600; margin-bottom:16px; }
.form-item { margin-bottom:14px; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:5px; }
.form-item select, .form-item textarea { width:100%; padding:8px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.form-item textarea { height:80px; resize:none; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
.btn-cancel { padding:8px 18px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
</style>