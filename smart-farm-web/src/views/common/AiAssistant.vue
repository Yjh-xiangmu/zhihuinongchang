<template>
  <div class="ai-chat-container">
    <div class="chat-header">
      <div class="header-info">
        <span class="ai-dot">✦</span>
        <span>AI 农业助手</span>
      </div>
      <button class="clear-btn" @click="clearHistory">清空对话历史</button>
    </div>

    <div class="chat-list" ref="chatListRef">
      <div v-for="(msg, index) in messages" :key="index" :class="['chat-bubble', msg.role]">
        <div class="bubble-inner">
          <img v-if="msg.imageBase64" :src="'data:image/jpeg;base64,' + msg.imageBase64" class="msg-img" />
          <div class="msg-text">{{ msg.content }}</div>
        </div>
      </div>
      <div v-if="loading" class="chat-bubble assistant">
        <div class="bubble-inner loading-text">AI 思考中...</div>
      </div>
    </div>

    <div class="chat-input-area">
      <div v-if="previewImage" class="image-preview">
        <img :src="previewImage" />
        <span class="remove-img" @click="removeImage">×</span>
      </div>

      <div class="input-box">
        <label class="upload-btn">
          <input type="file" accept="image/*" @change="handleImageUpload" hidden />
          <span class="icon">📎 图片</span>
        </label>
        <textarea
            v-model="inputText"
            placeholder="描述作物情况或上传照片问我..."
            @keyup.enter.prevent="sendMessage"
        ></textarea>
        <button class="send-btn" @click="sendMessage" :disabled="loading || (!inputText && !base64Data)">发送</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'

const chatListRef = ref(null)
const messages = ref([])
const inputText = ref('')
const loading = ref(false)
const previewImage = ref('')
const base64Data = ref('')

const userInfo = JSON.parse(localStorage.getItem('userInfo') || '{}')
const userId = userInfo.id || 1
// 后端需要 sessionId 进行上下文关联，这里暂定一个固定的
const sessionId = 'default-session'
// 提取用户角色（根据你的后端逻辑，传入 ADMIN / MANAGER / WORKER）
const role = userInfo.role || 'WORKER'

// 获取历史记录
const loadHistory = async () => {
  try {
    const res = await fetch(`http://localhost:8080/api/ai/history?userId=${userId}&sessionId=${sessionId}`)
    const data = await res.json()
    if (data.code === 200 && data.data) {
      messages.value = data.data
      scrollToBottom()
    }
  } catch (e) {
    console.error('加载历史记录失败', e)
  }
}

// 发送消息
const sendMessage = async () => {
  if (!inputText.value.trim() && !base64Data.value) return
  if (loading.value) return

  const msgObj = {
    userId: userId,
    sessionId: sessionId,
    message: inputText.value || '请分析一下这张图片',
    imageBase64: base64Data.value || null,
    role: role
  }

  // 先把用户的消息显示在界面上
  messages.value.push({
    role: 'user',
    content: msgObj.message,
    imageBase64: msgObj.imageBase64
  })

  // 清空输入框和图片
  inputText.value = ''
  removeImage()
  loading.value = true
  scrollToBottom()

  try {
    const res = await fetch('http://localhost:8080/api/ai/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(msgObj)
    })
    const data = await res.json()
    if (data.code === 200) {
      messages.value.push({
        role: 'assistant',
        content: data.data.reply
      })
    } else {
      messages.value.push({ role: 'assistant', content: '服务异常：' + data.msg })
    }
  } catch (e) {
    messages.value.push({ role: 'assistant', content: '网络错误，请稍后再试。' })
  } finally {
    loading.value = false
    scrollToBottom()
  }
}

