import { useNotifications } from '../contexts/NotificationsContext'

function ConnectionStatus() {
  const { isConnected, notifications } = useNotifications()

  return (
    <div className="fixed bottom-4 right-4 z-50 bg-white rounded-lg shadow-lg border p-3 flex items-center gap-3">
      <div className="flex items-center gap-2">
        <div
          className={`w-3 h-3 rounded-full ${
            isConnected ? 'bg-green-500 animate-pulse' : 'bg-red-500'
          }`}
        ></div>
        <span className="text-xs font-medium text-slate-700">
          {isConnected ? 'Conectado' : 'Desconectado'}
        </span>
      </div>
      {notifications.length > 0 && (
        <span className="text-xs text-slate-500">
          ({notifications.length} notificaciones)
        </span>
      )}
    </div>
  )
}

export default ConnectionStatus

