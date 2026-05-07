/**
 * @file routes/wireguard.js
 * @description Endpoints REST para consultar el estado en tiempo real del servidor WireGuard.
 * Usa wireguardService para conectarse vía SSH al servidor.
 */

const express = require('express');
const router = express.Router();
const {
  getWireGuardStatus, getPeerStats, pingServer,
  getTrafficRates, getPacketCapture,
} = require('../services/wireguardService');

// Caché simple en memoria para evitar SSH en cada petición
let statusCache = null;
let cacheTimestamp = 0;
const CACHE_TTL_MS = 8000;

function isCacheValid() {
  return statusCache !== null && (Date.now() - cacheTimestamp) < CACHE_TTL_MS;
}

// Guard para evitar capturas simultáneas de tcpdump
let captureInProgress = false;

/**
 * GET /api/wireguard/status
 * Retorna el estado completo: interfaz, peers, sistema, resumen de tráfico.
 * Usa caché de 8s para no saturar de conexiones SSH.
 */
router.get('/status', async (req, res) => {
  const forceRefresh = req.query.refresh === 'true';

  if (!forceRefresh && isCacheValid()) {
    return res.json({ ...statusCache, cached: true });
  }

  try {
    const status = await getWireGuardStatus();
    statusCache = status;
    cacheTimestamp = Date.now();
    res.json({ ...status, cached: false });
  } catch (err) {
    console.error('wireguard/status error:', err.message);
    res.status(503).json({
      error: 'No se pudo conectar al servidor WireGuard',
      message: err.message,
      timestamp: new Date().toISOString(),
    });
  }
});

/**
 * GET /api/wireguard/peers
 * Retorna solo la lista de peers con su estado actual (más ligero).
 */
router.get('/peers', async (req, res) => {
  const forceRefresh = req.query.refresh === 'true';
  if (!forceRefresh && isCacheValid() && statusCache?.peers) {
    return res.json({ peers: statusCache.peers, cached: true });
  }

  try {
    const result = await getPeerStats();
    if (!result.ok) {
      return res.status(503).json({ error: result.error });
    }
    res.json({ peers: result.peers, cached: false });
  } catch (err) {
    res.status(503).json({ error: err.message });
  }
});

/**
 * GET /api/wireguard/ping
 * Verifica si el servidor SSH es accesible.
 */
router.get('/ping', async (req, res) => {
  try {
    const result = await pingServer();
    res.json(result);
  } catch (err) {
    res.status(503).json({ ok: false, message: err.message });
  }
});

/**
 * GET /api/wireguard/traffic
 * Tasas de transferencia en tiempo real por peer (bytes/s).
 * Calcula deltas entre polls consecutivos.
 */
router.get('/traffic', async (req, res) => {
  try {
    const result = await getTrafficRates();
    res.json(result);
  } catch (err) {
    res.status(503).json({ ok: false, error: err.message });
  }
});

/**
 * GET /api/wireguard/packets
 * Captura de paquetes UDP en el puerto WireGuard via tcpdump (SSH).
 * Timeout de 4s. Si ya hay una captura en progreso, retorna busy:true.
 */
router.get('/packets', async (req, res) => {
  if (captureInProgress) {
    return res.json({ ok: true, busy: true, packets: [], message: 'Captura en progreso...' });
  }
  captureInProgress = true;
  try {
    const result = await getPacketCapture(20);
    res.json(result);
  } catch (err) {
    res.status(503).json({ ok: false, error: err.message });
  } finally {
    captureInProgress = false;
  }
});

module.exports = router;
