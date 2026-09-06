const express = require('express');
const db = require('../db');
const geolib = require('geolib');
const { verifyToken } = require('../middleware/auth');
const upload = require('../config/multer');

const router = express.Router();

router.post('/masuk', verifyToken, upload.single('foto'), async (req, res) => {
  try {
    const lat = parseFloat(req.body.lat);
    const lng = parseFloat(req.body.lng);
    const foto = req.file ? req.file.filename : null;
    const userId = req.user.id;

    if (!lat || !lng) {
      return res.status(400).json({ message: 'Lokasi wajib dikirim' });
    }

    const today = new Date().toISOString().split('T')[0];
    const [schedules] = await db.query(
      'SELECT * FROM schedule WHERE user_id = ? AND tanggal = ?',
      [userId, today]
    );

    if (schedules.length === 0) {
      return res.status(404).json({ message: 'Tidak ada jadwal kerja hari ini' });
    }
    const schedule = schedules[0];

    const [existing] = await db.query(
      'SELECT * FROM attendance WHERE schedule_id = ?',
      [schedule.id]
    );
    if (existing.length > 0 && existing[0].jam_masuk_aktual) {
      return res.status(409).json({ message: 'Sudah absen masuk hari ini' });
    }

    const [locations] = await db.query('SELECT * FROM office_location LIMIT 1');
    const office = locations[0];
    const distance = geolib.getDistance(
      { latitude: lat, longitude: lng },
      { latitude: office.latitude, longitude: office.longitude }
    );

    if (distance > office.radius_meter) {
      return res.status(403).json({ message: `Terlalu jauh dari lokasi kerja (${distance}m dari batas ${office.radius_meter}m)` });
    }

    const now = new Date();
    const [jamH, jamM] = schedule.jam_mulai.split(':');
    const jamMulaiToday = new Date();
    jamMulaiToday.setHours(jamH, jamM, 0, 0);

    // Tidak boleh absen lebih dari 1 jam sebelum jam mulai shift
    const batasAwal = new Date(jamMulaiToday.getTime() - 60 * 60000);
    if (now < batasAwal) {
      return res.status(403).json({ message: 'Belum waktunya absen masuk (maksimal 1 jam sebelum jadwal)' });
    }

    // Batas tepat waktu: 10 menit sebelum jam mulai (contoh: jadwal 16:00 -> batas 15:50, tepat di 15:50 masih dianggap tepat waktu)
    const selisihMenit = Math.floor((now - jamMulaiToday) / 60000);
    const batasTelatMenit = -10;

    let menitTelat = 0;
    let statusMasuk = 'tepat_waktu';
    if (selisihMenit > batasTelatMenit) {
      menitTelat = selisihMenit - batasTelatMenit;
      statusMasuk = 'telat';
    }

    if (existing.length > 0) {
      await db.query(
        `UPDATE attendance SET jam_masuk_aktual = ?, lat_masuk = ?, lng_masuk = ?, foto_masuk = ?, menit_telat = ?, status_masuk = ? WHERE id = ?`,
        [now, lat, lng, foto, menitTelat, statusMasuk, existing[0].id]
      );
    } else {
      await db.query(
        `INSERT INTO attendance (user_id, schedule_id, jam_masuk_aktual, lat_masuk, lng_masuk, foto_masuk, menit_telat, status_masuk)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [userId, schedule.id, now, lat, lng, foto, menitTelat, statusMasuk]
      );
    }

    res.json({
      message: statusMasuk === 'telat' ? `Absen berhasil, telat ${menitTelat} menit` : 'Absen berhasil, tepat waktu',
      status: statusMasuk,
      menit_telat: menitTelat,
      foto_url: foto ? `/uploads/attendance/${foto}` : null,
    });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

router.post('/pulang', verifyToken, upload.single('foto'), async (req, res) => {
  try {
    const lat = parseFloat(req.body.lat);
    const lng = parseFloat(req.body.lng);
    const foto = req.file ? req.file.filename : null;
    const userId = req.user.id;

    const today = new Date().toISOString().split('T')[0];
    const [schedules] = await db.query(
      'SELECT * FROM schedule WHERE user_id = ? AND tanggal = ?',
      [userId, today]
    );

    if (schedules.length === 0) {
      return res.status(404).json({ message: 'Tidak ada jadwal kerja hari ini' });
    }
    const schedule = schedules[0];

    const [existing] = await db.query(
      'SELECT * FROM attendance WHERE schedule_id = ?',
      [schedule.id]
    );

    if (existing.length === 0 || !existing[0].jam_masuk_aktual) {
      return res.status(400).json({ message: 'Belum absen masuk, tidak bisa absen pulang' });
    }
    if (existing[0].jam_pulang_aktual) {
      return res.status(409).json({ message: 'Sudah absen pulang hari ini' });
    }

    const now = new Date();
    const [jamH, jamM] = schedule.jam_selesai.split(':');
    const jamSelesaiToday = new Date();
    jamSelesaiToday.setHours(jamH, jamM, 0, 0);
    if (schedule.jam_selesai < schedule.jam_mulai) {
      jamSelesaiToday.setDate(jamSelesaiToday.getDate() + 1);
    }

    const batasAkhir = new Date(jamSelesaiToday.getTime() + 45 * 60000);

    let statusPulang = 'tepat_waktu';
    if (now < jamSelesaiToday) {
      statusPulang = 'lebih_awal';
    } else if (now > batasAkhir) {
      statusPulang = 'lewat_batas';
    }

    await db.query(
      `UPDATE attendance SET jam_pulang_aktual = ?, lat_pulang = ?, lng_pulang = ?, foto_pulang = ?, status_pulang = ? WHERE id = ?`,
      [now, lat, lng, foto, statusPulang, existing[0].id]
    );

    res.json({
      message: 'Absen pulang berhasil',
      status: statusPulang,
      foto_url: foto ? `/uploads/attendance/${foto}` : null,
    });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

// ============================================
// STATUS HARI INI - buat kartu status di dashboard
// ============================================
router.get('/today', verifyToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const today = new Date().toISOString().split('T')[0];

    const [schedules] = await db.query(
      'SELECT * FROM schedule WHERE user_id = ? AND tanggal = ?',
      [userId, today]
    );

    if (schedules.length === 0) {
      return res.json({ ada_jadwal: false });
    }

    const schedule = schedules[0];
    const [attendanceRows] = await db.query(
      'SELECT * FROM attendance WHERE schedule_id = ?',
      [schedule.id]
    );
    const attendance = attendanceRows[0] || null;

    res.json({
      ada_jadwal: true,
      jam_mulai: schedule.jam_mulai,
      jam_selesai: schedule.jam_selesai,
      sudah_masuk: !!attendance?.jam_masuk_aktual,
      sudah_pulang: !!attendance?.jam_pulang_aktual,
      jam_masuk_aktual: attendance?.jam_masuk_aktual || null,
      status_masuk: attendance?.status_masuk || null,
    });
  } catch (error) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: error.message });
  }
});

module.exports = router;