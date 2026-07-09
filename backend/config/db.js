const dotenv = require('dotenv');
const fs = require('fs');
const path = require('path');

dotenv.config();

let pool;

if (process.env.DB_USE_SQLITE === 'true') {
  const Database = require('better-sqlite3');
  const dbPath = process.env.SQLITE_PATH || path.join(__dirname, '..', 'data', 'fixigo.sqlite');
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });

  const db = new Database(dbPath);
  db.pragma('journal_mode = WAL');

  const normalizeQuery = (text) => text.replace(/\$(\d+)/g, '?');

  pool = {
    query: (text, params = []) => {
      const normalizedText = normalizeQuery(text);
      const statement = db.prepare(normalizedText);
      const upper = normalizedText.trim().toUpperCase();

      if (upper.startsWith('SELECT') || upper.startsWith('WITH')) {
        const result = statement.all(...params);
        return Promise.resolve({ rows: result });
      }

      const result = statement.run(...params);
      if (/\bRETURNING\b/i.test(normalizedText)) {
        const returningColumn = normalizedText.split(/\bRETURNING\b/i)[1]?.trim().split(',')[0]?.trim().split(/\s+/)[0] || 'id';
        if (returningColumn === 'id' || returningColumn === 'rowid') {
          return Promise.resolve({ rows: [{ id: result.lastInsertRowid }] });
        }
      }

      return Promise.resolve({ rows: [] });
    },
    connect: async () => ({ release: () => {} }),
  };

  console.log('✓ SQLite database initialized');
} else {
  const { Pool } = require('pg');
  pool = new Pool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 5432,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    max: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000,
  });

  pool.connect()
    .then(client => {
      console.log('✓ Supabase database pool initialized');
      client.release();
    })
    .catch(err => {
      console.error('✗ Database connection error:', err.message);
      console.error('Falling back to SQLite for local development. Set DB_USE_SQLITE=true in .env to keep this behavior.');
    });
}

module.exports = pool;