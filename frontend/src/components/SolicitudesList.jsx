import { useState, useEffect } from 'react'

import SolicitudDetails from './SolicitudDetails'

function SolicitudesList({ token, user }) {
  const [country, setCountry] = useState('mexico')
  const [status, setStatus] = useState('pending')
  const [page, setPage] = useState(1)
  const [solicitudes, setSolicitudes] = useState([])
  const [pagination, setPagination] = useState(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [selectedSolicitudId, setSelectedSolicitudId] = useState(null)

  const fetchSolicitudes = async (currentPage = page) => {
    setIsLoading(true)
    setError('')

    try {
      const url = new URL('http://localhost:3000/api/v1/credit_applications')
      url.searchParams.append('country', country)
      url.searchParams.append('status', status)
      url.searchParams.append('page', currentPage.toString())

      const response = await fetch(url.toString(), {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
      })

      const data = await response.json()

      if (response.ok) {
        setSolicitudes(data.data || [])
        setPagination(data.pagination || null)
      } else {
        setError(data.message || 'Error al cargar las solicitudes')
        setSolicitudes([])
        setPagination(null)
      }
    } catch (error) {
      setError('Error de conexión. Verifica que la API esté corriendo.')
      console.error('Error:', error)
      setSolicitudes([])
    } finally {
      setIsLoading(false)
    }
  }

  // Cargar solicitudes cuando cambian los filtros (resetea a página 1)
  useEffect(() => {
    if (token) {
      setPage(1)
      fetchSolicitudes(1)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [country, status, token])

  // Cargar solicitudes cuando cambia la página
  useEffect(() => {
    if (token && page > 0) {
      fetchSolicitudes(page)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [page])

  const handleNextPage = () => {
    if (pagination && page < pagination.total_pages) {
      setPage((prev) => prev + 1)
    }
  }

  const handlePrevPage = () => {
    if (page > 1) {
      setPage((prev) => prev - 1)
    }
  }

  // Helper para obtener el ID (puede ser un array o un número)
  const getSolicitudId = (id) => {
    if (Array.isArray(id)) {
      return id[0]
    }
    return id
  }

  const handleSolicitudClick = (solicitud) => {
    const id = getSolicitudId(solicitud.id)
    setSelectedSolicitudId(id)
  }

  const handleBackToList = () => {
    setSelectedSolicitudId(null)
  }

  // Si hay una solicitud seleccionada, mostrar los detalles
  if (selectedSolicitudId) {
    return (
      <SolicitudDetails
        solicitudId={selectedSolicitudId}
        country={country}
        token={token}
        onBack={handleBackToList}
        user={user}
      />
    )
  }

  return (
    <div className="bg-white rounded-2xl shadow-xl p-8">
      <h2 className="text-3xl font-bold text-blue-900 mb-6">Lista de Solicitudes</h2>

      {/* Filtros */}
      <div className="mb-6 space-y-4">
        {/* País - Radio buttons */}
        <div>
          <label className="block text-sm font-medium text-slate-700 mb-2">
            País <span className="text-red-500">*</span>
          </label>
          <div className="flex gap-6">
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="country"
                value="mexico"
                checked={country === 'mexico'}
                onChange={(e) => setCountry(e.target.value)}
                required
                className="w-4 h-4 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-slate-700">México</span>
            </label>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="radio"
                name="country"
                value="portugal"
                checked={country === 'portugal'}
                onChange={(e) => setCountry(e.target.value)}
                required
                className="w-4 h-4 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-slate-700">Portugal</span>
            </label>
          </div>
        </div>

        {/* Status - Select */}
        <div>
          <label htmlFor="status" className="block text-sm font-medium text-slate-700 mb-2">
            Estado
          </label>
          <select
            id="status"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className="w-full md:w-auto px-4 py-2 border-2 border-slate-200 rounded-lg text-base focus:outline-none focus:border-blue-500"
          >
            <option value="pending">Pending</option>
            <option value="preapproved">Preapproved</option>
            <option value="manual_required">Manual Required</option>
            <option value="country_validated">Country Validated</option>
            <option value="country_invalidated">Country Invalidated</option>
          </select>
        </div>
      </div>

      {/* Mensaje de error */}
      {error && (
        <div className="mb-4 p-4 bg-red-50 border-l-4 border-red-500 rounded-lg">
          <p className="text-red-700 text-sm font-medium">{error}</p>
        </div>
      )}

      {/* Lista de solicitudes */}
      {isLoading ? (
        <div className="text-center py-8">
          <p className="text-slate-500">Cargando solicitudes...</p>
        </div>
      ) : solicitudes.length > 0 ? (
        <div className="space-y-4">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-slate-200">
              <thead className="bg-slate-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    ID
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Nombre Completo
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    País
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Monto Solicitado
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Estado
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Fecha de Solicitud
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 uppercase tracking-wider">
                    Documento
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-slate-200">
                {solicitudes.map((solicitud, index) => (
                  <tr
                    key={getSolicitudId(solicitud.id) || index}
                    onClick={() => handleSolicitudClick(solicitud)}
                    className="hover:bg-slate-50 cursor-pointer transition-colors"
                  >
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                      {getSolicitudId(solicitud.id) || 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900 font-medium">
                      {solicitud.full_name || 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                      {solicitud.country ? solicitud.country.charAt(0).toUpperCase() + solicitud.country.slice(1) : 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-900">
                      ${solicitud.requested_amount ? solicitud.requested_amount.toLocaleString('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '0.00'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                      <span className="px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800">
                        {solicitud.status || 'N/A'}
                      </span>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                      {solicitud.application_date
                        ? new Date(solicitud.application_date).toLocaleDateString('es-MX')
                        : 'N/A'}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-slate-500">
                      {solicitud.identity_document_url ? (
                        <a
                          href={solicitud.identity_document_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          onClick={(e) => e.stopPropagation()}
                          className="text-blue-600 hover:text-blue-800 underline"
                        >
                          Ver documento
                        </a>
                      ) : (
                        'N/A'
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Paginación */}
          {pagination && (
            <div className="flex justify-between items-center mt-6 pt-4 border-t border-slate-200">
              <button
                onClick={handlePrevPage}
                disabled={page === 1}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed hover:bg-blue-600"
              >
                ← Atrás
              </button>
              <div className="flex flex-col items-center gap-1">
                <span className="text-sm text-slate-600">
                  Página {pagination.page} de {pagination.total_pages}
                </span>
                <span className="text-xs text-slate-500">
                  Total: {pagination.total_count} solicitudes
                </span>
              </div>
              <button
                onClick={handleNextPage}
                disabled={page >= pagination.total_pages}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed hover:bg-blue-600"
              >
                Siguiente →
              </button>
            </div>
          )}
        </div>
      ) : (
        <div className="text-center py-8">
          <p className="text-slate-500">No se encontraron solicitudes con los filtros seleccionados.</p>
        </div>
      )}
    </div>
  )
}

export default SolicitudesList

