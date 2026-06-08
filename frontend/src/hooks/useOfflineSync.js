import { useEffect, useRef, useState } from 'react'
import { getPendingOrders, markOrderSynced, deleteOldSyncedOrders } from '../db'
import { ordersApi } from '../services/api'

/**
 * useOfflineSync — oflayn buyurtmalarni kuzatib, internet kelganda serverga yuboradi
 *
 * Returns:
 *   isOnline  — hozirgi holat
 *   pending   — yuborilmagan buyurtmalar soni
 *   syncNow() — qo'lda sync qilish
 */
export function useOfflineSync() {
  const [isOnline, setIsOnline] = useState(navigator.onLine)
  const [pending, setPending]   = useState(0)
  const syncingRef = useRef(false)

  // Online/offline hodisalari
  useEffect(() => {
    const goOnline  = () => { setIsOnline(true);  syncPending() }
    const goOffline = () => setIsOnline(false)
    window.addEventListener('online',  goOnline)
    window.addEventListener('offline', goOffline)
    // Sahifa ochilganda ham tekshir
    syncPending()
    return () => {
      window.removeEventListener('online',  goOnline)
      window.removeEventListener('offline', goOffline)
    }
  }, [])

  // Har 30 soniyada ham sync qilishga urish
  useEffect(() => {
    const t = setInterval(() => {
      if (navigator.onLine) syncPending()
    }, 30000)
    return () => clearInterval(t)
  }, [])

  async function syncPending() {
    if (syncingRef.current) return
    syncingRef.current = true
    try {
      const orders = await getPendingOrders()
      setPending(orders.length)
      if (!orders.length || !navigator.onLine) return

      for (const order of orders) {
        try {
          await ordersApi.create({
            table_id: order.table_id,
            items:    order.items,
            note:     order.note || '',
          })
          await markOrderSynced(order.localId)
        } catch (err) {
          console.warn('Sync xato:', err)
        }
      }

      await deleteOldSyncedOrders()
      const remaining = await getPendingOrders()
      setPending(remaining.length)
    } catch (err) {
      console.error('syncPending xato:', err)
    } finally {
      syncingRef.current = false
    }
  }

  return { isOnline, pending, syncNow: syncPending }
}
