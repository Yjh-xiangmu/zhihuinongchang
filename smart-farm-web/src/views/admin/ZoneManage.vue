<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">种植区域管理</div>
        <div class="page-sub">管理全场所有种植区域，分配负责人</div>
      </div>
      <button class="btn-primary" @click="openAdd">+ 新建区域</button>
    </div>

    <div class="card">
      <div v-if="loading" class="loading-tip">加载中...</div>
      <div v-else-if="zones.length === 0" class="empty-tip">暂无区域，点击右上角新建</div>
      <table v-else class="table">
        <thead>
        <tr>
          <th>区域名称</th><th>作物</th><th>类型</th><th>面积(亩)</th>
          <th>播种日期</th><th>生长阶段</th><th>负责人</th><th>状态</th><th>操作</th>
        </tr>
        </thead>
        <tbody>
        <tr v-for="z in zones" :key="z.id">
          <td class="fw">{{ z.zoneName }}</td>
          <td>{{ z.cropName || '-' }}</td>
          <td>{{ z.zoneType || '-' }}</td>
          <td>{{ z.area || '-' }}</td>
          <td>{{ fmtDate(z.plantDate) }}</td>
          <td><span class="badge badge-info">{{ z.growthStage || '-' }}</span></td>
          <td>{{ z.managerName || '未指定' }}</td>
          <td><span :class="['badge', statusBadge(z.status)]">{{ statusLabel(z.status) }}</span></td>
          <td class="actions">
            <button class="btn-link" @click="openAssignWorkers(z)">分配员工</button>
            <button class="btn-link" @click="openEdit(z)">编辑</button>
            <button class="btn-link danger" @click="deleteZone(z)">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="modal-mask" @click.self="showModal=false">
      <div class="modal-box">
        <div class="modal-title">{{ isEdit ? '编辑区域' : '新建区域' }}</div>
        <div class="form-grid">
          <div class="form-item">
            <label>区域名称 *</label>
            <input v-model="form.zoneName" placeholder="如：A区大棚1号" />
          </div>
          <div class="form-item">
            <label>种植作物</label>
            <input v-model="form.cropName" placeholder="如：西红柿" />
          </div>
          <div class="form-item">
            <label>区域类型</label>
            <select v-model="form.zoneType">
              <option>大棚</option><option>温室</option><option>露天</option><option>水培</option>
            </select>
          </div>
          <div class="form-item">
            <label>面积（亩）</label>
            <input v-model="form.area" type="number" placeholder="如：2.5" />
          </div>
          <div class="form-item">
            <label>目标产量（kg）</label>
            <input v-model="form.targetYield" type="number" placeholder="如：3000" />
          </div>
          <div class="form-item">
            <label>播种日期</label>
            <input v-model="form.plantDate" type="date" />
          </div>
          <div class="form-item">
            <label>生长阶段</label>
            <select v-model="form.growthStage">
              <option>播种</option><option>缓苗期</option><option>开花期</option><option>结果期</option><option>采收</option>
            </select>
          </div>
          <div class="form-item">
            <label>负责人</label>
            <select v-model="form.managerId">
              <option :value="null">请选择</option>
              <option v-for="m in managers" :key="m.id" :value="m.id">{{ m.realName }}</option>
            </select>
          </div>
          <div class="form-item">
            <label>状态</label>
            <select v-model="form.status">
              <option value="NORMAL">正常</option>
              <option value="WARNING">异常</option>
              <option value="HARVESTING">采收中</option>
            </select>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showModal=false">取消</button>
          <button class="btn-primary" @click="submit" :disabled="saving">{{ saving ? '保存中...' : '确认保存' }}</button>
        </div>
      </div>
    </div>

    <div v-if="showAssignModal" class="modal-mask" @click.self="showAssignModal=false">
      <div class="modal-box" style="width:400px;">
        <div class="modal-title">分配员工 - {{ currentZone?.zoneName }}</div>
        <div class="form-item">
          <label>选择分配到该区域的员工（可多选）</label>
          <div style="max-height: 200px; overflow-y: auto; border: 1px solid var(--color-border); padding: 10px; border-radius: var(--radius-md);">
            <label v-for="w in allWorkers" :key="w.id" style="display: flex; align-items: center; gap: 8px; margin-bottom: 8px; cursor: pointer;">
              <input type="checkbox" :value="w.id" v-model="selectedWorkerIds" style="width: auto; margin: 0;">
              <span style="font-size: 13px; color: #333;">{{ w.realName }} ({{ w.username }})</span>
            </label>
            <div v-if="allWorkers.length === 0" style="color: #999; font-size: 12px; text-align: center;">暂无普通员工</div>
          </div>
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showAssignModal=false">取消</button>
          <button class="btn-primary" @click="submitAssign">确认分配</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { zoneApi, userApi } from '@/api.js'

