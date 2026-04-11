const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// ======== CUSTOMER AUTH ========

exports.customerSignup = async (req, res) => {
  try {
    const { name, phone, email, password, address } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const [existing] = await pool.query('SELECT id FROM customers WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const [result] = await pool.query(
      'INSERT INTO customers (name, phone, email, password, address) VALUES (?, ?, ?, ?, ?)',
      [name, phone, email, hashedPassword, address]
    );

    res.status(201).json({
      message: 'Customer registered successfully',
      customerId: result.insertId,
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

    const [rows] = await pool.query('SELECT * FROM customers WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const customer = rows[0];
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
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ message: 'Server error during login' });
  }
};

// ======== TECHNICIAN AUTH ========

exports.technicianSignup = async (req, res) => {
  try {
    const { name, phone, email, password, skills, experience } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const [existing] = await pool.query('SELECT id FROM technicians WHERE email = ?', [email]);
    if (existing.length > 0) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    let id_proof_url = null;
    if (req.file) {
      id_proof_url = '/uploads/' + req.file.filename;
    }

    const [result] = await pool.query(
      'INSERT INTO technicians (name, phone, email, password, skills, experience, verification_status, id_proof_url) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [name, phone, email, hashedPassword, skills || '', experience || 0, 'pending', id_proof_url]
    );

    res.status(201).json({
      message: 'Technician registered successfully. Awaiting verification.',
      technicianId: result.insertId,
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

    const [rows] = await pool.query('SELECT * FROM technicians WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const technician = rows[0];

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
    const [rows] = await pool.query('SELECT * FROM admins WHERE email = ?', [email]);
    if (rows.length === 0) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const admin = rows[0];
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