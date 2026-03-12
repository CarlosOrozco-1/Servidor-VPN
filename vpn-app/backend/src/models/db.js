require('dotenv').config();
const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', '..', 'database', 'vpn.db');

let db = null;
let SQL = null;
let initPromise = null;

async function ensureDb() {
  if (db) return db;
  
  if (!initPromise) {
    initPromise = (async () => {
      SQL = await initSqlJs();
      let buffer = null;
      if (fs.existsSync(DB_PATH)) {
        buffer = fs.readFileSync(DB_PATH);
      }
      db = new SQL.Database(buffer);
      return db;
    })();
  }
  
  return await initPromise;
}

function getDb() {
  if (!db) {
    throw new Error('DB no inicializada. Llama a await getDbAsync() primero.');
  }
  return db;
}

async function getDbAsync() {
  return await ensureDb();
}

function saveDb() {
  if (db) {
    const data = db.export();
    const buffer = Buffer.from(data);
    const dir = path.dirname(DB_PATH);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(DB_PATH, buffer);
  }
}

function closeDb() {
  if (db) {
    saveDb();
    db.close();
    db = null;
  }
}

module.exports = {
  getDb,
  getDbAsync,
  ensureDb,
  closeDb,
  saveDb
};
