# AGENT.md - Complete Project Recreation Guide

## Project Metadata

**Project Name:** BMI & Health Tracker  
**Architecture:** 3-Tier Web Application (Frontend + Backend + Database)  
**Purpose:** Track health metrics including BMI, BMR, and daily calorie needs with trend visualization  
**Target Platform:** AWS EC2 Ubuntu 22.04 LTS  
**Last Updated:** January 1, 2026

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Technology Stack](#technology-stack)
3. [Complete Directory Structure](#complete-directory-structure)
4. [Environment Configuration](#environment-configuration)
5. [Database Layer (Tier 3)](#database-layer-tier-3)
6. [Backend Layer (Tier 2)](#backend-layer-tier-2)
7. [Frontend Layer (Tier 1)](#frontend-layer-tier-1)
8. [Deployment Scripts](#deployment-scripts)
9. [Project Recreation Steps](#project-recreation-steps)
10. [Testing & Verification](#testing--verification)

---

## Project Overview

### What is This Application?

BMI & Health Tracker is a **production-ready full-stack web application** that enables users to:
- Track body measurements (weight, height, age, sex, activity level)
- Calculate health metrics automatically (BMI, BMR, daily calorie needs)
- Store historical measurements with custom dates
- Visualize BMI trends over a 30-day period
- View real-time statistics and recent measurements

### Architecture Pattern: 3-Tier Model

```
┌─────────────────────────────────────────────────────────────┐
│                    TIER 1: PRESENTATION                      │
│                                                              │
│  React 18 Frontend (Vite) - Port 5173 (dev) / 80 (prod)    │
│  Components: MeasurementForm, TrendChart, App               │
│  Static files served by Nginx in production                 │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP/REST API
                     │ (Axios)
┌────────────────────▼────────────────────────────────────────┐
│                    TIER 2: APPLICATION                       │
│                                                              │
│  Node.js + Express REST API - Port 3000                     │
│  Routes: /api/measurements, /api/measurements/trends        │
│  Business Logic: Health calculations (BMI, BMR, calories)   │
│  Managed by PM2 in production                               │
└────────────────────┬────────────────────────────────────────┘
                     │ PostgreSQL Protocol
                     │ (pg driver)
┌────────────────────▼────────────────────────────────────────┐
│                    TIER 3: DATA                              │
│                                                              │
│  PostgreSQL 14 Database - Port 5432                         │
│  Database: bmidb                                            │
│  Table: measurements (with indexes and constraints)         │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

✅ **Health Calculations**: Automatic BMI, BMR (Mifflin-St Jeor equation), activity-adjusted calories  
✅ **Custom Dates**: Backdate measurements for historical tracking  
✅ **Data Visualization**: 30-day BMI trend chart using Chart.js  
✅ **Real-time Stats**: Dashboard with current metrics  
✅ **Responsive Design**: Mobile-friendly UI with gradient aesthetics  
✅ **Production Ready**: Complete deployment automation, PM2 process management, Nginx reverse proxy  
✅ **Database Integrity**: CHECK constraints, indexes, and migrations  

---

## Technology Stack

### Backend (Tier 2)
- **Runtime:** Node.js (LTS version via NVM)
- **Framework:** Express.js 4.18.2
- **Database Driver:** pg (node-postgres) 8.10.0
- **Middleware:** cors 2.8.5, body-parser 1.20.2, dotenv 16.0.0
- **Process Manager:** PM2 (production)
- **Dev Tools:** nodemon 3.0.1

### Frontend (Tier 1)
- **Framework:** React 18.2.0
- **Build Tool:** Vite 5.0.0
- **HTTP Client:** Axios 1.4.0
- **Charts:** Chart.js 4.4.0 + react-chartjs-2 5.2.0

### Database (Tier 3)
- **DBMS:** PostgreSQL 14

### Infrastructure
- **Web Server:** Nginx (reverse proxy + static files)
- **Platform:** AWS EC2 Ubuntu 22.04 LTS
- **Firewall:** UFW
- **SSL/TLS:** Certbot/Let's Encrypt (optional)

---

## Complete Directory Structure

```
single-server-3tier-webapp-monitoring/
├── AGENT.md                          # This file - complete recreation guide
├── README.md                         # User-facing documentation
├── IMPLEMENTATION_GUIDE.md           # Manual deployment guide
├── IMPLEMENTATION_AUTO.sh            # Automated deployment script
│
├── database/
│   └── setup-database.sh             # Database setup script (688 lines)
│
├── backend/
│   ├── package.json                  # Backend dependencies
│   ├── ecosystem.config.js           # PM2 configuration
│   ├── .env                          # Environment variables (create manually)
│   │
│   ├── src/
│   │   ├── server.js                 # Express server entry point
│   │   ├── routes.js                 # API route handlers
│   │   ├── db.js                     # PostgreSQL connection pool
│   │   └── calculations.js           # Health metrics calculations
│   │
│   ├── migrations/
│   │   ├── 001_create_measurements.sql    # Create measurements table
│   │   └── 002_add_measurement_date.sql   # Add measurement_date column
│   │
│   └── logs/                         # PM2 logs (auto-created)
│
└── frontend/
    ├── package.json                  # Frontend dependencies
    ├── vite.config.js                # Vite build configuration
    ├── index.html                    # HTML entry point
    │
    └── src/
        ├── main.jsx                  # React entry point
        ├── App.jsx                   # Main application component
        ├── api.js                    # Axios instance configuration
        ├── index.css                 # Global styles (CSS variables)
        │
        └── components/
            ├── MeasurementForm.jsx   # Add measurement form component
            └── TrendChart.jsx        # BMI trend chart component
```

---

## Environment Configuration

### Backend Environment Variables

Create `backend/.env` file:

```env
# Server Configuration
PORT=3000
NODE_ENV=production

# Database Configuration
DATABASE_URL=postgresql://bmi_user:your_secure_password@localhost:5432/bmidb

# CORS Configuration
CORS_ORIGIN=*
FRONTEND_URL=http://your-server-ip-or-domain
```

### Port Configuration

| Service | Port | Protocol | Access |
|---------|------|----------|--------|
| Backend API | 3000 | HTTP | Internal only (proxied by Nginx) |
| Frontend Dev | 5173 | HTTP | Development only |
| Nginx HTTP | 80 | HTTP | Public |
| Nginx HTTPS | 443 | HTTPS | Public (with SSL) |
| PostgreSQL | 5432 | TCP | Internal only |

---

## Database Layer (Tier 3)

### Database Schema

**Database Name:** `bmidb`  
**User:** `bmi_user`  
**Table:** `measurements`

#### Table Structure

```sql
CREATE TABLE measurements (
  id SERIAL PRIMARY KEY,
  weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg > 0 AND weight_kg < 1000),
  height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm > 0 AND height_cm < 300),
  age INTEGER NOT NULL CHECK (age > 0 AND age < 150),
  sex VARCHAR(10) NOT NULL CHECK (sex IN ('male', 'female')),
  activity_level VARCHAR(30) CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  bmi NUMERIC(4,1) NOT NULL,
  bmi_category VARCHAR(30),
  bmr INTEGER,
  daily_calories INTEGER,
  measurement_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Indexes
CREATE INDEX idx_measurements_measurement_date ON measurements(measurement_date DESC);
CREATE INDEX idx_measurements_created_at ON measurements(created_at DESC);
CREATE INDEX idx_measurements_bmi ON measurements(bmi);
```

### Migration Files

#### File: `backend/migrations/001_create_measurements.sql`

```sql
-- BMI Health Tracker Database Migration
-- Version: 001
-- Description: Create measurements table
-- Date: 2025-12-12

-- Create measurements table
CREATE TABLE IF NOT EXISTS measurements (
  id SERIAL PRIMARY KEY,
  weight_kg NUMERIC(5,2) NOT NULL CHECK (weight_kg > 0 AND weight_kg < 1000),
  height_cm NUMERIC(5,2) NOT NULL CHECK (height_cm > 0 AND height_cm < 300),
  age INTEGER NOT NULL CHECK (age > 0 AND age < 150),
  sex VARCHAR(10) NOT NULL CHECK (sex IN ('male', 'female')),
  activity_level VARCHAR(30) CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very_active')),
  bmi NUMERIC(4,1) NOT NULL,
  bmi_category VARCHAR(30),
  bmr INTEGER,
  daily_calories INTEGER,
  measurement_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_measurements_measurement_date ON measurements(measurement_date DESC);
CREATE INDEX IF NOT EXISTS idx_measurements_created_at ON measurements(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_measurements_bmi ON measurements(bmi);

-- Add comments for documentation
COMMENT ON TABLE measurements IS 'Stores user health measurements including BMI, BMR, and calorie data';
COMMENT ON COLUMN measurements.weight_kg IS 'Weight in kilograms';
COMMENT ON COLUMN measurements.height_cm IS 'Height in centimeters';
COMMENT ON COLUMN measurements.age IS 'Age in years';
COMMENT ON COLUMN measurements.sex IS 'Biological sex (male/female)';
COMMENT ON COLUMN measurements.activity_level IS 'Physical activity level';
COMMENT ON COLUMN measurements.bmi IS 'Body Mass Index';
COMMENT ON COLUMN measurements.bmi_category IS 'BMI category (Underweight/Normal/Overweight/Obese)';
COMMENT ON COLUMN measurements.bmr IS 'Basal Metabolic Rate in calories';
COMMENT ON COLUMN measurements.daily_calories IS 'Daily calorie needs based on activity';
COMMENT ON COLUMN measurements.measurement_date IS 'Date when the measurement was taken (user-specified or current date)';

-- Display confirmation
SELECT 'Migration 001 completed successfully - measurements table created' AS status;
```

#### File: `backend/migrations/002_add_measurement_date.sql`

```sql
-- BMI Health Tracker Database Migration
-- Version: 002
-- Description: Add measurement_date column for custom date tracking
-- Date: 2025-12-15

-- Add measurement_date column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name='measurements' AND column_name='measurement_date'
    ) THEN
        ALTER TABLE measurements 
        ADD COLUMN measurement_date DATE NOT NULL DEFAULT CURRENT_DATE;
        
        -- Update existing records to use created_at date
        UPDATE measurements 
        SET measurement_date = DATE(created_at);
        
        -- Create index for better performance
        CREATE INDEX idx_measurements_measurement_date ON measurements(measurement_date DESC);
        
        RAISE NOTICE 'Column measurement_date added successfully';
    ELSE
        RAISE NOTICE 'Column measurement_date already exists';
    END IF;
END $$;

-- Add comment
COMMENT ON COLUMN measurements.measurement_date IS 'Date when the measurement was taken (user-specified or current date)';

-- Display confirmation
SELECT 'Migration 002 completed successfully - measurement_date column added' AS status;
```

---

## Backend Layer (Tier 2)

### File: `backend/package.json`

```json
{
  "name": "bmi-health-backend",
  "version": "1.0.0",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.0.0",
    "express": "^4.18.2",
    "pg": "^8.10.0",
    "body-parser": "^1.20.2"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
```

### File: `backend/src/server.js`

```javascript
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
const routes = require('./routes');

const app = express();
const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

// CORS configuration
// In development: Allow localhost:5173 (Vite dev server)
// In production: Allow configured frontend URL
const corsOptions = {
  origin: NODE_ENV === 'production' 
    ? process.env.FRONTEND_URL || 'http://localhost'
    : ['http://localhost:5173', 'http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
app.use(bodyParser.json());

// Health check endpoint - useful for monitoring and load balancers
app.get('/health', (req, res) => {
  res.json({ status: 'ok', environment: NODE_ENV });
});

// API routes mounted under /api prefix
app.use('/api', routes);

// 404 handler for undefined routes
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📊 Environment: ${NODE_ENV}`);
  console.log(`🔗 API available at: http://localhost:${PORT}/api`);
});
```

### File: `backend/src/db.js`

```javascript
const { Pool } = require('pg');

// PostgreSQL connection pool configuration
// Uses connection string from environment variable
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // Maximum number of clients in the pool
  idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
  connectionTimeoutMillis: 2000, // Return error after 2 seconds if can't connect
});

// Handle pool errors
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle PostgreSQL client:', err);
  process.exit(-1);
});

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Database connection failed:', err.message);
    process.exit(1);
  } else {
    console.log('✅ Database connected successfully at:', res.rows[0].now);
  }
});

// Export query method for executing SQL
module.exports = {
  query: (text, params) => pool.query(text, params),
  pool
};
```

### File: `backend/src/calculations.js`

```javascript
/**
 * Determine BMI category based on BMI value
 * @param {number} b - BMI value
 * @returns {string} - BMI category
 */
function bmiCategory(b) {
  if (b < 18.5) return 'Underweight';
  if (b < 25) return 'Normal';
  if (b < 30) return 'Overweight';
  return 'Obese';
}

/**
 * Calculate health metrics: BMI, BMR, and daily calorie needs
 * @param {Object} params - User measurements
 * @param {number} params.weightKg - Weight in kilograms
 * @param {number} params.heightCm - Height in centimeters
 * @param {number} params.age - Age in years
 * @param {string} params.sex - Biological sex ('male' or 'female')
 * @param {string} params.activity - Activity level (sedentary/light/moderate/active/very_active)
 * @returns {Object} - Calculated metrics
 */
function calculateMetrics({ weightKg, heightCm, age, sex, activity }) {
  // Convert height to meters
  const h = heightCm / 100;
  
  // Calculate BMI: weight(kg) / height(m)^2
  const bmi = +(weightKg / (h * h)).toFixed(1);
  
  // Calculate BMR using Mifflin-St Jeor Equation
  // Male: (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years) + 5
  // Female: (10 × weight in kg) + (6.25 × height in cm) − (5 × age in years) − 161
  let bmr = sex === 'male'
    ? 10 * weightKg + 6.25 * heightCm - 5 * age + 5
    : 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
  
  // Activity level multipliers for daily calorie calculation
  const mult = {
    sedentary: 1.2,      // Little or no exercise
    light: 1.375,        // Light exercise 1-3 days/week
    moderate: 1.55,      // Moderate exercise 3-5 days/week
    active: 1.725,       // Hard exercise 6-7 days/week
    very_active: 1.9     // Very hard exercise & physical job
  }[activity] || 1.2;
  
  return {
    bmi,
    bmiCategory: bmiCategory(bmi),
    bmr: Math.round(bmr),
    dailyCalories: Math.round(bmr * mult)
  };
}

module.exports = { calculateMetrics };
```

### File: `backend/src/routes.js`

```javascript
const express = require('express');
const router = express.Router();
const db = require('./db');
const { calculateMetrics } = require('./calculations');

// POST /api/measurements - Create new measurement
router.post('/measurements', async (req, res) => {
  try {
    const { weightKg, heightCm, age, sex, activity, measurementDate } = req.body;
    
    // Validation
    if (!weightKg || !heightCm || !age || !sex) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) {
      return res.status(400).json({ error: 'Invalid values: must be positive numbers' });
    }
    
    // Calculate health metrics
    const m = calculateMetrics({ weightKg, heightCm, age, sex, activity });
    
    // Use provided date or default to today
    const date = measurementDate || new Date().toISOString().split('T')[0];
    
    // Insert into database
    const q = `INSERT INTO measurements (weight_kg, height_cm, age, sex, activity_level, bmi, bmi_category, bmr, daily_calories, measurement_date, created_at)
    VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, now()) RETURNING *`;
    const v = [weightKg, heightCm, age, sex, activity, m.bmi, m.bmiCategory, m.bmr, m.dailyCalories, date];
    const r = await db.query(q, v);
    
    res.status(201).json({ measurement: r.rows[0] });
  } catch (e) {
    console.error('Error creating measurement:', e);
    res.status(500).json({ error: e.message || 'Failed to create measurement' });
  }
});

// GET /api/measurements - Get all measurements
router.get('/measurements', async (req, res) => {
  try {
    const r = await db.query('SELECT * FROM measurements ORDER BY measurement_date DESC, created_at DESC');
    res.json({ rows: r.rows });
  } catch (e) {
    console.error('Error fetching measurements:', e);
    res.status(500).json({ error: 'Failed to fetch measurements' });
  }
});

// GET /api/measurements/trends - Get 30-day BMI trends
router.get('/measurements/trends', async (req, res) => {
  try {
    const q = `SELECT measurement_date AS day, AVG(bmi) AS avg_bmi 
    FROM measurements
    WHERE measurement_date >= CURRENT_DATE - interval '30 days' 
    GROUP BY measurement_date 
    ORDER BY measurement_date`;
    const r = await db.query(q);
    res.json({ rows: r.rows });
  } catch (e) {
    console.error('Error fetching trends:', e);
    res.status(500).json({ error: 'Failed to fetch trends' });
  }
});

module.exports = router;
```

### File: `backend/ecosystem.config.js`

```javascript
module.exports = {
  apps: [{
    name: 'bmi-backend',
    script: './src/server.js',
    cwd: '/home/ubuntu/bmi-health-tracker/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true,
    merge_logs: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
```

---

## Frontend Layer (Tier 1)

### File: `frontend/package.json`

```json
{
  "name": "bmi-health-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview --port 5173"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "axios": "^1.4.0",
    "chart.js": "^4.4.0",
    "react-chartjs-2": "^5.2.0"
  },
  "devDependencies": {
    "vite": "^5.0.0",
    "@vitejs/plugin-react": "^4.2.0"
  }
}
```

### File: `frontend/vite.config.js`

```javascript
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true
      }
    }
  }
});
```

### File: `frontend/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content="BMI and Health Tracker - Track your Body Mass Index, BMR, and daily calorie needs" />
  <title>SAROWAR-GiT: BMI & Health Tracker</title>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
