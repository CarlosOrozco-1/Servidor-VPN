const { getDbAsync, saveDb } = require('../models/db');

class Log {
  static async getAll(limit = 100) {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT l.*, u.nombre as usuario_nombre FROM logs l LEFT JOIN usuarios u ON l.usuario_id = u.id ORDER BY l.fecha DESC LIMIT ?');
    stmt.bind([limit]);
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
  }

  static async getByUsuario(usuarioId) {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM logs WHERE usuario_id = ? ORDER BY fecha DESC');
    stmt.bind([usuarioId]);
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
  }

  static async create(usuarioId, accion, detalles = null) {
    const db = await getDbAsync();
    db.run('INSERT INTO logs (usuario_id, accion, detalles) VALUES (?, ?, ?)', [usuarioId, accion, detalles]);
    saveDb();
  }

  static async logSistema(accion, detalles = null) {
    const db = await getDbAsync();
    db.run('INSERT INTO logs (usuario_id, accion, detalles) VALUES (NULL, ?, ?)', [accion, detalles]);
    saveDb();
  }

  static async getRecientes(dias = 7) {
    const db = await getDbAsync();
    const stmt = db.prepare("SELECT l.*, u.nombre as usuario_nombre FROM logs l LEFT JOIN usuarios u ON l.usuario_id = u.id WHERE l.fecha >= datetime('now', '- ' || ? || ' days') ORDER BY l.fecha DESC");
    stmt.bind([dias]);
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
  }
}

module.exports = Log;
