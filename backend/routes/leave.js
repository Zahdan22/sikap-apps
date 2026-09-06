const express = require('express');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

// ============================================
// CREATE - karyawan ajukan izin
// ============================================
router.post('/', verifyToken, async (req, res) => {
  try {
    const { jenis, tanggal_mulai, tanggal_selesai, alasan } = req.body;
    const userId = req.user.id;

    if (!jenis || !tanggal_mulai || !tanggal_selesai) {
      return res.status(400).json({ message: 'Jenis, tanggal mulai, dan tanggal selesai wajib diisi' });
    }

    if (jenis !== 'sakit' && jenis !== 'keperluan_pribadi') {
      return res.status(400).json({ message: 'Jenis izin harus "sakit" atau "keperluan_pribadi"' });
    }

    await db.query(
      `INSERT INTO leave_request (user_id, jenis, tanggal_mulai, tanggal_selesai, alasan)
       VALUES (?, ?, ?, ?, ?)`,
      [userId, jenis, tanggal_mulai, tanggal_selesai, alasan || null]
    );

    res.status(201).json({ message: 'Pengajuan izin berhasil dikirim, menunggu persetujuan manajer' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET MINE - karyawan lihat riwayat izin sendiri
// ============================================
router.get('/mine', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT * FROM leave_request WHERE user_id = ? ORDER BY created_at DESC`,
      [req.user.id]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET ALL - manajer lihat semua pengajuan izin
// ============================================
router.get('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT lr.*, u.nama, u.username
       FROM leave_request lr
       JOIN users u ON lr.user_id = u.id
       ORDER BY lr.created_at DESC`
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// APPROVE/REJECT - manajer proses pengajuan izin
// ============================================
router.put('/:id/status', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, catatan_manajer } = req.body;

    if (status !== 'disetujui' && status !== 'ditolak') {
      return res.status(400).json({ message: 'Status harus "disetujui" atau "ditolak"' });
    }

    const [result] = await db.query(
      `UPDATE leave_request SET status = ?, approved_by = ?, catatan_manajer = ? WHERE id = ?`,
      [status, req.user.id, catatan_manajer || null, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Pengajuan izin tidak ditemukan' });
    }

    res.json({ message: `Pengajuan izin berhasil ${status === 'disetujui' ? 'disetujui' : 'ditolak'}` });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;