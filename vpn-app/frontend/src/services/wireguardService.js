/**
 * @file services/wireguardService.js
 * @description Llamadas a la API del backend para obtener estado de WireGuard.
 */

const API_BASE = import.meta.env.VITE_API_URL || '/api'; //identificación de la URL del backend

/**
 * Formatea bytes a unidad legible.
 */
export function formatBytes(bytes) {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`;
}

/**
 * Formatea segundos transcurridos a texto legible.
 */
export function formatTimeAgo(seconds) {
  if (seconds === null || seconds === undefined) return 'Nunca';
  if (seconds < 60) return `${seconds}s`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ${seconds % 60}s`;
  if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ${Math.floor((seconds % 3600) / 60)}m`;
  return `${Math.floor(seconds / 86400)}d ${Math.floor((seconds % 86400) / 3600)}h`;
}

/**
 * Obtiene el estado completo del servidor WireGuard.
 * @param {boolean} forceRefresh - Saltear la caché del backend
 */
export async function fetchWireguardStatus(forceRefresh = false) {
  const url = `${API_BASE}/wireguard/status${forceRefresh ? '?refresh=true' : ''}`;
  const res = await fetch(url);
  if (!res.ok) {
    const err = await res.json().catch(() => ({ message: res.statusText }));
    throw new Error(err.message || 'Error al consultar el servidor');
  }
  return res.json();
}

/**
 * Verifica la conectividad SSH con el servidor.
 */
export async function pingWireguardServer() {
  const res = await fetch(`${API_BASE}/wireguard/ping`);
  return res.json();
}

/**
 * Obtiene tasas de transferencia en tiempo real por peer (delta entre polls).
 */
export async function fetchTrafficRates() {
  const res = await fetch(`${API_BASE}/wireguard/traffic`);
  if (!res.ok) throw new Error('Error al obtener tasas de tráfico');
  return res.json();
}

/**
 * Obtiene captura de paquetes UDP del puerto WireGuard (tcpdump).
 */
export async function fetchPacketCapture() {
  const res = await fetch(`${API_BASE}/wireguard/packets`);
  if (!res.ok) throw new Error('Error al obtener captura de paquetes');
  return res.json();
}
