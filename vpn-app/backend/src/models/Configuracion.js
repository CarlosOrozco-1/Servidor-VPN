const { getDbAsync, saveDb } = require('../models/db');

class Configuracion {
  static async getAll() {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM configuraciones ORDER BY clave');
    const results = [];
    while (stmt.step()) {
      results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
  }

  static async getByClave(clave) {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT * FROM configuraciones WHERE clave = ?');
    stmt.bind([clave]);
    let result = null;
    if (stmt.step()) {
      result = stmt.getAsObject();
    }
    stmt.free();
    return result;
  }

  static async update(clave, valor) {
    const db = await getDbAsync();
    db.run('UPDATE configuraciones SET valor = ?, fecha_actualizacion = CURRENT_TIMESTAMP WHERE clave = ?', [valor, clave]);
    saveDb();
    return await this.getByClave(clave);
  }

  static async getEndpoint() { return (await this.getByClave('endpoint'))?.valor; }
  static async getServerPublicKey() { return (await this.getByClave('server_public_key'))?.valor; }
  static async getSubnet() { return (await this.getByClave('subnet'))?.valor; }
  static async getDns() { return (await this.getByClave('dns'))?.valor; }
  static async getPersistentKeepalive() { return (await this.getByClave('persistent_keepalive'))?.valor; }
}

module.exports = Configuracion;
