const pool = require('../config/db');

// ======== CUSTOMER RESALE FUNCTIONS ========

exports.submitResaleRequest = async (req, res) => {
  try {
    const { customerId, appliance_type, condition_description, expected_price } = req.body;

    if (!customerId || !appliance_type || !expected_price) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const [result] = await pool.query(
      'INSERT INTO resale_requests (customer_id, appliance_type, condition_description, expected_price, status) VALUES (?, ?, ?, ?, ?)',
      [customerId, appliance_type, condition_description || '', expected_price, 'pending']
    );

    res.status(201).json({ 
      message: 'Resale request submitted successfully',
      resaleRequestId: result.insertId
    });
  } catch (err) {
    console.error('Submit resale request error:', err);
    res.status(500).json({ message: 'Server error submitting resale request' });
  }
};

exports.getCustomerResaleRequests = async (req, res) => {
  try {
    const customerId = req.params.customerId;

    const [requests] = await pool.query(
      'SELECT * FROM resale_requests WHERE customer_id = ? ORDER BY created_at DESC',
      [customerId]
    );

    res.json(requests);
  } catch (err) {
    console.error('Fetch resale requests error:', err);
    res.status(500).json({ message: 'Server error fetching resale requests' });
  }
};