#!/usr/bin/env node

const bcrypt = require('bcrypt');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

dotenv.config();

const config = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'fixigo'
};

async function setupDatabase() {
  try {
    console.log('\n🔧 Fixigo Backend Setup Tool\n');
    console.log('Step 1: Creating database and tables...');

    // Create connection to MySQL (without specifying database first)
    const connection = await mysql.createConnection({
      host: config.host,
      user: config.user,
      password: config.password
    });

    // Create database
    await connection.query(`CREATE DATABASE IF NOT EXISTS ${config.database}`);
    console.log(`✓ Database '${config.database}' created/verified`);

    // Switch to the database
    await connection.query(`USE ${config.database}`);

    // Read and execute schema
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = fs.readFileSync(schemaPath, 'utf8');
    
    // Split and execute individual statements
    const statements = schema.split(';').filter(stmt => stmt.trim());
    for (const statement of statements) {
      if (statement.trim() && !statement.trim().startsWith('--')) {
        try {
          await connection.query(statement);
        } catch (err) {
          if (!err.message.includes('already exists')) {
            console.warn(`⚠ Warning: ${err.message}`);
          }
        }
      }
    }

    console.log('✓ Database schema created/verified');

    // Create admin account
    console.log('\nStep 2: Setting up admin account...');
    const adminEmail = 'admin@fixigo.com';
    const adminPassword = 'FixigoAdmin123';
    
    const hashedPassword = await bcrypt.hash(adminPassword, 10);

    // Delete existing admin if any
    await connection.query('DELETE FROM admins WHERE email = ?', [adminEmail]);

    // Insert admin
    await connection.query(
      'INSERT INTO admins (email, password, role) VALUES (?, ?, ?)',
      [adminEmail, hashedPassword, 'super_admin']
    );

    console.log(`✓ Admin account created`);
    console.log(`  Email: ${adminEmail}`);
    console.log(`  Password: ${adminPassword}`);

    await connection.end();

    console.log('\n✅ Setup completed successfully!');
    console.log('\nYou can now start the server with:');
    console.log('  npm run dev\n');
  } catch (err) {
    console.error('\n❌ Setup failed:', err.message);
    console.error('\nTroubleshooting:');
    console.error('1. Make sure MySQL is running');
    console.error('2. Check database credentials in .env file');
    console.error('3. Ensure MySQL user has CREATE DATABASE privilege\n');
    process.exit(1);
  }
}

setupDatabase();
