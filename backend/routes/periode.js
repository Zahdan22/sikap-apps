const express = require('express');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

// ============================================
// CREATE - manajer bikin periode kerja baru
// ============================================
router.post('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const { nama, tanggal_mulai, tanggal_selesai } = req.body;

    if (!nama || !tanggal_mulai || !tanggal_selesai) {
      return res.status(400).json({ message: 'Nama, tanggal mulai, dan tanggal selesai wajib diisi' });
    }

    const [result] = await db.query(
      `INSERT INTO periode_kerja (nama, tanggal_mulai, tanggal_selesai, dibuat_oleh) VALUES (?, ?, ?, ?)`,
      [nama, tanggal_mulai, tanggal_selesai, req.user.id]
    );

    res.status(201).json({ message: 'Periode kerja berhasil dibuat', id: result.insertId });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET ALL - manajer lihat semua periode kerja
// ============================================
router.get('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM periode_kerja ORDER BY tanggal_mulai DESC`
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// DELETE - manajer hapus periode kerja
// ============================================
router.delete('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await db.query('DELETE FROM periode_kerja WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Periode tidak ditemukan' });
    }
    res.json({ message: 'Periode berhasil dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;