import { useState, useEffect, useRef } from 'react'
import {
  CreditCard, Banknote, Smartphone, Receipt,
  CheckCircle, LogOut, Coffee, Clock,
  Printer, Search, X, RefreshCw, AlertCircle,
  XCircle, PlayCircle, StopCircle, TrendingUp
} from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { paymentsApi, ordersApi, shiftApi } from '../../services/api'

const C = {
  bg:      '#0F172A', surface: '#1E293B', card: '#263548',
  border:  '#334155', primary: '#F97316', text: '#F1F5F9',
  muted:   '#94A3B8', success: '#22C55E', danger: '#EF4444', warning: '#EAB308',
}

const STATUS_COLOR = { open: C.primary, sent: C.primary, ready: C.success, bill: C.warning, paid: C.muted }
const STATUS_LABEL = { open: 'Ochiq', sent: 'Oshpazda', ready: 'Tayyor', bill: 'Hisob', paid: "To'langan" }
const PAY_METHODS  = [
  { key: 'cash',  label: 'Naqd',  icon: Banknote },
  { key: 'card',  label: 'Karta', icon: CreditCard },
  { key: 'click', label: 'Click', icon: Smartphone },
  { key: 'payme', label: 'Payme', icon: Smartphone },
]
const PAY_LABEL = { cash: 'Naqd pul', card: 'Karta', click: 'Click', payme: 'Payme' }
const METHOD_UZ = { cash: 'Naqd', card: 'Karta', click: 'Click', payme: 'Payme', other: 'Boshqa' }

