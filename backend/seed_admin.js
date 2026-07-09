const bcrypt = require('bcrypt');
const pool = require('./config/db');

async function seedAdmin() {
  try {
    const email = 'admin@fixigo.com';
    const rawPassword = 'admin123';
    const role = 'super_admin';

    // Hash password
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    // Delete existing admin if any
    await pool.query('DELETE FROM admins WHERE email = $1', [email]);

    // Insert admin
    const result = await pool.query(
      `INSERT INTO admins (email, password, role) 
       VALUES ($1, $2, $3) RETURNING id`,
      [email, hashedPassword, role]
    );

    console.log('\n✅ Admin seeded successfully!');
    console.log('-------------------------------------------');
    console.log(`Email:    ${email}`);
    console.log(`Password: ${rawPassword}`);
    console.log(`Role:     ${role}`);
    console.log(`ID:       ${result.rows[0].id}\n`);
    
    process.exit(0);
  } catch (err) {
    console.error('Error seeding admin:', err.message);
    process.exit(1);
  }
}

seedAdmin();
