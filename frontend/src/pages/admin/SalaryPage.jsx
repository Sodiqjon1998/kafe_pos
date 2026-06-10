import { useState, useEffect, useCallback } from 'react'
import { salaryApi } from '../../services/api'

const ROLES = { admin: 'Admin', manager: 'Menejer', cashier: 'Kassir', waiter: 'Ofitsiant', kitchen: 'Oshpaz' }
const TYPES = { monthly: 'Oylik', advance: 'Avans', bonus: 'Bonus' }
const TYPE_COLORS = { monthly: '#22c55e', advance: '#3b82f6', bonus: '#f97316' }

function money(v) {
  return Number(v || 0).toLocaleString('uz-UZ') + ' so\'m'
}

function currentMonth() {
  return new Date().toISOString().slice(0, 7)
}

export default function SalaryPage() {
  const [month, setMonth]         = useState(currentMonth())
  const [users, setUsers]         = useState([])
  const [loading, setLoading]     = useState(false)
  const [selected, setSelected]   = useState(null)   // {user, mode: 'pay'|'history'|'salary'}
  const [summary, setSummary]     = useState([])

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [uRes, sRes] = await Promise.all([
        salaryApi.getAll(month),
        salaryApi.summary(
          new Date(new Date().setMonth(new Date().getMonth() - 5)).toISOString().slice(0, 7),
          currentMonth()
        ),
      ])
      setUsers(uRes.data)
      setSummary(sRes.data)
    } catch (e) {
      console.error(e)
    } finally {
      setLoading(false)
    }
  }, [month])

  useEffect(() => { load() }, [load])

  const totalSalary  = users.reduce((s, u) => s + Number(u.monthly_salary), 0)
  const totalPaid    = users.reduce((s, u) => s + Number(u.paid_this_month), 0)
  const totalDebt    = users.reduce((s, u) => s + Number(u.debt), 0)

  return (
    <div style={{ padding: '0 0 40px' }}>
      {/* ── Header ── */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20, flexWrap: 'wrap' }}>
        <h2 style={{ margin: 0, fontSize: 20, fontWeight: 700 }}>💰 Xodimlar Maoshi</h2>
        <input
          type="month"
          value={month}
          onChange={e => setMonth(e.target.value)}
          style={inputStyle}
        />
        <button onClick={load} style={btnSecStyle}>🔄 Yangilash</button>
      </div>

      {/* ── Statistika kartalar ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(160px,1fr))', gap: 12, marginBottom: 24 }}>
        <StatCard label="Umumiy fond" value={money(totalSalary)} color="#3b82f6" icon="👥" />
        <StatCard label="To'langan"   value={money(totalPaid)}    color="#22c55e" icon="✅" />
        <StatCard label="Qarz"        value={money(totalDebt)}    color="#ef4444" icon="⏳" />
        <StatCard label="Xodimlar"    value={users.length + ' kishi'} color="#f97316" icon="👤" />
      </div>

      {/* ── Xodimlar jadvali ── */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: 40, color: '#94a3b8' }}>Yuklanmoqda...</div>
      ) : (
        <div style={{ display: 'grid', gap: 10 }}>
          {users.map(u => (
            <UserSalaryCard
              key={u.id}
              user={u}
              month={month}
              onPay={() => setSelected({ user: u, mode: 'pay' })}
              onHistory={() => setSelected({ user: u, mode: 'history' })}
              onSetSalary={() => setSelected({ user: u, mode: 'salary' })}
            />
          ))}
          {users.length === 0 && (
            <div style={{ textAlign: 'center', padding: 40, color: '#94a3b8' }}>
              Xodimlar topilmadi
            </div>
          )}
        </div>
      )}

      {/* ── Modals ── */}
      {selected?.mode === 'pay' && (
        <PayModal
          user={selected.user}
          month={month}
          onClose={() => setSelected(null)}
          onDone={() => { setSelected(null); load() }}
        />
      )}
      {selected?.mode === 'history' && (
        <HistoryModal
          user={selected.user}
          month={month}
          onClose={() => setSelected(null)}
          onDeleted={load}
        />
      )}
      {selected?.mode === 'salary' && (
        <SetSalaryModal
          user={selected.user}
          onClose={() => setSelected(null)}
          onDone={() => { setSelected(null); load() }}
        />
      )}
    </div>
  )
}

