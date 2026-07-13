const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authenticate = require('../middleware/authMiddleware');

const multer = require('multer');
const path = require('path');
const fs = require('fs');

if (!fs.existsSync('uploads')) {
    fs.mkdirSync('uploads');
}

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'id_proof-' + uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

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
router.post('/technician/upload-proof', authenticate, upload.single('id_proof'), authController.uploadTechnicianProof);

// ======== ADMIN AUTH ROUTES ========
router.post('/admin/login', authController.adminLogin);

module.exports = router;