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

/**
 * Genera un nombre de usuario sugerido a partir del nombre completo.
 * Por ejemplo: "Carlos Orozco" -> "carloso"
 * @param {string} nombre - El nombre completo del usuario.
 * @returns {string} El nombre de usuario generado.
 */
function generarUsuarioDesdeNombre(nombre) {
  if (!nombre) return "";
  const partes = nombre.trim().split(" ");
  const nombreBase = partes[0].toLowerCase();
  const apellido =
    partes.length > 1 ? partes[partes.length - 1].charAt(0).toLowerCase() : "";
  return nombreBase + apellido;
}

function Usuarios() {
  // Estado para almacenar la lista de usuarios
  const [usuarios, setUsuarios] = useState([]);
  // Estado para indicar si los datos están cargando
  const [loading, setLoading] = useState(true);
  // Estado para manejar mensajes de error
  const [error, setError] = useState(null);
  // Estado para controlar la visibilidad del modal de creación/edición de usuario
  const [modalOpen, setModalOpen] = useState(false);
  // Estado para almacenar el usuario cuyas claves se están visualizando en un modal
  const [modalClaves, setModalClaves] = useState(null);
  // Estado para almacenar las claves (privada y pública) del usuario seleccionado
  const [claves, setClaves] = useState(null);
  // Estado para almacenar el usuario que se está editando (null si es un nuevo usuario)
  const [editando, setEditando] = useState(null);
  // Estado para los datos del formulario de usuario
  const [formData, setFormData] = useState({
    nombre: "",
    usuario: "",
    email: "",
    ip_asignada: "",
    notas: "",
    clave_privada: "",
    clave_publica: "",
    sistema_operativo: "linux", // Valor por defecto
  });

  // Ref para el contenido del modal de usuario para evitar cierres accidentales
  const userModalRef = useRef(null);
  // Ref para el contenido del modal de claves para evitar cierres accidentales
  const clavesModalRef = useRef(null);

  // useEffect se ejecuta una vez al montar el componente para cargar los usuarios iniciales
  useEffect(() => {
    cargarUsuarios();
  }, []); // El array vacío asegura que se ejecuta solo una vez al montar

  /**
   * Carga la lista de usuarios desde la API.
   */
  async function cargarUsuarios() {
    try {
      setLoading(true);
      const data = await getUsuarios();
      setUsuarios(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  /**
   * Maneja el cambio en el campo de nombre del formulario.
   * Si no se está editando y el campo de usuario está vacío, genera un nombre de usuario sugerido.
   * @param {Object} e - Evento de cambio del input.
   */
  function handleNombreChange(e) {
    const nombre = e.target.value;
    setFormData({ ...formData, nombre });

    // Si no estamos editando y el campo de usuario está vacío, genera uno automáticamente
    if (!editando && !formData.usuario) {
      setFormData((prev) => ({
        ...prev,
        usuario: generarUsuarioDesdeNombre(nombre),
      }));
    }
  }

  /**
   * Maneja el envío del formulario de creación/edición de usuario.
   * @param {Object} e - Evento de envío del formulario.
   */
  async function handleSubmit(e) {
    e.preventDefault();
    try {
      // Datos a enviar a la API
      const dataToSend = {
        nombre: formData.nombre,
        usuario: formData.usuario,
        email: formData.email,
        notas: formData.notas,
        sistema_operativo: formData.sistema_operativo,
      };

      if (editando) {
        // Si estamos editando, incluimos la IP asignada
        dataToSend.ip_asignada = formData.ip_asignada;
        await actualizarUsuario(editando.id, dataToSend);
      } else {
        // Si estamos creando un nuevo usuario, podemos incluir claves si fueron proporcionadas manualmente
        if (formData.clave_privada && formData.clave_publica) {
          dataToSend.clave_privada = formData.clave_privada;
          dataToSend.clave_publica = formData.clave_publica;
        }
        await crearUsuario(dataToSend);
      }
      // Cierra el modal y resetea el formulario
      setModalOpen(false);
      setEditando(null);
      setFormData({
        nombre: "",
        usuario: "",
        email: "",
        ip_asignada: "",
        notas: "",
        clave_privada: "",
        clave_publica: "",
        sistema_operativo: "linux",
      });
      cargarUsuarios(); // Recarga la lista de usuarios
    } catch (err) {
      setError(err.message);
    }
  }

  /**
   * Maneja la eliminación de un usuario.
   * @param {Object} usuario - El objeto usuario a eliminar.
   */
  async function handleEliminar(usuario) {
    if (!confirm(`¿Eliminar usuario ${usuario.nombre}?`)) return;
    try {
      await eliminarUsuario(usuario.id);
      cargarUsuarios(); // Recarga la lista de usuarios
    } catch (err) {
      setError(err.message);
    }
  }

  /**
   * Cambia el estado (activo/inactivo) de un usuario.
   * @param {Object} usuario - El objeto usuario a modificar.
   */
  async function handleToggle(usuario) {
    try {
      await toggleUsuario(usuario.id);
      cargarUsuarios(); // Recarga la lista de usuarios
    } catch (err) {
      setError(err.message);
    }
  }

  /**
   * Abre el modal para ver las claves de un usuario.
   * @param {Object} usuario - El objeto usuario.
   */
  async function handleVerClaves(usuario) {
    try {
      const data = await getClavesUsuario(usuario.id);
      setClaves(data);
      setModalClaves(usuario);
    } catch (err) {
      setError(err.message);
    }
  }

  /**
   * Descarga el archivo de configuración (.conf) para un usuario.
   * @param {Object} usuario - El objeto usuario.
   */
  function handleDescargar(usuario) {
    descargarConfig(usuario.id);
  }

  /**
   * Abre el modal en modo edición para un usuario existente.
   * @param {Object} usuario - El objeto usuario a editar.
   */
  function abrirModalEditar(usuario) {
    setEditando(usuario);
    setFormData({
      nombre: usuario.nombre,
      usuario: usuario.usuario || "",
      email: usuario.email || "",
      ip_asignada: usuario.ip_asignada,
      notas: usuario.notas || "",
      clave_privada: "", // Las claves no se cargan para edición por seguridad
      clave_publica: "", // Se podrían generar nuevas si se desea
      sistema_operativo: usuario.sistema_operativo || "linux",
    });
    setModalOpen(true);
  }

  /**
   * Abre el modal en modo creación de un nuevo usuario.
   */
  function abrirModalCrear() {
    setEditando(null); // Resetea el estado de edición
    setFormData({
      nombre: "",
      usuario: "",
      email: "",
      ip_asignada: "",
      notas: "",
      clave_privada: "",
      clave_publica: "",
      sistema_operativo: "linux",
    });
    setModalOpen(true);
  }

  /**
   * Retorna un ícono basado en el sistema operativo.
   * @param {string} sistema - El nombre del sistema operativo.
   * @returns {string} El emoji del ícono.
   */
  function getSistemaIcon(sistema) {
    switch (sistema) {
      case "windows":
        return "🪟";
      case "linux":
        return "🐧";
      case "android":
        return "📱";
      default:
        return "💻";
    }
  }

  // Si está cargando, muestra un mensaje
  if (loading) return <div className="loading">Cargando...</div>;

  return (
    <div>
      {/* Muestra un mensaje de error si existe */}
      {error && <div className="error">{error}</div>}

      <div className="card">
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: "16px",
          }}
        >
          <h2>Usuarios ({usuarios.length})</h2>
          {/* Botón para abrir el modal de creación de nuevo usuario */}
          <button className="btn btn-primary" onClick={abrirModalCrear}>
            + Nuevo Usuario
          </button>
        </div>

        {usuarios.length === 0 ? (
          // Mensaje si no hay usuarios registrados
          <div className="empty">No hay usuarios registrados</div>
        ) : (
          // Tabla de usuarios
          <table className="table">
            <thead>
              <tr>
                <th>Nombre</th>
                <th>Usuario</th>
                <th>IP</th>
                <th>S.O.</th>
                <th>Estado</th>
                <th>Acciones</th>
              </tr>
            </thead>
            <tbody>
              {usuarios.map((usuario) => (
                <tr key={usuario.id}>
                  <td>{usuario.nombre}</td>
                  <td>
                    <code>{usuario.usuario || "-"}</code>
                  </td>
                  <td>{usuario.ip_asignada}</td>
                  <td>
                    {getSistemaIcon(usuario.sistema_operativo)}{" "}
                    {usuario.sistema_operativo}
                  </td>
                  <td>
                    <span
                      className={`badge ${usuario.activo ? "badge-activo" : "badge-inactivo"}`}
                    >
                      {usuario.activo ? "Activo" : "Inactivo"}
                    </span>
                  </td>
                  <td>
                    {/* Botones de acción para cada usuario */}
                    <button
                      className="btn btn-sm btn-primary"
                      onClick={() => abrirModalEditar(usuario)}
                    >
                      Editar
                    </button>
                    <button
                      className={`btn btn-sm ${usuario.activo ? "btn-danger" : "btn-success"}`}
                      style={{ marginLeft: "4px" }}
                      onClick={() => handleToggle(usuario)}
                    >
                      {usuario.activo ? "Desact" : "Activar"}
                    </button>
                    <button
                      className="btn btn-sm"
                      style={{
                        marginLeft: "4px",
                        background: "#8b5cf6",
                        color: "white",
                      }}
                      onClick={() => handleVerClaves(usuario)}
                    >
                      Claves
                    </button>
                    <button
                      className="btn btn-sm"
                      style={{
                        marginLeft: "4px",
                        background: "#059669",
                        color: "white",
                      }}
                      onClick={() => handleDescargar(usuario)}
                    >
                      .conf
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {/* Modal para crear/editar usuario */}
      {modalOpen && (
        <div className="modal-overlay" onClick={() => setModalOpen(false)}>
          {" "}
          {/* Cierra al hacer clic fuera del modal */}
          <div
            className="modal"
            ref={userModalRef}
            onClick={(e) => e.stopPropagation()}
            style={{ maxWidth: "600px" }}
          >
            {" "}
            {/* Evita que el clic en el contenido cierre el modal */}
            <h2>{editando ? "Editar Usuario" : "Nuevo Usuario"}</h2>
            <form onSubmit={handleSubmit}>
              <div className="grid-2">
                <div className="form-group">
                  <label>Nombre completo *</label>
                  <input
                    type="text"
                    value={formData.nombre}
                    onChange={handleNombreChange}
                    required
                  />
                </div>
                <div className="form-group">
                  <label>Usuario (login)</label>
                  <input
                    type="text"
                    value={formData.usuario}
                    onChange={(e) =>
                      setFormData({ ...formData, usuario: e.target.value })
                    }
                    placeholder="nombre + inicial apellido"
                  />
                </div>
              </div>

              <div className="grid-2">
                <div className="form-group">
                  <label>Email</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) =>
                      setFormData({ ...formData, email: e.target.value })
                    }
                  />
                </div>
                {editando && (
                  <div className="form-group">
                    <label>IP Asignada</label>
                    <input
                      type="text"
                      value={formData.ip_asignada}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          ip_asignada: e.target.value,
                        })
                      }
                    />
                  </div>
                )}
              </div>

              <div className="form-group">
                <label>Sistema Operativo</label>
                <select
                  value={formData.sistema_operativo}
                  onChange={(e) =>
                    setFormData({
                      ...formData,
                      sistema_operativo: e.target.value,
                    })
                  }
                  style={{
                    width: "100%",
                    padding: "8px",
                    borderRadius: "4px",
                    border: "1px solid #d1d5db",
                  }}
                >
                  <option value="linux">🐧 Linux</option>
                  <option value="windows">🪟 Windows</option>
                  <option value="android">📱 Android</option>
                </select>
              </div>

              {!editando && (
                // Sección para claves WireGuard (solo visible en modo creación)
                <div
                  style={{
                    padding: "12px",
                    background: "#fef3c7",
                    borderRadius: "4px",
                    marginBottom: "16px",
                  }}
                >
                  <strong>Claves WireGuard</strong>
                  <p
                    style={{
                      fontSize: "12px",
                      color: "#6b7280",
                      marginTop: "4px",
                    }}
                  >
                    Deja vacío para generar automáticamente. Si usas Windows,
                    ingresa las claves que genera la app.
                  </p>
                  <div className="grid-2" style={{ marginTop: "8px" }}>
                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label style={{ fontSize: "12px" }}>Clave Privada</label>
                      <input
                        type="text"
                        value={formData.clave_privada}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            clave_privada: e.target.value,
                          })
                        }
                        placeholder="Generar automáticamente"
                        style={{ fontFamily: "monospace", fontSize: "11px" }}
                      />
                    </div>
                    <div className="form-group" style={{ marginBottom: 0 }}>
                      <label style={{ fontSize: "12px" }}>Clave Pública</label>
                      <input
                        type="text"
                        value={formData.clave_publica}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            clave_publica: e.target.value,
                          })
                        }
                        placeholder="Se genera automáticamente"
                        style={{ fontFamily: "monospace", fontSize: "11px" }}
                      />
                    </div>
                  </div>
                </div>
              )}

              <div className="form-group">
                <label>Notas</label>
                <textarea
                  value={formData.notas}
                  onChange={(e) =>
                    setFormData({ ...formData, notas: e.target.value })
                  }
                  rows={2}
                />
              </div>

              <div className="modal-actions">
                <button
                  type="button"
                  className="btn"
                  onClick={() => setModalOpen(false)}
                >
                  Cancelar
                </button>
                <button type="submit" className="btn btn-primary">
                  {editando ? "Guardar" : "Crear"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal para mostrar las claves del usuario */}
      {modalClaves && claves && (
        <div className="modal-overlay" onClick={() => setModalClaves(null)}>
          {" "}
          {/* Cierra al hacer clic fuera del modal */}
          <div
            className="modal"
            ref={clavesModalRef}
            onClick={(e) => e.stopPropagation()}
          >
            {" "}
            {/* Evita que el clic en el contenido cierre el modal */}
            <h2>Claves de {modalClaves.nombre}</h2>
            <div className="form-group">
              <label>Usuario</label>
              <input type="text" value={modalClaves.usuario || "-"} readOnly />
            </div>
            <div className="form-group">
              <label>IP Asignada</label>
              <input type="text" value={modalClaves.ip_asignada} readOnly />
            </div>
            <div className="form-group">
              <label>Clave Privada (NO compartir)</label>
              <textarea
                readOnly
                rows={2}
                style={{ fontFamily: "monospace", fontSize: "11px" }}
              >
                {claves.clave_privada}
              </textarea>
            </div>
            <div className="form-group">
              <label>Clave Pública</label>
              <input
                type="text"
                value={claves.clave_publica}
                readOnly
                style={{ fontFamily: "monospace" }}
              />
            </div>
            <div
              style={{
                marginTop: "16px",
                padding: "12px",
                background: "#fef3c7",
                borderRadius: "4px",
                fontSize: "13px",
              }}
            >
              <strong>Para agregar al servidor:</strong>
              <br />
              <code
                style={{
                  display: "block",
                  marginTop: "8px",
                  whiteSpace: "pre-wrap",
                }}
              >
                [Peer] PublicKey = {claves.clave_publica}
                AllowedIPs = {modalClaves.ip_asignada}/32
              </code>
            </div>
            <div className="modal-actions">
              <button
                className="btn btn-success"
                onClick={() => handleDescargar(modalClaves)}
              >
                Descargar archivo .conf
              </button>
              <button className="btn" onClick={() => setModalClaves(null)}>
                Cerrar
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

export default Usuarios;
