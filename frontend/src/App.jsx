import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import { AuthProvider, useAuth } from './context/AuthContext'
import LoginPage from './pages/LoginPage'

// Lazy load — keyinchalik to'ldiramiz
import { lazy, Suspense } from 'react'
const WaiterLayout   = lazy(() => import('./pages/waiter/WaiterLayout'))
const CashierLayout  = lazy(() => import('./pages/cashier/CashierLayout'))
const AdminLayout    = lazy(() => import('./pages/admin/AdminLayout'))
const KitchenLayout  = lazy(() => import('./pages/kitchen/KitchenLayout'))

function ProtectedRoute({ children, roles }) {
  const { user, loading } = useAuth()
  if (loading) return <div style={loadingStyle}>Yuklanmoqda...</div>
  if (!user) return <Navigate to="/login" replace />
  if (roles && !roles.includes(user.role)) return <Navigate to="/" replace />
  return children
}

function RootRedirect() {
  const { user, loading } = useAuth()
  if (loading) return <div style={loadingStyle}>Yuklanmoqda...</div>
  if (!user) return <Navigate to="/login" replace />
  if (user.role === 'admin' || user.role === 'manager') return <Navigate to="/admin" replace />
  if (user.role === 'cashier') return <Navigate to="/cashier" replace />
  if (user.role === 'kitchen') return <Navigate to="/kitchen" replace />
  return <Navigate to="/waiter" replace />
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Toaster position="top-center" toastOptions={{ duration: 3000 }} />
        <Suspense fallback={<div style={loadingStyle}>Yuklanmoqda...</div>}>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/" element={<RootRedirect />} />

            <Route path="/waiter/*" element={
              <ProtectedRoute roles={['waiter', 'cashier', 'manager', 'admin']}>
                <WaiterLayout />
              </ProtectedRoute>
            } />

            <Route path="/cashier/*" element={
              <ProtectedRoute roles={['cashier', 'manager', 'admin']}>
                <CashierLayout />
              </ProtectedRoute>
            } />

            <Route path="/admin/*" element={
              <ProtectedRoute roles={['manager', 'admin']}>
                <AdminLayout />
              </ProtectedRoute>
            } />

            <Route path="/kitchen/*" element={
              <ProtectedRoute roles={['kitchen', 'manager', 'admin']}>
                <KitchenLayout />
              </ProtectedRoute>
            } />
          </Routes>
        </Suspense>
      </BrowserRouter>
    </AuthProvider>
  )
}

const loadingStyle = {
  minHeight: '100vh', display: 'flex', alignItems: 'center',
  justifyContent: 'center', background: '#1a1a2e', color: '#fff', fontSize: 18,
}
