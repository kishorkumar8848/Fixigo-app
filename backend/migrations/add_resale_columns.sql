-- Migration: Add missing columns to resale_requests table
-- This fixes the "Server error submitting resale request" issue

-- Add the missing columns to resale_requests table
ALTER TABLE resale_requests 
ADD COLUMN IF NOT EXISTS brand VARCHAR(100),
ADD COLUMN IF NOT EXISTS age_years INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS estimated_value DECIMAL(10, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS working_status VARCHAR(50) DEFAULT 'Working',
ADD COLUMN IF NOT EXISTS cosmetic_condition VARCHAR(50) DEFAULT 'Good',
ADD COLUMN IF NOT EXISTS has_bill BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_box BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS has_accessories BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS image_url VARCHAR(255),
ADD COLUMN IF NOT EXISTS address TEXT;

-- Verify the columns were added
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'resale_requests' 
ORDER BY ordinal_position;
