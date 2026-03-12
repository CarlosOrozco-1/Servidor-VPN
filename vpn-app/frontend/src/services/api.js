const API_URL = '/api'

export async function getUsuarios() {
  const res = await fetch(`${API_URL}/usuarios`)
  return res.json()
}

export async function getUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}`)
  return res.json()
}

export async function getProximaIp() {
  const res = await fetch(`${API_URL}/usuarios/proxima-ip`)
  return res.json()
}

export async function crearUsuario(data) {
  const res = await fetch(`${API_URL}/usuarios`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  return res.json()
}

export async function actualizarUsuario(id, data) {
  const res = await fetch(`${API_URL}/usuarios/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  return res.json()
}

export async function eliminarUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}`, { method: 'DELETE' })
  return res.json()
}

export async function toggleUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}/toggle`, { method: 'POST' })
  return res.json()
}

export async function getClavesUsuario(id) {
  const res = await fetch(`${API_URL}/usuarios/${id}/claves`)
  return res.json()
}

export async function descargarConfig(id) {
  window.open(`${API_URL}/usuarios/${id}/config`, '_blank')
}

export async function getConfigs() {
  const res = await fetch(`${API_URL}/configuraciones`)
  return res.json()
}

export async function updateConfig(clave, valor) {
  const res = await fetch(`${API_URL}/configuraciones/${clave}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ valor })
  })
  return res.json()
}

export async function getLogs(limit = 100) {
  const res = await fetch(`${API_URL}/logs?limit=${limit}`)
  return res.json()
}

export async function getLogsRecientes(dias = 7) {
  const res = await fetch(`${API_URL}/logs/recientes?dias=${dias}`)
  return res.json()
}
