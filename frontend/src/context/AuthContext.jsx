import { createContext, useContext, useState, useEffect } from 'react'
import api from '../services/api'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const token = localStorage.getItem('pos_token')
    if (token) {
      api.get('/auth/me')
        .then(res => setUser(res.data))
        .catch(() => localStorage.removeItem('pos_token'))
        .finally(() => setLoading(false))
    } else {
      setLoading(false)
    }
  }, [])

  const loginByPin = async (pin) => {
    const res = await api.post('/auth/pin', { pin })
    localStorage.setItem('pos_token', res.data.token)
    setUser(res.data.user)
    return res.data.user
  }

  const loginByPassword = async (email, password) => {
    const res = await api.post('/auth/login', { email, password })
    localStorage.setItem('pos_token', res.data.token)
    setUser(res.data.user)
    return res.data.user
  }

  const logout = async () => {
    try { await api.post('/auth/logout') } catch {}
    localStorage.removeItem('pos_token')
    setUser(null)
  }

  const isManager = () => ['admin', 'manager'].includes(user?.role)
  const isAdmin   = () => user?.role === 'admin'

  return (
    <AuthContext.Provider value={{ user, loading, loginByPin, loginByPassword, logout, isManager, isAdmin }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
