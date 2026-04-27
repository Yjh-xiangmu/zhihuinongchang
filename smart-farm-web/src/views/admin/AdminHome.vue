<template>
  <div class="admin-home">

    <!-- 顶部统计卡片 -->
    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-label">种植区域总数</div>
        <div class="stat-val">{{ zones.length }}</div>
        <div class="stat-hint ok">{{ zones.filter(z => z.status === 'NORMAL').length }} 个生长中</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">未处理异常</div>
        <div class="stat-val warn">{{ pendingAnomalies.length }}</div>
        <div class="stat-hint warn">{{ pendingAnomalies.length > 0 ? '需要关注' : '暂无异常' }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">待审核记录</div>
        <div class="stat-val">{{ pendingAnomalies.length }}</div>
        <div class="stat-hint muted">全场待处理</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">本月采收批次</div>
        <div class="stat-val">{{ harvestCount }}</div>
        <div class="stat-hint muted">批次记录</div>
      </div>
    </div>

    <!-- 区域概览 -->
    <div class="section">
      <div class="section-header">
        <span class="section-title">种植区域概览</span>
        <button class="btn-add" @click="showAddZone = true">+ 新建区域</button>
      </div>

      <div v-if="zones.length === 0" class="empty-tip">暂无区域，点击右上角新建</div>

      <div class="zone-grid">
        <div
            v-for="zone in zones"
            :key="zone.id"
            class="zone-card"
        >
          <div class="zone-card-top">
            <span class="zone-name">{{ zone.zoneName }}</span>
            <span :class="['badge', statusBadge(zone.status)]">{{ statusLabel(zone.status) }}</span>
          </div>
          <div class="zone-crop">{{ zone.cropName || '暂未设置作物' }} · {{ zone.zoneType || '普通' }}</div>
          <div class="zone-meta">
            <span>负责人：{{ zone.managerName || '未指定' }}</span>
            <span>{{ zone.plantDate ? '种植于 ' + formatDate(zone.plantDate) : '未设置种植日期' }}</span>
          </div>
        </div>

        <!-- 新建按钮卡片 -->
        <div class="zone-card zone-add" @click="showAddZone = true">
          <span>+ 添加区域</span>
        </div>
      </div>
    </div>

    <!-- 最新预警 -->
    <div class="section">
      <div class="section-header">
        <span class="section-title">最新异常预警</span>
      </div>
      <div v-if="anomalies.length === 0" class="empty-tip">暂无异常记录</div>
      <div class="alert-list">
        <div v-for="a in anomalies.slice(0, 5)" :key="a.id" class="alert-row">
          <div :class="['alert-dot', a.status === 'PENDING' ? 'dot-danger' : 'dot-warn']"></div>
          <div class="alert-text">
            <span class="alert-zone">{{ a.zoneName }}</span> ·
            {{ anomalyTypeLabel(a.anomalyType) }}：{{ a.description }}
          </div>
          <span :class="['badge', anomalyStatusBadge(a.status)]">{{ anomalyStatusLabel(a.status) }}</span>
          <span class="alert-time">{{ formatDateTime(a.createTime) }}</span>
        </div>
      </div>
    </div>

    <!-- 新建区域弹窗 -->
    <div v-if="showAddZone" class="modal-mask" @click.self="showAddZone = false">
      <div class="modal-box">
        <div class="modal-title">新建种植区域</div>
        <div class="form-item">
          <label>区域名称 *</label>
          <input v-model="newZone.zoneName" placeholder="如：A区大棚1号" />
        </div>
        <div class="form-item">
          <label>种植作物</label>
          <input v-model="newZone.cropName" placeholder="如：西红柿" />
        </div>
        <div class="form-item">
          <label>区域类型</label>
          <select v-model="newZone.zoneType">
            <option value="大棚">大棚</option>
            <option value="温室">温室</option>
            <option value="露天">露天</option>
            <option value="水培">水培</option>
          </select>
        </div>
        <div class="form-item">
          <label>播种日期</label>
          <input type="date" v-model="newZone.plantDate" />
        </div>
        <div class="form-item">
          <label>区域负责人ID</label>
          <input v-model="newZone.managerId" placeholder="输入负责人的用户ID" type="number" />
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showAddZone = false">取消</button>
          <button class="btn-confirm" @click="submitZone" :disabled="submitting">
            {{ submitting ? '提交中...' : '确认创建' }}
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { zoneApi, anomalyApi } from '@/api.js'

const zones = ref([])
const anomalies = ref([])
const pendingAnomalies = ref([])
const harvestCount = ref(2)  // 暂时写死，后续可接harvest接口
const showAddZone = ref(false)
const submitting = ref(false)

const newZone = ref({
  zoneName: '',
  cropName: '',
  zoneType: '大棚',
  plantDate: '',
  managerId: null,
  status: 'NORMAL',
  growthStage: '播种'
})

onMounted(async () => {
  await loadZones()
  await loadAnomalies()
})

async function loadZones() {
  try {
    const res = await zoneApi.listAll()
    if (res.data.code === 200) {
      zones.value = res.data.data || []
    }
  } catch (e) {
    console.error('加载区域失败', e)
  }
}

async function loadAnomalies() {
  try {
    const res = await anomalyApi.listAll()
    if (res.data.code === 200) {
      anomalies.value = res.data.data || []
      pendingAnomalies.value = anomalies.value.filter(a => a.status === 'PENDING')
    }
  } catch (e) {
    console.error('加载异常失败', e)
  }
}

async function submitZone() {
  if (!newZone.value.zoneName) {
    alert('请填写区域名称')
    return
  }
  submitting.value = true
  try {
    const res = await zoneApi.add(newZone.value)
    if (res.data.code === 200) {
      showAddZone.value = false
      newZone.value = { zoneName: '', cropName: '', zoneType: '大棚', plantDate: '', managerId: null, status: 'NORMAL', growthStage: '播种' }
      await loadZones()
    }
  } catch (e) {
    alert('创建失败，请检查后端')
  } finally {
    submitting.value = false
  }
}

function statusLabel(s) {
  return { NORMAL: '正常', WARNING: '异常', HARVESTING: '采收中' }[s] || s
}
function statusBadge(s) {
  return { NORMAL: 'badge-ok', WARNING: 'badge-warn', HARVESTING: 'badge-info' }[s] || 'badge-ok'
}
function anomalyTypeLabel(t) {
  return { PEST: '病虫害', DEVICE: '设备损坏', GROWTH: '生长异常', OTHER: '其他' }[t] || t
}
function anomalyStatusLabel(s) {
  return { PENDING: '待处理', PROCESSING: '处理中', RESOLVED: '已解决', ESCALATED: '已上报' }[s] || s
}
function anomalyStatusBadge(s) {
  return { PENDING: 'badge-warn', PROCESSING: 'badge-info', RESOLVED: 'badge-ok', ESCALATED: 'badge-danger' }[s] || ''
}
function formatDate(d) {
  return d ? d.substring(0, 10) : ''
}
function formatDateTime(d) {
  if (!d) return ''
  return new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })
}
</script>

