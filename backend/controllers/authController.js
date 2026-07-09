const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

function geocodeAddress(address) {
  const addr = (address || '').toLowerCase();
  if (addr.includes('indiranagar')) {
    return { latitude: 12.971899, longitude: 77.641110 };
  } else if (addr.includes('koramangala')) {
    return { latitude: 12.935193, longitude: 77.624481 };
  } else if (addr.includes('hsr')) {
    return { latitude: 12.910079, longitude: 77.645020 };
  } else if (addr.includes('jayanagar')) {
    return { latitude: 12.930773, longitude: 77.583830 };
  } else if (addr.includes('whitefield')) {
    return { latitude: 12.969819, longitude: 77.749972 };
  } else if (addr.includes('hebbal')) {
    return { latitude: 13.035770, longitude: 77.597022 };
  } else if (addr.includes('rajajinagar')) {
    return { latitude: 12.990135, longitude: 77.552554 };
  } else if (addr.includes('mg road') || addr.includes('central')) {
    return { latitude: 12.973783, longitude: 77.611130 };
  }
  // Default to central Bengaluru with slight random offset
  return {
    latitude: 12.971598 + (Math.random() - 0.5) * 0.05,
    longitude: 77.594562 + (Math.random() - 0.5) * 0.05
  };
}


// ======== CUSTOMER AUTH ========

exports.customerSignup = async (req, res) => {
  try {
    const { name, phone, email, password, address } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const existingResult = await pool.query('SELECT id FROM customers WHERE email = $1', [email]);
    if (existingResult.rows.length > 0) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO customers (name, phone, email, password, address) VALUES ($1, $2, $3, $4, $5) RETURNING id',
      [name, phone, email, hashedPassword, address]
    );

    const customerId = result.rows[0].id;

    res.status(201).json({
      message: 'Customer registered successfully',
      customerId,
      name,
      email,
    });
  } catch (err) {
    console.error('Signup error:', err);
    res.status(500).json({ message: 'Server error during signup' });
  }
};

exports.customerLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password required' });
    }

    const result = await pool.query('SELECT * FROM customers WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const customer = result.rows[0];
    const validPassword = await bcrypt.compare(password, customer.password);
    if (!validPassword) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: customer.id, role: 'customer', email: customer.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      customerId: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Server error during login' });
  }
};

// ======== TECHNICIAN AUTH ========

exports.technicianSignup = async (req, res) => {
  try {
    const { name, phone, email, password, skills, experience, address } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const existingResult = await pool.query('SELECT id FROM technicians WHERE email = $1', [email]);
    if (existingResult.rows.length > 0) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    let id_proof_url = null;
    if (req.file) {
      id_proof_url = '/uploads/' + req.file.filename;
    }

    const coords = geocodeAddress(address);
    const latitude = req.body.latitude || coords.latitude;
    const longitude = req.body.longitude || coords.longitude;

    const result = await pool.query(
      'INSERT INTO technicians (name, phone, email, password, skills, experience, verification_status, id_proof_url, latitude, longitude, address) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id',
      [name, phone, email, hashedPassword, skills || '', experience || 0, 'pending', id_proof_url, latitude, longitude, address || '']
    );

    const technicianId = result.rows[0].id;

    res.status(201).json({
      message: 'Technician registered successfully. Awaiting verification.',
      technicianId,
      status: 'pending',
      name,
      email,
    });
  } catch (err) {
    console.error('Signup error:', err);
    res.status(500).json({ message: 'Server error during signup' });
  }
};

exports.technicianLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password required' });
    }

    // Admin login intercept
    if (email === 'admin@fixigo.com') {
      const adminResult = await pool.query('SELECT * FROM admins WHERE email = $1', [email]);
      if (adminResult.rows.length > 0) {
        const admin = adminResult.rows[0];
        const validPassword = await bcrypt.compare(password, admin.password);
        if (validPassword) {
          const token = jwt.sign(
            { id: admin.id, role: 'admin', email: admin.email },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
          );
          return res.json({
            message: 'Admin login successful',
            token,
            role: 'admin',
            adminId: admin.id,
            name: 'System Admin',
            email: admin.email,
          });
        }
      }
    }

    const result = await pool.query('SELECT * FROM technicians WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const technician = result.rows[0];

    if (technician.verification_status === 'rejected') {
      return res.status(403).json({ message: 'Your account has been rejected' });
    }

    if (technician.verification_status === 'pending') {
      return res.status(403).json({ message: 'Your account is pending verification by admin' });
    }

    const validPassword = await bcrypt.compare(password, technician.password);
    if (!validPassword) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: technician.id, role: 'technician', email: technician.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Login successful',
      token,
      technicianId: technician.id,
      verificationStatus: technician.verification_status,
      name: technician.name,
      email: technician.email,
      address: technician.address || '',
      latitude: parseFloat(technician.latitude || 12.971598),
      longitude: parseFloat(technician.longitude || 77.594562),
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Server error during login' });
  }
};

