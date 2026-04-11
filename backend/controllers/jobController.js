const pool = require('../config/db');

// ======== TECHNICIAN JOB FUNCTIONS ========

exports.getAvailableJobs = async (req, res) => {
  try {
    const technicianId = req.user.id;

    // Get jobs assigned to this technician OR unassigned jobs waiting for someone
    const [jobs] = await pool.query(
      `SELECT j.*, b.appliance_type, b.issue_description, b.location, b.preferred_date, c.name as customer_name, c.phone as customer_phone
       FROM jobs j
       JOIN bookings b ON j.booking_id = b.id
       JOIN customers c ON b.customer_id = c.id
       WHERE (j.technician_id = ? AND j.status IN ('assigned', 'accepted', 'in_progress'))
          OR (j.technician_id IS NULL AND j.status = 'assigned')
       ORDER BY j.created_at DESC`,
      [technicianId]
    );

    res.json(jobs);
  } catch (err) {
    console.error('Fetch jobs error:', err);
    res.status(500).json({ message: 'Server error fetching jobs' });
  }
};

exports.acceptJob = async (req, res) => {
  try {
    const jobId = req.params.jobId;
    const technicianId = req.user.id;

    // Verify job belongs to technician OR is unassigned
    const [jobs] = await pool.query('SELECT * FROM jobs WHERE id = ? AND (technician_id = ? OR technician_id IS NULL)', [jobId, technicianId]);
    if (jobs.length === 0) {
      return res.status(404).json({ message: 'Job not found or already taken' });
    }

    const job = jobs[0];
    const bookingId = job.booking_id;

    // Update job status to accepted and assign to this technician
    await pool.query('UPDATE jobs SET status = ?, technician_id = ? WHERE id = ?', ['accepted', technicianId, jobId]);

    // Update booking status to assigned
    await pool.query('UPDATE bookings SET status = ?, technician_id = ? WHERE id = ?', ['assigned', technicianId, bookingId]);

    res.json({ message: 'Job accepted successfully' });
  } catch (err) {
    console.error('Accept job error:', err);
    res.status(500).json({ message: 'Server error accepting job' });
  }
};

exports.rejectJob = async (req, res) => {
  try {
    const jobId = req.params.jobId;
    const technicianId = req.user.id;

    const [jobs] = await pool.query('SELECT * FROM jobs WHERE id = ? AND technician_id = ?', [jobId, technicianId]);
    if (jobs.length === 0) {
      return res.status(404).json({ message: 'Job not found' });
    }

    // Update job status to rejected
    await pool.query('UPDATE jobs SET status = ? WHERE id = ?', ['rejected', jobId]);

    // Update booking status back to pending so other technicians can accept it
    const bookingId = jobs[0].booking_id;
    await pool.query('UPDATE bookings SET technician_id = NULL, status = ? WHERE id = ?', ['pending', bookingId]);

    res.json({ message: 'Job rejected successfully' });
  } catch (err) {
    console.error('Reject job error:', err);
    res.status(500).json({ message: 'Server error rejecting job' });
  }
};

exports.updateJobStatus = async (req, res) => {
  try {
    const jobId = req.params.jobId;
    const { status } = req.body;
    const technicianId = req.user.id;

    if (!['accepted', 'in_progress', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const [jobs] = await pool.query('SELECT * FROM jobs WHERE id = ? AND technician_id = ?', [jobId, technicianId]);
    if (jobs.length === 0) {
      return res.status(404).json({ message: 'Job not found' });
    }

    const job = jobs[0];
    const bookingId = job.booking_id;

    // Update job status
    const updateData = status === 'completed'
      ? { status, completed_at: new Date() }
      : { status };

    await pool.query('UPDATE jobs SET status = ?, completed_at = ? WHERE id = ?',
      [status, updateData.completed_at || null, jobId]);

    // Update booking status accordingly
    let bookingStatus = status;
    if (status === 'in_progress') bookingStatus = 'in_progress';
    if (status === 'completed') bookingStatus = 'completed';

    await pool.query('UPDATE bookings SET status = ? WHERE id = ?', [bookingStatus, bookingId]);

    // If job completed, create earnings record
    if (status === 'completed') {
      const [bookings] = await pool.query('SELECT * FROM bookings WHERE id = ?', [bookingId]);
      if (bookings.length > 0) {
        // Default price if not set
        const price = job.price || 500;
        await pool.query(
          'INSERT INTO earnings (technician_id, job_id, amount, status) VALUES (?, ?, ?, ?)',
          [technicianId, jobId, price, 'pending']
        );
      }
    }

    res.json({ message: 'Job status updated successfully' });
  } catch (err) {
    console.error('Update job status error:', err);
    res.status(500).json({ message: 'Server error updating job status' });
  }
};

exports.getTechnicianEarnings = async (req, res) => {
  try {
    const technicianId = req.user.id;

    const [earnings] = await pool.query(
      `SELECT e.*, j.id as job_id, b.appliance_type
       FROM earnings e
       JOIN jobs j ON e.job_id = j.id
       JOIN bookings b ON j.booking_id = b.id
       WHERE e.technician_id = ?
       ORDER BY e.created_at DESC`,
      [technicianId]
    );

    // Calculate totals
    const totalEarnings = earnings.reduce((sum, e) => sum + (e.amount || 0), 0);
    const pendingEarnings = earnings.filter(e => e.status === 'pending').reduce((sum, e) => sum + (e.amount || 0), 0);

    res.json({
      earnings,
      totalEarnings,
      pendingEarnings
    });
  } catch (err) {
    console.error('Fetch earnings error:', err);
    res.status(500).json({ message: 'Server error fetching earnings' });
  }
};