const pool = require('../config/db');

// ======== CUSTOMER BOOKING FUNCTIONS ========

exports.createBooking = async (req, res) => {
  try {
    const { customerId, appliance_type, issue_description, location, preferred_date } = req.body;

    if (!customerId || !appliance_type || !issue_description || !location) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const [result] = await pool.query(
      'INSERT INTO bookings (customer_id, appliance_type, issue_description, location, preferred_date, status) VALUES (?, ?, ?, ?, ?, ?)',
      [customerId, appliance_type, issue_description, location, preferred_date || null, 'pending']
    );

    // Create a job for available technicians
    const [jobResult] = await pool.query(
      'INSERT INTO jobs (booking_id, technician_id, status) VALUES (?, ?, ?)',
      [result.insertId, null, 'assigned']
    );

    res.status(201).json({ 
      message: 'Booking created successfully',
      bookingId: result.insertId,
      jobId: jobResult.insertId
    });
  } catch (err) {
    console.error('Booking error:', err);
    res.status(500).json({ message: 'Server error creating booking' });
  }
};

exports.getCustomerBookings = async (req, res) => {
  try {
    const customerId = req.params.customerId;

    const [bookings] = await pool.query(
      `SELECT b.*, t.name as technician_name 
       FROM bookings b
       LEFT JOIN technicians t ON b.technician_id = t.id
       WHERE b.customer_id = ?
       ORDER BY b.created_at DESC`,
      [customerId]
    );

    res.json(bookings);
  } catch (err) {
    console.error('Fetch bookings error:', err);
    res.status(500).json({ message: 'Server error fetching bookings' });
  }
};

exports.getBookingHistory = async (req, res) => {
  try {
    const customerId = req.params.customerId;

    const [history] = await pool.query(
      `SELECT b.*, t.name as technician_name, t.rating as technician_rating
       FROM bookings b
       LEFT JOIN technicians t ON b.technician_id = t.id
       WHERE b.customer_id = ? AND b.status = 'completed'
       ORDER BY b.updated_at DESC`,
      [customerId]
    );

    res.json(history);
  } catch (err) {
    console.error('Fetch history error:', err);
    res.status(500).json({ message: 'Server error fetching history' });
  }
};

exports.getBookingDetails = async (req, res) => {
  try {
    const bookingId = req.params.bookingId;

    const [bookings] = await pool.query(
      `SELECT b.*, t.name as technician_name, t.phone as technician_phone, t.rating
       FROM bookings b
       LEFT JOIN technicians t ON b.technician_id = t.id
       WHERE b.id = ?`,
      [bookingId]
    );

    if (bookings.length === 0) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    res.json(bookings[0]);
  } catch (err) {
    console.error('Fetch booking details error:', err);
    res.status(500).json({ message: 'Server error fetching booking details' });
  }
};