<style scoped>
.admin-home { padding: 0; }

.stat-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 20px; }
.stat-card { background: #fff; border-radius: 10px; padding: 16px 18px; border: 1px solid #f0f0f0; }
.stat-label { font-size: 12px; color: #86909c; margin-bottom: 6px; }
.stat-val { font-size: 28px; font-weight: 600; color: var(--color-text-primary); }
.stat-val.warn { color: #f77234; }
.stat-hint { font-size: 12px; margin-top: 4px; }
.stat-hint.ok { color: #1D9E75; }
.stat-hint.warn { color: #f77234; }
.stat-hint.muted { color: #86909c; }

.section { background: #fff; border-radius: 10px; padding: 16px 20px; margin-bottom: 16px; border: 1px solid #f0f0f0; }
.section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.section-title { font-size: 14px; font-weight: 600; color: var(--color-text-primary); }

.btn-add { font-size: 12px; padding: 6px 14px; background: var(--color-primary); color: #fff; border: none; border-radius: 6px; cursor: pointer; }
.btn-add:hover { background: var(--color-primary-hover); }

.empty-tip { font-size: 13px; color: #86909c; text-align: center; padding: 20px 0; }

.zone-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; }
.zone-card { background: #fdfdfd; border: 1px solid #eee; border-radius: 10px; padding: 14px; cursor: pointer; transition: var(--transition); }
.zone-card:hover { border-color: #ccc; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
.zone-card-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 4px; }
.zone-name { font-size: 13px; font-weight: 600; color: var(--color-text-primary); }
.zone-crop { font-size: 12px; color: #86909c; margin-bottom: 8px; }
.zone-meta { display: flex; justify-content: space-between; font-size: 11px; color: #aaa; }
.zone-add { display: flex; align-items: center; justify-content: center; border-style: dashed; color: #aaa; font-size: 13px; min-height: 90px; background: #fafafa; }
.zone-add:hover { border-color: var(--color-primary); color: var(--color-primary); }

.badge { display: inline-block; font-size: 11px; padding: 2px 7px; border-radius: 20px; font-weight: 500; }
.badge-ok { background: #e8f5f0; color: #1D9E75; }
.badge-warn { background: #fff3e0; color: #f77234; }
.badge-info { background: #e8f0fe; color: #1a73e8; }
.badge-danger { background: #fde8e8; color: #d32f2f; }

.alert-list { display: flex; flex-direction: column; gap: 0; }
.alert-row { display: flex; align-items: center; gap: 10px; padding: 10px 0; border-bottom: 1px solid #f5f5f5; font-size: 13px; }
.alert-row:last-child { border-bottom: none; }
.alert-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
.dot-danger { background: #f44336; }
.dot-warn { background: #ff9800; }
.alert-text { flex: 1; color: var(--color-text-primary); }
.alert-zone { font-weight: 600; }
.alert-time { font-size: 11px; color: #aaa; white-space: nowrap; }

/* 弹窗 */
.modal-mask { position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 100; display: flex; align-items: center; justify-content: center; }
.modal-box { background: #fff; border-radius: 16px; padding: 28px; width: 420px; box-shadow: 0 8px 32px rgba(0,0,0,0.12); }
.modal-title { font-size: 16px; font-weight: 600; margin-bottom: 20px; }
.form-item { margin-bottom: 14px; }
.form-item label { display: block; font-size: 12px; color: #666; margin-bottom: 5px; }
.form-item input, .form-item select { width: 100%; padding: 9px 12px; border: 1px solid #e5e6eb; border-radius: 8px; font-size: 13px; outline: none; }
.form-item input:focus, .form-item select:focus { border-color: var(--color-primary); }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; margin-top: 20px; }
.btn-cancel { padding: 8px 18px; border: 1px solid #ddd; background: #fff; border-radius: 8px; cursor: pointer; font-size: 13px; }
.btn-confirm { padding: 8px 18px; background: var(--color-primary); color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: 13px; }
.btn-confirm:disabled { background: #aaa; cursor: not-allowed; }
</style>