import { useState, useEffect, useRef } from "react";
import {
  getUsuarios,
  crearUsuario,
  actualizarUsuario,
  eliminarUsuario,
  toggleUsuario,
  getClavesUsuario,
  descargarConfig,
} from "../services/api";

function generarUsuarioDesdeNombre(nombre) {
  if (!nombre) return "";
  const partes = nombre.trim().split(" ");
  const nombreBase = partes[0].toLowerCase();
  const apellido =
    partes.length > 1 ? partes[partes.length - 1].charAt(0).toLowerCase() : "";
  return nombreBase + apellido;
}

function Usuarios({ showToast }) {
  const [usuarios, setUsuarios] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [modalClaves, setModalClaves] = useState(null);
  const [claves, setClaves] = useState(null);
  const [editando, setEditando] = useState(null);
  const [usuarioAEliminar, setUsuarioAEliminar] = useState(null); 
  
  const [formData, setFormData] = useState({
    nombre: "",
    usuario: "",
    email: "",
    ip_asignada: "",
    notas: "",
    clave_privada: "",
    clave_publica: "",
    sistema_operativo: "linux",
    // modo_claves: 'auto' = backend genera | 'dispositivo' = usuario pega su clave pública
    modo_claves: "auto",
  });

  const userModalRef = useRef(null);
  const clavesModalRef = useRef(null);
  const deleteModalRef = useRef(null);

  useEffect(() => {
    cargarUsuarios();
  }, []);

  async function cargarUsuarios() {
    try {
      setLoading(true);
      const data = await getUsuarios();
      setUsuarios(data);
    } catch (err) {
      setError(err.message);
      if (showToast) showToast(err.message, 'error');
    } finally {
      setLoading(false);
    }
  }

  function handleNombreChange(e) {
    const nombre = e.target.value;
    setFormData({ ...formData, nombre });
    if (!editando && !formData.usuario) {
      setFormData((prev) => ({
        ...prev,
        usuario: generarUsuarioDesdeNombre(nombre),
      }));
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    try {
      const dataToSend = {
        nombre: formData.nombre,
        usuario: formData.usuario,
        email: formData.email,
        notas: formData.notas,
        sistema_operativo: formData.sistema_operativo,
      };

      if (editando) {
        dataToSend.ip_asignada = formData.ip_asignada;
        await actualizarUsuario(editando.id, dataToSend);
        if (showToast) showToast('Usuario actualizado correctamente');
      } else {
        // Modo dispositivo: solo enviamos clave_publica (sin clave_privada)
        // Modo auto:        enviamos nada, el backend genera ambas claves
        if (formData.modo_claves === 'dispositivo' && formData.clave_publica.trim()) {
          dataToSend.clave_publica = formData.clave_publica.trim();
          // NO enviamos clave_privada — el dispositivo la tiene, nosotros no
        }
        await crearUsuario(dataToSend);
        if (showToast) showToast('Usuario creado e inyectado en WireGuard');
      }
      setModalOpen(false);
      setEditando(null);
      resetForm();
      cargarUsuarios();
    } catch (err) {
      setError(err.message);
      if (showToast) showToast(err.message, 'error');
    }
  }

  async function confirmarEliminar() {
    if (!usuarioAEliminar) return;
    try {
      await eliminarUsuario(usuarioAEliminar.id);
      if (showToast) showToast('Usuario eliminado correctamente');
      setUsuarioAEliminar(null);
      cargarUsuarios();
    } catch (err) {
      setError(err.message);
      if (showToast) showToast(err.message, 'error');
    }
  }

  async function handleToggle(usuario) {
    try {
      await toggleUsuario(usuario.id);
      if (showToast) showToast(`Usuario ${usuario.activo ? 'desactivado' : 'activado'} correctamente`);
      cargarUsuarios();
    } catch (err) {
      setError(err.message);
      if (showToast) showToast(err.message, 'error');
    }
  }

  async function handleVerClaves(usuario) {
    try {
      const data = await getClavesUsuario(usuario.id);
      setClaves(data);
      setModalClaves(usuario);
    } catch (err) {
      setError(err.message);
      if (showToast) showToast(err.message, 'error');
    }
  }

  function handleDescargar(usuario) {
    descargarConfig(usuario.id);
    if (showToast) showToast('Descarga de archivo iniciada');
  }

  function abrirModalEditar(usuario) {
    setEditando(usuario);
    setFormData({
      nombre: usuario.nombre,
      usuario: usuario.usuario || "",
      email: usuario.email || "",
      ip_asignada: usuario.ip_asignada,
      notas: usuario.notas || "",
      clave_privada: "", 
      clave_publica: "", 
      sistema_operativo: usuario.sistema_operativo || "linux",
    });
    setModalOpen(true);
  }

  function resetForm() {
    setFormData({
      nombre: "", usuario: "", email: "", ip_asignada: "", notas: "",
      clave_privada: "", clave_publica: "", sistema_operativo: "linux", modo_claves: "auto",
    });
  }

  function abrirModalCrear() {
    setEditando(null);
    resetForm();
    setModalOpen(true);
  }

  function getSistemaIcon(sistema) {
    switch (sistema) {
      case "windows": return "🪟";
      case "linux": return "🐧";
      case "android": return "📱";
      default: return "💻";
    }
  }

  if (loading) return (
    <div className="loading">
      <div className="spinner"></div>
      <p>Cargando usuarios...</p>
    </div>
  );

  return (
    <div>
      <div className="card-header">
        <div>
          <h1 className="page-title" style={{marginBottom: '4px'}}>Gestión de Usuarios</h1>
          <p style={{color: 'var(--text-muted)', fontSize: '14px'}}>Administra los accesos VPN y las configuraciones de los clientes.</p>
        </div>
        <button className="btn btn-primary" onClick={abrirModalCrear}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
          Nuevo Usuario
        </button>
      </div>

      <div className="card" style={{padding: 0, overflow: 'hidden'}}>
        {usuarios.length === 0 ? (
          <div className="empty">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path><circle cx="9" cy="7" r="4"></circle><path d="M23 21v-2a4 4 0 0 0-3-3.87"></path><path d="M16 3.13a4 4 0 0 1 0 7.75"></path></svg>
            <p style={{fontWeight: 500}}>No hay usuarios registrados</p>
            <button className="btn btn-primary" onClick={abrirModalCrear}>Crear primer usuario</button>
          </div>
        ) : (
          <div className="table-container" style={{border: 'none', borderRadius: 0}}>
            <table className="table">
              <thead>
                <tr>
                  <th>Nombre</th>
                  <th>Usuario</th>
                  <th>IP</th>
                  <th>S.O.</th>
                  <th>Estado</th>
                  <th style={{textAlign: 'right'}}>Acciones</th>
                </tr>
              </thead>
              <tbody>
                {usuarios.map((usuario) => (
                  <tr key={usuario.id}>
                    <td>
                      <div style={{fontWeight: 500, color: 'var(--text-main)'}}>{usuario.nombre}</div>
                      {usuario.email && <div style={{fontSize: '12px', color: 'var(--text-muted)'}}>{usuario.email}</div>}
                    </td>
                    <td><code style={{background: '#f3f4f6', padding: '4px 8px', borderRadius: '6px', fontSize: '13px', color: '#4f46e5'}}>{usuario.usuario || "-"}</code></td>
                    <td style={{fontFamily: 'monospace'}}>{usuario.ip_asignada}</td>
                    <td>
                      <span style={{display: 'inline-flex', alignItems: 'center', gap: '6px', fontSize: '13px'}}>
                        {getSistemaIcon(usuario.sistema_operativo)}
                        <span style={{textTransform: 'capitalize'}}>{usuario.sistema_operativo}</span>
                      </span>
                    </td>
                    <td>
                      <span className={`badge ${usuario.activo ? "badge-activo" : "badge-inactivo"}`}>
                        {usuario.activo ? "Activo" : "Inactivo"}
                      </span>
                    </td>
                    <td style={{textAlign: 'right'}}>
                      <div style={{display: 'flex', gap: '6px', justifyContent: 'flex-end'}}>
                        <button className="btn btn-sm" style={{background: '#e5e7eb', color: 'var(--text-main)'}} onClick={() => abrirModalEditar(usuario)} title="Editar">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
                        </button>
                        <button className="btn btn-sm" style={{background: '#8b5cf6', color: 'white'}} onClick={() => handleVerClaves(usuario)} title="Ver Claves">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 2l-2 2m-7.61 7.61a5.5 5.5 0 1 1-7.778 7.778 5.5 5.5 0 0 1 7.777-7.777zm0 0L15.5 7.5m0 0l3 3L22 7l-3-3m-3.5 3.5L19 4"></path></svg>
                        </button>
                        <button className="btn btn-sm" style={{background: '#059669', color: 'white'}} onClick={() => handleDescargar(usuario)} title="Descargar .conf">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                        </button>
                        <button className={`btn btn-sm ${usuario.activo ? 'btn-danger' : 'btn-success'}`} onClick={() => handleToggle(usuario)} title={usuario.activo ? "Desactivar" : "Activar"}>
                          {usuario.activo ? 
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18.36 6.64a9 9 0 1 1-12.73 0"></path><line x1="12" y1="2" x2="12" y2="12"></line></svg> : 
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="5 3 19 12 5 21 5 3"></polygon></svg>
                          }
                        </button>
                        <button className="btn btn-sm" style={{background: '#fee2e2', color: '#991b1b'}} onClick={() => setUsuarioAEliminar(usuario)} title="Eliminar">
                          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal para crear/editar usuario */}
      {modalOpen && (
        <div className="modal-overlay" onClick={() => setModalOpen(false)}>
          <div className="modal" ref={userModalRef} onClick={(e) => e.stopPropagation()} style={{ maxWidth: "600px" }}>
            <h2>{editando ? "Editar Usuario" : "Nuevo Usuario"}</h2>
            <form onSubmit={handleSubmit}>
              <div className="grid-2">
                <div className="form-group">
                  <label>Nombre completo <span style={{color: 'var(--danger)'}}>*</span></label>
                  <input type="text" value={formData.nombre} onChange={handleNombreChange} required />
                </div>
                <div className="form-group">
                  <label>Usuario (login)</label>
                  <input type="text" value={formData.usuario} onChange={(e) => setFormData({ ...formData, usuario: e.target.value })} placeholder="nombre + inicial apellido" />
                </div>
              </div>

              <div className="grid-2">
                <div className="form-group">
                  <label>Email</label>
                  <input type="email" value={formData.email} onChange={(e) => setFormData({ ...formData, email: e.target.value })} />
                </div>
                {editando && (
                  <div className="form-group">
                    <label>IP Asignada</label>
                    <input type="text" value={formData.ip_asignada} onChange={(e) => setFormData({ ...formData, ip_asignada: e.target.value })} />
                  </div>
                )}
              </div>

              <div className="form-group">
                <label>Sistema Operativo</label>
                <select value={formData.sistema_operativo} onChange={(e) => setFormData({ ...formData, sistema_operativo: e.target.value })}>
                  <option value="linux">🐧 Linux</option>
                  <option value="windows">🪟 Windows</option>
                  <option value="android">📱 Android</option>
                </select>
              </div>

              {/* ── Selección de modo de claves ── */}
              {!editando && (
                <div style={{ marginBottom: 20 }}>
                  {/* Selector de modo según SO */}
                  <div style={{
                    display: 'flex', gap: 0, border: '1px solid var(--border)',
                    borderRadius: 8, overflow: 'hidden', marginBottom: 12,
                  }}>
                    <button
                      type="button"
                      id="modo-auto"
                      style={{
                        flex: 1, padding: '10px 8px', border: 'none', cursor: 'pointer',
                        fontSize: 13, fontWeight: 600, transition: 'all 0.2s',
                        background: formData.modo_claves === 'auto' ? 'var(--primary)' : '#f9fafb',
                        color: formData.modo_claves === 'auto' ? 'white' : 'var(--text-muted)',
                      }}
                      onClick={() => setFormData({ ...formData, modo_claves: 'auto', clave_publica: '', clave_privada: '' })}
                    >
                      ⚙️ Generar claves automáticamente
                    </button>
                    <button
                      type="button"
                      id="modo-dispositivo"
                      style={{
                        flex: 1, padding: '10px 8px', border: 'none', cursor: 'pointer',
                        fontSize: 13, fontWeight: 600, transition: 'all 0.2s',
                        borderLeft: '1px solid var(--border)',
                        background: formData.modo_claves === 'dispositivo' ? '#4f46e5' : '#f9fafb',
                        color: formData.modo_claves === 'dispositivo' ? 'white' : 'var(--text-muted)',
                      }}
                      onClick={() => setFormData({ ...formData, modo_claves: 'dispositivo', clave_privada: '' })}
                    >
                      📱 Usar llave del dispositivo (Windows/Android)
                    </button>
                  </div>

                  {/* MODO AUTO */}
                  {formData.modo_claves === 'auto' && (
                    <div style={{
                      padding: '12px 16px', background: '#f0fdf4', borderRadius: 8,
                      border: '1px solid #bbf7d0', display: 'flex', gap: 10, alignItems: 'flex-start',
                    }}>
                      <span style={{ fontSize: 18 }}>✅</span>
                      <div>
                        <div style={{ fontWeight: 600, color: '#166534', fontSize: 13 }}>Generación automática</div>
                        <div style={{ color: '#15803d', fontSize: 12, marginTop: 2 }}>
                          El sistema genera la clave privada y pública. Después podrás descargar el archivo <code>.conf</code> listo para importar.
                        </div>
                      </div>
                    </div>
                  )}

                  {/* MODO DISPOSITIVO */}
                  {formData.modo_claves === 'dispositivo' && (
                    <div>
                      <div style={{
                        padding: '12px 16px', background: '#eff6ff', borderRadius: '8px 8px 0 0',
                        border: '1px solid #bfdbfe', borderBottom: 'none',
                      }}>
                        <div style={{ fontWeight: 600, color: '#1e40af', fontSize: 13, marginBottom: 6 }}>
                          📱 Cómo obtener la llave pública de tu dispositivo:
                        </div>
                        <ol style={{ margin: 0, paddingLeft: 18, color: '#1e3a8a', fontSize: 12, lineHeight: 1.7 }}>
                          <li><strong>Windows:</strong> Abre WireGuard → <em>Añadir túnel</em> → <em>Crear desde cero</em> → copia la <strong>Clave Pública</strong></li>
                          <li><strong>Android:</strong> WireGuard → <em>+</em> → <em>Crear desde cero</em> → copia la <strong>Clave Pública</strong></li>
                        </ol>
                      </div>
                      <div className="form-group" style={{
                        margin: 0, padding: '12px 16px',
                        background: '#f8fafc', border: '1px solid #bfdbfe', borderRadius: '0 0 8px 8px',
                      }}>
                        <label style={{ fontSize: 13, fontWeight: 600, color: '#1e40af' }}>
                          Llave pública del dispositivo <span style={{ color: 'var(--danger)' }}>*</span>
                        </label>
                        <input
                          id="input-clave-publica-dispositivo"
                          type="text"
                          value={formData.clave_publica}
                          onChange={(e) => setFormData({ ...formData, clave_publica: e.target.value })}
                          placeholder="Pega aquí la llave pública (ej: fZrG0x6jFTRM/wwOasP7+...)"
                          required={formData.modo_claves === 'dispositivo'}
                          style={{ fontFamily: 'monospace', fontSize: 12, marginTop: 6 }}
                        />
                        {formData.clave_publica && formData.clave_publica.trim().length < 40 && (
                          <div style={{ color: 'var(--danger)', fontSize: 12, marginTop: 4 }}>
                            ⚠ La llave pública WireGuard debe tener al menos 40 caracteres.
                          </div>
                        )}
                        {formData.clave_publica && formData.clave_publica.trim().length >= 40 && (
                          <div style={{ color: 'var(--success)', fontSize: 12, marginTop: 4 }}>
                            ✔ Llave válida ({formData.clave_publica.trim().length} caracteres)
                          </div>
                        )}
                      </div>
                    </div>
                  )}
                </div>
              )}

              <div className="form-group">
                <label>Notas</label>
                <textarea value={formData.notas} onChange={(e) => setFormData({ ...formData, notas: e.target.value })} rows={2} />
              </div>

              <div className="modal-actions">
                <button type="button" className="btn" onClick={() => setModalOpen(false)}>Cancelar</button>
                <button type="submit" className="btn btn-primary">{editando ? "Guardar Cambios" : "Crear Usuario"}</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal para mostrar las claves del usuario */}
      {modalClaves && claves && (
        <div className="modal-overlay" onClick={() => setModalClaves(null)}>
          <div className="modal" ref={clavesModalRef} onClick={(e) => e.stopPropagation()} style={{maxWidth: '550px'}}>
            <h2>Credenciales VPN: <span style={{color: 'var(--primary)'}}>{modalClaves.nombre}</span></h2>
            
            <div className="grid-2" style={{marginBottom: '16px'}}>
              <div className="form-group" style={{marginBottom: 0}}>
                <label>Usuario</label>
                <input type="text" value={modalClaves.usuario || "-"} readOnly style={{background: '#f9fafb'}} />
              </div>
              <div className="form-group" style={{marginBottom: 0}}>
                <label>IP Asignada</label>
                <input type="text" value={modalClaves.ip_asignada} readOnly style={{background: '#f9fafb'}} />
              </div>
            </div>

            <div className="form-group">
              <label style={{display: 'flex', justifyContent: 'space-between'}}>
                Clave Privada <span style={{color: 'var(--danger)', fontSize: '12px'}}>NO compartir</span>
              </label>
              <textarea readOnly rows={2} style={{ fontFamily: "monospace", fontSize: "13px", background: '#fef2f2', borderColor: '#fecaca', color: '#991b1b' }} value={claves.clave_privada} />
            </div>
            
            <div className="form-group">
              <label>Clave Pública</label>
              <input type="text" value={claves.clave_publica} readOnly style={{ fontFamily: "monospace", fontSize: "13px", background: '#f9fafb' }} />
            </div>
            
            <div style={{ marginTop: "24px", padding: "16px", background: "#111827", color: '#e5e7eb', borderRadius: "8px", fontSize: "13px" }}>
              <div style={{color: '#9ca3af', marginBottom: '8px', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '0.05em'}}>Snippet del Servidor</div>
              <code style={{ display: "block", whiteSpace: "pre-wrap", fontFamily: 'monospace' }}>
                <span style={{color: '#818cf8'}}>[Peer]</span><br/>
                PublicKey = {claves.clave_publica}<br/>
                AllowedIPs = {modalClaves.ip_asignada}/32
              </code>
            </div>
            
            <div className="modal-actions">
              <button className="btn" onClick={() => setModalClaves(null)}>Cerrar</button>
              <button className="btn btn-success" onClick={() => handleDescargar(modalClaves)}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                Descargar Configuración
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal de confirmación de eliminación */}
      {usuarioAEliminar && (
        <div className="modal-overlay" onClick={() => setUsuarioAEliminar(null)}>
          <div className="modal" ref={deleteModalRef} onClick={(e) => e.stopPropagation()} style={{maxWidth: '400px'}}>
            <div style={{display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px'}}>
              <div style={{background: '#fee2e2', color: '#dc2626', padding: '10px', borderRadius: '50%'}}>
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path><line x1="12" y1="9" x2="12" y2="13"></line><line x1="12" y1="17" x2="12.01" y2="17"></line></svg>
              </div>
              <h2 style={{margin: 0}}>Confirmar eliminación</h2>
            </div>
            <p style={{color: 'var(--text-muted)'}}>
              ¿Estás seguro de que deseas eliminar permanentemente al usuario <strong style={{color: 'var(--text-main)'}}>{usuarioAEliminar.nombre}</strong>? Esta acción no se puede deshacer y revocará su acceso VPN inmediatamente.
            </p>
            <div className="modal-actions">
              <button className="btn" onClick={() => setUsuarioAEliminar(null)}>Cancelar</button>
              <button className="btn btn-danger" onClick={confirmarEliminar}>Sí, eliminar usuario</button>
            </div>
          </div>
        </div>
      )}

    </div>
  );
}

export default Usuarios;
