require('dotenv').config();
const express = require('express');
const cors = require('cors');
const db = require('./db');
const authRoutes = require('./routes/auth');
const scheduleRoutes = require('./routes/schedule'); 
const attendanceRoutes = require('./routes/attendance');
const leaveRoutes = require('./routes/leave');
const reportRoutes = require('./routes/report');
const periodeRoutes = require('./routes/periode');
const usersRoutes = require('./routes/users');
const jamKerjaRoutes = require('./routes/jamkerja');
const jobdeskRoutes = require('./routes/jobdesk');
const swapRoutes = require('./routes/swap');

const app = express();
app.use(cors());
app.use(express.json());

app.use('/uploads', express.static('uploads'));
app.use('/api/auth', authRoutes);
app.use('/api/schedule', scheduleRoutes);   
app.use('/api/attendance', attendanceRoutes);  
app.use('/api/leave', leaveRoutes);
app.use('/api/report', reportRoutes);
app.use('/api/periode', periodeRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/jamkerja', jamKerjaRoutes);
app.use('/api/jobdesk', jobdeskRoutes);
app.use('/api/swap', swapRoutes);

app.get('/api/test', async (req, res) => {
  try {
    const [rows] = await db.query('SELECT 1 + 1 AS hasil');
    res.json({ message: 'Server & database jalan normal!', hasil: rows[0].hasil });
  } catch (error) {
    res.status(500).json({ message: 'Gagal connect ke database', error: error.message });
  }
});

// Error handler khusus untuk multer (upload file)
app.use((err, req, res, next) => {
  if (err.message && err.message.includes('JPG/PNG')) {
    return res.status(400).json({ message: err.message });
  }
  if (err.code === 'LIMIT_FILE_SIZE') {
    return res.status(400).json({ message: 'Ukuran file maksimal 5MB' });
  }
  console.error(err);
  res.status(500).json({ message: 'Terjadi kesalahan server' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});