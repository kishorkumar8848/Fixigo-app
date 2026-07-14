// Test script to verify endpoints are working
require('dotenv').config();
const pool = require('./config/db');

async function testEndpoints() {
  console.log('=== Testing Database and Endpoints ===\n');
  
  try {
    // Test 1: Check if a technician exists
    console.log('1. Checking technicians...');
    const techResult = await pool.query('SELECT id, name, email FROM technicians LIMIT 1');
    if (techResult.rows.length > 0) {
      const tech = techResult.rows[0];
      console.log(`   ✓ Found technician: ${tech.name} (ID: ${tech.id})`);
      console.log(`     Email: ${tech.email}`);
    } else {
      console.log('   ⚠️  No technicians found in database');
    }
    
    // Test 2: Check if a customer exists  
    console.log('\n2. Checking customers...');
    const custResult = await pool.query('SELECT id, name, email FROM customers LIMIT 1');
    if (custResult.rows.length > 0) {
      const cust = custResult.rows[0];
      console.log(`   ✓ Found customer: ${cust.name} (ID: ${cust.id})`);
      console.log(`     Email: ${cust.email}`);
    } else {
      console.log('   ⚠️  No customers found in database');
    }
    
    // Test 3: Check resale_requests table structure
    console.log('\n3. Checking resale_requests table structure...');
    const Database = require('better-sqlite3');
    const db = new Database(process.env.SQLITE_PATH || './data/fixigo.sqlite');
    const columns = db.prepare('PRAGMA table_info(resale_requests)').all();
    console.log('   Columns:', columns.length);
    const requiredCols = ['customer_id', 'appliance_type', 'expected_price', 'brand', 'age_years', 'image_url', 'address'];
    requiredCols.forEach(col => {
      const exists = columns.find(c => c.name === col);
      console.log(`   ${exists ? '✓' : '✗'} ${col}`);
    });
    
    // Test 4: Check technicians table structure for ID proofs
    console.log('\n4. Checking technicians table for ID proof columns...');
    const techCols = db.prepare('PRAGMA table_info(technicians)').all();
    const requiredTechCols = ['aadhar_card_url', 'aadhar_verification_status', 'pan_card_url', 'pan_verification_status'];
    requiredTechCols.forEach(col => {
      const exists = techCols.find(c => c.name === col);
      console.log(`   ${exists ? '✓' : '✗'} ${col}`);
    });
    
    // Test 5: Check JWT_SECRET
    console.log('\n5. Checking environment variables...');
    console.log(`   JWT_SECRET: ${process.env.JWT_SECRET ? '✓ Set' : '✗ NOT SET'}`);
    console.log(`   DB_USE_SQLITE: ${process.env.DB_USE_SQLITE}`);
    
    // Test 6: Try to generate a test token
    if (process.env.JWT_SECRET && techResult.rows.length > 0) {
      const jwt = require('jsonwebtoken');
      const testToken = jwt.sign(
        { id: techResult.rows[0].id, role: 'technician', email: techResult.rows[0].email },
        process.env.JWT_SECRET,
        { expiresIn: '7d' }
      );
      console.log('\n6. Test JWT token generation:');
      console.log(`   ✓ Token generated successfully`);
      console.log(`   Token preview: ${testToken.substring(0, 50)}...`);
      
      // Verify it
      try {
        const decoded = jwt.verify(testToken, process.env.JWT_SECRET);
        console.log(`   ✓ Token verified successfully`);
        console.log(`   Decoded user ID: ${decoded.id}`);
      } catch (err) {
        console.log(`   ✗ Token verification failed: ${err.message}`);
      }
    }
    
    console.log('\n=== All tests completed ===\n');
    process.exit(0);
    
  } catch (err) {
    console.error('\n✗ Error during testing:', err.message);
    console.error('Details:', err);
    process.exit(1);
  }
}

testEndpoints();