// ======== ADMIN AUTH ========

exports.adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password required' });
    }

    // Check against admin credentials
    const result = await pool.query('SELECT * FROM admins WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const admin = result.rows[0];
    const validPassword = await bcrypt.compare(password, admin.password);
    if (!validPassword) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { id: admin.id, role: 'admin', email: admin.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({ message: 'Admin login successful', token, adminId: admin.id });
  } catch (err) {
    console.error('Admin login error:', err);
    res.status(500).json({ message: 'Server error during login' });
  }
};

// ======== CUSTOMER PROFILE MANAGEMENT ========

exports.getCustomerProfile = async (req, res) => {
  try {
    const customerId = req.params.customerId;

    // Get user details
    const userResult = await pool.query(
      'SELECT name, email, phone, address FROM customers WHERE id = $1',
      [customerId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }

    const user = userResult.rows[0];

    // Compute stats
    const totalRepairsRes = await pool.query(
      'SELECT COUNT(*) FROM bookings WHERE customer_id = $1',
      [customerId]
    );

    // Active warranties is count of completed bookings in the last 90 days
    const activeWarrantiesRes = await pool.query(
      "SELECT COUNT(*) FROM bookings WHERE customer_id = $1 AND status = 'completed' AND updated_at >= datetime('now', '-90 days')",
      [customerId]
    );

    // Appliances sold is count of resale requests with status 'sold'
    const appliancesSoldRes = await pool.query(
      "SELECT COUNT(*) FROM resale_requests WHERE customer_id = $1 AND status = 'sold'",
      [customerId]
    );

    res.json({
      name: user.name,
      email: user.email,
      phone: user.phone || '',
      address: user.address || '',
      stats: {
        totalRepairs: parseInt(totalRepairsRes.rows[0].count, 10),
        activeWarranties: parseInt(activeWarrantiesRes.rows[0].count, 10),
        appliancesSold: parseInt(appliancesSoldRes.rows[0].count, 10),
      }
    });
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ message: 'Server error fetching profile' });
  }
};

exports.updateCustomerProfile = async (req, res) => {
  try {
    const customerId = req.params.customerId;
    const { name, email, phone, address } = req.body;

    if (!name || !email) {
      return res.status(400).json({ message: 'Name and email are required' });
    }

    await pool.query(
      'UPDATE customers SET name = $1, email = $2, phone = $3, address = $4 WHERE id = $5',
      [name, email, phone || '', address || '', customerId]
    );

    res.json({ message: 'Profile updated successfully' });
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ message: 'Server error updating profile' });
  }
};

exports.customerGoogleLogin = async (req, res) => {
  try {
    const { email, name } = req.body;

    if (!email || !name) {
      return res.status(400).json({ message: 'Email and name are required' });
    }

    // Check if customer exists
    let result = await pool.query('SELECT * FROM customers WHERE email = $1', [email]);
    let customer;

    if (result.rows.length === 0) {
      // Register new customer with a random dummy password (since it's Google login)
      const dummyPassword = Math.random().toString(36).slice(-12);
      const hashedPassword = await bcrypt.hash(dummyPassword, 10);

      const insertResult = await pool.query(
        'INSERT INTO customers (name, email, password, phone, address) VALUES ($1, $2, $3, $4, $5) RETURNING *',
        [name, email, hashedPassword, '', '']
      );
      customer = insertResult.rows[0];
    } else {
      customer = result.rows[0];
    }

    const token = jwt.sign(
      { id: customer.id, role: 'customer', email: customer.email },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: 'Google login successful',
      token,
      customerId: customer.id,
      name: customer.name,
      email: customer.email,
      phone: customer.phone || '',
      address: customer.address || '',
    });
  } catch (err) {
    console.error('Google login error:', err);
    res.status(500).json({ message: 'Server error during Google login' });
  }
};

