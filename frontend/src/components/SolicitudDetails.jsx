import { useState, useEffect } from 'react'
import { useNotifications } from '../contexts/NotificationsContext'

function SolicitudDetails({ solicitudId, country, token, onBack, user }) {
  const [solicitud, setSolicitud] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')
  const [statusUpdated, setStatusUpdated] = useState(false)
  const [isUpdatingStatus, setIsUpdatingStatus] = useState(false)
  const [updateStatusError, setUpdateStatusError] = useState('')
  const [updateStatusSuccess, setUpdateStatusSuccess] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState('')
  const { notifications } = useNotifications()

  const isAdmin = user?.role === 'admin'

  // Opciones de status disponibles
  const statusOptions = [
    { value: 'pending', label: 'Pendiente' },
    { value: 'preapproved', label: 'Preaprobado' },
    { value: 'manual_required', label: 'Revisión Manual Requerida' },
    { value: 'in_review', label: 'En Revisión' },
    { value: 'approved', label: 'Aprobado' },
    { value: 'rejected', label: 'Rechazado' },
  ]

  useEffect(() => {
    const fetchSolicitud = async () => {
      setIsLoading(true)
      setError('')

      try {
        const url = new URL(`http://localhost:3000/api/v1/credit_applications/${solicitudId}`)
        url.searchParams.append('country', country)

        const response = await fetch(url.toString(), {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        })

        const data = await response.json()

        if (response.ok) {
          // Los datos vienen dentro de credit_application
          setSolicitud(data.credit_application || data)
        } else {
          setError(data.message || 'Error al cargar los detalles de la solicitud')
        }
      } catch (error) {
        setError('Error de conexión. Verifica que la API esté corriendo.')
        console.error('Error:', error)
      } finally {
        setIsLoading(false)
      }
    }

    if (solicitudId && country && token) {
      fetchSolicitud()
    }
  }, [solicitudId, country, token])

  const getSolicitudId = (id) => {
    if (Array.isArray(id)) {
      return id[0]
    }
    return id
  }

  // Función para comparar IDs (pueden venir como array [id, country] o como número/string)
  const compareIds = (notificationId, currentId) => {
    // Normalizar el ID de la notificación
    let normalizedNotificationId
    if (Array.isArray(notificationId)) {
      normalizedNotificationId = notificationId[0]
    } else {
      normalizedNotificationId = notificationId
    }

    // Normalizar el ID actual (que ya viene normalizado desde SolicitudesList)
    const normalizedCurrentId = Array.isArray(currentId) ? currentId[0] : currentId

    // Comparar como strings para manejar números y strings
    return String(normalizedNotificationId) === String(normalizedCurrentId)
  }

  // Escuchar notificaciones y actualizar el estado cuando cambie el status
  useEffect(() => {
    if (!notifications || notifications.length === 0 || !solicitud) return

    // Buscar la notificación más reciente relacionada con esta solicitud
    const relevantNotification = notifications.find((notif) => {
      if (!notif.credit_application_id) return false
      return compareIds(notif.credit_application_id, solicitudId)
    })

    if (relevantNotification && relevantNotification.status) {
      // Actualizar el estado de la solicitud con el nuevo status
      setSolicitud((prev) => {
        if (!prev) return prev
        // Solo actualizar si el status realmente cambió
        if (prev.status !== relevantNotification.status) {
          // Mostrar indicador visual de actualización
          setStatusUpdated(true)
          setTimeout(() => setStatusUpdated(false), 3000) // Ocultar después de 3 segundos

          return {
            ...prev,
            status: relevantNotification.status,
            updated_at: new Date().toISOString(), // Actualizar timestamp
          }
        }
        return prev
      })
    }
  }, [notifications, solicitudId, solicitud])

  // Función para actualizar el status de la solicitud
  const handleStatusChange = async (newStatus) => {
    if (!solicitud || !solicitudId || !country || !token) return
    if (solicitud.status === newStatus) return // No hacer nada si el status es el mismo

    setIsUpdatingStatus(true)
    setUpdateStatusError('')
    setUpdateStatusSuccess(false)

    try {
      const url = new URL(`http://localhost:3000/api/v1/credit_applications/${getSolicitudId(solicitudId)}`)
      url.searchParams.append('country', country)

      const response = await fetch(url.toString(), {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          status: newStatus,
        }),
      })

      const data = await response.json()

      if (response.ok) {
        // Actualizar el estado local con la respuesta de la API
        if (data.credit_application) {
          setSolicitud((prev) => ({
            ...prev,
            ...data.credit_application,
            updated_at: new Date().toISOString(),
          }))
        } else {
          // Si no viene credit_application, actualizar solo el status
          setSolicitud((prev) => ({
            ...prev,
            status: newStatus,
            updated_at: new Date().toISOString(),
          }))
        }

        setUpdateStatusSuccess(true)
        setTimeout(() => setUpdateStatusSuccess(false), 3000)

        // Mostrar indicador visual de actualización
        setStatusUpdated(true)
        setTimeout(() => setStatusUpdated(false), 3000)
      } else if (response.status === 404) {
        setUpdateStatusError(data.message || 'Solicitud no encontrada')
      } else if (response.status === 422) {
        const errorMessage = data.errors
          ? Array.isArray(data.errors) ? data.errors.join(', ') : data.errors
          : data.message || 'Error al actualizar el status'
        setUpdateStatusError(errorMessage)
      } else {
        setUpdateStatusError(data.message || 'Error al actualizar el status')
      }
    } catch (error) {
      console.error('Error al actualizar status:', error)
      setUpdateStatusError('Error de conexión. Verifica que la API esté corriendo.')
    } finally {
      setIsUpdatingStatus(false)
    }
  }

  // Función para borrar la solicitud
  const handleDelete = async () => {
    if (!isAdmin) return
    if (!window.confirm('¿Estás seguro de que quieres borrar esta solicitud? Esta acción no se puede deshacer.')) {
      return
    }

    setIsDeleting(true)
    setDeleteError('')

    try {
      const url = new URL(`http://localhost:3000/api/v1/credit_applications/${getSolicitudId(solicitudId)}`)
      url.searchParams.append('country', country)

      const response = await fetch(url.toString(), {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })

      if (response.ok) {
        alert('Solicitud borrada exitosamente')
        onBack() // Volver a la lista
      } else {
        const data = await response.json()
        setDeleteError(data.message || 'Error al borrar la solicitud')
      }
    } catch (error) {
      console.error('Error al borrar solicitud:', error)
      setDeleteError('Error de conexión. Verifica que la API esté corriendo.')
    } finally {
      setIsDeleting(false)
    }
  }

  if (isLoading) {
    return (
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <div className="text-center py-8">
          <p className="text-slate-500">Cargando detalles de la solicitud...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <div className="mb-4 p-4 bg-red-50 border-l-4 border-red-500 rounded-lg">
          <p className="text-red-700 text-sm font-medium">{error}</p>
        </div>
        <button
          onClick={onBack}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 transition-colors"
        >
          ← Volver a la lista
        </button>
      </div>
    )
  }

  if (!solicitud) {
    return (
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <p className="text-slate-500 mb-4">No se encontraron detalles de la solicitud.</p>
        <button
          onClick={onBack}
          className="px-4 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 transition-colors"
        >
          ← Volver a la lista
        </button>
      </div>
    )
  }

  // Convertir requested_amount de string a número si es necesario
  const requestedAmount = solicitud.requested_amount
    ? parseFloat(solicitud.requested_amount)
    : null

  return (
    <div className="bg-white rounded-2xl shadow-xl p-8">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-3xl font-bold text-blue-900">Detalles de la Solicitud</h2>
        <div className="flex gap-3">
          <button
            onClick={handleDelete}
            disabled={!isAdmin || isDeleting}
            className={`px-4 py-2 rounded-lg font-medium transition-all ${
              isAdmin
                ? 'bg-red-500 text-white hover:bg-red-600 shadow-md'
                : 'bg-slate-200 text-slate-400 cursor-not-allowed border border-slate-300'
            } ${isDeleting ? 'opacity-50' : ''}`}
            title={!isAdmin ? 'Solo administradores pueden borrar solicitudes' : ''}
          >
            {isDeleting ? 'Borrando...' : 'Borrar Solicitud'}
          </button>
          <button
            onClick={onBack}
            className="px-4 py-2 bg-blue-500 text-white rounded-lg font-medium hover:bg-blue-600 transition-colors"
          >
            ← Volver a la lista
          </button>
        </div>
      </div>

      {deleteError && (
        <div className="mb-6 p-4 bg-red-50 border-l-4 border-red-500 rounded-lg">
          <p className="text-red-700 text-sm font-medium">{deleteError}</p>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Información básica */}
        <div className="space-y-4">
          <div className="p-4 bg-slate-50 rounded-lg">
            <label className="text-xs font-semibold text-slate-500 uppercase">ID</label>
            <p className="text-lg font-semibold text-slate-900 mt-1">
              {getSolicitudId(solicitud.id) || 'N/A'}
            </p>
          </div>

          <div className="p-4 bg-slate-50 rounded-lg">
            <label className="text-xs font-semibold text-slate-500 uppercase">Nombre Completo</label>
            <p className="text-lg font-semibold text-slate-900 mt-1">
              {solicitud.full_name || 'N/A'}
            </p>
          </div>

          <div className="p-4 bg-slate-50 rounded-lg">
            <label className="text-xs font-semibold text-slate-500 uppercase">País</label>
            <p className="text-lg font-semibold text-slate-900 mt-1">
              {solicitud.country ? solicitud.country.charAt(0).toUpperCase() + solicitud.country.slice(1) : 'N/A'}
            </p>
          </div>

          <div className="p-4 bg-slate-50 rounded-lg">
            <label className="text-xs font-semibold text-slate-500 uppercase">Monto Solicitado</label>
            <p className="text-lg font-semibold text-slate-900 mt-1">
              ${requestedAmount ? requestedAmount.toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00'}
            </p>
          </div>

          {solicitud.monthly_income && (
            <div className="p-4 bg-slate-50 rounded-lg">
              <label className="text-xs font-semibold text-slate-500 uppercase">Ingreso Mensual</label>
              <p className="text-lg font-semibold text-slate-900 mt-1">
                ${parseFloat(solicitud.monthly_income).toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </p>
            </div>
          )}
        </div>

        {/* Información adicional */}
        <div className="space-y-4">
          <div className="p-4 bg-slate-50 rounded-lg relative">
            <label className="text-xs font-semibold text-slate-500 uppercase mb-2 block">Estado</label>
            <div className="mt-1 flex items-center gap-2 flex-wrap">
              <select
                value={solicitud.status || ''}
                onChange={(e) => handleStatusChange(e.target.value)}
                disabled={isUpdatingStatus}
                className={`px-3 py-2 text-sm font-semibold rounded-lg border-2 transition-all focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                  statusUpdated ? 'animate-pulse ring-2 ring-blue-400' : ''
                } ${
                  isUpdatingStatus
                    ? 'bg-slate-200 text-slate-500 cursor-not-allowed border-slate-300'
                    : 'bg-white text-slate-900 border-blue-300 hover:border-blue-400 cursor-pointer'
                }`}
              >
                {statusOptions.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
              {isUpdatingStatus && (
                <span className="text-xs text-slate-500 font-medium">
                  Actualizando...
                </span>
              )}
              {statusUpdated && !isUpdatingStatus && (
                <span className="text-xs text-green-600 font-medium animate-fade-in">
                  ✓ Actualizado
                </span>
              )}
            </div>
            {updateStatusError && (
              <div className="mt-2 p-2 bg-red-50 border-l-4 border-red-500 rounded text-xs text-red-700">
                {updateStatusError}
              </div>
            )}
            {updateStatusSuccess && (
              <div className="mt-2 p-2 bg-green-50 border-l-4 border-green-500 rounded text-xs text-green-700">
                Status actualizado exitosamente
              </div>
            )}
          </div>

          <div className="p-4 bg-slate-50 rounded-lg">
            <label className="text-xs font-semibold text-slate-500 uppercase">Fecha de Solicitud</label>
            <p className="text-lg font-semibold text-slate-900 mt-1">
              {solicitud.application_date
                ? new Date(solicitud.application_date).toLocaleDateString('es-MX', {
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })
                : 'N/A'}
            </p>
          </div>

          {solicitud.created_at && (
            <div className="p-4 bg-slate-50 rounded-lg">
              <label className="text-xs font-semibold text-slate-500 uppercase">Fecha de Creación</label>
              <p className="text-lg font-semibold text-slate-900 mt-1">
                {new Date(solicitud.created_at).toLocaleDateString('es-MX', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                })}
              </p>
            </div>
          )}

          {solicitud.updated_at && (
            <div className="p-4 bg-slate-50 rounded-lg">
              <label className="text-xs font-semibold text-slate-500 uppercase">Última Actualización</label>
              <p className="text-lg font-semibold text-slate-900 mt-1">
                {new Date(solicitud.updated_at).toLocaleDateString('es-MX', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                  hour: '2-digit',
                  minute: '2-digit'
                })}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Resultados de validación */}
      {solicitud.validation_result && solicitud.validation_result.length > 0 && (
        <div className="mt-6 p-4 bg-slate-50 rounded-lg">
          <label className="text-xs font-semibold text-slate-500 uppercase block mb-3">
            Resultados de Validación
          </label>
          <div className="space-y-2">
            {solicitud.validation_result.map((validation, index) => (
              <div key={index} className="flex items-center justify-between p-2 bg-white rounded">
                <span className="text-sm text-slate-700">
                  {validation.name.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                </span>
                <span className={`px-2 py-1 text-xs font-semibold rounded ${
                  validation.result
                    ? 'bg-green-100 text-green-800'
                    : 'bg-red-100 text-red-800'
                }`}>
                  {validation.result ? '✓ Aprobado' : '✗ Rechazado'}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Datos bancarios */}
      {solicitud.banking_data && (
        <div className="mt-6 p-4 bg-blue-50 rounded-lg border-l-4 border-blue-500">
          <label className="text-xs font-semibold text-slate-500 uppercase block mb-3">
            Datos Bancarios
          </label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            {solicitud.banking_data.customer_id && (
              <div>
                <span className="text-slate-600">ID de Cliente:</span>
                <span className="ml-2 font-semibold text-slate-900">{solicitud.banking_data.customer_id}</span>
              </div>
            )}
            {solicitud.banking_data.monthly_data && (
              <>
                <div>
                  <span className="text-slate-600">Ingreso Mensual:</span>
                  <span className="ml-2 font-semibold text-slate-900">
                    ${solicitud.banking_data.monthly_data.income.toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                  </span>
                </div>
                <div>
                  <span className="text-slate-600">Gasto Promedio:</span>
                  <span className="ml-2 font-semibold text-slate-900">
                    ${solicitud.banking_data.monthly_data.average_expense.toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                  </span>
                </div>
                <div>
                  <span className="text-slate-600">Tasa de Ahorro:</span>
                  <span className="ml-2 font-semibold text-slate-900">
                    {(solicitud.banking_data.monthly_data.savings_rate * 100).toFixed(1)}%
                  </span>
                </div>
              </>
            )}
            {solicitud.banking_data.contact && (
              <>
                {solicitud.banking_data.contact.email && (
                  <div>
                    <span className="text-slate-600">Email:</span>
                    <span className="ml-2 font-semibold text-slate-900">{solicitud.banking_data.contact.email}</span>
                  </div>
                )}
                {solicitud.banking_data.contact.phone && (
                  <div>
                    <span className="text-slate-600">Teléfono:</span>
                    <span className="ml-2 font-semibold text-slate-900">{solicitud.banking_data.contact.phone}</span>
                  </div>
                )}
              </>
            )}
            {solicitud.banking_data.account_status && (
              <div>
                <span className="text-slate-600">Estado de Cuenta:</span>
                <span className={`ml-2 px-2 py-1 text-xs font-semibold rounded ${
                  solicitud.banking_data.account_status === 'verified'
                    ? 'bg-green-100 text-green-800'
                    : 'bg-yellow-100 text-yellow-800'
                }`}>
                  {solicitud.banking_data.account_status}
                </span>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

export default SolicitudDetails