// ── UserSalaryCard ────────────────────────────────────────────────────────────
function UserSalaryCard({ user, onPay, onHistory, onSetSalary }) {
  const salary = Number(user.monthly_salary)
  const paid   = Number(user.paid_this_month)
  const debt   = Number(user.debt)
  const pct    = salary > 0 ? Math.min(100, Math.round(paid / salary * 100)) : 0

  return (
    <div style={{
      background: '#1e293b', borderRadius: 12, padding: '14px 16px',
      border: debt > 0 ? '1px solid #ef444440' : '1px solid #334155',
      display: 'flex', alignItems: 'center', gap: 14, flexWrap: 'wrap',
    }}>
      {/* Avatar */}
      <div style={{
        width: 42, height: 42, borderRadius: 21,
        background: roleColor(user.role), display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        fontSize: 18, flexShrink: 0,
      }}>
        {roleIcon(user.role)}
      </div>

      {/* Info */}
      <div style={{ flex: 1, minWidth: 140 }}>
        <div style={{ fontWeight: 600, fontSize: 15 }}>{user.name}</div>
        <div style={{ fontSize: 12, color: '#94a3b8', marginTop: 2 }}>
          {ROLES[user.role] || user.role}
          {!user.is_active && <span style={{ color: '#ef4444', marginLeft: 6 }}>• Faol emas</span>}
        </div>
        {/* Progress bar */}
        {salary > 0 && (
          <div style={{ marginTop: 6 }}>
            <div style={{ background: '#334155', borderRadius: 4, height: 6, overflow: 'hidden' }}>
              <div style={{
                width: pct + '%', height: '100%', borderRadius: 4,
                background: pct >= 100 ? '#22c55e' : '#f97316',
                transition: 'width .3s',
              }} />
            </div>
            <div style={{ fontSize: 11, color: '#94a3b8', marginTop: 2 }}>{pct}% to'langan</div>
          </div>
        )}
      </div>

      {/* Raqamlar */}
      <div style={{ textAlign: 'right', minWidth: 130 }}>
        <div style={{ fontSize: 12, color: '#94a3b8' }}>Oylik maosh</div>
        <div style={{ fontWeight: 700, fontSize: 15 }}>{money(salary)}</div>
        <div style={{ fontSize: 12, color: '#22c55e', marginTop: 2 }}>To'langan: {money(paid)}</div>
        {debt > 0 && <div style={{ fontSize: 12, color: '#ef4444' }}>Qarz: {money(debt)}</div>}
      </div>

      {/* Tugmalar */}
      <div style={{ display: 'flex', gap: 6, flexShrink: 0 }}>
        <button onClick={onSetSalary} title="Maosh belgilash" style={iconBtn('#3b82f6')}>⚙️</button>
        <button onClick={onPay} title="To'lov berish" style={iconBtn('#22c55e')}>💵</button>
        <button onClick={onHistory} title="To'lov tarixi" style={iconBtn('#94a3b8')}>📋</button>
      </div>
    </div>
  )
}

