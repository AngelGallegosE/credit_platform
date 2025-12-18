import { useState, useEffect } from 'react'
import Dashboard from './components/Dashboard'
import Login from './components/Login'
import NotificationToast from './components/NotificationToast'
import ConnectionStatus from './components/ConnectionStatus'
import { NotificationsProvider } from './contexts/NotificationsContext'

function App() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [errorMessage, setErrorMessage] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [user, setUser] = useState(null)
  const [token, setToken] = useState(null)
  const [currentView, setCurrentView] = useState('crear') // 'crear' o 'lista'

  // Cargar token del localStorage al iniciar
  useEffect(() => {
    const savedToken = localStorage.getItem('token')
    const savedUser = localStorage.getItem('user')
    if (savedToken && savedUser) {
      setToken(savedToken)
      setUser(JSON.parse(savedUser))
      setIsAuthenticated(true)
    }
  }, [])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setErrorMessage('')
    setIsLoading(true)

    try {
      const response = await fetch('http://localhost:3000/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          user: {
            email: email,
            password: password,
          },
        }),
      })

      const data = await response.json()

      if (response.status === 200) {
        setToken(data.token)
        setUser(data.user)
        setIsAuthenticated(true)
        // Guardar token en localStorage
        localStorage.setItem('token', data.token)
        localStorage.setItem('user', JSON.stringify(data.user))
      } else if (response.status === 401) {
        setErrorMessage(data.message || 'Credenciales inválidas')
      } else {
        setErrorMessage('Ocurrió un error. Por favor intenta de nuevo.')
      }
    } catch (error) {
      setErrorMessage('Error de conexión. Verifica que la API esté corriendo.')
      console.error('Error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleLogout = () => {
    setIsAuthenticated(false)
    setUser(null)
    setToken(null)
    setEmail('')
    setPassword('')
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  // Si está autenticado, mostrar el dashboard con notificaciones
  if (isAuthenticated) {
    return (
      <NotificationsProvider token={token}>
        <NotificationToast />
        <ConnectionStatus />
        <Dashboard
          user={user}
          currentView={currentView}
          setCurrentView={setCurrentView}
          onLogout={handleLogout}
          token={token}
        />
      </NotificationsProvider>
    )
  }

  // Vista de login
  return (
    <Login
      email={email}
      password={password}
      errorMessage={errorMessage}
      isLoading={isLoading}
      onEmailChange={(e) => setEmail(e.target.value)}
      onPasswordChange={(e) => setPassword(e.target.value)}
      onSubmit={handleSubmit}
    />
  )
}

export default App
