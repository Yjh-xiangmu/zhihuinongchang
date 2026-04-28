<template>
  <div>
    <div class="page-header">
      <div class="page-title">我的记录</div>
      <div class="page-sub">查看我历史提交的全部农事记录</div>
    </div>

    <div class="tab-row">
      <span v-for="t in tabs" :key="t.val" :class="['tab',{active:filterAudit===t.val}]" @click="filterAudit=t.val">
        {{ t.label }} <span class="tab-count">{{ countByAudit(t.val) }}</span>
      </span>
    </div>

    <div class="card">
      <div v-if="loading" class="empty-tip">加载中...</div>
      <div v-else-if="filtered.length===0" class="empty-tip">暂无记录</div>
      <div v-for="r in filtered" :key="r.id" class="record-row">
        <div class="record-left">
          <div :class="['type-dot', typeDot(r.recordType)]"></div>
          <div class="record-body">
            <div class="record-top">
              <span class="record-type">{{ typeLabel(r.recordType) }}</span>
              <span class="record-zone">{{ r.zoneName }}</span>
              <span :class="['badge', auditBadge(r.auditStatus)]">{{ auditLabel(r.auditStatus) }}</span>
            </div>
            <div class="record-content">{{ parseContent(r.content) }}</div>
            <div v-if="r.rejectReason" class="reject-tip">💬 驳回原因：{{ r.rejectReason }}</div>
            <div class="record-time">{{ fmtDT(r.createTime) }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { recordApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const records = ref([])
const loading = ref(false)
const filterAudit = ref('')

const tabs = [
  { val: '', label: '全部' },
  { val: 'PENDING', label: '待审核' },
  { val: 'PASSED', label: '已通过' },
  { val: 'REJECTED', label: '已驳回' },
]

onMounted(async () => {
  loading.value = true
  try {
    const res = await recordApi.listByWorker(userInfo.id)
    if (res.data.code === 200) records.value = res.data.data || []
  } finally { loading.value = false }
})

const filtered = computed(() =>
  filterAudit.value ? records.value.filter(r => r.auditStatus === filterAudit.value) : records.value
)
const countByAudit = s => s ? records.value.filter(r => r.auditStatus === s).length : records.value.length

function parseContent(c) {
  if (!c) return '无内容'
  try {
    const obj = JSON.parse(c)
    // 补全了采收等所有相关的中英文对照字典
    const map = {
      plant_height: '株高',
      leaf_color: '叶色',
      growth: '生长状态',
      remark: '备注',
      amount: '用量',
      batchNo: '批次号',
      yield: '总产量',
      gradeA: 'A级果',
      gradeB: 'B级果',
      gradeC: 'C级果'
    }
    return Object.entries(obj)
        .filter(([, v]) => v !== '' && v !== null && v !== undefined) // 过滤掉空值
        .map(([k, v]) => `${map[k] || k}: ${v}`)
        .filter(s => !s.endsWith(': ')) // 过滤掉没有值的键
        .join(' · ')
  } catch (e) {
    return c
  }
}

const typeLabel = t => ({ GROWTH: '生长记录', WATER: '浇水', FERTILIZER: '施肥', HARVEST: '采收' }[t] || t)
const typeDot = t => ({ GROWTH: 'dot-green', WATER: 'dot-blue', FERTILIZER: 'dot-orange', HARVEST: 'dot-purple' }[t] || 'dot-gray')
const auditLabel = s => ({ PENDING: '待审核', PASSED: '已通过', REJECTED: '已驳回' }[s] || s)
const auditBadge = s => ({ PENDING: 'badge-warn', PASSED: 'badge-ok', REJECTED: 'badge-danger' }[s] || '')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : ''
</script>

<style scoped>
.page-header { margin-bottom:16px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.tab-row { display:flex; gap:4px; margin-bottom:16px; border-bottom:1px solid var(--color-border); }
.tab { padding:8px 16px; font-size:13px; color:var(--color-text-regular); cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-1px; transition:var(--transition); }
.tab:hover { color:var(--color-text-primary); }
.tab.active { color:var(--color-primary); border-bottom-color:var(--color-primary); font-weight:600; }
.tab-count { font-size:11px; background:#f0f0f0; border-radius:10px; padding:1px 6px; margin-left:4px; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.record-row { padding:14px 20px; border-bottom:1px solid #f5f5f5; }
.record-row:last-child { border-bottom:none; }
.record-row:hover { background:#fafffe; }
.record-left { display:flex; align-items:flex-start; gap:12px; }
.type-dot { width:10px; height:10px; border-radius:50%; flex-shrink:0; margin-top:5px; }
.dot-green { background:#1D9E75; }
.dot-blue { background:#1a73e8; }
.dot-orange { background:#ff9800; }
.dot-purple { background:#534AB7; }
.dot-gray { background:#ccc; }
.record-body { flex:1; }
.record-top { display:flex; align-items:center; gap:8px; margin-bottom:5px; flex-wrap:wrap; }
.record-type { font-size:13px; font-weight:600; color:var(--color-text-primary); }
.record-zone { font-size:12px; color:var(--color-text-muted); }
.record-content { font-size:13px; color:var(--color-text-regular); line-height:1.5; }
.reject-tip { font-size:12px; color:#f44336; margin-top:5px; }
.record-time { font-size:11px; color:var(--color-text-muted); margin-top:4px; }
.badge { display:inline-block; font-size:11px; padding:2px 8px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
</style>
