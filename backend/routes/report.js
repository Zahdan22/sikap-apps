const express = require('express');
const db = require('../db');
const ExcelJS = require('exceljs');
const { verifyToken, verifyManager } = require('../middleware/auth');

const router = express.Router();

// ============================================
// GET REKAP BULANAN (JSON) - berdasarkan bulan kalender
// Query: /api/report/monthly?bulan=8&tahun=2026
// ============================================
router.get('/monthly', verifyToken, verifyManager, async (req, res) => {
  try {
    const { bulan, tahun } = req.query;
    if (!bulan || !tahun) {
      return res.status(400).json({ message: 'Parameter bulan dan tahun wajib diisi' });
    }

    const [detail] = await db.query(
      `SELECT u.id AS user_id, u.nama, u.username, s.tanggal,
        s.jam_mulai AS jadwal_jam_mulai, s.jam_selesai AS jadwal_jam_selesai,
        a.jam_masuk_aktual, a.jam_pulang_aktual, a.foto_masuk, a.foto_pulang, a.menit_telat, a.status_masuk, a.status_pulang
      FROM schedule s
      JOIN users u ON s.user_id = u.id
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE MONTH(s.tanggal) = ? AND YEAR(s.tanggal) = ?
      ORDER BY u.nama ASC, s.tanggal ASC`,
      [bulan, tahun]
    );

    const [summary] = await db.query(
      `SELECT u.id AS user_id, u.nama, u.username,
        COUNT(a.id) AS total_hari_masuk,
        SUM(CASE WHEN a.status_masuk = 'telat' THEN 1 ELSE 0 END) AS total_telat,
        SUM(a.menit_telat) AS total_menit_telat,
        SUM(CASE WHEN a.jam_masuk_aktual IS NOT NULL AND a.jam_pulang_aktual IS NULL THEN 1 ELSE 0 END) AS total_lupa_pulang
      FROM schedule s
      JOIN users u ON s.user_id = u.id
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE MONTH(s.tanggal) = ? AND YEAR(s.tanggal) = ?
      GROUP BY u.id, u.nama, u.username
      ORDER BY u.nama ASC`,
      [bulan, tahun]
    );

    res.json({ summary, detail });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET REKAP BERDASARKAN PERIODE KERJA (JSON)
// Query: /api/report/periode?periode_id=1
// ============================================
router.get('/periode', verifyToken, verifyManager, async (req, res) => {
  try {
    const { periode_id } = req.query;
    if (!periode_id) {
      return res.status(400).json({ message: 'Parameter periode_id wajib diisi' });
    }

    const [periodeRows] = await db.query('SELECT * FROM periode_kerja WHERE id = ?', [periode_id]);
    if (periodeRows.length === 0) {
      return res.status(404).json({ message: 'Periode tidak ditemukan' });
    }
    const periode = periodeRows[0];

    const [detail] = await db.query(
      `SELECT u.id AS user_id, u.nama, u.username, s.tanggal,
        s.jam_mulai AS jadwal_jam_mulai, s.jam_selesai AS jadwal_jam_selesai,
        a.jam_masuk_aktual, a.jam_pulang_aktual, a.foto_masuk, a.foto_pulang, a.menit_telat, a.status_masuk, a.status_pulang
      FROM schedule s
      JOIN users u ON s.user_id = u.id
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE s.tanggal BETWEEN ? AND ?
      ORDER BY u.nama ASC, s.tanggal ASC`,
      [periode.tanggal_mulai, periode.tanggal_selesai]
    );

    const [summary] = await db.query(
      `SELECT u.id AS user_id, u.nama, u.username,
        COUNT(a.id) AS total_hari_masuk,
        SUM(CASE WHEN a.status_masuk = 'telat' THEN 1 ELSE 0 END) AS total_telat,
        SUM(a.menit_telat) AS total_menit_telat,
        SUM(CASE WHEN a.jam_masuk_aktual IS NOT NULL AND a.jam_pulang_aktual IS NULL THEN 1 ELSE 0 END) AS total_lupa_pulang
      FROM schedule s
      JOIN users u ON s.user_id = u.id
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE s.tanggal BETWEEN ? AND ?
      GROUP BY u.id, u.nama, u.username
      ORDER BY u.nama ASC`,
      [periode.tanggal_mulai, periode.tanggal_selesai]
    );

    res.json({ periode, summary, detail });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// EXPORT EXCEL BERDASARKAN PERIODE
// Query: /api/report/export-periode?periode_id=1
// ============================================
router.get('/export-periode', verifyToken, verifyManager, async (req, res) => {
  try {
    const { periode_id } = req.query;
    if (!periode_id) {
      return res.status(400).json({ message: 'Parameter periode_id wajib diisi' });
    }

    const [periodeRows] = await db.query('SELECT * FROM periode_kerja WHERE id = ?', [periode_id]);
    if (periodeRows.length === 0) {
      return res.status(404).json({ message: 'Periode tidak ditemukan' });
    }
    const periode = periodeRows[0];

    const [rows] = await db.query(
      `SELECT u.nama, u.username, s.tanggal,
        s.jam_mulai AS jadwal_jam_mulai, s.jam_selesai AS jadwal_jam_selesai,
        a.jam_masuk_aktual, a.jam_pulang_aktual, a.menit_telat, a.status_masuk, a.status_pulang
      FROM schedule s
      JOIN users u ON s.user_id = u.id
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE s.tanggal BETWEEN ? AND ?
      ORDER BY u.nama ASC, s.tanggal ASC`,
      [periode.tanggal_mulai, periode.tanggal_selesai]
    );

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet(periode.nama);

    sheet.columns = [
      { header: 'Nama', key: 'nama', width: 20 },
      { header: 'Username', key: 'username', width: 15 },
      { header: 'Tanggal', key: 'tanggal', width: 15 },
      { header: 'Jadwal Masuk', key: 'jadwal_jam_mulai', width: 15 },
      { header: 'Jadwal Selesai', key: 'jadwal_jam_selesai', width: 15 },
      { header: 'Jam Masuk Aktual', key: 'jam_masuk_aktual', width: 20 },
      { header: 'Jam Pulang Aktual', key: 'jam_pulang_aktual', width: 20 },
      { header: 'Menit Telat', key: 'menit_telat', width: 12 },
      { header: 'Status Masuk', key: 'status_masuk', width: 15 },
      { header: 'Status Pulang', key: 'status_pulang', width: 15 },
    ];
    sheet.getRow(1).font = { bold: true };
    rows.forEach((row) => sheet.addRow(row));

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=${periode.nama.replace(/\s+/g, '_')}.xlsx`);

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// EXPORT EXCEL BULANAN
// Query: /api/report/export?bulan=8&tahun=2026
// ============================================
router.get('/export', verifyToken, verifyManager, async (req, res) => {
  try {
    const { bulan, tahun } = req.query;
    if (!bulan || !tahun) {
      return res.status(400).json({ message: 'Parameter bulan dan tahun wajib diisi' });
    }

    const [rows] = await db.query(
      `SELECT u.nama, u.username, s.tanggal,
        s.jam_mulai AS jadwal_jam_mulai, s.jam_selesai AS jadwal_jam_selesai,
        a.jam_masuk_aktual, a.jam_pulang_aktual,a.foto_masuk, a.foto_pulang, a.menit_telat, a.status_masuk, a.status_pulang
      FROM schedule s
      JOIN users u ON s.user_id = u.id
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE MONTH(s.tanggal) = ? AND YEAR(s.tanggal) = ?
      ORDER BY u.nama ASC, s.tanggal ASC`,
      [bulan, tahun]
    );

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet(`Rekap ${bulan}-${tahun}`);

    sheet.columns = [
      { header: 'Nama', key: 'nama', width: 20 },
      { header: 'Username', key: 'username', width: 15 },
      { header: 'Tanggal', key: 'tanggal', width: 15 },
      { header: 'Jadwal Masuk', key: 'jadwal_jam_mulai', width: 15 },
      { header: 'Jadwal Selesai', key: 'jadwal_jam_selesai', width: 15 },
      { header: 'Jam Masuk Aktual', key: 'jam_masuk_aktual', width: 20 },
      { header: 'Jam Pulang Aktual', key: 'jam_pulang_aktual', width: 20 },
      { header: 'Menit Telat', key: 'menit_telat', width: 12 },
      { header: 'Status Masuk', key: 'status_masuk', width: 15 },
      { header: 'Status Pulang', key: 'status_pulang', width: 15 },
      { header: 'Link Foto Masuk', key: 'link_foto_masuk', width: 40 },
      { header: 'Link Foto Pulang', key: 'link_foto_pulang', width: 40 },
    ];
    sheet.getRow(1).font = { bold: true };
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    rows.forEach((row) => {
      sheet.addRow({
        ...row,
        link_foto_masuk: row.foto_masuk ? `${baseUrl}/uploads/attendance/${row.foto_masuk}` : '-',
        link_foto_pulang: row.foto_pulang ? `${baseUrl}/uploads/attendance/${row.foto_pulang}` : '-',
      });
    });

    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=rekap_absensi_${bulan}_${tahun}.xlsx`);

    await workbook.xlsx.write(res);
    res.end();
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// GET RIWAYAT PRIBADI (JSON) - crew lihat riwayat absensi sendiri
// Query: /api/report/mine?bulan=8&tahun=2026
// ============================================
router.get('/mine', verifyToken, async (req, res) => {
  try {
    const { bulan, tahun } = req.query;
    const userId = req.user.id;

    if (!bulan || !tahun) {
      return res.status(400).json({ message: 'Parameter bulan dan tahun wajib diisi' });
    }

    const [detail] = await db.query(
      `SELECT s.tanggal, s.jam_mulai AS jadwal_jam_mulai, s.jam_selesai AS jadwal_jam_selesai,
        a.jam_masuk_aktual, a.jam_pulang_aktual, a.foto_masuk, a.foto_pulang, a.menit_telat, a.status_masuk, a.status_pulang
      FROM schedule s
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE s.user_id = ? AND MONTH(s.tanggal) = ? AND YEAR(s.tanggal) = ?
      ORDER BY s.tanggal DESC`,
      [userId, bulan, tahun]
    );

    const [summaryRows] = await db.query(
      `SELECT
        COUNT(a.id) AS total_hari_masuk,
        SUM(CASE WHEN a.status_masuk = 'telat' THEN 1 ELSE 0 END) AS total_telat,
        SUM(a.menit_telat) AS total_menit_telat,
        SUM(TIMESTAMPDIFF(MINUTE, a.jam_masuk_aktual, a.jam_pulang_aktual)) AS total_menit_kerja
      FROM schedule s
      LEFT JOIN attendance a ON a.schedule_id = s.id
      WHERE s.user_id = ? AND MONTH(s.tanggal) = ? AND YEAR(s.tanggal) = ?`,
      [userId, bulan, tahun]
    );

    res.json({ summary: summaryRows[0], detail });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;