const express = require('express');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

// ============================================
// REGISTER - daftarin karyawan/manajer baru
// ============================================
router.post('/register', verifyToken, verifyManager, async (req, res) => {
  try {
    const { username, nama, password, role } = req.body;

    // Validasi input dasar
    if (!username || !nama || !password || !role) {
      return res.status(400).json({ message: 'Semua field wajib diisi (username, nama, password, role)' });
    }

    if (role !== 'crew' && role !== 'manager') {
      return res.status(400).json({ message: 'Role harus "crew" atau "manager"' });
    }

    // Cek apakah username sudah dipakai
    const [existing] = await db.query('SELECT id FROM users WHERE username = ?', [username]);
    if (existing.length > 0) {
      return res.status(409).json({ message: 'Username sudah dipakai, coba yang lain' });
    }

    // Hash password sebelum disimpan
    const hashedPassword = await bcrypt.hash(password, 10);

    // Simpan ke database
    await db.query(
      'INSERT INTO users (username, nama, password, role) VALUES (?, ?, ?, ?)',
      [username, nama, hashedPassword, role]
    );

    res.status(201).json({ message: 'Registrasi berhasil' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// LOGIN - verifikasi username & password, kasih token
// ============================================
router.post('/login', async (req, res) => {
  try {
    const { username, password, role } = req.body;

    if (!username || !password || !role) {
      return res.status(400).json({ message: 'Username, password, dan role wajib diisi' });
    }

    // Cari user berdasarkan username DAN role yang dipilih saat login
    const [users] = await db.query(
      'SELECT * FROM users WHERE username = ? AND role = ?',
      [username, role]
    );

    if (users.length === 0) {
      return res.status(401).json({ message: 'Username, password, atau role salah' });
    }

    const user = users[0];

    // Bandingkan password yang diketik dengan hash yang tersimpan
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: 'Username, password, atau role salah' });
    }

    if (!user.status_aktif) {
      return res.status(403).json({ message: 'Akun tidak aktif, hubungi manajer' });
    }

    // Bikin token JWT, isinya info penting (id & role) untuk dipakai nanti
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' } // token berlaku 7 hari
    );

    res.json({
      message: 'Login berhasil',
      token,
      user: { id: user.id, nama: user.nama, username: user.username, role: user.role },
    });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;