// ── PayModal ──────────────────────────────────────────────────────────────────
function PayModal({ user, month, onClose, onDone }) {
  const [amount, setAmount] = useState(String(user.debt > 0 ? user.debt : user.monthly_salary))
  const [type, setType]     = useState('monthly')
  const [note, setNote]     = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError]   = useState('')

  async function submit(e) {
    e.preventDefault()
    if (!amount || Number(amount) < 1) { setError('Summa kiritilmagan'); return }
    setSaving(true); setError('')
    try {
      await salaryApi.pay({ user_id: user.id, amount: Number(amount), type, month, note })
      onDone()
    } catch (e) {
      setError(e.response?.data?.message || 'Xatolik yuz berdi')
      setSaving(false)
    }
  }

  return (
    <Modal onClose={onClose} title={`💵 Maosh to'lash — ${user.name}`}>
      <form onSubmit={submit}>
        <div style={{ color: '#94a3b8', fontSize: 13, marginBottom: 14 }}>
          Oy: <b style={{ color: '#f1f5f9' }}>{month}</b> &nbsp;|&nbsp;
          Oylik maosh: <b style={{ color: '#f97316' }}>{money(user.monthly_salary)}</b> &nbsp;|&nbsp;
          Qarz: <b style={{ color: user.debt > 0 ? '#ef4444' : '#22c55e' }}>{money(user.debt)}</b>
        </div>

        <label style={labelStyle}>To'lov turi</label>
        <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
          {Object.entries(TYPES).map(([k, v]) => (
            <button
              key={k} type="button"
              onClick={() => setType(k)}
              style={{
                flex: 1, padding: '8px 4px', borderRadius: 8, border: 'none',
                cursor: 'pointer', fontWeight: 600, fontSize: 13,
                background: type === k ? TYPE_COLORS[k] : '#263548',
                color: type === k ? '#fff' : '#94a3b8',
              }}
            >{v}</button>
          ))}
        </div>

        <label style={labelStyle}>Summa (so'm)</label>
        <input
          type="number" min="0" value={amount}
          onChange={e => setAmount(e.target.value)}
          style={{ ...inputStyle, width: '100%', marginBottom: 14 }}
          required
        />

        <label style={labelStyle}>Izoh (ixtiyoriy)</label>
        <input
          value={note} onChange={e => setNote(e.target.value)}
          placeholder="Masalan: Iyun oyi maoshi"
          style={{ ...inputStyle, width: '100%', marginBottom: 14 }}
        />

        {error && <div style={{ color: '#ef4444', fontSize: 13, marginBottom: 10 }}>{error}</div>}

        <div style={{ display: 'flex', gap: 8 }}>
          <button type="button" onClick={onClose} style={{ ...btnSecStyle, flex: 1 }}>Bekor</button>
          <button type="submit" disabled={saving} style={{ ...btnPrimStyle, flex: 1 }}>
            {saving ? 'Saqlanmoqda...' : '✅ Tasdiqlash'}
          </button>
        </div>
      </form>
    </Modal>
  )
}

// ── HistoryModal ──────────────────────────────────────────────────────────────
function HistoryModal({ user, month, onClose, onDeleted }) {
  const [payments, setPayments] = useState([])
  const [loading, setLoading]   = useState(true)

  useEffect(() => {
    salaryApi.getPayments(user.id, month)
      .then(r => setPayments(r.data.data || r.data))
      .catch(console.error)
      .finally(() => setLoading(false))
  }, [user.id, month])

  async function del(id) {
    if (!window.confirm('O\'chirishni tasdiqlaysizmi?')) return
    try {
      await salaryApi.deletePayment(id)
      setPayments(p => p.filter(x => x.id !== id))
      onDeleted()
    } catch (e) { alert('Xatolik') }
  }

  const total = payments.reduce((s, p) => s + Number(p.amount), 0)

  return (
    <Modal onClose={onClose} title={`📋 To'lov tarixi — ${user.name} (${month})`}>
      {loading ? (
        <div style={{ textAlign: 'center', padding: 20, color: '#94a3b8' }}>Yuklanmoqda...</div>
      ) : payments.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 20, color: '#94a3b8' }}>Bu oyda to'lov yo'q</div>
      ) : (
        <>
          <div style={{ display: 'grid', gap: 8, maxHeight: 340, overflowY: 'auto', marginBottom: 12 }}>
            {payments.map(p => (
              <div key={p.id} style={{
                background: '#263548', borderRadius: 8, padding: '10px 12px',
                display: 'flex', alignItems: 'center', gap: 10,
              }}>
                <span style={{ fontSize: 18 }}>{p.type === 'monthly' ? '💵' : p.type === 'advance' ? '🔵' : '🎁'}</span>
                <div style={{ flex: 1 }}>
                  <div style={{ fontWeight: 600 }}>{money(p.amount)}</div>
                  <div style={{ fontSize: 12, color: '#94a3b8' }}>
                    {TYPES[p.type]} • {p.paid_by_user?.name || '-'} • {new Date(p.created_at).toLocaleDateString('uz-UZ')}
                  </div>
                  {p.note && <div style={{ fontSize: 12, color: '#64748b', marginTop: 2 }}>{p.note}</div>}
                </div>
                <button onClick={() => del(p.id)} style={iconBtn('#ef4444')} title="O'chirish">🗑️</button>
              </div>
            ))}
          </div>
          <div style={{ borderTop: '1px solid #334155', paddingTop: 10, textAlign: 'right', fontWeight: 700 }}>
            Jami: {money(total)}
          </div>
        </>
      )}
    </Modal>
  )
}

