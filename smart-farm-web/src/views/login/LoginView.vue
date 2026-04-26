<template>
  <div class="login-wrapper">
    <div class="bg-decoration"></div>

    <div class="login-card">
      <div class="login-header">
        <div class="logo">
          <div class="logo-icon"></div>
        </div>
        <h1>智慧农场系统</h1>
        <p>Smart Farm Management Platform</p>
      </div>

      <div class="login-form">
        <div class="input-group">
          <label>账号</label>
          <div class="input-wrapper">
            <input
                type="text"
                v-model="loginForm.username"
                placeholder="请输入管理员或员工账号"
            />
          </div>
        </div>

        <div class="input-group">
          <label>密码</label>
          <div class="input-wrapper">
            <input
                type="password"
                v-model="loginForm.password"
                placeholder="请输入登录密码"
            />
          </div>
        </div>

        <div class="input-group">
          <label>权限入口</label>
          <div class="role-selector">
            <div
                v-for="role in roles"
                :key="role.value"
                :class="['role-opt', { active: loginForm.role === role.value }]"
                @click="loginForm.role = role.value"
            >
              {{ role.label }}
            </div>
          </div>
        </div>

        <button class="login-button" @click="handleLogin" :disabled="loading">
          <span v-if="!loading">立即登录</span>
          <span v-else class="loading-spinner"></span>
        </button>
      </div>

      <div class="login-footer">
        <p>© 2026 智慧农场数字化管理平台</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import axios from 'axios' // 引入发请求的工具

const router = useRouter()
const loading = ref(false)

const roles = [
  { label: '管理员', value: 'ADMIN' },
  { label: '负责人', value: 'MANAGER' },
  { label: '员工', value: 'WORKER' }
]

const loginForm = reactive({
  username: '',
  password: '',
  role: 'ADMIN' // 数据库里存的是大写，这里要对应大写
})

const handleLogin = async () => {
  if (!loginForm.username || !loginForm.password) {
    alert('请输入完整的账号和密码')
    return
  }

  loading.value = true

  try {
    // 往后端发送真实的 POST 请求
    const res = await axios.post('http://localhost:8080/api/login', {
      username: loginForm.username,
      password: loginForm.password,
      role: loginForm.role
    })

    // 判断后端返回的代码
    if (res.data.code === 200) {
      // 登录成功，把用户信息存到浏览器的本地存储里（后续页面可能用到名字）
      localStorage.setItem('userInfo', JSON.stringify(res.data.data))

      // 根据角色跳转
      if (loginForm.role === 'ADMIN') router.push('/admin')
      else if (loginForm.role === 'MANAGER') router.push('/manager')
      else router.push('/worker')
    } else {
      // 登录失败，弹出后端的错误提示
      alert(res.data.msg)
    }
  } catch (error) {
    alert('网络请求失败，请检查后端是否启动')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
/* 核心容器：使用柔和的渐变色 */
.login-wrapper {
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f0f4f2;
  position: relative;
  overflow: hidden;
}

.bg-decoration {
  position: absolute;
  width: 150%;
  height: 150%;
  background: radial-gradient(circle at 20% 30%, #e1eedd 0%, transparent 40%),
  radial-gradient(circle at 80% 70%, #d8e5ff 0%, transparent 40%);
  filter: blur(80px);
  z-index: 0;
}

/* 登录卡片：磨砂玻璃质感与深度阴影 */
.login-card {
  position: relative;
  z-index: 1;
  width: 420px;
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  padding: 48px;
  border-radius: 24px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.6);
}

.login-header {
  text-align: center;
  margin-bottom: 40px;
}

.logo-icon {
  width: 48px;
  height: 48px;
  background: #1d9e75;
  border-radius: 12px;
  margin: 0 auto 16px;
  box-shadow: 0 8px 16px rgba(29, 158, 117, 0.2);
}

h1 {
  font-size: 24px;
  font-weight: 600;
  color: #1a1a1a;
  margin-bottom: 4px;
}

p {
  font-size: 13px;
  color: #86909c;
}

/* 表单细节 */
.input-group {
  margin-bottom: 24px;
}

.input-group label {
  display: block;
  font-size: 13px;
  font-weight: 500;
  color: #4e5969;
  margin-bottom: 8px;
}

.input-wrapper input {
  width: 100%;
  padding: 12px 16px;
  background: #f7f8fa;
  border: 1px solid #e5e6eb;
  border-radius: 10px;
  font-size: 14px;
  transition: all 0.2s;
  outline: none;
}

.input-wrapper input:focus {
  border-color: #1d9e75;
  background: #fff;
  box-shadow: 0 0 0 4px rgba(29, 158, 117, 0.1);
}

/* 角色选择器优化 */
.role-selector {
  display: flex;
  gap: 8px;
  background: #f7f8fa;
  padding: 4px;
  border-radius: 10px;
}

.role-opt {
  flex: 1;
  text-align: center;
  padding: 8px 0;
  font-size: 12px;
  color: #86909c;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.2s;
}

.role-opt.active {
  background: #fff;
  color: #1d9e75;
  font-weight: 600;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.05);
}

/* 按钮点击反馈 */
.login-button {
  width: 100%;
  padding: 14px;
  background: #1d9e75;
  color: #fff;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  margin-top: 12px;
  display: flex;
  justify-content: center;
  align-items: center;
  height: 50px;
}

.login-button:hover:not(:disabled) {
  background: #14805e;
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(29, 158, 117, 0.2);
}

.login-button:disabled {
  background: #94d1bc;
  cursor: not-allowed;
}

.loading-spinner {
  display: inline-block;
  width: 20px;
  height: 20px;
  border: 2px solid rgba(255,255,255,0.3);
  border-radius: 50%;
  border-top-color: #fff;
  animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.login-footer {
  margin-top: 40px;
  text-align: center;
  font-size: 12px;
  color: #c9cdd4;
}
</style>