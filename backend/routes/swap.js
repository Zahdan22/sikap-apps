const express = require('express');
const db = require('../db');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

// ============================================
// CREATE - karyawan ajukan tukar shift
// ============================================
router.post('/', verifyToken, async (req, res) => {
  try {
    const { tanggal, target_id, alasan } = req.body;
    const requesterId = req.user.id;

    if (!tanggal || !target_id) {
      return res.status(400).json({ message: 'Tanggal dan target karyawan wajib diisi' });
    }

    if (target_id == requesterId) {
      return res.status(400).json({ message: 'Tidak bisa tukar shift dengan diri sendiri' });
    }

    const [targetCheck] = await db.query('SELECT id FROM users WHERE id = ? AND role = ?', [target_id, 'crew']);
    if (targetCheck.length === 0) {
      return res.status(404).json({ message: 'Karyawan tujuan tidak ditemukan' });
    }

    await db.query(
      `INSERT INTO shift_swap_request (tanggal, requester_id, target_id, alasan) VALUES (?, ?, ?, ?)`,
      [tanggal, requesterId, target_id, alasan || null]
    );

    res.status(201).json({ message: 'Pengajuan tukar shift berhasil dikirim, menunggu persetujuan manajer' });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET MINE - karyawan lihat pengajuan sendiri (yang dia buat & yang ditujukan ke dia)
// ============================================
router.get('/mine', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const [rows] = await db.query(
      `SELECT ssr.*, 
        req.nama AS requester_nama, 
        tgt.nama AS target_nama
       FROM shift_swap_request ssr
       JOIN users req ON ssr.requester_id = req.id
       JOIN users tgt ON ssr.target_id = tgt.id
       WHERE ssr.requester_id = ? OR ssr.target_id = ?
       ORDER BY ssr.created_at DESC`,
      [userId, userId]
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET ALL - manajer lihat semua pengajuan tukar shift
// ============================================
router.get('/', verifyToken, verifyManager, async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT ssr.*, 
        req.nama AS requester_nama, 
        tgt.nama AS target_nama
       FROM shift_swap_request ssr
       JOIN users req ON ssr.requester_id = req.id
       JOIN users tgt ON ssr.target_id = tgt.id
       ORDER BY ssr.created_at DESC`
    );
    res.json(rows);
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// APPROVE/REJECT - manajer proses pengajuan, auto-swap kalau disetujui
// ============================================
router.put('/:id/status', verifyToken, verifyManager, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, catatan_manajer } = req.body;

    if (status !== 'disetujui' && status !== 'ditolak') {
      return res.status(400).json({ message: 'Status harus "disetujui" atau "ditolak"' });
    }

    const [swapRows] = await db.query('SELECT * FROM shift_swap_request WHERE id = ?', [id]);
    if (swapRows.length === 0) {
      return res.status(404).json({ message: 'Pengajuan tidak ditemukan' });
    }
    const swap = swapRows[0];

    if (swap.status !== 'pending') {
      return res.status(409).json({ message: 'Pengajuan ini sudah diproses sebelumnya' });
    }

    if (status === 'disetujui') {
      // Ambil jadwal requester & target di tanggal itu
      const [requesterSchedule] = await db.query(
        'SELECT * FROM schedule WHERE user_id = ? AND tanggal = ?',
        [swap.requester_id, swap.tanggal]
      );
      const [targetSchedule] = await db.query(
        'SELECT * FROM schedule WHERE user_id = ? AND tanggal = ?',
        [swap.target_id, swap.tanggal]
      );

      const reqSched = requesterSchedule[0] || null;
      const tgtSched = targetSchedule[0] || null;

      // Ambil jobdesk masing-masing (kalau ada jadwal)
      const getJobdesk = async (scheduleId) => {
        if (!scheduleId) return [];
        const [rows] = await db.query('SELECT jobdesk_id FROM schedule_jobdesk WHERE schedule_id = ?', [scheduleId]);
        return rows.map((r) => r.jobdesk_id);
      };
      const reqJobdesk = await getJobdesk(reqSched?.id);
      const tgtJobdesk = await getJobdesk(tgtSched?.id);

      // Kasus 1: keduanya punya jadwal -> tukar jam & jobdesk
      if (reqSched && tgtSched) {
        await db.query(
          'UPDATE schedule SET jam_mulai=?, jam_selesai=?, durasi_jam=? WHERE id=?',
          [tgtSched.jam_mulai, tgtSched.jam_selesai, tgtSched.durasi_jam, reqSched.id]
        );
        await db.query(
          'UPDATE schedule SET jam_mulai=?, jam_selesai=?, durasi_jam=? WHERE id=?',
          [reqSched.jam_mulai, reqSched.jam_selesai, reqSched.durasi_jam, tgtSched.id]
        );
        await db.query('DELETE FROM schedule_jobdesk WHERE schedule_id IN (?, ?)', [reqSched.id, tgtSched.id]);
        if (tgtJobdesk.length > 0) {
          await db.query('INSERT INTO schedule_jobdesk (schedule_id, jobdesk_id) VALUES ?', [tgtJobdesk.map((j) => [reqSched.id, j])]);
        }
        if (reqJobdesk.length > 0) {
          await db.query('INSERT INTO schedule_jobdesk (schedule_id, jobdesk_id) VALUES ?', [reqJobdesk.map((j) => [tgtSched.id, j])]);
        }
      }
      // Kasus 2: requester kerja, target libur -> pindahkan jadwal ke target, requester jadi libur
      else if (reqSched && !tgtSched) {
        await db.query('UPDATE schedule SET user_id = ? WHERE id = ?', [swap.target_id, reqSched.id]);
      }
      // Kasus 3: target kerja, requester libur -> pindahkan jadwal ke requester, target jadi libur
      else if (!reqSched && tgtSched) {
        await db.query('UPDATE schedule SET user_id = ? WHERE id = ?', [swap.requester_id, tgtSched.id]);
      }
      // Kasus 4: keduanya libur -> tidak ada yang perlu ditukar
    }

    await db.query(
      'UPDATE shift_swap_request SET status = ?, approved_by = ?, catatan_manajer = ? WHERE id = ?',
      [status, req.user.id, catatan_manajer || null, id]
    );

    res.json({ message: `Pengajuan tukar shift berhasil ${status === 'disetujui' ? 'disetujui dan jadwal telah diperbarui' : 'ditolak'}` });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;