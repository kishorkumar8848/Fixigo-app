const pool = require('../config/db');

// ======== TECHNICIAN JOB FUNCTIONS ========

exports.getAvailableJobs = async (req, res) => {
  try {
    const technicianId = req.user.id;

    // Get jobs assigned to this technician OR unassigned jobs waiting for someone
    const result = await pool.query(
      `SELECT j.*, b.appliance_type, b.issue_description, b.location, b.preferred_date, 
              b.latitude as customer_latitude, b.longitude as customer_longitude, b.booking_fee,
              c.name as customer_name, c.phone as customer_phone
       FROM jobs j
       JOIN bookings b ON j.booking_id = b.id
       JOIN customers c ON b.customer_id = c.id
       WHERE (j.technician_id = $1 AND j.status IN ('assigned', 'accepted', 'in_progress'))
          OR (j.technician_id IS NULL AND j.status = 'assigned')
       ORDER BY j.created_at DESC`,
      [technicianId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Fetch jobs error:', err);
    res.status(500).json({ message: 'Server error fetching jobs' });
  }
};

exports.acceptJob = async (req, res) => {
  try {
    const jobId = req.params.jobId;
    const technicianId = req.user.id;

    // Check technician's verification status
    const techRes = await pool.query('SELECT verification_status FROM technicians WHERE id = $1', [technicianId]);
    if (techRes.rows.length === 0) {
      return res.status(404).json({ message: 'Technician not found' });
    }
    if (techRes.rows[0].verification_status !== 'verified') {
      return res.status(403).json({ 
        message: 'You must verify both Aadhaar Card and PAN Card in your profile before you can accept jobs.' 
      });
    }

    // Verify job belongs to technician OR is unassigned
    const jobsResult = await pool.query('SELECT * FROM jobs WHERE id = $1 AND (technician_id = $2 OR technician_id IS NULL)', [jobId, technicianId]);
    if (jobsResult.rows.length === 0) {
      return res.status(404).json({ message: 'Job not found or already taken' });
    }

    const job = jobsResult.rows[0];
    const bookingId = job.booking_id;

    // Update job status to accepted and assign to this technician
    await pool.query('UPDATE jobs SET status = $1, technician_id = $2 WHERE id = $3', ['accepted', technicianId, jobId]);

    // Reject other technician job requests for the same booking
    await pool.query("UPDATE jobs SET status = 'rejected' WHERE booking_id = $1 AND id != $2", [bookingId, jobId]);

    // Update booking status to assigned
    await pool.query('UPDATE bookings SET status = $1, technician_id = $2 WHERE id = $3', ['assigned', technicianId, bookingId]);

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

    const jobsResult = await pool.query('SELECT * FROM jobs WHERE id = $1 AND technician_id = $2', [jobId, technicianId]);
    if (jobsResult.rows.length === 0) {
      return res.status(404).json({ message: 'Job not found' });
    }

    // Update job status to rejected
    await pool.query('UPDATE jobs SET status = $1 WHERE id = $2', ['rejected', jobId]);

    // Update booking status back to pending so other technicians can accept it
    const bookingId = jobsResult.rows[0].booking_id;
    await pool.query('UPDATE bookings SET technician_id = NULL, status = $1 WHERE id = $2', ['pending', bookingId]);

    res.json({ message: 'Job rejected successfully' });
  } catch (err) {
    console.error('Reject job error:', err);
    res.status(500).json({ message: 'Server error rejecting job' });
  }
};

exports.updateJobStatus = async (req, res) => {
  try {
    const jobId = req.params.jobId;
    const { status, price } = req.body;
    const technicianId = req.user.id;

    if (!['accepted', 'in_progress', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({ message: 'Invalid status' });
    }

    const jobsResult = await pool.query('SELECT * FROM jobs WHERE id = $1 AND technician_id = $2', [jobId, technicianId]);
    if (jobsResult.rows.length === 0) {
      return res.status(404).json({ message: 'Job not found' });
    }

    const job = jobsResult.rows[0];
    const bookingId = job.booking_id;

    // Update job status & price
    const completedAt = status === 'completed' ? new Date() : null;
    const finalPrice = status === 'completed' && price ? parseFloat(price) : (job.price || 500);

    await pool.query(
      'UPDATE jobs SET status = $1, completed_at = $2, price = $3 WHERE id = $4',
      [status, completedAt, finalPrice, jobId]
    );

    // Update booking status accordingly
    let bookingStatus = status;
    if (status === 'in_progress') bookingStatus = 'in_progress';
    if (status === 'completed') bookingStatus = 'completed';

    await pool.query('UPDATE bookings SET status = $1 WHERE id = $2', [bookingStatus, bookingId]);

    // If job completed, create earnings record
    if (status === 'completed') {
      const bookingsResult = await pool.query('SELECT * FROM bookings WHERE id = $1', [bookingId]);
      if (bookingsResult.rows.length > 0) {
        await pool.query(
          'INSERT INTO earnings (technician_id, job_id, amount, status) VALUES ($1, $2, $3, $4)',
          [technicianId, jobId, finalPrice, 'pending']
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

    const result = await pool.query(
      `SELECT e.*, j.id as job_id, b.appliance_type
       FROM earnings e
       JOIN jobs j ON e.job_id = j.id
       JOIN bookings b ON j.booking_id = b.id
       WHERE e.technician_id = $1
       ORDER BY e.created_at DESC`,
      [technicianId]
    );

    const earnings = result.rows;

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