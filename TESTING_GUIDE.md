# Testing Guide for Bug Fixes

## Overview
This guide helps you test the three bug fixes implemented in this update.

---

## 1. Testing Logout Confirmation ✅

### Customer Portal
1. Open the app and log in as a **Customer**
2. Go to the **Profile** tab (bottom navigation)
3. Scroll down and click the **Logout** button
4. **Expected Result:** A dialog should appear asking "Are you sure you want to logout?"
5. Click **Cancel** → You should remain logged in
6. Click **Logout** again, then click **Logout** in the dialog → You should be logged out and redirected to role selection

### Technician Portal
1. Open the app and log in as a **Technician**
2. Go to the **Profile** tab
3. Scroll down and click the **Logout** button
4. **Expected Result:** A dialog should appear asking "Are you sure you want to logout?"
5. Click **Cancel** → You should remain logged in
6. Click **Logout** again, then confirm → You should be logged out

### Admin Portal
1. Open the app and log in as **Admin** (admin@fixigo.com)
2. Click the **Logout icon** in the top-right corner
3. **Expected Result:** A dialog should appear asking "Are you sure you want to logout?"
4. Test both Cancel and Logout options

**Status:** ✅ Fully Implemented

---

## 2. Testing Resale Pickup Scheduling 🔍

### Prerequisites
- Backend server must be running
- Customer must be logged in
- Internet connection required

### Steps
1. Log in as a **Customer**
2. Navigate to **"Sell Your Appliance"** (Resell tab)
3. Fill in the required information:
   - Select your location (must include "Chennai")
   - Select an appliance type (e.g., AC, Washing Machine)
   - Enter brand and model
   - Enter year of purchase (e.g., 2020)
   - Enter original price (e.g., 30000)
   - Select condition
   - Select working status
   - (Optional) Upload a photo
4. Click **"Get Instant Valuation"**
5. Review the estimated value
6. Click **"Schedule Free Pickup"**
7. Select a pickup date
8. Click OK

### Expected Results
- **Success:** A success dialog appears saying "Your pickup is scheduled..."
- **Error:** An error message with detailed information appears

### Troubleshooting
If you see an error:

1. **Check the app console** (VS Code Debug Console or Flutter logs):
   ```
   Submitting resale request with fields: {...}
   Resale response: {...}
   ```

2. **Check the backend console**:
   ```
   Resale request received: {...}
   Inserting resale request with params: [...]
   ```

3. **Common Issues:**
   - "Missing required fields" → Check that customerId, appliance_type, and expected_price are set
   - Network error → Verify backend is running and accessible
   - Database error → Check that the `resale_requests` table exists

**Status:** ⚠️ Enhanced with better error messages (original issue might require database/network fix)

---

## 3. Testing ID Proof Upload 🔍

### Prerequisites
- Backend server must be running
- Technician must be logged in and registered
- Image file ready for upload
- Backend `uploads` folder must exist with write permissions

### Steps
1. Log in as a **Technician**
2. Go to **Profile** tab
3. Find the **ID Verification** section
4. Click **"Upload Aadhaar"** or **"Upload PAN"**
5. Select an image file from your device
6. Wait for upload to complete

### Expected Results
- **Success:** A green success message appears: "Aadhaar Card uploaded successfully!" or "PAN Card uploaded successfully!"
- The verification status should update
- **Error:** An error message with detailed information appears

### Troubleshooting
If you see an error:

1. **Check the app console** (Flutter logs):
   ```
   Uploading aadhar proof from: /path/to/file
   Upload response: {...}
   ```

2. **Check the backend console**:
   ```
   Upload proof request: { technicianId: X, type: 'aadhar', hasFile: true }
   File URL: /uploads/...
   aadhar proof uploaded successfully for technician X
   ```

3. **Common Issues:**
   - "File is required" → The image picker didn't return a file
   - "Valid type is required" → The type parameter is missing or invalid
   - Network error → Verify backend is running
   - "No such file or directory" → Check uploads folder permissions on backend
   - Authentication error → Verify technician is logged in with valid token

### Backend Setup Check
Make sure the backend `uploads` directory exists:
```bash
cd backend
mkdir -p uploads
chmod 755 uploads
```

**Status:** ⚠️ Enhanced with better error messages (original issue might require backend setup)

---

## Debugging Tips

### Enable Detailed Logging

**Frontend:**
All three fixes now include `print()` statements for debugging. Check your Flutter console/logs.

**Backend:**
All three fixes now include `console.log()` statements. Check your Node.js server logs.

### Common Commands

**View Flutter logs:**
```bash
flutter logs
```

**Run backend with logs:**
```bash
cd backend
npm start
```

**Check backend uploads folder:**
```bash
cd backend
ls -la uploads/
```

### Network Issues

If you're getting network errors:

1. Check `lib/api.dart` - verify `useLocalBackend` is set correctly
2. If using local backend, verify IP address matches your machine
3. If using Render, verify the backend is deployed and running
4. Test the health endpoint:
   ```bash
   curl http://localhost:3000/health
   # or
   curl https://fixigo-app.onrender.com/health
   ```

---

## Success Criteria

✅ **Logout Confirmation:** All three portals show confirmation dialog before logout

🔍 **Resale Pickup:** Error messages now include detailed information (original server error may need additional backend fixes)

🔍 **ID Proof Upload:** Error messages now include detailed information (original server error may need backend setup or permission fixes)

---

## Next Steps

If issues persist after implementing these fixes:

1. **Review the detailed error messages** - they now include specific error details
2. **Check console logs** - both frontend and backend now log extensively
3. **Verify database schema** - ensure all tables exist with correct columns
4. **Check file permissions** - ensure uploads folder is writable
5. **Test authentication** - ensure tokens are being sent correctly
6. **Network connectivity** - verify backend is accessible from the app

The enhanced error handling and logging will help identify the exact root cause of any remaining issues.
