# ⚡ Fixigo Backend - Quick Setup (5 minutes)

## Step 1: Install Dependencies

```bash
cd backend
npm install
```

## Step 2: Setup Database & Admin

```bash
npm run setup
```

This command will:

- ✓ Create the `fixigo` database
- ✓ Create all tables
- ✓ Create admin account (admin@fixigo.com / FixigoAdmin123)

## Step 3: Start the Server

```bash
npm run dev
```

You should see:

```
✓ Database pool initialized
✓ Database connection successful
✓ Server running on http://localhost:3000
```

## ✅ Done! Your backend is ready.

---

## 🧪 Test the API

### 1. Customer Signup

```bash
curl -X POST http://localhost:3000/auth/customer/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123",
    "phone": "9876543210",
    "address": "Mumbai"
  }'
```

### 2. Customer Login

```bash
curl -X POST http://localhost:3000/auth/customer/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "SecurePass123"
  }'
```

Copy the `token` from the response.

### 3. Book a Repair (use token from step 2)

```bash
curl -X POST http://localhost:3000/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "customerId": 1,
    "appliance_type": "AC",
    "issue_description": "Not cooling",
    "location": "Mumbai",
    "preferred_date": "2024-03-20"
  }'
```

### 4. Admin Login

```bash
curl -X POST http://localhost:3000/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@fixigo.com",
    "password": "FixigoAdmin123"
  }'
```

### 5. Get Dashboard

```bash
curl http://localhost:3000/admin/dashboard \
  -H "Authorization: Bearer ADMIN_TOKEN_HERE"
```

---

## 📱 Frontend Integration

Use this base URL for all API calls from your Flutter app:

```
http://localhost:3000
```

Or if running on a device/emulator:

```
http://<YOUR_PC_IP>:3000
```

Example in Flutter:

```dart
final client = http.Client();
final response = await client.post(
  Uri.parse('http://localhost:3000/auth/customer/login'),
  headers: {'Content-Type': ' application/json'},
  body: jsonEncode({
    'email': email,
    'password': password,
  }),
);
```

---

## 🆘 Issues?

Check the full README.md for detailed documentation and troubleshooting.

---

## 📚 Main Endpoints

| Method | Endpoint                    | Auth | Role       |
| ------ | --------------------------- | ---- | ---------- |
| POST   | /auth/customer/signup       | ❌   | -          |
| POST   | /auth/customer/login        | ❌   | -          |
| POST   | /auth/technician/signup     | ❌   | -          |
| POST   | /auth/technician/login      | ❌   | -          |
| POST   | /auth/admin/login           | ❌   | -          |
| POST   | /bookings                   | ✅   | customer   |
| GET    | /bookings/user/:id          | ✅   | customer   |
| GET    | /technician/jobs            | ✅   | technician |
| POST   | /technician/jobs/:id/accept | ✅   | technician |
| PATCH  | /technician/jobs/:id/status | ✅   | technician |
| GET    | /admin/dashboard            | ✅   | admin      |
| GET    | /admin/technicians          | ✅   | admin      |
| GET    | /admin/bookings             | ✅   | admin      |
