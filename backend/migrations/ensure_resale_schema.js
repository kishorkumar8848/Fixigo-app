/**
 * Ensures resale_requests has all columns required by submitResaleRequest.
 * Safe to run repeatedly (IF NOT EXISTS / ignore duplicate column errors).
 */
async function ensureResaleSchema(pool) {
  const useSqlite = process.env.DB_USE_SQLITE === 'true';

  if (useSqlite) {
    // init_sqlite.js already adds missing columns; nothing else needed here.
    return { ok: true, engine: 'sqlite' };
  }

  const statements = [
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS brand VARCHAR(100)`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS age_years INT DEFAULT 0`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS original_price DECIMAL(10, 2) DEFAULT 0.0`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS estimated_value DECIMAL(10, 2) DEFAULT 0.0`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS working_status VARCHAR(50) DEFAULT 'Working'`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS cosmetic_condition VARCHAR(50) DEFAULT 'Good'`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS has_bill BOOLEAN DEFAULT FALSE`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS has_box BOOLEAN DEFAULT FALSE`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS has_accessories BOOLEAN DEFAULT FALSE`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS image_url VARCHAR(255)`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS address TEXT`,
    `ALTER TABLE resale_requests ADD COLUMN IF NOT EXISTS admin_notes TEXT`,
  ];

  for (const sql of statements) {
    try {
      await pool.query(sql);
    } catch (err) {
      // Ignore "already exists" style races; rethrow real failures.
      if (err.code === '42701') continue; // duplicate_column
      if (err.message && /already exists/i.test(err.message)) continue;
      throw err;
    }
  }

  const result = await pool.query(`
    SELECT column_name
    FROM information_schema.columns
    WHERE table_name = 'resale_requests'
    ORDER BY ordinal_position
  `);

  const columns = result.rows.map((r) => r.column_name);
  const required = [
    'brand', 'age_years', 'original_price', 'estimated_value',
    'working_status', 'cosmetic_condition', 'has_bill', 'has_box',
    'has_accessories', 'image_url', 'address',
  ];
  const missing = required.filter((c) => !columns.includes(c));

  if (missing.length) {
    throw new Error(`resale_requests still missing columns: ${missing.join(', ')}`);
  }

  return { ok: true, engine: 'postgres', columns };
}

module.exports = { ensureResaleSchema };
