const express = require('express');
const cors = require('cors');

require('dotenv').config();

const usuariosRoutes = require('./routes/usuarios');
const configuracionesRoutes = require('./routes/configuraciones');
const logsRoutes = require('./routes/logs');
const { getDbAsync, ensureDb } = require('./models/db');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(cors());
app.use(express.json());

app.use('/api/usuarios', usuariosRoutes);
app.use('/api/configuraciones', configuracionesRoutes);
app.use('/api/logs', logsRoutes);

app.get('/api/health', async (req, res) => {
  try {
    const db = await getDbAsync();
    const stmt = db.prepare('SELECT 1');
    stmt.step();
    stmt.free();
    res.json({ status: 'ok', database: 'connected' });
  } catch (error) {
    res.status(500).json({ status: 'error', message: error.message });
  }
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Algo salio mal', message: err.message });
});

async function startServer() {
  try {
    await ensureDb();
    app.listen(PORT, () => {
      console.log(`Servidor API corriendo en http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Error al iniciar el servidor:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
