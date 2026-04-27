<template>
  <div>
    <div class="page-header">
      <div>
        <div class="page-title">账号管理</div>
        <div class="page-sub">管理系统所有用户，分配角色权限</div>
      </div>
      <button class="btn-primary" @click="openAdd">+ 新建账号</button>
    </div>

    <div class="tab-row">
      <span v-for="r in roleFilters" :key="r.val" :class="['tab', { active: filterRole===r.val }]" @click="filterRole=r.val">
        {{ r.label }} <span class="tab-count">{{ countByRole(r.val) }}</span>
      </span>
    </div>

    <div class="card">
      <table class="table">
        <thead>
        <tr><th>ID</th><th>账号</th><th>姓名</th><th>角色</th><th>操作</th></tr>
        </thead>
        <tbody>
        <tr v-for="u in filteredUsers" :key="u.id">
          <td class="muted">{{ u.id }}</td>
          <td class="fw mono">{{ u.username }}</td>
          <td>{{ u.realName }}</td>
          <td><span :class="['badge', roleBadge(u.role)]">{{ roleLabel(u.role) }}</span></td>
          <td class="actions">
            <button class="btn-link" @click="openEdit(u)">编辑</button>
            <button class="btn-link danger" @click="deleteUser(u)" :disabled="u.id===currentUser.id">删除</button>
          </td>
        </tr>
        </tbody>
      </table>
      <div v-if="filteredUsers.length===0" class="empty-tip">暂无用户</div>
    </div>

    <div v-if="showModal" class="modal-mask" @click.self="showModal=false">
      <div class="modal-box">
        <div class="modal-title">{{ isEdit ? '编辑账号' : '新建账号' }}</div>
        <div class="form-item">
          <label>账号（登录用）*</label>
          <input v-model="form.username" placeholder="英文/数字，如: xiaowang" />
        </div>
        <div class="form-item">
          <label>姓名 *</label>
          <input v-model="form.realName" placeholder="真实姓名" />
        </div>
        <div class="form-item">
          <label>角色 *</label>
          <select v-model="form.role">
            <option value="ADMIN">管理员</option>
            <option value="MANAGER">区域负责人</option>
            <option value="WORKER">普通员工</option>
          </select>
        </div>
        <div class="form-item">
          <label>{{ isEdit ? '新密码（留空不修改）' : '密码 *' }}</label>
          <input v-model="form.password" type="password" placeholder="默认 123456" />
        </div>
        <div class="modal-footer">
          <button class="btn-cancel" @click="showModal=false">取消</button>
          <button class="btn-primary" @click="submit" :disabled="saving">{{ saving?'保存中...':'确认保存' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { userApi } from '@/api.js'

const users = ref([])
const filterRole = ref('')
const showModal = ref(false)
const isEdit = ref(false)
const saving = ref(false)
const form = ref({})
const currentUser = JSON.parse(localStorage.getItem('userInfo') || '{}')

const roleFilters = [
  { val:'', label:'全部' },
  { val:'ADMIN', label:'管理员' },
  { val:'MANAGER', label:'负责人' },
  { val:'WORKER', label:'员工' },
]

onMounted(async () => {
  const res = await userApi.listAll()
  if (res.data.code === 200) users.value = res.data.data || []
})

const filteredUsers = computed(() => filterRole.value ? users.value.filter(u=>u.role===filterRole.value) : users.value)
const countByRole = r => r ? users.value.filter(u=>u.role===r).length : users.value.length

function openAdd() {
  isEdit.value = false
  form.value = { username:'', realName:'', role:'WORKER', password:'123456' }
  showModal.value = true
}
function openEdit(u) {
  isEdit.value = true
  form.value = { ...u, password:'' }
  showModal.value = true
}
async function submit() {
  if (!form.value.username || !form.value.realName) { alert('请填写完整信息'); return }
  if (!isEdit.value && !form.value.password) form.value.password = '123456'
  saving.value = true
  try {
    if (isEdit.value) await userApi.update(form.value)
    else await userApi.add(form.value)
    showModal.value = false
    const res = await userApi.listAll()
    if (res.data.code === 200) users.value = res.data.data || []
  } catch(e) { alert('操作失败') }
  finally { saving.value = false }
}
async function deleteUser(u) {
  if (!confirm(`确认删除账号【${u.username}】？`)) return
  await userApi.remove(u.id)
  users.value = users.value.filter(x=>x.id!==u.id)
}

const roleLabel = r => ({ ADMIN:'管理员', MANAGER:'区域负责人', WORKER:'普通员工' }[r]||r)
const roleBadge = r => ({ ADMIN:'badge-danger', MANAGER:'badge-purple', WORKER:'badge-ok' }[r]||'')
</script>

<style scoped>
.page-header { display:flex; justify-content:space-between; align-items:flex-start; margin-bottom:16px; }
.page-title { font-size:18px; font-weight:600; }
.page-sub { font-size:13px; color:var(--color-text-muted); margin-top:3px; }
.tab-row { display:flex; gap:4px; margin-bottom:16px; border-bottom:1px solid var(--color-border); }
.tab { padding:8px 16px; font-size:13px; color:var(--color-text-regular); cursor:pointer; border-bottom:2px solid transparent; margin-bottom:-1px; transition:var(--transition); }
.tab:hover { color:var(--color-text-primary); }
.tab.active { color:var(--color-primary); border-bottom-color:var(--color-primary); font-weight:600; }
.tab-count { font-size:11px; background:#f0f0f0; border-radius:10px; padding:1px 6px; margin-left:4px; }
.card { background:#fff; border-radius:var(--radius-lg); border:1px solid var(--color-border); overflow:hidden; }
.table { width:100%; border-collapse:collapse; font-size:13px; }
.table th { padding:12px 16px; background:#fafafa; color:var(--color-text-muted); font-weight:500; text-align:left; border-bottom:1px solid var(--color-border); }
.table td { padding:12px 16px; border-bottom:1px solid #f5f5f5; }
.table tr:last-child td { border-bottom:none; }
.table tr:hover td { background:#fafffe; }
.fw { font-weight:600; }
.mono { font-family:monospace; }
.muted { color:var(--color-text-muted); }
.empty-tip { text-align:center; padding:40px; color:var(--color-text-muted); font-size:14px; }
.actions { display:flex; gap:8px; }
.btn-link { font-size:12px; color:var(--color-primary); background:none; border:none; cursor:pointer; padding:2px; }
.btn-link.danger { color:#f44336; }
.btn-link:disabled { color:#ccc; cursor:not-allowed; }
.badge { display:inline-block; font-size:11px; padding:2px 8px; border-radius:20px; font-weight:500; }
.badge-ok { background:#e8f5f0; color:#1D9E75; }
.badge-purple { background:#f0eeff; color:#534AB7; }
.badge-danger { background:#fde8e8; color:#d32f2f; }
.btn-primary { padding:8px 18px; background:var(--color-primary); color:#fff; border:none; border-radius:var(--radius-md); cursor:pointer; font-size:13px; font-weight:500; }
.btn-primary:disabled { background:#aaa; cursor:not-allowed; }
.modal-mask { position:fixed; inset:0; background:rgba(0,0,0,0.35); z-index:100; display:flex; align-items:center; justify-content:center; }
.modal-box { background:#fff; border-radius:16px; padding:28px; width:420px; box-shadow:0 8px 32px rgba(0,0,0,0.12); }
.modal-title { font-size:16px; font-weight:600; margin-bottom:20px; }
.form-item { margin-bottom:14px; }
.form-item label { display:block; font-size:12px; color:#666; margin-bottom:5px; }
.form-item input, .form-item select { width:100%; padding:8px 10px; border:1px solid var(--color-border); border-radius:var(--radius-md); font-size:13px; outline:none; }
.form-item input:focus { border-color:var(--color-primary); }
.modal-footer { display:flex; justify-content:flex-end; gap:10px; margin-top:20px; }
.btn-cancel { padding:8px 18px; border:1px solid var(--color-border); background:#fff; border-radius:var(--radius-md); cursor:pointer; font-size:13px; }
</style>