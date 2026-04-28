<template>
  <div class="worker-home">

    <div class="section">
      <div class="section-header">
        <span class="section-title">今日任务</span>
        <span class="badge badge-info">{{ pendingTasks.length }} 待办</span>
      </div>
      <div v-if="tasks.length === 0" class="empty-tip">暂无任务，等待负责人派发</div>
      <div class="task-list">
        <div v-for="t in tasks" :key="t.id" class="task-card">
          <div class="task-card-top">
            <div>
              <div class="task-name">{{ t.taskName }}</div>
              <div class="task-zone">{{ t.zoneName }} {{ t.rowNo ? '· ' + t.rowNo : '' }}</div>
            </div>
            <span :class="['badge', taskStatusBadge(t.status)]">{{ taskStatusLabel(t.status) }}</span>
          </div>
          <div class="task-footer">
            <span class="task-time">截止：{{ formatDateTime(t.deadline) }}</span>
            <button
                v-if="t.status === 'PENDING'"
                class="btn-submit"
                @click="openRecordForm(t)"
            >
              提交记录
            </button>
          </div>
        </div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <span class="section-title">消息通知</span>
        <button v-if="notifications.length > 0" class="btn-readall" @click="markAllRead">全部已读</button>
      </div>
      <div v-if="notifications.length === 0" class="empty-tip">暂无消息</div>
      <div class="notif-list">
        <div
            v-for="n in notifications.slice(0, 8)"
            :key="n.id"
            :class="['notif-row', { unread: n.isRead === 0 }]"
            @click="markRead(n)"
        >
          <div :class="['notif-dot', notifDotColor(n.type)]"></div>
          <div class="notif-body">
            <div class="notif-title">{{ n.title }}</div>
            <div class="notif-content">{{ n.content }}</div>
          </div>
          <div class="notif-time">{{ formatDateTime(n.createTime) }}</div>
        </div>
      </div>
    </div>

    <div class="section">
      <div class="section-header">
        <span class="section-title">历史提交记录</span>
      </div>
      <div v-if="myRecords.length === 0" class="empty-tip">暂未提交过记录</div>
      <div class="record-list">
        <div v-for="r in myRecords.slice(0, 5)" :key="r.id" class="record-row">
          <div class="record-info">
            <span class="record-type">{{ recordTypeLabel(r.recordType) }}</span>
            <span class="record-zone">{{ r.zoneName }}</span>
          </div>
          <div class="record-content">{{ parseContent(r.content) }}</div>
          <span :class="['badge', auditBadge(r.auditStatus)]">{{ auditLabel(r.auditStatus) }}</span>
          <span class="record-time">{{ formatDateTime(r.createTime) }}</span>
        </div>
      </div>
    </div>

    <div v-if="showRecordForm" class="modal-mask" @click.self="showRecordForm = false">
      <div class="modal-box">
        <div class="modal-title">提交任务记录</div>
        <div class="modal-task-info">任务：{{ currentTask?.taskName }}</div>

        <div class="form-item">
          <label>记录类型</label>
          <select v-model="newRecord.recordType">
            <option value="GROWTH">生长记录</option>
            <option value="WATER">浇水记录</option>
            <option value="FERTILIZER">施肥记录</option>
            <option value="HARVEST">采收记录</option>
          </select>
        </div>

        <template v-if="newRecord.recordType === 'GROWTH'">
          <div class="form-row">
            <div class="form-item half">
              <label>平均株高 (cm)</label>
              <input v-model="growthForm.plantHeight" type="number" placeholder="如：45" />
            </div>
            <div class="form-item half">
              <label>生长状态</label>
              <select v-model="growthForm.growth">
                <option value="优">优</option>
                <option value="良">良</option>
                <option value="中">中</option>
                <option value="差">差</option>
              </select>
            </div>
          </div>
          <div class="form-item">
            <label>叶色</label>
            <div class="radio-row">
              <span
                  v-for="opt in ['正常', '偏黄', '偏深', '其他']"
                  :key="opt"
                  :class="['radio-opt', { sel: growthForm.leafColor === opt }]"
                  @click="growthForm.leafColor = opt"
              >{{ opt }}</span>
            </div>
          </div>
        </template>

        <template v-if="newRecord.recordType === 'FERTILIZER'">
          <div class="form-item">
            <label>施肥用量</label>
            <input v-model="fertilizerForm.amount" placeholder="如：20kg" />
          </div>
        </template>

        <template v-if="newRecord.recordType === 'HARVEST'">
          <div class="form-item">
            <label>采收批次号 *</label>
            <input v-model="harvestForm.batchNo" placeholder="如：B2024032501" />
          </div>
          <div class="form-item">
            <label>总产量 (kg) *</label>
            <input v-model="harvestForm.yield" type="number" placeholder="实际采收总重量" />
          </div>
          <div class="form-row">
            <div class="form-item half">
              <label>A级产量 (kg)</label>
              <input v-model="harvestForm.gradeA" type="number" placeholder="0" />
            </div>
            <div class="form-item half">
              <label>B级产量 (kg)</label>
              <input v-model="harvestForm.gradeB" type="number" placeholder="0" />
            </div>
          </div>
          <div class="form-item">
            <label>C级产量 (kg)</label>
            <input v-model="harvestForm.gradeC" type="number" placeholder="0" />
          </div>
        </template>

        <div class="form-item">
          <label>备注（选填）</label>
          <textarea v-model="remarkText" placeholder="其他补充说明..."></textarea>
        </div>

        <div class="modal-footer">
          <button class="btn-cancel" @click="showRecordForm = false">取消</button>
          <button class="btn-confirm btn-green" @click="submitRecord" :disabled="submitting">
            {{ submitting ? '提交中...' : '确认提交' }}
          </button>
        </div>
      </div>
    </div>

    <button class="fab-report" @click="showAnomalyForm = true">+ 上报异常</button>

    <div v-if="showAnomalyForm" class="modal-mask" @click.self="showAnomalyForm = false">
      <div class="modal-box">
        <div class="modal-title">上报异常问题</div>
        <div class="form-item">
          <label>异常类型 *</label>
          <select v-model="newAnomaly.anomalyType">
            <option value="PEST">病虫害</option>
            <option value="DEVICE">设备损坏</option>
            <option value="GROWTH">生长异常</option>
            <option value="OTHER">其他</option>
          </select>
        </div>
        <div class="form-item">
          <label>区域ID *</label>
          <input v-model="newAnomaly.zoneId" type="number" placeholder="输入发现问题的区域ID" />
        </div>
        <div class="form-item">
          <label>问题描述 *</label>
          <textarea v-model="newAnomaly.description" placeholder="详细描述发现的问题..."></textarea>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showAnomalyForm = false">取消</button>
          <button class="btn-confirm btn-green" @click="submitAnomaly">确认上报</button>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { ref, computed, onMounted, reactive } from 'vue'
