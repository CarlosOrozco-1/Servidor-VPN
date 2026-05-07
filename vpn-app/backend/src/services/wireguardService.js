/**
 * @file wireguardService.js
 * @description Servicio SSH para consultar Y gestionar WireGuard en el servidor remoto.
 * Permite obtener estado, agregar/remover peers, tráfico en tiempo real y captura de paquetes.
 */

const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');

// La llave está en: repo/notas-internas/ssh-key-2026-02-23.key
// __dirname = repo/vpn-app/backend/src/services → 4 niveles arriba = repo root
const REPO_ROOT = path.resolve(__dirname, '../../../..'); // → Llaves-ubuntu-server-VPN/
const SSH_KEY_RELATIVE = process.env.WG_SSH_KEY_PATH || 'notas-internas/ssh-key-2026-02-23.key'; //Ruta relativa desde la raíz del repositorio para la llave privada del servidor WG
const SSH_KEY_PATH = path.join(REPO_ROOT, SSH_KEY_RELATIVE);

const SSH_CONFIG = {
  host: process.env.WG_SSH_HOST || '161.153.28.223', //IP del servidor WG
  port: parseInt(process.env.WG_SSH_PORT) || 22, //Puerto del servidor WG
  username: process.env.WG_SSH_USER || 'ubuntu', //Usuario del servidor WG
  readyTimeout: 10000, //Tiempo de espera para la conexión SSH
  timeout: 15000, //Tiempo de espera para la ejecución de comandos
};

const WG_INTERFACE = process.env.WG_INTERFACE || 'wg0'; //Nombre de la interfaz WireGuard

/**
 * Ejecuta un comando en el servidor remoto vía SSH.
 * @param {string} command - Comando a ejecutar
 * @returns {Promise<string>} - Salida estándar del comando
 */
function runRemoteCommand(command) {
  return new Promise((resolve, reject) => {
    const conn = new Client();

    let privateKey;
    try {
      privateKey = fs.readFileSync(SSH_KEY_PATH);
    } catch (err) {
      return reject(new Error(`No se pudo leer la llave SSH en: ${SSH_KEY_PATH} — ${err.message}`));
    }

    conn.on('ready', () => {
      conn.exec(command, (err, stream) => {
        if (err) {
          conn.end();
          return reject(err);
        }

        let stdout = '';
        let stderr = '';

        stream.on('data', (data) => { stdout += data.toString(); });
        stream.stderr.on('data', (data) => { stderr += data.toString(); });

        stream.on('close', (code) => {
          conn.end();
          if (code !== 0 && stderr) {
            // Algunos comandos de wg retornan código != 0 pero son válidos
            // solo rechazamos si no hay stdout útil
            if (!stdout.trim()) {
              return reject(new Error(`Comando falló (code ${code}): ${stderr.trim()}`));
            }
          }
          resolve(stdout);
        });
      });
    });

    conn.on('error', (err) => {
      reject(new Error(`Error de conexión SSH: ${err.message}`));
    });

    conn.connect({ ...SSH_CONFIG, privateKey });
  });
}

/**
 * Parsea la salida de `wg show <iface> dump` (formato TSV).
 * Primera línea: datos de la interfaz
 * Siguientes líneas: datos de cada peer
 */
function parseDump(dump) {
  const lines = dump.trim().split('\n').filter(Boolean);
  if (lines.length === 0) return { interface: null, peers: [] };

  // Primera línea = interfaz: private_key, public_key, listen_port, fwmark
  const [ifacePrivKey, ifacePubKey, listenPort] = lines[0].split('\t');

  const peers = [];
  const now = Math.floor(Date.now() / 1000);

  for (let i = 1; i < lines.length; i++) {
    const [pubKey, psk, endpoint, allowedIps, lastHandshake, rxBytes, txBytes, keepalive] =
      lines[i].split('\t');

    const lastHs = parseInt(lastHandshake) || 0;
    const ago = lastHs > 0 ? now - lastHs : null;
    const isActive = ago !== null && ago < 180; // < 3 minutos = activo

    peers.push({
      pubKey,
      endpoint: endpoint === '(none)' ? null : endpoint,
      allowedIps,
      lastHandshake: lastHs > 0 ? lastHs : null,
      lastHandshakeAgo: ago,
      isActive,
      rxBytes: parseInt(rxBytes) || 0,
      txBytes: parseInt(txBytes) || 0,
      keepalive: keepalive === 'off' ? null : parseInt(keepalive),
    });
  }

  return {
    interface: {
      publicKey: ifacePubKey,
      listenPort: parseInt(listenPort),
    },
    peers,
  };
}

/**
 * Obtiene el estado completo de la interfaz WireGuard y sus peers.
 * @returns {Promise<Object>}
 */
