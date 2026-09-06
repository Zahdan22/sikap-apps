const express = require('express');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

// ============================================
// CREATE - manajer input jadwal baru (+ jobdesk opsional, maks 5)
// ============================================
router.post('/', verifyToken, async (req, res) => {
  try {
    const { user_id, tanggal, jam_mulai, jam_selesai, durasi_jam, jobdesk_ids } = req.body;

    if (!user_id || !tanggal || !jam_mulai || !jam_selesai || !durasi_jam) {
      return res.status(400).json({ message: 'Semua field wajib diisi' });
    }

    if (jobdesk_ids && jobdesk_ids.length > 5) {
      return res.status(400).json({ message: 'Maksimal 5 jobdesk per jadwal' });
    }

    const [userCheck] = await db.query('SELECT id FROM users WHERE id = ? AND role = ?', [user_id, 'crew']);
    if (userCheck.length === 0) {
      return res.status(404).json({ message: 'Karyawan tidak ditemukan' });
    }

    const [result] = await db.query(
      `INSERT INTO schedule (user_id, tanggal, jam_mulai, jam_selesai, durasi_jam, dibuat_oleh)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [user_id, tanggal, jam_mulai, jam_selesai, durasi_jam, req.user.id]
    );

    const scheduleId = result.insertId;

    if (jobdesk_ids && jobdesk_ids.length > 0) {
      const values = jobdesk_ids.map((jid) => [scheduleId, jid]);
      await db.query(`INSERT INTO schedule_jobdesk (schedule_id, jobdesk_id) VALUES ?`, [values]);
    }

    res.status(201).json({ message: 'Jadwal berhasil dibuat' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ message: 'Karyawan ini sudah punya jadwal di tanggal tersebut' });
    }
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// UPDATE - manajer edit jadwal (+ jobdesk)
// ============================================
router.put('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { jam_mulai, jam_selesai, durasi_jam, jobdesk_ids } = req.body;

    if (jobdesk_ids && jobdesk_ids.length > 5) {
      return res.status(400).json({ message: 'Maksimal 5 jobdesk per jadwal' });
    }

    const [result] = await db.query(
      `UPDATE schedule SET jam_mulai = ?, jam_selesai = ?, durasi_jam = ? WHERE id = ?`,
      [jam_mulai, jam_selesai, durasi_jam, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Jadwal tidak ditemukan' });
    }

    if (jobdesk_ids) {
      await db.query('DELETE FROM schedule_jobdesk WHERE schedule_id = ?', [id]);
      if (jobdesk_ids.length > 0) {
        const values = jobdesk_ids.map((jid) => [id, jid]);
        await db.query(`INSERT INTO schedule_jobdesk (schedule_id, jobdesk_id) VALUES ?`, [values]);
      }
    }

    res.json({ message: 'Jadwal berhasil diupdate' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET ALL - manajer lihat semua jadwal (+ jobdesk)
// ============================================
router.get('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT s.id, s.tanggal, s.jam_mulai, s.jam_selesai, s.durasi_jam, s.user_id, u.nama, u.username
       FROM schedule s
       JOIN users u ON s.user_id = u.id
       ORDER BY s.tanggal ASC`
    );

    const [jobdeskRows] = await db.query(
      `SELECT sj.schedule_id, j.id, j.nama, j.singkatan
       FROM schedule_jobdesk sj
       JOIN jobdesk j ON sj.jobdesk_id = j.id`
    );

    const jobdeskMap = {};
    jobdeskRows.forEach((jd) => {
      if (!jobdeskMap[jd.schedule_id]) jobdeskMap[jd.schedule_id] = [];
      jobdeskMap[jd.schedule_id].push({ id: jd.id, nama: jd.nama, singkatan: jd.singkatan });
    });

    const result = rows.map((r) => ({ ...r, jobdesk: jobdeskMap[r.id] || [] }));

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET MINE - karyawan lihat jadwal sendiri (+ jobdesk)
// ============================================
router.get('/mine', verifyToken, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT id, tanggal, jam_mulai, jam_selesai, durasi_jam
       FROM schedule
       WHERE user_id = ?
       ORDER BY tanggal ASC`,
      [req.user.id]
    );

    const [jobdeskRows] = await db.query(
      `SELECT sj.schedule_id, j.id, j.nama, j.singkatan
       FROM schedule_jobdesk sj
       JOIN jobdesk j ON sj.jobdesk_id = j.id
       JOIN schedule s ON sj.schedule_id = s.id
       WHERE s.user_id = ?`,
      [req.user.id]
    );

    const jobdeskMap = {};
    jobdeskRows.forEach((jd) => {
      if (!jobdeskMap[jd.schedule_id]) jobdeskMap[jd.schedule_id] = [];
      jobdeskMap[jd.schedule_id].push({ id: jd.id, nama: jd.nama, singkatan: jd.singkatan });
    });

    const result = rows.map((r) => ({ ...r, jobdesk: jobdeskMap[r.id] || [] }));

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// DELETE - manajer hapus jadwal
// ============================================
router.delete('/:id', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const [result] = await db.query('DELETE FROM schedule WHERE id = ?', [id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Jadwal tidak ditemukan' });
    }

    res.json({ message: 'Jadwal berhasil dihapus' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// BULK SAVE - simpan jadwal semua crew sekaligus untuk 1 tanggal
// ============================================
router.post('/bulk', verifyToken, verifyManager, async (req, res) => {
  try {
    const { tanggal, entries } = req.body;

    if (!tanggal || !Array.isArray(entries)) {
      return res.status(400).json({ message: 'Tanggal dan entries wajib diisi' });
    }

    for (const entry of entries) {
      const { user_id, jam_mulai, jam_selesai, durasi_jam, jobdesk_ids, libur } = entry;

      if (libur || !jam_mulai) {
        // Kalau ditandai libur, hapus jadwal yang mungkin sudah ada
        await db.query('DELETE FROM schedule WHERE user_id = ? AND tanggal = ?', [user_id, tanggal]);
        continue;
      }

      // Upsert: insert baru, atau update kalau sudah ada jadwal di tanggal itu
      const [result] = await db.query(
        `INSERT INTO schedule (user_id, tanggal, jam_mulai, jam_selesai, durasi_jam, dibuat_oleh)
         VALUES (?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE jam_mulai = VALUES(jam_mulai), jam_selesai = VALUES(jam_selesai), durasi_jam = VALUES(durasi_jam)`,
        [user_id, tanggal, jam_mulai, jam_selesai, durasi_jam, req.user.id]
      );

      // Cari ulang schedule_id (karena kalau UPDATE, insertId bisa 0)
      const [scheduleRow] = await db.query(
        'SELECT id FROM schedule WHERE user_id = ? AND tanggal = ?',
        [user_id, tanggal]
      );
      const scheduleId = scheduleRow[0].id;

      // Reset jobdesk lama, pasang yang baru
      await db.query('DELETE FROM schedule_jobdesk WHERE schedule_id = ?', [scheduleId]);
      if (jobdesk_ids && jobdesk_ids.length > 0) {
        const values = jobdesk_ids.slice(0, 5).map((jid) => [scheduleId, jid]);
        await db.query(`INSERT INTO schedule_jobdesk (schedule_id, jobdesk_id) VALUES ?`, [values]);
      }
    }

    res.json({ message: 'Jadwal berhasil disimpan untuk semua karyawan' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET BY DATE - lihat jadwal semua crew di 1 tanggal
// Bisa diakses manager (buat grid) maupun crew (buat lihat jadwal rekan kerja)
// ============================================
router.get('/date/:tanggal', verifyToken, async (req, res) => {
  try {
    const { tanggal } = req.params;

    const [rows] = await db.query(
      `SELECT s.id, s.user_id, u.nama, s.jam_mulai, s.jam_selesai, s.durasi_jam
       FROM schedule s
       JOIN users u ON s.user_id = u.id
       WHERE s.tanggal = ?
       ORDER BY s.jam_mulai ASC`,
      [tanggal]
    );

    const [jobdeskRows] = await db.query(
      `SELECT sj.schedule_id, j.id, j.nama, j.singkatan
       FROM schedule_jobdesk sj
       JOIN jobdesk j ON sj.jobdesk_id = j.id
       JOIN schedule s ON sj.schedule_id = s.id
       WHERE s.tanggal = ?`,
      [tanggal]
    );

    const jobdeskMap = {};
    jobdeskRows.forEach((jd) => {
      if (!jobdeskMap[jd.schedule_id]) jobdeskMap[jd.schedule_id] = [];
      jobdeskMap[jd.schedule_id].push({ id: jd.id, nama: jd.nama, singkatan: jd.singkatan });
    });

    const result = rows.map((r) => ({ ...r, jobdesk: jobdeskMap[r.id] || [] }));

    res.json(result);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;