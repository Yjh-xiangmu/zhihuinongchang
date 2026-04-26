import { createApp } from 'vue'
import App from './App.vue'
import router from './router' // 引入我们写的路由配置

// 引入我们刚才写的全局样式变量
import './assets/main.css'

const app = createApp(App)

// 告诉 Vue 使用路由
app.use(router)

// 挂载到 index.html 的 #app 节点上
app.mount('#app')