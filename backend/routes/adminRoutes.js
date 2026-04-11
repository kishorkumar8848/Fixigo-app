const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authenticate = require('../middleware/authMiddleware');
const authorize = require('../middleware/roleMiddleware');

// All admin routes require authentication and admin role
router.use(authenticate, authorize('admin'));

// ======== DASHBOARD ========
router.get('/dashboard', adminController.getDashboardOverview);

// ======== CUSTOMERS MANAGEMENT ========
router.get('/customers', adminController.getAllCustomers);
router.get('/customers/:customerId', adminController.getCustomerDetails);

// ======== TECHNICIANS MANAGEMENT ========
router.get('/technicians', adminController.getAllTechnicians);
router.get('/technicians/pending', adminController.getPendingTechnicians);
router.patch('/technicians/:technicianId/verify', adminController.verifyTechnician);
router.patch('/technicians/:technicianId/reject', adminController.rejectTechnician);

// ======== BOOKINGS MANAGEMENT ========
router.get('/bookings', adminController.getAllBookings);
router.get('/bookings/stats', adminController.getBookingStats);

// ======== RESALE REQUESTS MANAGEMENT ========
router.get('/resale-requests', adminController.getAllResaleRequests);
router.patch('/resale-requests/:resaleId/approve', adminController.approveResaleRequest);
router.patch('/resale-requests/:resaleId/reject', adminController.rejectResaleRequest);

module.exports = router;