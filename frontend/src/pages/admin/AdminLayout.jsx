import { useState, useEffect, useCallback } from 'react'
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts'
import {
  LayoutDashboard, UtensilsCrossed, Grid3X3, Users,
  BarChart2, Settings, LogOut, ChevronRight, Menu,
  TrendingUp, ShoppingBag, Clock, DollarSign,
  Plus, Edit2, Trash2, ToggleLeft, ToggleRight,
  Coffee, Search, X, ClipboardList, ChevronDown, ChevronUp, RefreshCw,
  CalendarClock, CheckCircle, XCircle, Package, ArrowDownCircle, ArrowUpCircle, AlertTriangle, Wallet
} from 'lucide-react'
import { useAuth } from '../../context/AuthContext'
import { menuApi, tablesApi, usersApi, ordersApi, shiftApi, paymentsApi, stockApi, expenseApi } from '../../services/api'
import SalaryPage from './SalaryPage'

const C = {
  bg:      '#0F172A', surface: '#1E293B', card: '#263548',
  border:  '#334155', primary: '#F97316', text: '#F1F5F9',
  muted:   '#94A3B8', success: '#22C55E', danger: '#EF4444', warning: '#EAB308',
}

const NAV = [
  { key: 'dashboard', label: 'Bosh sahifa',   icon: LayoutDashboard },
  { key: 'orders',    label: 'Buyurtmalar',   icon: ClipboardList },
  { key: 'menu',      label: 'Menyu',          icon: UtensilsCrossed },
  { key: 'tables',    label: 'Stollar',         icon: Grid3X3 },
  { key: 'staff',     label: 'Xodimlar',        icon: Users },
  { key: 'shifts',    label: 'Smenalar',        icon: CalendarClock },
  { key: 'stock',     label: 'Sklad',            icon: Package },
  { key: 'expenses',  label: 'Xarajatlar',       icon: Wallet },
  { key: 'salary',    label: 'Maosh',            icon: DollarSign },
  { key: 'reports',   label: 'Hisobotlar',      icon: BarChart2 },
  { key: 'settings',  label: 'Sozlamalar',      icon: Settings },
]

const ROLE_LABELS = {
  admin: 'Admin', manager: 'Menejer', cashier: 'Kassir',
  waiter: 'Ofitsiant', kitchen: 'Oshpaz',
}

const fmt = n => Number(n || 0).toLocaleString('uz-UZ') + " so'm"

// UTC timestamp ni to'g'ri parse qilish (Laravel UTC qaytaradi)
function toDate(dt) {
  if (!dt) return null
  const s = String(dt).replace(' ', 'T')
  return new Date(s.endsWith('Z') || s.includes('+') ? s : s + 'Z')
}
function fmtTime(dt) {
  const d = toDate(dt)
  if (!d) return '—'
  return d.toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' })
}
function fmtDateTime(dt) {
  const d = toDate(dt)
  if (!d) return '—'
  return d.toLocaleString('uz-UZ', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

// ─── Umumiy komponentlar ───────────────────────────────────────────────────────
function Modal({ title, onClose, children }) {
  return (
    <div style={{ position: 'fixed', inset: 0, background: '#00000088', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 200 }}>
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 14, width: 440, padding: 28 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <span style={{ color: C.text, fontWeight: 700, fontSize: 16 }}>{title}</span>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted }}><X size={20} /></button>
        </div>
        {children}
      </div>
    </div>
  )
}

function Field({ label, value, onChange, type = 'text', placeholder }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ color: C.muted, fontSize: 12, marginBottom: 6 }}>{label}</div>
      <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder || ''}
        style={{ width: '100%', background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '10px 14px', color: C.text, fontSize: 13, boxSizing: 'border-box', outline: 'none' }} />
    </div>
  )
}

function Select({ label, value, onChange, options }) {
  return (
    <div style={{ marginBottom: 14 }}>
      <div style={{ color: C.muted, fontSize: 12, marginBottom: 6 }}>{label}</div>
      <select value={value} onChange={e => onChange(e.target.value)}
        style={{ width: '100%', background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '10px 14px', color: C.text, fontSize: 13, outline: 'none' }}>
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  )
}

function SaveBtn({ onClick, loading, label = 'Saqlash' }) {
  return (
    <button onClick={onClick} disabled={loading} style={{
      width: '100%', background: C.primary, border: 'none', borderRadius: 8,
      padding: '12px 0', color: '#fff', fontWeight: 700, fontSize: 14, cursor: 'pointer',
      opacity: loading ? 0.6 : 1, marginTop: 4,
    }}>{loading ? 'Saqlanmoqda...' : label}</button>
  )
}

function ConfirmDelete({ text, onConfirm, onClose }) {
  return (
    <Modal title="O'chirishni tasdiqlang" onClose={onClose}>
      <p style={{ color: C.muted, fontSize: 14, marginBottom: 20 }}>{text}</p>
      <div style={{ display: 'flex', gap: 10 }}>
        <button onClick={onClose} style={{ flex: 1, background: C.card, border: `1px solid ${C.border}`, borderRadius: 8, padding: '10px 0', color: C.muted, cursor: 'pointer', fontWeight: 600 }}>Bekor</button>
        <button onClick={onConfirm} style={{ flex: 1, background: C.danger, border: 'none', borderRadius: 8, padding: '10px 0', color: '#fff', cursor: 'pointer', fontWeight: 700 }}>O'chirish</button>
      </div>
    </Modal>
  )
}

const iconBtnSm = { background: C.card, border: `1px solid ${C.border}`, borderRadius: 6, padding: '6px', cursor: 'pointer', display: 'flex', alignItems: 'center' }

// ─── Main layout ───────────────────────────────────────────────────────────────
function useIsMobile() {
  const [m, setM] = useState(window.innerWidth < 768)
  useEffect(() => {
    const h = () => setM(window.innerWidth < 768)
    window.addEventListener('resize', h)
    return () => window.removeEventListener('resize', h)
  }, [])
  return m
}

