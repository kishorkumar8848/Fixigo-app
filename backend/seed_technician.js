const bcrypt = require('bcrypt');
const pool = require('./config/db');

async function seedTechnician() {
  try {
    const name = 'John Doe';
    const email = 'tech@fixigo.com';
    const rawPassword = 'password123';
    const phone = '9876543210';
    const skills = 'Air Conditioner, Refrigerator, Television';
    const experience = 5;

    // Hash password
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    // Delete existing tech if any
    await pool.query('DELETE FROM technicians WHERE email = $1', [email]);

    // Insert verified technician
    const result = await pool.query(
      `INSERT INTO technicians (name, email, password, phone, skills, experience, verification_status) 
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id`,
      [name, email, hashedPassword, phone, skills, experience, 'verified']
    );

    console.log('\n✅ Verified Technician seeded successfully!');
    console.log('-------------------------------------------');
    console.log(`Email:    ${email}`);
    console.log(`Password: ${rawPassword}`);
    console.log(`Name:     ${name}`);
    console.log(`ID:       ${result.rows[0].id}\n`);
    
    process.exit(0);
  } catch (err) {
    console.error('Error seeding technician:', err.message);
    process.exit(1);
  }
}

seedTechnician();
