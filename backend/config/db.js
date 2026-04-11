const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'k1i2s3h4o5r6',
  database: process.env.DB_NAME || 'fixigo',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelayMs: 0
});

// Test connection on startup
pool.getConnection()
  .then(conn => {
    console.log('✓ Database pool initialized');
    conn.release();
  })
  .catch(err => {
    console.error('✗ Database connection error:', err.message);
    process.exit(1);
  });

module.exports = pool;