const pool = require('../config/db');

// ======== CUSTOMER BOOKING FUNCTIONS ========

function haversineDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function isSkillMatch(techSkillsString, applianceName) {
  if (!techSkillsString) return false;
  const skills = techSkillsString.split(',').map(s => s.trim().toLowerCase());
  const appLower = applianceName.toLowerCase();
  for (const skill of skills) {
    if (appLower.includes(skill) || skill.includes(appLower)) return true;
    if (skill.includes('air conditioner') && (appLower.includes('ac') || appLower.includes('cooler') || appLower.includes('conditioner'))) return true;
    if (skill.includes('laptop') && (appLower.includes('pc') || appLower.includes('desktop') || appLower.includes('laptop') || appLower.includes('printer') || appLower.includes('router') || appLower.includes('cctv'))) return true;
    if (skill.includes('kitchen') && (appLower.includes('mixer') || appLower.includes('stove') || appLower.includes('kettle') || appLower.includes('cooker') || appLower.includes('fryer') || appLower.includes('toaster') || appLower.includes('coffee') || appLower.includes('dishwasher') || appLower.includes('oven') || appLower.includes('microwave') || appLower.includes('chimney'))) return true;
    if (skill.includes('electrical') && (appLower.includes('fan') || appLower.includes('switchboard') || appLower.includes('wiring') || appLower.includes('mcb') || appLower.includes('fuse') || appLower.includes('bell') || appLower.includes('inverter') || appLower.includes('ups') || appLower.includes('stabilizer') || appLower.includes('generator'))) return true;
    if (skill.includes('water heater') && (appLower.includes('geyser') || appLower.includes('heater') || appLower.includes('solar') || appLower.includes('pump') || appLower.includes('motor') || appLower.includes('borewell'))) return true;
  }
  return false;
}

function selectTechniciansForBooking(technicians, applianceName, bookingLat, bookingLon, maxDistanceKm = 20) {
  const ranked = [];

  for (const tech of technicians) {
    if (!tech || !isSkillMatch(tech.skills, applianceName)) continue;

    const techLat = parseFloat(tech.latitude || 12.971598);
    const techLon = parseFloat(tech.longitude || 77.594562);
    const distance = haversineDistance(
      parseFloat(bookingLat || 12.971598),
      parseFloat(bookingLon || 77.594562),
      techLat,
      techLon
    );

    if (distance <= maxDistanceKm) {
      ranked.push({ id: tech.id, distance, latitude: techLat, longitude: techLon });
    }
  }

  ranked.sort((a, b) => a.distance - b.distance);
  return ranked;
}

exports.selectTechniciansForBooking = selectTechniciansForBooking;

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

exports.createBooking = async (req, res) => {
  try {
    const { 
      customerId, 
      appliance_type, 
      issue_description, 
      location, 
      preferred_date,
      booking_fee,
      payment_status,
      razorpay_payment_id,
      razorpay_order_id,
      estimated_price_min,
      estimated_price_max
    } = req.body;

    if (!customerId || !appliance_type || !issue_description || !location) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    // Geocode location to coordinates
    const coords = geocodeAddress(location);
    const bookingLat = req.body.latitude || coords.latitude;
    const bookingLon = req.body.longitude || coords.longitude;

    const result = await pool.query(
      `INSERT INTO bookings (
        customer_id, appliance_type, issue_description, location, preferred_date, status, latitude, longitude,
        booking_fee, payment_status, razorpay_payment_id, razorpay_order_id, estimated_price_min, estimated_price_max
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING id`,
      [
        customerId, 
        appliance_type, 
        issue_description, 
        location, 
        preferred_date || null, 
        'pending', 
        bookingLat, 
        bookingLon,
        booking_fee || 50.00,
        payment_status || 'paid',
        razorpay_payment_id || null,
        razorpay_order_id || null,
        estimated_price_min || null,
        estimated_price_max || null
      ]
    );

    const bookingId = result.rows[0].id;

    // Find verified technicians
    const techsRes = await pool.query("SELECT id, name, skills, latitude, longitude FROM technicians WHERE verification_status = 'verified'");
    const techs = techsRes.rows;

    const matchingTechs = selectTechniciansForBooking(
      techs,
      appliance_type,
      bookingLat,
      bookingLon,
      20.0
    );

    const assignedTechIds = [];
    if (matchingTechs.length > 0) {
      for (const tech of matchingTechs) {
        await pool.query(
          'INSERT INTO jobs (booking_id, technician_id, status) VALUES ($1, $2, $3)',
          [bookingId, tech.id, 'assigned']
        );
        assignedTechIds.push(tech.id);
      }
    } else {
      // Fallback: If no technician matches within 20km and appropriate skill,
      // assign it to the first verified technician (or a default technician like John Doe ID=1)
      const defaultTechRes = await pool.query("SELECT id FROM technicians WHERE verification_status = 'verified' LIMIT 1");
      if (defaultTechRes.rows.length > 0) {
        const techId = defaultTechRes.rows[0].id;
        await pool.query(
          'INSERT INTO jobs (booking_id, technician_id, status) VALUES ($1, $2, $3)',
          [bookingId, techId, 'assigned']
        );
        assignedTechIds.push(techId);
      }
    }

    res.status(201).json({ 
      message: 'Booking created successfully',
      bookingId,
      assignedTechniciansCount: assignedTechIds.length
    });
  } catch (err) {
    console.error('Booking error:', err);
    res.status(500).json({ message: 'Server error creating booking' });
  }
};

