const express = require('express');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

router.get('/', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM jam_kerja_opsi ORDER BY jam_mulai ASC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

router.post('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const { label, jam_mulai, jam_selesai, durasi_jam } = req.body;
    if (!label || !jam_mulai || !jam_selesai || !durasi_jam) {
      return res.status(400).json({ message: 'Semua field wajib diisi' });
    }
    const [result] = await db.query(
      `INSERT INTO jam_kerja_opsi (label, jam_mulai, jam_selesai, durasi_jam, dibuat_oleh) VALUES (?, ?, ?, ?, ?)`,
      [label, jam_mulai, jam_selesai, durasi_jam, req.user.id]
    );
    res.status(201).json({ message: 'Opsi jam kerja berhasil dibuat', id: result.insertId });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

router.put('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { label, jam_mulai, jam_selesai, durasi_jam } = req.body;
    const [result] = await db.query(
      `UPDATE jam_kerja_opsi SET label = ?, jam_mulai = ?, jam_selesai = ?, durasi_jam = ? WHERE id = ?`,
      [label, jam_mulai, jam_selesai, durasi_jam, id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Opsi jam kerja tidak ditemukan' });
    }
    res.json({ message: 'Opsi jam kerja berhasil diupdate' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

router.delete('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await db.query('DELETE FROM jam_kerja_opsi WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Opsi jam kerja tidak ditemukan' });
    }
    res.json({ message: 'Opsi jam kerja berhasil dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;