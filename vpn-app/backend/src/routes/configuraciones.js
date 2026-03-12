const express = require('express');
const router = express.Router();
const Configuracion = require('../models/Configuracion');
const Log = require('../models/Log');

router.get('/', async (req, res) => {
  try {
    const configs = await Configuracion.getAll();
    res.json(configs);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/:clave', async (req, res) => {
  try {
    const config = await Configuracion.getByClave(req.params.clave);
    if (!config) {
      return res.status(404).json({ error: 'Configuracion no encontrada' });
    }
    res.json(config);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.put('/:clave', async (req, res) => {
  try {
    const { valor } = req.body;
    if (valor === undefined) {
      return res.status(400).json({ error: 'El valor es requerido' });
    }

    const config = await Configuracion.update(req.params.clave, valor);
    await Log.logSistema('ACTUALIZAR_CONFIG', req.params.clave + ': ' + valor);

    res.json(config);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
