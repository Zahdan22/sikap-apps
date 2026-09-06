const jwt = require('jsonwebtoken');

// ============================================
// verifyToken - cek apakah token valid
// Dipakai di SEMUA endpoint yang butuh login
// ============================================
function verifyToken(req, res, next) {
  const authHeader = req.headers['authorization'];

  if (!authHeader) {
    return res.status(401).json({ message: 'Token tidak ditemukan, silakan login' });
  }

  // Format header: "Bearer <token>"
  const token = authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ message: 'Format token salah' });
  }

  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(403).json({ message: 'Token tidak valid atau sudah kadaluarsa' });
    }
    req.user = decoded; // simpan info user (id, username, role) ke request
    next(); // lanjut ke endpoint sesungguhnya
  });
}

// ============================================
// verifyManager - cek apakah role-nya manager
// Dipakai SETELAH verifyToken, khusus endpoint manajer
// ============================================
function verifyManager(req, res, next) {
  if (req.user.role !== 'manager') {
    return res.status(403).json({ message: 'Akses ditolak, khusus untuk manajer' });
  }
  next();
}

module.exports = { verifyToken, verifyManager };