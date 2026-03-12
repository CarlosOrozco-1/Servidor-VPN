import { useState, useEffect } from 'react'
import { getConfigs, updateConfig } from '../services/api'

function Configuracion() {
  const [configs, setConfigs] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [editando, setEditando] = useState(null)
  const [valorEdit, setValorEdit] = useState('')

  useEffect(() => {
    cargarConfigs()
  }, [])

  async function cargarConfigs() {
    try {
      setLoading(true)
      const data = await getConfigs()
      setConfigs(data)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  async function handleGuardar() {
    try {
      await updateConfig(editando, valorEdit)
      setEditando(null)
      setValorEdit('')
      cargarConfigs()
    } catch (err) {
      setError(err.message)
    }
  }

  function iniciarEdicion(config) {
    setEditando(config.clave)
    setValorEdit(config.valor)
  }

  if (loading) return <div className="loading">Cargando...</div>

  return (
    <div>
      {error && <div className="error">{error}</div>}
      
      <div className="card">
        <h2>Configuración del Servidor VPN</h2>
        
        <table className="table">
          <thead>
            <tr>
              <th>Clave</th>
              <th>Valor</th>
              <th>Descripción</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            {configs.map(config => (
              <tr key={config.id}>
                <td><strong>{config.clave}</strong></td>
                <td>
                  {editando === config.clave ? (
                    <input 
                      type="text" 
                      value={valorEdit}
                      onChange={e => setValorEdit(e.target.value)}
                      style={{ width: '100%' }}
                    />
                  ) : (
                    config.valor
                  )}
                </td>
                <td style={{ color: '#6b7280' }}>{config.descripcion}</td>
                <td>
                  {editando === config.clave ? (
                    <>
                      <button className="btn btn-sm btn-primary" onClick={handleGuardar}>Guardar</button>
                      <button className="btn btn-sm" style={{ marginLeft: '4px' }} onClick={() => setEditando(null)}>Cancelar</button>
                    </>
                  ) : (
                    <button className="btn btn-sm btn-primary" onClick={() => iniciarEdicion(config)}>Editar</button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Información del Servidor</h2>
        <div style={{ color: '#6b7280' }}>
          <p><strong>Endpoint:</strong> {configs.find(c => c.clave === 'endpoint')?.valor}</p>
          <p><strong>Subnet:</strong> {configs.find(c => c.clave === 'subnet')?.valor}</p>
          <p><strong>DNS:</strong> {configs.find(c => c.clave === 'dns')?.valor}</p>
          <p><strong>Persistent Keepalive:</strong> {configs.find(c => c.clave === 'persistent_keepalive')?.valor} segundos</p>
        </div>
      </div>
    </div>
  )
}

export default Configuracion
