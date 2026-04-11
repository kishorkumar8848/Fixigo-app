const express = require('express');
const router = express.Router();
const resaleController = require('../controllers/resaleController');
const authenticate = require('../middleware/authMiddleware');

// ======== CUSTOMER RESALE ROUTES ========
router.post('/', authenticate, resaleController.submitResaleRequest);
router.get('/:customerId', authenticate, resaleController.getCustomerResaleRequests);

module.exports = router;