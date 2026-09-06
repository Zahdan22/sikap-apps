const express = require('express');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

router.get('/', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query('SELECT * FROM jobdesk ORDER BY nama ASC');
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

router.post('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const { nama, singkatan } = req.body;
    if (!nama || !singkatan) {
      return res.status(400).json({ message: 'Nama dan singkatan wajib diisi' });
    }
    const [result] = await db.query(
      `INSERT INTO jobdesk (nama, singkatan, dibuat_oleh) VALUES (?, ?, ?)`,
      [nama, singkatan, req.user.id]
    );
    res.status(201).json({ message: 'Jobdesk berhasil dibuat', id: result.insertId });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

router.put('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, singkatan } = req.body;
    const [result] = await db.query(
      `UPDATE jobdesk SET nama = ?, singkatan = ? WHERE id = ?`,
      [nama, singkatan, id]
    );
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Jobdesk tidak ditemukan' });
    }
    res.json({ message: 'Jobdesk berhasil diupdate' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

router.delete('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await db.query('DELETE FROM jobdesk WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Jobdesk tidak ditemukan' });
    }
    res.json({ message: 'Jobdesk berhasil dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;