const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const authenticate = require('../middleware/authMiddleware');

// ======== CUSTOMER BOOKING ROUTES ========
router.post('/', authenticate, bookingController.createBooking);
router.get('/user/:customerId', authenticate, bookingController.getCustomerBookings);
router.get('/history/:customerId', authenticate, bookingController.getBookingHistory);
router.get('/details/:bookingId', authenticate, bookingController.getBookingDetails);

module.exports = router;