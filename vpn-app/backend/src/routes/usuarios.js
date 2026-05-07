const express = require('express');
const router = express.Router();
const Usuario = require('../models/Usuario');
const Log = require('../models/Log');
const { addPeer, removePeer } = require('../services/wireguardService');

// Genera un par de claves Curve25519 (X25519) compatible con WireGuard.
// Usa tweetnacl — no requiere que `wg` esté instalado en el servidor local.
function generarClavesWireGuard() {
  const nacl = require('tweetnacl');
  const kp = nacl.box.keyPair();  // Curve25519 DH — mismo algoritmo que WireGuard
  const privateKey = Buffer.from(kp.secretKey).toString('base64');
  const publicKey  = Buffer.from(kp.publicKey).toString('base64');
  return { privateKey, publicKey };
}

router.get('/', async (req, res) => {
  try {
    const usuarios = await Usuario.getAll();
    res.json(Array.isArray(usuarios) ? usuarios : []);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/activos', async (req, res) => {
  try {
    const usuarios = await Usuario.getActivos();
    res.json(usuarios);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/inactivos', async (req, res) => {
  try {
    const usuarios = await Usuario.getInactivos();
    res.json(usuarios);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/proxima-ip', async (req, res) => {
  try {
    const nextIp = await Usuario.getNextIp();
    res.json({ ip_asignada: nextIp });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:id/claves', async (req, res) => {
  try {
    const usuario = await Usuario.getById(req.params.id);
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json({
      clave_privada: usuario.clave_privada,
      clave_publica: usuario.clave_publica
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:id/config', async (req, res) => {
  try {
    const usuario = await Usuario.getById(req.params.id);
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const Configuracion = require('../models/Configuracion');
    const endpoint = await Configuracion.getByClave('endpoint');
    const serverPublicKey = await Configuracion.getByClave('server_public_key');
    const dns = await Configuracion.getByClave('dns');
    const keepalive = await Configuracion.getByClave('persistent_keepalive');

    const config = `[Interface]
PrivateKey = ${usuario.clave_privada}
Address = ${usuario.ip_asignada}/24
DNS = ${dns?.valor || '1.1.1.1, 8.8.8.8'}

[Peer]
PublicKey = ${serverPublicKey?.valor || 'fZrG0x6jFTRM/wwOasP7+ww4uc1bHnKJ6Zhnx6ZB8gk='}
Endpoint = ${endpoint?.valor || '161.153.28.223:51820'}
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = ${keepalive?.valor || '25'}
`;

    res.set('Content-Type', 'text/plain');
    res.set('Content-Disposition', `attachment; filename=${usuario.nombre.replace(/\s+/g, '_')}.conf`);
    res.send(config);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const usuario = await Usuario.getById(req.params.id);
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }
    res.json(usuario);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const { nombre, usuario, email, notas, clave_privada, clave_publica, sistema_operativo } = req.body;

    if (!nombre) {
      return res.status(400).json({ error: 'El nombre es requerido' });
    }

    const ip_asignada = await Usuario.getNextIp();

    let privateKey = null;
    let publicKey = null;

    if (clave_publica && clave_publica.trim().length >= 40) {
      // Modo dispositivo: el usuario proporciona su propia clave pública
      // (generada por la app WireGuard en Windows/Android/iOS)
      publicKey = clave_publica.trim();
      privateKey = clave_privada ? clave_privada.trim() : '[GENERADA EN EL DISPOSITIVO]'; // Evita el constraint NOT NULL
    } else {
      // Modo automático: el backend genera el par de claves
      const claves = generarClavesWireGuard();
      privateKey = claves.privateKey;
      publicKey = claves.publicKey;
    }

    let nombreUsuario = usuario;
    if (!nombreUsuario) {
      const partes = nombre.trim().split(' ');
      const nombreBase = partes[0].toLowerCase();
      const apellido = partes.length > 1 ? partes[partes.length - 1].charAt(0).toLowerCase() : '';
      nombreUsuario = nombreBase + apellido;
    }

    const usuarioCreado = await Usuario.create({
      nombre,
      usuario: nombreUsuario,
      email,
      ip_asignada,
      clave_privada: privateKey,
      clave_publica: publicKey,
      activo: 1,
      notas,
      sistema_operativo: sistema_operativo || 'linux'
    });

    // ── Inyectar peer en WireGuard (operación no bloqueante) ──
    try {
      await addPeer(publicKey, ip_asignada);
      await Log.logSistema('WG_PEER_AÑADIDO', `Peer ${publicKey.substring(0, 16)}... inyectado en WireGuard para ${nombre} (${ip_asignada})`);
    } catch (wgErr) {
      // No bloqueamos la creación del usuario si el servidor WireGuard falla
      console.warn('⚠ No se pudo inyectar el peer en WireGuard:', wgErr.message);
      await Log.logSistema('WG_PEER_ERROR', `Error al inyectar peer para ${nombre}: ${wgErr.message}`);
    }

    await Log.logSistema('CREAR_USUARIO', 'Usuario ' + nombre + ' (' + nombreUsuario + ') creado con IP ' + ip_asignada);
    await Log.create(usuarioCreado.id, 'CREADO', 'IP: ' + ip_asignada + ', Sistema: ' + (sistema_operativo || 'linux'));

    res.status(201).json(usuarioCreado);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const usuario = await Usuario.getById(req.params.id);
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const { nombre, usuario: nombreUsuario, email, ip_asignada, activo, notas, sistema_operativo } = req.body;
    const actualizado = await Usuario.update(req.params.id, { 
      nombre, 
      usuario: nombreUsuario,
      email, 
      ip_asignada,
      activo, 
      notas,
      sistema_operativo
    });

    await Log.create(usuario.id, 'ACTUALIZADO', 'Campos: ' + Object.keys(req.body).join(', '));

    res.json(actualizado);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const usuario = await Usuario.getById(req.params.id);
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    await Usuario.delete(req.params.id);
    await Log.create(usuario.id, 'ELIMINADO', 'IP: ' + usuario.ip_asignada);

    // ── Remover peer de WireGuard ──
    if (usuario.clave_publica) {
      try {
        await removePeer(usuario.clave_publica);
        await Log.logSistema('WG_PEER_ELIMINADO', `Peer de ${usuario.nombre} (${usuario.ip_asignada}) removido de WireGuard`);
      } catch (wgErr) {
        console.warn('⚠ No se pudo remover el peer de WireGuard:', wgErr.message);
        await Log.logSistema('WG_PEER_ERROR', `Error al remover peer de ${usuario.nombre}: ${wgErr.message}`);
      }
    }

    res.json({ message: 'Usuario eliminado', usuario });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/:id/toggle', async (req, res) => {
  try {
    const usuario = await Usuario.getById(req.params.id);
    if (!usuario) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const nuevoEstado = usuario.activo === 1 ? 0 : 1;
    const actualizado = await Usuario.update(req.params.id, { activo: nuevoEstado });

    await Log.create(usuario.id, nuevoEstado === 1 ? 'ACTIVADO' : 'DESACTIVADO', '');

    // ── Sincronizar estado con WireGuard ──
    if (usuario.clave_publica) {
      try {
        if (nuevoEstado === 0) {
          // Desactivar = remover peer de WireGuard (no puede conectarse)
          await removePeer(usuario.clave_publica);
          await Log.logSistema('WG_PEER_DESACTIVADO', `Peer de ${usuario.nombre} removido de WireGuard`);
        } else {
          // Activar = re-agregar peer a WireGuard
          await addPeer(usuario.clave_publica, usuario.ip_asignada);
          await Log.logSistema('WG_PEER_ACTIVADO', `Peer de ${usuario.nombre} re-añadido a WireGuard (${usuario.ip_asignada})`);
        }
      } catch (wgErr) {
        console.warn('⚠ No se pudo sincronizar toggle con WireGuard:', wgErr.message);
        await Log.logSistema('WG_PEER_ERROR', `Error en toggle WireGuard para ${usuario.nombre}: ${wgErr.message}`);
      }
    }

    res.json(actualizado);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
