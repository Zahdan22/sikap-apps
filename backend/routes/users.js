const express = require('express');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

// ============================================
// GET ALL - manajer lihat semua karyawan (role crew)
// ============================================
router.get('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, username, nama, role, status_aktif, created_at FROM users WHERE role = 'crew' ORDER BY nama ASC`
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// DELETE - manajer hapus akun karyawan
// ============================================
router.delete('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await db.query('DELETE FROM users WHERE id = ? AND role = ?', [id, 'crew']);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Karyawan tidak ditemukan' });
    }
    res.json({ message: 'Karyawan berhasil dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});
// ============================================
// GET LIST SIMPLE - siapa saja bisa akses, buat keperluan pilih rekan kerja (tukar shift, dll)
// ============================================
router.get('/list', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, nama FROM users WHERE role = 'crew' ORDER BY nama ASC`
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});
module.exports = router;