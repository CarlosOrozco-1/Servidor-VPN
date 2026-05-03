import { useState, useEffect } from "react";
import { getConfigs, updateConfig } from "../services/api";

function Configuracion({ showToast }) {
  const [configs, setConfigs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [editando, setEditando] = useState(null);
  const [valorEdit, setValorEdit] = useState("");

  useEffect(() => {
    cargarConfigs();
  }, []);

  async function cargarConfigs() {
    try {
      setLoading(true);
      const data = await getConfigs();
      setConfigs(data);
    } catch (err) {
      setError(err.message);
      if (showToast) showToast(err.message, 'error');
    } finally {
      setLoading(false);
    }
  }

  async function handleGuardar() {
    try {
      await updateConfig(editando, valorEdit);
      if (showToast) showToast(`Configuración ${editando} guardada correctamente`);
      setEditando(null);
      setValorEdit("");
      cargarConfigs();
    } catch (err) {
      setError(err.message);
      if (showToast) showToast(err.message, 'error');
    }
  }

  function iniciarEdicion(config) {
    setEditando(config.clave);
    setValorEdit(config.valor);
  }

  if (loading) return (
    <div className="loading">
      <div className="spinner"></div>
      <p>Cargando configuración...</p>
    </div>
  );

  return (
    <div>
      <div className="card-header">
        <div>
          <h1 className="page-title" style={{marginBottom: '4px'}}>Configuración del Servidor</h1>
          <p style={{color: 'var(--text-muted)', fontSize: '14px'}}>Ajusta los parámetros globales de la red VPN WireGuard.</p>
        </div>
      </div>

      <div className="grid-2">
        <div className="card" style={{padding: 0, overflow: 'hidden'}}>
          <div style={{padding: '20px 24px', borderBottom: '1px solid var(--border)', background: '#f8fafc'}}>
            <h2 style={{margin: 0, fontSize: '16px', display: 'flex', alignItems: 'center', gap: '8px'}}>
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="3"></circle><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"></path></svg>
              Parámetros
            </h2>
          </div>
          <table className="table">
            <tbody>
              {configs.map((config) => (
                <tr key={config.id}>
                  <td style={{width: '30%', verticalAlign: 'top'}}>
                    <div style={{fontWeight: 600, color: 'var(--text-main)'}}>{config.clave}</div>
                    <div style={{fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px'}}>{config.descripcion}</div>
                  </td>
                  <td>
                    {editando === config.clave ? (
                      <div style={{display: 'flex', gap: '8px', alignItems: 'center'}}>
                        <input
                          type="text"
                          value={valorEdit}
                          onChange={(e) => setValorEdit(e.target.value)}
                          style={{ width: "100%", padding: '8px', borderRadius: '6px', border: '1px solid var(--primary)', outline: 'none', boxShadow: '0 0 0 2px rgba(79, 70, 229, 0.1)' }}
                          autoFocus
                        />
                        <button className="btn btn-sm btn-primary" onClick={handleGuardar}>Guardar</button>
                        <button className="btn btn-sm" onClick={() => setEditando(null)}>Cancelar</button>
                      </div>
                    ) : (
                      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
                        <code style={{background: '#f3f4f6', padding: '4px 8px', borderRadius: '4px', fontSize: '13px'}}>{config.valor}</code>
                        <button className="btn btn-sm" style={{background: 'transparent', color: 'var(--text-muted)', padding: '4px'}} onClick={() => iniciarEdicion(config)} title="Editar">
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                        </button>
                      </div>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        <div className="card" style={{height: 'fit-content'}}>
          <h2 style={{display: 'flex', alignItems: 'center', gap: '8px', margin: 0, paddingBottom: '16px', borderBottom: '1px solid var(--border)', marginBottom: '16px'}}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--primary)" strokeWidth="2"><rect x="2" y="2" width="20" height="8" rx="2" ry="2"></rect><rect x="2" y="14" width="20" height="8" rx="2" ry="2"></rect><line x1="6" y1="6" x2="6.01" y2="6"></line><line x1="6" y1="18" x2="6.01" y2="18"></line></svg>
            Resumen del Servidor
          </h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
              <span style={{color: 'var(--text-muted)'}}>Endpoint</span>
              <span style={{fontWeight: 500}}>{configs.find((c) => c.clave === "endpoint")?.valor}</span>
            </div>
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
              <span style={{color: 'var(--text-muted)'}}>Subnet</span>
              <span style={{fontWeight: 500}}>{configs.find((c) => c.clave === "subnet")?.valor}</span>
            </div>
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
              <span style={{color: 'var(--text-muted)'}}>DNS</span>
              <span style={{fontWeight: 500}}>{configs.find((c) => c.clave === "dns")?.valor}</span>
            </div>
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
              <span style={{color: 'var(--text-muted)'}}>Persistent Keepalive</span>
              <span style={{fontWeight: 500}}>{configs.find((c) => c.clave === "persistent_keepalive")?.valor} seg</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Configuracion;
