require('dotenv').config();
const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', 'database', 'vpn.db');

async function initDb() {
  const SQL = await initSqlJs();
  
  let db;
  if (fs.existsSync(DB_PATH)) {
    const buffer = fs.readFileSync(DB_PATH);
    db = new SQL.Database(buffer);
  } else {
    db = new SQL.Database();
  }

  console.log('Inicializando base de datos...');

  db.run(`
    CREATE TABLE IF NOT EXISTS usuarios (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL,
      email TEXT,
      ip_asignada TEXT NOT NULL UNIQUE,
      clave_privada TEXT NOT NULL,
      clave_publica TEXT NOT NULL,
      activo INTEGER DEFAULT 1,
      fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP,
      fecha_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP,
      notas TEXT
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS configuraciones (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      clave TEXT NOT NULL UNIQUE,
      valor TEXT NOT NULL,
      descripcion TEXT,
      fecha_actualizacion TEXT DEFAULT CURRENT_TIMESTAMP
    )
  `);

  db.run(`
    CREATE TABLE IF NOT EXISTS logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      usuario_id INTEGER,
      accion TEXT NOT NULL,
      detalles TEXT,
      fecha TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    )
  `);

  const configsDefault = [
    ['endpoint', '161.153.28.223:51820', 'IP pública del servidor VPN'],
    ['server_public_key', 'fZrG0x6jFTRM/wwOasP7+ww4uc1bHnKJ6Zhnx6ZB8gk=', 'Clave pública del servidor'],
    ['subnet', '10.6.0.0/24', 'Subred de la VPN'],
    ['dns', '1.1.1.1, 8.8.8.8', 'Servidores DNS'],
    ['persistent_keepalive', '25', 'Keepalive en segundos']
  ];

  configsDefault.forEach(([clave, valor, descripcion]) => {
    db.run(
      'INSERT OR IGNORE INTO configuraciones (clave, valor, descripcion) VALUES (?, ?, ?)',
      [clave, valor, descripcion]
    );
  });

  const data = db.export();
  const dir = path.dirname(DB_PATH);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  fs.writeFileSync(DB_PATH, Buffer.from(data));

  console.log('Base de datos inicializada correctamente');
  console.log('Tablas creadas: usuarios, configuraciones, logs');

  db.close();
}

initDb().catch(console.error);
