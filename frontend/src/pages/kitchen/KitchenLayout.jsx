import { useState, useEffect, useRef } from 'react'
import {
  ChefHat, Clock, CheckCircle, Bell, RefreshCw,
  AlertTriangle, Flame, UtensilsCrossed, LogOut, Check
} from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { kitchenApi } from '../../services/api'

const C = {
  bg:       '#0F172A',
  surface:  '#1E293B',
  card:     '#263548',
  border:   '#334155',
  primary:  '#F97316',
  text:     '#F1F5F9',
  muted:    '#94A3B8',
  success:  '#22C55E',
  warning:  '#EAB308',
  danger:   '#EF4444',
  new:      '#3B82F6',
}

const STATUS = {
  new:     { label: 'Yangi',          color: C.new,     icon: Bell },
  cooking: { label: 'Pishirilmoqda',  color: C.primary, icon: Flame },
  ready:   { label: 'Tayyor',         color: C.success,  icon: CheckCircle },
}

// Kutish vaqtiga qarab rang: yashil → sariq → qizil
function waitColor(date) {
  const m = Math.floor((Date.now() - new Date(date)) / 60000)
  if (m >= 20) return C.danger
  if (m >= 10) return C.warning
  return C.success
}

function elapsedMins(date) {
  return Math.floor((Date.now() - new Date(date)) / 60000)
}

function elapsedLabel(date) {
  const m = elapsedMins(date)
  if (m < 1) return '< 1 daq'
  return `${m} daq`
}

function useTimer() {
  const [, setTick] = useState(0)
  useEffect(() => {
    const t = setInterval(() => setTick(n => n + 1), 5000)
    return () => clearInterval(t)
  }, [])
}

function useIsMobile() {
  const [m, setM] = useState(window.innerWidth < 768)
  useEffect(() => {
    const h = () => setM(window.innerWidth < 768)
    window.addEventListener('resize', h)
    return () => window.removeEventListener('resize', h)
  }, [])
  return m
}

