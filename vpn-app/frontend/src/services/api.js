/**
 * @file api.js
 * @description Módulo de servicios para interactuar con la API del backend.
 *              Contiene funciones para realizar peticiones HTTP a los diferentes endpoints
 *              relacionados con usuarios, configuraciones y logs.
 */

// Define la URL base de la API. Se asume que el frontend y el backend están
// sirviendo desde el mismo origen, o que el proxy de desarrollo se encarga de redirigir.
const API_URL = "/api";

/**
 * Obtiene la lista de todos los usuarios desde la API.
 * @returns {Promise<Array>} Una promesa que resuelve con un array de objetos de usuario.
 */
export async function getUsuarios() {
  const res = await fetch(`${API_URL}/usuarios`);
  // Si la respuesta no es OK, `res.json()` podría fallar o devolver un error del servidor.
  // En un entorno de producción, se podría agregar un manejo de errores más robusto aquí.
  return res.json();
}

/**
 * Obtiene un usuario específico por su ID.
 * @param {number} id - El ID del usuario.
 * @returns {Promise<Object>} Una promesa que resuelve con el objeto de usuario.
 */
export async function getUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}`);
  return res.json();
}

/**
 * Obtiene la próxima dirección IP disponible para asignar a un nuevo usuario.
 * @returns {Promise<Object>} Una promesa que resuelve con un objeto que contiene la IP asignada.
 */
export async function getProximaIp() {
  const res = await fetch(`${API_URL}/usuarios/proxima-ip`);
  return res.json();
}

/**
 * Crea un nuevo usuario enviando los datos a la API.
 * @param {Object} data - Los datos del nuevo usuario (nombre, email, etc.).
 * @returns {Promise<Object>} Una promesa que resuelve con el objeto del usuario creado.
 */
export async function crearUsuario(data) {
  const res = await fetch(`${API_URL}/usuarios`, {
    method: "POST", // Método HTTP POST para crear recursos.
    headers: { "Content-Type": "application/json" }, // Indica que el cuerpo de la petición es JSON.
    body: JSON.stringify(data), // Convierte el objeto de datos a una cadena JSON.
  });
  // Se podría agregar `if (!res.ok) throw new Error(res.statusText)` para un mejor manejo de errores.
  return res.json();
}

/**
 * Actualiza un usuario existente por su ID.
 * @param {number} id - El ID del usuario a actualizar.
 * @param {Object} data - Los datos a actualizar para el usuario.
 * @returns {Promise<Object>} Una promesa que resuelve con el objeto del usuario actualizado.
 */
export async function actualizarUsuario(id, data) {
  const res = await fetch(`${API_URL}/usuarios/${id}`, {
    method: "PUT", // Método HTTP PUT para actualizar recursos existentes.
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(data),
  });
  return res.json();
}

/**
 * Elimina un usuario por su ID.
 * @param {number} id - El ID del usuario a eliminar.
 * @returns {Promise<Object>} Una promesa que resuelve con un mensaje de confirmación.
 */
export async function eliminarUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}`, { method: "DELETE" }); // Método HTTP DELETE.
  return res.json();
}

/**
 * Activa o desactiva un usuario por su ID.
 * @param {number} id - El ID del usuario a modificar.
 * @returns {Promise<Object>} Una promesa que resuelve con el objeto del usuario modificado.
 */
export async function toggleUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}/toggle`, {
    method: "POST",
  }); // Usa POST para una acción que cambia estado.
  return res.json();
}

/**
 * Obtiene las claves (privada y pública) de un usuario específico.
 * Nota: En un sistema real, el acceso a la clave privada debería ser extremadamente restringido.
 * @param {number} id - El ID del usuario.
 * @returns {Promise<Object>} Una promesa que resuelve con un objeto que contiene las claves.
 */
export async function getClavesUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}/claves`);
  return res.json();
}

/**
 * Descarga el archivo de configuración WireGuard (.conf) para un usuario.
 * Abre una nueva ventana/pestaña del navegador para iniciar la descarga.
 * @param {number} id - El ID del usuario para el cual descargar la configuración.
 */
export async function descargarConfig(id) {
  window.open(`${API_URL}/usuarios/${id}/config`, "_blank"); // Abre una nueva ventana para la descarga.
}

/**
 * Obtiene todas las configuraciones generales del servidor.
 * @returns {Promise<Array>} Una promesa que resuelve con un array de objetos de configuración.
 */
export async function getConfigs() {
  const res = await fetch(`${API_URL}/configuraciones`);
  return res.json();
}

/**
 * Actualiza una configuración general del servidor.
 * @param {string} clave - La clave de la configuración a actualizar (ej. 'endpoint').
 * @param {string} valor - El nuevo valor para la configuración.
 * @returns {Promise<Object>} Una promesa que resuelve con el objeto de configuración actualizado.
 */
export async function updateConfig(clave, valor) {
  const res = await fetch(`${API_URL}/configuraciones/${clave}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ valor }), // El cuerpo contiene un objeto con la propiedad 'valor'.
  });
  return res.json();
}

/**
 * Obtiene un número limitado de logs de actividad.
 * @param {number} [limit=100] - El número máximo de logs a recuperar.
 * @returns {Promise<Array>} Una promesa que resuelve con un array de objetos de log.
 */
export async function getLogs(limit = 100) {
  const res = await fetch(`${API_URL}/logs?limit=${limit}`);
  return res.json();
}

/**
 * Obtiene logs de actividad de un período reciente.
 * @param {number} [dias=7] - El número de días hacia atrás desde el cual recuperar los logs.
 * @returns {Promise<Array>} Una promesa que resuelve con un array de objetos de log.
 */
export async function getLogsRecientes(dias = 7) {
  const res = await fetch(`${API_URL}/logs/recientes?dias=${dias}`);
  return res.json();
}
