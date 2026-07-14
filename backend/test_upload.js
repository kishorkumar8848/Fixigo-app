// Test script to diagnose upload issues
const fs = require('fs');
const path = require('path');

console.log('=== Testing Upload Configuration ===\n');

// 1. Check uploads directory
const uploadsDir = path.join(__dirname, 'uploads');
console.log('1. Uploads directory check:');
console.log('   Path:', uploadsDir);
console.log('   Exists:', fs.existsSync(uploadsDir));

if (fs.existsSync(uploadsDir)) {
  try {
    // Check if writable
    const testFile = path.join(uploadsDir, 'test-write.txt');
    fs.writeFileSync(testFile, 'test');
    fs.unlinkSync(testFile);
    console.log('   Writable: YES ✓');
  } catch (err) {
    console.log('   Writable: NO ✗');
    console.log('   Error:', err.message);
  }
  
  // List files
  const files = fs.readdirSync(uploadsDir);
  console.log('   Files count:', files.length);
  if (files.length > 0) {
    console.log('   Recent files:', files.slice(0, 5).join(', '));
  }
} else {
  console.log('   ⚠️  Directory does not exist! Creating it...');
  try {
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log('   ✓ Created successfully');
  } catch (err) {
    console.log('   ✗ Failed to create:', err.message);
  }
}

console.log('\n2. Database connection check:');
try {
  const pool = require('./config/db');
  console.log('   Database module loaded: ✓');
  
  // Check if technicians table exists
  pool.query('SELECT COUNT(*) as count FROM technicians')
    .then(result => {
      console.log('   Technicians table accessible: ✓');
      console.log('   Technician count:', result.rows[0].count);
      
      // Check resale_requests table
      return pool.query('SELECT COUNT(*) as count FROM resale_requests');
    })
    .then(result => {
      console.log('   Resale_requests table accessible: ✓');
      console.log('   Resale requests count:', result.rows[0].count);
      
      process.exit(0);
    })
    .catch(err => {
      console.log('   Database query error: ✗');
      console.log('   Error:', err.message);
      process.exit(1);
    });
} catch (err) {
  console.log('   Database connection error: ✗');
  console.log('   Error:', err.message);
  process.exit(1);
}

console.log('\n3. Environment check:');
console.log('   DB_USE_SQLITE:', process.env.DB_USE_SQLITE);
console.log('   NODE_ENV:', process.env.NODE_ENV || 'not set');
console.log('   PORT:', process.env.PORT || '3000');
