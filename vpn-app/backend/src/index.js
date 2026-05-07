/**
 * @file index.js
 * @description Punto de entrada principal de la API del backend para la gestión de VPN.
 *              Configura el servidor Express, los middlewares básicos y las rutas de la API.
 */

const express = require("express");
const cors = require("cors");
const path = require("path");

// Carga las variables de entorno desde el archivo .env
require("dotenv").config();

// Importación de las rutas de la API
const usuariosRoutes = require("./routes/usuarios");
const configuracionesRoutes = require("./routes/configuraciones");
const logsRoutes = require("./routes/logs");
const wireguardRoutes = require("./routes/wireguard");

// Importación de la conexión a la base de datos para verificaciones de salud
const { getDbAsync, ensureDb } = require("./models/db");

// Inicialización de la aplicación Express
const app = express();

// Define el puerto del servidor (por defecto 3001 si no está en .env)
const PORT = process.env.PORT || 3001;

// Middleware para permitir peticiones Cross-Origin (CORS)
app.use(cors());

// Middleware para parsear el cuerpo de las peticiones en formato JSON
app.use(express.json());

/**
 * Registro de rutas de la API
 * Cada módulo de rutas se asocia a un prefijo específico.
 */
app.use("/api/usuarios", usuariosRoutes);
app.use("/api/configuraciones", configuracionesRoutes);
app.use("/api/logs", logsRoutes);
app.use("/api/wireguard", wireguardRoutes); // Estado en tiempo real del servidor WireGuard

/**
 * Endpoint de Salud (Health Check)
 * Permite verificar si el servidor está activo y si la conexión a la base de datos funciona.
 */
app.get("/api/health", async (req, res) => {
  try {
    const db = await getDbAsync();
    const stmt = db.prepare("SELECT 1");
    stmt.step();
    stmt.free();
    res.json({ status: "ok", database: "connected" });
  } catch (error) {
    res.status(500).json({ status: "error", message: error.message });
  }
});

/**
 * Middleware de manejo de errores global
 * Captura cualquier error no manejado en las rutas y devuelve una respuesta JSON amigable.
 */
app.use((err, req, res, next) => {
  console.error("Error detectado:", err.stack);
  res.status(500).json({
    error: "Algo salió mal en el servidor",
    message: err.message,
  });
});

/**
 * Inicio del servidor
 * Escucha peticiones en el puerto especificado.
 */
async function startServer() {
  try {
    await ensureDb();
    console.log("Base de datos inicializada");
    
    app.listen(PORT, () => {
      console.log(`=========================================`);
      console.log(`Servidor API VPN corriendo en:`);
      console.log(`http://localhost:${PORT}`);
      console.log(`=========================================`);
    });
  } catch (error) {
    console.error("Error al iniciar el servidor:", error);
    process.exit(1);
  }
}

startServer();

// Exporta la instancia de la aplicación para posibles tests
module.exports = app;
