require('dotenv').config();
const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', 'database', 'vpn.db');

async function migrarDb() {
  const SQL = await initSqlJs();
  
  let db;
  if (fs.existsSync(DB_PATH)) {
    const buffer = fs.readFileSync(DB_PATH);
    db = new SQL.Database(buffer);
    console.log('Base de datos existente encontrada');
  } else {
    console.log('No existe base de datos. Ejecute primero npm run init-db');
    db.close();
    return;
  }

  try {
    db.run('ALTER TABLE usuarios ADD COLUMN usuario TEXT');
    console.log('Campo usuario agregado');
  } catch (e) {
    if (e.message.includes('duplicate column name')) {
      console.log('Campo usuario ya existe');
    } else {
      console.log('Error:', e.message);
    }
  }

  try {
    db.run("ALTER TABLE usuarios ADD COLUMN sistema_operativo TEXT DEFAULT 'linux'");
    console.log('Campo sistema_operativo agregado');
  } catch (e) {
    if (e.message.includes('duplicate column name')) {
      console.log('Campo sistema_operativo ya existe');
    } else {
      console.log('Error:', e.message);
    }
  }

  const data = db.export();
  fs.writeFileSync(DB_PATH, Buffer.from(data));

  console.log('Migración completada');

  db.close();
}

migrarDb().catch(console.error);