export default function AdminLayout() {
  const { user, logout } = useAuth()
  const [page, setPage]           = useState('dashboard')
  const [collapsed, setCollapsed] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const isMobile = useIsMobile()

  const PAGES = { dashboard: Dashboard, orders: OrdersPage, menu: MenuPage, tables: TablesPage, staff: StaffPage, shifts: ShiftsPage, stock: StockPage, expenses: ExpensesPage, salary: SalaryPage, reports: ReportsPage, settings: SettingsPage }
  const Page = PAGES[page] || Dashboard

  function navigate(key) {
    setPage(key)
    if (isMobile) setMobileOpen(false)
  }

  const sidebarVisible = isMobile ? mobileOpen : true
  const sidebarCollapsed = isMobile ? false : collapsed

  return (
    <div style={{ height: '100vh', overflow: 'hidden', background: C.bg, display: 'flex', fontFamily: 'system-ui, sans-serif' }}>

      {/* Mobile overlay */}
      {isMobile && mobileOpen && (
        <div onClick={() => setMobileOpen(false)} style={{ position: 'fixed', inset: 0, background: '#00000077', zIndex: 199 }} />
      )}

      {/* Sidebar */}
      {sidebarVisible && (
        <aside style={{
          width: sidebarCollapsed ? 60 : 220, flexShrink: 0,
          background: C.surface, borderRight: `1px solid ${C.border}`,
          display: 'flex', flexDirection: 'column',
          transition: 'width .2s',
          height: '100vh', overflowY: 'auto',
          ...(isMobile ? { position: 'fixed', left: 0, top: 0, bottom: 0, zIndex: 200 } : {}),
        }}>
          <div style={{ padding: '18px 16px', borderBottom: `1px solid ${C.border}`, display: 'flex', alignItems: 'center', gap: 10 }}>
            <Coffee size={22} color={C.primary} style={{ flexShrink: 0 }} />
            {!sidebarCollapsed && <span style={{ color: C.text, fontWeight: 700, fontSize: 15 }}>Kafe POS</span>}
          </div>
          <nav style={{ flex: 1, padding: '8px 0' }}>
            {NAV.map(({ key, label, icon: Icon }) => {
              const active = page === key
              return (
                <button key={key} onClick={() => navigate(key)} style={{
                  width: '100%', background: active ? `${C.primary}1A` : 'none',
                  border: 'none', borderLeft: `3px solid ${active ? C.primary : 'transparent'}`,
                  cursor: 'pointer', padding: sidebarCollapsed ? '12px 18px' : '12px 16px',
                  display: 'flex', alignItems: 'center', gap: 10,
                  color: active ? C.primary : C.muted, fontWeight: active ? 600 : 400, fontSize: 13, textAlign: 'left',
                }}>
                  <Icon size={18} style={{ flexShrink: 0 }} />
                  {!sidebarCollapsed && label}
                </button>
              )
            })}
          </nav>
          <div style={{ padding: '12px 14px', borderTop: `1px solid ${C.border}` }}>
            {!sidebarCollapsed && (
              <div style={{ marginBottom: 8 }}>
                <div style={{ color: C.text, fontSize: 13, fontWeight: 600 }}>{user?.name}</div>
                <div style={{ color: C.muted, fontSize: 11 }}>{ROLE_LABELS[user?.role]}</div>
              </div>
            )}
            <button onClick={logout} style={{ width: '100%', background: 'none', border: `1px solid ${C.border}`, borderRadius: 8, cursor: 'pointer', padding: '8px 10px', display: 'flex', alignItems: 'center', gap: 8, color: C.muted, fontSize: 12 }}>
              <LogOut size={15} />{!sidebarCollapsed && 'Chiqish'}
            </button>
          </div>
        </aside>
      )}

      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <header style={{ background: C.surface, borderBottom: `1px solid ${C.border}`, padding: isMobile ? '0 12px' : '0 24px', height: 56, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexShrink: 0 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {isMobile ? (
              <button onClick={() => setMobileOpen(o => !o)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted, display: 'flex' }}>
                <Menu size={22} />
              </button>
            ) : (
              <button onClick={() => setCollapsed(c => !c)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: C.muted, display: 'flex' }}>
                <ChevronRight size={18} style={{ transform: collapsed ? 'rotate(0deg)' : 'rotate(180deg)', transition: '.2s' }} />
              </button>
            )}
            <span style={{ color: C.text, fontWeight: 600, fontSize: isMobile ? 14 : 15 }}>{NAV.find(n => n.key === page)?.label}</span>
          </div>
          {!isMobile && <div style={{ color: C.muted, fontSize: 12 }}>{new Date().toLocaleDateString('uz-UZ', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</div>}
        </header>
        <main style={{ flex: 1, overflowY: 'auto', padding: isMobile ? 12 : 24 }}>
          <Page />
        </main>
      </div>
    </div>
  )
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
const DAYS_UZ = ['Yak', 'Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan']

function StatCard({ label, value, icon: Icon, color, sub }) {
  return (
    <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 6 }}>{label}</div>
          <div style={{ color: C.text, fontSize: 22, fontWeight: 700 }}>{value}</div>
          {sub && <div style={{ color: C.muted, fontSize: 11, marginTop: 4 }}>{sub}</div>}
        </div>
        <div style={{ background: `${color}22`, borderRadius: 10, padding: 10 }}>
          <Icon size={20} color={color} />
        </div>
      </div>
    </div>
  )
}

function CustomTooltip({ active, payload, label }) {
  if (!active || !payload?.length) return null
  return (
    <div style={{ background: '#1E293B', border: '1px solid #334155', borderRadius: 8, padding: '10px 14px', fontSize: 12 }}>
      <div style={{ color: '#94A3B8', marginBottom: 6 }}>{label}</div>
      {payload.map((p, i) => (
        <div key={i} style={{ color: p.color, fontWeight: 600 }}>
          {p.name}: {Number(Math.round(p.value)).toLocaleString('uz-UZ')} so'm
        </div>
      ))}
    </div>
  )
}

function Dashboard() {
  const [orders, setOrders] = useState([])
  const [loading, setLoading] = useState(true)

  function load() {
    setLoading(true)
    ordersApi.getAllAdmin().then(r => setOrders(r.data)).catch(() => {}).finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const today   = new Date().toDateString()
  const paid    = orders.filter(o => o.status === 'paid')
  const todayPaid = paid.filter(o => (toDate(o.closed_at || o.created_at) || new Date()).toDateString() === today)
  const active  = orders.filter(o => !['paid','cancelled'].includes(o.status))
  const oTotal  = o => { const t = parseFloat(o.total||0); return t > 0 ? t : (o.items||[]).reduce((a,i)=>a+parseFloat(i.product_price||0)*(i.quantity||1),0) }
  const revenue = todayPaid.reduce((s, o) => s + oTotal(o), 0)
  const discount = todayPaid.reduce((s, o) => s + parseFloat(o.discount || 0), 0)
  const avg     = todayPaid.length ? Math.round(revenue / todayPaid.length) : 0

  // So'nggi 7 kun chart ma'lumotlari
  const chartData = Array.from({ length: 7 }, (_, i) => {
    const d = new Date()
    d.setDate(d.getDate() - (6 - i))
    const ds = d.toDateString()
    const dayPaid = paid.filter(o => (toDate(o.closed_at || o.created_at) || new Date(0)).toDateString() === ds)
    return {
      kun: DAYS_UZ[d.getDay()],
      Tushum: Math.round(dayPaid.reduce((s, o) => s + oTotal(o), 0)),
      Chegirma: Math.round(dayPaid.reduce((s, o) => s + parseFloat(o.discount || 0), 0)),
    }
  })

  const ORDER_STATUS = { paid: [C.success, "To'langan"], cancelled: [C.danger, 'Bekor'], open: [C.primary, 'Ochiq'], sent: [C.primary, 'Oshpazda'], ready: [C.success, 'Tayyor'], bill: [C.warning, 'Hisob'] }

  return (
    <div style={{ padding: 24 }}>
      {/* Stat kartalar */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(210px, 1fr))', gap: 14, marginBottom: 24 }}>
        <StatCard label="Bugungi tushum"    value={fmt(revenue)}          icon={DollarSign}  color={C.success} sub={`${todayPaid.length} ta to'langan`} />
        <StatCard label="Bugungi chegirma"  value={fmt(discount)}         icon={TrendingUp}  color={C.warning} sub={discount > 0 ? `${Math.round(discount/Math.max(revenue+discount,1)*100)}% dan` : '—'} />
        <StatCard label="Faol buyurtmalar"  value={String(active.length)} icon={Clock}       color={C.primary} />
        <StatCard label="O'rtacha chek"     value={fmt(avg)}              icon={ShoppingBag} color={C.muted} />
      </div>

      {/* Chart */}
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20, marginBottom: 20 }}>
        <div style={{ color: C.text, fontWeight: 600, fontSize: 14, marginBottom: 16 }}>So'nggi 7 kun tushumi</div>
        <ResponsiveContainer width="100%" height={220}>
          <BarChart data={chartData} barGap={4}>
            <CartesianGrid strokeDasharray="3 3" stroke={C.border} vertical={false} />
            <XAxis dataKey="kun" tick={{ fill: C.muted, fontSize: 12 }} axisLine={false} tickLine={false} />
            <YAxis tick={{ fill: C.muted, fontSize: 11 }} axisLine={false} tickLine={false}
              tickFormatter={v => v >= 1000 ? `${Math.round(v/1000)}k` : v} />
            <Tooltip content={<CustomTooltip />} cursor={{ fill: '#ffffff08' }} />
            <Bar dataKey="Tushum"   fill={C.primary} radius={[4,4,0,0]} maxBarSize={40} />
            <Bar dataKey="Chegirma" fill={C.warning}  radius={[4,4,0,0]} maxBarSize={40} />
          </BarChart>
        </ResponsiveContainer>
        <div style={{ display: 'flex', gap: 20, marginTop: 8, justifyContent: 'center' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: C.muted }}>
            <div style={{ width: 10, height: 10, borderRadius: 2, background: C.primary }} /> Tushum
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: C.muted }}>
            <div style={{ width: 10, height: 10, borderRadius: 2, background: C.warning }} /> Chegirma
          </div>
        </div>
      </div>

      {/* So'nggi buyurtmalar */}
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, overflow: 'hidden' }}>
        <div style={{ padding: '14px 20px', borderBottom: `1px solid ${C.border}`, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ color: C.text, fontWeight: 600, fontSize: 14 }}>So'nggi buyurtmalar</span>
          <button onClick={load} disabled={loading} style={{ background: 'none', border: `1px solid ${C.border}`, borderRadius: 7, padding: '5px 12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 5, color: C.muted, fontSize: 12, opacity: loading ? 0.5 : 1 }}>
            <RefreshCw size={12} /> Yangilash
          </button>
        </div>
        {loading ? (
          <div style={{ padding: 24, textAlign: 'center', color: C.muted }}>Yuklanmoqda...</div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 520 }}>
            <thead>
              <tr style={{ background: C.card }}>
                {['Raqam', 'Stol', 'Summa', 'Chegirma', 'Holat', 'Vaqt'].map(h => (
                  <th key={h} style={{ padding: '10px 20px', textAlign: 'left', color: C.muted, fontSize: 12, fontWeight: 600 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {orders.slice(0, 10).map(o => {
                const [color, label] = ORDER_STATUS[o.status] || [C.muted, o.status]
                return (
                <tr key={o.id} style={{ borderTop: `1px solid ${C.border}` }}>
                  <td style={{ padding: '11px 20px', color: C.text, fontWeight: 600, fontSize: 13 }}>{o.order_number}</td>
                  <td style={{ padding: '11px 20px', color: C.muted, fontSize: 13 }}>{o.table?.name || '—'}</td>
                  <td style={{ padding: '11px 20px', color: C.text, fontSize: 13 }}>{fmt(o.total)}</td>
                  <td style={{ padding: '11px 20px', fontSize: 13 }}>
                    {parseFloat(o.discount) > 0
                      ? <span style={{ color: C.warning, fontWeight: 600 }}>-{fmt(o.discount)}</span>
                      : <span style={{ color: C.muted }}>—</span>}
                  </td>
                  <td style={{ padding: '11px 20px' }}>
                    <span style={{ background: `${color}22`, color, borderRadius: 20, padding: '3px 10px', fontSize: 11, fontWeight: 600 }}>{label}</span>
                  </td>
                  <td style={{ padding: '11px 20px', color: C.muted, fontSize: 13 }}>
                    {fmtTime(o.created_at)}
                  </td>
                </tr>
              )})}
              {orders.length === 0 && (
                <tr><td colSpan={6} style={{ padding: 24, textAlign: 'center', color: C.muted }}>Buyurtma yo'q</td></tr>
              )}
            </tbody>
          </table>
          </div>
        )}
      </div>
    </div>
  )
}

// ─── Menu ─────────────────────────────────────────────────────────────────────
function MenuPage() {
  const [products, setProducts]     = useState([])
  const [categories, setCategories] = useState([])
  const [search, setSearch]         = useState('')
  const [loading, setLoading]       = useState(true)
  const [modal, setModal]           = useState(null) // 'add' | {id, ...}
  const [confirm, setConfirm]       = useState(null)
  const [form, setForm]             = useState({ name_uz: '', name_ru: '', price: '', category_id: '', cook_time: '0' })
  const [saving, setSaving]         = useState(false)
  const [imgFile, setImgFile]       = useState(null)   // yangi tanlangan fayl
  const [imgPreview, setImgPreview] = useState(null)   // preview URL

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    try {
      const [p, c] = await Promise.all([menuApi.getProducts(), menuApi.getCategories()])
      setProducts(p.data)
      setCategories(c.data)
    } finally { setLoading(false) }
  }

  function openAdd() {
    setForm({ name_uz: '', name_ru: '', price: '', category_id: categories[0]?.id || '', cook_time: '0' })
    setImgFile(null); setImgPreview(null)
    setModal('add')
  }

  function openEdit(p) {
    setForm({ name_uz: p.name_uz, name_ru: p.name_ru, price: p.price, category_id: p.category_id, cook_time: p.cook_time || 0 })
    setImgFile(null); setImgPreview(p.image || null)
    setModal(p)
  }

  function handleImgChange(e) {
    const file = e.target.files[0]
    if (!file) return
    setImgFile(file)
    setImgPreview(URL.createObjectURL(file))
  }

  async function removeImg() {
    if (modal !== 'add' && modal?.image) {
      try { await menuApi.deleteImage(modal.id) } catch {}
    }
    setImgFile(null); setImgPreview(null)
    if (modal !== 'add') setModal(prev => ({ ...prev, image: null }))
  }

  async function save() {
    setSaving(true)
    try {
      const data = { ...form, price: parseFloat(form.price), cook_time: parseInt(form.cook_time) }
      let saved
      if (modal === 'add') saved = await menuApi.createProduct(data)
      else saved = await menuApi.updateProduct(modal.id, data)
      // Rasm yuklash
      if (imgFile) {
        const fd = new FormData()
        fd.append('image', imgFile)
        await menuApi.uploadImage(saved.data.id, fd)
      }
      setModal(null)
      await load()
    } catch { alert('Xato yuz berdi') }
    finally { setSaving(false) }
  }

  async function toggleActive(p) {
    try {
      await menuApi.updateProduct(p.id, { is_active: !p.is_active })
      await load()
    } catch {}
  }

  async function del(id) {
    try { await menuApi.deleteProduct(id); setConfirm(null); await load() }
    catch { alert("O'chirishda xato") }
  }

  const filtered = products.filter(p => p.name_uz?.toLowerCase().includes(search.toLowerCase()))
  const catName  = id => categories.find(c => c.id === id)?.name_uz || '—'

  return (
    <div>
      <div style={{ display: 'flex', gap: 12, marginBottom: 20 }}>
        <div style={{ flex: 1, position: 'relative' }}>
          <Search size={15} color={C.muted} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)' }} />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Taom nomi..."
            style={{ width: '100%', background: C.surface, border: `1px solid ${C.border}`, borderRadius: 8, padding: '10px 12px 10px 36px', color: C.text, fontSize: 13, boxSizing: 'border-box', outline: 'none' }} />
        </div>
        <button onClick={openAdd} style={{ background: C.primary, color: '#fff', border: 'none', borderRadius: 8, padding: '10px 18px', fontWeight: 600, fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
          <Plus size={15} /> Yangi taom
        </button>
      </div>

      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, overflow: 'hidden' }}>
        {loading ? <div style={{ padding: 24, textAlign: 'center', color: C.muted }}>Yuklanmoqda...</div> : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: C.card }}>
                {['', 'Nomi', 'Kategoriya', 'Narxi', 'Vaqt', 'Holat', ''].map((h, i) => (
                  <th key={i} style={{ padding: '10px 20px', textAlign: 'left', color: C.muted, fontSize: 12, fontWeight: 600 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map(p => (
                <tr key={p.id} style={{ borderTop: `1px solid ${C.border}` }}>
                  <td style={{ padding: '8px 8px 8px 20px', width: 44 }}>
                    {p.image
                      ? <img src={p.image} alt="" style={{ width: 40, height: 40, borderRadius: 8, objectFit: 'cover' }} />
                      : <div style={{ width: 40, height: 40, borderRadius: 8, background: C.card, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>🍽️</div>
                    }
                  </td>
                  <td style={{ padding: '12px 20px', color: C.text, fontWeight: 600, fontSize: 13 }}>{p.name_uz}</td>
                  <td style={{ padding: '12px 20px', color: C.muted, fontSize: 13 }}>{catName(p.category_id)}</td>
                  <td style={{ padding: '12px 20px', color: C.primary, fontWeight: 700, fontSize: 13 }}>{fmt(p.price)}</td>
                  <td style={{ padding: '12px 20px', color: C.muted, fontSize: 13 }}>{p.cook_time > 0 ? `${p.cook_time} daq` : 'Tezkor'}</td>
                  <td style={{ padding: '12px 20px' }}>
                    <button onClick={() => toggleActive(p)} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex' }}>
                      {p.is_active ? <ToggleRight size={22} color={C.success} /> : <ToggleLeft size={22} color={C.muted} />}
                    </button>
                  </td>
                  <td style={{ padding: '12px 20px' }}>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button onClick={() => openEdit(p)} style={iconBtnSm}><Edit2 size={14} color={C.muted} /></button>
                      <button onClick={() => setConfirm(p)} style={iconBtnSm}><Trash2 size={14} color={C.danger} /></button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Add/Edit modal */}
      {modal && (
        <Modal title={modal === 'add' ? 'Yangi taom' : 'Taomni tahrirlash'} onClose={() => setModal(null)}>
          <Field label="Nomi (O'zbek)" value={form.name_uz} onChange={v => setForm(f => ({ ...f, name_uz: v }))} placeholder="Osh (Plov)" />
          <Field label="Nomi (Rus)" value={form.name_ru} onChange={v => setForm(f => ({ ...f, name_ru: v }))} placeholder="Плов" />
          <Select label="Kategoriya" value={form.category_id} onChange={v => setForm(f => ({ ...f, category_id: v }))}
            options={categories.map(c => ({ value: c.id, label: c.name_uz }))} />
          <Field label="Narxi (so'm)" value={form.price} onChange={v => setForm(f => ({ ...f, price: v }))} type="number" placeholder="35000" />
          <Field label="Tayyorlash vaqti (daqiqa, 0 = tezkor)" value={form.cook_time} onChange={v => setForm(f => ({ ...f, cook_time: v }))} type="number" placeholder="0" />
          {/* Rasm yuklash */}
          <div style={{ marginBottom: 16 }}>
            <div style={{ fontSize: 12, color: C.muted, marginBottom: 6, fontWeight: 600 }}>Rasm</div>
            {imgPreview ? (
              <div style={{ position: 'relative', display: 'inline-block' }}>
                <img src={imgPreview} alt="preview" style={{ width: 100, height: 100, objectFit: 'cover', borderRadius: 10, border: `2px solid ${C.border}` }} />
                <button onClick={removeImg} style={{ position: 'absolute', top: -8, right: -8, background: C.danger, color: '#fff', border: 'none', borderRadius: '50%', width: 22, height: 22, cursor: 'pointer', fontSize: 13, lineHeight: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>×</button>
              </div>
            ) : (
              <label style={{ display: 'inline-flex', alignItems: 'center', gap: 8, cursor: 'pointer', background: C.card, border: `1.5px dashed ${C.border}`, borderRadius: 10, padding: '10px 18px', fontSize: 13, color: C.muted }}>
                📷 Rasm tanlash
                <input type="file" accept="image/*" onChange={handleImgChange} style={{ display: 'none' }} />
              </label>
            )}
          </div>
          <SaveBtn onClick={save} loading={saving} />
        </Modal>
      )}

      {/* Delete confirm */}
      {confirm && (
        <ConfirmDelete
          text={`"${confirm.name_uz}" taomini o'chirmoqchimisiz?`}
          onConfirm={() => del(confirm.id)}
          onClose={() => setConfirm(null)}
        />
      )}
    </div>
  )
}

// ─── Tables ───────────────────────────────────────────────────────────────────
function TablesPage() {
  const [halls, setHalls]           = useState([])
  const [activeHallId, setActiveHallId] = useState(null)
  const [loading, setLoading]       = useState(true)
  const [modal, setModal]           = useState(null) // 'addHall' | 'addTable'
  const [confirm, setConfirm]       = useState(null)
  const [form, setForm]             = useState({ name: '', capacity: '4', name_uz: '', name_ru: '' })
  const [saving, setSaving]         = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    try {
      const r = await tablesApi.getHalls()
      setHalls(r.data)
      if (r.data.length && !activeHallId) setActiveHallId(r.data[0].id)
    } finally { setLoading(false) }
  }

  const activeHall  = halls.find(h => h.id === activeHallId)
  const hallTables  = activeHall?.tables || []

  const STATUS_COLOR = { free: C.success, occupied: C.primary, bill_requested: C.warning, reserved: C.muted }
  const STATUS_LABEL = { free: "Bo'sh", occupied: 'Band', bill_requested: 'Hisob', reserved: 'Bron' }

  async function addHall() {
    setSaving(true)
    try {
      await tablesApi.createHall({ name_uz: form.name_uz, name_ru: form.name_ru || form.name_uz })
      setModal(null)
      await load()
    } catch { alert('Xato yuz berdi') }
    finally { setSaving(false) }
  }

  async function addTable() {
    setSaving(true)
    try {
      await tablesApi.createTable({ hall_id: activeHallId, name: form.name, capacity: parseInt(form.capacity) })
      setModal(null)
      await load()
    } catch { alert('Xato yuz berdi') }
    finally { setSaving(false) }
  }

  async function editTable() {
    setSaving(true)
    try {
      await tablesApi.updateTable(modal.id, { name: form.name, capacity: parseInt(form.capacity) })
      setModal(null)
      await load()
    } catch { alert('Xato yuz berdi') }
    finally { setSaving(false) }
  }

  async function delTable(id) {
    try { await tablesApi.deleteTable(id); setConfirm(null); await load() }
    catch { alert("O'chirishda xato") }
  }

  return (
    <div>
      {/* Hall tabs */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20, flexWrap: 'wrap' }}>
        {halls.map(h => (
          <button key={h.id} onClick={() => setActiveHallId(h.id)} style={{
            background: activeHallId === h.id ? C.primary : C.surface,
            color: activeHallId === h.id ? '#fff' : C.muted,
            border: `1px solid ${activeHallId === h.id ? C.primary : C.border}`,
            borderRadius: 8, padding: '8px 18px', fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>{h.name_uz}</button>
        ))}
        <button onClick={() => { setForm({ name_uz: '', name_ru: '' }); setModal('addHall') }}
          style={{ background: 'none', border: `1px dashed ${C.border}`, borderRadius: 8, padding: '8px 14px', color: C.muted, fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
          <Plus size={13} /> Zal qo'shish
        </button>
        <button onClick={() => { setForm({ name: '', capacity: '4' }); setModal('addTable') }}
          style={{ marginLeft: 'auto', background: C.primary, color: '#fff', border: 'none', borderRadius: 8, padding: '8px 16px', fontSize: 13, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
          <Plus size={14} /> Stol qo'shish
        </button>
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', color: C.muted, padding: 40 }}>Yuklanmoqda...</div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 12 }}>
          {hallTables.map(t => {
            const sc = STATUS_COLOR[t.status] || C.muted
            const sl = STATUS_LABEL[t.status] || t.status
            return (
              <div key={t.id} style={{
                background: C.surface, border: `1px solid ${sc}44`,
                borderTop: `3px solid ${sc}`, borderRadius: 12, padding: '18px 14px', textAlign: 'center',
              }}>
                <div style={{ color: C.text, fontWeight: 700, fontSize: 17 }}>{t.name}</div>
                <div style={{ color: C.muted, fontSize: 12, marginTop: 2 }}>{t.capacity} kishi</div>
                <div style={{ color: sc, fontSize: 12, marginTop: 4, fontWeight: 600 }}>{sl}</div>
                <div style={{ display: 'flex', gap: 6, marginTop: 12, justifyContent: 'center' }}>
                  <button
                    onClick={() => { setForm({ name: t.name, capacity: String(t.capacity) }); setModal({ id: t.id, type: 'editTable' }) }}
                    style={iconBtnSm}
                  >
                    <Edit2 size={13} color={C.muted} />
                  </button>
                  <button
                    onClick={() => setConfirm(t)}
                    disabled={t.status !== 'free'}
                    style={{ ...iconBtnSm, opacity: t.status !== 'free' ? 0.4 : 1 }}
                    title={t.status !== 'free' ? "Band stol o'chirilmaydi" : ''}
                  >
                    <Trash2 size={13} color={C.danger} />
                  </button>
                </div>
              </div>
            )
          })}

          {hallTables.length === 0 && (
            <div style={{ gridColumn: '1/-1', textAlign: 'center', color: C.muted, padding: 40 }}>
              Bu zalda hali stol yo'q
            </div>
          )}
        </div>
      )}

      {/* Zal qo'shish */}
      {modal === 'addHall' && (
        <Modal title="Yangi zal" onClose={() => setModal(null)}>
          <Field label="Zal nomi (O'zbek)" value={form.name_uz} onChange={v => setForm(f => ({ ...f, name_uz: v }))} placeholder="Asosiy zal" />
          <Field label="Zal nomi (Rus)" value={form.name_ru} onChange={v => setForm(f => ({ ...f, name_ru: v }))} placeholder="Основной зал" />
          <SaveBtn onClick={addHall} loading={saving} label="Zal qo'shish" />
        </Modal>
      )}

      {/* Stol qo'shish */}
      {modal === 'addTable' && (
        <Modal title={`Yangi stol — ${activeHall?.name_uz}`} onClose={() => setModal(null)}>
          <Field label="Stol nomi" value={form.name} onChange={v => setForm(f => ({ ...f, name: v }))} placeholder="5-stol yoki VIP 2" />
          <Field label="Sig'imi (kishi)" value={form.capacity} onChange={v => setForm(f => ({ ...f, capacity: v }))} type="number" placeholder="4" />
          <SaveBtn onClick={addTable} loading={saving} label="Stol qo'shish" />
        </Modal>
      )}

      {/* Stolni tahrirlash */}
      {modal?.type === 'editTable' && (
        <Modal title="Stolni tahrirlash" onClose={() => setModal(null)}>
          <Field label="Stol nomi" value={form.name} onChange={v => setForm(f => ({ ...f, name: v }))} placeholder="5-stol yoki VIP 2" />
          <Field label="Sig'imi (kishi)" value={form.capacity} onChange={v => setForm(f => ({ ...f, capacity: v }))} type="number" placeholder="4" />
          <SaveBtn onClick={editTable} loading={saving} label="Saqlash" />
        </Modal>
      )}

      {/* Delete confirm */}
      {confirm && (
        <ConfirmDelete
          text={`"${confirm.name}" stolini o'chirmoqchimisiz?`}
          onConfirm={() => delTable(confirm.id)}
          onClose={() => setConfirm(null)}
        />
      )}
    </div>
  )
}

// ─── Staff ────────────────────────────────────────────────────────────────────
function StaffPage() {
  const { user: me } = useAuth()
  const isMobile = useIsMobile()
  const [staff, setStaff]   = useState([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal]   = useState(null)
  const [confirm, setConfirm] = useState(null)
  const [form, setForm]     = useState({ name: '', pin: '', role: 'waiter', email: '', password: '' })
  const [saving, setSaving] = useState(false)

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    try { const r = await usersApi.getAll(); setStaff(r.data) }
    finally { setLoading(false) }
  }

  async function save() {
    setSaving(true)
    try {
      if (modal === 'add') await usersApi.create(form)
      else await usersApi.update(modal.id, form)
      setModal(null)
      await load()
    } catch (e) {
      const msg = e?.response?.data?.message || e?.message || 'Xato yuz berdi'
      alert(msg)
    } finally { setSaving(false) }
  }

  async function toggleActive(s) {
    try { await usersApi.update(s.id, { is_active: !s.is_active }); await load() } catch {}
  }

  async function del(id) {
    try { await usersApi.delete(id); setConfirm(null); await load() }
    catch { alert("O'chirishda xato") }
  }

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 20 }}>
        <button onClick={() => { setForm({ name: '', pin: '', role: 'waiter', email: '', password: '' }); setModal('add') }}
          style={{ background: C.primary, color: '#fff', border: 'none', borderRadius: 8, padding: '10px 18px', fontWeight: 600, fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
          <Plus size={15} /> Xodim qo'shish
        </button>
      </div>

      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, overflow: 'hidden' }}>
        {loading ? <div style={{ padding: 24, textAlign: 'center', color: C.muted }}>Yuklanmoqda...</div> : isMobile ? (
          /* Mobile cards */
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, padding: 12 }}>
            {staff.map(s => (
              <div key={s.id} style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 10, padding: '12px 14px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div>
                    <div style={{ color: C.text, fontWeight: 700, fontSize: 14, marginBottom: 4 }}>{s.name}</div>
                    <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
                      <span style={{ background: `${C.primary}22`, color: C.primary, borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>{ROLE_LABELS[s.role] || s.role}</span>
                      {s.pin && <span style={{ color: C.muted, fontSize: 12, fontFamily: 'monospace' }}>PIN: {s.pin}</span>}
                      {s.email && <span style={{ color: C.muted, fontSize: 11 }}>{s.email}</span>}
                    </div>
                  </div>
                  <div style={{ display: 'flex', gap: 6, alignItems: 'center', flexShrink: 0 }}>
                    <button onClick={() => toggleActive(s)} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex' }}>
                      {s.is_active ? <ToggleRight size={22} color={C.success} /> : <ToggleLeft size={22} color={C.muted} />}
                    </button>
                    <button onClick={() => { setForm({ name: s.name, pin: s.pin, role: s.role, email: s.email || '', password: '' }); setModal(s) }} style={iconBtnSm}>
                      <Edit2 size={14} color={C.muted} />
                    </button>
                    <button onClick={() => setConfirm(s)} disabled={s.id === me?.id} style={{ ...iconBtnSm, opacity: s.id === me?.id ? 0.4 : 1 }}>
                      <Trash2 size={14} color={C.danger} />
                    </button>
                  </div>
                </div>
              </div>
            ))}
            {staff.length === 0 && <div style={{ padding: 24, textAlign: 'center', color: C.muted }}>Xodim yo'q</div>}
          </div>
        ) : (
          /* Desktop table */
          <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 480 }}>
            <thead>
              <tr style={{ background: C.card }}>
                {['Ism', 'Rol', 'PIN', 'Email', 'Holat', ''].map(h => (
                  <th key={h} style={{ padding: '10px 20px', textAlign: 'left', color: C.muted, fontSize: 12, fontWeight: 600 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {staff.map(s => (
                <tr key={s.id} style={{ borderTop: `1px solid ${C.border}` }}>
                  <td style={{ padding: '12px 20px', color: C.text, fontWeight: 600, fontSize: 13 }}>{s.name}</td>
                  <td style={{ padding: '12px 20px' }}>
                    <span style={{ background: `${C.primary}22`, color: C.primary, borderRadius: 20, padding: '3px 10px', fontSize: 11, fontWeight: 600 }}>
                      {ROLE_LABELS[s.role] || s.role}
                    </span>
                  </td>
                  <td style={{ padding: '12px 20px', color: C.muted, fontSize: 13, fontFamily: 'monospace', letterSpacing: 2 }}>{s.pin}</td>
                  <td style={{ padding: '12px 20px', color: C.muted, fontSize: 12 }}>{s.email || '—'}</td>
                  <td style={{ padding: '12px 20px' }}>
                    <button onClick={() => toggleActive(s)} style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex' }}>
                      {s.is_active ? <ToggleRight size={22} color={C.success} /> : <ToggleLeft size={22} color={C.muted} />}
                    </button>
                  </td>
                  <td style={{ padding: '12px 20px' }}>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button onClick={() => { setForm({ name: s.name, pin: s.pin, role: s.role, email: s.email || '', password: '' }); setModal(s) }} style={iconBtnSm}>
                        <Edit2 size={14} color={C.muted} />
                      </button>
                      <button onClick={() => setConfirm(s)} disabled={s.id === me?.id} style={{ ...iconBtnSm, opacity: s.id === me?.id ? 0.4 : 1 }}>
                        <Trash2 size={14} color={C.danger} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
          </div>
        )}
      </div>

      {modal && (
        <Modal title={modal === 'add' ? 'Yangi xodim' : 'Xodimni tahrirlash'} onClose={() => setModal(null)}>
          <Field label="Ism Familiya" value={form.name} onChange={v => setForm(f => ({ ...f, name: v }))} placeholder="Jasur Toshmatov" />
          <Field label="PIN kod (4-6 raqam)" value={form.pin} onChange={v => setForm(f => ({ ...f, pin: v }))} placeholder="1234" />
          <Select label="Rol" value={form.role} onChange={v => setForm(f => ({ ...f, role: v }))}
            options={Object.entries(ROLE_LABELS).map(([v, l]) => ({ value: v, label: l }))} />
          <Field label="Email (ixtiyoriy)" value={form.email} onChange={v => setForm(f => ({ ...f, email: v }))} type="email" placeholder="jasur@kafe.uz" />
          <Field label={modal === 'add' ? 'Parol (ixtiyoriy)' : 'Yangi parol (o\'zgartirish uchun)'} value={form.password} onChange={v => setForm(f => ({ ...f, password: v }))} type="password" placeholder="••••••" />
          <SaveBtn onClick={save} loading={saving} />
        </Modal>
      )}

      {confirm && (
        <ConfirmDelete
          text={`"${confirm.name}" xodimini o'chirmoqchimisiz?`}
          onConfirm={() => del(confirm.id)}
          onClose={() => setConfirm(null)}
        />
      )}
    </div>
  )
}

// ─── Shifts ───────────────────────────────────────────────────────────────────
function ShiftsPage() {
  const [shifts, setShifts] = useState([])
  const [loading, setLoading] = useState(true)

  function toDate(dt) {
    if (!dt) return null
    const s = String(dt).replace(' ', 'T')
    return new Date(s.endsWith('Z') || s.includes('+') ? s : s + 'Z')
  }
  function fmt(n) { return Number(Math.round(n || 0)).toLocaleString('uz-UZ') + " so'm" }
  function timeStr(dt) {
    const d = toDate(dt)
    if (!d) return '—'
    return d.toLocaleDateString('uz-UZ', { day: '2-digit', month: '2-digit' }) + ' ' +
           d.toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' })
  }
  function dur(from, to) {
    const d1 = toDate(from), d2 = to ? toDate(to) : new Date()
    if (!d1) return '—'
    const diff = Math.floor((d2 - d1) / 60000)
    if (diff < 60) return `${diff} daq`
    return `${Math.floor(diff / 60)}h ${diff % 60}daq`
  }

  useEffect(() => {
    shiftApi.getAll().then(r => { setShifts(r.data); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div style={{ padding: 40, color: C.muted, textAlign: 'center' }}>Yuklanmoqda...</div>

  return (
    <div style={{ padding: 28 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <h2 style={{ color: C.text, fontSize: 20, fontWeight: 700, margin: 0 }}>Smenalar tarixi</h2>
        <span style={{ color: C.muted, fontSize: 13 }}>{shifts.length} ta smena</span>
      </div>

      {shifts.length === 0 ? (
        <div style={{ textAlign: 'center', color: C.muted, padding: 60 }}>Smena topilmadi</div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {shifts.map(s => {
            const stats = s.stats || {}
            const isOpen = s.is_open
            return (
              <div key={s.id} style={{ background: C.surface, border: `1px solid ${isOpen ? C.success + '44' : C.border}`, borderRadius: 12, padding: 20 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{ background: isOpen ? C.success + '22' : C.card, borderRadius: 8, padding: 8 }}>
                      {isOpen
                        ? <CheckCircle size={18} color={C.success} />
                        : <XCircle size={18} color={C.muted} />}
                    </div>
                    <div>
                      <div style={{ color: C.text, fontWeight: 700, fontSize: 15 }}>
                        Smena #{s.id}
                        {isOpen && <span style={{ marginLeft: 8, background: C.success + '22', color: C.success, fontSize: 11, padding: '2px 8px', borderRadius: 10 }}>Ochiq</span>}
                      </div>
                      <div style={{ color: C.muted, fontSize: 12, marginTop: 2 }}>
                        {s.opener?.name || '—'} tomonidan ochildi
                      </div>
                    </div>
                  </div>
                  <div style={{ textAlign: 'right' }}>
                    <div style={{ color: C.primary, fontWeight: 800, fontSize: 18 }}>{fmt(stats.revenue)}</div>
                    <div style={{ color: C.muted, fontSize: 11 }}>jami tushum</div>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(100px, 1fr))', gap: 10 }}>
                  <div style={{ background: C.card, borderRadius: 8, padding: '10px 14px' }}>
                    <div style={{ color: C.muted, fontSize: 11 }}>Boshlangan</div>
                    <div style={{ color: C.text, fontWeight: 600, fontSize: 13, marginTop: 2 }}>{timeStr(s.opened_at)}</div>
                  </div>
                  <div style={{ background: C.card, borderRadius: 8, padding: '10px 14px' }}>
                    <div style={{ color: C.muted, fontSize: 11 }}>Yakunlangan</div>
                    <div style={{ color: C.text, fontWeight: 600, fontSize: 13, marginTop: 2 }}>{isOpen ? '—' : timeStr(s.closed_at)}</div>
                  </div>
                  <div style={{ background: C.card, borderRadius: 8, padding: '10px 14px' }}>
                    <div style={{ color: C.muted, fontSize: 11 }}>Davomiyligi</div>
                    <div style={{ color: C.text, fontWeight: 600, fontSize: 13, marginTop: 2 }}>{dur(s.opened_at, s.closed_at)}</div>
                  </div>
                  <div style={{ background: C.card, borderRadius: 8, padding: '10px 14px' }}>
                    <div style={{ color: C.muted, fontSize: 11 }}>Buyurtmalar</div>
                    <div style={{ color: C.text, fontWeight: 600, fontSize: 13, marginTop: 2 }}>
                      {stats.orders_paid || 0}/{stats.orders_total || 0} ta
                    </div>
                  </div>
                </div>

                {s.closer && (
                  <div style={{ marginTop: 10, color: C.muted, fontSize: 12 }}>
                    Yopdi: <span style={{ color: C.text }}>{s.closer.name}</span>
                    {' · '} Boshlang'ich kassa: <span style={{ color: C.text }}>{fmt(s.opening_cash)}</span>
                    {' · '} Yakuniy kassa: <span style={{ color: C.text }}>{fmt(s.closing_cash)}</span>
                  </div>
                )}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

// ─── DonutChart ───────────────────────────────────────────────────────────────
const METHOD_COLORS = { cash:'#22c55e', card:'#3b82f6', click:'#f97316', payme:'#a855f7', transfer:'#06b6d4', debt:'#ef4444', other:'#94a3b8' }
const METHOD_UZ     = { cash:'Naqd', card:'Karta', click:'Click', payme:'Payme', transfer:"O'tkazma", debt:'Qarz', other:'Boshqa' }

function DonutChart({ data, total }) {
  if (!data || data.length === 0 || total <= 0) return <div style={{color:'#475569',textAlign:'center',padding:20}}>Ma'lumot yo'q</div>
  const r = 70, cx = 90, cy = 90, stroke = 28
  const circ = 2 * Math.PI * r
  let offset = 0
  const slices = data.map(d => {
    const pct = d.total / total
    const dash = pct * circ
    const s = { pct, dash, offset, color: METHOD_COLORS[d.method] || '#94a3b8' }
    offset += dash
    return { ...d, ...s }
  })
  return (
    <div style={{ display: 'flex', gap: 24, alignItems: 'center', flexWrap: 'wrap' }}>
      <svg width={180} height={180} style={{ flexShrink: 0 }}>
        {slices.map((s, i) => (
          <circle key={i} cx={cx} cy={cy} r={r}
            fill="none" stroke={s.color} strokeWidth={stroke}
            strokeDasharray={`${s.dash} ${circ - s.dash}`}
            strokeDashoffset={-s.offset + circ / 4}
            style={{ transition: 'stroke-dasharray 0.3s' }}
          />
        ))}
        <text x={cx} y={cy - 8} textAnchor="middle" fill="#f1f5f9" fontSize={11} fontWeight={600}>Jami</text>
        <text x={cx} y={cy + 10} textAnchor="middle" fill="#f97316" fontSize={12} fontWeight={800}>{data.length} tur</text>
      </svg>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
        {slices.map((s, i) => (
          <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 12, height: 12, borderRadius: '50%', background: s.color, flexShrink: 0 }} />
            <div>
              <div style={{ color: '#f1f5f9', fontSize: 13, fontWeight: 600 }}>{METHOD_UZ[s.method] || s.method}</div>
              <div style={{ color: '#94a3b8', fontSize: 11 }}>{s.count} ta · {fmt(s.total)} · {Math.round(s.pct * 100)}%</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

// ─── Reports ──────────────────────────────────────────────────────────────────
function ReportsPage() {
  const today = new Date().toISOString().slice(0, 10)

  const [orders, setOrders]             = useState([])
  const [loading, setLoading]           = useState(true)
  const [dateFrom, setDateFrom]         = useState(today)
  const [dateTo, setDateTo]             = useState(today)
  const [waiterFilter, setWaiterFilter] = useState('')

  useEffect(() => {
    ordersApi.getAllAdmin().then(r => setOrders(r.data)).catch(() => {}).finally(() => setLoading(false))
  }, [])

  // 1. Faqat sana bo'yicha filterlangan (ofitsiant statistikasi uchun — umumiy tasvir)
  const paid = orders.filter(o => {
    if (o.status !== 'paid') return false
    const d = toDate(o.closed_at || o.created_at)
    if (!d) return true
    if (dateFrom && d < new Date(dateFrom + 'T00:00:00')) return false
    if (dateTo   && d > new Date(dateTo   + 'T23:59:59')) return false
    return true
  })

  // 2. Ofitsiant dropdown uchun nomlar (date filterlangan barcha ofitsiantlar)
  const waiterNames = [...new Set(paid.map(o => o.waiter?.name || "Noma'lum"))]

  // 3. Sana + ofitsiant bo'yicha to'liq filterlangan — stat kartalar, grafik, Top-5, jadval uchun
  const paidFiltered = waiterFilter
    ? paid.filter(o => (o.waiter?.name || "Noma'lum") === waiterFilter)
    : paid

  // Buyurtma haqiqiy summasi (total 0 bo'lsa items dan hisoblaydi)
  function orderTotal(o) {
    const t = parseFloat(o.total || 0)
    if (t > 0) return t
    return (o.items || []).reduce((a, i) => a + parseFloat(i.product_price || 0) * (i.quantity || 1), 0)
  }

  // Stat qiymatlar — paidFiltered dan
  const revenue  = paidFiltered.reduce((s, o) => s + orderTotal(o), 0)
  const discount = paidFiltered.reduce((s, o) => s + parseFloat(o.discount || 0), 0)
  const avg      = paidFiltered.length ? Math.round(revenue / paidFiltered.length) : 0

  // To'lov usuli — paidFiltered dan
  const payMethodMap = {}
  paidFiltered.forEach(o => {
    const method = o.payment?.method || 'other'
    const amount = orderTotal(o)
    if (!payMethodMap[method]) payMethodMap[method] = { method, count: 0, total: 0 }
    payMethodMap[method].count++
    payMethodMap[method].total += amount
  })
  const paySum = { methods: Object.values(payMethodMap), grand_total: revenue }

  // Top-5 mahsulot — paidFiltered dan
  const productMap = {}
  paidFiltered.forEach(o => {
    ;(o.items || []).forEach(item => {
      const name = item.product?.name_uz || item.product_name || '?'
      if (!productMap[name]) productMap[name] = { name, qty: 0, total: 0 }
      productMap[name].qty   += parseInt(item.quantity || 0)
      productMap[name].total += parseFloat(item.product_price || 0) * parseInt(item.quantity || 0)
    })
  })
  const top5   = Object.values(productMap).sort((a, b) => b.qty - a.qty).slice(0, 5)
  const maxQty = top5[0]?.qty || 1

  // Ofitsiant statistikasi — paid dan (sana filterlangan, lekin ofitsiant filtrlanmagan — umumiy tasvir)
  const waiterMap = {}
  paid.forEach(o => {
    const name = o.waiter?.name || "Noma'lum"
    if (!waiterMap[name]) waiterMap[name] = { name, orders: 0, revenue: 0 }
    waiterMap[name].orders++
    waiterMap[name].revenue += orderTotal(o)
  })
  const waiterStats = Object.values(waiterMap).sort((a, b) => b.revenue - a.revenue)
  const maxRev = waiterStats[0]?.revenue || 1

  function printReport() {
    const cafe = (() => { try { return JSON.parse(localStorage.getItem('pos_settings') || '{}') } catch { return {} } })()
    const cafeName = cafe.cafe_name || 'Kafe POS'
    const footer   = cafe.receipt_footer || 'Tashrifingiz uchun rahmat!'
    const now = new Date().toLocaleString('uz-UZ')
    const rows = paidFiltered.map(o =>
      `<tr>
        <td>${o.order_number}</td>
        <td>${o.table?.name || '—'}</td>
        <td>${o.waiter?.name || '—'}</td>
        <td style="text-align:right">${fmt(o.total)}</td>
        <td>${fmtTime(o.closed_at || o.created_at)}</td>
      </tr>`
    ).join('')
    const top5rows = top5.map(p =>
      `<tr><td>${p.name}</td><td style="text-align:right">${p.qty} ta</td><td style="text-align:right">${fmt(p.total)}</td></tr>`
    ).join('')
    const waiterRows = waiterStats.map(w =>
      `<tr><td>${w.name}</td><td style="text-align:right">${w.orders} ta</td><td style="text-align:right">${fmt(w.revenue)}</td></tr>`
    ).join('')

    const html = `<!DOCTYPE html><html><head><meta charset="utf-8">
      <title>Hisobot — ${cafeName}${dateFrom ? ' ' + dateFrom : ''}${dateTo ? ' — ' + dateTo : ''}${waiterFilter ? ' | ' + waiterFilter : ''}</title>
      <style>
        body{font-family:monospace;font-size:13px;margin:20px;color:#111}
        h2{text-align:center;margin-bottom:4px}h3{margin:20px 0 8px;font-size:14px}
        .meta{text-align:center;color:#555;margin-bottom:20px;font-size:12px}
        .stats{display:grid;grid-template-columns:repeat(2,1fr);gap:10px;margin-bottom:20px}
        .stat{border:1px solid #ddd;border-radius:8px;padding:12px}
        .stat-label{font-size:11px;color:#777}.stat-value{font-size:18px;font-weight:bold;margin-top:4px}
        table{width:100%;border-collapse:collapse;margin-bottom:20px}
        th{background:#f0f0f0;padding:8px 12px;text-align:left;font-size:12px}
        td{padding:8px 12px;border-bottom:1px solid #eee;font-size:12px}
        tfoot td{font-weight:bold;background:#f9f9f9}
        .footer{text-align:center;margin-top:20px;color:#777;font-size:11px}
        @media print{button{display:none}}
      </style></head><body>
      <h2>${cafeName}</h2>
      <div class="meta">Hisobot: ${now}${dateFrom ? ' | ' + dateFrom : ''}${dateTo ? ' — ' + dateTo : ''}${waiterFilter ? ' | Ofitsiant: ' + waiterFilter : ''}</div>
      <div class="stats">
        <div class="stat"><div class="stat-label">To'langan buyurtmalar</div><div class="stat-value">${paidFiltered.length} ta</div></div>
        <div class="stat"><div class="stat-label">Jami tushum</div><div class="stat-value">${fmt(revenue)}</div></div>
        <div class="stat"><div class="stat-label">Chegirmalar</div><div class="stat-value">${fmt(discount)}</div></div>
        <div class="stat"><div class="stat-label">O'rtacha chek</div><div class="stat-value">${fmt(avg)}</div></div>
      </div>
      <h3>Top-5 mahsulot</h3>
      <table><thead><tr><th>Mahsulot</th><th style="text-align:right">Soni</th><th style="text-align:right">Summa</th></tr></thead><tbody>${top5rows}</tbody></table>
      <h3>Ofitsiant bo'yicha (umumiy)</h3>
      <table><thead><tr><th>Ofitsiant</th><th style="text-align:right">Buyurtma</th><th style="text-align:right">Tushum</th></tr></thead><tbody>${waiterRows}</tbody></table>
      <h3>Buyurtmalar${waiterFilter ? ' — ' + waiterFilter : ''}</h3>
      <table>
        <thead><tr><th>Raqam</th><th>Stol</th><th>Ofitsiant</th><th style="text-align:right">Summa</th><th>Vaqt</th></tr></thead>
        <tbody>${rows}</tbody>
        <tfoot><tr><td colspan="3">Jami (${paidFiltered.length} ta)</td><td style="text-align:right">${fmt(revenue)}</td><td></td></tr></tfoot>
      </table>
      <div class="footer">${footer}</div>
      </body></html>`

    const win = window.open('', '_blank')
    win.document.write(html)
    win.document.close()
    win.focus()
    setTimeout(() => win.print(), 500)
  }

  return (
    <div>
      {/* Filter va PDF */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 20, flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
          <span style={{ color: C.muted, fontSize: 13 }}>Dan:</span>
          <input type="date" value={dateFrom} onChange={e => setDateFrom(e.target.value)}
            style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 8, padding: '8px 12px', color: C.text, fontSize: 13, outline: 'none' }} />
          <span style={{ color: C.muted, fontSize: 13 }}>Gacha:</span>
          <input type="date" value={dateTo} onChange={e => setDateTo(e.target.value)}
            style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 8, padding: '8px 12px', color: C.text, fontSize: 13, outline: 'none' }} />
          <select value={waiterFilter} onChange={e => setWaiterFilter(e.target.value)}
            style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 8, padding: '8px 12px', color: waiterFilter ? C.text : C.muted, fontSize: 13, outline: 'none' }}>
            <option value=''>Barcha ofitsiantlar</option>
            {waiterNames.map(n => <option key={n} value={n}>{n}</option>)}
          </select>
          {(dateFrom || dateTo || waiterFilter) && (
            <button onClick={() => { setDateFrom(''); setDateTo(''); setWaiterFilter('') }}
              style={{ background: 'none', border: `1px solid ${C.border}`, borderRadius: 8, padding: '8px 12px', color: C.muted, fontSize: 13, cursor: 'pointer' }}>
              Tozalash
            </button>
          )}
        </div>
        <button onClick={printReport} disabled={!paidFiltered.length}
          style={{ marginLeft: 'auto', background: C.success, color: '#fff', border: 'none', borderRadius: 8, padding: '9px 18px', fontWeight: 600, fontSize: 13, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, opacity: paidFiltered.length ? 1 : 0.5 }}>
          🖨 PDF / Chop etish
        </button>
      </div>

      {/* Stat kartalar — paidFiltered dan */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px,1fr))', gap: 12, marginBottom: 20 }}>
        {[
          { label: 'Jami buyurtmalar', value: `${orders.length} ta` },
          { label: "To'langan",        value: `${paidFiltered.length} ta` },
          { label: 'Jami tushum',      value: fmt(revenue) },
          { label: 'Chegirmalar',      value: fmt(discount) },
          { label: "O'rtacha chek",    value: fmt(avg) },
        ].map((s, i) => (
          <div key={i} style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 16 }}>
            <div style={{ color: C.muted, fontSize: 11, marginBottom: 4 }}>{s.label}</div>
            <div style={{ color: C.text, fontWeight: 700, fontSize: 18 }}>{loading ? '...' : s.value}</div>
          </div>
        ))}
      </div>

      {/* 3 panel */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px,1fr))', gap: 14, marginBottom: 20 }}>

        {/* To'lov usuli — paidFiltered dan */}
        <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20 }}>
          <div style={{ color: C.muted, fontSize: 11, fontWeight: 700, letterSpacing: 1, marginBottom: 14 }}>TO'LOV USULI BO'YICHA</div>
          {paySum.methods.length > 0
            ? <DonutChart data={paySum.methods} total={paySum.grand_total} />
            : <div style={{ color: C.muted, fontSize: 13, textAlign: 'center', padding: '20px 0' }}>Ma'lumot yo'q</div>
          }
        </div>

        {/* Top-5 — paidFiltered dan */}
        <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20 }}>
          <div style={{ color: C.muted, fontSize: 11, fontWeight: 700, letterSpacing: 1, marginBottom: 14 }}>TOP-5 MAHSULOT</div>
          {top5.length === 0
            ? <div style={{ color: C.muted, fontSize: 13, textAlign: 'center', padding: '20px 0' }}>Ma'lumot yo'q</div>
            : top5.map((p, i) => (
              <div key={p.name} style={{ marginBottom: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ color: C.text, fontSize: 13, fontWeight: 600 }}>
                    <span style={{ color: C.primary, marginRight: 6 }}>#{i + 1}</span>{p.name}
                  </span>
                  <span style={{ color: C.muted, fontSize: 12 }}>{p.qty} ta</span>
                </div>
                <div style={{ background: C.card, borderRadius: 4, height: 6, overflow: 'hidden' }}>
                  <div style={{ background: C.primary, height: '100%', width: `${Math.round(p.qty / maxQty * 100)}%`, borderRadius: 4 }} />
                </div>
              </div>
            ))
          }
        </div>

        {/* Ofitsiant — paid dan (umumiy tasvir, filter ta'sir qilmaydi) */}
        <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20 }}>
          <div style={{ color: C.muted, fontSize: 11, fontWeight: 700, letterSpacing: 1, marginBottom: 4 }}>OFITSIANT BO'YICHA</div>
          <div style={{ color: C.muted, fontSize: 10, marginBottom: 12 }}>sana filterlangan, barcha ofitsiantlar</div>
          {waiterStats.length === 0
            ? <div style={{ color: C.muted, fontSize: 13, textAlign: 'center', padding: '20px 0' }}>Ma'lumot yo'q</div>
            : waiterStats.map((w, i) => (
              <div key={w.name} style={{ marginBottom: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                  <span style={{ color: C.text, fontSize: 13, fontWeight: 600 }}>
                    <span style={{ color: C.success, marginRight: 6 }}>#{i + 1}</span>{w.name}
                  </span>
                  <span style={{ color: C.muted, fontSize: 12 }}>{w.orders} buyurtma</span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 8 }}>
                  <div style={{ flex: 1, background: C.card, borderRadius: 4, height: 6, overflow: 'hidden' }}>
                    <div style={{ background: C.success, height: '100%', width: `${Math.round(w.revenue / maxRev * 100)}%`, borderRadius: 4 }} />
                  </div>
                  <span style={{ color: C.primary, fontSize: 12, fontWeight: 700, whiteSpace: 'nowrap' }}>{fmt(w.revenue)}</span>
                </div>
              </div>
            ))
          }
        </div>
      </div>

      {/* Buyurtmalar jadvali */}
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, overflow: 'hidden' }}>
        <div style={{ padding: '14px 20px', borderBottom: `1px solid ${C.border}`, display: 'flex', justifyContent: 'space-between' }}>
          <span style={{ color: C.text, fontWeight: 600, fontSize: 14 }}>
            To'langan buyurtmalar{waiterFilter ? ` — ${waiterFilter}` : ''}
          </span>
          <span style={{ color: C.muted, fontSize: 13 }}>{paidFiltered.length} ta</span>
        </div>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 480 }}>
            <thead>
              <tr style={{ background: C.card }}>
                {['Raqam', 'Stol', 'Ofitsiant', 'Summa', 'Vaqt'].map(h => (
                  <th key={h} style={{ padding: '10px 20px', textAlign: 'left', color: C.muted, fontSize: 12, fontWeight: 600 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {paidFiltered.map(o => (
                <tr key={o.id} style={{ borderTop: `1px solid ${C.border}` }}>
                  <td style={{ padding: '11px 20px', color: C.text, fontWeight: 600, fontSize: 13 }}>{o.order_number}</td>
                  <td style={{ padding: '11px 20px', color: C.muted, fontSize: 13 }}>{o.table?.name || '—'}</td>
                  <td style={{ padding: '11px 20px', color: C.muted, fontSize: 13 }}>{o.waiter?.name || '—'}</td>
                  <td style={{ padding: '11px 20px', color: C.primary, fontWeight: 700, fontSize: 13 }}>{fmt(o.total)}</td>
                  <td style={{ padding: '11px 20px', color: C.muted, fontSize: 13 }}>{fmtTime(o.closed_at || o.created_at)}</td>
                </tr>
              ))}
              {!loading && paidFiltered.length === 0 && (
                <tr><td colSpan={5} style={{ padding: 24, textAlign: 'center', color: C.muted }}>To'langan buyurtma yo'q</td></tr>
              )}
            </tbody>
            {paidFiltered.length > 0 && (
              <tfoot>
                <tr style={{ borderTop: `2px solid ${C.border}`, background: C.card }}>
                  <td colSpan={3} style={{ padding: '12px 20px', color: C.muted, fontSize: 13, fontWeight: 600 }}>Jami ({paidFiltered.length} ta buyurtma)</td>
                  <td style={{ padding: '12px 20px', color: C.primary, fontWeight: 800, fontSize: 15 }}>{fmt(revenue)}</td>
                  <td />
                </tr>
              </tfoot>
            )}
          </table>
        </div>
      </div>
    </div>
  )
}

// ─── Orders (admin) ───────────────────────────────────────────────────────────
const ORDER_STATUS_COLOR = { open: '#F97316', sent: '#F97316', ready: '#22C55E', bill: '#EAB308', paid: '#94A3B8', cancelled: '#EF4444' }
const ORDER_STATUS_LABEL = { open: 'Ochiq', sent: 'Oshpazda', ready: 'Tayyor', bill: 'Hisob', paid: "To'langan", cancelled: 'Bekor' }

function OrdersPage() {
  const isMobile = useIsMobile()
  const [orders, setOrders]     = useState([])
  const [loading, setLoading]   = useState(true)
  const [filter, setFilter]     = useState('all')
  const [search, setSearch]     = useState('')
  const [expanded, setExpanded] = useState(null)
  const [confirm, setConfirm]   = useState(null)  // order object

  useEffect(() => { load() }, [])

  async function load() {
    setLoading(true)
    ordersApi.getAllAdmin().then(r => setOrders(r.data)).catch(() => {}).finally(() => setLoading(false))
  }

  async function cancelOrder(id) {
    try {
      await ordersApi.updateStatus(id, 'cancelled')
      setConfirm(null)
      await load()
    } catch {
      alert("Bekor qilishda xato")
    }
  }

  const visible = orders.filter(o => {
    if (filter !== 'all' && o.status !== filter) return false
    if (search && !o.order_number?.includes(search) && !o.table?.name?.toLowerCase().includes(search.toLowerCase())) return false
    return true
  })

  return (
    <div>
      {/* Filter + search */}
      <div style={{ display: 'flex', gap: 10, marginBottom: 16, flexWrap: 'wrap', alignItems: 'center' }}>
        <div style={{ position: 'relative', flex: 1, minWidth: 200 }}>
          <Search size={14} color={C.muted} style={{ position: 'absolute', left: 10, top: '50%', transform: 'translateY(-50%)' }} />
          <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Raqam yoki stol..."
            style={{ width: '100%', background: C.surface, border: `1px solid ${C.border}`, borderRadius: 8, padding: '9px 10px 9px 32px', color: C.text, fontSize: 13, boxSizing: 'border-box', outline: 'none' }} />
        </div>
        <button onClick={load} disabled={loading}
          style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 8, padding: '9px 12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, color: C.muted, fontSize: 13, opacity: loading ? 0.5 : 1 }}>
          <RefreshCw size={14} style={{ animation: loading ? 'spin 1s linear infinite' : 'none' }} /> Yangilash
        </button>
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
          {[['all', 'Barchasi'], ['open', 'Ochiq'], ['sent', 'Oshpaz'], ['ready', 'Tayyor'], ['bill', 'Hisob'], ['paid', "To'langan"], ['cancelled', 'Bekor']].map(([k, l]) => (
            <button key={k} onClick={() => setFilter(k)} style={{
              background: filter === k ? C.primary : C.surface,
              color: filter === k ? '#fff' : C.muted,
              border: `1px solid ${filter === k ? C.primary : C.border}`,
              borderRadius: 8, padding: '8px 14px', fontSize: 12, fontWeight: 600, cursor: 'pointer',
            }}>{l}</button>
          ))}
        </div>
      </div>

      {/* Jami */}
      <div style={{ color: C.muted, fontSize: 12, marginBottom: 10 }}>{visible.length} ta buyurtma</div>

      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: 32, textAlign: 'center', color: C.muted }}>Yuklanmoqda...</div>
        ) : visible.length === 0 ? (
          <div style={{ padding: 32, textAlign: 'center', color: C.muted }}>Buyurtma topilmadi</div>
        ) : isMobile ? (
          /* Mobile cards */
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, padding: 12 }}>
            {visible.map(o => {
              const sc = ORDER_STATUS_COLOR[o.status] || C.muted
              const isOpen = expanded === o.id
              const total = o.total && parseFloat(o.total) > 0
                ? parseFloat(o.total)
                : (o.items || []).reduce((s, i) => s + parseFloat(i.product_price || 0) * (i.quantity || 1), 0)
              const canCancel = !['paid', 'cancelled'].includes(o.status)
              return (
                <div key={o.id} style={{ background: C.card, border: `1px solid ${C.border}`, borderRadius: 10 }}>
                  <div style={{ padding: '12px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', cursor: 'pointer' }}
                    onClick={() => setExpanded(isOpen ? null : o.id)}>
                    <div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                        <span style={{ color: C.text, fontWeight: 700, fontSize: 14 }}>#{o.order_number}</span>
                        <span style={{ background: `${sc}22`, color: sc, borderRadius: 20, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>{ORDER_STATUS_LABEL[o.status] || o.status}</span>
                      </div>
                      <div style={{ display: 'flex', gap: 10, color: C.muted, fontSize: 12, flexWrap: 'wrap' }}>
                        {o.table?.name && <span>Stol: {o.table.name}</span>}
                        {o.waiter?.name && <span>{o.waiter.name}</span>}
                        <span>{(o.items || []).length} ta taom</span>
                        {o.created_at && <span>{new Date(o.created_at).toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' })}</span>}
                      </div>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6, flexShrink: 0 }}>
                      <span style={{ color: C.primary, fontWeight: 700, fontSize: 14 }}>{fmt(total)}</span>
                      {isOpen ? <ChevronUp size={14} color={C.muted} /> : <ChevronDown size={14} color={C.muted} />}
                    </div>
                  </div>
                  {isOpen && (
                    <div style={{ borderTop: `1px solid ${C.border}`, padding: '10px 14px' }}>
                      {(o.items || []).length === 0 ? (
                        <div style={{ color: C.muted, fontSize: 12 }}>Taomlar yo'q</div>
                      ) : (o.items || []).map((item, i) => (
                        <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 4 }}>
                          <span style={{ color: C.text }}>{item.product_name}</span>
                          <span style={{ color: C.muted }}>x{item.quantity} = {fmt(item.total)}</span>
                        </div>
                      ))}
                      {canCancel && (
                        <button onClick={() => setConfirm(o)}
                          style={{ marginTop: 8, background: 'none', border: `1px solid ${C.danger}`, borderRadius: 6, padding: '6px 14px', color: C.danger, fontSize: 12, fontWeight: 600, cursor: 'pointer' }}>
                          Bekor qilish
                        </button>
                      )}
                    </div>
                  )}
                </div>
              )
            })}
          </div>
        ) : (
          /* Desktop table */
          <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 600 }}>
            <thead>
              <tr style={{ background: C.card }}>
                {['', 'Raqam', 'Stol', 'Ofitsiant', 'Taomlar', 'Summa', 'Holat', 'Vaqt', ''].map(h => (
                  <th key={h} style={{ padding: '10px 16px', textAlign: 'left', color: C.muted, fontSize: 12, fontWeight: 600 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {visible.map(o => {
                const sc = ORDER_STATUS_COLOR[o.status] || C.muted
                const isOpen = expanded === o.id
                const total = o.total && parseFloat(o.total) > 0
                  ? parseFloat(o.total)
                  : (o.items || []).reduce((s, i) => s + parseFloat(i.product_price || 0) * (i.quantity || 1), 0)
                const canCancel = !['paid', 'cancelled'].includes(o.status)
                return (
                  <>
                    <tr key={o.id} style={{ borderTop: `1px solid ${C.border}` }}>
                      <td style={{ padding: '12px 8px 12px 16px', color: C.muted, cursor: 'pointer' }}
                        onClick={() => setExpanded(isOpen ? null : o.id)}>
                        {isOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                      </td>
                      <td style={{ padding: '12px 16px', color: C.text, fontWeight: 700, fontSize: 13, cursor: 'pointer' }}
                        onClick={() => setExpanded(isOpen ? null : o.id)}>{o.order_number}</td>
                      <td style={{ padding: '12px 16px', color: C.muted, fontSize: 13 }}>{o.table?.name || '—'}</td>
                      <td style={{ padding: '12px 16px', color: C.muted, fontSize: 13 }}>{o.waiter?.name || '—'}</td>
                      <td style={{ padding: '12px 16px', color: C.muted, fontSize: 13 }}>{(o.items || []).length} ta</td>
                      <td style={{ padding: '12px 16px', color: C.primary, fontWeight: 700, fontSize: 13 }}>{fmt(total)}</td>
                      <td style={{ padding: '12px 16px' }}>
                        <span style={{ background: `${sc}22`, color: sc, borderRadius: 20, padding: '3px 10px', fontSize: 11, fontWeight: 600 }}>
                          {ORDER_STATUS_LABEL[o.status] || o.status}
                        </span>
                      </td>
                      <td style={{ padding: '12px 16px', color: C.muted, fontSize: 12 }}>
                        {o.created_at ? new Date(o.created_at).toLocaleTimeString('uz-UZ', { hour: '2-digit', minute: '2-digit' }) : '---'}
                      </td>
                      <td style={{ padding: '12px 16px' }}>
                        {canCancel && (
                          <button onClick={() => setConfirm(o)}
                            style={{ background: 'none', border: `1px solid ${C.danger}`, borderRadius: 6, padding: '5px 10px', color: C.danger, fontSize: 11, fontWeight: 600, cursor: 'pointer' }}>
                            Bekor
                          </button>
                        )}
                      </td>
                    </tr>
                    {isOpen && (
                      <tr key={o.id + '-detail'} style={{ background: C.card }}>
                        <td colSpan={9} style={{ padding: '12px 20px 16px 48px' }}>
                          {(o.items || []).length === 0 ? (
                            <div style={{ color: C.muted, fontSize: 12 }}>Taomlar yo'q</div>
                          ) : (o.items || []).map((item, i) => (
                            <div key={i} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 13, marginBottom: 4, maxWidth: 500 }}>
                              <span style={{ color: C.text }}>{item.product_name}</span>
                              <span style={{ color: C.muted }}>x {item.quantity} = {fmt(item.total)}</span>
                            </div>
                          ))}
                        </td>
                      </tr>
                    )}
                  </>
                )
              })}
            </tbody>
            <tfoot>
              <tr style={{ borderTop: `2px solid ${C.border}`, background: C.card }}>
                <td colSpan={5} style={{ padding: '12px 16px', color: C.muted, fontSize: 12, fontWeight: 600 }}>
                  Jami ({visible.length} ta buyurtma)
                </td>
                <td style={{ padding: '12px 16px', color: C.primary, fontWeight: 800, fontSize: 15 }}>
                  {fmt(visible.reduce((s, o) => {
                    const t = o.total && parseFloat(o.total) > 0
                      ? parseFloat(o.total)
                      : (o.items || []).reduce((a, i) => a + parseFloat(i.product_price || 0) * (i.quantity || 1), 0)
                    return s + t
                  }, 0))}
                </td>
                <td colSpan={3} />
              </tr>
            </tfoot>
          </table>
          </div>
        )}
      </div>

      {confirm && (
        <ConfirmDelete
          text={"Buyurtma #" + confirm.order_number + "ni bekor qilmoqchimisiz?"}
          onConfirm={() => cancelOrder(confirm.id)}
          onClose={() => setConfirm(null)}
        />
      )}
    </div>
  )
}

// ─── Settings ─────────────────────────────────────────────────────────────────
function SettingsPage() {
  const STORAGE_KEY = 'pos_settings'
  const defaults = {
    cafe_name: 'Kafe POS',
    cafe_address: '',
    cafe_phone: '',
    currency: "so'm",
    lang: 'uz',
    receipt_footer: "Tashrifingiz uchun rahmat!",
    kitchen_poll: '5',
    cashier_poll: '5',
  }
  const [form, setForm] = useState(() => {
    try { return { ...defaults, ...JSON.parse(localStorage.getItem(STORAGE_KEY) || '{}') } }
    catch { return defaults }
  })
  const [saved, setSaved] = useState(false)

  function set(k, v) { setForm(f => ({ ...f, [k]: v })) }

  function save() {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(form))
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div style={{ padding: 24, maxWidth: 600 }}>
      <h2 style={{ color: C.text, fontSize: 20, fontWeight: 700, marginBottom: 24 }}>Sozlamalar</h2>

      {/* Kafe ma'lumotlari */}
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20, marginBottom: 16 }}>
        <div style={{ color: C.muted, fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 16 }}>Kafe ma'lumotlari</div>
        <Field label="Kafe nomi" value={form.cafe_name} onChange={v => set('cafe_name', v)} placeholder="Kafe POS" />
        <Field label="Manzil" value={form.cafe_address} onChange={v => set('cafe_address', v)} placeholder="Toshkent, Chilonzor..." />
        <Field label="Telefon" value={form.cafe_phone} onChange={v => set('cafe_phone', v)} placeholder="+998 90 123 45 67" />
        <Field label="Chek pastki matni" value={form.receipt_footer} onChange={v => set('receipt_footer', v)} placeholder="Tashrifingiz uchun rahmat!" />
      </div>

      {/* Til */}
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20, marginBottom: 16 }}>
        <div style={{ color: C.muted, fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 16 }}>Til / Язык</div>
        <div style={{ display: 'flex', gap: 10 }}>
          {[['uz', "O'zbek"], ['ru', 'Русский']].map(([k, l]) => (
            <button key={k} onClick={() => set('lang', k)} style={{
              flex: 1, padding: '12px', borderRadius: 10, fontWeight: 600, fontSize: 14, cursor: 'pointer',
              background: form.lang === k ? C.primary : C.card,
              color: form.lang === k ? '#fff' : C.muted,
              border: `1px solid ${form.lang === k ? C.primary : C.border}`,
            }}>{l}</button>
          ))}
        </div>
      </div>

      {/* Tizim */}
      <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 12, padding: 20, marginBottom: 24 }}>
        <div style={{ color: C.muted, fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 16 }}>Tizim</div>
        <div style={{ marginBottom: 14 }}>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 6 }}>Backend URL</div>
          <div style={{ color: C.text, fontSize: 13, background: C.card, borderRadius: 8, padding: '10px 14px', fontFamily: 'monospace' }}>
            {import.meta.env.VITE_API_URL || 'http://localhost:8000/api'}
          </div>
        </div>
        <div style={{ marginBottom: 14 }}>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 6 }}>Versiya</div>
          <div style={{ color: C.text, fontSize: 13, background: C.card, borderRadius: 8, padding: '10px 14px', fontFamily: 'monospace' }}>
            Kafe POS v1.0.0
          </div>
        </div>
        <div>
          <div style={{ color: C.muted, fontSize: 12, marginBottom: 6 }}>Yangilanish intervali</div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {['3', '5', '10', '15', '30'].map(s => (
              <button key={s} onClick={() => set('kitchen_poll', s)} style={{
                padding: '8px 16px', borderRadius: 8, fontSize: 13, fontWeight: 600, cursor: 'pointer',
                background: form.kitchen_poll === s ? C.primary : C.card,
                color: form.kitchen_poll === s ? '#fff' : C.muted,
                border: `1px solid ${form.kitchen_poll === s ? C.primary : C.border}`,
              }}>{s}s</button>
            ))}
          </div>
          <div style={{ color: C.muted, fontSize: 11, marginTop: 6 }}>Oshpaz va kassir uchun (standart: 5s)</div>
        </div>
      </div>

      <button onClick={save} style={{
        background: saved ? C.success : C.primary, color: '#fff', border: 'none',
        borderRadius: 10, padding: '14px 32px', fontSize: 15, fontWeight: 700,
        cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8, transition: 'background .3s',
      }}>
        {saved ? '✓ Saqlandi' : 'Saqlash'}
      </button>
    </div>
  )
}

// ─── Sklad sahifasi ────────────────────────────────────────────────────────────
function StockPage() {
  const [tab, setTab]               = useState('ingredients') // ingredients | recipe | movements
  const [ingredients, setIngredients] = useState([])
  const [products, setProducts]     = useState([])
  const [loading, setLoading]       = useState(true)

  // Ingredient modal
  const [modal, setModal]           = useState(null) // null | 'add' | 'edit' | 'stock-in' | 'movements'
  const [selected, setSelected]     = useState(null)
  const [form, setForm]             = useState({})
  const [saving, setSaving]         = useState(false)

  // Recipe modal
  const [recipeProduct, setRecipeProduct] = useState(null)
  const [recipe, setRecipe]         = useState([])
  const [recipeModal, setRecipeModal] = useState(false)

  // Movements list
  const [movements, setMovements]   = useState([])
  // Tannarxlar: { productId: { cost, has_recipe } }
  const [costs, setCosts]           = useState({})
  // Inline narx tahrirlash: { productId: string }
  const [editingPrice, setEditingPrice] = useState({})
  const [savingPrice, setSavingPrice]   = useState({})

  const UNITS = ['kg', 'gr', 'litr', 'ml', 'dona', 'paket', 'quti']

  const load = useCallback(async () => {
    try {
      setLoading(true)
      const [iRes, pRes, cRes] = await Promise.all([
        stockApi.getIngredients(),
        menuApi.getProducts(),
        stockApi.getAllCosts(),
      ])
      setIngredients(iRes.data || [])
      setProducts(pRes.data || [])
      // costs map: { productId: {cost, has_recipe} }
      const map = {}
      ;(cRes.data || []).forEach(c => { map[c.product_id] = c })
      setCosts(map)
    } catch(e) {}
    finally { setLoading(false) }
  }, [])

  useEffect(() => { load() }, [load])

  function openAdd() { setForm({ name:'', unit:'kg', quantity:0, min_quantity:0, cost_per_unit:0 }); setModal('add') }
  function openEdit(i) { setSelected(i); setForm({ name:i.name, unit:i.unit, min_quantity:i.min_quantity, cost_per_unit:i.cost_per_unit }); setModal('edit') }
  function openStockIn(i) { setSelected(i); setForm({ quantity:'', cost_per_unit: i.cost_per_unit, reason:'' }); setModal('stock-in') }
  async function openMovements(i) { setSelected(i); setModal('movements'); const r = await stockApi.getMovements(i.id); setMovements(r.data||[]) }

  async function saveIngredient() {
    if (!form.name) return
    setSaving(true)
    try {
      if (modal === 'add') await stockApi.createIngredient(form)
      else await stockApi.updateIngredient(selected.id, form)
      await load(); setModal(null)
    } catch(e) {} finally { setSaving(false) }
  }

  async function doStockIn() {
    if (!form.quantity || form.quantity <= 0) return
    setSaving(true)
    try {
      await stockApi.addStock(selected.id, form)
      await load(); setModal(null)
    } catch(e) {} finally { setSaving(false) }
  }

  async function deleteIngredient(i) {
    if (!window.confirm(`"${i.name}"ni o'chirasizmi?`)) return
    await stockApi.deleteIngredient(i.id); load()
  }

  async function openRecipe(product) {
    setRecipeProduct(product)
    const r = await stockApi.getRecipe(product.id)
    const existing = r.data || []
    setRecipe(
      ingredients.map(ing => {
        const found = existing.find(e => e.id === ing.id)
        return { id: ing.id, name: ing.name, unit: ing.unit, quantity: found ? found.quantity : '', enabled: !!found }
      })
    )
    setRecipeModal(true)
  }

  async function saveRecipe() {
    const items = recipe.filter(r => r.enabled && r.quantity > 0).map(r => ({ id: r.id, quantity: parseFloat(r.quantity) }))
    await stockApi.saveRecipe(recipeProduct.id, items)
    setRecipeModal(false)
    // Tannarxlarni yangilash
    const cRes = await stockApi.getAllCosts()
    const map = {}
    ;(cRes.data || []).forEach(c => { map[c.product_id] = c })
    setCosts(map)
  }

  const fld = (k, v) => setForm(f => ({...f, [k]: v}))

  async function savePrice(p) {
    const newPrice = parseFloat(editingPrice[p.id])
    if (!newPrice || newPrice <= 0) return
    setSavingPrice(s => ({ ...s, [p.id]: true }))
    try {
      await menuApi.updateProduct(p.id, { price: newPrice })
      setProducts(ps => ps.map(x => x.id === p.id ? { ...x, price: newPrice } : x))
      setEditingPrice(s => { const n = {...s}; delete n[p.id]; return n })
    } catch(e) {}
    setSavingPrice(s => ({ ...s, [p.id]: false }))
  }

  const lowItems = ingredients.filter(i => i.low_stock)

  // ── RENDER ──────────────────────────────────────────────────────────────────
  const tabs = [
    { key:'ingredients', label:'Ingredientlar' },
    { key:'recipe',      label:'Retseptlar' },
  ]

  return (
    <div style={{ padding: 24, maxWidth: 1100, margin: '0 auto' }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom: 20 }}>
        <h2 style={{ color: C.text, margin:0, fontSize:20, fontWeight:700 }}>📦 Sklad</h2>
        {tab === 'ingredients' && (
          <button onClick={openAdd} style={{
            background: C.primary, color:'#fff', border:'none', borderRadius:8,
            padding:'10px 18px', fontWeight:700, cursor:'pointer', display:'flex', alignItems:'center', gap:6,
          }}><Plus size={16}/> Ingredient qo'shish</button>
        )}
      </div>

      {/* Kam qolgan ogohlantirish */}
      {lowItems.length > 0 && (
        <div style={{ background:'#7C2D1220', border:`1px solid ${C.danger}`, borderRadius:10, padding:'12px 16px', marginBottom:16, display:'flex', alignItems:'center', gap:10 }}>
          <AlertTriangle size={18} color={C.danger}/>
          <span style={{ color: C.danger, fontSize:13, fontWeight:600 }}>
            Kam qolgan: {lowItems.map(i => `${i.name} (${i.quantity} ${i.unit})`).join(', ')}
          </span>
        </div>
      )}

      {/* Tab buttons */}
      <div style={{ display:'flex', gap:8, marginBottom:20 }}>
        {tabs.map(t => (
          <button key={t.key} onClick={()=>setTab(t.key)} style={{
            padding:'8px 18px', borderRadius:8, fontWeight:600, fontSize:13, cursor:'pointer',
            background: tab===t.key ? C.primary : C.card,
            color: tab===t.key ? '#fff' : C.muted,
            border: `1px solid ${tab===t.key ? C.primary : C.border}`,
          }}>{t.label}</button>
        ))}
      </div>

      {loading ? <div style={{color:C.muted, textAlign:'center', padding:40}}>Yuklanmoqda...</div> : (

        // ── Ingredientlar tab ────────────────────────────────────────────────
        tab === 'ingredients' ? (
          <div>
            {ingredients.length === 0 ? (
              <div style={{ color:C.muted, textAlign:'center', padding:60 }}>Hali ingredient qo'shilmagan</div>
            ) : (
              <div style={{ background:C.surface, borderRadius:12, overflow:'hidden', border:`1px solid ${C.border}` }}>
                <table style={{ width:'100%', borderCollapse:'collapse' }}>
                  <thead>
                    <tr style={{ borderBottom:`1px solid ${C.border}` }}>
                      {['Nomi','Birlik','Qoldiq','Min.','Narx/birlik','Jami qiymat','Holat',''].map((h,i) => (
                        <th key={i} style={{ padding:'12px 16px', textAlign: i >= 2 && i <= 5 ? 'right' : 'left', color:C.muted, fontSize:12, fontWeight:600 }}>{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {ingredients.map(ing => (
                      <tr key={ing.id} style={{ borderBottom:`1px solid ${C.border}30` }}>
                        <td style={{ padding:'12px 16px', color:C.text, fontWeight:600 }}>{ing.name}</td>
                        <td style={{ padding:'12px 16px', color:C.muted }}>{ing.unit}</td>
                        <td style={{ padding:'12px 16px', color: ing.low_stock ? C.danger : C.success, fontWeight:700, textAlign:'right' }}>
                          {Number(ing.quantity).toFixed(2)}
                        </td>
                        <td style={{ padding:'12px 16px', color:C.muted, textAlign:'right' }}>{ing.min_quantity}</td>
                        <td style={{ padding:'12px 16px', color:C.muted, textAlign:'right' }}>{Number(ing.cost_per_unit).toLocaleString()} so'm</td>
                        <td style={{ padding:'12px 16px', color:C.warning, fontWeight:700, textAlign:'right' }}>
                          {Math.round(Number(ing.quantity) * Number(ing.cost_per_unit)).toLocaleString()} so'm
                        </td>
                        <td style={{ padding:'12px 16px' }}>
                          {ing.low_stock
                            ? <span style={{ background:`${C.danger}20`, color:C.danger, borderRadius:6, padding:'3px 8px', fontSize:11, fontWeight:700 }}>⚠ Kam</span>
                            : <span style={{ background:`${C.success}20`, color:C.success, borderRadius:6, padding:'3px 8px', fontSize:11, fontWeight:700 }}>OK</span>
                          }
                        </td>
                        <td style={{ padding:'12px 16px' }}>
                          <div style={{ display:'flex', gap:6 }}>
                            <button title="Kirim" onClick={()=>openStockIn(ing)} style={{...iconBtnSm, color:C.success}}><ArrowDownCircle size={15}/></button>
                            <button title="Harakatlar" onClick={()=>openMovements(ing)} style={{...iconBtnSm, color:C.primary}}><ClipboardList size={15}/></button>
                            <button title="Tahrirlash" onClick={()=>openEdit(ing)} style={{...iconBtnSm, color:C.muted}}><Edit2 size={15}/></button>
                            <button title="O'chirish" onClick={()=>deleteIngredient(ing)} style={{...iconBtnSm, color:C.danger}}><Trash2 size={15}/></button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                  <tfoot>
                    <tr style={{ borderTop:`2px solid ${C.border}` }}>
                      <td colSpan={5} style={{ padding:'12px 16px', color:C.muted, fontSize:12, fontWeight:600 }}>
                        Jami ({ingredients.length} ta ingredient)
                      </td>
                      <td style={{ padding:'12px 16px', color:C.warning, fontWeight:800, fontSize:14, textAlign:'right' }}>
                        {ingredients.reduce((s, i) => s + Math.round(Number(i.quantity) * Number(i.cost_per_unit)), 0).toLocaleString()} so'm
                      </td>
                      <td colSpan={2} />
                    </tr>
                  </tfoot>
                </table>
              </div>
            )}
          </div>
        ) : (

        // ── Retseptlar tab ───────────────────────────────────────────────────
          <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(240px,1fr))', gap:14 }}>
            {products.map(p => {
              const c = costs[p.id]
              const sellPrice = Number(p.price || 0)
              const cost = c?.cost || 0
              const margin = sellPrice - cost
              const marginPct = sellPrice > 0 ? Math.round((margin / sellPrice) * 100) : null
              return (
                <div key={p.id} style={{ background:C.surface, border:`1px solid ${C.border}`, borderRadius:12, padding:16 }}>
                  <div style={{ color:C.text, fontWeight:700, marginBottom:4 }}>{p.name_uz}</div>
                  <div style={{ color:C.muted, fontSize:12, marginBottom:12 }}>{p.category?.name_uz || ''}</div>

                  {c?.has_recipe ? (
                    <div style={{ background:C.card, borderRadius:8, padding:'10px 12px', marginBottom:12 }}>
                      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:4 }}>
                        <span style={{ color:C.muted, fontSize:11 }}>Tannarx:</span>
                        <span style={{ color:C.warning, fontWeight:700, fontSize:13 }}>{cost.toLocaleString()} so'm</span>
                      </div>
                      <div style={{ display:'flex', justifyContent:'space-between', marginBottom:4 }}>
                        <span style={{ color:C.muted, fontSize:11 }}>Sotish narxi:</span>
                        <span style={{ color:C.text, fontSize:13 }}>{sellPrice.toLocaleString()} so'm</span>
                      </div>
                      <div style={{ display:'flex', justifyContent:'space-between' }}>
                        <span style={{ color:C.muted, fontSize:11 }}>Foyda:</span>
                        <span style={{ color: margin >= 0 ? C.success : C.danger, fontWeight:700, fontSize:13 }}>
                          {margin.toLocaleString()} so'm {marginPct !== null ? `(${marginPct}%)` : ''}
                        </span>
                      </div>
                    </div>
                  ) : (
                    <div style={{ color:C.muted, fontSize:12, marginBottom:12, fontStyle:'italic' }}>
                      Retsept kiritilmagan
                    </div>
                  )}

                  {/* Narx tahrirlash */}
                  {editingPrice[p.id] !== undefined ? (
                    <div style={{ display:'flex', gap:6, marginBottom:8 }}>
                      <input
                        type="number"
                        value={editingPrice[p.id]}
                        onChange={e => setEditingPrice(s => ({ ...s, [p.id]: e.target.value }))}
                        onKeyDown={e => { if (e.key === 'Enter') savePrice(p); if (e.key === 'Escape') setEditingPrice(s => { const n={...s}; delete n[p.id]; return n }) }}
                        autoFocus
                        style={{ flex:1, background:C.card, border:`1px solid ${C.primary}`, borderRadius:8, padding:'7px 10px', color:C.text, fontSize:13, outline:'none' }}
                      />
                      <button onClick={() => savePrice(p)} disabled={savingPrice[p.id]} style={{ background:C.primary, border:'none', borderRadius:8, padding:'7px 12px', color:'#fff', fontWeight:700, cursor:'pointer', fontSize:12 }}>
                        {savingPrice[p.id] ? '...' : '✓'}
                      </button>
                      <button onClick={() => setEditingPrice(s => { const n={...s}; delete n[p.id]; return n })} style={{ background:C.card, border:`1px solid ${C.border}`, borderRadius:8, padding:'7px 10px', color:C.muted, cursor:'pointer', fontSize:12 }}>✕</button>
                    </div>
                  ) : (
                    <button onClick={() => setEditingPrice(s => ({ ...s, [p.id]: String(sellPrice) }))} style={{
                      width:'100%', background:'transparent', border:`1px solid ${C.border}`,
                      borderRadius:8, padding:'7px 0', color:C.muted, fontWeight:600,
                      fontSize:12, cursor:'pointer', marginBottom:6,
                    }}>✏️ Narx o'zgartirish</button>
                  )}

                  <button onClick={()=>openRecipe(p)} style={{
                    width:'100%', background:C.card, border:`1px solid ${C.border}`,
                    borderRadius:8, padding:'8px 0', color:C.primary, fontWeight:600,
                    fontSize:12, cursor:'pointer',
                  }}>Retseptni sozlash</button>
                </div>
              )
            })}
          </div>
        )
      )}

      {/* ── Add / Edit modal ─────────────────────────────────────────────── */}
      {(modal === 'add' || modal === 'edit') && (
        <Modal title={modal==='add' ? 'Yangi ingredient' : 'Tahrirlash'} onClose={()=>setModal(null)}>
          <Field label="Nomi" value={form.name||''} onChange={v=>fld('name',v)} placeholder="Masalan: Un, Go'sht"/>
          <div style={{marginBottom:14}}>
            <div style={{color:C.muted,fontSize:12,marginBottom:6}}>O'lchov birligi</div>
            <select value={form.unit||'kg'} onChange={e=>fld('unit',e.target.value)}
              style={{width:'100%',background:C.card,border:`1px solid ${C.border}`,borderRadius:8,padding:'10px 14px',color:C.text,fontSize:13,outline:'none'}}>
              {UNITS.map(u=><option key={u} value={u}>{u}</option>)}
            </select>
          </div>
          {modal==='add' && <Field label="Boshlang'ich miqdor" value={form.quantity||''} onChange={v=>fld('quantity',v)} type="number"/>}
          <Field label="Minimum qoldiq (ogohlantirish)" value={form.min_quantity||''} onChange={v=>fld('min_quantity',v)} type="number"/>
          <Field label="Narx/birlik (so'm)" value={form.cost_per_unit||''} onChange={v=>fld('cost_per_unit',v)} type="number"/>
          <SaveBtn onClick={saveIngredient} loading={saving}/>
        </Modal>
      )}

      {/* ── Kirim modal ──────────────────────────────────────────────────── */}
      {modal === 'stock-in' && selected && (
        <Modal title={`Kirim: ${selected.name}`} onClose={()=>setModal(null)}>
          <div style={{color:C.muted,fontSize:13,marginBottom:16}}>
            Joriy qoldiq: <b style={{color:C.success}}>{selected.quantity} {selected.unit}</b>
          </div>
          <Field label={`Miqdor (${selected.unit})`} value={form.quantity||''} onChange={v=>fld('quantity',v)} type="number"/>
          <Field label="Narx/birlik (so'm)" value={form.cost_per_unit||''} onChange={v=>fld('cost_per_unit',v)} type="number"/>
          <Field label="Izoh" value={form.reason||''} onChange={v=>fld('reason',v)} placeholder="Yangi partiya, etkazib beruvchi..."/>
          <SaveBtn onClick={doStockIn} loading={saving} label="Kirim qilish"/>
        </Modal>
      )}

      {/* ── Harakatlar modali ────────────────────────────────────────────── */}
      {modal === 'movements' && selected && (
        <Modal title={`${selected.name} — harakatlar`} onClose={()=>setModal(null)}>
          <div style={{maxHeight:350, overflowY:'auto'}}>
            {movements.length === 0
              ? <div style={{color:C.muted,textAlign:'center',padding:30}}>Harakatlar yo'q</div>
              : movements.map(m => (
                <div key={m.id} style={{display:'flex',justifyContent:'space-between',alignItems:'center',padding:'10px 0',borderBottom:`1px solid ${C.border}30`}}>
                  <div style={{display:'flex',alignItems:'center',gap:8}}>
                    {m.type==='in'
                      ? <ArrowDownCircle size={16} color={C.success}/>
                      : <ArrowUpCircle size={16} color={C.danger}/>}
                    <div>
                      <div style={{color:C.text,fontSize:13,fontWeight:600}}>{m.type==='in'?'+ ':'- '}{m.quantity} {selected.unit}</div>
                      <div style={{color:C.muted,fontSize:11}}>{m.reason || '—'}</div>
                    </div>
                  </div>
                  <div style={{color:C.muted,fontSize:11,textAlign:'right'}}>
                    <div>{m.user?.name || '—'}</div>
                    <div>{new Date(m.created_at).toLocaleDateString('uz-UZ')}</div>
                  </div>
                </div>
              ))
            }
          </div>
        </Modal>
      )}

      {/* ── Retsept modali ───────────────────────────────────────────────── */}
      {recipeModal && recipeProduct && (
        <div style={{position:'fixed',inset:0,background:'#00000088',display:'flex',alignItems:'center',justifyContent:'center',zIndex:200}}>
          <div style={{background:C.surface,border:`1px solid ${C.border}`,borderRadius:14,width:500,maxHeight:'85vh',display:'flex',flexDirection:'column',padding:28}}>
            <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
              <span style={{color:C.text,fontWeight:700,fontSize:16}}>Retsept: {recipeProduct.name_uz}</span>
              <button onClick={()=>setRecipeModal(false)} style={{background:'none',border:'none',cursor:'pointer',color:C.muted}}><X size={20}/></button>
            </div>
            <div style={{color:C.muted,fontSize:12,marginBottom:14}}>1 porsiya uchun ingredientlarni belgilang:</div>
            <div style={{flex:1,overflowY:'auto',marginBottom:16}}>
              {recipe.map((r,i) => (
                <div key={r.id} style={{display:'flex',alignItems:'center',gap:10,padding:'8px 0',borderBottom:`1px solid ${C.border}30`}}>
                  <input type="checkbox" checked={r.enabled} onChange={e=>{
                    const nr=[...recipe]; nr[i]={...nr[i],enabled:e.target.checked}; setRecipe(nr)
                  }} style={{accentColor:C.primary,width:16,height:16}}/>
                  <span style={{color:C.text,fontSize:13,flex:1}}>{r.name}</span>
                  <input type="number" value={r.quantity} onChange={e=>{
                    const nr=[...recipe]; nr[i]={...nr[i],quantity:e.target.value,enabled:true}; setRecipe(nr)
                  }} placeholder="0"
                    style={{width:80,background:C.card,border:`1px solid ${C.border}`,borderRadius:6,padding:'6px 10px',color:C.text,fontSize:13,outline:'none'}}/>
                  <span style={{color:C.muted,fontSize:12,width:30}}>{r.unit}</span>
                </div>
              ))}
            </div>
            <button onClick={saveRecipe} style={{
              background:C.primary,color:'#fff',border:'none',borderRadius:8,
              padding:'12px 0',fontWeight:700,fontSize:14,cursor:'pointer',
            }}>Saqlash</button>
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Xarajatlar sahifasi ───────────────────────────────────────────────────────
function ExpensesPage() {
  const today = new Date().toISOString().slice(0, 10)
  const [from, setFrom]       = useState(today)
  const [to, setTo]           = useState(today)
  const [expenses, setExpenses] = useState([])
  const [orders, setOrders]   = useState([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal]     = useState(false)
  const [form, setForm]       = useState({ type: 'other', amount: '', note: '' })
  const [saving, setSaving]   = useState(false)

  const TYPE_LABELS = {
    stock_in: 'Ombor kirim', salary: 'Maosh', rent: 'Ijara',
    utility: 'Kommunal', equipment: 'Jihozlar', other: 'Boshqa',
  }
  const TYPE_COLORS = {
    stock_in: '#3B82F6', salary: '#8B5CF6', rent: '#F59E0B',
    utility: '#06B6D4', equipment: '#10B981', other: '#94A3B8',
  }

  // Hisobotlar bilan bir xil logika
  function orderTotal(o) {
    const t = parseFloat(o.total || 0)
    if (t > 0) return t
    return (o.items || []).reduce((a, i) => a + parseFloat(i.product_price || 0) * (i.quantity || 1), 0)
  }

  // Buyurtmani mahalliy sana bo'yicha filterlash (Hisobotlar bilan bir xil)
  function inRange(o) {
    const d = toDate(o.closed_at || o.created_at) // toDate → UTC aware ✓
    if (!d) return true
    const ds = d.toLocaleDateString('sv-SE') // YYYY-MM-DD mahalliy vaqt
    if (from && ds < from) return false
    if (to   && ds > to)   return false
    return true
  }

  // byType expenses dan hisoblash
  const byType = Object.values(expenses.reduce((acc, e) => {
    if (!acc[e.type]) acc[e.type] = { type: e.type, total: 0, count: 0 }
    acc[e.type].total += parseFloat(e.amount || 0)
    acc[e.type].count++
    return acc
  }, {}))

  // Frontendda daromad va xarajat hisoblanadi
  const paidInRange = orders.filter(o => o.status === 'paid' && inRange(o))
  const revenue     = paidInRange.reduce((s, o) => s + orderTotal(o), 0)
  const totalExpense = expenses.reduce((s, e) => s + parseFloat(e.amount || 0), 0)
  const netProfit   = revenue - totalExpense

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [eRes, oRes] = await Promise.all([
        expenseApi.getAll({ from, to }),
        ordersApi.getAllAdmin(),
      ])
      setExpenses(eRes.data || [])
      setOrders(oRes.data || [])
    } catch(e) {}
    finally { setLoading(false) }
  }, [from, to])

  useEffect(() => { load() }, [load])

  async function saveExpense() {
    if (!form.amount || !form.type) return
    setSaving(true)
    try {
      await expenseApi.create(form)
      setModal(false)
      setForm({ type: 'other', amount: '', note: '' })
      load()
    } catch(e) {} finally { setSaving(false) }
  }

  async function deleteExpense(id) {
    if (!window.confirm("Xarajatni o'chirasizmi?")) return
    await expenseApi.delete(id)
    load()
  }

  const netColor = netProfit >= 0 ? '#22C55E' : '#EF4444'

  return (
    <div style={{ padding: 24, maxWidth: 1100, margin: '0 auto' }}>
      <div style={{ display:'flex', justifyContent:'space-between', alignItems:'center', marginBottom: 20 }}>
        <h2 style={{ color: C.text, margin:0, fontSize:20, fontWeight:700 }}>💸 Xarajatlar</h2>
        <button onClick={()=>setModal(true)} style={{
          background: C.primary, color:'#fff', border:'none', borderRadius:8,
          padding:'10px 18px', fontWeight:700, cursor:'pointer', display:'flex', alignItems:'center', gap:6,
        }}><Plus size={16}/> Xarajat qo'shish</button>
      </div>

      {/* Filter */}
      <div style={{ display:'flex', gap:10, marginBottom:20, flexWrap:'wrap' }}>
        <div>
          <div style={{color:C.muted,fontSize:11,marginBottom:4}}>Dan</div>
          <input type="date" value={from} onChange={e=>setFrom(e.target.value)}
            style={{background:C.card,border:`1px solid ${C.border}`,borderRadius:8,padding:'8px 12px',color:C.text,fontSize:13,outline:'none'}}/>
        </div>
        <div>
          <div style={{color:C.muted,fontSize:11,marginBottom:4}}>Gacha</div>
          <input type="date" value={to} onChange={e=>setTo(e.target.value)}
            style={{background:C.card,border:`1px solid ${C.border}`,borderRadius:8,padding:'8px 12px',color:C.text,fontSize:13,outline:'none'}}/>
        </div>
      </div>

      {/* Xulosа kartalar */}
      <div style={{ display:'grid', gridTemplateColumns:'repeat(auto-fill, minmax(200px,1fr))', gap:14, marginBottom:24 }}>
        {[
          { label:'Daromad', value: revenue, color: C.success },
          { label:'Xarajat', value: totalExpense, color: C.danger },
          { label:'Sof foyda', value: netProfit, color: netColor, big: true },
        ].map(c => (
          <div key={c.label} style={{ background:C.surface, border:`1px solid ${c.big ? c.color : C.border}`, borderRadius:12, padding:18 }}>
            <div style={{color:C.muted, fontSize:12, marginBottom:6}}>{c.label}</div>
            <div style={{color:c.color, fontSize:c.big?22:18, fontWeight:800}}>
              {Number(c.value||0).toLocaleString()} so'm
            </div>
          </div>
        ))}
      </div>

      {/* Tur bo'yicha */}
      {byType.length > 0 && (
        <div style={{ background:C.surface, border:`1px solid ${C.border}`, borderRadius:12, padding:16, marginBottom:20 }}>
          <div style={{color:C.muted, fontSize:12, marginBottom:12, fontWeight:600}}>Tur bo'yicha xarajat</div>
          <div style={{display:'flex', gap:8, flexWrap:'wrap'}}>
            {byType.map(t => (
              <div key={t.type} style={{
                background:`${TYPE_COLORS[t.type] || '#94A3B8'}20`,
                border:`1px solid ${TYPE_COLORS[t.type] || '#94A3B8'}`,
                borderRadius:8, padding:'8px 14px',
              }}>
                <div style={{color:TYPE_COLORS[t.type]||C.muted, fontSize:11, fontWeight:600}}>{TYPE_LABELS[t.type]||t.type}</div>
                <div style={{color:C.text, fontSize:14, fontWeight:700}}>{Number(t.total).toLocaleString()} so'm</div>
                <div style={{color:C.muted, fontSize:11}}>{t.count} ta</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Jadval */}
      {loading ? <div style={{color:C.muted,textAlign:'center',padding:40}}>Yuklanmoqda...</div> : (
        <div style={{ background:C.surface, borderRadius:12, overflow:'hidden', border:`1px solid ${C.border}` }}>
          {expenses.length === 0 ? (
            <div style={{color:C.muted,textAlign:'center',padding:40}}>Bu davrda xarajat yo'q</div>
          ) : (
            <table style={{width:'100%',borderCollapse:'collapse'}}>
              <thead>
                <tr style={{borderBottom:`1px solid ${C.border}`}}>
                  {['Sana','Tur','Summa','Izoh','Xodim',''].map((h,i)=>(
                    <th key={i} style={{padding:'12px 16px',textAlign:'left',color:C.muted,fontSize:12,fontWeight:600}}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {expenses.map(e=>(
                  <tr key={e.id} style={{borderBottom:`1px solid ${C.border}20`}}>
                    <td style={{padding:'12px 16px',color:C.muted,fontSize:12}}>
                      {new Date(e.created_at).toLocaleDateString('uz-UZ')}
                    </td>
                    <td style={{padding:'12px 16px'}}>
                      <span style={{
                        background:`${TYPE_COLORS[e.type]||'#94A3B8'}20`,
                        color:TYPE_COLORS[e.type]||C.muted,
                        borderRadius:6,padding:'3px 8px',fontSize:11,fontWeight:700,
                      }}>{TYPE_LABELS[e.type]||e.type}</span>
                    </td>
                    <td style={{padding:'12px 16px',color:C.danger,fontWeight:700}}>
                      {Number(e.amount).toLocaleString()} so'm
                    </td>
                    <td style={{padding:'12px 16px',color:C.muted,fontSize:13}}>{e.note||'—'}</td>
                    <td style={{padding:'12px 16px',color:C.muted,fontSize:12}}>{e.user?.name||'—'}</td>
                    <td style={{padding:'12px 16px'}}>
                      {e.type !== 'stock_in' && (
                        <button onClick={()=>deleteExpense(e.id)} style={{...iconBtnSm,color:C.danger}}>
                          <Trash2 size={14}/>
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Xarajat qo'shish modali */}
      {modal && (
        <Modal title="Xarajat qo'shish" onClose={()=>setModal(false)}>
          <div style={{marginBottom:14}}>
            <div style={{color:C.muted,fontSize:12,marginBottom:6}}>Turi</div>
            <select value={form.type} onChange={e=>setForm(f=>({...f,type:e.target.value}))}
              style={{width:'100%',background:C.card,border:`1px solid ${C.border}`,borderRadius:8,padding:'10px 14px',color:C.text,fontSize:13,outline:'none'}}>
              {Object.entries(TYPE_LABELS).filter(([k])=>k!=='stock_in').map(([v,l])=>(
                <option key={v} value={v}>{l}</option>
              ))}
            </select>
          </div>
          <Field label="Summa (so'm)" value={form.amount} onChange={v=>setForm(f=>({...f,amount:v}))} type="number" placeholder="Masalan: 500000"/>
          <Field label="Izoh" value={form.note} onChange={v=>setForm(f=>({...f,note:v}))} placeholder="Masalan: Aprel oyi ijarasi"/>
          <SaveBtn onClick={saveExpense} loading={saving} label="Saqlash"/>
        </Modal>
      )}
    </div>
  )
}
