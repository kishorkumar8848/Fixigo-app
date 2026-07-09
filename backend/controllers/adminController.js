const pool = require('../config/db');

// ======== ADMIN FUNCTIONS ========

// ---- Users Management ----

exports.getAllCustomers = async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, email, phone, address, created_at FROM customers ORDER BY created_at DESC');
    res.json(result.rows);
  } catch (err) {
    console.error('Fetch customers error:', err);
    res.status(500).json({ message: 'Server error fetching customers' });
  }
};

exports.getCustomerDetails = async (req, res) => {
  try {
    const customerId = req.params.customerId;
    const result = await pool.query('SELECT * FROM customers WHERE id = $1', [customerId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    const bookingsResult = await pool.query('SELECT COUNT(*) as total FROM bookings WHERE customer_id = $1', [customerId]);
    res.json({ ...result.rows[0], totalBookings: bookingsResult.rows[0].total });
  } catch (err) {
    console.error('Fetch customer details error:', err);
    res.status(500).json({ message: 'Server error fetching customer details' });
  }
};

// ---- Technicians Management ----

exports.getAllTechnicians = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, email, phone, skills, experience, verification_status, rating, total_jobs, id_proof_url, created_at FROM technicians ORDER BY created_at DESC'
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Fetch technicians error:', err);
    res.status(500).json({ message: 'Server error fetching technicians' });
  }
};

exports.verifyTechnician = async (req, res) => {
  try {
    const technicianId = req.params.technicianId;
    const result = await pool.query('SELECT * FROM technicians WHERE id = $1', [technicianId]);
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Technician not found' });
    }

    await pool.query('UPDATE technicians SET verification_status = $1 WHERE id = $2', ['verified', technicianId]);
    res.json({ message: 'Technician verified successfully' });
  } catch (err) {
    console.error('Verify technician error:', err);
    res.status(500).json({ message: 'Server error verifying technician' });
  }
};

exports.rejectTechnician = async (req, res) => {
  try {
    const technicianId = req.params.technicianId;
    await pool.query('UPDATE technicians SET verification_status = $1 WHERE id = $2', ['rejected', technicianId]);
    res.json({ message: 'Technician rejected successfully' });
  } catch (err) {
    console.error('Reject technician error:', err);
    res.status(500).json({ message: 'Server error rejecting technician' });
  }
};

exports.getPendingTechnicians = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, email, phone, skills, experience, verification_status, id_proof_url FROM technicians WHERE verification_status = $1',
      ['pending']
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Fetch pending technicians error:', err);
    res.status(500).json({ message: 'Server error fetching pending technicians' });
  }
};

// ---- Bookings Management ----

exports.getAllBookings = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT b.*, c.name as customer_name, c.phone as customer_phone,
              t.name as technician_name, t.phone as technician_phone
       FROM bookings b
       JOIN customers c ON b.customer_id = c.id
       LEFT JOIN technicians t ON b.technician_id = t.id
       ORDER BY b.created_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Fetch bookings error:', err);
    res.status(500).json({ message: 'Server error fetching bookings' });
  }
};

exports.getBookingStats = async (req, res) => {
  try {
    const totalBookingsResult = await pool.query('SELECT COUNT(*) as total FROM bookings');
    const completedBookingsResult = await pool.query("SELECT COUNT(*) as total FROM bookings WHERE status = 'completed'");
    const pendingBookingsResult = await pool.query("SELECT COUNT(*) as total FROM bookings WHERE status = 'pending'");
    const inProgressBookingsResult = await pool.query("SELECT COUNT(*) as total FROM bookings WHERE status = 'in_progress'");

    res.json({
      total: totalBookingsResult.rows[0].total,
      completed: completedBookingsResult.rows[0].total,
      pending: pendingBookingsResult.rows[0].total,
      inProgress: inProgressBookingsResult.rows[0].total
    });
  } catch (err) {
    console.error('Fetch booking stats error:', err);
    res.status(500).json({ message: 'Server error fetching booking stats' });
  }
};

// ---- Resale Requests Management ----

exports.getAllResaleRequests = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT r.*, c.name as customer_name, c.phone as customer_phone
       FROM resale_requests r
       JOIN customers c ON r.customer_id = c.id
       ORDER BY r.created_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Fetch resale requests error:', err);
    res.status(500).json({ message: 'Server error fetching resale requests' });
  }
};

exports.approveResaleRequest = async (req, res) => {
  try {
    const resaleId = req.params.resaleId;
    await pool.query('UPDATE resale_requests SET status = $1 WHERE id = $2', ['approved', resaleId]);
    res.json({ message: 'Resale request approved' });
  } catch (err) {
    console.error('Approve resale error:', err);
    res.status(500).json({ message: 'Server error approving resale request' });
  }
};

exports.rejectResaleRequest = async (req, res) => {
  try {
    const resaleId = req.params.resaleId;
    await pool.query('UPDATE resale_requests SET status = $1 WHERE id = $2', ['rejected', resaleId]);
    res.json({ message: 'Resale request rejected' });
  } catch (err) {
    console.error('Reject resale error:', err);
    res.status(500).json({ message: 'Server error rejecting resale request' });
  }
};

// ---- Dashboard Overview ----

exports.getDashboardOverview = async (req, res) => {
  try {
    const totalCustomersResult = await pool.query('SELECT COUNT(*) as total FROM customers');
    const totalTechniciansResult = await pool.query('SELECT COUNT(*) as total FROM technicians');
    const verifiedTechniciansResult = await pool.query("SELECT COUNT(*) as total FROM technicians WHERE verification_status = 'verified'");
    const totalBookingsResult = await pool.query('SELECT COUNT(*) as total FROM bookings');
    const completedBookingsResult = await pool.query("SELECT COUNT(*) as total FROM bookings WHERE status = 'completed'");
    const totalEarningsResult = await pool.query('SELECT SUM(amount) as total FROM earnings WHERE status = $1', ['completed']);

    res.json({
      totalCustomers: totalCustomersResult.rows[0].total,
      totalTechnicians: totalTechniciansResult.rows[0].total,
      verifiedTechnicians: verifiedTechniciansResult.rows[0].total,
      totalBookings: totalBookingsResult.rows[0].total,
      completedBookings: completedBookingsResult.rows[0].total,
      totalEarnings: totalEarningsResult.rows[0].total || 0
    });
  } catch (err) {
    console.error('Dashboard overview error:', err);
    res.status(500).json({ message: 'Server error fetching dashboard overview' });
  }
};