import Footer from './Footer'
import SolicitudesList from './SolicitudesList'
import CreateSolicitud from './CreateSolicitud'
import Analytics from './Analytics'

function Dashboard({ user, currentView, setCurrentView, onLogout, token }) {
  return (
    <div className="min-h-screen flex flex-col">
      {/* Header con menú */}
      <header className="bg-gradient-to-br from-blue-800 to-blue-500 text-white py-6 shadow-lg">
        <div className="max-w-7xl mx-auto px-5 w-full">
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
            <div className="flex items-center gap-4">
              <h1 className="text-2xl md:text-3xl font-bold m-0">GoBravo</h1>
              <span className="text-sm md:text-base opacity-90 font-light">Crédito Bravo</span>
            </div>
            <div className="flex flex-col md:flex-row items-start md:items-center gap-4 md:gap-6 w-full md:w-auto">
              <nav className="flex flex-col md:flex-row gap-2 md:gap-4 w-full md:w-auto">
                <button
                  onClick={() => setCurrentView('crear')}
                  className={`px-4 py-2 rounded-lg font-medium transition-all text-sm md:text-base ${
                    currentView === 'crear'
                      ? 'bg-white text-blue-800 shadow-md'
                      : 'bg-blue-600/50 text-white hover:bg-blue-600/70'
                  }`}
                >
                  Crear Solicitud
                </button>
                <button
                  onClick={() => setCurrentView('lista')}
                  className={`px-4 py-2 rounded-lg font-medium transition-all text-sm md:text-base ${
                    currentView === 'lista'
                      ? 'bg-white text-blue-800 shadow-md'
                      : 'bg-blue-600/50 text-white hover:bg-blue-600/70'
                  }`}
                >
                  Ver Lista de Solicitudes
                </button>
                <button
                  onClick={() => setCurrentView('analytics')}
                  className={`px-4 py-2 rounded-lg font-medium transition-all text-sm md:text-base ${
                    currentView === 'analytics'
                      ? 'bg-white text-blue-800 shadow-md'
                      : 'bg-blue-600/50 text-white hover:bg-blue-600/70'
                  }`}
                >
                  Analytics
                </button>
              </nav>
              <div className="flex flex-col md:flex-row items-start md:items-center gap-3 md:border-l md:border-blue-400/30 md:pl-6 w-full md:w-auto pt-2 md:pt-0 border-t border-blue-400/30 md:border-t-0">
                <span className="text-xs md:text-sm opacity-90">{user?.email}</span>
                <button
                  onClick={onLogout}
                  className="px-4 py-2 bg-red-500 hover:bg-red-600 rounded-lg text-xs md:text-sm font-medium transition-colors w-full md:w-auto"
                >
                  Cerrar Sesión
                </button>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Contenido principal */}
      <main className="flex-1 bg-gradient-to-br from-slate-50 to-slate-200 py-10">
        <div className="max-w-7xl mx-auto px-5 w-full">
          {currentView === 'crear' && <CreateSolicitud token={token} />}
          {currentView === 'lista' && <SolicitudesList token={token} user={user} />}
          {currentView === 'analytics' && <Analytics token={token} />}
        </div>
      </main>

      <Footer />
    </div>
  )
}

export default Dashboard

