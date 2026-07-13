# Fix: Resale Pickup Scheduling Error

## Root Cause

The error "Server error submitting resale request" occurs because the database table `resale_requests` is missing columns that the backend code is trying to insert.

### Missing Columns:
- `brand`
- `age_years`
- `original_price`
- `estimated_value`
- `working_status`
- `cosmetic_condition`
- `has_bill`
- `has_box`
- `has_accessories`
- `image_url`
- `address`

---

## Solution: Run Database Migration

### Option 1: Run Migration Script (Recommended)

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```

2. **Run the migration:**
   ```bash
   node migrations/run_migration.js
   ```

3. **Expected output:**
   ```
   🔄 Running resale_requests table migration...
   ✅ Migration completed successfully!
   ✅ The following columns were added to resale_requests table:
      - brand
      - age_years
      - original_price
      - estimated_value
      - working_status
      - cosmetic_condition
      - has_bill
      - has_box
      - has_accessories
      - image_url
      - address
   
   📋 Current table structure:
      id: integer
      customer_id: integer
      appliance_type: character varying
      condition_description: text
      expected_price: numeric
      status: USER-DEFINED
      brand: character varying
      age_years: integer
      ...
   ```

4. **Restart the backend server** (if it's running)

---

### Option 2: Manual SQL Execution

If you prefer to run the SQL directly:

1. **Connect to your PostgreSQL database** (Supabase):
   - Go to your Supabase dashboard
   - Navigate to the SQL Editor
   - Or use `psql` command line

2. **Run this SQL:**

```sql
-- Add missing columns to resale_requests table
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
```

3. **Verify the columns were added:**

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'resale_requests' 
ORDER BY ordinal_position;
```

---

### Option 3: Using Supabase Dashboard

1. **Log in to Supabase**
2. **Go to your project**
3. **Click on "SQL Editor" in the left sidebar**
4. **Create a new query**
5. **Paste the SQL from Option 2**
6. **Click "Run"**

---

## Testing After Migration

1. **Open the Fixigo app**
2. **Log in as a Customer**
3. **Navigate to "Sell Your Appliance" (Resell tab)**
4. **Fill in the form:**
   - Select location (Chennai)
   - Select appliance type
   - Enter brand and model
   - Enter year of purchase
   - Enter original price
   - Select condition and working status
5. **Click "Get Instant Valuation"**
6. **Click "Schedule Free Pickup"**
7. **Select a date**

**Expected Result:** ✅ Success dialog appears: "Your pickup is scheduled and resale request submitted successfully to the admin portal."

---

## Verification

After running the migration, verify the columns exist:

```bash
# From backend directory
node -e "const pool = require('./config/db'); pool.query('SELECT column_name FROM information_schema.columns WHERE table_name = \\'resale_requests\\' ORDER BY ordinal_position').then(res => { console.log(res.rows.map(r => r.column_name)); process.exit(0); });"
```

You should see all these columns:
- id
- customer_id
- appliance_type
- condition_description
- expected_price
- status
- **brand** ← NEW
- **age_years** ← NEW
- **original_price** ← NEW
- **estimated_value** ← NEW
- **working_status** ← NEW
- **cosmetic_condition** ← NEW
- **has_bill** ← NEW
- **has_box** ← NEW
- **has_accessories** ← NEW
- **image_url** ← NEW
- **address** ← NEW
- created_at
- updated_at

---

## Troubleshooting

### Migration fails with "relation does not exist"
**Solution:** The `resale_requests` table doesn't exist. Run the full schema first:
```bash
cd backend
psql $DATABASE_URL -f schema.sql
```

### "Permission denied" error
**Solution:** Make sure your database user has ALTER TABLE permissions.

### Connection error
**Solution:** Check your `.env` file has the correct database credentials:
```
DB_HOST=your-supabase-host
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres
DB_PASSWORD=your-password
DATABASE_URL=postgresql://user:password@host:5432/postgres
```

### Still getting "Server error"
**Solution:** 
1. Check the backend console logs for detailed error
2. Check the Flutter console logs for request details
3. Verify the migration was successful
4. Restart the backend server

---

## Files Created/Modified

### Created:
- `backend/migrations/add_resale_columns.sql` - SQL migration script
- `backend/migrations/run_migration.js` - Node.js migration runner
- `FIX_RESALE_ERROR.md` - This guide

### Modified:
- `backend/schema.sql` - Updated to include all columns for future deployments

---

## Important Notes

⚠️ **This migration is safe to run multiple times** - it uses `IF NOT EXISTS` so it won't fail if columns already exist.

✅ **No data loss** - This only adds columns, it doesn't delete or modify existing data.

🔄 **For production**: Test in a staging environment first before running on production database.

---

## Next Steps After Migration

Once the migration is complete, the resale pickup scheduling feature will work correctly. The app will be able to:
- Submit complete resale requests with all appliance details
- Upload images of appliances
- Store customer addresses for pickup
- Track appliance condition and working status
- Record warranty and accessory information

The admin portal will receive all this information to process resale requests effectively.
