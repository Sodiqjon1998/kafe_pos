/**
 * IndexedDB wrapper — oflayn saqlash uchun
 * DB: pos_db, version: 1
 * Stores:
 *   - offline_orders: yuborilmagan buyurtmalar
 *   - cache_halls:    zallar + stollar (oxirgi muvaffaqiyatli fetch)
 *   - cache_menu:     menyu kategoriyalar + mahsulotlar
 */

const DB_NAME = 'pos_db'
const DB_VERSION = 1

function openDB() {
  return new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, DB_VERSION)
    req.onupgradeneeded = (e) => {
      const db = e.target.result
      if (!db.objectStoreNames.contains('offline_orders')) {
        const store = db.createObjectStore('offline_orders', { keyPath: 'localId', autoIncrement: true })
        store.createIndex('synced', 'synced', { unique: false })
      }
      if (!db.objectStoreNames.contains('cache_halls')) {
        db.createObjectStore('cache_halls', { keyPath: 'id' })
      }
      if (!db.objectStoreNames.contains('cache_menu')) {
        db.createObjectStore('cache_menu', { keyPath: 'id' })
      }
    }
    req.onsuccess = () => resolve(req.result)
    req.onerror   = () => reject(req.error)
  })
}

function tx(db, storeName, mode = 'readonly') {
  return db.transaction(storeName, mode).objectStore(storeName)
}

// ─── Offline orders ───────────────────────────────────────────────────────────

export async function saveOfflineOrder(orderData) {
  const db = await openDB()
  return new Promise((resolve, reject) => {
    const store = tx(db, 'offline_orders', 'readwrite')
    const req = store.add({ ...orderData, synced: 0, createdAt: new Date().toISOString() })
    req.onsuccess = () => resolve(req.result)
    req.onerror   = () => reject(req.error)
  })
}

export async function getPendingOrders() {
  const db = await openDB()
  return new Promise((resolve, reject) => {
    const store = tx(db, 'offline_orders', 'readonly')
    const req = store.index('synced').getAll(0)
    req.onsuccess = () => resolve(req.result)
    req.onerror   = () => reject(req.error)
  })
}

export async function markOrderSynced(localId) {
  const db = await openDB()
  return new Promise((resolve, reject) => {
    const store = tx(db, 'offline_orders', 'readwrite')
    const getReq = store.get(localId)
    getReq.onsuccess = () => {
      const record = getReq.result
      if (!record) return resolve()
      record.synced = 1
      const putReq = store.put(record)
      putReq.onsuccess = () => resolve()
      putReq.onerror   = () => reject(putReq.error)
    }
    getReq.onerror = () => reject(getReq.error)
  })
}

export async function deleteOldSyncedOrders() {
  const db = await openDB()
  return new Promise((resolve, reject) => {
    const store = tx(db, 'offline_orders', 'readwrite')
    const req = store.index('synced').openCursor(IDBKeyRange.only(1))
    req.onsuccess = (e) => {
      const cursor = e.target.result
      if (cursor) { cursor.delete(); cursor.continue() }
      else resolve()
    }
    req.onerror = () => reject(req.error)
  })
}

// ─── Cache halls ──────────────────────────────────────────────────────────────

export async function cacheHalls(halls) {
  const db = await openDB()
  return new Promise((resolve) => {
    const store = tx(db, 'cache_halls', 'readwrite')
    store.clear().onsuccess = () => {
      halls.forEach(h => store.put(h))
      resolve()
    }
  })
}

export async function getCachedHalls() {
  const db = await openDB()
  return new Promise((resolve, reject) => {
    const req = tx(db, 'cache_halls', 'readonly').getAll()
    req.onsuccess = () => resolve(req.result)
    req.onerror   = () => reject(req.error)
  })
}

// ─── Cache menu ───────────────────────────────────────────────────────────────

export async function cacheMenu(categories) {
  const db = await openDB()
  return new Promise((resolve) => {
    const store = tx(db, 'cache_menu', 'readwrite')
    store.clear().onsuccess = () => {
      categories.forEach(c => store.put(c))
      resolve()
    }
  })
}

export async function getCachedMenu() {
  const db = await openDB()
  return new Promise((resolve, reject) => {
    const req = tx(db, 'cache_menu', 'readonly').getAll()
    req.onsuccess = () => resolve(req.result)
    req.onerror   = () => reject(req.error)
  })
}
