-- Fix plaintext / wrong admin password in init_admin.sql
-- Email: admin@fixigo.com
-- Password: FixigoAdmin123
-- Prefer running: node seed_admin.js  (hashes with bcrypt)

DELETE FROM admins WHERE email = 'admin@fixigo.com';

-- Do not insert a plaintext password here.
-- Use: node seed_admin.js
