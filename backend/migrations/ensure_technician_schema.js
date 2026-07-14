/**
 * Ensures technicians table has ID-proof columns used by upload/admin verification.
 * Safe to run repeatedly.
 */
async function ensureTechnicianSchema(pool) {
  const useSqlite = process.env.DB_USE_SQLITE === 'true';

  if (useSqlite) {
    // init_sqlite.js already adds missing columns.
    return { ok: true, engine: 'sqlite' };
  }

  const statements = [
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS aadhar_card_url VARCHAR(255)`,
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS aadhar_verification_status VARCHAR(50) DEFAULT 'unuploaded'`,
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS pan_card_url VARCHAR(255)`,
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS pan_verification_status VARCHAR(50) DEFAULT 'unuploaded'`,
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS work_schedule TEXT`,
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS address TEXT`,
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS latitude DECIMAL(9, 6)`,
    `ALTER TABLE technicians ADD COLUMN IF NOT EXISTS longitude DECIMAL(9, 6)`,
  ];

  for (const sql of statements) {
    try {
      await pool.query(sql);
    } catch (err) {
      if (err.code === '42701') continue; // duplicate_column
      if (err.message && /already exists/i.test(err.message)) continue;
      throw err;
    }
  }

  // Backfill null statuses so admin UI doesn't treat them as missing oddly
  try {
    await pool.query(`
      UPDATE technicians
      SET aadhar_verification_status = COALESCE(aadhar_verification_status, 'unuploaded'),
          pan_verification_status = COALESCE(pan_verification_status, 'unuploaded')
    `);
  } catch (err) {
    console.warn('Technician status backfill skipped:', err.message);
  }

  const result = await pool.query(`
    SELECT column_name
    FROM information_schema.columns
    WHERE table_name = 'technicians'
    ORDER BY ordinal_position
  `);

  const columns = result.rows.map((r) => r.column_name);
  const required = [
    'aadhar_card_url',
    'aadhar_verification_status',
    'pan_card_url',
    'pan_verification_status',
  ];
  const missing = required.filter((c) => !columns.includes(c));

  if (missing.length) {
    throw new Error(`technicians still missing columns: ${missing.join(', ')}`);
  }

  return { ok: true, engine: 'postgres', columns: required };
}

module.exports = { ensureTechnicianSchema };
