const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

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

// ======== TECHNICIAN AUTH ROUTES ========
router.post('/technician/signup', upload.single('id_proof'), authController.technicianSignup);
router.post('/technician/login', authController.technicianLogin);

// ======== ADMIN AUTH ROUTES ========
router.post('/admin/login', authController.adminLogin);

module.exports = router;