async function getWireGuardStatus() {
  // 1. Verificar que la interfaz existe
  let ifaceActive = false;
  let ifaceIp = null;
  let linkState = null;

  try {
    const ipOutput = await runRemoteCommand(
      `ip addr show ${WG_INTERFACE} 2>/dev/null && echo "__OK__" || echo "__INACTIVE__"`
    );
    ifaceActive = ipOutput.includes('__OK__') && !ipOutput.includes('__INACTIVE__');
    if (ifaceActive) {
      const ipMatch = ipOutput.match(/inet\s+([\d./]+)/);
      ifaceIp = ipMatch ? ipMatch[1] : null;
      const stateMatch = ipOutput.match(/state\s+(\w+)/i);
      linkState = stateMatch ? stateMatch[1] : 'UNKNOWN';
    }
  } catch {
    ifaceActive = false;
  }

  // 2. Obtener dump de peers (requiere sudo)
  let dumpData = { interface: null, peers: [] };
  let listenPort = null;
  let serverPublicKey = null;

  if (ifaceActive) {
    try {
      const dump = await runRemoteCommand(`sudo wg show ${WG_INTERFACE} dump`);
      dumpData = parseDump(dump);
      listenPort = dumpData.interface?.listenPort || null;
      serverPublicKey = dumpData.interface?.publicKey || null;
    } catch (err) {
      console.warn('wireguardService: no se pudo obtener dump:', err.message);
    }
  }

  // 3. Info del sistema
  let systemInfo = {};
  try {
    const sysOutput = await runRemoteCommand(
      "hostname && uptime -p && cat /proc/loadavg | awk '{print $1,$2,$3}' && free -h | awk '/^Mem:/{print $3\"/\"$2}'"
    );
    const lines = sysOutput.trim().split('\n');
    systemInfo = {
      hostname: lines[0] || 'unknown',
      uptime: lines[1] || '',
      loadAvg: lines[2] || '',
      memory: lines[3] || '',
    };
  } catch {
    systemInfo = { hostname: 'N/A', uptime: 'N/A', loadAvg: 'N/A', memory: 'N/A' };
  }

  const now = Math.floor(Date.now() / 1000);
  const activePeers = dumpData.peers.filter((p) => p.isActive).length;
  const totalRx = dumpData.peers.reduce((s, p) => s + p.rxBytes, 0);
  const totalTx = dumpData.peers.reduce((s, p) => s + p.txBytes, 0);

  return {
    timestamp: new Date().toISOString(),
    server: {
      active: ifaceActive,
      interface: WG_INTERFACE,
      ipAddress: ifaceIp,
      linkState,
      listenPort,
      publicKey: serverPublicKey,
      host: SSH_CONFIG.host,
    },
    system: systemInfo,
    summary: {
      totalPeers: dumpData.peers.length,
      activePeers,
      inactivePeers: dumpData.peers.length - activePeers,
      totalRxBytes: totalRx,
      totalTxBytes: totalTx,
    },
    peers: dumpData.peers,
  };
}

/**
 * Obtiene solo el resumen de tráfico y handshakes (más rápido, sin info de sistema).
 */
async function getPeerStats() {
  try {
    const dump = await runRemoteCommand(`sudo wg show ${WG_INTERFACE} dump`);
    const { peers } = parseDump(dump);
    return { ok: true, peers };
  } catch (err) {
    return { ok: false, error: err.message, peers: [] };
  }
}

/**
 * Verifica la conectividad con el servidor SSH.
 */
async function pingServer() {
  try {
    const result = await runRemoteCommand('echo pong');
    return { ok: result.trim() === 'pong', message: 'Servidor accesible' };
  } catch (err) {
    return { ok: false, message: err.message };
  }
}

/**
 * Agrega un nuevo peer al servidor WireGuard en tiempo real (sin reiniciar).
 * Persiste el cambio con wg-quick save.
 *
 * @param {string} publicKey   - Clave pública del cliente WireGuard
 * @param {string} allowedIp  - IP asignada al peer (ej: '10.6.0.11' o '10.6.0.11/32')
 * @param {number} keepalive  - PersistentKeepalive en segundos (default: 25)
 * @returns {Promise<void>}
 */
async function addPeer(publicKey, allowedIp, keepalive = 25) {
  // Normalizar IP (asegurarse de que tenga /32)
  const ip = allowedIp.includes('/') ? allowedIp : `${allowedIp}/32`;

  // Validación básica de clave pública WireGuard (44 chars base64)
  if (!publicKey || publicKey.length < 40) {
    throw new Error('Clave pública WireGuard inválida.');
  }

  // 1. Agregar peer en vivo (efecto inmediato, sin reiniciar WireGuard)
  const addCmd = `sudo wg set ${WG_INTERFACE} peer ${publicKey} allowed-ips ${ip} persistent-keepalive ${keepalive}`;
  await runRemoteCommand(addCmd);

  // 2. Persistir la configuración actual al archivo wg0.conf
  await runRemoteCommand(`sudo wg-quick save ${WG_INTERFACE}`);
}

