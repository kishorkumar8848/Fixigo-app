const express = require('express');
const router = express.Router();
const jobController = require('../controllers/jobController');
const authenticate = require('../middleware/authMiddleware');

// ======== TECHNICIAN JOB ROUTES ========
router.get('/', authenticate, jobController.getAvailableJobs);
router.post('/:jobId/accept', authenticate, jobController.acceptJob);
router.post('/:jobId/reject', authenticate, jobController.rejectJob);
router.patch('/:jobId/status', authenticate, jobController.updateJobStatus);
router.get('/earnings', authenticate, jobController.getTechnicianEarnings);

module.exports = router;