-- Initialize Fixigo database with default admin account
USE fixigo;
-- Insert default admin account (required for system to work)
-- Email: admin@fixigo.com
-- Password: FixigoAdmin123 (hashed with bcrypt)
-- Hash: $2b$10$kI7bHhVeGqF/f4D4S3UqDe1Ly7V8x3x3x3x3x3x3x3x3x3x3x (example)
-- To generate the correct hash, use this Node.js code:
-- const bcrypt = require('bcrypt');
-- bcrypt.hash('FixigoAdmin123', 10).then(hash => console.log(hash));
-- Then replace the hash below with the output
DELETE FROM admins
WHERE email = 'admin@fixigo.com';
INSERT INTO admins (email, password, role)
VALUES (
        'admin@fixigo.com',
        'kishor@123',
        'super_admin'
    );
-- To run this script:
-- mysql -u root -p fixigo < init_admin.sql