<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">种植全程追溯</div>
        <div class="page-sub">选择区域，查看从播种到采收的完整操作记录链</div>
      </div>
    </div>

    <!-- 选择区域 -->
    <div class="search-bar">
      <select v-model="selectedZoneId" @change="loadTrace">
        <option :value="null">请选择区域</option>
        <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.zoneName }}</option>
      </select>
      <div v-if="selectedZone" class="zone-info">
        <span class="zi-item">作物：<strong>{{ selectedZone.cropName }}</strong></span>
        <span class="zi-item">状态：<span :class="['badge', statusBadge(selectedZone.status)]">{{ statusLabel(selectedZone.status) }}</span></span>
        <span class="zi-item">播种：<strong>{{ fmtDate(selectedZone.plantDate) }}</strong></span>
        <span class="zi-item">阶段：<strong>{{ selectedZone.growthStage }}</strong></span>
      </div>
    </div>

    <div v-if="!selectedZoneId" class="hint-box">← 请先选择左侧区域</div>

    <div v-else-if="loading" class="hint-box">加载中...</div>

    <div v-else class="trace-wrap">
      <!-- 统计 -->
      <div class="trace-stats">
        <div class="ts-item">农事记录 <strong>{{ farmRecords.length }}</strong> 条</div>
        <div class="ts-item">采收批次 <strong>{{ harvestRecords.length }}</strong> 批</div>
        <div class="ts-item">异常上报 <strong>{{ anomalies.length }}</strong> 次</div>
      </div>

      <!-- 时间轴 -->
      <div class="timeline">
        <div v-for="(item, i) in timeline" :key="i" class="tl-item">
          <div :class="['tl-dot', item.color]"></div>
          <div class="tl-line" v-if="i < timeline.length-1"></div>
          <div class="tl-body">
            <div class="tl-time">{{ fmtDT(item.time) }}</div>
            <div class="tl-tag" :class="item.tagClass">{{ item.tag }}</div>
            <div class="tl-title">{{ item.title }}</div>
            <div class="tl-desc" v-if="item.desc">{{ item.desc }}</div>
            <div class="tl-who" v-if="item.who">操作人：{{ item.who }}</div>
          </div>
        </div>
        <div v-if="timeline.length===0" class="empty-tip">该区域暂无记录</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { zoneApi, recordApi, harvestApi, anomalyApi } from '@/api.js'

const zones = ref([])
const selectedZoneId = ref(null)
const farmRecords = ref([])
const harvestRecords = ref([])
const anomalies = ref([])
const loading = ref(false)

const selectedZone = computed(() => zones.value.find(z => z.id === selectedZoneId.value))

onMounted(async () => {
  const res = await zoneApi.listAll()
  if (res.data.code === 200) zones.value = res.data.data || []
})

async function loadTrace() {
  if (!selectedZoneId.value) return
  loading.value = true
  try {
    const [r1, r2, r3] = await Promise.all([
      recordApi.listByZone(selectedZoneId.value),
      harvestApi.listByZone(selectedZoneId.value),
      anomalyApi.listByZone(selectedZoneId.value),
    ])
    if (r1.data.code === 200) farmRecords.value = r1.data.data || []
    if (r2.data.code === 200) harvestRecords.value = r2.data.data || []
    if (r3.data.code === 200) anomalies.value = r3.data.data || []
  } finally { loading.value = false }
}