export default function KitchenLayout() {
  const { user, logout } = useAuth()
  const [tickets, setTickets]     = useState([])
  const [filter, setFilter]       = useState('all')
  const [online, setOnline]       = useState(true)
  const [newBanner, setNewBanner] = useState(false)   // yangi buyurtma banner
  const prevCountRef = useRef(null)
  const isMobile = useIsMobile()
  useTimer()

  function playBeep() {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)()
      // 3 ta qisqa signal — e'tibor jalb qilish uchun
      [0, 0.25, 0.5].forEach(offset => {
        const osc = ctx.createOscillator()
        const gain = ctx.createGain()
        osc.connect(gain); gain.connect(ctx.destination)
        osc.frequency.value = 880
        gain.gain.setValueAtTime(0.4, ctx.currentTime + offset)
        gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + offset + 0.2)
        osc.start(ctx.currentTime + offset)
        osc.stop(ctx.currentTime + offset + 0.2)
      })
    } catch {}
  }

  useEffect(() => { loadTickets() }, [])
  useEffect(() => {
    const t = setInterval(loadTickets, 5000)
    return () => clearInterval(t)
  }, [])

  async function loadTickets() {
    try {
      const res = await kitchenApi.getTickets()
      const mapped = res.data.map(o => ({
        id:          o.id,
        orderNumber: o.order_number,
        table:       o.table?.name || 'Olib ketish',
        hall:        o.table?.hall?.name_uz || '',
        waiter:      o.waiter?.name || '',
        createdAt:   o.created_at,
        status:      mapStatus(o),
        items: (o.items || [])
          .filter(i => i.status === 'pending' || i.status === 'cooking' || i.status === 'ready')
          .map(i => ({
            id:     i.id,
            name:   i.product_name?.split(' / ')[0] || i.product_name,
            qty:    i.quantity,
            note:   i.note || '',
            status: i.status,
          })),
      }))
      setTickets(prev => {
        const prevCount = prevCountRef.current
        if (prevCount !== null && mapped.length > prevCount) {
          playBeep()
          setNewBanner(true)
          setTimeout(() => setNewBanner(false), 4000)
        }
        prevCountRef.current = mapped.length
        return mapped
      })
      setOnline(true)
    } catch {
      setOnline(false)
    }
  }

  function mapStatus(order) {
    if (order.status === 'ready') return 'ready'
    const items = order.items || []
    const active = items.filter(i => i.status !== 'cancelled' && i.status !== 'served')
    if (active.length === 0) return 'new'
    if (active.every(i => i.status === 'ready')) return 'ready'
    if (active.some(i => i.status === 'cooking')) return 'cooking'
    return 'new'
  }

  async function advance(id) {
    const ticket = tickets.find(t => t.id === id)
    const nextStatus = ticket?.status === 'new' ? 'cooking' : 'ready'
    try {
      await kitchenApi.updateOrderStatus(id, nextStatus)
      setTickets(prev => prev.map(t => t.id === id ? { ...t, status: nextStatus } : t))
    } catch {}
  }

  async function markItemDone(ticketId, itemId) {
    try {
      await kitchenApi.updateItemStatus(itemId, 'ready')
      setTickets(prev => prev.map(t =>
        t.id !== ticketId ? t : {
          ...t,
          items: t.items.map(i => i.id === itemId ? { ...i, status: 'ready' } : i),
        }
      ))
    } catch {}
  }

  async function dismiss(id) {
    setTickets(prev => prev.filter(t => t.id !== id))
  }

  const counts = {
    all:     tickets.length,
    new:     tickets.filter(t => t.status === 'new').length,
    cooking: tickets.filter(t => t.status === 'cooking').length,
    ready:   tickets.filter(t => t.status === 'ready').length,
  }

  const visible = filter === 'all' ? tickets : tickets.filter(t => t.status === filter)
  const sorted  = [...visible].sort((a, b) => {
    const order = { new: 0, cooking: 1, ready: 2 }
    return order[a.status] - order[b.status] || new Date(a.createdAt) - new Date(b.createdAt)
  })

  return (
    <div style={{ minHeight: '100vh', background: C.bg, display: 'flex', flexDirection: 'column', fontFamily: 'system-ui, sans-serif' }}>

      {/* Yangi buyurtma banneri */}
      {newBanner && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, zIndex: 9999,
          background: C.new, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12,
          padding: '16px 20px', fontSize: isMobile ? 18 : 22, fontWeight: 800,
          boxShadow: `0 4px 30px ${C.new}88`,
          animation: 'none',
        }}>
          <Bell size={isMobile ? 22 : 28} />
          🆕 YANGI BUYURTMA KELDI!
        </div>
      )}

      {/* Header */}
      <header style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, padding: isMobile ? '0 12px' : '0 24px', height: isMobile ? 52 : 60, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <UtensilsCrossed size={isMobile ? 18 : 22} color={C.primary} />
          <span style={{ color: C.text, fontWeight: 700, fontSize: isMobile ? 15 : 18 }}>Oshpaz paneli</span>
          {!isMobile && (
            <span style={{ background: C.card, color: C.muted, fontSize: 12, padding: '3px 10px', borderRadius: 20, border: `1px solid ${C.border}` }}>
              {user?.name}
            </span>
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: isMobile ? 8 : 16 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: online ? C.success : C.danger, boxShadow: online ? `0 0 0 3px ${C.success}33` : 'none' }} />
            {!isMobile && <span style={{ color: C.muted, fontSize: 12 }}>{online ? 'Jonli' : 'Uzilgan'}</span>}
          </div>
          <button onClick={loadTickets} style={iconBtn}><RefreshCw size={16} color={C.muted} /></button>
          <button onClick={logout} style={iconBtn}><LogOut size={16} color={C.muted} /></button>
        </div>
      </header>

      {/* Filter tabs */}
      <div style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, padding: isMobile ? '0 8px' : '0 24px', display: 'flex', gap: 4, overflowX: 'auto' }}>
        {[
          { key: 'all',     label: 'Barchasi' },
          { key: 'new',     label: 'Yangi' },
          { key: 'cooking', label: 'Pishirilmoqda' },
          { key: 'ready',   label: 'Tayyor' },
        ].map(({ key, label }) => (
          <button key={key} onClick={() => setFilter(key)} style={{
            background: 'none', border: 'none', cursor: 'pointer',
            padding: '14px 16px', fontSize: 13, fontWeight: 600,
            color: filter === key ? C.primary : C.muted,
            borderBottom: `2px solid ${filter === key ? C.primary : 'transparent'}`,
            display: 'flex', alignItems: 'center', gap: 6, whiteSpace: 'nowrap',
          }}>
            {label}
            <span style={{
              background: filter === key ? C.primary : C.card,
              color: filter === key ? '#fff' : C.muted,
              borderRadius: 20, padding: '1px 7px', fontSize: 11,
            }}>{counts[key]}</span>
          </button>
        ))}
      </div>

      {/* Ticket grid */}
      <div style={{ flex: 1, padding: isMobile ? 10 : 20, overflowY: 'auto' }}>
        {sorted.length === 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: 300, gap: 12 }}>
            <ChefHat size={48} color={C.border} />
            <span style={{ color: C.muted, fontSize: 15 }}>Buyurtma yo'q</span>
          </div>
        ) : (
          <div style={{ display: 'grid', gridTemplateColumns: isMobile ? '1fr' : 'repeat(auto-fill, minmax(300px, 1fr))', gap: isMobile ? 10 : 16 }}>
            {sorted.map(ticket => (
              <TicketCard
                key={ticket.id}
                ticket={ticket}
                isMobile={isMobile}
                onAdvance={() => advance(ticket.id)}
                onDismiss={() => dismiss(ticket.id)}
                onItemDone={(itemId) => markItemDone(ticket.id, itemId)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Footer */}
      <footer style={{ background: C.surface, borderTop: `1px solid ${C.border}`, padding: isMobile ? '8px 12px' : '10px 24px', display: 'flex', gap: isMobile ? 16 : 24, alignItems: 'center', flexWrap: 'wrap' }}>
        <StatBadge label="Yangi"          value={counts.new}     color={C.new} />
        <StatBadge label="Pishirilmoqda"  value={counts.cooking} color={C.primary} />
        <StatBadge label="Tayyor"         value={counts.ready}   color={C.success} />
        {!isMobile && (
          <div style={{ marginLeft: 'auto', color: C.muted, fontSize: 12, display: 'flex', alignItems: 'center', gap: 6 }}>
            <Clock size={13} /> Har 5 soniyada yangilanadi
          </div>
        )}
      </footer>
    </div>
  )
}

function TicketCard({ ticket, isMobile, onAdvance, onDismiss, onItemDone }) {
  const st       = STATUS[ticket.status]
  const Icon     = st.icon
  const wColor   = ticket.status !== 'ready' ? waitColor(ticket.createdAt) : C.muted
  const mins     = elapsedMins(ticket.createdAt)
  const isUrgent = mins >= 20 && ticket.status !== 'ready'
  const doneCount = ticket.items.filter(i => i.status === 'ready').length
  const allDone   = doneCount === ticket.items.length && ticket.items.length > 0

  return (
    <div style={{
      background: C.card,
      border: `1px solid ${isUrgent ? C.danger : C.border}`,
      borderTop: `4px solid ${st.color}`,
      borderRadius: 12,
      overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
      boxShadow: isUrgent ? `0 0 16px ${C.danger}44` : 'none',
    }}>

      {/* Stol raqami — katta */}
      <div style={{ background: C.surface, padding: '10px 16px 6px', borderBottom: `1px solid ${C.border}` }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          {/* Stol raqami — eng muhim ma'lumot */}
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span style={{ color: C.primary, fontWeight: 900, fontSize: isMobile ? 26 : 30, lineHeight: 1 }}>
              {ticket.table}
            </span>
            {ticket.hall && (
              <span style={{ color: C.muted, fontSize: 12 }}>{ticket.hall}</span>
            )}
          </div>
          {/* Holat */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
            <Icon size={13} color={st.color} />
            <span style={{ color: st.color, fontSize: 12, fontWeight: 700 }}>{st.label}</span>
          </div>
        </div>

        {/* Ofitsiant + buyurtma raqami + vaqt */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 4 }}>
          <div style={{ color: C.muted, fontSize: 12 }}>
            {ticket.orderNumber} · {ticket.waiter}
          </div>
          {/* Vaqt — rangli */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, background: `${wColor}22`, borderRadius: 20, padding: '3px 10px' }}>
            <Clock size={11} color={wColor} />
            <span style={{ color: wColor, fontSize: 12, fontWeight: 700 }}>{elapsedLabel(ticket.createdAt)}</span>
            {isUrgent && <AlertTriangle size={11} color={C.danger} />}
          </div>
        </div>
      </div>

      {/* Taomlar ro'yxati — har birini belgilash mumkin */}
      <div style={{ padding: '8px 16px', flex: 1 }}>
        {ticket.items.map((item, i) => {
          const done = item.status === 'ready'
          return (
            <div key={item.id} style={{
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              padding: '8px 0',
              borderBottom: i < ticket.items.length - 1 ? `1px solid ${C.border}` : 'none',
              opacity: done ? 0.45 : 1,
            }}>
              <div style={{ flex: 1 }}>
                <span style={{
                  color: C.text, fontSize: isMobile ? 15 : 14,
                  fontWeight: 600,
                  textDecoration: done ? 'line-through' : 'none',
                }}>
                  {item.name}
                </span>
                {item.note ? (
                  <div style={{ color: C.warning, fontSize: 11, marginTop: 2 }}>⚠️ {item.note}</div>
                ) : null}
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{
                  background: C.surface, color: C.primary,
                  fontWeight: 800, fontSize: isMobile ? 17 : 15,
                  borderRadius: 6, padding: '2px 10px', minWidth: 32, textAlign: 'center',
                }}>×{item.qty}</span>
                {/* Tayyor tugmasi — har bir taom uchun */}
                {ticket.status !== 'ready' && !done && (
                  <button onClick={() => onItemDone(item.id)} title="Tayyor" style={{
                    width: 30, height: 30, borderRadius: 8,
                    background: 'none', border: `1.5px solid ${C.border}`,
                    cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    flexShrink: 0,
                  }}>
                    <Check size={14} color={C.muted} />
                  </button>
                )}
                {done && (
                  <div style={{ width: 30, height: 30, borderRadius: 8, background: `${C.success}22`, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                    <Check size={14} color={C.success} />
                  </div>
                )}
              </div>
            </div>
          )
        })}
      </div>

      {/* Progress bar */}
      {ticket.items.length > 0 && ticket.status !== 'ready' && (
        <div style={{ padding: '0 16px 8px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
            <span style={{ color: C.muted, fontSize: 11 }}>Tayyor bo'ldi</span>
            <span style={{ color: C.muted, fontSize: 11 }}>{doneCount}/{ticket.items.length}</span>
          </div>
          <div style={{ background: C.border, borderRadius: 4, height: 5 }}>
            <div style={{
              background: allDone ? C.success : C.primary,
              height: '100%', borderRadius: 4,
              width: `${Math.round(doneCount / ticket.items.length * 100)}%`,
              transition: 'width 0.3s',
            }} />
          </div>
        </div>
      )}

      {/* Amallar */}
      <div style={{ padding: '10px 16px', display: 'flex', gap: 8 }}>
        {ticket.status === 'new' && (
          <button onClick={onAdvance} style={{
            flex: 1, background: C.primary, color: '#fff',
            border: 'none', borderRadius: 8,
            padding: '12px 0', fontWeight: 700, fontSize: isMobile ? 15 : 13, cursor: 'pointer',
          }}>
            🍳 Pishira boshlash
          </button>
        )}
        {ticket.status === 'cooking' && (
          <button onClick={onAdvance} style={{
            flex: 1, background: allDone ? C.success : C.surface,
            color: allDone ? '#fff' : C.muted,
            border: `1.5px solid ${allDone ? C.success : C.border}`,
            borderRadius: 8, padding: '12px 0',
            fontWeight: 700, fontSize: isMobile ? 15 : 13, cursor: 'pointer',
          }}>
            ✅ Tayyor!
          </button>
        )}
        {ticket.status === 'ready' && (
          <button onClick={onDismiss} style={{
            flex: 1, background: C.surface, color: C.muted,
            border: `1px solid ${C.border}`, borderRadius: 8,
            padding: '12px 0', fontWeight: 600, fontSize: isMobile ? 15 : 13, cursor: 'pointer',
          }}>
            Yopish
          </button>
        )}
      </div>
    </div>
  )
}

function StatBadge({ label, value, color }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
      <span style={{ color, fontSize: 20, fontWeight: 800 }}>{value}</span>
      <span style={{ color: C.muted, fontSize: 12 }}>{label}</span>
    </div>
  )
}

const iconBtn = {
  background: 'none', border: 'none', cursor: 'pointer',
  padding: 8, borderRadius: 8, display: 'flex', alignItems: 'center',
}
