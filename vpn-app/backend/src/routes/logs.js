const express = require('express');
const router = express.Router();
const Log = require('../models/Log');

router.get('/', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 100;
    const logs = await Log.getAll(limit);
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/recientes', async (req, res) => {
  try {
    const dias = parseInt(req.query.dias) || 7;
    const logs = await Log.getRecientes(dias);
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/usuario/:usuarioId', async (req, res) => {
  try {
    const logs = await Log.getByUsuario(req.params.usuarioId);
    res.json(logs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
