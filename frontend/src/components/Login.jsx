import Header from './Header'
import Footer from './Footer'

function Login({ email, password, errorMessage, isLoading, onEmailChange, onPasswordChange, onSubmit }) {
  return (
    <div className="min-h-screen flex flex-col">
      <Header />

      {/* Login Section */}
      <section className="bg-gradient-to-br from-slate-50 to-slate-200 py-20 min-h-[calc(100vh-200px)] flex items-center flex-1">
        <div className="max-w-7xl mx-auto px-5 w-full">
          <div className="max-w-md mx-auto bg-white p-12 rounded-2xl shadow-xl">
            <h2 className="text-center text-3xl text-blue-900 mb-2 font-bold">
              Inicia sesión en Crédito Bravo
            </h2>
            <p className="text-center text-slate-500 mb-8 text-base">
              Accede a tu cuenta para gestionar tus finanzas
            </p>

            {/* Mensaje de error */}
            {errorMessage && (
              <div className="mb-6 p-4 bg-red-50 border-l-4 border-red-500 rounded-lg">
                <p className="text-red-700 text-sm font-medium">{errorMessage}</p>
              </div>
            )}

            <form className="flex flex-col gap-6" onSubmit={onSubmit}>
              <div className="flex flex-col gap-2">
                <label htmlFor="email" className="text-slate-700 font-medium text-sm">
                  Correo electrónico
                </label>
                <input
                  type="email"
                  id="email"
                  value={email}
                  onChange={onEmailChange}
                  placeholder="tu@email.com"
                  required
                  disabled={isLoading}
                  className="px-3.5 py-3.5 border-2 border-slate-200 rounded-lg text-base transition-colors focus:outline-none focus:border-blue-500 font-sans disabled:opacity-50 disabled:cursor-not-allowed"
                />
              </div>
              <div className="flex flex-col gap-2">
                <label htmlFor="password" className="text-slate-700 font-medium text-sm">
                  Contraseña
                </label>
                <input
                  type="password"
                  id="password"
                  value={password}
                  onChange={onPasswordChange}
                  placeholder="••••••••"
                  required
                  disabled={isLoading}
                  className="px-3.5 py-3.5 border-2 border-slate-200 rounded-lg text-base transition-colors focus:outline-none focus:border-blue-500 font-sans disabled:opacity-50 disabled:cursor-not-allowed"
                />
              </div>
              <button
                type="submit"
                disabled={isLoading}
                className="bg-gradient-to-r from-blue-500 to-blue-800 text-white py-4 rounded-lg text-lg font-semibold cursor-pointer transition-all hover:-translate-y-0.5 hover:shadow-lg hover:shadow-blue-500/40 active:translate-y-0 mt-2 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0"
              >
                {isLoading ? 'Iniciando sesión...' : 'Iniciar sesión'}
              </button>
            </form>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  )
}

export default Login

