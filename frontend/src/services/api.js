import axios from 'axios'

// Local da /api (vite proxy), production da Railway URL
const BASE_URL = import.meta.env.VITE_API_URL
  ? import.meta.env.VITE_API_URL + '/api'
  : '/api'

const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
  timeout: 10000,
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('pos_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('pos_token')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api

// ── Auth ──────────────────────────────────────────────────────────────────────
export const authApi = {
  loginByPin:      (pin)            => api.post('/auth/pin',   { pin }),
  loginByPassword: (email, password)=> api.post('/auth/login', { email, password }),
  logout:          ()               => api.post('/auth/logout'),
  me:              ()               => api.get('/auth/me'),
}

// ── Menyu ─────────────────────────────────────────────────────────────────────
export const menuApi = {
  getAll:          ()       => api.get('/menu'),
  getCategories:   ()       => api.get('/categories'),
  getProducts:     ()       => api.get('/products'),
  createCategory:  (data)   => api.post('/categories', data),
  updateCategory:  (id, d)  => api.put(`/categories/${id}`, d),
  deleteCategory:  (id)     => api.delete(`/categories/${id}`),
  createProduct:   (data)   => api.post('/products', data),
  updateProduct:   (id, d)  => api.put(`/products/${id}`, d),
  deleteProduct:   (id)     => api.delete(`/products/${id}`),
  uploadImage:     (id, formData) => api.post(`/products/${id}/image`, formData, { headers: { 'Content-Type': 'multipart/form-data' } }),
  deleteImage:     (id)     => api.delete(`/products/${id}/image`),
}

// ── Stollar ───────────────────────────────────────────────────────────────────
export const tablesApi = {
  getHalls:       ()            => api.get('/halls'),
  getAll:         ()            => api.get('/tables'),
  updateStatus:   (id, status)  => api.patch(`/tables/${id}/status`, { status }),
  createHall:     (data)        => api.post('/halls', data),
  createTable:    (data)        => api.post('/tables', data),
  updateTable:    (id, d)       => api.put(`/tables/${id}`, d),
  deleteTable:    (id)          => api.delete(`/tables/${id}`),
}

// ── Buyurtmalar ───────────────────────────────────────────────────────────────
export const ordersApi = {
  getAll:        ()           => api.get('/orders'),
  getAllAdmin:    ()           => api.get('/orders?all=1'),
  getMine:       ()           => api.get('/orders?mine=1&all=1'),
  getOne:        (id)         => api.get(`/orders/${id}`),
  create:        (data)       => api.post('/orders', data),
  addItem:       (id, data)         => api.post(`/orders/${id}/items`, data),
  updateItem:    (id, itemId, qty)  => api.patch(`/orders/${id}/items/${itemId}`, { quantity: qty }),
  removeItem:    (id, itemId)       => api.delete(`/orders/${id}/items/${itemId}`),
  sendToKitchen: (id)               => api.post(`/orders/${id}/send`),
  updateStatus:  (id, status)       => api.patch(`/orders/${id}/status`, { status }),
}

// ── To'lov ────────────────────────────────────────────────────────────────────
export const paymentsApi = {
  getOrders: ()         => api.get('/payments/orders'),
  pay:       (data)     => api.post('/payments', data),
  summary:   (from, to) => api.get('/payments/summary', { params: { from, to } }),
}

// ── Oshpaz ────────────────────────────────────────────────────────────────────
export const kitchenApi = {
  getTickets:        ()                  => api.get('/kitchen/tickets'),
  updateItemStatus:  (itemId, status)    => api.patch(`/kitchen/items/${itemId}/status`,  { status }),
  updateOrderStatus: (orderId, status)   => api.patch(`/kitchen/orders/${orderId}/status`, { status }),
}

// ── Smena ─────────────────────────────────────────────────────────────────────
export const shiftApi = {
  current: ()     => api.get('/shifts/current'),
  open:    (data) => api.post('/shifts/open', data),
  close:   (data) => api.post('/shifts/close', data),
  getAll:  ()     => api.get('/shifts'),
}

// ── Sklad ─────────────────────────────────────────────────────────────────────
export const stockApi = {
  getIngredients:  ()           => api.get('/ingredients'),
  createIngredient:(data)       => api.post('/ingredients', data),
  updateIngredient:(id, data)   => api.put(`/ingredients/${id}`, data),
  deleteIngredient:(id)         => api.delete(`/ingredients/${id}`),
  addStock:        (id, data)   => api.post(`/ingredients/${id}/stock`, data),
  getMovements:    (id)         => api.get(`/ingredients/${id}/movements`),
  getLowStock:     ()           => api.get('/ingredients/low-stock'),
  getAllCosts:     ()            => api.get('/products/recipe-costs'),
  getRecipe:       (productId)  => api.get(`/products/${productId}/recipe`),
  saveRecipe:      (productId, ingredients) => api.post(`/products/${productId}/recipe`, { ingredients }),
}

// ── Xarajatlar ────────────────────────────────────────────────────────────────
export const expenseApi = {
  getAll:   (params)  => api.get('/expenses', { params }),
  create:   (data)    => api.post('/expenses', data),
  delete:   (id)      => api.delete(`/expenses/${id}`),
  summary:  (from, to) => api.get('/expenses/summary', { params: { from, to } }),
}

// ── Xodimlar ──────────────────────────────────────────────────────────────────
export const usersApi = {
  getAll:  ()       => api.get('/users'),
  create:  (data)   => api.post('/users', data),
  update:  (id, d)  => api.put(`/users/${id}`, d),
  delete:  (id)     => api.delete(`/users/${id}`),
}
