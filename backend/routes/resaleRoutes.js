const express = require('express');
const router = express.Router();
const resaleController = require('../controllers/resaleController');
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
        cb(null, 'resale-' + uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

// ======== CUSTOMER RESALE ROUTES ========
router.post('/', authenticate, upload.single('image'), resaleController.submitResaleRequest);
router.get('/:customerId', authenticate, resaleController.getCustomerResaleRequests);

module.exports = router;