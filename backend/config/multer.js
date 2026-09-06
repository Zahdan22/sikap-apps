const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/attendance');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + req.user.id;
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueSuffix}${ext}`);
  },
});

const fileFilter = (req, file, cb) => {
  const allowedExt = /\.(jpg|jpeg|png|heic|heif|webp)$/i;
  if (allowedExt.test(file.originalname)) {
    cb(null, true);
  } else {
    cb(new Error('Format foto tidak didukung'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 }, // maksimal 5MB
});

module.exports = upload;