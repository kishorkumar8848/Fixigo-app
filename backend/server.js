require('dotenv').config();
const express = require('express');
const path = require('path');
const fs = require('fs');
const pool = require('./config/db');

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
const authRoutes = require('./routes/authRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const jobRoutes = require('./routes/jobRoutes');
const resaleRoutes = require('./routes/resaleRoutes');
const adminRoutes = require('./routes/adminRoutes');
const serviceRoutes = require('./routes/serviceRoutes');

app.use('/auth', authRoutes);
app.use('/bookings', bookingRoutes);
app.use('/technician/jobs', jobRoutes);
app.use('/resale', resaleRoutes);
app.use('/admin', adminRoutes);
app.use('/services', serviceRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ message: 'Server is running' });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ message: 'Internal server error' });
});

const PORT = process.env.PORT || 3000;

async function initializeDatabase() {
  try {
    const useSqlite = process.env.DB_USE_SQLITE === 'true';
    if (useSqlite) {
      const initSqlitePath = path.join(__dirname, 'init_sqlite.js');
      if (fs.existsSync(initSqlitePath)) {
        require(initSqlitePath);
      }
      return;
    }

    const client = await pool.connect();
    console.log('✓ Database connection successful');
    client.release();
  } catch (err) {
    console.error('✗ Database connection failed:', err.message);
    console.error('Please ensure Supabase is configured and credentials in .env are correct');
    process.exit(1);
  }
}

// Start server with database connection test
app.listen(PORT, async () => {
  await initializeDatabase();
  console.log(`✓ Server running on http://localhost:${PORT}`);
});