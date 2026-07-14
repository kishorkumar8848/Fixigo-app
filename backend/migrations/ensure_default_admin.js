const bcrypt = require('bcrypt');

/**
 * Ensures the default admin account exists with the documented credentials.
 * Email: admin@fixigo.com
 * Password: FixigoAdmin123 (or ADMIN_PASSWORD env override)
 */
async function ensureDefaultAdmin(pool) {
  const email = process.env.ADMIN_EMAIL || 'admin@fixigo.com';
  const rawPassword = process.env.ADMIN_PASSWORD || 'FixigoAdmin123';
  const role = 'super_admin';

  const hashedPassword = await bcrypt.hash(rawPassword, 10);
  const existing = await pool.query('SELECT id FROM admins WHERE email = $1', [email]);

  if (existing.rows.length === 0) {
    await pool.query(
      `INSERT INTO admins (email, password, role) VALUES ($1, $2, $3)`,
      [email, hashedPassword, role]
    );
    console.log(`✓ Default admin created (${email})`);
    return { created: true, updated: false, email };
  }

  // Keep documented login working even if an older seed used a different password (e.g. admin123).
  await pool.query(
    `UPDATE admins SET password = $1, role = $2 WHERE email = $3`,
    [hashedPassword, role, email]
  );
  console.log(`✓ Default admin password synced (${email})`);
  return { created: false, updated: true, email };
}

module.exports = { ensureDefaultAdmin };
