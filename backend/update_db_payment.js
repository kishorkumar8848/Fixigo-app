const pool = require('./config/db');

async function updateSchema() {
  const client = await pool.connect();
  try {
    console.log('Altering bookings table...');
    
    // Add columns if they do not exist
    await client.query(`
      ALTER TABLE bookings 
      ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
      ADD COLUMN IF NOT EXISTS booking_fee DECIMAL(10, 2) DEFAULT 50.00,
      ADD COLUMN IF NOT EXISTS payment_status VARCHAR(50) DEFAULT 'unpaid',
      ADD COLUMN IF NOT EXISTS razorpay_payment_id VARCHAR(100),
      ADD COLUMN IF NOT EXISTS razorpay_order_id VARCHAR(100),
      ADD COLUMN IF NOT EXISTS estimated_price_min DECIMAL(10, 2),
      ADD COLUMN IF NOT EXISTS estimated_price_max DECIMAL(10, 2)
    `);
    
    console.log('✓ Successfully altered bookings table to support payments and cancellation!');
  } catch (err) {
    console.error('✗ Error updating database schema:', err.message);
  } finally {
    client.release();
    process.exit(0);
  }
}

updateSchema();
