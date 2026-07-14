const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authenticate = require('../middleware/authMiddleware');

const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Always use backend/uploads (absolute), matching express.static in server.js
const uploadsDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'id_proof-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 }, // 8MB
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp|gif|pdf/i;
    const ext = path.extname(file.originalname || '').replace('.', '');
    const mimeOk = !file.mimetype || file.mimetype.startsWith('image/') || file.mimetype === 'application/pdf';
    if (allowed.test(ext) || mimeOk) {
      return cb(null, true);
    }
    cb(new Error('Only image or PDF files are allowed for ID proof'));
  },
});

// ======== CUSTOMER AUTH ROUTES ========
router.post('/customer/signup', authController.customerSignup);
router.post('/customer/login', authController.customerLogin);
router.post('/customer/google-login', authController.customerGoogleLogin);
router.get('/customer/profile/:customerId', authenticate, authController.getCustomerProfile);
router.put('/customer/profile/:customerId', authenticate, authController.updateCustomerProfile);

// ======== TECHNICIAN AUTH ROUTES ========
router.post('/technician/signup', upload.single('id_proof'), authController.technicianSignup);
router.post('/technician/login', authController.technicianLogin);
router.get('/technician/profile/:technicianId', authenticate, authController.getTechnicianProfile);
router.put('/technician/profile/:technicianId', authenticate, authController.updateTechnicianProfile);
router.get('/technician/dashboard/:technicianId', authenticate, authController.getTechnicianDashboard);
router.post('/technician/upload-proof', authenticate, (req, res, next) => {
  upload.single('id_proof')(req, res, (err) => {
    if (err) {
      console.error('Multer upload error:', err.message);
      return res.status(400).json({ message: err.message || 'File upload failed' });
    }
    next();
  });
}, authController.uploadTechnicianProof);

// ======== ADMIN AUTH ROUTES ========
router.post('/admin/login', authController.adminLogin);

module.exports = router;