const timeline = computed(() => {
  const items = []
  const zone = selectedZone.value
  if (zone?.plantDate) {
    items.push({ time: zone.plantDate + 'T00:00:00', tag:'播种', tagClass:'tag-green', color:'dot-green', title:`${zone.cropName || '作物'}开始种植`, desc:`区域：${zone.zoneName}`, who: zone.managerName })
  }
  farmRecords.value.forEach(r => {
    const typeMap = { GROWTH:'生长记录', WATER:'浇水', FERTILIZER:'施肥', HARVEST:'采收' }
    let desc = r.content
    try { const obj = JSON.parse(r.content); desc = Object.values(obj).filter(Boolean).join(' · ') } catch(e){}
    items.push({ time: r.createTime, tag: typeMap[r.recordType]||'记录', tagClass:'tag-blue', color: r.auditStatus==='REJECTED'?'dot-red':'dot-blue', title: `${typeMap[r.recordType]||'农事记录'}`, desc, who: r.workerName })
  })
  anomalies.value.forEach(a => {
    items.push({ time: a.createTime, tag:'异常上报', tagClass:'tag-red', color:'dot-red', title: `${a.anomalyType==='PEST'?'病虫害':a.anomalyType==='DEVICE'?'设备损坏':'生长异常'}：${a.description}`, desc: a.handleNote ? `处理：${a.handleNote}` : '', who: a.reporterName })
  })
  harvestRecords.value.forEach(h => {
    items.push({ time: h.createTime, tag:'采收', tagClass:'tag-orange', color:'dot-orange', title:`批次 ${h.batchNo}，总重 ${h.actualWeight}kg`, desc:`A级${h.gradeA}kg / B级${h.gradeB}kg / C级${h.gradeC}kg`, who: h.workerName })
  })
  return items.sort((a,b) => new Date(a.time) - new Date(b.time))
})

const statusLabel = s => ({NORMAL:'正常',WARNING:'异常',HARVESTING:'采收中'}[s]||s)
const statusBadge = s => ({NORMAL:'badge-ok',WARNING:'badge-warn',HARVESTING:'badge-info'}[s]||'')
const fmtDate = d => d ? String(d).substring(0,10) : '-'
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN',{month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}) : '-'
</script>

<style scoped>
.page-header { margin-bottom:20px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.search-bar { display:flex; align-items:center; gap:16px; margin-bottom:20px; flex-wrap:wrap; }
.search-bar select { padding:8px 12px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; min-width:200px; }
.zone-info { display:flex; gap:16px; flex-wrap:wrap; }
.zi-item { font-size:13px; color:var(--color-text-regular); }
.hint-box { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); text-align:center; padding:60px; color:var(--color-text-muted); font-size:14px; }
.trace-wrap { }
.trace-stats { display:flex; gap:12px; margin-bottom:20px; }
.ts-item { background:#fff; border-radius:var(--radius-md); border:1px solid var(--color-border); padding:10px 20px; font-size:13px; color:var(--color-text-regular); }
.ts-item strong { color:var(--color-text-primary); font-size:16px; margin-left:6px; }
.timeline { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); padding:24px 28px; }
.tl-item { display:flex; gap:14px; position:relative; padding-bottom:24px; }
.tl-item:last-child { padding-bottom:0; }
.tl-dot { width:12px; height:12px; border-radius:50%; flex-shrink:0; margin-top:4px; z-index:1; }
.dot-green { background:#1D9E75; }
.dot-blue { background:#1a73e8; }
.dot-red { background:#f44336; }
.dot-orange { background:#ff9800; }
.tl-line { position:absolute; left:5px; top:16px; bottom:0; width:2px; background:var(--color-border); }
.tl-body { flex:1; }
.tl-time { font-size:11px; color:var(--color-text-muted); margin-bottom:4px; }
.tl-tag { display:inline-block; font-size:11px; padding:2px 7px; border-radius:4px; font-weight:600; margin-bottom:5px; }
.tag-green { background:#e8f5f0; color:#1D9E75; }
.tag-blue { background:#e8f0fe; color:#1a73e8; }
.tag-red { background:#fde8e8; color:#d32f2f; }
.tag-orange { background:#fff3e0; color:#f57c00; }
.tl-title { font-size:13px; font-weight:500; color:var(--color-text-primary); }
.tl-desc { font-size:12px; color:var(--color-text-muted); margin-top:3px; }
.tl-who { font-size:12px; color:var(--color-text-muted); margin-top:2px; }
.empty-tip { text-align:center; padding:30px; color:var(--color-text-muted); }
.badge { display:inline-block; font-size:11px; padding:2px 7px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-info { background:#e8f0fe; color:#1a73e8; }
</style>