const zones = ref([])
const managers = ref([])
const loading = ref(false)
const showModal = ref(false)
const isEdit = ref(false)
const saving = ref(false)
const form = ref({})

// 分配员工相关
const showAssignModal = ref(false)
const currentZone = ref(null)
const allWorkers = ref([])
const selectedWorkerIds = ref([])

onMounted(async () => {
  loading.value = true
  await loadZones()
  await loadManagers()
  loading.value = false
})

async function loadZones() {
  const res = await zoneApi.listAll()
  if (res.data.code === 200) zones.value = res.data.data || []
}
async function loadManagers() {
  const res = await userApi.listByRole('MANAGER')
  if (res.data.code === 200) managers.value = res.data.data || []
}

function openAdd() {
  isEdit.value = false
  form.value = { zoneName:'', cropName:'', zoneType:'大棚', area:'', targetYield:'', plantDate:'', growthStage:'播种', managerId:null, status:'NORMAL' }
  showModal.value = true
}
function openEdit(z) {
  isEdit.value = true
  form.value = { ...z, plantDate: z.plantDate ? z.plantDate.substring(0,10) : '' }
  showModal.value = true
}
async function submit() {
  if (!form.value.zoneName) { alert('请填写区域名称'); return }
  saving.value = true
  try {
    if (isEdit.value) await zoneApi.update(form.value)
    else await zoneApi.add(form.value)
    showModal.value = false
    await loadZones()
  } catch(e) { alert('操作失败') }
  finally { saving.value = false }
}
async function deleteZone(z) {
  if (!confirm(`确认删除【${z.zoneName}】？`)) return
  await zoneApi.remove(z.id)
  await loadZones()
}

// 打开分配员工弹窗
async function openAssignWorkers(zone) {
  currentZone.value = zone
  selectedWorkerIds.value = []
  showAssignModal.value = true

  // 查询所有普通员工
  const uRes = await userApi.listByRole('WORKER')
  if (uRes.data.code === 200) allWorkers.value = uRes.data.data || []

  // 查询该区域当前绑定的员工进行回显
  const wRes = await zoneApi.getWorkers(zone.id)
  if (wRes.data.code === 200) {
    selectedWorkerIds.value = (wRes.data.data || []).map(w => w.id)
  }
}

// 提交分配
async function submitAssign() {
  try {
    await zoneApi.setWorkers(currentZone.value.id, selectedWorkerIds.value)
    showAssignModal.value = false
    alert('员工分配成功')
  } catch(e) {
    alert('分配失败')
  }
}

const statusLabel = s => ({NORMAL:'正常',WARNING:'异常',HARVESTING:'采收中'}[s]||s)
const statusBadge = s => ({NORMAL:'badge-ok',WARNING:'badge-warn',HARVESTING:'badge-info'}[s]||'')
const fmtDate = d => d ? String(d).substring(0,10) : '-'
</script>

<style scoped>
.page-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:20px; }
.page-title { font-size:18px; font-weight:600; color:var(--color-text-primary); }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.loading-tip, .empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.table { width:100%; border-collapse:collapse; font-size:13px; }
.table th { padding:12px 16px; background:#fafafa; color:var(--color-text-muted); font-weight:500; text-align:left; border-bottom:1px solid var(--color-border); white-space:nowrap; }
.table td { padding:12px 16px; border-bottom:1px solid #f5f5f5; vertical-align:middle; }
.table tr:last-child td { border-bottom:none; }
.table tr:hover td { background:#fafffe; }
.fw { font-weight:500; color:var(--color-text-primary); }
.actions { display:flex; gap:8px; }
.btn-link { font-size:12px; color:var(--color-primary); background:none; border:none; cursor:pointer; padding:2px 4px; }
.btn-link.danger { color:#f44336; }
.btn-link:hover { text-decoration:underline; }
.badge { display:inline-block; font-size:11px; padding:2px 8px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-warn { background:#fff3e0; color:#f77234; }
.badge-info { background:#e8f0fe; color:#1a73e8; }
.btn-primary { padding:8px 18px; background:var(--color-primary); color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; font-weight:500; }
.btn-primary:disabled { background:#aaa; cursor:not-allowed; }
.modal-mask { position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:100; display:flex; align-items:center; justify-content:center; }
.modal-box { background:#fff; border-radius:16px; padding:28px; width:560px; box-shadow:0 8px 32px rgba(0,0,0,0.12); max-height:90vh; overflow-y:auto; }
.modal-title { font-size:16px; font-weight:600; margin-bottom:20px; }
.form-grid { display:grid; grid-template-columns:1fr 1fr; gap:14px; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:5px; }
.form-item input, .form-item select { width:100%; padding:8px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.form-item input:focus, .form-item select:focus { border-color:var(--color-primary); }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
.btn-cancel { padding:8px 18px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
</style>