<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">产量报告</div>
        <div class="page-sub">查看各区域采收批次与产量统计</div>
      </div>
    </div>

    <!-- 汇总卡片 -->
    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-label">采收批次总数</div>
        <div class="stat-val">{{ records.length }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">总采收重量</div>
        <div class="stat-val">{{ totalWeight }} <span class="unit">kg</span></div>
      </div>
      <div class="stat-card">
        <div class="stat-label">A级产量</div>
        <div class="stat-val ok">{{ totalA }} <span class="unit">kg</span></div>
      </div>
      <div class="stat-card">
        <div class="stat-label">A级占比</div>
        <div class="stat-val">{{ aRate }}<span class="unit">%</span></div>
      </div>
    </div>

    <!-- 采收记录表 -->
    <div class="card">
      <div class="card-header">采收批次明细</div>
      <div v-if="records.length===0" class="empty-tip">暂无采收记录</div>
      <table v-else class="table">
        <thead>
        <tr>
          <th>批次号</th><th>区域</th><th>采收人</th>
          <th>总重量(kg)</th><th>A级(kg)</th><th>B级(kg)</th><th>C级(kg)</th>
          <th>备注</th><th>时间</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="r in records" :key="r.id">
          <td class="fw mono">{{ r.batchNo }}</td>
          <td>{{ r.zoneName }}</td>
          <td>{{ r.workerName }}</td>
          <td class="fw">{{ r.actualWeight }}</td>
          <td class="ok">{{ r.gradeA }}</td>
          <td>{{ r.gradeB }}</td>
          <td class="muted">{{ r.gradeC }}</td>
          <td class="muted">{{ r.remark || '-' }}</td>
          <td class="muted">{{ fmtDate(r.createTime) }}</td>
        </tr>
        </tbody>
        <tfoot>
        <tr class="total-row">
          <td colspan="3" class="fw">合计</td>
          <td class="fw">{{ totalWeight }}</td>
          <td class="ok fw">{{ totalA }}</td>
          <td class="fw">{{ totalB }}</td>
          <td class="fw">{{ totalC }}</td>
          <td colspan="2"></td>
        </tr>
        </tfoot>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { harvestApi } from '@/api.js'

const records = ref([])

onMounted(async () => {
  const res = await harvestApi.listAll()
  if (res.data.code === 200) records.value = res.data.data || []
})

const totalWeight = computed(() => records.value.reduce((s,r) => s + (Number(r.actualWeight)||0), 0).toFixed(1))
const totalA = computed(() => records.value.reduce((s,r) => s + (Number(r.gradeA)||0), 0).toFixed(1))
const totalB = computed(() => records.value.reduce((s,r) => s + (Number(r.gradeB)||0), 0).toFixed(1))
const totalC = computed(() => records.value.reduce((s,r) => s + (Number(r.gradeC)||0), 0).toFixed(1))
const aRate = computed(() => totalWeight.value > 0 ? ((totalA.value / totalWeight.value)*100).toFixed(1) : 0)

const fmtDate = d => d ? new Date(d).toLocaleDateString('zh-CN') : '-'
</script>

<style scoped>
.page-header { margin-bottom:20px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.stat-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:12px; margin-bottom:20px; }
.stat-card { background:#fff; border-radius:var(--radius-lg); padding:18px 20px; border:1px solid var(--color-border); }
.stat-label { font-size:12px; color:var(--color-text-muted); margin-bottom:6px; }
.stat-val { font-size:28px; font-weight:600; color:var(--color-text-primary); }
.stat-val.ok { color:var(--color-primary); }
.unit { font-size:14px; font-weight:400; color:var(--color-text-muted); margin-left:2px; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.card-header { padding:14px 20px; font-size:14px; font-weight:600; border-bottom:1px solid var(--color-border); }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.table { width:100%; border-collapse:collapse; font-size:13px; }
.table th { padding:10px 16px; background:#fafafa; color:var(--color-text-muted); font-weight:500; text-align:left; border-bottom:1px solid var(--color-border); white-space:nowrap; }
.table td { padding:11px 16px; border-bottom:1px solid #f5f5f5; }
.table tr:last-child td { border-bottom:none; }
.table tr:hover td { background:#fafffe; }
.total-row td { background:#f7f8fa; font-size:13px; }
.fw { font-weight:600; color:var(--color-text-primary); }
.ok { color:var(--color-primary); }
.muted { color:var(--color-text-muted); }
.mono { font-family:monospace; font-size:12px; }
</style>