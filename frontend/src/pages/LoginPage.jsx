import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import toast from 'react-hot-toast'

const ROLES = {
  admin: 'Admin',
  manager: 'Menejer',
  cashier: 'Kassir',
  waiter: 'Ofitsiant',
}

export default function LoginPage() {
  const { loginByPin, loginByPassword } = useAuth()
  const navigate = useNavigate()

  const [mode, setMode] = useState('pin') // 'pin' | 'password'
  const [pin, setPin] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)

  const handlePinKey = (key) => {
    if (key === '←') return setPin(p => p.slice(0, -1))
    if (pin.length >= 6) return
    setPin(p => p + key)
  }

  const handlePinSubmit = async () => {
    if (pin.length < 4) return toast.error("PIN kamida 4 ta raqam")
    setLoading(true)
    try {
      const user = await loginByPin(pin)
      toast.success(`Xush kelibsiz, ${user.name}!`)
      navigate(getDefaultRoute(user.role))
    } catch {
      toast.error('PIN noto\'g\'ri')
      setPin('')
    } finally {
      setLoading(false)
    }
  }

  const handlePasswordSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      const user = await loginByPassword(email, password)
      toast.success(`Xush kelibsiz, ${user.name}!`)
      navigate(getDefaultRoute(user.role))
    } catch {
      toast.error('Email yoki parol noto\'g\'ri')
    } finally {
      setLoading(false)
    }
  }

  const getDefaultRoute = (role) => {
    if (role === 'admin' || role === 'manager') return '/admin'
    if (role === 'cashier') return '/cashier'
    return '/waiter'
  }

  const keys = ['1','2','3','4','5','6','7','8','9','←','0','✓']

  return (
    <div style={styles.container}>
      <div style={styles.card}>
        {/* Logo */}
        <div style={styles.logo}>🍽️</div>
        <h1 style={styles.title}>Kafe POS</h1>

        {/* Mode toggle */}
        <div style={styles.tabs}>
          <button style={mode === 'pin' ? styles.tabActive : styles.tab} onClick={() => setMode('pin')}>
            PIN
          </button>
          <button style={mode === 'password' ? styles.tabActive : styles.tab} onClick={() => setMode('password')}>
            Parol
          </button>
        </div>

        {mode === 'pin' ? (
          <>
            {/* PIN ko'rsatish */}
            <div style={styles.pinDisplay}>
              {Array.from({ length: 6 }).map((_, i) => (
                <span key={i} style={i < pin.length ? styles.pinDotFilled : styles.pinDot} />
              ))}
            </div>

            {/* Klaviatura */}
            <div style={styles.keypad}>
              {keys.map(key => (
                <button
                  key={key}
                  style={key === '✓' ? styles.keyConfirm : styles.key}
                  onClick={() => key === '✓' ? handlePinSubmit() : handlePinKey(key)}
                  disabled={loading}
                >
                  {key}
                </button>
              ))}
            </div>
          </>
        ) : (
          <form onSubmit={handlePasswordSubmit} style={styles.form}>
            <input
              type="email"
              placeholder="Email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              style={styles.input}
              required
            />
            <input
              type="password"
              placeholder="Parol"
              value={password}
              onChange={e => setPassword(e.target.value)}
              style={styles.input}
              required
            />
            <button type="submit" style={styles.submitBtn} disabled={loading}>
              {loading ? 'Kirilmoqda...' : 'Kirish'}
            </button>
          </form>
        )}
      </div>
    </div>
  )
}

const styles = {
  container: {
    minHeight: '100vh',
    background: '#1a1a2e',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
  },
  card: {
    background: '#16213e',
    borderRadius: 20,
    padding: 'clamp(20px, 5vw, 40px)',
    width: 'min(360px, calc(100vw - 32px))',
    textAlign: 'center',
    boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
  },
  logo: { fontSize: 48, marginBottom: 8 },
  title: { color: '#fff', fontSize: 24, fontWeight: 700, marginBottom: 24 },
  tabs: { display: 'flex', gap: 8, marginBottom: 24 },
  tab: {
    flex: 1, padding: '10px', background: '#0f3460', color: '#aaa',
    border: 'none', borderRadius: 10, cursor: 'pointer', fontSize: 14,
  },
  tabActive: {
    flex: 1, padding: '10px', background: '#e94560', color: '#fff',
    border: 'none', borderRadius: 10, cursor: 'pointer', fontSize: 14, fontWeight: 700,
  },
  pinDisplay: {
    display: 'flex', gap: 12, justifyContent: 'center', marginBottom: 24,
  },
  pinDot: {
    width: 16, height: 16, borderRadius: '50%',
    background: '#0f3460', border: '2px solid #aaa',
  },
  pinDotFilled: {
    width: 16, height: 16, borderRadius: '50%',
    background: '#e94560', border: '2px solid #e94560',
  },
  keypad: {
    display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10,
  },
  key: {
    padding: 'clamp(12px, 3vw, 18px)', background: '#0f3460', color: '#fff', border: 'none',
    borderRadius: 12, fontSize: 'clamp(16px, 4vw, 20px)', cursor: 'pointer', fontWeight: 600,
    transition: 'background 0.1s',
  },
  keyConfirm: {
    padding: 'clamp(12px, 3vw, 18px)', background: '#e94560', color: '#fff', border: 'none',
    borderRadius: 12, fontSize: 'clamp(16px, 4vw, 20px)', cursor: 'pointer', fontWeight: 600,
  },
  form: { display: 'flex', flexDirection: 'column', gap: 14 },
  input: {
    padding: '14px', background: '#0f3460', border: 'none', borderRadius: 10,
    color: '#fff', fontSize: 16, outline: 'none',
  },
  submitBtn: {
    padding: '14px', background: '#e94560', color: '#fff', border: 'none',
    borderRadius: 10, fontSize: 16, cursor: 'pointer', fontWeight: 700,
  },
}