import { taskApi, recordApi, anomalyApi, notificationApi, harvestApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const workerId = userInfo.id

const tasks = ref([])
const notifications = ref([])
const myRecords = ref([])

const showRecordForm = ref(false)
const showAnomalyForm = ref(false)
const currentTask = ref(null)
const submitting = ref(false)
const remarkText = ref('')

const newRecord = reactive({ recordType: 'GROWTH', taskId: null, zoneId: null, workerId: workerId })
const growthForm = reactive({ plantHeight: '', leafColor: '正常', growth: '良' })
const fertilizerForm = reactive({ amount: '' })
const harvestForm = reactive({ batchNo: '', yield: '', gradeA: '', gradeB: '', gradeC: '' })
const newAnomaly = reactive({ anomalyType: 'PEST', zoneId: null, description: '', reporterId: workerId })

onMounted(async () => {
  await loadTasks()
  await loadNotifications()
  await loadMyRecords()
})

async function loadTasks() {
  try {
    const res = await taskApi.listByWorker(workerId)
    if (res.data.code === 200) tasks.value = res.data.data || []
  } catch (e) { console.error(e) }
}

async function loadNotifications() {
  try {
    const res = await notificationApi.list(workerId)
    if (res.data.code === 200) notifications.value = res.data.data || []
  } catch (e) { console.error(e) }
}

async function loadMyRecords() {
  try {
    const res = await recordApi.listByWorker(workerId)
    if (res.data.code === 200) myRecords.value = res.data.data || []
  } catch (e) { console.error(e) }
}

function openRecordForm(task) {
  currentTask.value = task
  newRecord.taskId = task.id
  newRecord.zoneId = task.zoneId
  newRecord.recordType = 'GROWTH'
  remarkText.value = ''
  harvestForm.batchNo = ''
  harvestForm.yield = ''
  harvestForm.gradeA = ''
  harvestForm.gradeB = ''
  harvestForm.gradeC = ''
  showRecordForm.value = true
}

async function submitRecord() {
  submitting.value = true
  try {
    let content = ''
    if (newRecord.recordType === 'GROWTH') {
      content = JSON.stringify({
        plant_height: growthForm.plantHeight,
        leaf_color: growthForm.leafColor,
        growth: growthForm.growth,
        remark: remarkText.value
      })
    } else if (newRecord.recordType === 'FERTILIZER') {
      content = JSON.stringify({ amount: fertilizerForm.amount, remark: remarkText.value })
    } else if (newRecord.recordType === 'HARVEST') {
      if (!harvestForm.yield || !harvestForm.batchNo) {
        alert('请填写批次号和总产量')
        submitting.value = false
        return
      }
      // 保存农事记录展示
      content = JSON.stringify({
        batchNo: harvestForm.batchNo,
        yield: harvestForm.yield + 'kg',
        gradeA: (harvestForm.gradeA || 0) + 'kg',
        gradeB: (harvestForm.gradeB || 0) + 'kg',
        gradeC: (harvestForm.gradeC || 0) + 'kg',
        remark: remarkText.value
      })

      // 同步调用 harvestApi.add 接口，将详细数据存入采收记录表
      await harvestApi.add({
        zoneId: newRecord.zoneId,
        workerId: workerId,
        batchNo: harvestForm.batchNo,
        yield: harvestForm.yield,
        gradeA: harvestForm.gradeA || 0,
        gradeB: harvestForm.gradeB || 0,
        gradeC: harvestForm.gradeC || 0,
        remark: remarkText.value
      })
    } else {
      content = JSON.stringify({ remark: remarkText.value })
    }

    await recordApi.add({ ...newRecord, content })
    showRecordForm.value = false
    await loadTasks()
    await loadMyRecords()
  } catch (e) {
    alert('提交失败，请检查后端')
  } finally {
    submitting.value = false
  }
}

async function submitAnomaly() {
  if (!newAnomaly.description || !newAnomaly.zoneId) { alert('请填写区域ID和问题描述'); return }
  try {
    await anomalyApi.add({ ...newAnomaly })
    showAnomalyForm.value = false
    alert('上报成功，负责人将尽快处理')
  } catch (e) { alert('上报失败') }
}

async function markRead(n) {
  if (n.isRead === 1) return
  try {
    await notificationApi.markRead(n.id)
    n.isRead = 1
  } catch (e) {}
}

async function markAllRead() {
  try {
    await notificationApi.markAllRead(workerId)
    notifications.value.forEach(n => n.isRead = 1)
  } catch (e) {}
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

const pendingTasks = computed(() => tasks.value.filter(t => t.status === 'PENDING'))

function taskStatusLabel(s) {
  return { PENDING: '待办', DONE: '已完成', LATE: '超时' }[s] || s
}
function taskStatusBadge(s) {
  return { PENDING: 'badge-info', DONE: 'badge-ok', LATE: 'badge-danger' }[s] || ''
}
function recordTypeLabel(t) {
  return { GROWTH: '生长记录', WATER: '浇水', FERTILIZER: '施肥', HARVEST: '采收' }[t] || t
}
function auditLabel(s) {
  return { PENDING: '待审核', PASSED: '已通过', REJECTED: '已驳回' }[s] || s
}
function auditBadge(s) {
  return { PENDING: 'badge-info', PASSED: 'badge-ok', REJECTED: 'badge-danger' }[s] || ''
}
function notifDotColor(type) {
  return { AUDIT_PASS: 'dot-ok', AUDIT_REJECT: 'dot-danger', TASK_TIMEOUT: 'dot-warn', ANOMALY: 'dot-ok', TASK_NEW: 'dot-info' }[type] || 'dot-info'
}
function formatDateTime(d) {
  if (!d) return '未设置'
  return new Date(d).toLocaleString('zh-CN', { month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })
}
</script>

<style scoped>
.worker-home { position: relative; padding-bottom: 72px; }

.section { background: #fff; border-radius: 10px; padding: 16px 20px; margin-bottom: 14px; border: 1px solid #f0f0f0; }
.section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.section-title { font-size: 14px; font-weight: 600; }
.empty-tip { font-size: 13px; color: #86909c; text-align: center; padding: 16px 0; }

.task-list { display: flex; flex-direction: column; gap: 10px; }
.task-card { background: #fdfdfd; border: 1px solid #eee; border-radius: 10px; padding: 12px 14px; }
.task-card-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 10px; }
.task-name { font-size: 13px; font-weight: 600; color: var(--color-text-primary); }
.task-zone { font-size: 12px; color: #86909c; margin-top: 2px; }
.task-footer { display: flex; justify-content: space-between; align-items: center; }
.task-time { font-size: 12px; color: #aaa; }
.btn-submit { font-size: 12px; padding: 5px 14px; background: var(--color-primary); color: #fff; border: none; border-radius: 6px; cursor: pointer; }

.btn-readall { font-size: 11px; padding: 3px 10px; border: 1px solid #ddd; background: #fff; border-radius: 5px; cursor: pointer; color: #666; }
.notif-list { display: flex; flex-direction: column; }
.notif-row { display: flex; align-items: flex-start; gap: 10px; padding: 9px 0; border-bottom: 1px solid #f5f5f5; cursor: pointer; }
.notif-row:last-child { border-bottom: none; }
.notif-row.unread { background: #fafffe; }
.notif-dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; margin-top: 5px; }
.dot-ok { background: #1D9E75; }
.dot-warn { background: #ff9800; }
.dot-danger { background: #f44336; }
.dot-info { background: #1a73e8; }
.notif-body { flex: 1; }
.notif-title { font-size: 13px; font-weight: 500; }
.notif-content { font-size: 12px; color: #666; margin-top: 1px; }
.notif-time { font-size: 11px; color: #aaa; white-space: nowrap; }

.record-list { display: flex; flex-direction: column; }
.record-row { display: flex; align-items: center; gap: 10px; padding: 8px 0; border-bottom: 1px solid #f5f5f5; font-size: 12px; }
.record-row:last-child { border-bottom: none; }
.record-info { display: flex; flex-direction: column; min-width: 64px; flex-shrink: 0; }
.record-type { font-weight: 500; color: var(--color-text-primary); }
.record-zone { color: #86909c; font-size: 11px; }
.record-content { flex: 1; min-width: 0; color: #666; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.record-time { flex-shrink: 0; color: #aaa; font-size: 11px; white-space: nowrap; }

.fab-report { position: fixed; bottom: 24px; right: 24px; background: #f44336; color: #fff; border: none; border-radius: 24px; padding: 12px 20px; font-size: 14px; font-weight: 600; cursor: pointer; box-shadow: 0 4px 16px rgba(244,67,54,0.3); z-index: 50; }
.fab-report:hover { background: #d32f2f; }

.badge { flex-shrink: 0; display: inline-block; font-size: 11px; padding: 2px 7px; border-radius: 20px; font-weight: 500; }
.badge-ok { background: #e8f5f0; color: #1D9E75; }
.badge-warn { background: #fff3e0; color: #f77234; }
.badge-info { background: #f0eeff; color: #534AB7; }
.badge-danger { background: #fde8e8; color: #d32f2f; }

.modal-mask { position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 100; display: flex; align-items: center; justify-content: center; }
.modal-box { background: #fff; border-radius: 16px; padding: 24px 28px; width: 440px; max-height: 90vh; overflow-y: auto; box-shadow: 0 8px 32px rgba(0,0,0,0.12); }
.modal-title { font-size: 16px; font-weight: 600; margin-bottom: 6px; }
.modal-task-info { font-size: 12px; color: #86909c; margin-bottom: 16px; }
.form-item { margin-bottom: 14px; }
.form-item label { display: block; font-size: 12px; color: #666; margin-bottom: 5px; }
.form-item input, .form-item select, .form-item textarea { width: 100%; padding: 9px 12px; border: 1px solid #e5e6eb; border-radius: 8px; font-size: 13px; outline: none; }
.form-item textarea { resize: none; height: 72px; }
.form-row { display: flex; gap: 12px; }
.form-item.half { flex: 1; }
.radio-row { display: flex; gap: 8px; flex-wrap: wrap; }
.radio-opt { font-size: 12px; padding: 5px 12px; border-radius: 20px; border: 1px solid #ddd; cursor: pointer; color: #666; }
.radio-opt.sel { border-color: var(--color-primary); color: var(--color-primary); background: #e8f5f0; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; margin-top: 20px; }
.btn-cancel { padding: 8px 18px; border: 1px solid #ddd; background: #fff; border-radius: 8px; cursor: pointer; font-size: 13px; }
.btn-confirm { padding: 8px 18px; background: #534AB7; color: #fff; border: none; border-radius: 8px; cursor: pointer; font-size: 13px; }
.btn-confirm.btn-green { background: var(--color-primary); }
.btn-confirm:disabled { background: #aaa; cursor: not-allowed; }
</style>