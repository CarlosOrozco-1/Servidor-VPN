const { getDbAsync, saveDb } = require('../models/db');

class Usuario {
  static async getAll() {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM usuarios ORDER BY ip_asignada');
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
  }

  static async getById(id) {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM usuarios WHERE id = ?');
    stmt.bind([id]);
    let result = null;
    if (stmt.step()) {
      result = stmt.getAsObject();
    }
    stmt.free();
    return result;
  }

  static async getByIp(ip) {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM usuarios WHERE ip_asignada = ?');
    stmt.bind([ip]);
    let result = null;
    if (stmt.step()) {
      result = stmt.getAsObject();
    }
    stmt.free();
    return result;
  }

  static async create(data) {
    const db = await getDbAsync();
    db.run(
      'INSERT INTO usuarios (nombre, usuario, email, ip_asignada, clave_privada, clave_publica, activo, notas, sistema_operativo) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [data.nombre, data.usuario || null, data.email || null, data.ip_asignada, data.clave_privada, data.clave_publica, data.activo !== undefined ? data.activo : 1, data.notas || null, data.sistema_operativo || 'linux']
    );
    const lastId = db.exec('SELECT last_insert_rowid() as id')[0].values[0][0];
    saveDb();
    return await this.getById(lastId);
  }

  static async update(id, data) {
    const db = await getDbAsync();
    const fields = [];
    const values = [];

    if (data.nombre !== undefined) { fields.push('nombre = ?'); values.push(data.nombre); }
    if (data.usuario !== undefined) { fields.push('usuario = ?'); values.push(data.usuario); }
    if (data.email !== undefined) { fields.push('email = ?'); values.push(data.email); }
    if (data.ip_asignada !== undefined) { fields.push('ip_asignada = ?'); values.push(data.ip_asignada); }
    if (data.activo !== undefined) { fields.push('activo = ?'); values.push(data.activo); }
    if (data.notas !== undefined) { fields.push('notas = ?'); values.push(data.notas); }
    if (data.sistema_operativo !== undefined) { fields.push('sistema_operativo = ?'); values.push(data.sistema_operativo); }

    if (fields.length === 0) return await this.getById(id);

    fields.push('fecha_actualizacion = CURRENT_TIMESTAMP');
    values.push(id);

    db.run('UPDATE usuarios SET ' + fields.join(', ') + ' WHERE id = ?', values);
    saveDb();
    return await this.getById(id);
  }

  static async delete(id) {
    const db = await getDbAsync();
    const usuario = await this.getById(id);
    if (!usuario) return false;
    db.run('DELETE FROM usuarios WHERE id = ?', [id]);
    saveDb();
    return true;
  }

  static async getNextIp() {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT ip_asignada FROM usuarios ORDER BY ip_asignada DESC LIMIT 1');
    let lastIp = null;
    if (stmt.step()) {
      lastIp = stmt.getAsObject().ip_asignada;
    }
    stmt.free();
    if (!lastIp) return '10.6.0.2';
    const parts = lastIp.split('.');
    const lastOctet = parseInt(parts[3]);
    return '10.6.0.' + (lastOctet + 1);
  }

  static async getActivos() {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM usuarios WHERE activo = 1 ORDER BY ip_asignada');
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
  }

  static async getInactivos() {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM usuarios WHERE activo = 0 ORDER BY ip_asignada');
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
  }
}

module.exports = Usuario;
