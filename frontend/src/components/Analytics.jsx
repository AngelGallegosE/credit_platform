import { useState, useEffect } from 'react'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement
} from 'chart.js'
import { Bar, Pie } from 'react-chartjs-2'

// Registrar componentes de ChartJS
ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
  ArcElement
)

function Analytics({ token }) {
  const [data, setData] = useState(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchAnalytics = async () => {
      setIsLoading(true)
      setError('')
      try {
        const response = await fetch('http://localhost:3000/api/v1/analytics/credit_applications/by_status', {
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        })

        if (!response.ok) {
          throw new Error('Error al cargar los datos de analítica')
        }

        const analyticsData = await response.json()
        setData(analyticsData)
      } catch (err) {
        console.error('Error fetching analytics:', err)
        setError(err.message)
      } finally {
        setIsLoading(false)
      }
    }

    if (token) {
      fetchAnalytics()
    }
  }, [token])

  const getChartData = (countryCode) => {
    if (!data || !data[countryCode]) return null

    const countryData = data[countryCode]
    const labels = Object.keys(countryData).map(status =>
      status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
    )
    const values = Object.values(countryData)

    return {
      labels,
      datasets: [
        {
          label: `Solicitudes por Estado - ${countryCode === 'MX' ? 'México' : 'Portugal'}`,
          data: values,
          backgroundColor: [
            'rgba(54, 162, 235, 0.6)',   // pending
            'rgba(75, 192, 192, 0.6)',   // preapproved
            'rgba(255, 206, 86, 0.6)',   // manual_required
            'rgba(153, 102, 255, 0.6)',  // country_validated
            'rgba(255, 99, 132, 0.6)',   // country_invalidated
            'rgba(255, 159, 64, 0.6)',   // in_review
            'rgba(34, 197, 94, 0.6)',    // approved
            'rgba(239, 68, 68, 0.6)',    // rejected
            'rgba(107, 114, 128, 0.6)',  // expired
            'rgba(209, 213, 219, 0.6)',  // cancelled
          ],
          borderColor: [
            'rgba(54, 162, 235, 1)',
            'rgba(75, 192, 192, 1)',
            'rgba(255, 206, 86, 1)',
            'rgba(153, 102, 255, 1)',
            'rgba(255, 99, 132, 1)',
            'rgba(255, 159, 64, 1)',
            'rgba(34, 197, 94, 1)',
            'rgba(239, 68, 68, 1)',
            'rgba(107, 114, 128, 1)',
            'rgba(209, 213, 219, 1)',
          ],
          borderWidth: 1,
        },
      ],
    }
  }

  const options = {
    responsive: true,
    plugins: {
      legend: {
        position: 'top',
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          stepSize: 1
        }
      }
    }
  }

  if (isLoading) {
    return (
      <div className="bg-white rounded-2xl shadow-xl p-8 flex justify-center items-center min-h-[400px]">
        <p className="text-slate-500 animate-pulse">Cargando analíticas...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <div className="p-4 bg-red-50 border-l-4 border-red-500 rounded-lg text-red-700 font-medium">
          {error}
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-8">
      <div className="bg-white rounded-2xl shadow-xl p-8">
        <h2 className="text-3xl font-bold text-blue-900 mb-8 text-center">Analíticas de Solicitudes</h2>

        <div className="grid grid-cols-1 xl:grid-cols-2 gap-12">
          {/* Gráfica México */}
          <div className="bg-slate-50 p-6 rounded-xl border border-slate-100 shadow-sm">
            <h3 className="text-xl font-bold text-slate-800 mb-6 flex items-center gap-2">
              <span className="text-2xl">🇲🇽</span> México
            </h3>
            <div className="h-[350px] flex items-center justify-center">
              {data?.MX ? (
                <Bar data={getChartData('MX')} options={options} />
              ) : (
                <p className="text-slate-400 italic">No hay datos para México</p>
              )}
            </div>
          </div>

          {/* Gráfica Portugal */}
          <div className="bg-slate-50 p-6 rounded-xl border border-slate-100 shadow-sm">
            <h3 className="text-xl font-bold text-slate-800 mb-6 flex items-center gap-2">
              <span className="text-2xl">🇵🇹</span> Portugal
            </h3>
            <div className="h-[350px] flex items-center justify-center">
              {data?.PT ? (
                <Bar data={getChartData('PT')} options={options} />
              ) : (
                <p className="text-slate-400 italic">No hay datos para Portugal</p>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Resumen Total */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {['MX', 'PT'].map(country => {
          const countryData = data?.[country] || {}
          const total = Object.values(countryData).reduce((a, b) => a + b, 0)

          return (
            <div key={country} className="bg-white p-6 rounded-2xl shadow-lg border-t-4 border-blue-500">
              <div className="flex justify-between items-center mb-4">
                <h4 className="text-lg font-bold text-slate-700">
                  Total {country === 'MX' ? 'México' : 'Portugal'}
                </h4>
                <span className="text-3xl font-black text-blue-600">{total}</span>
              </div>
              <div className="grid grid-cols-2 gap-3">
                {Object.entries(countryData)
                  .filter(([_, value]) => value > 0)
                  .map(([status, value]) => (
                    <div key={status} className="bg-slate-50 p-2 rounded flex justify-between items-center border border-slate-100">
                      <span className="text-xs font-medium text-slate-500 capitalize">
                        {status.replace(/_/g, ' ')}
                      </span>
                      <span className="text-sm font-bold text-slate-800">{value}</span>
                    </div>
                  ))}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}

export default Analytics;

