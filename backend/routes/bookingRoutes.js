const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const authenticate = require('../middleware/authMiddleware');

// ======== CUSTOMER BOOKING ROUTES ========
router.post('/', authenticate, bookingController.createBooking);
router.post('/initiate', authenticate, bookingController.initiateBooking);
router.post('/verify-payment', authenticate, bookingController.verifyPaymentSignature);
router.get('/payment-callback', bookingController.handlePaymentCallback);
router.get('/mock-payment', bookingController.serveMockPaymentPage);

router.get('/user/:customerId', authenticate, bookingController.getCustomerBookings);
router.get('/history/:customerId', authenticate, bookingController.getBookingHistory);
router.get('/details/:bookingId', authenticate, bookingController.getBookingDetails);
router.put('/:bookingId/cancel', authenticate, bookingController.cancelBooking);

module.exports = router;