// ── SetSalaryModal ─────────────────────────────────────────────────────────────
function SetSalaryModal({ user, onClose, onDone }) {
  const [amount, setAmount] = useState(String(user.monthly_salary))
  const [saving, setSaving] = useState(false)

  async function submit(e) {
    e.preventDefault()
    setSaving(true)
    try {
      await salaryApi.setSalary(user.id, Number(amount))
      onDone()
    } catch { setSaving(false) }
  }

  return (
    <Modal onClose={onClose} title={`⚙️ Oylik maosh — ${user.name}`}>
      <form onSubmit={submit}>
        <label style={labelStyle}>Oylik maosh (so'm)</label>
        <input
          type="number" min="0" value={amount}
          onChange={e => setAmount(e.target.value)}
          style={{ ...inputStyle, width: '100%', marginBottom: 16 }}
        />
        <div style={{ display: 'flex', gap: 8 }}>
          <button type="button" onClick={onClose} style={{ ...btnSecStyle, flex: 1 }}>Bekor</button>
          <button type="submit" disabled={saving} style={{ ...btnPrimStyle, flex: 1 }}>
            {saving ? 'Saqlanmoqda...' : '💾 Saqlash'}
          </button>
        </div>
      </form>
    </Modal>
  )
}

// ── StatCard ──────────────────────────────────────────────────────────────────
function StatCard({ label, value, color, icon }) {
  return (
    <div style={{
      background: '#1e293b', borderRadius: 12, padding: '14px 16px',
      borderLeft: `3px solid ${color}`,
    }}>
      <div style={{ fontSize: 22, marginBottom: 4 }}>{icon}</div>
      <div style={{ fontSize: 12, color: '#94a3b8' }}>{label}</div>
      <div style={{ fontWeight: 700, fontSize: 15, marginTop: 2 }}>{value}</div>
    </div>
  )
}

// ── Modal ─────────────────────────────────────────────────────────────────────
function Modal({ children, title, onClose }) {
  return (
    <div style={{
      position: 'fixed', inset: 0, background: '#000a',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      zIndex: 1000, padding: 16,
    }} onClick={e => e.target === e.currentTarget && onClose()}>
      <div style={{
        background: '#1e293b', borderRadius: 16, padding: 24,
        width: '100%', maxWidth: 480, maxHeight: '90vh', overflowY: 'auto',
        border: '1px solid #334155',
      }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 18, alignItems: 'center' }}>
          <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700 }}>{title}</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 20, color: '#94a3b8' }}>✕</button>
        </div>
        {children}
      </div>
    </div>
  )
}

// ── Helpers ───────────────────────────────────────────────────────────────────
function roleIcon(role) {
  const m = { admin: '👑', manager: '🏆', cashier: '💵', waiter: '🍽️', kitchen: '👨‍🍳' }
  return m[role] || '👤'
}
function roleColor(role) {
  const m = { admin: '#7c3aed', manager: '#2563eb', cashier: '#0891b2', waiter: '#d97706', kitchen: '#dc2626' }
  return m[role] || '#475569'
}

const inputStyle = {
  background: '#263548', border: '1px solid #334155', borderRadius: 8,
  color: '#f1f5f9', padding: '8px 12px', fontSize: 14, outline: 'none',
}
const labelStyle = { display: 'block', fontSize: 12, color: '#94a3b8', marginBottom: 6 }
const btnSecStyle = {
  background: '#263548', border: '1px solid #334155', borderRadius: 8,
  color: '#f1f5f9', padding: '8px 16px', cursor: 'pointer', fontSize: 13,
}
const btnPrimStyle = {
  background: '#f97316', border: 'none', borderRadius: 8,
  color: '#fff', padding: '8px 16px', cursor: 'pointer', fontSize: 13, fontWeight: 600,
}
function iconBtn(color) {
  return {
    background: color + '20', border: `1px solid ${color}40`,
    borderRadius: 8, padding: '6px 10px', cursor: 'pointer', fontSize: 15,
  }
}
