import { useState, useEffect } from "react";
import { getConfigs, updateConfig } from "../services/api";

/**
 * Componente funcional para la página de configuración del servidor VPN.
 * Permite visualizar y editar las configuraciones generales del servidor.
 */
function Configuracion() {
  // Estado para almacenar la lista de configuraciones obtenidas de la API.
  const [configs, setConfigs] = useState([]);
  // Estado para indicar si los datos de configuración están cargando.
  const [loading, setLoading] = useState(true);
  // Estado para manejar cualquier mensaje de error que pueda ocurrir durante las operaciones.
  const [error, setError] = useState(null);
  // Estado para almacenar la 'clave' de la configuración que se está editando actualmente (ej. 'endpoint').
  const [editando, setEditando] = useState(null);
  // Estado para almacenar el valor temporal del input cuando una configuración está siendo editada.
  const [valorEdit, setValorEdit] = useState("");

  // useEffect se ejecuta una vez al montar el componente para cargar las configuraciones iniciales.
  useEffect(() => {
    cargarConfigs();
  }, []); // El array vacío asegura que se ejecuta solo una vez al montar.

  /**
   * Carga las configuraciones del servidor desde la API.
   * Actualiza los estados `configs`, `loading` y `error`.
   */
  async function cargarConfigs() {
    try {
      setLoading(true); // Inicia el estado de carga.
      const data = await getConfigs(); // Llama a la API para obtener las configuraciones.
      setConfigs(data); // Almacena las configuraciones en el estado.
    } catch (err) {
      setError(err.message); // Captura y muestra cualquier error.
    } finally {
      setLoading(false); // Finaliza el estado de carga, independientemente del resultado.
    }
  }

  /**
   * Maneja el guardado de una configuración editada.
   * Envía el valor actualizado a la API y luego recarga todas las configuraciones.
   */
  async function handleGuardar() {
    try {
      // Llama a la API para actualizar la configuración con la clave y el nuevo valor.
      await updateConfig(editando, valorEdit);
      setEditando(null); // Resetea el estado de edición.
      setValorEdit(""); // Limpia el valor temporal de edición.
      cargarConfigs(); // Recarga todas las configuraciones para reflejar el cambio.
    } catch (err) {
      setError(err.message); // Captura y muestra cualquier error.
    }
  }

  /**
   * Inicia el modo de edición para una configuración específica.
   * @param {Object} config - El objeto de configuración a editar.
   */
  function iniciarEdicion(config) {
    setEditando(config.clave); // Establece la clave de la configuración que se está editando.
    setValorEdit(config.valor); // Carga el valor actual de la configuración en el input de edición.
  }

  // Si los datos están cargando, muestra un mensaje de carga.
  if (loading) return <div className="loading">Cargando...</div>;

  return (
    <div>
      {/* Muestra un mensaje de error si existe */}
      {error && <div className="error">{error}</div>}

      <div className="card">
        <h2>Configuración del Servidor VPN</h2>

        {/* Tabla para mostrar y editar las configuraciones */}
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
            {/* Mapea sobre la lista de configuraciones para renderizar cada fila */}
            {configs.map((config) => (
              <tr key={config.id}>
                <td>
                  <strong>{config.clave}</strong>
                </td>
                <td>
                  {/* Renderizado condicional: si se está editando esta configuración, muestra un input; de lo contrario, muestra el valor */}
                  {editando === config.clave ? (
                    <input
                      type="text"
                      value={valorEdit}
                      onChange={(e) => setValorEdit(e.target.value)} // Actualiza el estado temporal al escribir
                      style={{ width: "100%" }}
                    />
                  ) : (
                    config.valor // Muestra el valor de la configuración
                  )}
                </td>
                <td style={{ color: "#6b7280" }}>{config.descripcion}</td>
                <td>
                  {/* Renderizado condicional de botones: Guardar/Cancelar si editando, o Editar si no */}
                  {editando === config.clave ? (
                    <>
                      <button
                        className="btn btn-sm btn-primary"
                        onClick={handleGuardar}
                      >
                        Guardar
                      </button>
                      <button
                        className="btn btn-sm"
                        style={{ marginLeft: "4px" }}
                        onClick={() => setEditando(null)}
                      >
                        Cancelar
                      </button>
                    </>
                  ) : (
                    <button
                      className="btn btn-sm btn-primary"
                      onClick={() => iniciarEdicion(config)}
                    >
                      Editar
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Sección de información consolidada del servidor */}
      <div className="card">
        <h2>Información del Servidor</h2>
        <div style={{ color: "#6b7280" }}>
          {/* Muestra valores específicos de configuración de forma legible */}
          <p>
            <strong>Endpoint:</strong>{" "}
            {configs.find((c) => c.clave === "endpoint")?.valor}
          </p>
          <p>
            <strong>Subnet:</strong>{" "}
            {configs.find((c) => c.clave === "subnet")?.valor}
          </p>
          <p>
            <strong>DNS:</strong>{" "}
            {configs.find((c) => c.clave === "dns")?.valor}
          </p>
          <p>
            <strong>Persistent Keepalive:</strong>{" "}
            {configs.find((c) => c.clave === "persistent_keepalive")?.valor}{" "}
            segundos
          </p>
        </div>
      </div>
    </div>
  );
}

export default Configuracion;
