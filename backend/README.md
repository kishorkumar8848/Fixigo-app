# Fixigo Backend - Setup & Installation Guide

## 📋 Prerequisites

Make sure you have installed:

- **Node.js** (v14+) - Download from https://nodejs.org/
- **MySQL** (v5.7+) - Download from https://www.mysql.com/
- **npm** (comes with Node.js)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

Create a `.env` file in the `backend/` directory:

```env
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=fixigo

# JWT Secret (change this in production!)
JWT_SECRET=fixigo_jwt_secret_key_2024_keep_safe

# Server Port
PORT=3000

# Environment
NODE_ENV=development
```

### 3. Create Database Schema

Open MySQL and run:

```bash
mysql -u root -p < schema.sql
```

Or paste the contents of `schema.sql` into MySQL Workbench/Command Line.

### 4. Generate Admin Password Hash

Run this Node.js command to generate a secure password hash:

```bash
node -e "const bcrypt = require('bcrypt'); bcrypt.hash('FixigoAdmin123', 10).then(hash => console.log(hash));"
```

Copy the output hash.

### 5. Create Admin Account

Update `init_admin.sql` with the hash from step 4, then run:

```bash
mysql -u root -p fixigo < init_admin.sql
```

Or run this SQL directly in MySQL:

```sql
USE fixigo;
INSERT INTO admins (email, password, role) VALUES
('admin@fixigo.com', '[PASTE_HASH_HERE]', 'super_admin');
```

### 6. Start the Server

```bash
npm run dev
```

Or use:

```bash
npm start
```

You should see:

```
✓ Database connection successful
✓ Server running on http://localhost:3000
```

---

## 🔌 API Endpoints

### Authentication

#### Customer Sign Up

```
POST /auth/customer/signup
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "SecurePass123",
  "phone": "9876543210",
  "address": "123 Main St, City"
}
```

#### Customer Login

```
POST /auth/customer/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePass123"
}

Response:
{
  "message": "Login successful",
  "token": "eyJhbGc...",
  "customerId": 1
}
```

#### Technician Sign Up

```
POST /auth/technician/signup
Content-Type: application/json

{
  "name": "Mike Singh",
  "email": "mike@example.com",
  "password": "SecurePass123",
  "phone": "9876543210",
  "skills": "AC,Fridge,Microwave",
  "experience": 5
}
```

#### Technician Login

```
POST /auth/technician/login
Content-Type: application/json

{
  "email": "mike@example.com",
  "password": "SecurePass123"
}
```

#### Admin Login

```
POST /auth/admin/login
Content-Type: application/json

{
  "email": "admin@fixigo.com",
  "password": "FixigoAdmin123"
}
```

### Customer Operations

#### Book a Repair

```
POST /bookings
Authorization: Bearer <token>
Content-Type: application/json

{
  "customerId": 1,
  "appliance_type": "AC",
  "issue_description": "Not cooling properly",
  "location": "123 Main St, City",
  "preferred_date": "2024-03-15"
}
```

#### Get My Bookings

```
GET /bookings/user/1
Authorization: Bearer <token>
```

#### Get Booking History

```
GET /bookings/history/1
Authorization: Bearer <token>
```

#### Get Booking Details

```
GET /bookings/details/1
Authorization: Bearer <token>
```

#### Submit Resale Request

```
POST /resale
Authorization: Bearer <token>
Content-Type: application/json

{
  "customerId": 1,
  "appliance_type": "Microwave",
  "condition_description": "Good condition, 2 years old",
  "expected_price": 2500
}
```

#### Get My Resale Requests

```
GET /resale/1
Authorization: Bearer <token>
```

### Technician Operations

#### Get Available Jobs

```
GET /technician/jobs
Authorization: Bearer <token>
```

#### Accept a Job

```
POST /technician/jobs/1/accept
Authorization: Bearer <token>
```

#### Reject a Job

```
POST /technician/jobs/1/reject
Authorization: Bearer <token>
```

#### Update Job Status

```
PATCH /technician/jobs/1/status
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "in_progress"  // or "completed", "cancelled"
}
```

#### Get My Earnings

```
GET /technician/jobs/earnings
Authorization: Bearer <token>
```

### Admin Operations

#### Dashboard Overview

```
GET /admin/dashboard
Authorization: Bearer <token>
```

#### Get All Customers

```
GET /admin/customers
Authorization: Bearer <token>
```

#### Get Customer Details

```
GET /admin/customers/1
Authorization: Bearer <token>
```

#### Get All Technicians

```
GET /admin/technicians
Authorization: Bearer <token>
```

#### Get Pending Technicians

```
GET /admin/technicians/pending
Authorization: Bearer <token>
```

#### Verify Technician

```
PATCH /admin/technicians/1/verify
Authorization: Bearer <token>
```

#### Reject Technician

```
PATCH /admin/technicians/1/reject
Authorization: Bearer <token>
```

#### Get All Bookings

```
GET /admin/bookings
Authorization: Bearer <token>
```

#### Get Booking Stats

```
GET /admin/bookings/stats
Authorization: Bearer <token>
```

#### Get All Resale Requests

```
GET /admin/resale-requests
Authorization: Bearer <token>
```

#### Approve Resale Request

```
PATCH /admin/resale-requests/1/approve
Authorization: Bearer <token>
```

#### Reject Resale Request

```
PATCH /admin/resale-requests/1/reject
Authorization: Bearer <token>
```

---

## 📁 Project Structure

```
backend/
├── config/
│   └── db.js                    # Database connection pool
├── controllers/
│   ├── authController.js        # Auth logic (signup/login)
│   ├── bookingController.js     # Booking management
│   ├── jobController.js         # Job management for technicians
│   ├── adminController.js       # Admin panel operations
│   └── resaleController.js      # Resale request handling
├── middleware/
│   ├── authMiddleware.js        # JWT verification
│   └── roleMiddleware.js        # Role-based access control
├── routes/
│   ├── authRoutes.js            # Auth endpoints
│   ├── bookingRoutes.js         # Booking endpoints
│   ├── jobRoutes.js             # Job endpoints
│   ├── resaleRoutes.js          # Resale endpoints
│   └── adminRoutes.js           # Admin endpoints
├── schema.sql                   # Database schema
├── init_admin.sql              # Admin initialization
├── .env                         # Environment variables
├── server.js                    # Main server entry point
└── package.json                 # Dependencies
```

---

## 🐛 Troubleshooting

### "Database connection refused"

- Make sure MySQL is running
- Check DB credentials in `.env`
- Verify database `fixigo` exists

### "Cannot find module 'mysql2'"

- Run `npm install` to install dependencies

### "Invalid token"

- Make sure you're sending the token in the Authorization header as `Bearer <token>`
- Check that JWT_SECRET in `.env` matches the one used to sign tokens

### "Cannot POST /auth/customer/signup"

- Verify the endpoint is correct
- Check the request body has required fields
- Ensure Content-Type is `application/json`

---

## 🔐 Security Notes

- Change `JWT_SECRET` in `.env` for production
- Use strong passwords for admin account
- Enable HTTPS for production
- Implement rate limiting for production
- Validate all user inputs
- Use environment variables for sensitive data

---

## 📞 Support

For issues or questions, refer to the full API documentation or contact support.
