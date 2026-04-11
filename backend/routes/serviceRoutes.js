const express = require('express');
const router = express.Router();
const serviceController = require('../controllers/serviceController');
const authenticate = require('../middleware/authMiddleware');
const authorize = require('../middleware/roleMiddleware');

// Get all services is public (or can be accessed by any user/technician)
router.get('/', serviceController.getAllServices);

// Create, Update, Delete require admin privileges
router.post('/', authenticate, authorize('admin'), serviceController.createService);
router.put('/:serviceId', authenticate, authorize('admin'), serviceController.updateService);
router.delete('/:serviceId', authenticate, authorize('admin'), serviceController.deleteService);

module.exports = router;