```

### File: `frontend/src/main.jsx`

```jsx
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './index.css';

createRoot(document.getElementById('root')).render(<App />);
```

### File: `frontend/src/api.js`

```javascript
import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  timeout: 10000, // 10 second timeout
  headers: {
    'Content-Type': 'application/json'
  }
});

// Request interceptor
api.interceptors.request.use(
  config => {
    return config;
  },
  error => {
    console.error('Request error:', error);
    return Promise.reject(error);
  }
);

// Response interceptor for error handling
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response) {
      // Server responded with error status
      console.error('API Error:', error.response.status, error.response.data);
    } else if (error.request) {
      // Request made but no response
      console.error('Network Error: No response from server');
    } else {
      // Something else happened
      console.error('Error:', error.message);
    }
    return Promise.reject(error);
  }
);

export default api;
```

### File: `frontend/src/App.jsx`

```jsx
import React, { useEffect, useState } from 'react';
import MeasurementForm from './components/MeasurementForm';
import TrendChart from './components/TrendChart';
import api from './api';

export default function App() {
  const [rows, setRows] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const r = await api.get('/measurements');
      setRows(r.data.rows);
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to load measurements');
    } finally {
      setLoading(false);
    }
  };
  
  useEffect(() => { load() }, []);
  
  // Calculate stats
  const latestMeasurement = rows[0];
  const totalMeasurements = rows.length;
  
  return (
    <>
      <header className="app-header">
        <h1>BMI & Health Tracker</h1>
        <p className="app-subtitle">Track your health metrics and reach your fitness goals</p>
      </header>

      <div className="container">
        {/* Add Measurement Card */}
        <div className="card">
          <div className="card-header">
            <h2>Add New Measurement</h2>
          </div>
          <MeasurementForm onSaved={load} />
        </div>

        {/* Stats Cards */}
        {latestMeasurement && (
          <div className="stats-grid">
            <div className="stat-card">
              <span className="stat-value">{latestMeasurement.bmi}</span>
              <span className="stat-label">Current BMI</span>
            </div>
            <div className="stat-card" style={{ background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)' }}>
              <span className="stat-value">{latestMeasurement.bmr}</span>
              <span className="stat-label">BMR (cal)</span>
            </div>
            <div className="stat-card" style={{ background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)' }}>
              <span className="stat-value">{latestMeasurement.daily_calories}</span>
              <span className="stat-label">Daily Calories</span>
            </div>
            <div className="stat-card" style={{ background: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)' }}>
              <span className="stat-value">{totalMeasurements}</span>
              <span className="stat-label">Total Records</span>
            </div>
          </div>
        )}

        {/* Recent Measurements Card */}
        <div className="card">
          <div className="card-header">
            <h2>Recent Measurements</h2>
          </div>
          {error && <div className="alert alert-error">{error}</div>}
          {loading ? (
            <div className="loading">Loading your data</div>
          ) : (
            <ul className="measurements-list">
              {rows.length === 0 ? (
                <div className="empty-state">
                  <p>No measurements yet. Add your first one above!</p>
                </div>
              ) : (
                rows.slice(0, 10).map(r => (
                  <li key={r.id} className="measurement-item">
                    <span className="measurement-date">
                      {new Date(r.measurement_date || r.created_at).toLocaleDateString('en-US', { 
                        month: 'short', 
                        day: 'numeric', 
                        year: 'numeric' 
                      })}
                    </span>
                    <div className="measurement-data">
                      <span className="measurement-badge badge-bmi">
                        BMI: <strong>{r.bmi}</strong> ({r.bmi_category})
                      </span>
                      <span className="measurement-badge badge-bmr">
                        BMR: <strong>{r.bmr}</strong> cal
                      </span>
                      <span className="measurement-badge badge-calories">
                        Daily: <strong>{r.daily_calories}</strong> cal
                      </span>
                    </div>
                    <div className="measurement-meta">
                      {r.sex} • {r.age} yrs • {r.activity_level}
                    </div>
                  </li>
                ))
              )}
            </ul>
          )}
        </div>

        {/* Trend Chart Card */}
        <div className="card">
          <div className="card-header">
            <h2>30-Day BMI Trend</h2>
          </div>
          <TrendChart />
        </div>
      </div>
    </>
  );
}
```

### File: `frontend/src/components/MeasurementForm.jsx`

```jsx
import React, { useState } from 'react';
import api from '../api';

export default function MF({ onSaved }) {
  const getTodayDate = () => new Date().toISOString().split('T')[0];
  const [f, sf] = useState({ 
    weightKg: 70, 
    heightCm: 175, 
    age: 30, 
    sex: 'male', 
    activity: 'moderate', 
    measurementDate: getTodayDate() 
  });
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(false);
  const [loading, setLoading] = useState(false);
  
  const sub = async e => {
    e.preventDefault();
    setError(null);
    setSuccess(false);
    setLoading(true);
    try {
      await api.post('/measurements', f);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
      onSaved && onSaved();
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to save measurement');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <form onSubmit={sub}>
      {error && <div className="alert alert-error">{error}</div>}
      {success && <div className="alert alert-success">Measurement saved successfully!</div>}
      
      <div className="form-row">
        <div className="form-group">
          <label htmlFor="measurementDate">Measurement Date</label>
          <input 
            id="measurementDate"
            type="date"
            value={f.measurementDate} 
            onChange={e => sf({ ...f, measurementDate: e.target.value })}
            required
            max={new Date().toISOString().split('T')[0]}
          />
        </div>
      </div>
      
      <div className="form-row">
        <div className="form-group">
          <label htmlFor="weight">Weight (kg)</label>
          <input 
            id="weight"
            type="number" 
            value={f.weightKg} 
            onChange={e => sf({ ...f, weightKg: +e.target.value })}
            required
            min="1"
            max="500"
            step="0.1"
            placeholder="70"
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="height">Height (cm)</label>
          <input 
            id="height"
            type="number"
            value={f.heightCm} 
            onChange={e => sf({ ...f, heightCm: +e.target.value })}
            required
            min="1"
            max="300"
            step="0.1"
            placeholder="175"
          />
        </div>
        
        <div className="form-group">
          <label htmlFor="age">Age (years)</label>
          <input 
            id="age"
            type="number"
            value={f.age} 
            onChange={e => sf({ ...f, age: +e.target.value })}
            required
            min="1"
            max="150"
            placeholder="30"
          />
        </div>
      </div>
      
      <div className="form-row">
        <div className="form-group">
          <label htmlFor="sex">Biological Sex</label>
          <select 
            id="sex"
            value={f.sex} 
            onChange={e => sf({ ...f, sex: e.target.value })}
            required
          >
            <option value="male">Male</option>
            <option value="female">Female</option>
          </select>
        </div>
        
        <div className="form-group">
          <label htmlFor="activity">Activity Level</label>
          <select 
            id="activity"
            value={f.activity} 
            onChange={e => sf({ ...f, activity: e.target.value })}
            required
          >
            <option value="sedentary">Sedentary (Little/No Exercise)</option>
            <option value="light">Light (1-3 days/week)</option>
            <option value="moderate">Moderate (3-5 days/week)</option>
            <option value="active">Active (6-7 days/week)</option>
            <option value="very_active">Very Active (2x per day)</option>
          </select>
        </div>
      </div>
      
      <button type="submit" disabled={loading}>
        {loading ? 'Saving...' : 'Save Measurement'}
      </button>
    </form>
  );
}
```

### File: `frontend/src/components/TrendChart.jsx`

```jsx
import React, { useEffect, useState } from 'react';
import { Line } from 'react-chartjs-2';
import api from '../api';
import { Chart as C, CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend } from 'chart.js';

C.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Legend);

export default function TC() {
  const [d, sd] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  useEffect(() => {
    setLoading(true);
    api.get('/measurements/trends')
      .then(r => {
        console.log('Trend data:', r.data);
        const rows = r.data.rows;
        if (rows && rows.length > 0) {
          sd({
            labels: rows.map(x => new Date(x.day).toLocaleDateString()),
            datasets: [{
              label: 'Average BMI',
              data: rows.map(x => parseFloat(x.avg_bmi)),
              borderColor: 'rgb(75, 192, 192)',
              backgroundColor: 'rgba(75, 192, 192, 0.2)',
              tension: 0.1
            }]
          });
        } else {
          setError(null); // Clear error if no data
        }
      })
      .catch(err => {
        console.error('Failed to load trends:', err);
        console.error('Error details:', err.response?.data);
        setError('Failed to load trend data');
      })
      .finally(() => setLoading(false));
  }, []);
  
  if (loading) return <div className="loading">Loading chart</div>;
  if (error) return <div className="alert alert-error">{error}</div>;
  if (!d) return <div className="empty-state"><p>No trend data available yet. Add measurements over multiple days to see trends!</p></div>;
  
  return <Line data={d} options={{
    responsive: true,
    plugins: {
      legend: { position: 'top' },
      title: { display: true, text: '30-Day BMI Trend' }
    }
  }} />;
}
```

### File: `frontend/src/index.css`

```css
:root {
  --primary: #4f46e5;
  --primary-dark: #4338ca;
  --primary-light: #818cf8;
  --secondary: #10b981;
  --danger: #ef4444;
  --warning: #f59e0b;
  --gray-50: #f9fafb;
  --gray-100: #f3f4f6;
  --gray-200: #e5e7eb;
  --gray-300: #d1d5db;
  --gray-600: #4b5563;
  --gray-700: #374151;
  --gray-800: #1f2937;
  --gray-900: #111827;
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  color: var(--gray-800);
  line-height: 1.6;
}

/* Header */
.app-header {
  background: rgba(255, 255, 255, 0.95);
  backdrop-filter: blur(10px);
  padding: 1.5rem 0;
  box-shadow: var(--shadow-md);
  margin-bottom: 2rem;
  border-bottom: 3px solid var(--primary);
}

.app-header h1 {
  color: var(--primary);
  font-size: 2.5rem;
  font-weight: 700;
  text-align: center;
  margin: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.75rem;
}

.app-subtitle {
  text-align: center;
  color: var(--gray-600);
  font-size: 1rem;
  margin-top: 0.5rem;
}

/* Container */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1.5rem 3rem;
}

/* Card */
.card {
  background: white;
  border-radius: 16px;
  padding: 2rem;
  box-shadow: var(--shadow-lg);
  margin-bottom: 2rem;
  transition: transform 0.2s, box-shadow 0.2s;
}

.card:hover {
  transform: translateY(-2px);
  box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
}

.card-header {
  border-bottom: 2px solid var(--gray-100);
  padding-bottom: 1rem;
  margin-bottom: 1.5rem;
}

.card-header h2 {
  color: var(--gray-800);
  font-size: 1.5rem;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

/* Form Styles */
form {
  display: grid;
  gap: 1.5rem;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

label {
  font-weight: 600;
  color: var(--gray-700);
  font-size: 0.875rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

input,
select {
  padding: 0.75rem 1rem;
  border: 2px solid var(--gray-200);
  border-radius: 8px;
  font-size: 1rem;
  transition: all 0.2s;
  background: var(--gray-50);
  font-family: inherit;
}

input:focus,
select:focus {
  outline: none;
  border-color: var(--primary);
  background: white;
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
}

input:hover,
select:hover {
  border-color: var(--gray-300);
}

/* Buttons */
button {
  padding: 0.875rem 2rem;
  background: linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%);
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  box-shadow: var(--shadow);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

button:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
  background: linear-gradient(135deg, var(--primary-dark) 0%, var(--primary) 100%);
}

button:active:not(:disabled) {
  transform: translateY(0);
}

button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* Alert Messages */
.alert {
  padding: 1rem 1.25rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-weight: 500;
  animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.alert-error {
  background-color: #fef2f2;
  color: #991b1b;
  border: 1px solid #fecaca;
}

.alert-success {
  background-color: #f0fdf4;
  color: #166534;
  border: 1px solid #bbf7d0;
}

/* Loading State */
.loading {
  text-align: center;
  padding: 3rem;
  color: var(--gray-600);
}

.loading::after {
  content: "";
  display: inline-block;
  width: 2rem;
  height: 2rem;
  border: 3px solid var(--gray-200);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
  margin-left: 1rem;
  vertical-align: middle;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Measurements List */
.measurements-list {
  list-style: none;
  display: grid;
  gap: 1rem;
}

.measurement-item {
  background: var(--gray-50);
  padding: 1.25rem;
  border-radius: 10px;
  border-left: 4px solid var(--primary);
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 1rem;
  align-items: center;
  transition: all 0.2s;
}

.measurement-item:hover {
  background: white;
  box-shadow: var(--shadow-md);
  transform: translateX(4px);
}

.measurement-date {
  font-weight: 600;
  color: var(--primary);
  font-size: 0.875rem;
}

.measurement-data {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
  align-items: center;
}

.measurement-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
  padding: 0.375rem 0.75rem;
  background: white;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 600;
  box-shadow: var(--shadow-sm);
}

.badge-bmi {
  color: var(--primary);
}

.badge-bmr {
  color: #f59e0b;
}

.badge-calories {
  color: var(--secondary);
}

.measurement-meta {
  font-size: 0.875rem;
  color: var(--gray-600);
}

.empty-state {
  text-align: center;
  padding: 3rem;
  color: var(--gray-600);
  background: var(--gray-50);
  border-radius: 12px;
  border: 2px dashed var(--gray-300);
}

/* Chart Container */
.chart-container {
  padding: 1.5rem;
  background: var(--gray-50);
  border-radius: 12px;
  min-height: 300px;
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.stat-card {
  background: linear-gradient(135deg, var(--primary-light) 0%, var(--primary) 100%);
  color: white;
  padding: 1.5rem;
  border-radius: 12px;
  text-align: center;
  box-shadow: var(--shadow);
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  display: block;
  margin-bottom: 0.25rem;
}

.stat-label {
  font-size: 0.875rem;
  opacity: 0.9;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

/* Responsive Design */
@media (max-width: 768px) {
  .app-header h1 {
    font-size: 2rem;
  }
  
  .card {
    padding: 1.5rem;
  }
  
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .measurement-item {
    grid-template-columns: 1fr;
    text-align: center;
  }
  
  .measurement-data {
    justify-content: center;
  }
}

@media (max-width: 480px) {
  .container {
    padding: 0 1rem 2rem;
  }
  
  .card {
    padding: 1rem;
    border-radius: 12px;
  }
}
```

---

## Deployment Scripts

The project includes automated deployment scripts. Reference the existing `IMPLEMENTATION_AUTO.sh` (908 lines) and `database/setup-database.sh` (688 lines) files in your project directory. These scripts handle:

- Prerequisites installation (Node.js, PostgreSQL, Nginx, PM2)
- Database setup (user, database, migrations)
- Backend deployment (dependencies, .env, PM2 start)
- Frontend build and deployment
- Nginx configuration
- Firewall setup (UFW)

---

## Project Recreation Steps

### Step 1: Initialize Project Structure

```bash
mkdir single-server-3tier-webapp-monitoring
cd single-server-3tier-webapp-monitoring

# Create directory structure
mkdir -p backend/src backend/migrations backend/logs
mkdir -p frontend/src/components
mkdir -p database
```

### Step 2: Create Backend Files

```bash
# Navigate to backend directory
cd backend

# Create all backend files by copying content from sections above
# - package.json
# - ecosystem.config.js
# - src/server.js
# - src/routes.js
# - src/db.js
# - src/calculations.js
# - migrations/001_create_measurements.sql
# - migrations/002_add_measurement_date.sql

# Install dependencies
npm install

# Create .env file
cat > .env << 'EOF'
PORT=3000
NODE_ENV=development
DATABASE_URL=postgresql://bmi_user:password@localhost:5432/bmidb
CORS_ORIGIN=*
FRONTEND_URL=http://localhost:5173
EOF
```

### Step 3: Create Frontend Files

```bash
# Navigate to frontend directory
cd ../frontend

# Create all frontend files by copying content from sections above
# - package.json
# - vite.config.js
# - index.html
# - src/main.jsx
# - src/App.jsx
# - src/api.js
# - src/index.css
# - src/components/MeasurementForm.jsx
# - src/components/TrendChart.jsx

# Install dependencies
npm install
```

### Step 4: Setup Database

```bash
# Install PostgreSQL (Ubuntu/Debian)
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database user and database
sudo -u postgres psql << EOF
CREATE USER bmi_user WITH PASSWORD 'your_secure_password';
CREATE DATABASE bmidb OWNER bmi_user;
\c bmidb
GRANT ALL PRIVILEGES ON DATABASE bmidb TO bmi_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO bmi_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO bmi_user;
EOF

# Run migrations
cd ../backend
sudo -u postgres psql -U bmi_user -d bmidb -f migrations/001_create_measurements.sql
sudo -u postgres psql -U bmi_user -d bmidb -f migrations/002_add_measurement_date.sql
```

### Step 5: Local Development Testing

```bash
# Terminal 1: Start backend
cd backend
npm run dev

# Terminal 2: Start frontend
cd frontend
npm run dev

# Access application at http://localhost:5173
```

### Step 6: Production Deployment (AWS EC2)

```bash
# Install PM2 globally
sudo npm install -g pm2

# Build frontend
cd frontend
npm run build

# Copy dist to web server directory
sudo mkdir -p /var/www/bmi-health-tracker
sudo cp -r dist/* /var/www/bmi-health-tracker/

# Start backend with PM2
cd ../backend
pm2 start ecosystem.config.js
pm2 save
pm2 startup systemd

# Install and configure Nginx
sudo apt install -y nginx

# Create Nginx configuration
sudo tee /etc/nginx/sites-available/bmi-health-tracker << 'EOF'
server {
    listen 80;
    server_name your-domain-or-ip;
    
    # Frontend - serve static files
    location / {
        root /var/www/bmi-health-tracker;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
    
    # Backend API - reverse proxy
    location /api/ {
        proxy_pass http://127.0.0.1:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
EOF

# Enable site
sudo ln -s /etc/nginx/sites-available/bmi-health-tracker /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx HTTP'
sudo ufw allow 'Nginx HTTPS'
sudo ufw enable
```

---

## Testing & Verification

### Backend API Tests

```bash
# Health check
curl http://localhost:3000/health

# Create measurement
curl -X POST http://localhost:3000/api/measurements \
  -H "Content-Type: application/json" \
  -d '{
    "weightKg": 70,
    "heightCm": 175,
    "age": 30,
    "sex": "male",
    "activity": "moderate",
    "measurementDate": "2026-01-01"
  }'

# Get all measurements
curl http://localhost:3000/api/measurements

# Get trends
curl http://localhost:3000/api/measurements/trends
```

### Database Verification

```bash
# Connect to database
sudo -u postgres psql -U bmi_user -d bmidb

# Check table
\dt

# View data
SELECT * FROM measurements LIMIT 5;

# Check indexes
\di
```

### Application Health Checks

```bash
# Check PM2 status
pm2 status

# View PM2 logs
pm2 logs bmi-backend

# Check Nginx status
sudo systemctl status nginx

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

---

## API Documentation

### Endpoints

#### GET /health
Health check endpoint for monitoring.

**Response:**
```json
{
  "status": "ok",
  "environment": "production"
}
```

#### POST /api/measurements
Create a new health measurement.

**Request Body:**
```json
{
  "weightKg": 70,
  "heightCm": 175,
  "age": 30,
  "sex": "male",
  "activity": "moderate",
  "measurementDate": "2026-01-01"
}
```

**Response (201):**
```json
{
  "measurement": {
    "id": 1,
    "weight_kg": "70.00",
    "height_cm": "175.00",
    "age": 30,
    "sex": "male",
    "activity_level": "moderate",
    "bmi": "22.9",
    "bmi_category": "Normal",
    "bmr": 1668,
    "daily_calories": 2585,
    "measurement_date": "2026-01-01",
    "created_at": "2026-01-01T12:00:00.000Z"
  }
}
```

#### GET /api/measurements
Retrieve all measurements.

**Response (200):**
```json
{
  "rows": [
    { "id": 1, "bmi": "22.9", "..." }
  ]
}
```

#### GET /api/measurements/trends
Get 30-day BMI trend data.

**Response (200):**
```json
{
  "rows": [
    { "day": "2026-01-01", "avg_bmi": "22.9" }
  ]
}
```

---

## Maintenance Commands

```bash
# Restart backend
pm2 restart bmi-backend

# Update backend code
cd backend
git pull
npm install
pm2 restart bmi-backend

# Rebuild and redeploy frontend
cd frontend
npm install
npm run build
sudo rm -rf /var/www/bmi-health-tracker/*
sudo cp -r dist/* /var/www/bmi-health-tracker/

# Database backup
pg_dump -U bmi_user bmidb > backup_$(date +%Y%m%d).sql

# Database restore
psql -U bmi_user bmidb < backup_20260101.sql
```

---

## Conclusion

This AGENT.md file provides complete instructions to recreate the BMI & Health Tracker application from scratch. All source code, configuration files, database schemas, and deployment procedures are included. Follow the Project Recreation Steps section sequentially to build and deploy the entire 3-tier application.

For user-facing documentation and learning resources, refer to the companion README.md file.

**Project Status:** Production-Ready ✅  
**Deployment Target:** AWS EC2 Ubuntu 22.04 LTS  
**Architecture:** 3-Tier (React + Node.js/Express + PostgreSQL)