// 处理图片上传并转 Base64
const handleImageUpload = (e) => {
  const file = e.target.files[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = (event) => {
    // 界面预览用的完整 base64
    previewImage.value = event.target.result
    // 后端需要的纯 base64 数据（截掉 data:image/jpeg;base64,）
    base64Data.value = event.target.result.split(',')[1]
  }
  reader.readAsDataURL(file)
  e.target.value = '' // 清空 input 允许重复选同一张图
}

const removeImage = () => {
  previewImage.value = ''
  base64Data.value = ''
}

// 清空对话记录
const clearHistory = async () => {
  try {
    await fetch(`http://localhost:8080/api/ai/history?userId=${userId}&sessionId=${sessionId}`, {
      method: 'DELETE'
    })
    messages.value = []
  } catch (e) {
    console.error('清空失败', e)
  }
}

// 让聊天列表一直滚动到最底部
const scrollToBottom = () => {
  nextTick(() => {
    if (chatListRef.value) {
      chatListRef.value.scrollTop = chatListRef.value.scrollHeight
    }
  })
}

onMounted(() => {
  loadHistory()
})
</script>

<style scoped>
.ai-chat-container {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 100px);
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 12px rgba(0,0,0,0.05);
  overflow: hidden;
}

.chat-header {
  padding: 16px 20px;
  border-bottom: 1px solid var(--color-border);
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #fcfcfc;
}

.header-info {
  font-weight: 600;
  color: var(--color-text-primary);
  display: flex;
  align-items: center;
  gap: 8px;
}

.ai-dot { color: #534AB7; font-size: 16px; }

.clear-btn {
  font-size: 12px;
  color: #f56c6c;
  background: none;
  border: 1px solid #fbc4c4;
  padding: 4px 10px;
  border-radius: 4px;
  cursor: pointer;
}

.clear-btn:hover { background: #fef0f0; }

.chat-list {
  flex: 1;
  padding: 20px;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
  background: #f9fafc;
}

.chat-bubble {
  display: flex;
  max-width: 80%;
}

.chat-bubble.user {
  align-self: flex-end;
}

.chat-bubble.assistant {
  align-self: flex-start;
}

.bubble-inner {
  padding: 12px 16px;
  border-radius: 8px;
  font-size: 14px;
  line-height: 1.5;
  word-break: break-all;
}

.chat-bubble.user .bubble-inner {
  background: var(--color-primary);
  color: #fff;
  border-bottom-right-radius: 2px;
}

.chat-bubble.assistant .bubble-inner {
  background: #fff;
  color: var(--color-text-regular);
  border: 1px solid var(--color-border);
  border-bottom-left-radius: 2px;
}

.msg-img {
  max-width: 200px;
  border-radius: 4px;
  margin-bottom: 8px;
  display: block;
}

.loading-text {
  color: #999;
  font-style: italic;
}

.chat-input-area {
  padding: 16px 20px;
  background: #fff;
  border-top: 1px solid var(--color-border);
}

.image-preview {
  position: relative;
  display: inline-block;
  margin-bottom: 10px;
}

.image-preview img {
  height: 60px;
  border-radius: 4px;
  border: 1px solid var(--color-border);
}

.remove-img {
  position: absolute;
  top: -8px;
  right: -8px;
  background: rgba(0,0,0,0.5);
  color: #fff;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  font-size: 12px;
}

.input-box {
  display: flex;
  align-items: flex-end;
  gap: 12px;
}

.upload-btn {
  cursor: pointer;
  padding: 8px 12px;
  background: #f5f7fa;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  font-size: 13px;
  color: var(--color-text-regular);
  white-space: nowrap;
}

.upload-btn:hover { background: #eef0f6; }

textarea {
  flex: 1;
  height: 40px;
  min-height: 40px;
  max-height: 120px;
  padding: 10px 12px;
  border: 1px solid var(--color-border);
  border-radius: 6px;
  resize: vertical;
  font-size: 14px;
  outline: none;
}

textarea:focus { border-color: var(--color-primary); }

.send-btn {
  padding: 0 20px;
  height: 40px;
  background: var(--color-primary);
  color: #fff;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
}

.send-btn:disabled {
  background: #a0cfff;
  cursor: not-allowed;
}
</style>