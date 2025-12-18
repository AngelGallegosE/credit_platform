import { createContext, useContext, useState, useEffect, useRef } from 'react'
import { createActionCableConnection, disconnectActionCable, updateCallbacks } from '../utils/actionCableConnection'

const NotificationsContext = createContext()

export const useNotifications = () => {
  const context = useContext(NotificationsContext)
  if (!context) {
    throw new Error('useNotifications must be used within a NotificationsProvider')
  }
  return context
}

export const NotificationsProvider = ({ children, token }) => {
  const [notifications, setNotifications] = useState([])
  const [isConnected, setIsConnected] = useState(false)

  useEffect(() => {
    if (!token) {
      setIsConnected(false)
      return
    }

    // Crear o reutilizar conexión usando el singleton
    const { consumer, subscription } = createActionCableConnection(token, {
      onConnected: (consumerRef, subscriptionRef) => {
        setIsConnected(true)
        if (typeof window !== 'undefined') {
          window.actionCableSubscription = subscriptionRef || subscription
          window.actionCableConsumer = consumerRef || consumer
        }
      },
      onDisconnected: () => {
        setIsConnected(false)
      },
      onRejected: () => {
        setIsConnected(false)
      },
      onReceived: (data) => {
        if (!data) return

        const newNotification = {
          id: Date.now() + Math.random(),
          type: data.type || 'unknown',
          credit_application_id: data.credit_application_id,
          status: data.status || 'unknown',
          message: data.message || 'Sin mensaje',
          timestamp: new Date(),
          rawData: data,
        }

        setNotifications((prev) => [newNotification, ...prev])
      },
    })

    // Actualizar callbacks si el componente se re-renderiza
    updateCallbacks({
      onReceived: (data) => {
        if (!data) return
        const newNotification = {
          id: Date.now() + Math.random(),
          type: data.type || 'unknown',
          credit_application_id: data.credit_application_id,
          status: data.status || 'unknown',
          message: data.message || 'Sin mensaje',
          timestamp: new Date(),
          rawData: data,
        }
        setNotifications((prev) => [newNotification, ...prev])
      },
    })
  }, [token])

  const removeNotification = (id) => {
    setNotifications((prev) => prev.filter((notif) => notif.id !== id))
  }

  const clearAllNotifications = () => {
    setNotifications([])
  }

  const value = {
    notifications,
    isConnected,
    removeNotification,
    clearAllNotifications,
  }

  return (
    <NotificationsContext.Provider value={value}>
      {children}
    </NotificationsContext.Provider>
  )
}

