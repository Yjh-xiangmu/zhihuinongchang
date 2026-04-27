<template>
  <div>
    <div class="page-header">
      <div class="page-title">周报生成</div>
      <div class="page-sub">汇总本区域本周数据，生成工作周报</div>
    </div>

    <div class="zone-select-row">
      <select v-model="selectedZoneId" @change="loadReport">
        <option :value="null">请选择区域</option>
        <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.zoneName }}</option>
      </select>
      <button class="btn-primary" @click="printReport" :disabled="!selectedZoneId">打印 / 导出</button>
    </div>

    <div v-if="!selectedZoneId" class="hint-card">← 请先选择区域</div>

    <div v-else-if="loading" class="hint-card">数据加载中...</div>

    <div v-else id="report-content" class="report">
      <!-- 报告头 -->
      <div class="report-header">
        <div class="report-title">{{ zone?.zoneName }} 工作周报</div>
        <div class="report-sub">报告生成时间：{{ nowStr }} · 负责人：{{ userInfo.realName }}</div>
      </div>

      <!-- 区域基本信息 -->
      <div class="section">
        <div class="section-title">一、区域基本信息</div>
        <div class="info-grid">
          <div class="info-item"><span class="info-label">区域名称</span><span class="info-val">{{ zone?.zoneName }}</span></div>
          <div class="info-item"><span class="info-label">种植作物</span><span class="info-val">{{ zone?.cropName || '-' }}</span></div>
          <div class="info-item"><span class="info-label">区域类型</span><span class="info-val">{{ zone?.zoneType || '-' }}</span></div>
          <div class="info-item"><span class="info-label">当前阶段</span><span class="info-val">{{ zone?.growthStage || '-' }}</span></div>
          <div class="info-item"><span class="info-label">播种日期</span><span class="info-val">{{ fmtDate(zone?.plantDate) }}</span></div>
          <div class="info-item"><span class="info-label">区域状态</span><span class="info-val">{{ statusLabel(zone?.status) }}</span></div>
        </div>
      </div>

      <!-- 本周任务汇总 -->
      <div class="section">
        <div class="section-title">二、本周任务汇总</div>
        <div class="stat-row">
          <div class="stat-box">
            <div class="sb-val">{{ tasks.length }}</div>
            <div class="sb-label">总任务数</div>
          </div>
          <div class="stat-box ok">
            <div class="sb-val">{{ tasks.filter(t=>t.status==='DONE').length }}</div>
            <div class="sb-label">已完成</div>
          </div>
          <div class="stat-box warn">
            <div class="sb-val">{{ tasks.filter(t=>t.status==='PENDING').length }}</div>
            <div class="sb-label">未完成</div>
          </div>
          <div class="stat-box danger">
            <div class="sb-val">{{ tasks.filter(t=>t.status==='LATE').length }}</div>
            <div class="sb-label">超时</div>
          </div>
          <div class="stat-box">
            <div class="sb-val">{{ taskRate }}%</div>
            <div class="sb-label">完成率</div>
          </div>
        </div>
      </div>

      <!-- 农事记录汇总 -->
      <div class="section">
        <div class="section-title">三、农事记录汇总</div>
        <div class="stat-row">
          <div class="stat-box">
            <div class="sb-val">{{ records.length }}</div>
            <div class="sb-label">总记录数</div>
          </div>
          <div class="stat-box ok">
            <div class="sb-val">{{ records.filter(r=>r.auditStatus==='PASSED').length }}</div>
            <div class="sb-label">已审核通过</div>
          </div>
          <div class="stat-box warn">
            <div class="sb-val">{{ records.filter(r=>r.auditStatus==='PENDING').length }}</div>
            <div class="sb-label">待审核</div>
          </div>
          <div class="stat-box danger">
            <div class="sb-val">{{ records.filter(r=>r.auditStatus==='REJECTED').length }}</div>
            <div class="sb-label">已驳回</div>
          </div>
        </div>
        <!-- 各类型分布 -->
        <div class="type-dist">
          <div v-for="(count, type) in recordTypeCount" :key="type" class="type-item">
            <span class="type-name">{{ recTypeLabel(type) }}</span>
            <div class="type-bar-wrap">
              <div class="type-bar" :style="{ width: (count/records.length*100)+'%' }"></div>
            </div>
            <span class="type-count">{{ count }}条</span>
          </div>
        </div>
      </div>

      <!-- 异常情况 -->
      <div class="section">
        <div class="section-title">四、异常情况</div>
        <div v-if="anomalies.length===0" class="no-anomaly">本周无异常上报 ✓</div>
        <table v-else class="table">
          <thead><tr><th>类型</th><th>描述</th><th>上报人</th><th>状态</th><th>时间</th></tr></thead>
          <tbody>
            <tr v-for="a in anomalies" :key="a.id">
              <td><span :class="['type-badge', typeBadge(a.anomalyType)]">{{ typeLabel(a.anomalyType) }}</span></td>
              <td>{{ a.description }}</td>
              <td>{{ a.reporterName }}</td>
              <td><span :class="['badge', statusBadge(a.status)]">{{ statusLabel(a.status) }}</span></td>
              <td class="muted">{{ fmtDT(a.createTime) }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- 采收情况 -->
      <div class="section" v-if="harvests.length > 0">
        <div class="section-title">五、采收情况</div>
        <table class="table">
          <thead><tr><th>批次号</th><th>总重量</th><th>A级</th><th>B级</th><th>C级</th><th>采收人</th></tr></thead>
          <tbody>
            <tr v-for="h in harvests" :key="h.id">
              <td class="mono">{{ h.batchNo }}</td>
              <td class="fw">{{ h.actualWeight }}kg</td>
              <td class="ok">{{ h.gradeA }}kg</td>
              <td>{{ h.gradeB }}kg</td>
              <td class="muted">{{ h.gradeC }}kg</td>
              <td>{{ h.workerName }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { zoneApi, taskApi, recordApi, anomalyApi, harvestApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const zones = ref([])
const selectedZoneId = ref(null)
const loading = ref(false)
const tasks = ref([])
const records = ref([])
const anomalies = ref([])
const harvests = ref([])
const nowStr = new Date().toLocaleString('zh-CN')

const zone = computed(() => zones.value.find(z => z.id === selectedZoneId.value))
const taskRate = computed(() => tasks.value.length ? Math.round(tasks.value.filter(t => t.status === 'DONE').length / tasks.value.length * 100) : 0)
const recordTypeCount = computed(() => {
  const cnt = {}
  records.value.forEach(r => { cnt[r.recordType] = (cnt[r.recordType] || 0) + 1 })
  return cnt
})

onMounted(async () => {
  const res = await zoneApi.listByManager(userInfo.id)
  if (res.data.code === 200) zones.value = res.data.data || []
})

async function loadReport() {
  if (!selectedZoneId.value) return
  loading.value = true
  try {
    const [r1, r2, r3, r4] = await Promise.all([
      taskApi.listByZone(selectedZoneId.value),
      recordApi.listByZone(selectedZoneId.value),
      anomalyApi.listByZone(selectedZoneId.value),
      harvestApi.listByZone(selectedZoneId.value),
    ])
    if (r1.data.code === 200) tasks.value = r1.data.data || []
    if (r2.data.code === 200) records.value = r2.data.data || []
    if (r3.data.code === 200) anomalies.value = r3.data.data || []
    if (r4.data.code === 200) harvests.value = r4.data.data || []
  } finally { loading.value = false }
}

function printReport() {
  window.print()
}

const statusLabel = s => ({ NORMAL: '正常', WARNING: '异常', HARVESTING: '采收中' }[s] || s)
const typeLabel = t => ({ PEST: '病虫害', DEVICE: '设备损坏', GROWTH: '生长异常', OTHER: '其他' }[t] || t)
const typeBadge = t => ({ PEST: 'tb-red', DEVICE: 'tb-orange', GROWTH: 'tb-blue', OTHER: 'tb-gray' }[t] || 'tb-gray')
const statusBadge = s => ({ PENDING: 'badge-warn', PROCESSING: 'badge-info', RESOLVED: 'badge-ok', ESCALATED: 'badge-danger' }[s] || '')
const recTypeLabel = t => ({ GROWTH: '生长记录', WATER: '浇水', FERTILIZER: '施肥', HARVEST: '采收' }[t] || t)
const fmtDate = d => d ? String(d).substring(0, 10) : '-'
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : ''
</script>

<style scoped>
.page-header { margin-bottom:16px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.zone-select-row { display:flex; align-items:center; gap:12px; margin-bottom:20px; }
.zone-select-row select { padding:8px 12px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; min-width:220px; }
.btn-primary { padding:8px 18px; background:#534AB7; color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
.btn-primary:disabled { background:#aaa; cursor:not-allowed; }
.hint-card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); text-align:center; padding:60px; color:var(--color-text-muted); font-size:14px; }
.report { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); padding:32px 36px; }
.report-header { text-align:center; margin-bottom:28px; padding-bottom:20px; border-bottom:2px solid var(--color-border); }
.report-title { font-size:22px; font-weight:700; color:var(--color-text-primary); }
.report-sub { font-size:13px; color:var(--color-text-muted); margin-top:6px; }
.section { margin-bottom:24px; }
.section-title { font-size:15px; font-weight:600; color:var(--color-text-primary); margin-bottom:14px; padding-left:10px; border-left:3px solid #534AB7; }
.info-grid { display:grid; grid-template-columns:repeat(3,1fr); gap:10px; }
.info-item { background:#f7f8fa; border-radius:8px; padding:10px 14px; display:flex; flex-direction:column; gap:4px; }
.info-label { font-size:11px; color:var(--color-text-muted); }
.info-val { font-size:14px; font-weight:500; }
.stat-row { display:flex; gap:12px; flex-wrap:wrap; }
.stat-box { background:#f7f8fa; border-radius:8px; padding:14px 20px; text-align:center; min-width:90px; flex:1; }
.stat-box.ok { background:#e8f5f0; }
.stat-box.warn { background:#fff3e0; }
.stat-box.danger { background:#fde8e8; }
.sb-val { font-size:24px; font-weight:700; color:var(--color-text-primary); }
.stat-box.ok .sb-val { color:#1D9E75; }
.stat-box.warn .sb-val { color:#f77234; }
.stat-box.danger .sb-val { color:#d32f2f; }
.sb-label { font-size:12px; color:var(--color-text-muted); margin-top:4px; }
.type-dist { margin-top:14px; display:flex; flex-direction:column; gap:8px; }
.type-item { display:flex; align-items:center; gap:10px; font-size:13px; }
.type-name { width:72px; color:var(--color-text-regular); flex-shrink:0; }
.type-bar-wrap { flex:1; height:8px; background:#f0f0f0; border-radius:4px; overflow:hidden; }
.type-bar { height:100%; background:#534AB7; border-radius:4px; min-width:4px; transition:width 0.4s; }
.type-count { width:36px; text-align:right; color:var(--color-text-muted); }
.no-anomaly { background:#e8f5f0; border-radius:8px; padding:16px 20px; color:#1D9E75; font-weight:500; }
.table { width:100%; border-collapse:collapse; font-size:13px; }
.table th { padding:10px 12px; background:#fafafa; color:var(--color-text-muted); font-weight:500; text-align:left; border-bottom:1px solid var(--color-border); }
.table td { padding:10px 12px; border-bottom:1px solid #f5f5f5; }
.table tr:last-child td { border-bottom:none; }
.fw { font-weight:600; }
.ok { color:#1D9E75; }
.muted { color:var(--color-text-muted); }
.mono { font-family:monospace; font-size:12px; }
.type-badge { display:inline-block; font-size:11px; padding:2px 7px; border-radius:4px; font-weight:600; }
.tb-red { background:#fde8e8; color:#d32f2f; }
.tb-orange { background:#fff3e0; color:#f57c00; }
.tb-blue { background:#e8f0fe; color:#1a73e8; }
.tb-gray { background:#f0f0f0; color:#666; }
.badge { display:inline-block; font-size:11px; padding:2px 7px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-info { background:#e8f0fe; color:#1a73e8; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
@media print { .zone-select-row { display:none; } }
</style>
