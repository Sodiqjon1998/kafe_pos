import { useState, useEffect, useCallback, useRef } from 'react'
import { useAuth } from '../../context/AuthContext'
import { tablesApi, menuApi, ordersApi } from '../../services/api'
import { saveOfflineOrder, cacheHalls, cacheMenu, getCachedHalls, getCachedMenu } from '../../db'
import { useOfflineSync } from '../../hooks/useOfflineSync'
import toast from 'react-hot-toast'
import {
  LayoutGrid, LogOut, Users, Clock,
  Plus, Minus, Send, ShoppingCart, UtensilsCrossed,
  RefreshCw, AlertCircle, CheckCircle, History, X, WifiOff, Trash2
} from 'lucide-react'

const C = {
  bg:        '#0F172A', surface:   '#1E293B', surface2:  '#334155',
  border:    '#475569', primary:   '#F97316', text:      '#F1F5F9',
  muted:     '#94A3B8', success:   '#22C55E', warning:   '#EAB308', danger: '#EF4444',
}

const TABLE_STATUS = {
  free:           { label: "Bo'sh", color: C.surface2, border: C.border,  textColor: C.success },
  occupied:       { label: 'Band',  color: '#431407',  border: C.primary, textColor: C.primary },
  bill_requested: { label: 'Hisob', color: '#422006',  border: C.warning, textColor: C.warning },
  reserved:       { label: 'Bron',  color: '#1e1b4b',  border: '#818cf8', textColor: '#818cf8' },
}

const STATUS_LABEL = { open:'Ochiq', sent:'Oshpazda', ready:'Tayyor', bill:'Hisob', paid:"To'langan", cancelled:'Bekor' }
const STATUS_COLOR = { open:C.primary, sent:C.primary, ready:C.success, bill:C.warning, paid:C.muted, cancelled:C.danger }

