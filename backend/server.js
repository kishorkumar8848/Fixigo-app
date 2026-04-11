require('dotenv').config();
const express = require('express');
const pool = require('./config/db');

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const path = require('path');
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

// Start server with database connection test
app.listen(PORT, async () => {
  try {
    // Test database connection
    const connection = await pool.getConnection();
    console.log('✓ Database connection successful');
    connection.release();

    console.log(`✓ Server running on http://localhost:${PORT}`);
  } catch (err) {
    console.error('✗ Database connection failed:', err.message);
    console.error('Please ensure MySQL is running and credentials in .env are correct');
    process.exit(1);
  }
});