function orderTotal(order) {
  if (order.total && parseFloat(order.total) > 0) return parseFloat(order.total)
  return (order.items || []).reduce((s, i) => s + parseFloat(i.product_price || 0) * (i.quantity || 0), 0)
}
function fmt(n)    { return Number(Math.round(n || 0)).toLocaleString('uz-UZ') + " so'm" }
function toDate(dt) {
  if (!dt) return null
  const s = String(dt).replace(' ', 'T')
  return new Date(s.endsWith('Z') || s.includes('+') ? s : s + 'Z')
}
function timeStr(dt) {
  const d = toDate(dt)
  if (!d) return ''
  return d.toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' })
}
function duration(from) {
  const d = toDate(from)
  if (!d) return '—'
  const diff = Math.floor((Date.now() - d) / 60000)
  if (isNaN(diff) || diff < 0) return '0 daq'
  if (diff < 60) return `${diff} daq`
  const h = Math.floor(diff / 60), m = diff % 60
  return `${h} soat ${m} daq`
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

export default function CashierLayout() {
  const { user, logout } = useAuth()
  const [orders, setOrders]               = useState([])
  const [selected, setSelected]           = useState(null)
  const [payModal, setPayModal]           = useState(false)
  const [kitchenWarn, setKitchenWarn]     = useState(false)
  const [receipt, setReceipt]             = useState(null)
  const [cancelConfirm, setCancelConfirm] = useState(false)
  const [filter, setFilter]               = useState('all')
  const [search, setSearch]               = useState('')
  const [loading, setLoading]             = useState(true)
  const [error, setError]                 = useState(null)

  // Smena
  const [shift, setShift]               = useState(undefined)  // undefined=yuklanmagan, null=yo'q
  const [shiftModal, setShiftModal]     = useState(null)       // 'open' | 'close'
  const [shiftReport, setShiftReport]   = useState(null)

  const current = orders.find(o => o.id === selected)

  useEffect(() => {
    loadShift()
    loadOrders()
    const t = setInterval(() => { loadShift(); loadOrders() }, 5000)
    return () => clearInterval(t)
  }, [])

  async function loadShift() {
    try {
      const r = await shiftApi.current()
      // null yoki id mavjud bo'lgan shift qabul qilinadi
      const s = r.data && r.data.id ? r.data : null
      setShift(s)
    } catch { setShift(null) }
  }

  async function loadOrders() {
    setLoading(true); setError(null)
    try { const res = await paymentsApi.getOrders(); setOrders(res.data) }
    catch { setError("Buyurtmalar yuklanmadi") }
    finally { setLoading(false) }
  }

  async function openShift(cash) {
    try {
      const r = await shiftApi.open({ opening_cash: parseFloat(cash) || 0 })
      setShiftModal(null)
      // Verify by reloading from DB
      await loadShift()
    } catch (e) {
      const msg = e?.response?.data?.message || 'Smena ochishda xato'
      alert(msg)
      await loadShift() // refresh actual state from DB
    }
  }

  async function closeShift(cash) {
    try {
      const r = await shiftApi.close({ shift_id: shift?.id, closing_cash: parseFloat(cash) || 0 })
      setShift(null)
      setShiftModal(null)
      setShiftReport(r.data)
    } catch (e) {
      setShiftModal(null)
      if (e?.response?.status === 422) {
        // MySQL da ochiq smena yo'q — frontendni tozalaymiz
        setShift(null)
      } else {
        alert(e?.response?.data?.message || 'Smena yopishda xato')
        await loadShift()
      }
    }
  }

  function openPayment() {
    if (!shift) {
      alert('Avval smenani oching!')
      setShiftModal('open')
      return
    }
    const hasPending = (current?.items || []).some(i => ['pending', 'cooking'].includes(i.status))
    if (hasPending) setKitchenWarn(true)
    else setPayModal(true)
  }

  async function handlePay(method, cashReceived, discount = 0) {
    try {
      const resp = await paymentsApi.pay({
        order_id: selected,
        method,
        cash_received: method === 'cash' ? cashReceived : undefined,
        discount: discount > 0 ? discount : undefined,
      })
      const paidOrder = resp.data?.order || orders.find(o => o.id === selected)
      setPayModal(false); setSelected(null)
      await loadOrders()
      setReceipt({ order: paidOrder, method, cashReceived, discount })
    } catch (e) { alert(e?.response?.data?.message || "To'lov amalga oshmadi") }
  }

  async function handleCancel() {
    try {
      await ordersApi.updateStatus(selected, 'cancelled')
      setCancelConfirm(false); setSelected(null)
      await loadOrders()
    } catch { alert("Bekor qilishda xato") }
  }

  const isMobile = useIsMobile()

  const visible = orders.filter(o => {
    if (filter !== 'all' && o.status !== filter) return false
    if (search && !o.order_number?.includes(search) && !o.table?.name?.includes(search)) return false
    return true
  })

  return (
    <div style={{ height: '100vh', overflow: 'hidden', background: C.bg, display: 'flex', flexDirection: 'column', fontFamily: 'system-ui, sans-serif' }}>

      {/* Header */}
      <header style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, padding: '0 20px', height: 56, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Coffee size={20} color={C.primary} />
          <span style={{ color: C.text, fontWeight: 700, fontSize: 16 }}>Kassir paneli</span>
          <span style={{ background: C.card, color: C.muted, fontSize: 11, padding: '3px 10px', borderRadius: 20, border: `1px solid ${C.border}` }}>{user?.name}</span>
        </div>

        {/* Smena holati */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          {shift === undefined ? null : shift ? (
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{ background: `${C.success}22`, border: `1px solid ${C.success}44`, borderRadius: 8, padding: '5px 12px', display: 'flex', alignItems: 'center', gap: 6 }}>
                <div style={{ width: 7, height: 7, borderRadius: '50%', background: C.success }} />
                <span style={{ color: C.success, fontSize: 12, fontWeight: 600 }}>Smena ochiq</span>
                <span style={{ color: C.muted, fontSize: 11 }}>{duration(shift.opened_at)}</span>
              </div>
              <button onClick={() => setShiftModal('close')}
                style={{ background: `${C.danger}22`, border: `1px solid ${C.danger}44`, borderRadius: 8, padding: '5px 12px', color: C.danger, fontSize: 12, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 5 }}>
                <StopCircle size={13} /> Smena yopish
              </button>
            </div>
          ) : (
            <button onClick={() => setShiftModal('open')}
              style={{ background: C.primary, border: 'none', borderRadius: 8, padding: '7px 14px', color: '#fff', fontSize: 13, fontWeight: 700, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
              <PlayCircle size={15} /> Smena ochish
            </button>
          )}
          <button onClick={() => { loadOrders(); loadShift() }} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted, display: 'flex' }}><RefreshCw size={16} /></button>
          <button onClick={logout} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, color: C.muted, fontSize: 13 }}>
            <LogOut size={15} /> Chiqish
          </button>
        </div>
      </header>

      {/* Smena yo'q banner */}
      {/* Smena banneri - faqat ogohlantirish, bloklash yo'q */}
      {shift === null && (
        <div style={{ background: `${C.border}55`, borderBottom: `1px solid ${C.border}`, padding: '6px 20px', display: 'flex', alignItems: 'center', gap: 8 }}>
          <AlertCircle size={14} color={C.muted} />
          <span style={{ color: C.muted, fontSize: 12 }}>Smena ochilmagan (ixtiyoriy)</span>
        </div>
      )}

      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>

        {/* Chap: ro'yxat */}
        <div style={{ width: isMobile ? '100%' : 340, flexShrink: 0, background: C.surface, borderRight: `1px solid ${C.border}`, display: isMobile && selected ? 'none' : 'flex', flexDirection: 'column' }}>
          <div style={{ padding: 12, borderBottom: `1px solid ${C.border}` }}>
            <div style={{ position: 'relative' }}>
              <Search size={14} color={C.muted} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)' }} />
              <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Raqam yoki stol..."
                style={{ width: '100%', background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '9px 10px 9px 32px', color: C.text, fontSize: 13, boxSizing: 'border-box', outline: 'none' }} />
            </div>
          </div>
          <div style={{ display: 'flex', borderBottom: `1px solid ${C.border}` }}>
            {[{ k: 'all', l: 'Barchasi' }, { k: 'bill', l: 'Hisob' }, { k: 'ready', l: 'Tayyor' }, { k: 'open', l: 'Ochiq' }].map(({ k, l }) => (
              <button key={k} onClick={() => setFilter(k)} style={{ flex: 1, background: 'none', border: 'none', cursor: 'pointer', padding: '10px 4px', fontSize: 11, fontWeight: 600, color: filter === k ? C.primary : C.muted, borderBottom: `2px solid ${filter === k ? C.primary : 'transparent'}` }}>{l}</button>
            ))}
          </div>
          <div style={{ flex: 1, overflowY: 'auto' }}>
            {loading ? (
              <div style={{ padding: 24, textAlign: 'center', color: C.muted }}>Yuklanmoqda...</div>
            ) : error ? (
              <div style={{ padding: 24, textAlign: 'center' }}>
                <AlertCircle size={24} color={C.danger} style={{ marginBottom: 8 }} />
                <div style={{ color: C.danger, fontSize: 13 }}>{error}</div>
              </div>
            ) : visible.length === 0 ? (
              <div style={{ padding: 24, textAlign: 'center', color: C.muted, fontSize: 13 }}>Buyurtma yo'q</div>
            ) : visible.map(o => (
              <div key={o.id} onClick={() => setSelected(o.id)} style={{
                padding: '14px 16px', borderBottom: `1px solid ${C.border}`, cursor: 'pointer',
                background: selected === o.id ? `${C.primary}11` : 'transparent',
                borderLeft: `3px solid ${selected === o.id ? C.primary : 'transparent'}`,
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ color: C.text, fontWeight: 700, fontSize: 14 }}>{o.order_number}</span>
                    <span style={{ background: `${STATUS_COLOR[o.status] || C.muted}22`, color: STATUS_COLOR[o.status] || C.muted, fontSize: 10, fontWeight: 600, padding: '2px 8px', borderRadius: 20 }}>
                      {STATUS_LABEL[o.status] || o.status}
                    </span>
                  </div>
                  <div style={{ color: C.muted, fontSize: 12, marginTop: 3 }}>{o.table?.name} · {o.table?.hall?.name_uz} · {o.waiter?.name}</div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{ color: C.primary, fontWeight: 700, fontSize: 14 }}>{fmt(orderTotal(o))}</div>
                  <div style={{ color: C.muted, fontSize: 11, marginTop: 2 }}>{timeStr(o.created_at)}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* O'ng: tafsilot */}
        <div style={{ flex: 1, display: isMobile && !selected ? 'none' : 'flex', flexDirection: 'column', overflow: 'hidden', width: isMobile ? '100%' : 'auto' }}>
          {current ? (
            <>
              {isMobile && (
                <button onClick={() => setSelected(null)} style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '10px 16px', cursor: 'pointer', color: C.text, fontWeight: 600, fontSize: 13, margin: '10px 16px 0', display: 'flex', alignItems: 'center', gap: 6 }}>← Orqaga</button>
              )}
              <div style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, padding: '16px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <span style={{ color: C.text, fontWeight: 700, fontSize: 18 }}>{current.order_number}</span>
                    <span style={{ background: `${STATUS_COLOR[current.status]}22`, color: STATUS_COLOR[current.status], fontSize: 12, fontWeight: 600, padding: '3px 10px', borderRadius: 20 }}>
                      {STATUS_LABEL[current.status]}
                    </span>
                  </div>
                  <div style={{ color: C.muted, fontSize: 13, marginTop: 4 }}>{current.table?.name} · {current.table?.hall?.name_uz} · Ofitsiant: {current.waiter?.name}</div>
                </div>
                <div style={{ display: 'flex', gap: 8 }}>
                  <button onClick={() => setReceipt({ order: current, preview: true })}
                    style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '9px 14px', color: C.muted, fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Printer size={15} /> Chek
                  </button>
                  {!['paid', 'cancelled'].includes(current.status) && (
                    <button onClick={() => setCancelConfirm(true)}
                      style={{ background: 'none', border: `1px solid ${C.danger}`, borderRadius: 8, padding: '9px 14px', color: C.danger, fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
                      <XCircle size={15} /> Bekor qilish
                    </button>
                  )}
                  {!['paid', 'cancelled'].includes(current.status) && (
                    <button onClick={openPayment}
                      style={{ background: C.primary, border: 'none', borderRadius: 8, padding: '9px 18px', color: '#fff', fontWeight: 700, fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
                      <CreditCard size={15} /> To'lash
                    </button>
                  )}
                </div>
              </div>

              <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
                <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                  <thead>
                    <tr style={{ background: C.surface }}>
                      {['Taom', 'Soni', 'Narxi', 'Jami'].map(h => (
                        <th key={h} style={{ padding: '10px 16px', textAlign: 'left', color: C.muted, fontSize: 12, fontWeight: 600 }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {(current.items || []).map((item, i) => (
                      <tr key={i} style={{ borderBottom: `1px solid ${C.border}` }}>
                        <td style={{ padding: '14px 16px', color: C.text, fontSize: 14 }}>{item.product_name}</td>
                        <td style={{ padding: '14px 16px', color: C.muted, fontSize: 14 }}>× {item.quantity}</td>
                        <td style={{ padding: '14px 16px', color: C.muted, fontSize: 14 }}>{fmt(item.product_price)}</td>
                        <td style={{ padding: '14px 16px', color: C.text, fontWeight: 600, fontSize: 14 }}>{fmt(parseFloat(item.product_price) * item.quantity)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div style={{ background: C.surface, borderTop: `1px solid ${C.border}`, padding: '16px 24px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ color: C.muted, fontSize: 12 }}>Jami summa</div>
                  <div style={{ color: C.primary, fontWeight: 800, fontSize: 26 }}>{fmt(orderTotal(current))}</div>
                </div>
                {!['paid', 'cancelled'].includes(current.status) ? (
                  <button onClick={openPayment} style={{ background: C.primary, border: 'none', borderRadius: 10, padding: '14px 32px', color: '#fff', fontWeight: 700, fontSize: 15, cursor: 'pointer' }}>
                    To'lovni qabul qilish
                  </button>
                ) : (
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, color: current.status === 'cancelled' ? C.danger : C.success }}>
                    <CheckCircle size={20} />
                    <span style={{ fontWeight: 700, fontSize: 15 }}>{current.status === 'cancelled' ? 'Bekor qilingan' : "To'langan"}</span>
                  </div>
                )}
              </div>
            </>
          ) : (
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 12 }}>
              <Receipt size={48} color={C.border} />
              <span style={{ color: C.muted, fontSize: 15 }}>Buyurtma tanlang</span>
            </div>
          )}
        </div>
      </div>

      {/* ── Modallar ── */}
      {shiftModal === 'open' && <ShiftOpenModal onConfirm={openShift} onClose={() => setShiftModal(null)} />}
      {shiftModal === 'close' && shift && <ShiftCloseModal shift={shift} onConfirm={closeShift} onClose={() => setShiftModal(null)} />}
      {shiftReport && <ShiftReportModal report={shiftReport} onClose={() => setShiftReport(null)} />}

      {payModal && current && <PayModal order={current} sum={orderTotal(current)} onClose={() => setPayModal(false)} onPay={handlePay} />}

      {receipt && <ReceiptModal order={receipt.order} method={receipt.method} cashReceived={receipt.cashReceived} discount={receipt.discount} onClose={() => setReceipt(null)} />}

      {kitchenWarn && current && (
        <div style={{ position: 'fixed', inset: 0, background: '#00000088', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div style={{ background: C.surface, border: `1px solid ${C.warning}44`, borderRadius: 14, width: 400, padding: 28 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
              <div style={{ background: `${C.warning}22`, borderRadius: 10, padding: 10 }}>
                <AlertCircle size={22} color={C.warning} />
              </div>
              <span style={{ color: C.text, fontWeight: 700, fontSize: 16 }}>Oshpaz hali tayyorlamagan</span>
            </div>
            <div style={{ background: C.card, borderRadius: 10, padding: 14, marginBottom: 16 }}>
              {(current.items || []).filter(i => ['pending', 'cooking'].includes(i.status)).map((item, i) => (
                <div key={i} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, fontSize: 13 }}>
                  <span style={{ color: C.text }}>{item.product_name}</span>
                  <span style={{ color: C.warning, fontWeight: 600 }}>{item.status === 'cooking' ? 'Pishirilmoqda' : 'Kutilmoqda'}</span>
                </div>
              ))}
            </div>
            <p style={{ color: C.muted, fontSize: 13, marginBottom: 20 }}>Shunga qaramay to'lovni qabul qilasizmi?</p>
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setKitchenWarn(false)} style={{ flex: 1, background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '11px 0', color: C.muted, cursor: 'pointer', fontWeight: 600 }}>Orqaga</button>
              <button onClick={() => { setKitchenWarn(false); setPayModal(true) }} style={{ flex: 1, background: C.primary, border: 'none', borderRadius: 8, padding: '11px 0', color: '#fff', cursor: 'pointer', fontWeight: 700 }}>Ha, to'lovni qabul qilish</button>
            </div>
          </div>
        </div>
      )}

      {cancelConfirm && current && (
        <div style={{ position: 'fixed', inset: 0, background: '#00000088', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
          <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 14, width: 380, padding: 28 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 14 }}>
              <XCircle size={22} color={C.danger} />
              <span style={{ color: C.text, fontWeight: 700, fontSize: 16 }}>Buyurtmani bekor qilish</span>
            </div>
            <p style={{ color: C.muted, fontSize: 14, marginBottom: 8 }}><strong style={{ color: C.text }}>{current.order_number}</strong> — {current.table?.name || "Stol yo'q"} bekor qilinadi.</p>
            <p style={{ color: C.muted, fontSize: 13, marginBottom: 24 }}>Stol bo'shatiladi. Bu amalni qaytarib bo'lmaydi.</p>
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setCancelConfirm(false)} style={{ flex: 1, background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '11px 0', color: C.muted, cursor: 'pointer', fontWeight: 600 }}>Orqaga</button>
              <button onClick={handleCancel} style={{ flex: 1, background: C.danger, border: 'none', borderRadius: 8, padding: '11px 0', color: '#fff', cursor: 'pointer', fontWeight: 700 }}>Ha, bekor qilish</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Smena ochish ─────────────────────────────────────────────────────────────
function ShiftOpenModal({ onConfirm, onClose }) {
  const [cash, setCash] = useState('')
  const [saving, setSaving] = useState(false)

  async function confirm() {
    setSaving(true)
    await onConfirm(cash)
    setSaving(false)
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#00000088', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 16, width: 380, padding: 28 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
          <div style={{ background: `${C.success}22`, borderRadius: 10, padding: 10 }}>
            <PlayCircle size={22} color={C.success} />
          </div>
          <div>
            <div style={{ color: C.text, fontWeight: 700, fontSize: 16 }}>Smena ochish</div>
            <div style={{ color: C.muted, fontSize: 12, marginTop: 2 }}>{new Date().toLocaleString('uz-UZ', { hour: '2-digit', minute: '2-digit', day: 'numeric', month: 'long' })}</div>
          </div>
        </div>
        <div style={{ marginBottom: 20 }}>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 8 }}>Kassadagi boshlang'ich naqd pul (ixtiyoriy)</div>
          <input type="number" value={cash} onChange={e => setCash(e.target.value)} placeholder="0"
            style={{ width: '100%', background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '12px 14px', color: C.text, fontSize: 16, fontWeight: 700, boxSizing: 'border-box', outline: 'none' }} />
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={onClose} style={{ flex: 1, background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '12px 0', color: C.muted, cursor: 'pointer', fontWeight: 600 }}>Bekor</button>
          <button onClick={confirm} disabled={saving} style={{ flex: 2, background: C.success, border: 'none', borderRadius: 8, padding: '12px 0', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 14 }}>
            {saving ? 'Ochilmoqda...' : 'Smena ochish'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Smena yopish ─────────────────────────────────────────────────────────────
function ShiftCloseModal({ shift, onConfirm, onClose }) {
  const [cash, setCash] = useState('')
  const [saving, setSaving] = useState(false)

  const stats = shift.stats || {}
  const byMethod = stats.by_method || {}

  async function confirm() {
    setSaving(true)
    await onConfirm(cash)
    setSaving(false)
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#00000088', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 16, width: 420, padding: 28, maxHeight: '90vh', overflowY: 'auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 20 }}>
          <div style={{ background: `${C.danger}22`, borderRadius: 10, padding: 10 }}>
            <StopCircle size={22} color={C.danger} />
          </div>
          <div>
            <div style={{ color: C.text, fontWeight: 700, fontSize: 16 }}>Smena yopish</div>
            <div style={{ color: C.muted, fontSize: 12, marginTop: 2 }}>Davomiyligi: {shift.opened_at ? duration(shift.opened_at) : '—'}</div>
          </div>
        </div>

        {/* Smena statistikasi */}
        <div style={{ background: C.card, borderRadius: 10, padding: 16, marginBottom: 16 }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 12 }}>
            <div>
              <div style={{ color: C.muted, fontSize: 11 }}>Jami buyurtmalar</div>
              <div style={{ color: C.text, fontWeight: 700, fontSize: 18 }}>{stats.orders_total || 0} ta</div>
            </div>
            <div>
              <div style={{ color: C.muted, fontSize: 11 }}>To'langan</div>
              <div style={{ color: C.success, fontWeight: 700, fontSize: 18 }}>{stats.orders_paid || 0} ta</div>
            </div>
          </div>
          <div style={{ borderTop: `1px solid ${C.border}`, paddingTop: 12 }}>
            <div style={{ color: C.muted, fontSize: 11, marginBottom: 4 }}>Jami tushum</div>
            <div style={{ color: C.primary, fontWeight: 800, fontSize: 22 }}>{fmt(stats.revenue || 0)}</div>
          </div>
          {Object.keys(byMethod).length > 0 && (
            <div style={{ borderTop: `1px solid ${C.border}`, paddingTop: 12, marginTop: 12 }}>
              <div style={{ color: C.muted, fontSize: 11, marginBottom: 8 }}>To'lov usuli bo'yicha</div>
              {Object.entries(byMethod).map(([method, data]) => (
                <div key={method} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, fontSize: 13 }}>
                  <span style={{ color: C.muted }}>{METHOD_UZ[method] || method} ({data.count} ta)</span>
                  <span style={{ color: C.text, fontWeight: 600 }}>{fmt(data.amount)}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        <div style={{ marginBottom: 20 }}>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 8 }}>Kassadagi yakuniy naqd pul (ixtiyoriy)</div>
          <input type="number" value={cash} onChange={e => setCash(e.target.value)} placeholder="0"
            style={{ width: '100%', background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '12px 14px', color: C.text, fontSize: 16, fontWeight: 700, boxSizing: 'border-box', outline: 'none' }} />
        </div>

        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={onClose} style={{ flex: 1, background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '12px 0', color: C.muted, cursor: 'pointer', fontWeight: 600 }}>Bekor</button>
          <button onClick={confirm} disabled={saving} style={{ flex: 2, background: C.danger, border: 'none', borderRadius: 8, padding: '12px 0', color: '#fff', fontWeight: 700, cursor: 'pointer', fontSize: 14 }}>
            {saving ? 'Yopilmoqda...' : 'Smena yopish'}
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Smena yakuniy hisobot ────────────────────────────────────────────────────
function ShiftReportModal({ report, onClose }) {
  const stats = report.stats || {}
  const byMethod = stats.by_method || {}

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#00000088', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 16, width: 400, padding: 28 }}>
        <div style={{ textAlign: 'center', marginBottom: 20 }}>
          <div style={{ background: `${C.success}22`, width: 52, height: 52, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px' }}>
            <TrendingUp size={24} color={C.success} />
          </div>
          <div style={{ color: C.text, fontWeight: 700, fontSize: 17 }}>Smena yopildi</div>
          <div style={{ color: C.muted, fontSize: 12, marginTop: 4 }}>
            {timeStr(report.opened_at)} — {timeStr(report.closed_at)}
          </div>
        </div>

        <div style={{ background: C.card, borderRadius: 10, padding: 16, marginBottom: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8, fontSize: 13 }}>
            <span style={{ color: C.muted }}>Jami buyurtmalar</span>
            <span style={{ color: C.text, fontWeight: 600 }}>{stats.orders_total || 0} ta</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8, fontSize: 13 }}>
            <span style={{ color: C.muted }}>To'langan</span>
            <span style={{ color: C.success, fontWeight: 600 }}>{stats.orders_paid || 0} ta</span>
          </div>
          <div style={{ borderTop: `1px solid ${C.border}`, paddingTop: 10, marginTop: 4 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 15 }}>
              <span style={{ color: C.muted }}>Jami tushum</span>
              <span style={{ color: C.primary, fontWeight: 800, fontSize: 18 }}>{fmt(stats.revenue || 0)}</span>
            </div>
          </div>
          {Object.keys(byMethod).length > 0 && (
            <div style={{ borderTop: `1px solid ${C.border}`, paddingTop: 10, marginTop: 10 }}>
              {Object.entries(byMethod).map(([method, data]) => (
                <div key={method} style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4, fontSize: 12 }}>
                  <span style={{ color: C.muted }}>{METHOD_UZ[method] || method} ({data.count} ta)</span>
                  <span style={{ color: C.text }}>{fmt(data.amount)}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        <button onClick={onClose} style={{ width: '100%', background: C.primary, border: 'none', borderRadius: 8, padding: '12px 0', color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer' }}>
          Yopish
        </button>
      </div>
    </div>
  )
}

// ─── To'lov modali ────────────────────────────────────────────────────────────
function PayModal({ order, sum, onClose, onPay }) {
  const [method,      setMethod]      = useState('cash')
  const [given,       setGiven]       = useState('')
  const [discountVal, setDiscountVal] = useState('')
  const [discountType, setDiscType]   = useState('%')   // '%' yoki 'sum'
  const [paying,      setPaying]      = useState(false)

  // Chegirma hisoblash
  const discNum     = parseFloat(discountVal) || 0
  const discountAmt = discountType === '%'
    ? Math.round(sum * discNum / 100)
    : Math.min(discNum, sum)
  const finalSum    = Math.max(0, sum - discountAmt)

  const givenNum = parseFloat(given) || 0
  const change   = givenNum - finalSum

  async function confirm() {
    if (method === 'cash' && given && givenNum < finalSum) return
    setPaying(true)
    await onPay(method, givenNum, discountAmt)
    setPaying(false)
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#00000088', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }}>
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 16, width: 420, padding: 28 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <span style={{ color: C.text, fontWeight: 700, fontSize: 17 }}>To'lovni qabul qilish</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted }}><X size={20} /></button>
        </div>

        {/* Narx bloki */}
        <div style={{ background: C.card, borderRadius: 10, padding: 14, marginBottom: 16 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
            <span style={{ color: C.muted, fontSize: 13 }}>{order.order_number} · {order.table?.name}</span>
            <span style={{ color: C.muted, fontSize: 13 }}>{order.items?.length} ta taom</span>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            {discountAmt > 0 ? (
              <div>
                <div style={{ color: C.muted, fontSize: 13, textDecoration: 'line-through' }}>{fmt(sum)}</div>
                <div style={{ color: C.primary, fontWeight: 800, fontSize: 24 }}>{fmt(finalSum)}</div>
              </div>
            ) : (
              <div style={{ color: C.primary, fontWeight: 800, fontSize: 24 }}>{fmt(sum)}</div>
            )}
            {discountAmt > 0 && (
              <div style={{ background: `${C.success}22`, border: `1px solid ${C.success}44`, borderRadius: 8, padding: '4px 10px', color: C.success, fontSize: 13, fontWeight: 700 }}>
                -{fmt(discountAmt)}
              </div>
            )}
          </div>
        </div>

        {/* Chegirma */}
        <div style={{ marginBottom: 16 }}>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 8 }}>Chegirma (ixtiyoriy)</div>
          <div style={{ display: 'flex', gap: 8 }}>
            <div style={{ display: 'flex', background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, overflow: 'hidden', flexShrink: 0 }}>
              {['%', "so'm"].map(t => (
                <button key={t} onClick={() => { setDiscType(t === "so'm" ? 'sum' : '%'); setDiscountVal('') }}
                  style={{ padding: '10px 12px', background: (t === '%' ? discountType === '%' : discountType === 'sum') ? C.primary : 'transparent',
                    border: 'none', cursor: 'pointer', color: (t === '%' ? discountType === '%' : discountType === 'sum') ? '#fff' : C.muted,
                    fontWeight: 600, fontSize: 13 }}>{t}</button>
              ))}
            </div>
            <input type="number" value={discountVal} onChange={e => setDiscountVal(e.target.value)}
              placeholder={discountType === '%' ? '0 – 100' : '0'}
              min="0" max={discountType === '%' ? '100' : sum}
              style={{ flex: 1, background: C.card, border: `1px solid ${C.border}`, borderRadius: 8,
                padding: '10px 14px', color: C.text, fontSize: 15, fontWeight: 700, outline: 'none', boxSizing: 'border-box' }} />
          </div>
        </div>

        {/* To'lov turi */}
        <div style={{ marginBottom: 16 }}>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 8 }}>To'lov turi</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
            {PAY_METHODS.map(({ key, label, icon: Icon }) => (
              <button key={key} onClick={() => setMethod(key)} style={{
                background: method === key ? `${C.primary}22` : C.card, border: `1px solid ${method === key ? C.primary : C.border}`,
                borderRadius: 8, padding: '10px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8,
                color: method === key ? C.primary : C.muted, fontWeight: method === key ? 700 : 400, fontSize: 13,
              }}><Icon size={16} /> {label}</button>
            ))}
          </div>
        </div>

        {/* Naqd bo'lsa — berilgan summa */}
        {method === 'cash' && (
          <div style={{ marginBottom: 16 }}>
            <div style={{ color: C.muted, fontSize: 12, marginBottom: 8 }}>Berilgan summa</div>
            <input type="number" value={given} onChange={e => setGiven(e.target.value)} placeholder={finalSum.toString()}
              style={{ width: '100%', background: C.card, border: `1px solid ${C.border}`, borderRadius: 8,
                padding: '12px 14px', color: C.text, fontSize: 16, fontWeight: 700, boxSizing: 'border-box', outline: 'none' }} />
            {givenNum >= finalSum && given && (
              <div style={{ marginTop: 8, display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: C.muted, fontSize: 13 }}>Qaytim:</span>
                <span style={{ color: C.success, fontWeight: 700, fontSize: 15 }}>{fmt(change)}</span>
              </div>
            )}
            {givenNum > 0 && givenNum < finalSum && <div style={{ marginTop: 6, color: C.danger, fontSize: 12 }}>Summa yetarli emas</div>}
          </div>
        )}

        <button onClick={confirm} disabled={paying || (method === 'cash' && given && givenNum < finalSum)} style={{
          width: '100%', background: C.primary, border: 'none', borderRadius: 10, padding: '14px 0',
          color: '#fff', fontWeight: 700, fontSize: 15, cursor: 'pointer',
          opacity: (paying || (method === 'cash' && given && givenNum < finalSum)) ? 0.5 : 1,
        }}>
          <CheckCircle size={16} style={{ marginRight: 8, verticalAlign: 'middle' }} />
          {paying ? 'Amalga oshirilmoqda...' : `To'lovni tasdiqlash · ${fmt(finalSum)}`}
        </button>
      </div>
    </div>
  )
}

// ─── Chek modali ──────────────────────────────────────────────────────────────
function ReceiptModal({ order, method, cashReceived, discount = 0, onClose }) {
  const receiptRef = useRef(null)
  const total      = orderTotal(order)
  const change     = cashReceived ? cashReceived - total : 0
  const now        = new Date()
  const cafeName   = localStorage.getItem('pos_cafe_name') || 'Kafe POS'
  const cafeAddr   = localStorage.getItem('pos_address') || ''
  const cafePhone  = localStorage.getItem('pos_phone') || ''
  const lines      = (order.items || []).filter(i => i.status !== 'cancelled')

  function print() {
    const content = receiptRef.current?.innerHTML
    if (!content) return
    const w = window.open('', '_blank', 'width=400,height=700')
    w.document.write(`<!DOCTYPE html><html><head><meta charset="utf-8"><title>Chek ${order.order_number}</title>
      <style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:'Courier New',monospace;font-size:13px;color:#000;background:#fff;padding:8px;width:280px}
      .center{text-align:center}.bold{font-weight:bold}.line{border-top:1px dashed #000;margin:8px 0}
      .row{display:flex;justify-content:space-between;margin:3px 0}.small{font-size:11px}
      @media print{@page{margin:0;size:80mm auto}body{width:100%}}</style>
      </head><body>${content}
      <script>window.onload=()=>{window.print();setTimeout(()=>window.close(),1500)}<\/script></body></html>`)
    w.document.close()
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: '#00000099', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 16, width: 380, maxHeight: '90vh', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        <div style={{ padding: '16px 20px', borderBottom: `1px solid ${C.border}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ color: C.text, fontWeight: 700, fontSize: 15 }}>Chek ko'rinishi</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted }}><X size={18} /></button>
        </div>
        <div style={{ flex: 1, overflowY: 'auto', padding: 20 }}>
          <div style={{ background: '#fff', color: '#000', borderRadius: 8, padding: '16px 14px', fontFamily: "'Courier New', monospace", fontSize: 13 }}>
            <div ref={receiptRef}>
              <div style={{ textAlign: 'center', fontWeight: 'bold', fontSize: 15, marginBottom: 2 }}>{cafeName}</div>
              {cafeAddr && <div style={{ textAlign: 'center', fontSize: 11, marginBottom: 2 }}>{cafeAddr}</div>}
              {cafePhone && <div style={{ textAlign: 'center', fontSize: 11, marginBottom: 6 }}>{cafePhone}</div>}
              <div style={{ borderTop: '1px dashed #000', margin: '6px 0' }} />
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                <span>Raqam:</span><span style={{ fontWeight: 'bold' }}>#{order.order_number}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                <span>Sana:</span><span>{now.toLocaleDateString('uz-UZ')}</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                <span>Vaqt:</span><span>{now.toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' })}</span>
              </div>
              {order.table && <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                <span>Stol:</span><span>{order.table.name}</span>
              </div>}
              <div style={{ borderTop: '1px dashed #000', margin: '6px 0' }} />
              {lines.map((item, i) => (
                <div key={i} style={{ marginBottom: 4 }}>
                  <div style={{ fontWeight: 'bold' }}>{item.name_uz || item.product_name}</div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12 }}>
                    <span>{item.quantity} x {Number(item.product_price || 0).toLocaleString('uz-UZ')}</span>
                    <span>{Number((item.product_price || 0) * (item.quantity || 1)).toLocaleString('uz-UZ')}</span>
                  </div>
                </div>
              ))}
              <div style={{ borderTop: '1px dashed #000', margin: '6px 0' }} />
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                <span>Jami:</span><span>{Number(total).toLocaleString('uz-UZ')} so'm</span>
              </div>
              {parseFloat(order.discount) > 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2, color: '#666' }}>
                  <span>Chegirma:</span><span>-{Number(order.discount).toLocaleString('uz-UZ')} so'm</span>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', fontWeight: 'bold', fontSize: 15, marginBottom: 2 }}>
                <span>TO'LOV:</span><span>{Number(order.total || total).toLocaleString('uz-UZ')} so'm</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                <span>Usul:</span>
                <span>{{ cash: 'Naqd', card: 'Karta', click: 'Click', payme: 'Payme', transfer: "O'tkazma", debt: 'Qarz' }[method] || method}</span>
              </div>
              {method === 'cash' && cashReceived > 0 && <>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                  <span>Berildi:</span><span>{Number(cashReceived).toLocaleString('uz-UZ')} so'm</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 2 }}>
                  <span>Qaytim:</span><span>{Number(Math.max(0, change)).toLocaleString('uz-UZ')} so'm</span>
                </div>
              </>}
              <div style={{ borderTop: '1px dashed #000', margin: '10px 0 6px' }} />
              <div style={{ textAlign: 'center', fontSize: 11 }}>Tashrif uchun rahmat!</div>
            </div>
          </div>
        </div>
        <div style={{ padding: '14px 20px', borderTop: `1px solid ${C.border}`, display: 'flex', gap: 10 }}>
          <button onClick={print} style={{
            flex: 1, background: C.primary, border: 'none', borderRadius: 10, padding: '12px',
            color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
          }}>
            <Printer size={16} /> Chop etish
          </button>
          <button onClick={onClose} style={{
            flex: 1, background: C.card, border: `1px solid ${C.border}`, borderRadius: 10, padding: '12px',
            color: C.text, fontWeight: 600, fontSize: 14, cursor: 'pointer',
          }}>
            Yopish
          </button>
        </div>
      </div>
    </div>
  )
}

