require('dotenv').config();
const pool = require('../config/db');
const fs = require('fs');
const path = require('path');

async function runMigration() {
  try {
    console.log('🔄 Running resale_requests table migration...');
    
    // Read the SQL migration file
    const sqlPath = path.join(__dirname, 'add_resale_columns.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    // Execute the migration
    await pool.query(sql);
    
    console.log('✅ Migration completed successfully!');
    console.log('✅ The following columns were added to resale_requests table:');
    console.log('   - brand');
    console.log('   - age_years');
    console.log('   - original_price');
    console.log('   - estimated_value');
    console.log('   - working_status');
    console.log('   - cosmetic_condition');
    console.log('   - has_bill');
    console.log('   - has_box');
    console.log('   - has_accessories');
    console.log('   - image_url');
    console.log('   - address');
    
    // Verify columns
    const result = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'resale_requests' 
      ORDER BY ordinal_position
    `);
    
    console.log('\n📋 Current table structure:');
    result.rows.forEach(row => {
      console.log(`   ${row.column_name}: ${row.data_type}`);
    });
    
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    console.error('Error details:', err);
    process.exit(1);
  }
}

runMigration();
