# Supabase Migration Guide

## ✅ Changes Already Made

1. **package.json** - Updated dependencies:
   - Removed: `mysql2`
   - Added: `pg` (PostgreSQL client), `@supabase/supabase-js`

2. **.env** - Updated with Supabase credentials:
   - Supabase URL and API key configured
   - PostgreSQL connection details added
   - Database host: `db.smoluqhnnocohgzvlutc.supabase.co`

3. **backend/config/db.js** - Converted to PostgreSQL:
   - Changed from MySQL to pg Pool
   - SSL enabled for Supabase

4. **backend/schema.sql** - Converted to PostgreSQL syntax:
   - MySQL ENUM → PostgreSQL custom types
   - INT AUTO_INCREMENT → SERIAL
   - DATETIME → TIMESTAMP
   - Removed CREATE DATABASE and USE statements

5. **backend/server.js** - Updated for PostgreSQL:
   - `pool.getConnection()` → `pool.connect()`

## 🔧 Next Steps

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Apply Schema to Supabase

**Option A: Using Supabase Dashboard (Recommended)**

1. Go to https://app.supabase.com
2. Log in to your project: `smoluqhnnocohgzvlutc`
3. Navigate to SQL Editor
4. Create a new query
5. Copy the entire content of `backend/schema.sql`
6. Paste and run it

**Option B: Using psql command line**

```bash
psql -h db.smoluqhnnocohgzvlutc.supabase.co -U postgres -d postgres
# Enter password: k1i2s3h4o5r6
\i backend/schema.sql
```

### 3. Update Controller Query Syntax

The biggest change: PostgreSQL uses `$1, $2, $3` placeholders instead of MySQL's `?`

**Before (MySQL):**

```javascript
const [existing] = await pool.query(
  "SELECT id FROM customers WHERE email = ?",
  [email],
);
```

**After (PostgreSQL):**

```javascript
const result = await pool.query("SELECT id FROM customers WHERE email = $1", [
  email,
]);
// Access rows with result.rows (not result[0])
const existing = result.rows;
```

**Key differences:**

- MySQL: `pool.query()` returns `[rows, fields]` array
- PostgreSQL: `pool.query()` returns object with `.rows` property
- MySQL: Uses `?` placeholders
- PostgreSQL: Uses `$1, $2, $3` placeholders
- MySQL: `result.insertId` → PostgreSQL: `RETURNING id` in INSERT statement

### 4. Update All Controllers

You need to update these files to use PostgreSQL syntax:

- `backend/controllers/authController.js`
- `backend/controllers/bookingController.js`
- `backend/controllers/jobController.js`
- `backend/controllers/resaleController.js`
- `backend/controllers/adminController.js`
- `backend/controllers/serviceController.js`

**Example conversion for authController.js:**

```javascript
// SELECT query
const result = await pool.query("SELECT id FROM customers WHERE email = $1", [
  email,
]);
const existing = result.rows;

// INSERT query with RETURNING
const result = await pool.query(
  "INSERT INTO customers (name, phone, email, password, address) VALUES ($1, $2, $3, $4, $5) RETURNING id",
  [name, phone, email, hashedPassword, address],
);
const customerId = result.rows[0].id;

// UPDATE query
const result = await pool.query(
  "UPDATE customers SET name = $1, phone = $2, address = $3 WHERE id = $4",
  [name, phone, address, customerId],
);

// DELETE query
const result = await pool.query("DELETE FROM customers WHERE id = $1", [
  customerId,
]);
```

### 5. Test Connection

```bash
cd backend
npm start
```

You should see:

```
✓ Supabase database pool initialized
✓ Database connection successful
✓ Server running on http://localhost:3000
```

## 📝 Common PostgreSQL Patterns

### Getting last inserted ID

```javascript
// Instead of: result.insertId
// Use RETURNING clause:
const result = await pool.query(
  "INSERT INTO customers (...) VALUES (...) RETURNING id",
  [...values],
);
const newId = result.rows[0].id;
```

### Checking affected rows

```javascript
const result = await pool.query("UPDATE customers SET ... WHERE id = $1", [id]);
if (result.rowCount === 0) {
  // No rows were updated
}
```

### ENUM types

PostgreSQL ENUMs are pre-defined types (created in schema.sql). Use them as strings:

```javascript
await pool.query(
  "UPDATE technicians SET verification_status = $1 WHERE id = $2",
  ["verified", technicianId],
);
```

## 🚀 After Migration

Once all controllers are updated:

1. Run the app:

   ```bash
   npm start
   ```

2. Test endpoints with Postman or curl

3. Monitor logs in Supabase dashboard:
   - Database → Logs

4. Check data in Supabase:
   - Database → Tables

## ⚠️ Important Notes

1. **Your Supabase Project Info:**
   - URL: `https://smoluqhnnocohgzvlutc.supabase.co`
   - Project Reference: `smoluqhnnocohgzvlutc`
   - Database: `postgres` (default)
   - User: `postgres`

2. **File Uploads:** If you're storing file paths in the database and uploading to the `uploads/` folder, consider using Supabase Storage instead of local filesystem.

3. **Backups:** Supabase automatically backs up your data. Check Backups in the dashboard.

4. **Environment Variables:** Your `.env` file now has Supabase credentials. Keep it secure and never commit it to version control.

## 🆘 Troubleshooting

**"Error: SSL Error"**

- This is normal for Supabase. The `db.js` file already handles this with `rejectUnauthorized: false`

**"Error: Database does not exist"**

- Ensure you ran the schema.sql in Supabase. The default database is `postgres`, not `fixigo`

**"Error: Table does not exist"**

- Run the schema.sql file again in Supabase SQL Editor

**Queries not working after running**

- Check that all `?` placeholders have been converted to `$1, $2, etc.`
- Check that result access has been changed from `result[0]` to `result.rows[0]`

## 📚 Resources

- Supabase Documentation: https://supabase.com/docs
- PostgreSQL vs MySQL: https://www.postgresql.org/
- Node.js pg library: https://node-postgres.com/
