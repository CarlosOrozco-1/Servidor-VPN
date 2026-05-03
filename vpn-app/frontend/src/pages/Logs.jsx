import { useState, useEffect } from "react";
import { getLogs, getLogsRecientes } from "../services/api";

function Logs() {
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filtro, setFiltro] = useState("todos");

  useEffect(() => {
    cargarLogs();
  }, [filtro]);

  async function cargarLogs() {
    try {
      setLoading(true);
      let data;
      if (filtro === "7dias") {
        data = await getLogsRecientes(7);
      } else if (filtro === "30dias") {
        data = await getLogsRecientes(30);
      } else {
        data = await getLogs(200);
      }
      setLogs(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  function getAccionBadge(accion) {
    if (accion.includes("CREADO") || accion.includes("ACTIVADO")) {
      return <span style={{background: '#d1fae5', color: '#065f46', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 600}}>{accion}</span>;
    }
    if (accion.includes("ELIMINADO") || accion.includes("DESACTIVADO")) {
      return <span style={{background: '#fee2e2', color: '#991b1b', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 600}}>{accion}</span>;
    }
    if (accion.includes("ACTUALIZAR")) {
      return <span style={{background: '#dbeafe', color: '#1e40af', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 600}}>{accion}</span>;
    }
    return <span style={{background: '#f3f4f6', color: '#374151', padding: '4px 8px', borderRadius: '4px', fontSize: '12px', fontWeight: 600}}>{accion}</span>;
  }

  if (loading) return (
    <div className="loading">
      <div className="spinner"></div>
      <p>Cargando historial...</p>
    </div>
  );

  return (
    <div>
      <div className="card-header">
        <div>
          <h1 className="page-title" style={{marginBottom: '4px'}}>Historial de Actividad</h1>
          <p style={{color: 'var(--text-muted)', fontSize: '14px'}}>Auditoría de eventos y acciones realizadas en el servidor VPN.</p>
        </div>
        <div className="form-group" style={{marginBottom: 0}}>
          <select value={filtro} onChange={(e) => setFiltro(e.target.value)} style={{minWidth: '160px'}}>
            <option value="todos">Todos los eventos</option>
            <option value="7dias">Últimos 7 días</option>
            <option value="30dias">Últimos 30 días</option>
          </select>
        </div>
      </div>

      <div className="card" style={{padding: 0, overflow: 'hidden'}}>
        {logs.length === 0 ? (
          <div className="empty">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"></circle><polyline points="12 6 12 12 16 14"></polyline></svg>
            <p style={{fontWeight: 500}}>No hay registros de actividad</p>
          </div>
        ) : (
          <div className="table-container" style={{maxHeight: "600px", border: 'none', borderRadius: 0}}>
            <table className="table">
              <thead style={{position: 'sticky', top: 0, zIndex: 1}}>
                <tr>
                  <th>Fecha y Hora</th>
                  <th>Usuario</th>
                  <th>Acción</th>
                  <th>Detalles</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => (
                  <tr key={log.id}>
                    <td style={{ whiteSpace: "nowrap", color: 'var(--text-muted)', fontSize: '13px' }}>
                      {new Date(log.fecha).toLocaleString()}
                    </td>
                    <td>
                      <span style={{fontWeight: 500}}>{log.usuario_nombre || "Sistema"}</span>
                    </td>
                    <td>{getAccionBadge(log.accion)}</td>
                    <td style={{ color: "var(--text-muted)", fontSize: '13px' }}>{log.detalles || "-"}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

export default Logs;
