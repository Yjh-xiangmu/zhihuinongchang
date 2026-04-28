<!-- GrowthTimeline.vue -->
<template>
  <div>
    <div class="page-header">
      <div class="page-title">生长时间轴</div>
      <div class="page-sub">追踪区域作物各阶段进度</div>
    </div>

    <div class="zone-select-row">
      <select v-model="selectedZoneId" @change="loadData">
        <option :value="null">请选择区域</option>
        <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.zoneName }}</option>
      </select>
    </div>

    <div v-if="!selectedZoneId" class="hint-card">← 请选择一个区域</div>

    <template v-else>
      <!-- 阶段进度条 -->
      <div class="stage-card">
        <div class="stage-title">{{ zone?.zoneName }} · {{ zone?.cropName }} 生长进度</div>
        <div class="stages">
          <div v-for="(s,i) in stages" :key="s.name" :class="['stage-item', stageClass(s.name)]">
            <div class="stage-dot"></div>
            <div class="stage-line" v-if="i<stages.length-1"></div>
            <div class="stage-name">{{ s.name }}</div>
            <div class="stage-date">{{ s.date }}</div>
          </div>
        </div>
      </div>

      <!-- 记录时间轴 -->
      <div class="card">
        <div class="card-header">操作记录（{{ records.length }}条）</div>
        <div v-if="records.length===0" class="empty-tip">暂无记录</div>
        <div v-for="(r,i) in records" :key="r.id" class="tl-row">
          <div class="tl-left">
            <div :class="['tl-dot', typeDot(r.recordType)]"></div>
            <div class="tl-vline" v-if="i<records.length-1"></div>
          </div>
          <div class="tl-body">
            <div class="tl-header">
              <span :class="['type-tag', typeTagClass(r.recordType)]">{{ typeLabel(r.recordType) }}</span>
              <span class="tl-who">{{ r.workerName }}</span>
              <span class="tl-time">{{ fmtDT(r.createTime) }}</span>
              <span :class="['badge', auditBadge(r.auditStatus)]">{{ auditLabel(r.auditStatus) }}</span>
            </div>
            <div class="tl-content">{{ parseContent(r.content) }}</div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { zoneApi, recordApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const zones = ref([])
const selectedZoneId = ref(null)
const records = ref([])

const zone = computed(() => zones.value.find(z=>z.id===selectedZoneId.value))

const stageOrder = ['播种','缓苗期','开花期','结果期','采收']
const stages = computed(() => {
  const z = zone.value
  if (!z) return []
  return stageOrder.map(name => ({
    name,
    date: name==='播种' && z.plantDate ? z.plantDate.substring(0,10) : ''
  }))
})

function stageClass(name) {
  const z = zone.value
  if (!z) return ''
  const cur = stageOrder.indexOf(z.growthStage)
  const idx = stageOrder.indexOf(name)
  if (idx < cur) return 'done'
  if (idx === cur) return 'current'
  return 'pending'
}

onMounted(async () => {
  const res = await zoneApi.listByManager(userInfo.id)
  if (res.data.code===200) zones.value = res.data.data||[]
})

async function loadData() {
  if (!selectedZoneId.value) return
  const res = await recordApi.listByZone(selectedZoneId.value)
  if (res.data.code===200) records.value = (res.data.data||[]).sort((a,b)=>new Date(b.createTime)-new Date(a.createTime))
}

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

const typeLabel = t => ({GROWTH:'生长记录',WATER:'浇水',FERTILIZER:'施肥',HARVEST:'采收'}[t]||t)
const typeDot = t => ({GROWTH:'dot-green',WATER:'dot-blue',FERTILIZER:'dot-orange',HARVEST:'dot-purple'}[t]||'dot-gray')
const typeTagClass = t => ({GROWTH:'tag-green',WATER:'tag-blue',FERTILIZER:'tag-orange',HARVEST:'tag-purple'}[t]||'tag-gray')
const auditLabel = s => ({PENDING:'待审核',PASSED:'已通过',REJECTED:'已驳回'}[s]||s)
const auditBadge = s => ({PENDING:'badge-warn',PASSED:'badge-ok',REJECTED:'badge-danger'}[s]||'')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN',{month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}) : ''
</script>

<style scoped>
.page-header { margin-bottom:16px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.zone-select-row { margin-bottom:16px; }
.zone-select-row select { padding:8px 12px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; min-width:220px; }
.hint-card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); text-align:center; padding:60px; color:var(--color-text-muted); font-size:14px; }
.stage-card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); padding:20px 24px; margin-bottom:16px; }
.stage-title { font-size:14px; font-weight:600; margin-bottom:16px; }
.stages { display:flex; align-items:flex-start; gap:0; overflow-x:auto; }
.stage-item { display:flex; flex-direction:column; align-items:center; position:relative; min-width:80px; flex:1; }
.stage-dot { width:14px; height:14px; border-radius:50%; border:2px solid #ddd; background:#fff; z-index:1; }
.stage-line { position:absolute; top:6px; left:50%; width:100%; height:2px; background:#ddd; z-index:0; }
.stage-name { font-size:12px; margin-top:8px; color:var(--color-text-muted); text-align:center; }
.stage-date { font-size:11px; color:var(--color-text-muted); }
.stage-item.done .stage-dot { background:var(--color-primary); border-color:var(--color-primary); }
.stage-item.done .stage-line { background:var(--color-primary); }
.stage-item.done .stage-name { color:var(--color-primary); font-weight:500; }
.stage-item.current .stage-dot { background:#fff; border-color:#534AB7; box-shadow:0 0 0 3px #e8e6ff; }
.stage-item.current .stage-name { color:#534AB7; font-weight:600; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.card-header { padding:14px 20px; font-size:14px; font-weight:600; border-bottom:1px solid var(--color-border); }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.tl-row { display:flex; gap:0; padding:0 20px; }
.tl-left { display:flex; flex-direction:column; align-items:center; width:32px; flex-shrink:0; padding-top:16px; }
.tl-dot { width:10px; height:10px; border-radius:50%; flex-shrink:0; }
.tl-vline { flex:1; width:2px; background:var(--color-border); min-height:20px; }
.dot-green { background:#1D9E75; }
.dot-blue { background:#1a73e8; }
.dot-orange { background:#ff9800; }
.dot-purple { background:#534AB7; }
.dot-gray { background:#ccc; }
.tl-body { flex:1; padding:14px 0 14px 4px; border-bottom:1px solid #f5f5f5; }
.tl-row:last-child .tl-body { border-bottom:none; }
.tl-header { display:flex; align-items:center; gap:8px; flex-wrap:wrap; margin-bottom:5px; }
.type-tag { font-size:11px; padding:2px 7px; border-radius:4px; font-weight:600; }
.tag-green { background:#e8f5f0; color:#1D9E75; }
.tag-blue { background:#e8f0fe; color:#1a73e8; }
.tag-orange { background:#fff3e0; color:#f57c00; }
.tag-purple { background:#f0eeff; color:#534AB7; }
.tag-gray { background:#f0f0f0; color:#666; }
.tl-who { font-size:12px; font-weight:500; }
.tl-time { font-size:12px; color:var(--color-text-muted); flex:1; }
.tl-content { font-size:13px; color:var(--color-text-regular); }
.badge { display:inline-block; font-size:11px; padding:2px 7px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
</style>