/**
 * Elimina un peer del servidor WireGuard en tiempo real y persiste el cambio.
 *
 * @param {string} publicKey - Clave pública del peer a eliminar
 * @returns {Promise<void>}
 */
async function removePeer(publicKey) {
  if (!publicKey || publicKey.length < 40) {
    throw new Error('Clave pública WireGuard inválida.');
  }

  // Verificar si el peer existe antes de intentar eliminar
  const peers = await runRemoteCommand(`sudo wg show ${WG_INTERFACE} peers`);
  if (!peers.includes(publicKey)) {
    // Peer no existe en el servidor, no hay nada que eliminar
    console.warn(`wireguardService.removePeer: peer no encontrado en el servidor (${publicKey.substring(0, 16)}...)`);
    return;
  }

  await runRemoteCommand(`sudo wg set ${WG_INTERFACE} peer ${publicKey} remove`);
  await runRemoteCommand(`sudo wg-quick save ${WG_INTERFACE}`);
}

// ── Estado para cálculo de tasas de tráfico (delta entre polls) ──
let _transferSnapshot = null;
let _snapshotTime = null;

/**
 * Calcula la tasa de transferencia en tiempo real por peer (KB/s).
 * Hace un diff entre el snapshot anterior y el actual de `wg show transfer`.
 */
async function getTrafficRates() {
  const now = Date.now();
  try {
    const dump = await runRemoteCommand(`sudo wg show ${WG_INTERFACE} dump`);
    const { peers: currentPeers } = parseDump(dump);

    let rates = currentPeers.map(peer => ({ ...peer, rxRate: 0, txRate: 0 }));

    if (_transferSnapshot && _snapshotTime) {
      const dt = (now - _snapshotTime) / 1000; // segundos
      if (dt >= 1) {
        rates = currentPeers.map(peer => {
          const prev = _transferSnapshot.find(p => p.pubKey === peer.pubKey);
          if (prev) {
            return {
              ...peer,
              rxRate: Math.round(Math.max(0, peer.rxBytes - prev.rxBytes) / dt),
              txRate: Math.round(Math.max(0, peer.txBytes - prev.txBytes) / dt),
            };
          }
          return { ...peer, rxRate: 0, txRate: 0 };
        });
      }
    }

    _transferSnapshot = currentPeers;
    _snapshotTime = now;

    return { ok: true, rates, timestamp: new Date().toISOString() };
  } catch (err) {
    return { ok: false, error: err.message, rates: [] };
  }
}

/**
 * Captura paquetes UDP en el puerto WireGuard usando tcpdump (SSH + sudo).
 * Timeout de 4 segundos. Intenta la interfaz configurada, luego 'any'.
 *
 * @param {number} count - Máx paquetes a capturar (default 20)
 */
async function getPacketCapture(count = 20) {
  const netIface = process.env.WG_NET_IFACE || 'ens3';
  const wgPort  = process.env.WG_LISTEN_PORT || '51820';

  // Intento 1: interfaz configurada. Intento 2: 'any'. Siempre con timeout
  const cmd = [
    `timeout 4 sudo tcpdump -i ${netIface} udp port ${wgPort} -c ${count} -n -tt 2>&1`,
    `timeout 4 sudo tcpdump -i any      udp port ${wgPort} -c ${count} -n -tt 2>&1`,
  ].join(' || ');

  try {
    const output = await runRemoteCommand(cmd);
    const lines  = (output || '').trim().split('\n');

    // Líneas de paquetes: empiezan con timestamp numérico (ej: 1746283200.123456)
    const packetLines = lines.filter(l => /^\d{9,}\.\d+\s+IP/.test(l));
    // Líneas de estadísticas al final
    const statsLine   = lines.filter(l => /captured|received|dropped/.test(l)).join(' | ');

    const packets = packetLines.map((line, i) => {
      // Formato: "1746283200.123456 IP src.port > dst.port: UDP, length N"
      const m = line.match(/^(\d+\.\d+)\s+IP\s+([\d.]+)\.(\d+)\s+>\s+([\d.]+)\.(\d+)/);
      return {
        id: `${Date.now()}-${i}`,
        ts: m ? parseFloat(m[1]) : 0,
        time: m ? new Date(parseFloat(m[1]) * 1000).toLocaleTimeString() : '',
        src: m ? `${m[2]}:${m[3]}` : '',
        dst: m ? `${m[4]}:${m[5]}` : '',
        raw: line.trim(),
      };
    });

    return {
      ok: true,
      packets,
      stats: statsLine,
      iface: netIface,
      port: wgPort,
      timestamp: new Date().toISOString(),
    };
  } catch (err) {
    return { ok: false, error: err.message, packets: [], timestamp: new Date().toISOString() };
  }
}

module.exports = {
  getWireGuardStatus,
  getPeerStats,
  pingServer,
  addPeer,
  removePeer,
  getTrafficRates,
  getPacketCapture,
};

