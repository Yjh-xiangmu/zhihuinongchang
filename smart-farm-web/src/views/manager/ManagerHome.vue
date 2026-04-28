<template>
  <div class="manager-home">

    <!-- 顶部统计 -->
    <div class="stat-grid">
      <div class="stat-card">
        <div class="stat-label">待审核记录</div>
        <div class="stat-val" :class="pendingRecords.length>0?'warn':''">{{ pendingRecords.length }}</div>
        <div class="stat-hint" :class="pendingRecords.length>0?'warn':'muted'">{{ pendingRecords.length > 0 ? '需要处理' : '全部处理完' }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">今日任务</div>
        <div class="stat-val">{{ tasks.length }}</div>
        <div class="stat-hint ok">{{ tasks.filter(t=>t.status==='DONE').length }} 已完成</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">区域异常</div>
        <div class="stat-val" :class="pendingAnomalies.length>0?'warn':''">{{ pendingAnomalies.length }}</div>
        <div class="stat-hint" :class="pendingAnomalies.length>0?'warn':'muted'">{{ pendingAnomalies.length > 0 ? '待处理' : '暂无' }}</div>
      </div>
      <div class="stat-card">
        <div class="stat-label">任务完成率</div>
        <div class="stat-val">{{ taskRate }}%</div>
        <div class="stat-hint muted">全部任务</div>
      </div>
    </div>

    <!-- 待审核快捷栏 -->
    <div class="section">
      <div class="section-header">
        <span class="section-title">待审核记录</span>
        <div style="display:flex;gap:8px;align-items:center">
          <span class="badge badge-warn" v-if="pendingRecords.length > 0">{{ pendingRecords.length }} 条</span>
          <router-link to="/manager/audit" class="link-more">查看全部 →</router-link>
        </div>
      </div>
      <div v-if="pendingRecords.length === 0" class="empty-tip">暂无待审核记录 ✓</div>
      <div class="record-list">
        <div v-for="r in pendingRecords.slice(0,4)" :key="r.id" class="record-row">
          <div class="avatar">{{ r.workerName ? r.workerName[0] : '?' }}</div>
          <div class="record-body">
            <div class="record-who">{{ r.workerName }} · <span class="record-type-tag">{{ recordTypeLabel(r.recordType) }}</span></div>
            <!-- 解析JSON内容，转成可读文字 -->
            <div class="record-desc">{{ parseContent(r.content) }}</div>
            <div class="record-time">{{ fmtDT(r.createTime) }}</div>
          </div>
          <div class="record-actions">
            <button class="btn-pass" @click="auditRecord(r.id, 'PASSED', '')">通过</button>
            <button class="btn-rej" @click="openRejectDialog(r)">驳回</button>
          </div>
        </div>
      </div>
    </div>

    <!-- 任务工单 -->
    <div class="section">
      <div class="section-header">
        <span class="section-title">任务工单</span>
        <div style="display:flex;gap:8px;align-items:center">
          <router-link to="/manager/tasks" class="link-more">查看全部 →</router-link>
          <button class="btn-add" @click="openAddTask">+ 派发任务</button>
        </div>
      </div>
      <div v-if="tasks.length === 0" class="empty-tip">暂无任务</div>
      <div class="task-list">
        <div v-for="t in tasks.slice(0,5)" :key="t.id" class="task-row">
          <span :class="['badge', taskStatusBadge(t.status)]">{{ taskStatusLabel(t.status) }}</span>
          <span class="task-name">{{ t.taskName }}</span>
          <span class="task-who">{{ t.assigneeName || '未指派' }}</span>
          <span class="task-time">截止 {{ fmtDT(t.deadline) }}</span>
        </div>
      </div>
    </div>

    <!-- 区域异常 -->
    <div class="section">
      <div class="section-header">
        <span class="section-title">区域异常</span>
        <router-link to="/manager/anomaly" class="link-more">查看全部 →</router-link>
      </div>
      <div v-if="anomalies.length === 0" class="empty-tip">暂无异常记录 ✓</div>
      <div class="alert-list">
        <div v-for="a in anomalies.slice(0, 4)" :key="a.id" class="alert-row">
          <div :class="['alert-dot', a.status === 'PENDING' ? 'dot-danger' : 'dot-warn']"></div>
          <div class="alert-text">
            <span class="alert-who">{{ a.reporterName }}</span> 上报：{{ anomalyTypeLabel(a.anomalyType) }} — {{ a.description }}
          </div>
          <span :class="['badge', anomalyStatusBadge(a.status)]">{{ anomalyStatusLabel(a.status) }}</span>
        </div>
      </div>
    </div>

    <!-- 派发任务弹窗 -->
    <div v-if="showAddTask" class="modal-mask" @click.self="showAddTask=false">
      <div class="modal-box">
        <div class="modal-title">派发新任务</div>
        <div class="form-grid">
          <div class="form-item full">
            <label>任务名称 *</label>
            <input v-model="newTask.taskName" placeholder="如：第1-3排生长巡检" />
          </div>
          <div class="form-item">
            <label>任务类型</label>
            <select v-model="newTask.taskType">
              <option value="GROWTH">生长巡检</option>
              <option value="WATER">浇水</option>
              <option value="FERTILIZER">施肥</option>
              <option value="PEST">病虫害检查</option>
              <option value="HARVEST">采收</option>
            </select>
          </div>
          <div class="form-item">
            <label>所属区域</label>
            <select v-model="newTask.zoneId" @change="loadZoneWorkers">
              <option :value="null">请选择</option>
              <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.zoneName }}</option>
            </select>
          </div>
          <div class="form-item">
            <label>指派员工</label>
            <select v-model="newTask.assigneeId" :disabled="!newTask.zoneId">
              <option :value="null">{{ newTask.zoneId ? '请选择员工' : '先选区域' }}</option>
              <option v-for="w in zoneWorkers" :key="w.id" :value="w.id">{{ w.realName }}</option>
            </select>
            <div v-if="newTask.zoneId && zoneWorkers.length===0" class="field-tip">该区域暂无分配员工，请先在区域管理中添加</div>
          </div>
          <div class="form-item">
            <label>截止时间</label>
            <input type="datetime-local" v-model="newTask.deadline" />
          </div>
          <div class="form-item">
            <label>作业排数（选填）</label>
            <input v-model="newTask.rowNo" placeholder="如：第1-3排" />
          </div>
          <div class="form-item full">
            <label>任务描述（选填）</label>
            <input v-model="newTask.description" placeholder="具体要求和注意事项" />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showAddTask=false">取消</button>
          <button class="btn-confirm" @click="submitTask" :disabled="saving">{{ saving?'派发中...':'确认派发' }}</button>
        </div>
      </div>
    </div>

    <!-- 驳回原因弹窗 -->
    <div v-if="showRejectDialog" class="modal-mask" @click.self="showRejectDialog=false">
      <div class="modal-box small">
        <div class="modal-title">填写驳回原因</div>
        <div class="form-item">
          <label>原因 *</label>
          <textarea v-model="rejectReason" placeholder="请说明需要员工补充或修改的内容..."></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showRejectDialog=false">取消</button>
          <button class="btn-rej-confirm" @click="confirmReject">确认驳回</button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { taskApi, recordApi, anomalyApi, zoneApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')

const tasks = ref([])
const pendingRecords = ref([])
const anomalies = ref([])
const zones = ref([])
const zoneWorkers = ref([])
const showAddTask = ref(false)
const showRejectDialog = ref(false)
const rejectTargetId = ref(null)
const rejectReason = ref('')
const saving = ref(false)

const newTask = ref({
  zoneId: null, taskName: '', taskType: 'GROWTH',
  assigneeId: null, deadline: '', rowNo: '', description: '',
  creatorId: userInfo.id
})

onMounted(async () => {
  // 加载负责人管的区域
  const zRes = await zoneApi.listByManager(userInfo.id)
  if (zRes.data.code === 200) zones.value = zRes.data.data || []

  await Promise.all([loadTasks(), loadPendingRecords(), loadAnomalies()])
})

async function loadTasks() {
  const all = []
  for (const z of zones.value) {
    const res = await taskApi.listByZone(z.id)
    if (res.data.code === 200) all.push(...(res.data.data || []))
  }
  tasks.value = all.sort((a, b) => new Date(b.createTime) - new Date(a.createTime))
}

async function loadPendingRecords() {
  const all = []
  for (const z of zones.value) {
    const res = await recordApi.listPending(z.id)
    if (res.data.code === 200) all.push(...(res.data.data || []))
  }
  pendingRecords.value = all.sort((a, b) => new Date(b.createTime) - new Date(a.createTime))
}

async function loadAnomalies() {
  const all = []
  for (const z of zones.value) {
    const res = await anomalyApi.listByZone(z.id)
    if (res.data.code === 200) all.push(...(res.data.data || []))
  }
  anomalies.value = all.sort((a, b) => new Date(b.createTime) - new Date(a.createTime))
}

// 选择区域后，加载该区域的员工
async function loadZoneWorkers() {
  newTask.value.assigneeId = null
  zoneWorkers.value = []
  if (!newTask.value.zoneId) return
  const res = await zoneApi.getWorkers(newTask.value.zoneId)
  if (res.data.code === 200) zoneWorkers.value = res.data.data || []
}

function openAddTask() {
  newTask.value = { zoneId: null, taskName: '', taskType: 'GROWTH', assigneeId: null, deadline: '', rowNo: '', description: '', creatorId: userInfo.id }
  zoneWorkers.value = []
  showAddTask.value = true
}

async function submitTask() {
  if (!newTask.value.taskName) { alert('请填写任务名称'); return }
  saving.value = true
  try {
    await taskApi.add(newTask.value)
    showAddTask.value = false
    await loadTasks()
  } catch (e) { alert('派发失败') }
  finally { saving.value = false }
}

async function auditRecord(id, status, reason) {
  await recordApi.audit({ id, auditStatus: status, rejectReason: reason })
  await loadPendingRecords()
}

function openRejectDialog(r) {
  rejectTargetId.value = r.id
  rejectReason.value = ''
  showRejectDialog.value = true
}

async function confirmReject() {
  if (!rejectReason.value) { alert('请填写驳回原因'); return }
  await auditRecord(rejectTargetId.value, 'REJECTED', rejectReason.value)
  showRejectDialog.value = false
}

// 解析JSON内容 → 可读文字
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

const pendingAnomalies = computed(() => anomalies.value.filter(a => a.status === 'PENDING'))
const taskRate = computed(() => {
  if (!tasks.value.length) return 0
  return Math.round(tasks.value.filter(t => t.status === 'DONE').length / tasks.value.length * 100)
})

const recordTypeLabel = t => ({ GROWTH: '生长记录', WATER: '浇水', FERTILIZER: '施肥', HARVEST: '采收' }[t] || t)
const taskStatusLabel = s => ({ PENDING: '待办', DONE: '已完成', LATE: '超时' }[s] || s)
const taskStatusBadge = s => ({ PENDING: 'badge-info', DONE: 'badge-ok', LATE: 'badge-danger' }[s] || '')
const anomalyTypeLabel = t => ({ PEST: '病虫害', DEVICE: '设备损坏', GROWTH: '生长异常', OTHER: '其他' }[t] || t)
const anomalyStatusLabel = s => ({ PENDING: '待处理', PROCESSING: '处理中', RESOLVED: '已解决', ESCALATED: '已上报' }[s] || s)
const anomalyStatusBadge = s => ({ PENDING: 'badge-warn', PROCESSING: 'badge-info', RESOLVED: 'badge-ok', ESCALATED: 'badge-danger' }[s] || '')
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' }) : '未设置'
</script>

<style scoped>
.manager-home { }
.stat-grid { display:grid; grid-template-columns:repeat(4,1fr); gap:12px; margin-bottom:16px; }
.stat-card { background:#fff; border-radius:var(--radius-lg); padding:16px 18px; border:1px solid var(--color-border); }
.stat-label { font-size:12px; color:var(--color-text-muted); margin-bottom:6px; }
.stat-val { font-size:28px; font-weight:600; color:var(--color-text-primary); }
.stat-val.warn { color:#f77234; }
.stat-hint { font-size:12px; margin-top:4px; }
.stat-hint.ok { color:var(--color-primary); }
.stat-hint.warn { color:#f77234; }
.stat-hint.muted { color:var(--color-text-muted); }
.section { background:#fff; border-radius:var(--radius-lg); padding:16px 20px; margin-bottom:14px; border:1px solid var(--color-border); }
.section-header { display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; }
.section-title { font-size:14px; font-weight:600; }
.link-more { font-size:12px; color:#534AB7; text-decoration:none; }
.link-more:hover { text-decoration:underline; }
.empty-tip { font-size:13px; color:var(--color-text-muted); text-align:center; padding:16px 0; }
.btn-add { font-size:12px; padding:5px 12px; background:#534AB7; color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; }
/* 记录列表 */
.record-list { display:flex; flex-direction:column; gap:2px; }
.record-row { display:flex; align-items:flex-start; gap:10px; padding:10px 0; border-bottom:1px solid #f5f5f5; }
.record-row:last-child { border-bottom:none; }
.avatar { width:32px; height:32px; border-radius:50%; background:#f0eeff; color:#534AB7; display:flex; align-items:center; justify-content:center; font-size:13px; font-weight:600; flex-shrink:0; }
.record-body { flex:1; min-width:0; }
.record-who { font-size:13px; font-weight:500; display:flex; align-items:center; gap:6px; }
.record-type-tag { font-size:11px; background:#e8f0fe; color:#1a73e8; padding:1px 6px; border-radius:4px; font-weight:400; }
.record-desc { font-size:12px; color:var(--color-text-regular); margin-top:2px; overflow:hidden; text-overflow:ellipsis; white-space:nowrap; }
.record-time { font-size:11px; color:var(--color-text-muted); margin-top:2px; }
.record-actions { display:flex; flex-direction:column; gap:5px; flex-shrink:0; }
.btn-pass { font-size:11px; padding:4px 10px; border:1px solid #1D9E75; color:#1D9E75; background:transparent; border-radius:5px; cursor:pointer; }
.btn-rej { font-size:11px; padding:4px 10px; border:1px solid #f44336; color:#f44336; background:transparent; border-radius:5px; cursor:pointer; }
/* 任务列表 */
.task-list { display:flex; flex-direction:column; }
.task-row { display:flex; align-items:center; gap:10px; padding:9px 0; border-bottom:1px solid #f5f5f5; font-size:13px; }
.task-row:last-child { border-bottom:none; }
.task-name { flex:1; }
.task-who { color:var(--color-text-muted); font-size:12px; }
.task-time { color:var(--color-text-muted); font-size:12px; white-space:nowrap; }
/* 异常列表 */
.alert-list { display:flex; flex-direction:column; }
.alert-row { display:flex; align-items:center; gap:10px; padding:9px 0; border-bottom:1px solid #f5f5f5; font-size:13px; }
.alert-row:last-child { border-bottom:none; }
.alert-dot { width:7px; height:7px; border-radius:50%; flex-shrink:0; }
.dot-danger { background:#f44336; }
.dot-warn { background:#ff9800; }
.alert-text { flex:1; }
.alert-who { font-weight:600; }
/* 徽章 */
.badge { display:inline-block; font-size:11px; padding:2px 7px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-info { background:#f0eeff; color:#534AB7; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
/* 弹窗 */
.modal-mask { position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:100; display:flex; align-items:center; justify-content:center; }
.modal-box { background:#fff; border-radius:16px; padding:28px; width:500px; box-shadow:0 8px 32px rgba(0,0,0,0.12); max-height:90vh; overflow-y:auto; }
.modal-box.small { width:400px; }
.modal-title { font-size:16px; font-weight:600; margin-bottom:20px; }
.form-grid { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
.form-item.full { grid-column:1/-1; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:5px; }
.form-item input, .form-item select, .form-item textarea { width:100%; padding:8px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.form-item input:focus, .form-item select:focus { border-color:#534AB7; }
.form-item textarea { height:72px; resize:none; }
.form-item select:disabled { background:#f5f5f5; color:#aaa; cursor:not-allowed; }
.field-tip { font-size:11px; color:#f77234; margin-top:4px; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
.btn-cancel { padding:8px 18px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
.btn-confirm { padding:8px 18px; background:#534AB7; color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
.btn-confirm:disabled { background:#aaa; cursor:not-allowed; }
.btn-rej-confirm { padding:8px 18px; background:#f44336; color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
</style>