exports.getCustomerBookings = async (req, res) => {
  try {
    const customerId = req.params.customerId;

    const result = await pool.query(
      `SELECT b.*, t.name as technician_name 
       FROM bookings b
       LEFT JOIN technicians t ON b.technician_id = t.id
       WHERE b.customer_id = $1
       ORDER BY b.created_at DESC`,
      [customerId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Fetch bookings error:', err);
    res.status(500).json({ message: 'Server error fetching bookings' });
  }
};

exports.getBookingHistory = async (req, res) => {
  try {
    const customerId = req.params.customerId;

    const result = await pool.query(
      `SELECT b.*, t.name as technician_name, t.rating as technician_rating, j.price as job_price
       FROM bookings b
       LEFT JOIN technicians t ON b.technician_id = t.id
       LEFT JOIN jobs j ON j.booking_id = b.id
       WHERE b.customer_id = $1 AND b.status = 'completed'
       ORDER BY b.updated_at DESC`,
      [customerId]
    );

    res.json(result.rows);
  } catch (err) {
    console.error('Fetch history error:', err);
    res.status(500).json({ message: 'Server error fetching history' });
  }
};

exports.getBookingDetails = async (req, res) => {
  try {
    const bookingId = req.params.bookingId;

    const result = await pool.query(
      `SELECT b.*, t.name as technician_name, t.phone as technician_phone, t.rating
       FROM bookings b
       LEFT JOIN technicians t ON b.technician_id = t.id
       WHERE b.id = $1`,
      [bookingId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('Fetch booking details error:', err);
    res.status(500).json({ message: 'Server error fetching booking details' });
  }
};

exports.cancelBooking = async (req, res) => {
  try {
    const bookingId = req.params.bookingId;
    const { reason } = req.body;

    if (!reason) {
      return res.status(400).json({ message: 'Cancellation reason is required' });
    }

    // Update booking status to cancelled and write cancellation reason
    const bookingRes = await pool.query(
      `UPDATE bookings 
       SET status = 'cancelled', cancellation_reason = $1, updated_at = datetime('now') 
       WHERE id = $2 RETURNING *`,
      [reason, bookingId]
    );

    if (bookingRes.rows.length === 0) {
      return res.status(404).json({ message: 'Booking not found' });
    }

    // Also update associated jobs status to cancelled
    await pool.query(
      `UPDATE jobs 
       SET status = 'cancelled', updated_at = datetime('now') 
       WHERE booking_id = $1`,
      [bookingId]
    );

    res.json({ 
      message: 'Booking cancelled successfully', 
      booking: bookingRes.rows[0] 
    });
  } catch (err) {
    console.error('Cancel booking error:', err);
    res.status(500).json({ message: 'Server error cancelling booking' });
  }
};

function calculateEstimate(appliance, issue) {
  const appLower = (appliance || '').toLowerCase();
  const issueLower = (issue || '').toLowerCase();

  let baseMin = 150;
  let baseMax = 300;

  const isPremium = appLower.includes('ac') ||
      appLower.includes('conditioner') ||
      appLower.includes('refrigerator') ||
      appLower.includes('freezer') ||
      appLower.includes('laptop') ||
      appLower.includes('pc') ||
      appLower.includes('desktop') ||
      appLower.includes('television') ||
      appLower.includes('tv') ||
      appLower.includes('solar') ||
      appLower.includes('pump') ||
      appLower.includes('borewell');

  const isMedium = appLower.includes('washing') ||
      appLower.includes('dryer') ||
      appLower.includes('laundry') ||
      appLower.includes('microwave') ||
      appLower.includes('oven') ||
      appLower.includes('dishwasher') ||
      appLower.includes('purifier') ||
      appLower.includes('geyser') ||
      appLower.includes('heater') ||
      appLower.includes('cctv') ||
      appLower.includes('router') ||
      appLower.includes('lock') ||
      appLower.includes('generator') ||
      appLower.includes('inverter');

  if (isPremium) {
    baseMin = 400;
    baseMax = 800;
  } else if (isMedium) {
    baseMin = 250;
    baseMax = 500;
  }

  let factorMin = 1.0;
  let factorMax = 1.0;

  if (issueLower.includes('not turning') || issueLower.includes('display')) {
    factorMin = 1.5;
    factorMax = 2.0;
  } else if (issueLower.includes('not cooling') ||
      issueLower.includes('not heating') ||
      issueLower.includes('leakage') ||
      issueLower.includes('noise')) {
    factorMin = 1.2;
    factorMax = 1.5;
  } else if (issueLower.includes('remote') || issueLower.includes('other')) {
    factorMin = 0.8;
    factorMax = 1.0;
  }

  const minCharge = Math.round(baseMin * factorMin);
  const maxCharge = Math.round(baseMax * factorMax);

  return {
    inspection: 99,
    repairMin: minCharge,
    repairMax: maxCharge,
    totalMin: minCharge + 99,
    totalMax: maxCharge + 99
  };
}

exports.initiateBooking = async (req, res) => {
  try {
    const { customerId, appliance_type, issue_description, location, preferred_date } = req.body;

    if (!customerId || !appliance_type || !issue_description || !location) {
      return res.status(400).json({ message: 'Missing required fields' });
    }

    const customerRes = await pool.query('SELECT * FROM customers WHERE id = $1', [customerId]);
    if (customerRes.rows.length === 0) {
      return res.status(404).json({ message: 'Customer not found' });
    }
    const customer = customerRes.rows[0];

    // Calculate dynamic estimates
    const estimate = calculateEstimate(appliance_type, issue_description);
    
    // Geocode coordinates
    const coords = geocodeAddress(location);
    const bookingLat = req.body.latitude || coords.latitude;
    const bookingLon = req.body.longitude || coords.longitude;

    // Insert booking in pending_payment state
    const result = await pool.query(
      `INSERT INTO bookings (
        customer_id, appliance_type, issue_description, location, preferred_date, status, latitude, longitude,
        booking_fee, payment_status, estimated_price_min, estimated_price_max
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id`,
      [
        customerId,
        appliance_type,
        issue_description,
        location,
        preferred_date || null,
        'pending_payment',
        bookingLat,
        bookingLon,
        50.00,
        'unpaid',
        estimate.totalMin,
        estimate.totalMax
      ]
    );
    const bookingId = result.rows[0].id;

    // Create payment link
    const isMock = process.env.RAZORPAY_KEY_ID === 'rzp_test_mockkeyid123' || !process.env.RAZORPAY_KEY_ID;
    let paymentUrl = '';
    let razorpayOrderId = '';

    if (isMock) {
      paymentUrl = `http://${req.headers.host || 'localhost:3000'}/bookings/mock-payment?booking_id=${bookingId}&amount=50`;
      razorpayOrderId = `order_mock_${bookingId}_${Date.now().toString().slice(-4)}`;
    } else {
      const razorpay = require('../config/razorpay');
      try {
        const paymentLink = await razorpay.paymentLink.create({
          amount: 50 * 100, // paise
          currency: "INR",
          accept_partial: false,
          reference_id: `booking_${bookingId}`,
          description: `Fixigo Booking Fee for Booking #${bookingId}`,
          customer: {
            name: customer.name,
            email: customer.email,
            contact: customer.phone || '9876543210'
          },
          notify: {
            sms: false,
            email: false
          },
          callback_url: `http://${req.headers.host || 'localhost:3000'}/bookings/payment-callback?booking_id=${bookingId}`,
          callback_method: "get"
        });
        paymentUrl = paymentLink.short_url;
        razorpayOrderId = paymentLink.order_id || `order_${paymentLink.id}`;
      } catch (err) {
        console.error('Razorpay API error, falling back to mock:', err.message);
        paymentUrl = `http://${req.headers.host || 'localhost:3000'}/bookings/mock-payment?booking_id=${bookingId}&amount=50`;
        razorpayOrderId = `order_mock_${bookingId}_${Date.now().toString().slice(-4)}`;
      }
    }

    // Save order details to booking
    await pool.query(
      'UPDATE bookings SET razorpay_order_id = $1 WHERE id = $2',
      [razorpayOrderId, bookingId]
    );

    res.json({
      message: 'Booking initiated',
      bookingId,
      paymentUrl,
      orderId: razorpayOrderId,
      estimated_price_min: estimate.totalMin,
      estimated_price_max: estimate.totalMax
    });
  } catch (err) {
    console.error('Initiate booking error:', err);
    res.status(500).json({ message: 'Server error initiating booking' });
  }
};

exports.handlePaymentCallback = async (req, res) => {
  try {
    const { booking_id, razorpay_payment_id, razorpay_payment_link_id, razorpay_payment_link_status } = req.query;

    if (!booking_id) {
      return res.status(400).send('Missing booking_id');
    }

    const isConfirmed = razorpay_payment_link_status === 'confirmed' || (razorpay_payment_id && razorpay_payment_id.startsWith('pay_'));

    if (isConfirmed) {
      // 1. Fetch booking
      const bookingRes = await pool.query('SELECT * FROM bookings WHERE id = $1', [booking_id]);
      if (bookingRes.rows.length === 0) {
        return res.status(404).send('Booking not found');
      }

      const booking = bookingRes.rows[0];

      if (booking.payment_status !== 'paid') {
        // 2. Update payment status and booking status
        await pool.query(
          `UPDATE bookings 
           SET payment_status = 'paid', status = 'pending', razorpay_payment_id = $1, updated_at = datetime('now') 
           WHERE id = $2`,
          [razorpay_payment_id || `pay_${Date.now()}`, booking_id]
        );

        // 3. Find and assign technicians
        const techsRes = await pool.query("SELECT id, name, skills, latitude, longitude FROM technicians WHERE verification_status = 'verified'");
        const techs = techsRes.rows;

        const matchingTechs = selectTechniciansForBooking(
          techs,
          booking.appliance_type,
          parseFloat(booking.latitude || 12.971598),
          parseFloat(booking.longitude || 77.594562),
          20.0
        );

        const assignedTechIds = [];
        if (matchingTechs.length > 0) {
          for (const tech of matchingTechs) {
            await pool.query(
              'INSERT INTO jobs (booking_id, technician_id, status) VALUES ($1, $2, $3)',
              [booking_id, tech.id, 'assigned']
            );
            assignedTechIds.push(tech.id);
          }
        } else {
          const defaultTechRes = await pool.query("SELECT id FROM technicians WHERE verification_status = 'verified' LIMIT 1");
          if (defaultTechRes.rows.length > 0) {
            const techId = defaultTechRes.rows[0].id;
            await pool.query(
              'INSERT INTO jobs (booking_id, technician_id, status) VALUES ($1, $2, $3)',
              [booking_id, techId, 'assigned']
            );
            assignedTechIds.push(techId);
          }
        }
      }

      res.send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Payment Successful</title>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { font-family: 'Segoe UI', system-ui, sans-serif; text-align: center; padding: 50px 20px; background-color: #f7f9fc; color: #1a1f36; }
            .card { background: white; padding: 40px; border-radius: 16px; box-shadow: 0 4px 12px rgba(0,0,0,0.05); display: inline-block; max-width: 400px; width: 100%; }
            .icon { font-size: 64px; color: #2ecc71; margin-bottom: 20px; }
            h1 { font-size: 24px; margin-bottom: 10px; color: #2ecc71; }
            p { font-size: 14px; color: #697386; margin-bottom: 30px; line-height: 1.5; }
            .btn { background: #26da89; color: white; border: none; padding: 12px 24px; border-radius: 8px; font-weight: bold; cursor: pointer; text-decoration: none; display: inline-block; }
          </style>
        </head>
        <body>
          <div class="card">
            <div class="icon">✓</div>
            <h1>Payment Successful!</h1>
            <p>Your ₹50.00 booking fee has been processed securely. You can now close this window and track your repair service in the Fixigo app.</p>
            <button class="btn" onclick="window.close()">Close Window</button>
          </div>
        </body>
        </html>
      `);
    } else {
      res.status(400).send('Payment not confirmed. Please try again.');
    }
  } catch (err) {
    console.error('Callback error:', err);
    res.status(500).send('Server error processing payment callback');
  }
};

exports.serveMockPaymentPage = async (req, res) => {
  const { booking_id, amount } = req.query;
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Razorpay Secured Checkout</title>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { font-family: 'Segoe UI', system-ui, sans-serif; background-color: #0b0e14; color: #e1e4ea; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .checkout-box { background: #121620; border: 1px solid #1f2638; border-radius: 12px; max-width: 400px; width: 90%; padding: 24px; box-shadow: 0 10px 25px rgba(0,0,0,0.3); }
        .header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #1f2638; padding-bottom: 16px; margin-bottom: 20px; }
        .logo { color: #528ff0; font-weight: 800; letter-spacing: 1.2px; font-size: 14px; }
        .amount { font-size: 22px; font-weight: 800; color: #fff; }
        .desc { font-size: 13px; color: #8a94a6; margin-bottom: 24px; }
        .btn-pay { background: #528ff0; color: white; font-weight: bold; width: 100%; border: none; padding: 14px; border-radius: 6px; font-size: 15px; cursor: pointer; transition: background 0.2s; }
        .btn-pay:hover { background: #3a75d1; }
        .footer { font-size: 11px; text-align: center; color: #5c6470; margin-top: 16px; }
      </style>
    </head>
    <body>
      <div class="checkout-box">
        <div class="header">
          <span class="logo">RAZORPAY SECURE</span>
          <span class="amount">₹${amount || '50'}.00</span>
        </div>
        <h3>Fixigo Appliance Service</h3>
        <p class="desc">Simulated Payment sandbox environment. Click payment confirm to generate booking.</p>
        <form action="/bookings/payment-callback" method="get">
          <input type="hidden" name="booking_id" value="${booking_id}">
          <input type="hidden" name="razorpay_payment_id" value="pay_mock_${booking_id}_${Date.now()}">
          <input type="hidden" name="razorpay_payment_link_id" value="plink_mock_${booking_id}">
          <input type="hidden" name="razorpay_payment_link_status" value="confirmed">
          <button type="submit" class="btn-pay">Pay ₹${amount || '50'}.00 Securely</button>
        </form>
        <div class="footer">🔒 PCI-DSS Secured connection sandbox</div>
      </div>
    </body>
    </html>
  `);
};

exports.verifyPaymentSignature = async (req, res) => {
  try {
    const { bookingId, razorpay_payment_id, razorpay_order_id, razorpay_signature } = req.body;

    if (!bookingId || !razorpay_payment_id || !razorpay_order_id || !razorpay_signature) {
      return res.status(400).json({ message: 'Missing required validation fields' });
    }

    if (razorpay_payment_id.startsWith('pay_mock_')) {
      await pool.query(
        `UPDATE bookings 
         SET payment_status = 'paid', status = 'pending', razorpay_payment_id = $1, razorpay_order_id = $2, updated_at = datetime('now') 
         WHERE id = $3`,
        [razorpay_payment_id, razorpay_order_id, bookingId]
      );
      return res.json({ status: 'success', message: 'Mock payment verified successfully' });
    }

    const crypto = require("crypto");
    const hmac = crypto.createHmac("sha256", process.env.RAZORPAY_KEY_SECRET);
    hmac.update(razorpay_order_id + "|" + razorpay_payment_id);
    const generated_signature = hmac.digest("hex");

    if (generated_signature === razorpay_signature) {
      await pool.query(
        `UPDATE bookings 
         SET payment_status = 'paid', status = 'pending', razorpay_payment_id = $1, razorpay_order_id = $2, updated_at = datetime('now') 
         WHERE id = $3`,
        [razorpay_payment_id, razorpay_order_id, bookingId]
      );
      res.json({ status: 'success', message: 'Payment signature verified successfully' });
    } else {
      res.status(400).json({ message: 'Invalid payment signature verification failed' });
    }
  } catch (err) {
    console.error('Signature verification error:', err);
    res.status(500).json({ message: 'Server error verifying signature' });
  }
};