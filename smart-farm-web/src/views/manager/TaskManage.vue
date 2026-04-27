<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">任务管理</div>
        <div class="page-sub">派发并跟踪区域内所有工单</div>
      </div>
      <button class="btn-primary" @click="openAdd">+ 派发任务</button>
    </div>

    <div class="tab-row">
      <span v-for="t in tabs" :key="t.val" :class="['tab',{active:filterStatus===t.val}]" @click="filterStatus=t.val">
        {{ t.label }} <span class="tab-count">{{ countByStatus(t.val) }}</span>
      </span>
    </div>

    <div class="card">
      <div v-if="filtered.length===0" class="empty-tip">暂无任务</div>
      <div v-for="t in filtered" :key="t.id" class="task-row">
        <div class="task-left">
          <span :class="['badge', taskBadge(t.status)]">{{ taskLabel(t.status) }}</span>
          <div class="task-info">
            <div class="task-name">{{ t.taskName }}</div>
            <div class="task-meta">{{ t.zoneName }} · {{ typeLabel(t.taskType) }} · 指派给 {{ t.assigneeName||'未指派' }} · 截止 {{ fmtDT(t.deadline) }}</div>
            <div v-if="t.description" class="task-desc">{{ t.description }}</div>
          </div>
        </div>
        <div class="task-right">
          <button v-if="t.status!=='DONE'" class="btn-sm" @click="markDone(t)">标记完成</button>
          <button class="btn-sm danger" @click="deleteTask(t)">删除</button>
        </div>
      </div>
    </div>

    <!-- 派发弹窗 -->
    <div v-if="showModal" class="modal-mask" @click.self="showModal=false">
      <div class="modal-box">
        <div class="modal-title">派发新任务</div>
        <div class="form-grid">
          <div class="form-item full">
            <label>任务名称 *</label>
            <input v-model="form.taskName" placeholder="如：第1-3排生长巡检" />
          </div>
          <div class="form-item">
            <label>任务类型</label>
            <select v-model="form.taskType">
              <option value="GROWTH">生长巡检</option>
              <option value="WATER">浇水</option>
              <option value="FERTILIZER">施肥</option>
              <option value="PEST">病虫害检查</option>
              <option value="HARVEST">采收</option>
            </select>
          </div>
          <div class="form-item">
            <label>指派员工</label>
            <select v-model="form.assigneeId">
              <option :value="null">请选择</option>
              <option v-for="w in workers" :key="w.id" :value="w.id">{{ w.realName }}</option>
            </select>
          </div>
          <div class="form-item">
            <label>所属区域</label>
            <select v-model="form.zoneId">
              <option v-for="z in zones" :key="z.id" :value="z.id">{{ z.zoneName }}</option>
            </select>
          </div>
          <div class="form-item">
            <label>截止时间</label>
            <input type="datetime-local" v-model="form.deadline" />
          </div>
          <div class="form-item full">
            <label>作业排数/区域</label>
            <input v-model="form.rowNo" placeholder="如：第1-3排，可不填" />
          </div>
          <div class="form-item full">
            <label>任务描述</label>
            <input v-model="form.description" placeholder="具体要求和注意事项" />
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showModal=false">取消</button>
          <button class="btn-primary" @click="submit" :disabled="saving">{{ saving?'派发中...':'确认派发' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { taskApi, userApi, zoneApi } from '@/api.js'

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const tasks = ref([])
const workers = ref([])
const zones = ref([])
const filterStatus = ref('')
const showModal = ref(false)
const saving = ref(false)
const form = ref({})

const tabs = [
  { val:'', label:'全部' },
  { val:'PENDING', label:'待办' },
  { val:'DONE', label:'已完成' },
  { val:'LATE', label:'超时' },
]

onMounted(async () => {
  const [r1,r2,r3] = await Promise.all([
    zoneApi.listByManager(userInfo.id),
    userApi.listByRole('WORKER'),
    zoneApi.listByManager(userInfo.id),
  ])
  if (r1.data.code===200) zones.value = r1.data.data||[]
  if (r2.data.code===200) workers.value = r2.data.data||[]
  await loadTasks()
})

async function loadTasks() {
  const allTasks = []
  for (const z of zones.value) {
    const res = await taskApi.listByZone(z.id)
    if (res.data.code===200) allTasks.push(...(res.data.data||[]))
  }
  tasks.value = allTasks.sort((a,b) => new Date(b.createTime)-new Date(a.createTime))
}

const filtered = computed(() => filterStatus.value ? tasks.value.filter(t=>t.status===filterStatus.value) : tasks.value)
const countByStatus = s => s ? tasks.value.filter(t=>t.status===s).length : tasks.value.length

function openAdd() {
  form.value = { taskName:'', taskType:'GROWTH', assigneeId:null, zoneId: zones.value[0]?.id||null, deadline:'', rowNo:'', description:'', creatorId: userInfo.id }
  showModal.value = true
}

async function submit() {
  if (!form.value.taskName) { alert('请填写任务名称'); return }
  saving.value = true
  try {
    await taskApi.add(form.value)
    showModal.value = false
    await loadTasks()
  } catch(e) { alert('派发失败') }
  finally { saving.value = false }
}

async function markDone(t) {
  await taskApi.update({ id: t.id, status:'DONE' })
  await loadTasks()
}

async function deleteTask(t) {
  if (!confirm(`确认删除任务【${t.taskName}】？`)) return
  await taskApi.remove(t.id)
  await loadTasks()
}

const taskLabel = s => ({PENDING:'待办',DONE:'已完成',LATE:'超时'}[s]||s)
const taskBadge = s => ({PENDING:'badge-info',DONE:'badge-ok',LATE:'badge-danger'}[s]||'')
const typeLabel = t => ({GROWTH:'生长巡检',WATER:'浇水',FERTILIZER:'施肥',PEST:'病虫害检查',HARVEST:'采收'}[t]||t)
const fmtDT = d => d ? new Date(d).toLocaleString('zh-CN',{month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}) : '未设置'
</script>

<style scoped>
.page-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:16px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.tab-row { display:flex; gap:4px; margin-bottom:16px; border-bottom:1px solid var(--color-border); }
.tab { padding:8px 16px; font-size:13px; color:var(--color-text-regular); cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-1px; transition:var(--transition); }
.tab:hover { color:var(--color-text-primary); }
.tab.active { color:#534AB7; border-bottom-color:#534AB7; font-weight:600; }
.tab-count { font-size:11px; background:#f0f0f0; border-radius:10px; padding:1px 6px; margin-left:4px; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.task-row { display:flex; justify-content:space-between; align-items:flex-start; padding:14px 20px; border-bottom:1px solid #f5f5f5; gap:12px; }
.task-row:last-child { border-bottom:none; }
.task-row:hover { background:#fafffe; }
.task-left { display:flex; align-items:flex-start; gap:12px; flex:1; }
.task-name { font-size:13px; font-weight:500; color:var(--color-text-primary); }
.task-meta { font-size:12px; color:var(--color-text-muted); margin-top:3px; }
.task-desc { font-size:12px; color:var(--color-text-regular); margin-top:3px; }
.task-right { display:flex; gap:6px; flex-shrink:0; }
.badge { display:inline-block; font-size:11px; padding:2px 8px; border-radius:20px; font-weight:500; white-space:nowrap; flex-shrink:0; margin-top:2px; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-info { background:#f0eeff; color:#534AB7; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
.btn-sm { font-size:12px; padding:4px 12px; border:1px solid #534AB7; color:#534AB7; background:transparent; border-radius:var(--radius-md); cursor:pointer; white-space:nowrap; }
.btn-sm.danger { border-color:#f44336; color:#f44336; }
.btn-primary { padding:8px 18px; background:#534AB7; color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; font-weight:500; }
.btn-primary:disabled { background:#aaa; cursor:not-allowed; }
.modal-mask { position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:100; display:flex; align-items:center; justify-content:center; }
.modal-box { background:#fff; border-radius:16px; padding:28px; width:520px; box-shadow:0 8px 32px rgba(0,0,0,0.12); }
.modal-title { font-size:16px; font-weight:600; margin-bottom:20px; }
.form-grid { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
.form-item.full { grid-column:1/-1; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:5px; }
.form-item input, .form-item select { width:100%; padding:8px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
.btn-cancel { padding:8px 18px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
</style>