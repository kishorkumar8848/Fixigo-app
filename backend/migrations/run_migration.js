require('dotenv').config();
const pool = require('../config/db');
const { ensureResaleSchema } = require('./ensure_resale_schema');
const { ensureTechnicianSchema } = require('./ensure_technician_schema');

async function runMigration() {
  try {
    console.log('🔄 Running schema migrations...');

    if (process.env.DB_USE_SQLITE === 'true') {
      // Ensure columns via SQLite init path
      require('../init_sqlite');
      console.log('✅ SQLite schema ensured via init_sqlite.js');
      process.exit(0);
      return;
    }

    const resale = await ensureResaleSchema(pool);
    console.log('✅ resale_requests ready (' + resale.engine + ')');

    const tech = await ensureTechnicianSchema(pool);
    console.log('✅ technicians ID-proof columns ready (' + tech.engine + ')');
    console.log('📋 Columns:', (tech.columns || []).join(', '));

    console.log('✅ Migration completed successfully!');
    process.exit(0);
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    console.error('Error details:', err);
    process.exit(1);
  }
}

runMigration();
