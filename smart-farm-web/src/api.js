import axios from 'axios'

const BASE_URL = 'http://localhost:8080/api'

const http = axios.create({
  baseURL: BASE_URL,
  timeout: 10000
})

// ==================== 区域接口 ====================
export const zoneApi = {
  listAll: () => http.get('/zones/list'),
  listByManager: (managerId) => http.get(`/zones/list/manager/${managerId}`),
  add: (data) => http.post('/zones/add', data),
  update: (data) => http.put('/zones/update', data),
  remove: (id) => http.delete(`/zones/delete/${id}`),
  // 区域员工
  getWorkers: (zoneId) => http.get(`/zones/${zoneId}/workers`),
  setWorkers: (zoneId, workerIds) => http.post(`/zones/${zoneId}/workers`, { workerIds }),
}

// ==================== 用户接口 ====================
export const userApi = {
  listAll: () => http.get('/users/list'),
  listByRole: (role) => http.get(`/users/list/role/${role}`),
  add: (data) => http.post('/users/add', data),
  update: (data) => http.put('/users/update', data),
  remove: (id) => http.delete(`/users/delete/${id}`)
}

// ==================== 任务接口 ====================
export const taskApi = {
  listByWorker: (workerId) => http.get(`/tasks/list/worker/${workerId}`),
  listByZone: (zoneId) => http.get(`/tasks/list/zone/${zoneId}`),
  add: (data) => http.post('/tasks/add', data),
  update: (data) => http.put('/tasks/update', data),
  remove: (id) => http.delete(`/tasks/delete/${id}`)
}

// ==================== 记录接口 ====================
export const recordApi = {
  listByWorker: (workerId) => http.get(`/records/list/worker/${workerId}`),
  listPending: (zoneId) => http.get(`/records/list/pending/${zoneId}`),
  listByZone: (zoneId) => http.get(`/records/list/zone/${zoneId}`),
  add: (data) => http.post('/records/add', data),
  audit: (data) => http.post('/records/audit', data)
}

// ==================== 异常接口 ====================
export const anomalyApi = {
  listAll: () => http.get('/anomalies/list/all'),
  listByZone: (zoneId) => http.get(`/anomalies/list/zone/${zoneId}`),
  listByReporter: (reporterId) => http.get(`/anomalies/list/reporter/${reporterId}`),
  add: (data) => http.post('/anomalies/add', data),
  handle: (data) => http.put('/anomalies/handle', data)
}

// ==================== 采收接口 ====================
export const harvestApi = {
  listAll: () => http.get('/harvests/list/all'),
  listByZone: (zoneId) => http.get(`/harvests/list/zone/${zoneId}`),
  listByWorker: (workerId) => http.get(`/harvests/list/worker/${workerId}`),
  add: (data) => http.post('/harvests/add', data)
}

// ==================== 通知接口 ====================
export const notificationApi = {
  list: (userId) => http.get(`/notifications/list/${userId}`),
  unreadCount: (userId) => http.get(`/notifications/unread/${userId}`),
  markRead: (id) => http.post(`/notifications/read/${id}`),
  markAllRead: (userId) => http.post(`/notifications/readAll/${userId}`)
}
// ==================== AI 接口 ====================
export const aiApi = {
  // 发送消息（支持图片）
  chat: (data) => http.post('/ai/chat', data),
  // 获取历史记录
  getHistory: (userId, sessionId) => http.get(`/ai/history?userId=${userId}&sessionId=${sessionId}`),
  // 清除会话
  clearHistory: (userId, sessionId) => http.delete(`/ai/history?userId=${userId}&sessionId=${sessionId}`),
}