const fmt = (n) => Number(n || 0).toLocaleString('uz-UZ') + " so'm"
function toDate(dt) {
  if (!dt) return null
  const s = String(dt).replace(' ', 'T')
  return new Date(s.endsWith('Z') || s.includes('+') ? s : s + 'Z')
}
function fmtTime(dt) {
  const d = toDate(dt)
  if (!d) return '—'
  return d.toLocaleString('uz-UZ', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function useIsMobile() {
  const [m, setM] = useState(window.innerWidth < 768)
  useEffect(() => {
    const fn = () => setM(window.innerWidth < 768)
    window.addEventListener('resize', fn)
    return () => window.removeEventListener('resize', fn)
  }, [])
  return m
}

// ─── TableCard ────────────────────────────────────────────────────────────────
function TableCard({ table, selected, onClick, myId }) {
  const st = TABLE_STATUS[table.status] || TABLE_STATUS.free
  const order = table.activeOrder || table.active_order
  const isReady  = order?.status === 'ready'
  const isMine   = order?.waiter_id === myId
  const waiterName = order?.waiter?.name || null
  const isBusy   = table.status !== 'free'

  return (
    <button onClick={onClick} style={{
      background: selected ? C.primary : isReady ? '#052e16' : st.color,
      border: `2px solid ${selected ? C.primary : isMine && isBusy ? '#fb923c' : isReady ? C.success : st.border}`,
      borderRadius: 12, padding: '14px 10px', cursor: 'pointer',
      textAlign: 'center', display: 'flex', flexDirection: 'column',
      alignItems: 'center', gap: 4, position: 'relative', minWidth: 0,
    }}>
      {/* Tayyor belgisi */}
      {isReady && !selected && (
        <div style={{ position: 'absolute', top: 5, right: 5 }}>
          <CheckCircle size={13} color={C.success} />
        </div>
      )}
      {/* Mening stolim belgisi */}
      {isMine && isBusy && !selected && (
        <div style={{ position: 'absolute', top: 5, left: 5, background: C.primary, borderRadius: 4, width: 6, height: 6 }} />
      )}
      <LayoutGrid size={20} color={selected ? '#fff' : isReady ? C.success : C.muted} />
      <span style={{ color: selected ? '#fff' : C.text, fontWeight: 700, fontSize: 14 }}>{table.name}</span>
      <div style={{ display: 'flex', alignItems: 'center', gap: 3 }}>
        <Users size={11} color={selected ? 'rgba(255,255,255,0.7)' : C.muted} />
        <span style={{ color: selected ? 'rgba(255,255,255,0.7)' : C.muted, fontSize: 11 }}>{table.capacity}</span>
      </div>
      <span style={{ fontSize: 10, fontWeight: 600, color: selected ? '#fff' : isReady ? C.success : st.textColor }}>
        {isReady ? 'Tayyor!' : st.label}
      </span>
      {/* Ofitsiant ismi — band bo'lsa */}
      {waiterName && !selected && (
        <span style={{ fontSize: 9, color: isMine ? C.primary : C.muted, fontWeight: 600, maxWidth: '100%', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {isMine ? '★ Men' : waiterName}
        </span>
      )}
    </button>
  )
}

// ─── HistoryModal ─────────────────────────────────────────────────────────────
function HistoryModal({ onClose }) {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)
  const [expanded, setExpanded] = useState(null)

  useEffect(() => {
    ordersApi.getMine().then(r => setOrders(r.data)).catch(() => {}).finally(() => setLoading(false))
  }, [])

  const history = orders.filter(o => ['paid', 'cancelled'].includes(o.status))
  const active  = orders.filter(o => !['paid', 'cancelled'].includes(o.status))

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#00000099', zIndex: 300, display: 'flex', flexDirection: 'column' }}>
      <div style={{ background: C.surface, flex: 1, marginTop: 48, borderRadius: '16px 16px 0 0', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '16px 20px', borderBottom: `1px solid ${C.border}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ color: C.text, fontWeight: 700, fontSize: 16 }}>Mening buyurtmalarim</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted }}><X size={22} /></button>
        </div>

        {loading ? (
          <div style={{ padding: 32, textAlign: 'center', color: C.muted }}>Yuklanmoqda...</div>
        ) : (
          <div style={{ flex: 1, overflowY: 'auto', padding: '12px 16px' }}>
            {/* Aktiv buyurtmalar */}
            {active.length > 0 && (
              <div style={{ marginBottom: 16 }}>
                <div style={{ color: C.muted, fontSize: 11, fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>AKTIV ({active.length})</div>
                {active.map(o => <OrderCard key={o.id} o={o} expanded={expanded} setExpanded={setExpanded} />)}
              </div>
            )}
            {/* Tarix */}
            <div>
              <div style={{ color: C.muted, fontSize: 11, fontWeight: 700, letterSpacing: 1, marginBottom: 8 }}>TARIX ({history.length})</div>
              {history.length === 0 && <div style={{ color: C.muted, fontSize: 13, textAlign: 'center', padding: 20 }}>Tarix yo'q</div>}
              {history.map(o => <OrderCard key={o.id} o={o} expanded={expanded} setExpanded={setExpanded} />)}
            </div>
          </div>
        )}
      </div>
    </div>
  )
}

function OrderCard({ o, expanded, setExpanded }) {
  const sc = STATUS_COLOR[o.status] || C.muted
  const sl = STATUS_LABEL[o.status] || o.status
  const isOpen = expanded === o.id
  const subtotal = (o.items||[]).reduce((s,i)=>s+parseFloat(i.product_price||0)*i.quantity,0)
  const total = parseFloat(o.total||0) || subtotal

  return (
    <div style={{ background: C.surface2, borderRadius: 10, marginBottom: 8, overflow: 'hidden' }}>
      <button onClick={() => setExpanded(isOpen ? null : o.id)} style={{
        width: '100%', background: 'none', border: 'none', cursor: 'pointer',
        padding: '12px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      }}>
        <div style={{ textAlign: 'left' }}>
          <div style={{ color: C.text, fontWeight: 700, fontSize: 14 }}>#{o.order_number}</div>
          <div style={{ color: C.muted, fontSize: 12 }}>{o.table?.name || 'Olib ketish'} · {fmtTime(o.created_at)}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <span style={{ background: `${sc}22`, color: sc, borderRadius: 20, padding: '3px 10px', fontSize: 11, fontWeight: 700 }}>{sl}</span>
          <span style={{ color: C.primary, fontWeight: 700, fontSize: 14 }}>{fmt(total)}</span>
        </div>
      </button>
      {isOpen && (
        <div style={{ padding: '0 14px 12px', borderTop: `1px solid ${C.border}` }}>
          {(o.items||[]).map((item, i) => (
            <div key={i} style={{ display: 'flex', justifyContent: 'space-between', color: C.muted, fontSize: 13, padding: '5px 0', borderBottom: i < o.items.length-1 ? `1px solid ${C.border}33` : 'none' }}>
              <span>{item.name_uz || item.product_name} × {item.quantity}</span>
              <span>{fmt((item.product_price||0)*item.quantity)}</span>
            </div>
          ))}
          {parseFloat(o.discount) > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', color: C.warning, fontSize: 12, paddingTop: 6 }}>
              <span>Chegirma</span><span>-{fmt(o.discount)}</span>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

// ─── Main ─────────────────────────────────────────────────────────────────────
export default function WaiterLayout() {
  const { user, logout } = useAuth()
  const isMobile = useIsMobile()
  const prevReadyRef = useRef(null)
  const { isOnline, pending, syncNow } = useOfflineSync()

  const [halls, setHalls]               = useState([])
  const [activeHallId, setActiveHallId] = useState(null)
  const [selectedTable, setSelectedTable] = useState(null)
  const [categories, setCategories]     = useState([])
  const [activeCatId, setActiveCatId]   = useState(null)
  const [cart, setCart]     = useState([])
  const [note, setNote]     = useState('')
  const [sending, setSending] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError]   = useState(null)
  const [showHistory, setShowHistory] = useState(false)
  const [editOrder, setEditOrder] = useState(null) // {id, items} — tahrirlash rejimi
  const [cancelling, setCancelling] = useState(false)
  // Mobile: qaysi tab ko'rinmoqda
  const [mobileTab, setMobileTab] = useState('tables') // 'tables' | 'menu' | 'cart'

  function playBeep(freq = 660) {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain); gain.connect(ctx.destination)
      osc.frequency.value = freq
      gain.gain.setValueAtTime(0.3, ctx.currentTime)
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.5)
      osc.start(ctx.currentTime); osc.stop(ctx.currentTime + 0.5)
    } catch {}
  }

  useEffect(() => {
    loadData()
    const t = setInterval(loadData, 10000)
    return () => clearInterval(t)
  }, [])

  async function loadData() {
    setLoading(true); setError(null)
    try {
      const [hallsRes, tablesRes, menuRes] = await Promise.all([
        tablesApi.getHalls(),
        tablesApi.getAll(),
        menuApi.getAll(),
      ])

      const allTables = tablesRes.data || []
      const hallsWithTables = (hallsRes.data || []).map(h => ({
        ...h,
        tables: (h.tables && h.tables.length > 0)
          ? h.tables
          : allTables.filter(t => t.hall_id === h.id),
      }))

      // Cache saqlaymiz (oflayn uchun)
      cacheHalls(hallsWithTables).catch(() => {})
      cacheMenu(menuRes.data || []).catch(() => {})

      // "Tayyor" buyurtmalarni kuzatish
      const readyTables = hallsWithTables.flatMap(h => h.tables || [])
        .filter(t => t.activeOrder?.status === 'ready')
        .map(t => t.activeOrder?.id)
        .sort().join(',')
      if (prevReadyRef.current !== null && prevReadyRef.current !== readyTables && readyTables.length > 0) {
        playBeep(880)
      }
      prevReadyRef.current = readyTables

      setHalls(hallsWithTables)
      setCategories(menuRes.data || [])
      if (hallsWithTables.length) setActiveHallId(prev => prev || hallsWithTables[0].id)
      if (menuRes.data?.length)   setActiveCatId(prev => prev || menuRes.data[0].id)
    } catch (e) {
      console.error('loadData error:', e)
      // Oflayn: cache dan yuklash
      try {
        const cachedHalls = await getCachedHalls()
        const cachedMenu  = await getCachedMenu()
        if (cachedHalls.length) {
          setHalls(cachedHalls)
          setActiveHallId(prev => prev || cachedHalls[0]?.id)
          toast('Oflayn rejim — keshdan yuklandi', { icon: '📶' })
        }
        if (cachedMenu.length) {
          setCategories(cachedMenu)
          setActiveCatId(prev => prev || cachedMenu[0]?.id)
        }
        if (!cachedHalls.length) setError("Ma'lumot yuklanmadi")
      } catch {
        setError("Ma'lumot yuklanmadi")
      }
    }
    finally { setLoading(false) }
  }

  const activeHall  = halls.find(h => h.id === activeHallId)
  const hallTables  = activeHall?.tables || []
  const activeCat   = categories.find(c => c.id === activeCatId)
  const catProducts = activeCat?.products || []
  const cartTotal   = cart.reduce((s, i) => s + i.price * i.qty, 0)
  const cartCount   = cart.reduce((s, i) => s + i.qty, 0)

  function addToCart(product) {
    setCart(prev => {
      const ex = prev.find(i => i.id === product.id)
      if (ex) return prev.map(i => i.id === product.id ? { ...i, qty: i.qty + 1 } : i)
      return [...prev, { id: product.id, name: product.name_uz, price: product.price, qty: 1 }]
    })
    if (isMobile) setMobileTab('cart')
  }

  function changeQty(id, delta) {
    setCart(prev => prev.map(i => i.id === id ? { ...i, qty: Math.max(0, i.qty + delta) } : i).filter(i => i.qty > 0))
  }

  async function selectTable(table) {
    const order = table.activeOrder || table.active_order
    setSelectedTable(table)
    setNote('')
    if (table.status === 'occupied' && order?.id) {
      try {
        const res = await ordersApi.getOne(order.id)
        const fullOrder = res.data
        setEditOrder({ id: fullOrder.id, items: fullOrder.items || [] })
        setCart((fullOrder.items || []).map(i => ({
          id: i.product_id,
          itemId: i.id,
          name: i.product_name,
          price: parseFloat(i.product_price),
          qty: i.quantity,
        })))
      } catch {
        setEditOrder(null)
        setCart([])
      }
    } else {
      setEditOrder(null)
      setCart([])
    }
    if (isMobile) setMobileTab(table.status === 'occupied' ? 'cart' : 'menu')
  }

  async function removeCartItem(item) {
    if (item.itemId && editOrder) {
      try {
        await ordersApi.removeItem(editOrder.id, item.itemId)
        setEditOrder(prev => prev ? { ...prev, items: prev.items.filter(i => i.id !== item.itemId) } : null)
      } catch { toast.error("O'chirib bo'lmadi"); return }
    }
    setCart(prev => prev.filter(i => i.id !== item.id))
  }

  async function cancelOrder() {
    if (!editOrder) return
    if (!window.confirm('Buyurtmani bekor qilasizmi? Mijoz ketib qolganmi?')) return
    setCancelling(true)
    try {
      await ordersApi.updateStatus(editOrder.id, 'cancelled')
      toast.success('Buyurtma bekor qilindi')
      setCart([]); setNote(''); setSelectedTable(null); setEditOrder(null)
      if (isMobile) setMobileTab('tables')
      await loadData()
    } catch { toast.error('Xato yuz berdi') }
    finally { setCancelling(false) }
  }

  async function sendOrder() {
    if (!cart.length || !selectedTable) return
    setSending(true)
    try {
      if (editOrder) {
        // Tahrirlash rejimi
        const origItems = editOrder.items || []
        const newItems     = cart.filter(i => !i.itemId)
        const changedItems = cart.filter(i => i.itemId).filter(i => {
          const orig = origItems.find(o => o.id === i.itemId)
          return orig && orig.quantity !== i.qty
        })
        for (const item of newItems) {
          await ordersApi.addItem(editOrder.id, { product_id: item.id, quantity: item.qty })
        }
        for (const item of changedItems) {
          await ordersApi.updateItem(editOrder.id, item.itemId, item.qty)
        }
        if (newItems.length > 0) await ordersApi.sendToKitchen(editOrder.id)
        toast.success('Buyurtma yangilandi!')
      } else {
        // Yangi buyurtma
        const orderRes = await ordersApi.create({ table_id: selectedTable.id, type: 'dine_in', guests_count: 1, note })
        const order = orderRes.data
        for (const item of cart) await ordersApi.addItem(order.id, { product_id: item.id, quantity: item.qty })
        await ordersApi.sendToKitchen(order.id)
        toast.success('Oshpazga yuborildi!')
      }
      setCart([]); setNote(''); setSelectedTable(null); setEditOrder(null)
      if (isMobile) setMobileTab('tables')
      await loadData()
    } catch { toast.error("Xato yuz berdi. Qayta urinib ko'ring.") }
    finally { setSending(false) }
  }

  if (loading && !halls.length) return (
    <div style={{ minHeight: '100vh', background: C.bg, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      <div style={{ color: C.muted }}>Yuklanmoqda...</div>
    </div>
  )

  if (error) return (
    <div style={{ minHeight: '100vh', background: C.bg, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
      <AlertCircle size={40} color={C.danger} />
      <span style={{ color: C.danger }}>{error}</span>
      <button onClick={loadData} style={{ background: C.primary, color: '#fff', border: 'none', borderRadius: 8, padding: '10px 20px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
        <RefreshCw size={15} /> Qayta yuklash
      </button>
    </div>
  )

  // ── MOBILE LAYOUT ──────────────────────────────────────────────────────────
  if (isMobile) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', background: C.bg, color: C.text, fontFamily: 'system-ui, sans-serif' }}>
        {/* Header */}
        <header style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, padding: '0 16px', height: 52, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <UtensilsCrossed size={18} color={C.primary} />
            <span style={{ fontWeight: 700, fontSize: 15, color: C.text }}>Kafe POS</span>
            <span style={{ color: C.muted, fontSize: 12 }}>· {user?.name}</span>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={() => setShowHistory(true)} style={{ background: 'none', border: `1px solid ${C.border}`, borderRadius: 8, padding: '5px 10px', cursor: 'pointer', color: C.muted, display: 'flex', alignItems: 'center', gap: 4, fontSize: 12 }}>
              <History size={14} /> Tarix
            </button>
            <button onClick={logout} style={{ background: 'none', border: `1px solid ${C.border}`, borderRadius: 8, padding: '5px 10px', cursor: 'pointer', color: C.muted, display: 'flex', alignItems: 'center', gap: 4, fontSize: 12 }}>
              <LogOut size={14} />
            </button>
          </div>
        </header>

        {/* Hall tabs - only show if multiple halls */}
        {halls.length > 1 && (
          <div style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, display: 'flex', overflowX: 'auto', flexShrink: 0, padding: '0 8px' }}>
            {halls.map(h => (
              <button key={h.id} onClick={() => { setActiveHallId(h.id); setSelectedTable(null); setMobileTab('tables') }} style={{
                background: 'none', border: 'none', borderBottom: `2px solid ${activeHallId === h.id ? C.primary : 'transparent'}`,
                color: activeHallId === h.id ? C.primary : C.muted, fontWeight: 600, fontSize: 13,
                padding: '10px 14px', cursor: 'pointer', whiteSpace: 'nowrap', flexShrink: 0,
              }}>{h.name_uz || h.name_ru || h.name}</button>
            ))}
          </div>
        )}

        {/* Selected table banner */}
        {selectedTable && (
          <div style={{ background: `${C.primary}15`, borderBottom: `1px solid ${C.primary}44`, padding: '8px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexShrink: 0 }}>
            <span style={{ color: C.primary, fontWeight: 600, fontSize: 13 }}>Stol: {selectedTable.name}</span>
            <button onClick={() => { setSelectedTable(null); setCart([]); setNote(''); setMobileTab('tables') }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted }}>
              <X size={16} />
            </button>
          </div>
        )}

        {/* Content */}
        <div style={{ flex: 1, overflowY: 'auto' }}>
          {/* TABLES TAB */}
          {mobileTab === 'tables' && (
            <div style={{ padding: 12 }}>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(90px, 1fr))', gap: 8 }}>
                {hallTables.map(t => (
                  <TableCard key={t.id} table={t} selected={selectedTable?.id === t.id} onClick={() => selectTable(t)} myId={user?.id} />
                ))}
              </div>
              {hallTables.length === 0 && <div style={{ textAlign: 'center', color: C.muted, padding: 40 }}>Stol yo'q</div>}
            </div>
          )}

          {/* MENU TAB */}
          {mobileTab === 'menu' && (
            <div style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
              {/* Category tabs */}
              <div style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, display: 'flex', overflowX: 'auto', padding: '0 8px', flexShrink: 0 }}>
                {categories.map(c => (
                  <button key={c.id} onClick={() => setActiveCatId(c.id)} style={{
                    background: 'none', border: 'none', borderBottom: `2px solid ${activeCatId === c.id ? C.primary : 'transparent'}`,
                    color: activeCatId === c.id ? C.primary : C.muted, fontWeight: 600, fontSize: 13,
                    padding: '10px 14px', cursor: 'pointer', whiteSpace: 'nowrap', flexShrink: 0,
                  }}>{c.name_uz}</button>
                ))}
              </div>
              {/* Products */}
              <div style={{ flex: 1, overflowY: 'auto', padding: 12 }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 8 }}>
                  {catProducts.filter(p => p.is_available).map(p => {
                    const inCart = cart.find(i => i.id === p.id)
                    return (
                      <button key={p.id} onClick={() => addToCart(p)} style={{
                        background: inCart ? `${C.primary}15` : C.surface,
                        border: `1px solid ${inCart ? C.primary : C.border}`,
                        borderRadius: 10, padding: 0, cursor: 'pointer', textAlign: 'left',
                        overflow: 'hidden', display: 'flex', flexDirection: 'column',
                      }}>
                        {p.image
                          ? <img src={p.image} alt={p.name_uz} style={{ width: '100%', height: 110, objectFit: 'cover' }} />
                          : <div style={{ width: '100%', height: 110, background: C.surface2, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28 }}>🍽️</div>
                        }
                        <div style={{ padding: '8px 10px 10px' }}>
                          <div style={{ color: C.text, fontWeight: 600, fontSize: 13, marginBottom: 4 }}>{p.name_uz}</div>
                          <div style={{ color: C.primary, fontWeight: 700, fontSize: 14 }}>{fmt(p.price)}</div>
                          {inCart && <div style={{ color: C.success, fontSize: 11, marginTop: 3 }}>Savatchada: {inCart.qty}</div>}
                        </div>
                      </button>
                    )
                  })}
                </div>
              </div>
            </div>
          )}

          {/* CART TAB */}
          {mobileTab === 'cart' && (
            <div style={{ padding: 12 }}>
              {cart.length === 0 ? (
                <div style={{ textAlign: 'center', color: C.muted, padding: 40 }}>
                  <ShoppingCart size={40} color={C.border} style={{ marginBottom: 8 }} />
                  <div>Savatcha bo'sh</div>
                </div>
              ) : (
                <>
                  {cart.map(item => (
                    <div key={item.id} style={{ background: C.surface, borderRadius: 10, padding: '12px 14px', marginBottom: 8, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <div style={{ color: C.text, fontWeight: 600, fontSize: 14 }}>{item.name}</div>
                        <div style={{ color: C.primary, fontSize: 13 }}>{fmt(item.price * item.qty)}</div>
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                        <button onClick={() => changeQty(item.id, -1)} style={qBtn}><span style={{ color: C.text, fontSize: 16 }}>-</span></button>
                        <span style={{ color: C.text, fontWeight: 700, fontSize: 15, minWidth: 20, textAlign: 'center' }}>{item.qty}</span>
                        <button onClick={() => changeQty(item.id, 1)} style={qBtn}><span style={{ color: C.text, fontSize: 16 }}>+</span></button>
                      </div>
                    </div>
                  ))}
                  <textarea value={note} onChange={e => setNote(e.target.value)} placeholder="Oshpazga izoh..."
                    style={{ width: '100%', background: C.surface, border: `1px solid ${C.border}`, borderRadius: 8, padding: '10px 12px', color: C.text, fontSize: 13, outline: 'none', marginBottom: 12, boxSizing: 'border-box', resize: 'none', height: 70 }} />
                  {editOrder && (
                    <button onClick={cancelOrder} disabled={cancelling} style={{ width: '100%', background: '#7f1d1d', border: 'none', borderRadius: 10, padding: '12px', color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer', marginBottom: 8 }}>
                      🚫 {cancelling ? 'Bekor qilinmoqda...' : 'Buyurtmani bekor qilish'}
                    </button>
                  )}
                  <button onClick={sendOrder} disabled={sending || !selectedTable} style={{
                    width: '100%', background: sending || !selectedTable ? C.surface2 : C.primary,
                    border: 'none', borderRadius: 10, padding: '14px',
                    color: sending || !selectedTable ? C.muted : '#fff', fontWeight: 700, fontSize: 15,
                    cursor: sending || !selectedTable ? 'not-allowed' : 'pointer',
                    display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                  }}>
                    <Send size={16} />
                    {!selectedTable ? 'Avval stol tanlang' : sending ? 'Yuborilmoqda...' : editOrder ? `Yangilash - ${fmt(cartTotal)}` : `Oshpazga yuborish - ${fmt(cartTotal)}`}
                  </button>
                </>
              )}
            </div>
          )}
        </div>

        {/* Bottom tab bar */}
        <div style={{ background: C.surface, borderTop: `1px solid ${C.border}`, display: 'flex', flexShrink: 0, height: 60 }}>
          {[
            { key: 'tables', label: 'Stollar',  icon: LayoutGrid },
            { key: 'menu',   label: 'Menyu',    icon: UtensilsCrossed },
            { key: 'cart',   label: cartCount > 0 ? `Savatcha (${cartCount})` : 'Savatcha', icon: ShoppingCart },
          ].map(({ key, label, icon: Icon }) => (
            <button key={key} onClick={() => setMobileTab(key)} style={{
              flex: 1, background: 'none', border: 'none', cursor: 'pointer',
              display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 3,
              color: mobileTab === key ? C.primary : C.muted,
              borderTop: `2px solid ${mobileTab === key ? C.primary : 'transparent'}`,
              position: 'relative',
            }}>
              <Icon size={20} />
              <span style={{ fontSize: 10, fontWeight: 600 }}>{label}</span>
              {key === 'cart' && cartCount > 0 && (
                <div style={{ position: 'absolute', top: 8, right: '25%', background: C.danger, borderRadius: '50%', width: 16, height: 16, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 9, fontWeight: 700, color: '#fff' }}>{cartCount}</div>
              )}
            </button>
          ))}
        </div>

        {showHistory && <HistoryModal onClose={() => setShowHistory(false)} />}
      </div>
    )
  }

  // DESKTOP LAYOUT
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', background: C.bg, color: C.text, fontFamily: 'system-ui, sans-serif' }}>

      {/* Header */}
      <header style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, padding: '0 24px', height: 60, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <UtensilsCrossed size={22} color={C.primary} />
          <span style={{ fontWeight: 800, fontSize: 18, color: C.text }}>Kafe POS</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <Clock size={15} color={C.muted} />
            <span style={{ color: C.muted, fontSize: 13 }}>
              {new Date().toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' })}
            </span>
          </div>
          <span style={{ color: C.muted, fontSize: 13 }}>|</span>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ color: C.text, fontSize: 13, fontWeight: 600 }}>{user?.name}</span>
            {!isOnline && <span style={{ background: C.danger, color: '#fff', fontSize: 11, fontWeight: 700, borderRadius: 6, padding: '3px 8px', display: 'flex', alignItems: 'center', gap: 4 }}><WifiOff size={12} /> Oflayn</span>}
            {pending > 0 && isOnline && <span onClick={syncNow} style={{ background: C.warning, color: '#000', fontSize: 11, fontWeight: 700, borderRadius: 6, padding: '3px 8px', cursor: 'pointer' }}>{pending} kutmoqda ↑</span>}
          </div>
          <button onClick={() => setShowHistory(true)} style={{ background: C.surface2, border: `1px solid ${C.border}`, borderRadius: 8, padding: '7px 14px', cursor: 'pointer', color: C.text, fontSize: 13, display: 'flex', alignItems: 'center', gap: 6 }}>
            <History size={15} /> Tarix
          </button>
          <button onClick={loadData} disabled={loading} style={{ background: 'none', border: `1px solid ${C.border}`, borderRadius: 8, padding: '7px 12px', cursor: 'pointer', color: C.muted, display: 'flex', alignItems: 'center', gap: 5, fontSize: 13, opacity: loading ? 0.5 : 1 }}>
            <RefreshCw size={14} style={{ animation: loading ? 'spin 1s linear infinite' : 'none' }} />
          </button>
          <button onClick={logout} style={{ background: 'none', border: `1px solid ${C.border}`, borderRadius: 8, padding: '7px 12px', cursor: 'pointer', color: C.muted, display: 'flex', alignItems: 'center', gap: 6, fontSize: 13 }}>
            <LogOut size={15} /> Chiqish
          </button>
        </div>
      </header>

      {halls.length > 1 && (
        <div style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, display: 'flex', gap: 0, padding: '0 20px', flexShrink: 0 }}>
          {halls.map(h => (
            <button key={h.id} onClick={() => { setActiveHallId(h.id); setSelectedTable(null) }} style={{
              background: 'none', border: 'none',
              borderBottom: `2px solid ${activeHallId === h.id ? C.primary : 'transparent'}`,
              color: activeHallId === h.id ? C.primary : C.muted,
              fontWeight: 600, fontSize: 14, padding: '12px 16px', cursor: 'pointer',
            }}>{h.name_uz || h.name_ru || h.name}</button>
          ))}
        </div>
      )}

      {/* Main */}
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        {/* Tables */}
        <div style={{ flex: selectedTable ? '0 0 280px' : 1, padding: 16, overflowY: 'auto', borderRight: selectedTable ? `1px solid ${C.border}` : 'none' }}>
          {!selectedTable && (
            <div style={{ color: C.muted, fontSize: 12, marginBottom: 12 }}>Stol tanlang</div>
          )}
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(100px, 1fr))', gap: 10 }}>
            {hallTables.map(t => (
              <TableCard key={t.id} table={t} selected={selectedTable?.id === t.id} onClick={() => selectTable(t)} myId={user?.id} />
            ))}
          </div>
          {hallTables.length === 0 && <div style={{ color: C.muted, textAlign: 'center', padding: 40 }}>Stol yo'q</div>}
        </div>

        {selectedTable && (
          <>
            {/* Menu */}
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
              {/* Category tabs */}
              <div style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, display: 'flex', overflowX: 'auto', padding: '0 12px', flexShrink: 0 }}>
                {categories.map(c => (
                  <button key={c.id} onClick={() => setActiveCatId(c.id)} style={{
                    background: 'none', border: 'none',
                    borderBottom: `2px solid ${activeCatId === c.id ? C.primary : 'transparent'}`,
                    color: activeCatId === c.id ? C.primary : C.muted,
                    fontWeight: 600, fontSize: 13, padding: '10px 14px', cursor: 'pointer', whiteSpace: 'nowrap',
                  }}>{c.name_uz}</button>
                ))}
              </div>
              {/* Products grid */}
              <div style={{ flex: 1, overflowY: 'auto', padding: 12 }}>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 10 }}>
                  {catProducts.filter(p => p.is_available).map(p => {
                    const inCart = cart.find(i => i.id === p.id)
                    return (
                      <button key={p.id} onClick={() => addToCart(p)} style={{
                        background: inCart ? `${C.primary}15` : C.surface,
                        border: `1px solid ${inCart ? C.primary : C.border}`,
                        borderRadius: 10, padding: 0, cursor: 'pointer', textAlign: 'left',
                        overflow: 'hidden', display: 'flex', flexDirection: 'column',
                      }}>
                        {p.image
                          ? <img src={p.image} alt={p.name_uz} style={{ width: '100%', height: 110, objectFit: 'cover' }} />
                          : <div style={{ width: '100%', height: 110, background: C.surface2, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 30 }}>🍽️</div>
                        }
                        <div style={{ padding: '8px 12px 12px' }}>
                          <div style={{ color: C.text, fontWeight: 600, fontSize: 14, marginBottom: 4 }}>{p.name_uz}</div>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                            <span style={{ color: C.primary, fontWeight: 700, fontSize: 15 }}>{fmt(p.price)}</span>
                            {inCart && <span style={{ background: C.primary, color: '#fff', borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 700 }}>{inCart.qty}</span>}
                          </div>
                        </div>
                      </button>
                    )
                  })}
                </div>
              </div>
            </div>

            {/* Cart */}
            <div style={{ width: 300, background: C.surface, borderLeft: `1px solid ${C.border}`, display: 'flex', flexDirection: 'column' }}>
              <div style={{ padding: '14px 16px', borderBottom: `1px solid ${C.border}` }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  <div style={{ color: C.text, fontWeight: 700, fontSize: 15 }}>Stol: {selectedTable.name}</div>
                  {editOrder && <span style={{ background: C.warning + '33', color: C.warning, fontSize: 11, fontWeight: 700, borderRadius: 6, padding: '2px 8px' }}>Tahrirlash</span>}
                </div>
                <div style={{ display: 'flex', gap: 8, marginTop: 2 }}>
                  <button onClick={() => { setSelectedTable(null); setCart([]); setNote(''); setEditOrder(null) }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted, fontSize: 12 }}>Yopish</button>
                  {editOrder && <button onClick={cancelOrder} disabled={cancelling} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.danger, fontSize: 12, fontWeight: 600 }}>{cancelling ? '...' : '🚫 Buyurtmani bekor qilish'}</button>}
                </div>
              </div>

              {cart.length === 0 ? (
                <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: C.muted }}>
                  <ShoppingCart size={32} color={C.border} style={{ marginBottom: 8 }} />
                  <div style={{ fontSize: 13 }}>Mahsulot qo'shing</div>
                </div>
              ) : (
                <>
                  <div style={{ flex: 1, overflowY: 'auto', padding: '8px 12px' }}>
                    {cart.map(item => (
                      <div key={item.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: `1px solid ${C.border}33` }}>
                        <div style={{ flex: 1 }}>
                          <div style={{ color: C.text, fontSize: 13, fontWeight: 600 }}>{item.name}</div>
                          <div style={{ color: C.primary, fontSize: 12 }}>{fmt(item.price * item.qty)}</div>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <button onClick={() => item.qty <= 1 ? removeCartItem(item) : changeQty(item.id, -1)} style={{ ...qBtn, background: item.qty <= 1 ? '#7f1d1d' : qBtn.background }}><span style={{ color: C.text }}>{item.qty <= 1 ? '🗑' : '-'}</span></button>
                          <span style={{ color: C.text, fontWeight: 700, minWidth: 16, textAlign: 'center' }}>{item.qty}</span>
                          <button onClick={() => changeQty(item.id, 1)} style={qBtn}><span style={{ color: C.text }}>+</span></button>
                        </div>
                      </div>
                    ))}
                  </div>
                  <div style={{ padding: 12, borderTop: `1px solid ${C.border}` }}>
                    <textarea value={note} onChange={e => setNote(e.target.value)} placeholder="Oshpazga izoh..."
                      style={{ width: '100%', background: C.bg, border: `1px solid ${C.border}`, borderRadius: 8, padding: '8px 12px', color: C.text, fontSize: 13, outline: 'none', marginBottom: 10, boxSizing: 'border-box', resize: 'none', height: 60 }} />
                    <button onClick={sendOrder} disabled={sending} style={{
                      width: '100%', background: sending ? C.surface2 : C.primary, border: 'none', borderRadius: 10,
                      padding: '12px', color: '#fff', fontWeight: 700, fontSize: 15,
                      cursor: sending ? 'not-allowed' : 'pointer',
                      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
                    }}>
                      <Send size={16} />
                      {sending ? 'Yuborilmoqda...' : editOrder ? `Yangilash - ${fmt(cartTotal)}` : `Oshpazga yuborish - ${fmt(cartTotal)}`}
                    </button>
                  </div>
                </>
              )}
            </div>
          </>
        )}
      </div>

      {showHistory && <HistoryModal onClose={() => setShowHistory(false)} />}

    </div>
  )
}

const qBtn = {
  background: '#334155', border: 'none', borderRadius: 6,
  width: 28, height: 28, cursor: 'pointer', display: 'flex',
  alignItems: 'center', justifyContent: 'center',
}
