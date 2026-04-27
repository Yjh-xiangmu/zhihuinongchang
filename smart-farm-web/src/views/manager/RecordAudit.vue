<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">记录审核</div>
        <div class="page-sub">审核员工提交的农事记录</div>
      </div>
    </div>

    <div class="tab-row">
      <span v-for="t in tabs" :key="t.val" :class="['tab',{active:filterAudit===t.val}]" @click="filterAudit=t.val">
        {{ t.label }} <span class="tab-count">{{ countByAudit(t.val) }}</span>
      </span>
    </div>

    <div class="card">
      <div v-if="filtered.length===0" class="empty-tip">暂无记录</div>
      <div v-for="r in filtered" :key="r.id" class="record-row">
        <div class="record-avatar">{{ r.workerName?r.workerName[0]:'?' }}</div>
        <div class="record-body">
          <div class="record-top">
            <span class="record-who">{{ r.workerName }}</span>
            <span class="record-type-tag">{{ typeLabel(r.recordType) }}</span>
            <span class="record-zone">{{ r.zoneName }}</span>
          </div>
          <div class="record-content">{{ parseContent(r.content) }}</div>
          <div class="record-meta">{{ fmtDT(r.createTime) }}</div>
          <div v-if="r.rejectReason" class="reject-tip">驳回原因：{{ r.rejectReason }}</div>
        </div>
        <div class="record-actions">
          <span :class="['badge', auditBadge(r.auditStatus)]">{{ auditLabel(r.auditStatus) }}</span>
          <template v-if="r.auditStatus==='PENDING'">
            <button class="btn-pass" @click="pass(r)">通过</button>
            <button class="btn-rej" @click="openReject(r)">驳回</button>
          </template>
        </div>
      </div>
    </div>

    <div v-if="showReject" class="modal-mask" @click.self="showReject=false">
      <div class="modal-box">
        <div class="modal-title">填写驳回原因</div>
        <div class="form-item">
          <label>原因 *</label>
          <textarea v-model="rejectReason" placeholder="说明需要员工补充或修改的内容..."></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showReject=false">取消</button>
          <button class="btn-danger" @click="confirmReject">确认驳回</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { recordApi, zoneApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const records = ref([])
const zones = ref([])
const filterAudit = ref('PENDING')
const showReject = ref(false)
const rejectTarget = ref(null)
const rejectReason = ref('')

const tabs = [
  { val:'PENDING', label:'待审核' },
  { val:'PASSED', label:'已通过' },
  { val:'REJECTED', label:'已驳回' },
  { val:'', label:'全部' },
]

onMounted(async () => {
  const res = await zoneApi.listByManager(userInfo.id)
  if (res.data.code===200) {
    zones.value = res.data.data||[]
    await loadRecords()
  }
})

async function loadRecords() {
  const all = []
  for (const z of zones.value) {
    const res = await recordApi.listByZone(z.id)
    if (res.data.code===200) all.push(...(res.data.data||[]))
  }
  records.value = all.sort((a,b) => new Date(b.createTime)-new Date(a.createTime))
}

const filtered = computed(() => filterAudit.value ? records.value.filter(r=>r.auditStatus===filterAudit.value) : records.value)
const countByAudit = s => s ? records.value.filter(r=>r.auditStatus===s).length : records.value.length

async function pass(r) {
  await recordApi.audit({ id:r.id, auditStatus:'PASSED', rejectReason:'' })
  await loadRecords()
}
function openReject(r) {
  rejectTarget.value = r
  rejectReason.value = ''
  showReject.value = true
}
async function confirmReject() {
  if (!rejectReason.value) { alert('请填写驳回原因'); return }
  await recordApi.audit({ id:rejectTarget.value.id, auditStatus:'REJECTED', rejectReason:rejectReason.value })
  showReject.value = false
  await loadRecords()
}

function parseContent(c) {
  try {
    const obj = JSON.parse(c)
    return Object.entries(obj).map(([k,v]) => {
      const map = { plant_height:'株高', leaf_color:'叶色', growth:'生长状态', remark:'备注', amount:'用量' }
      return `${map[k]||k}: ${v}`
    }).filter(s=>s.includes(': ') && !s.endsWith(': ')).join(' · ')
  } catch(e) { return c }
}

const typeLabel = t => ({GROWTH:'生长记录',WATER:'浇水',FERTILIZER:'施肥',HARVEST:'采收'}[t]||t)
const auditLabel = s => ({PENDING:'待审核',PASSED:'已通过',REJECTED:'已驳回'}[s]||s)
const auditBadge = s => ({PENDING:'badge-warn',PASSED:'badge-ok',REJECTED:'badge-danger'}[s]||'')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN',{month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}) : ''
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
.record-row { display:flex; align-items:flex-start; gap:12px; padding:14px 20px; border-bottom:1px solid #f5f5f5; }
.record-row:last-child { border-bottom:none; }
.record-row:hover { background:#fafffe; }
.record-avatar { width:34px; height:34px; border-radius:50%; background:#f0eeff; color:#534AB7; display:flex; align-items:center; justify-content:center; font-size:13px; font-weight:600; flex-shrink:0; }
.record-body { flex:1; min-width:0; }
.record-top { display:flex; align-items:center; gap:8px; margin-bottom:4px; flex-wrap:wrap; }
.record-who { font-size:13px; font-weight:600; }
.record-type-tag { font-size:11px; background:#e8f0fe; color:#1a73e8; padding:2px 7px; border-radius:4px; }
.record-zone { font-size:12px; color:var(--color-text-muted); }
.record-content { font-size:13px; color:var(--color-text-regular); line-height:1.5; }
.record-meta { font-size:11px; color:var(--color-text-muted); margin-top:4px; }
.reject-tip { font-size:12px; color:#f44336; margin-top:4px; }
.record-actions { display:flex; flex-direction:column; align-items:flex-end; gap:6px; flex-shrink:0; }
.badge { display:inline-block; font-size:11px; padding:2px 8px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
.btn-pass { font-size:12px; padding:4px 12px; border:1px solid #1D9E75; color:#1D9E75; background:transparent; border-radius:var(--radius-md); cursor:pointer; }
.btn-rej { font-size:12px; padding:4px 12px; border:1px solid #f44336; color:#f44336; background:transparent; border-radius:var(--radius-md); cursor:pointer; }
.modal-mask { position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:100; display:flex; align-items:center; justify-content:center; }
.modal-box { background:#fff; border-radius:16px; padding:28px; width:420px; box-shadow:0 8px 32px rgba(0,0,0,0.12); }
.modal-title { font-size:16px; font-weight:600; margin-bottom:20px; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:5px; }
.form-item textarea { width:100%; padding:8px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; height:80px; resize:none; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
.btn-cancel { padding:8px 18px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
.btn-danger { padding:8px 18px; background:#f44336; color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
</style>