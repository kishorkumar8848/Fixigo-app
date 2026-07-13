const pool = require('../config/db');

// ======== CUSTOMER RESALE FUNCTIONS ========

exports.submitResaleRequest = async (req, res) => {
  try {
    const { 
      customerId, 
      appliance_type, 
      condition_description, 
      expected_price,
      brand,
      age_years,
      original_price,
      estimated_value,
      working_status,
      cosmetic_condition,
      has_bill,
      has_box,
      has_accessories,
      address
    } = req.body;

    console.log('Resale request received:', { customerId, appliance_type, expected_price, address });

    if (!customerId || !appliance_type || !expected_price) {
      console.error('Missing required fields:', { customerId, appliance_type, expected_price });
      return res.status(400).json({ message: 'Missing required fields: customerId, appliance_type, and expected_price are required' });
    }

    let imageUrl = '';
    if (req.file) {
      imageUrl = '/uploads/' + req.file.filename;
      console.log('Image uploaded:', imageUrl);
    }

    const queryText = `
      INSERT INTO resale_requests (
        customer_id, appliance_type, condition_description, expected_price, status,
        brand, age_years, original_price, estimated_value, working_status,
        cosmetic_condition, has_bill, has_box, has_accessories, image_url, address
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16) 
      RETURNING id
    `;

    const params = [
      customerId, 
      appliance_type, 
      condition_description || '', 
      expected_price, 
      'pending',
      brand || '',
      age_years ? parseInt(age_years) : 0,
      original_price ? parseFloat(original_price) : 0.0,
      estimated_value ? parseFloat(estimated_value) : 0.0,
      working_status || 'Working',
      cosmetic_condition || 'Good',
      has_bill === 'true' || has_bill === 1 || has_bill === '1' ? 1 : 0,
      has_box === 'true' || has_box === 1 || has_box === '1' ? 1 : 0,
      has_accessories === 'true' || has_accessories === 1 || has_accessories === '1' ? 1 : 0,
      imageUrl,
      address || ''
    ];

    console.log('Inserting resale request with params:', params);

    const result = await pool.query(queryText, params);
    const resaleRequestId = result.rows[0].id;

    console.log('Resale request created successfully with ID:', resaleRequestId);

    res.status(201).json({ 
      message: 'Resale request submitted successfully',
      resaleRequestId
    });
  } catch (err) {
    console.error('Submit resale request error:', err);
    console.error('Error details:', err.message);
    console.error('Error stack:', err.stack);
    res.status(500).json({ message: `Server error submitting resale request: ${err.message}` });
  }
};

exports.getCustomerResaleRequests = async (req, res) => {
  try {
    const customerId = req.params.customerId;

    const result = await pool.query(
      'SELECT * FROM resale_requests WHERE customer_id = $1 ORDER BY created_at DESC',
      [customerId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Fetch resale requests error:', err);
    res.status(500).json({ message: 'Server error fetching resale requests' });
  }
};