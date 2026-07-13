const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');
const Database = require('better-sqlite3');

const dbPath = process.env.SQLITE_PATH || path.join(__dirname, 'data', 'fixigo.sqlite');
fs.mkdirSync(path.dirname(dbPath), { recursive: true });
const db = new Database(dbPath);

const schema = `
CREATE TABLE IF NOT EXISTS customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  phone TEXT,
  address TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS technicians (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  phone TEXT,
  skills TEXT,
  experience INTEGER DEFAULT 0,
  id_proof_url TEXT,
  aadhar_card_url TEXT,
  aadhar_verification_status TEXT DEFAULT 'unuploaded',
  pan_card_url TEXT,
  pan_verification_status TEXT DEFAULT 'unuploaded',
  work_schedule TEXT,
  verification_status TEXT DEFAULT 'pending',
  rating REAL DEFAULT 0,
  total_jobs INTEGER DEFAULT 0,
  address TEXT,
  latitude REAL,
  longitude REAL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL,
  role TEXT DEFAULT 'admin',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  technician_id INTEGER,
  appliance_type TEXT NOT NULL,
  issue_description TEXT NOT NULL,
  location TEXT NOT NULL,
  preferred_date TEXT,
  status TEXT DEFAULT 'pending',
  latitude REAL,
  longitude REAL,
  booking_fee REAL DEFAULT 50.00,
  payment_status TEXT DEFAULT 'paid',
  razorpay_payment_id TEXT,
  razorpay_order_id TEXT,
  estimated_price_min REAL,
  estimated_price_max REAL,
  cancellation_reason TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id INTEGER NOT NULL,
  technician_id INTEGER NOT NULL,
  status TEXT DEFAULT 'assigned',
  price REAL,
  started_at DATETIME,
  completed_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS earnings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  technician_id INTEGER NOT NULL,
  job_id INTEGER NOT NULL,
  amount REAL,
  status TEXT DEFAULT 'pending',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE CASCADE,
  FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS resale_requests (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  appliance_type TEXT NOT NULL,
  condition_description TEXT,
  expected_price REAL,
  status TEXT DEFAULT 'pending',
  brand TEXT,
  age_years INTEGER,
  original_price REAL,
  estimated_value REAL,
  working_status TEXT,
  cosmetic_condition TEXT,
  has_bill INTEGER,
  has_box INTEGER,
  has_accessories INTEGER,
  image_url TEXT,
  address TEXT,
  admin_notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS services (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS reviews (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id INTEGER NOT NULL UNIQUE,
  customer_id INTEGER NOT NULL,
  technician_id INTEGER NOT NULL,
  rating INTEGER NOT NULL,
  comment TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
  FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE CASCADE
);
`;

db.exec(schema);

// Dynamically patch existing database if needed
try {
  db.exec("ALTER TABLE technicians ADD COLUMN aadhar_card_url TEXT;");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians ADD COLUMN aadhar_verification_status TEXT DEFAULT 'unuploaded';");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians ADD COLUMN pan_card_url TEXT;");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians ADD COLUMN pan_verification_status TEXT DEFAULT 'unuploaded';");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians ADD COLUMN work_schedule TEXT;");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians ADD COLUMN address TEXT;");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians ADD COLUMN latitude REAL;");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians ADD COLUMN longitude REAL;");
} catch (e) {}
try {
  db.exec("ALTER TABLE technicians RENAME COLUMN id_proof_url TO old_id_proof_url;");
} catch (e) {}
try {
  // Ensure default verification status is pending for SQLite
  db.exec("UPDATE technicians SET verification_status = 'pending' WHERE verification_status IS NULL;");
} catch (e) {}

console.log("Database initialized & schema verified successfully.");

// Dynamically add columns if database already exists
const cols = [
  'brand TEXT',
  'age_years INTEGER',
  'original_price REAL',
  'estimated_value REAL',
  'working_status TEXT',
  'cosmetic_condition TEXT',
  'has_bill INTEGER',
  'has_box INTEGER',
  'has_accessories INTEGER',
  'image_url TEXT',
  'address TEXT',
  'admin_notes TEXT'
];
for (const col of cols) {
  try {
    db.exec(`ALTER TABLE resale_requests ADD COLUMN ${col}`);
  } catch (_) {}
}

(async () => {
  const adminPassword = await bcrypt.hash('FixigoAdmin123', 10);
  db.prepare('INSERT OR IGNORE INTO admins (email, password, role) VALUES (?, ?, ?)').run('admin@fixigo.com', adminPassword, 'super_admin');

  const customerPassword = await bcrypt.hash('demo123', 10);
  db.prepare('INSERT OR IGNORE INTO customers (name, email, password, phone, address) VALUES (?, ?, ?, ?, ?)').run('Demo Customer', 'demo@example.com', customerPassword, '9999999999', 'Koramangala, Bengaluru');

  const technicianPassword = await bcrypt.hash('password123', 10);
  db.prepare('INSERT OR IGNORE INTO technicians (name, email, password, phone, skills, experience, verification_status, address, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)').run(
    'John Doe',
    'tech@fixigo.com',
    technicianPassword,
    '9876543210',
    'Air Conditioner, Refrigerator, Television',
    5,
    'verified',
    'Indiranagar, Bengaluru',
    12.971899,
    77.641110
  );

  console.log('SQLite auth seed data initialized');
})();
