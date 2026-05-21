const storageService = require('../services/storage.service');

async function subirArchivo(req, res) {
  try {
    const resultado = await storageService.subirArchivo(req.file);

    res.status(201).json({
      ok: true,
      message: 'Archivo subido correctamente',
      data: resultado,
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message || 'Error al subir archivo',
    });
  }
}

async function eliminarArchivo(req, res) {
  try {
    const { key } = req.body;

    await storageService.eliminarArchivo(key);

    res.json({
      ok: true,
      message: 'Archivo eliminado correctamente',
    });
  } catch (error) {
    res.status(400).json({
      ok: false,
      message: error.message || 'Error al eliminar archivo',
    });
  }
}

module.exports = {
  subirArchivo,
  eliminarArchivo,
};