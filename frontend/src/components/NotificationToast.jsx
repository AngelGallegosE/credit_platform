import { useNotifications } from '../contexts/NotificationsContext'
import { useEffect, useState } from 'react'

function NotificationToast() {
  const { notifications, removeNotification } = useNotifications()
  const [visibleNotifications, setVisibleNotifications] = useState([])

  useEffect(() => {
    // Mostrar solo las últimas 5 notificaciones
    const visible = notifications.slice(0, 5)
    setVisibleNotifications(visible)
  }, [notifications])

  useEffect(() => {
    // Auto-eliminar notificaciones después de 5 segundos
    const timers = visibleNotifications.map((notif) => {
      return setTimeout(() => {
        removeNotification(notif.id)
      }, 5000)
    })

    return () => {
      timers.forEach((timer) => clearTimeout(timer))
    }
  }, [visibleNotifications, removeNotification])

  if (visibleNotifications.length === 0) {
    return null
  }

  return (
    <div className="fixed top-4 right-4 z-50 space-y-2 max-w-md">
      {visibleNotifications.map((notif) => (
        <div
          key={notif.id}
          className="bg-white rounded-lg shadow-lg border-l-4 border-blue-500 p-4 animate-slide-in-right"
        >
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <div className="flex items-center gap-2 mb-1">
                <div className="w-2 h-2 bg-blue-500 rounded-full animate-pulse"></div>
                <h4 className="text-sm font-semibold text-slate-900">
                  Actualización de Solicitud
                </h4>
              </div>
              <p className="text-sm text-slate-600 mb-1">
                {notif.message || `Solicitud #${notif.credit_application_id} cambió a: ${notif.status}`}
              </p>
              {notif.credit_application_id && (
                <p className="text-xs text-slate-500">
                  ID: {Array.isArray(notif.credit_application_id)
                    ? notif.credit_application_id[0]
                    : notif.credit_application_id}
                </p>
              )}
            </div>
            <button
              onClick={() => removeNotification(notif.id)}
              className="ml-4 text-slate-400 hover:text-slate-600 transition-colors"
              aria-label="Cerrar notificación"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path d="M6 18L18 6M6 6l12 12"></path>
              </svg>
            </button>
          </div>
        </div>
      ))}
    </div>
  )
}

export default NotificationToast