exports.getTechnicianProfile = async (req, res) => {
  try {
    const technicianId = req.params.technicianId;

    const result = await pool.query(
      'SELECT id, name, email, phone, skills, experience, rating, verification_status, total_jobs, address, latitude, longitude FROM technicians WHERE id = $1',
      [technicianId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Technician not found' });
    }

    const tech = result.rows[0];

    // Compute total earnings
    const earningsRes = await pool.query(
      'SELECT COALESCE(SUM(amount), 0) as total FROM earnings WHERE technician_id = $1',
      [technicianId]
    );
    const totalEarnings = parseFloat(earningsRes.rows[0].total || 0);

    res.json({
      id: tech.id,
      name: tech.name,
      email: tech.email,
      phone: tech.phone || '',
      skills: tech.skills || '',
      experience: tech.experience || 0,
      rating: parseFloat(tech.rating || 0),
      verificationStatus: tech.verification_status,
      totalJobs: tech.total_jobs || 0,
      totalEarnings,
      address: tech.address || '',
      latitude: parseFloat(tech.latitude || 12.971598),
      longitude: parseFloat(tech.longitude || 77.594562),
    });
  } catch (err) {
    console.error('Get tech profile error:', err);
    res.status(500).json({ message: 'Server error fetching profile' });
  }
};

exports.getTechnicianDashboard = async (req, res) => {
  try {
    const technicianId = req.params.technicianId;

    // 1. Today's Jobs count
    const todayJobsRes = await pool.query(
      "SELECT COUNT(*) FROM jobs WHERE technician_id = $1 AND status IN ('accepted', 'in_progress', 'completed') AND created_at::date = CURRENT_DATE",
      [technicianId]
    );

    // 2. Today's Earnings
    const todayEarningsRes = await pool.query(
      "SELECT COALESCE(SUM(amount), 0) as total FROM earnings WHERE technician_id = $1 AND created_at::date = CURRENT_DATE",
      [technicianId]
    );

    // 3. Pending Jobs requests count
    const pendingJobsRes = await pool.query(
      "SELECT COUNT(*) FROM jobs WHERE technician_id = $1 AND status = 'assigned'",
      [technicianId]
    );

    // 4. Rating and general details
    const techRes = await pool.query(
      "SELECT rating, name, skills FROM technicians WHERE id = $1",
      [technicianId]
    );
    if (techRes.rows.length === 0) {
      return res.status(404).json({ message: 'Technician not found' });
    }
    const tech = techRes.rows[0];

    // 5. Today's Jobs list
    const jobsListRes = await pool.query(
      `SELECT j.*, b.appliance_type, b.issue_description, b.location, b.preferred_date, c.name as customer_name, c.phone as customer_phone
       FROM jobs j
       JOIN bookings b ON j.booking_id = b.id
       JOIN customers c ON b.customer_id = c.id
       WHERE j.technician_id = $1 AND j.status IN ('accepted', 'in_progress', 'completed')
       ORDER BY j.created_at DESC`,
      [technicianId]
    );

    res.json({
      name: tech.name,
      rating: parseFloat(tech.rating || 0),
      skills: tech.skills || '',
      stats: {
        todayJobsCount: parseInt(todayJobsRes.rows[0].count, 10),
        todayEarnings: parseFloat(todayEarningsRes.rows[0].total || 0),
        pendingJobsCount: parseInt(pendingJobsRes.rows[0].count, 10),
        rating: parseFloat(tech.rating || 0),
      },
      todayJobs: jobsListRes.rows
    });
  } catch (err) {
    console.error('Get tech dashboard error:', err);
    res.status(500).json({ message: 'Server error fetching dashboard' });
  }
};

exports.updateTechnicianProfile = async (req, res) => {
  try {
    const technicianId = req.params.technicianId;
    const { name, email, phone, address } = req.body;

    if (!name || !email) {
      return res.status(400).json({ message: 'Name and email are required' });
    }

    let query = 'UPDATE technicians SET name = $1, email = $2, phone = $3, address = $4';
    const params = [name, email, phone || '', address || ''];

    if (address) {
      const coords = geocodeAddress(address);
      query += ', latitude = $5, longitude = $6';
      params.push(coords.latitude, coords.longitude);
    }

    query += ' WHERE id = $' + (params.length + 1);
    params.push(technicianId);

    await pool.query(query, params);

    res.json({ message: 'Profile updated successfully' });
  } catch (err) {
    console.error('Update tech profile error:', err);
    res.status(500).json({ message: 'Server error updating profile' });
  }
};