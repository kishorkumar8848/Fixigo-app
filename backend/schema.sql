-- PostgreSQL schema for Fixigo platform on Supabase
-- Comprehensive database structure matching business requirements
-- Drop types if they exist (for clean recreation)
DROP TYPE IF EXISTS verification_status_enum CASCADE;
DROP TYPE IF EXISTS booking_status_enum CASCADE;
DROP TYPE IF EXISTS job_status_enum CASCADE;
DROP TYPE IF EXISTS earnings_status_enum CASCADE;
DROP TYPE IF EXISTS resale_status_enum CASCADE;
DROP TYPE IF EXISTS admin_role_enum CASCADE;
-- Create ENUM types
CREATE TYPE verification_status_enum AS ENUM ('pending', 'verified', 'rejected');
CREATE TYPE booking_status_enum AS ENUM (
    'pending',
    'assigned',
    'in_progress',
    'completed',
    'cancelled'
);
CREATE TYPE job_status_enum AS ENUM (
    'assigned',
    'accepted',
    'rejected',
    'in_progress',
    'completed',
    'cancelled'
);
CREATE TYPE earnings_status_enum AS ENUM ('pending', 'completed', 'paid');
CREATE TYPE resale_status_enum AS ENUM ('pending', 'approved', 'rejected', 'sold');
CREATE TYPE admin_role_enum AS ENUM ('admin', 'super_admin');
-- CUSTOMERS TABLE
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- TECHNICIANS TABLE
CREATE TABLE IF NOT EXISTS technicians (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    skills VARCHAR(255),
    experience INT DEFAULT 0,
    id_proof_url VARCHAR(255),
    verification_status verification_status_enum DEFAULT 'pending',
    rating DECIMAL(3, 2) DEFAULT 0,
    total_jobs INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- ADMINS TABLE
CREATE TABLE IF NOT EXISTS admins (
    id SERIAL PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role admin_role_enum DEFAULT 'admin',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- BOOKINGS TABLE
CREATE TABLE IF NOT EXISTS bookings (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    technician_id INT,
    appliance_type VARCHAR(100) NOT NULL,
    issue_description TEXT NOT NULL,
    location TEXT NOT NULL,
    preferred_date DATE,
    status booking_status_enum DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE
    SET NULL
);
-- JOBS TABLE
CREATE TABLE IF NOT EXISTS jobs (
    id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    technician_id INT NOT NULL,
    status job_status_enum DEFAULT 'assigned',
    price DECIMAL(10, 2),
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE CASCADE
);
-- EARNINGS TABLE
CREATE TABLE IF NOT EXISTS earnings (
    id SERIAL PRIMARY KEY,
    technician_id INT NOT NULL,
    job_id INT NOT NULL,
    amount DECIMAL(10, 2),
    status earnings_status_enum DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (technician_id) REFERENCES technicians(id) ON DELETE CASCADE,
    FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
);
-- RESALE REQUESTS TABLE
CREATE TABLE IF NOT EXISTS resale_requests (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    appliance_type VARCHAR(100) NOT NULL,
    condition_description TEXT,
    expected_price DECIMAL(10, 2),
    status resale_status_enum DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
-- SERVICES TABLE
CREATE TABLE IF NOT EXISTS services (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_customer_email ON customers(email);
CREATE INDEX IF NOT EXISTS idx_technician_email ON technicians(email);
CREATE INDEX IF NOT EXISTS idx_technician_verification ON technicians(verification_status);
CREATE INDEX IF NOT EXISTS idx_booking_customer ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_booking_technician ON bookings(technician_id);
CREATE INDEX IF NOT EXISTS idx_job_technician ON jobs(technician_id);
CREATE INDEX IF NOT EXISTS idx_job_booking ON jobs(booking_id);
CREATE INDEX IF NOT EXISTS idx_earnings_technician ON earnings(technician_id);