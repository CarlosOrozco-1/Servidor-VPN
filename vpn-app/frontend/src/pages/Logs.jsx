import { useState, useEffect } from 'react'
import { getLogs, getLogsRecientes } from '../services/api'

function Logs() {
  const [logs, setLogs] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [filtro, setFiltro] = useState('todos')

  useEffect(() => {
    cargarLogs()
  }, [filtro])

  async function cargarLogs() {
    try {
      setLoading(true)
      let data
      if (filtro === '7dias') {
        data = await getLogsRecientes(7)
      } else if (filtro === '30dias') {
        data = await getLogsRecientes(30)
      } else {
        data = await getLogs(200)
      }
      setLogs(data)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  function getAccionColor(accion) {
    if (accion.includes('CREADO') || accion.includes('ACTIVADO')) return '#16a34a'
    if (accion.includes('ELIMINADO') || accion.includes('DESACTIVADO')) return '#dc2626'
    if (accion.includes('ACTUALIZAR')) return '#2563eb'
    return '#6b7280'
  }

  if (loading) return <div className="loading">Cargando...</div>

  return (
    <div>
      {error && <div className="error">{error}</div>}
      
      <div className="card">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
          <h2>Historial de Actividad</h2>
          <select 
            value={filtro} 
            onChange={e => setFiltro(e.target.value)}
            style={{ padding: '8px', borderRadius: '4px', border: '1px solid #d1d5db' }}
          >
            <option value="todos">Todos</option>
            <option value="7dias">Últimos 7 días</option>
            <option value="30dias">Últimos 30 días</option>
          </select>
        </div>

        {logs.length === 0 ? (
          <div className="empty">No hay registros</div>
        ) : (
          <div style={{ maxHeight: '600px', overflowY: 'auto' }}>
            <table className="table">
              <thead>
                <tr>
                  <th>Fecha</th>
                  <th>Usuario</th>
                  <th>Acción</th>
                  <th>Detalles</th>
                </tr>
              </thead>
              <tbody>
                {logs.map(log => (
                  <tr key={log.id}>
                    <td style={{ whiteSpace: 'nowrap' }}>
                      {new Date(log.fecha).toLocaleString()}
                    </td>
                    <td>{log.usuario_nombre || 'Sistema'}</td>
                    <td>
                      <span style={{ 
                        color: getAccionColor(log.accion),
                        fontWeight: 500 
                      }}>
                        {log.accion}
                      </span>
                    </td>
                    <td style={{ color: '#6b7280' }}>{log.detalles || '-'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  )
}

export default Logs
