import { useState } from 'react'

function CreateSolicitud({ token }) {
  const [formData, setFormData] = useState({
    country: 'mexico',
    full_name: '',
    requested_amount: '',
    status: 'pending',
    identity_document: null,
  })
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }))
    // Limpiar mensajes al cambiar el formulario
    setError('')
    setSuccess('')
  }

  const handleFileChange = (e) => {
    const file = e.target.files[0]
    setFormData((prev) => ({
      ...prev,
      identity_document: file,
    }))
    setError('')
    setSuccess('')
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setSuccess('')
    setIsLoading(true)

    // Validaciones
    if (!formData.full_name.trim()) {
      setError('El nombre completo es requerido')
      setIsLoading(false)
      return
    }

    if (!formData.requested_amount || parseFloat(formData.requested_amount) <= 0) {
      setError('El monto solicitado debe ser mayor a 0')
      setIsLoading(false)
      return
    }

    if (!formData.identity_document) {
      setError('El documento de identidad es requerido')
      setIsLoading(false)
      return
    }

    try {
      // Crear FormData para multipart/form-data
      const formDataToSend = new FormData()
      formDataToSend.append('country', formData.country)
      formDataToSend.append('full_name', formData.full_name)
      formDataToSend.append('requested_amount', formData.requested_amount)
      formDataToSend.append('status', formData.status)
      formDataToSend.append('identity_document', formData.identity_document)

      const response = await fetch('http://localhost:3000/api/v1/credit_applications', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'Accept': 'application/json',
        },
        body: formDataToSend,
      })

      const data = await response.json()

      if (response.ok) {
        setSuccess('Solicitud creada exitosamente')
        // Limpiar formulario
        setFormData({
          country: 'mexico',
          full_name: '',
          requested_amount: '',
          status: 'pending',
          identity_document: null,
        })
        // Limpiar el input de archivo
        const fileInput = document.getElementById('identity_document')
        if (fileInput) fileInput.value = ''
      } else {
        setError(data.message || data.error || 'Error al crear la solicitud')
      }
    } catch (error) {
      setError('Error de conexión. Verifica que la API esté corriendo.')
      console.error('Error:', error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="bg-white rounded-2xl shadow-xl p-8">
      <h2 className="text-3xl font-bold text-blue-900 mb-6">Crear Nueva Solicitud</h2>

      {/* Mensaje de éxito */}
      {success && (
        <div className="mb-6 p-4 bg-green-50 border-l-4 border-green-500 rounded-lg">
          <p className="text-green-700 text-sm font-medium">{success}</p>
        </div>
      )}

      {/* Mensaje de error */}
      {error && (
        <div className="mb-6 p-4 bg-red-50 border-l-4 border-red-500 rounded-lg">
          <p className="text-red-700 text-sm font-medium">{error}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
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
                checked={formData.country === 'mexico'}
                onChange={handleInputChange}
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
                checked={formData.country === 'portugal'}
                onChange={handleInputChange}
                required
                className="w-4 h-4 text-blue-600 focus:ring-blue-500"
              />
              <span className="text-slate-700">Portugal</span>
            </label>
          </div>
        </div>

        {/* Nombre completo */}
        <div>
          <label htmlFor="full_name" className="block text-sm font-medium text-slate-700 mb-2">
            Nombre completo <span className="text-red-500">*</span>
          </label>
          <input
            type="text"
            id="full_name"
            name="full_name"
            value={formData.full_name}
            onChange={handleInputChange}
            placeholder="Ej: Carlos García López"
            required
            className="w-full px-4 py-2 border-2 border-slate-200 rounded-lg text-base focus:outline-none focus:border-blue-500"
          />
        </div>

        {/* Monto solicitado */}
        <div>
          <label htmlFor="requested_amount" className="block text-sm font-medium text-slate-700 mb-2">
            Monto solicitado <span className="text-red-500">*</span>
          </label>
          <input
            type="number"
            id="requested_amount"
            name="requested_amount"
            value={formData.requested_amount}
            onChange={handleInputChange}
            placeholder="Ej: 50000"
            min="0"
            step="0.01"
            required
            className="w-full px-4 py-2 border-2 border-slate-200 rounded-lg text-base focus:outline-none focus:border-blue-500"
          />
        </div>

        {/* Estado */}
        <div>
          <label htmlFor="status" className="block text-sm font-medium text-slate-700 mb-2">
            Estado
          </label>
          <select
            id="status"
            name="status"
            value={formData.status}
            onChange={handleInputChange}
            className="w-full px-4 py-2 border-2 border-slate-200 rounded-lg text-base focus:outline-none focus:border-blue-500"
          >
            <option value="pending">Pending</option>
            <option value="preapproved">Preapproved</option>
            <option value="manual_required">Manual Required</option>
            <option value="country_validated">Country Validated</option>
          </select>
        </div>

        {/* Documento de identidad */}
        <div>
          <label htmlFor="identity_document" className="block text-sm font-medium text-slate-700 mb-2">
            Documento de identidad <span className="text-red-500">*</span>
          </label>
          <input
            type="file"
            id="identity_document"
            name="identity_document"
            onChange={handleFileChange}
            required
            accept=".pdf,.jpg,.jpeg,.png,.file"
            className="w-full px-4 py-2 border-2 border-slate-200 rounded-lg text-base focus:outline-none focus:border-blue-500 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
          />
          {formData.identity_document && (
            <p className="mt-2 text-sm text-slate-500">
              Archivo seleccionado: {formData.identity_document.name}
            </p>
          )}
        </div>

        {/* Botón de envío */}
        <div className="flex gap-4">
          <button
            type="submit"
            disabled={isLoading}
            className="flex-1 bg-gradient-to-r from-blue-500 to-blue-800 text-white py-3 rounded-lg text-lg font-semibold cursor-pointer transition-all hover:-translate-y-0.5 hover:shadow-lg hover:shadow-blue-500/40 active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0"
          >
            {isLoading ? 'Creando solicitud...' : 'Crear Solicitud'}
          </button>
          <button
            type="button"
            onClick={() => {
              setFormData({
                country: 'mexico',
                full_name: '',
                requested_amount: '',
                status: 'pending',
                identity_document: null,
              })
              setError('')
              setSuccess('')
              const fileInput = document.getElementById('identity_document')
              if (fileInput) fileInput.value = ''
            }}
            className="px-6 py-3 bg-slate-200 text-slate-700 rounded-lg font-semibold hover:bg-slate-300 transition-colors"
          >
            Limpiar
          </button>
        </div>
      </form>
    </div>
  )
}

export default CreateSolicitud

