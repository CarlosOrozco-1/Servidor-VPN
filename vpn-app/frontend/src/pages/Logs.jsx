import { useState, useEffect } from "react";
import { getLogs, getLogsRecientes } from "../services/api";

/**
 * Componente funcional para la página de Logs (Historial de Actividad).
 * Muestra un registro de las acciones realizadas en la aplicación, como la creación,
 * actualización o eliminación de usuarios. Permite filtrar los logs por período.
 */
function Logs() {
  // Estado para almacenar la lista de logs obtenidos de la API.
  const [logs, setLogs] = useState([]);
  // Estado para indicar si los datos de los logs están cargando.
  const [loading, setLoading] = useState(true);
  // Estado para manejar cualquier mensaje de error que pueda ocurrir.
  const [error, setError] = useState(null);
  // Estado para controlar el filtro de tiempo aplicado a los logs ('todos', '7dias', '30dias').
  const [filtro, setFiltro] = useState("todos");

  // useEffect se ejecuta cada vez que el valor de `filtro` cambia, o una vez al montar.
  useEffect(() => {
    cargarLogs();
  }, [filtro]); // Dependencia del `filtro` para recargar los logs cuando cambia.

  /**
   * Carga los logs desde la API, aplicando el filtro de tiempo seleccionado.
   * Actualiza los estados `logs`, `loading` y `error`.
   */
  async function cargarLogs() {
    try {
      setLoading(true); // Inicia el estado de carga.
      let data; // Variable para almacenar los datos de los logs.

      // Lógica condicional para llamar a la API correcta según el filtro.
      if (filtro === "7dias") {
        data = await getLogsRecientes(7); // Obtiene logs de los últimos 7 días.
      } else if (filtro === "30dias") {
        data = await getLogsRecientes(30); // Obtiene logs de los últimos 30 días.
      } else {
        data = await getLogs(200); // Obtiene todos los logs (limitado a 200 en este caso).
      }
      setLogs(data); // Almacena los logs obtenidos en el estado.
    } catch (err) {
      setError(err.message); // Captura y muestra cualquier error.
    } finally {
      setLoading(false); // Finaliza el estado de carga, independientemente del resultado.
    }
  }

  /**
   * Retorna un color de texto basado en el tipo de acción del log.
   * Útil para resaltar visualmente los logs en la tabla.
   * @param {string} accion - La cadena de texto que describe la acción del log.
   * @returns {string} Un código de color hexadecimal.
   */
  function getAccionColor(accion) {
    if (accion.includes("CREADO") || accion.includes("ACTIVADO"))
      return "#16a34a"; // Verde para acciones positivas.
    if (accion.includes("ELIMINADO") || accion.includes("DESACTIVADO"))
      return "#dc2626"; // Rojo para acciones destructivas/negativas.
    if (accion.includes("ACTUALIZAR")) return "#2563eb"; // Azul para actualizaciones.
    return "#6b7280"; // Gris por defecto para otras acciones.
  }

  // Si los datos están cargando, muestra un mensaje de carga.
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
          <h2>Historial de Actividad</h2>
          {/* Selector de filtro para los logs */}
          <select
            value={filtro}
            onChange={(e) => setFiltro(e.target.value)} // Actualiza el estado `filtro` al cambiar la selección.
            style={{
              padding: "8px",
              borderRadius: "4px",
              border: "1px solid #d1d5db",
            }}
          >
            <option value="todos">Todos</option>
            <option value="7dias">Últimos 7 días</option>
            <option value="30dias">Últimos 30 días</option>
          </select>
        </div>

        {logs.length === 0 ? (
          // Mensaje si no hay registros de logs.
          <div className="empty">No hay registros</div>
        ) : (
          // Contenedor con scroll para la tabla de logs.
          <div style={{ maxHeight: "600px", overflowY: "auto" }}>
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
                {/* Mapea sobre la lista de logs para renderizar cada fila */}
                {logs.map((log) => (
                  <tr key={log.id}>
                    <td style={{ whiteSpace: "nowrap" }}>
                      {/* Formatea la fecha del log a un formato legible */}
                      {new Date(log.fecha).toLocaleString()}
                    </td>
                    <td>{log.usuario_nombre || "Sistema"}</td>{" "}
                    {/* Muestra el nombre del usuario o 'Sistema' */}
                    <td>
                      <span
                        style={{
                          color: getAccionColor(log.accion), // Aplica color según el tipo de acción.
                          fontWeight: 500,
                        }}
                      >
                        {log.accion} {/* Muestra la acción realizada */}
                      </span>
                    </td>
                    <td style={{ color: "#6b7280" }}>{log.detalles || "-"}</td>{" "}
                    {/* Muestra los detalles de la acción */}
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
