#!/bin/bash

##############################################################################
# BMI Health Tracker - Application Server Exporters Setup Script
# 
# This script installs and configures exporters on the application server:
# - Node Exporter (system metrics)
# - PostgreSQL Exporter (database metrics)
# - Nginx Exporter (web server metrics)
# - Promtail (log shipping to Loki)
# - BMI Custom App Exporter (application metrics)
#
# Usage: sudo ./setup-application-exporters.sh
##############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Versions
NODE_EXPORTER_VERSION="1.7.0"
POSTGRES_EXPORTER_VERSION="0.15.0"
NGINX_EXPORTER_VERSION="0.11.0"
PROMTAIL_VERSION="2.9.3"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "Please run as root or with sudo"
        exit 1
    fi
}

# Main execution
log_info "====================================================================="
log_info "BMI Health Tracker - Application Server Exporters Setup"
log_info "====================================================================="

check_root

# Get monitoring server IP
echo ""
read -p "Enter MONITORING SERVER IP address: " MONITORING_IP
if [ -z "$MONITORING_IP" ]; then
    log_error "Monitoring server IP is required"
    exit 1
fi

log_info "Monitoring server IP: $MONITORING_IP"

# Get database credentials
echo ""
log_info "PostgreSQL Database Configuration:"
read -p "Database Name [bmi_tracker]: " DB_NAME
DB_NAME=${DB_NAME:-bmi_tracker}
read -p "Database User [bmi_user]: " DB_USER
DB_USER=${DB_USER:-bmi_user}
read -sp "Database Password: " DB_PASSWORD
echo ""

if [ -z "$DB_PASSWORD" ]; then
    log_error "Database password is required"
    exit 1
fi

# Update system
log_info "Updating system packages..."
apt update && apt upgrade -y
log_success "System updated"

# Install essential tools
log_info "Installing essential tools..."
apt install -y curl wget git vim htop net-tools unzip
log_success "Essential tools installed"

# Create users
log_info "Creating service users..."
useradd --no-create-home --shell /bin/false node_exporter || true
useradd --no-create-home --shell /bin/false postgres_exporter || true
useradd --no-create-home --shell /bin/false nginx_exporter || true
log_success "Service users created"

#=============================================================================
# INSTALL NODE EXPORTER
#=============================================================================
log_info "Installing Node Exporter ${NODE_EXPORTER_VERSION}..."
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create Node Exporter systemd service
cat > /etc/systemd/system/node_exporter.service <<'EOFSVC'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOFSVC

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

log_success "Node Exporter installed and started on port 9100"

#=============================================================================
# INSTALL POSTGRESQL EXPORTER
#=============================================================================
log_info "Installing PostgreSQL Exporter ${POSTGRES_EXPORTER_VERSION}..."
cd /tmp
wget -q https://github.com/prometheus-community/postgres_exporter/releases/download/v${POSTGRES_EXPORTER_VERSION}/postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64.tar.gz
tar -xzf postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64.tar.gz
cp postgres_exporter-${POSTGRES_EXPORTER_VERSION}.linux-amd64/postgres_exporter /usr/local/bin/
chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter

# Create environment file for postgres exporter
cat > /etc/default/postgres_exporter <<EOFENV
DATA_SOURCE_NAME=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}?sslmode=disable
EOFENV

chmod 600 /etc/default/postgres_exporter
chown postgres_exporter:postgres_exporter /etc/default/postgres_exporter

# Create PostgreSQL Exporter systemd service
cat > /etc/systemd/system/postgres_exporter.service <<'EOFSVC'
[Unit]
Description=PostgreSQL Exporter
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=postgres_exporter
EnvironmentFile=/etc/default/postgres_exporter
ExecStart=/usr/local/bin/postgres_exporter

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOFSVC

systemctl daemon-reload
systemctl enable postgres_exporter
systemctl start postgres_exporter

log_success "PostgreSQL Exporter installed and started on port 9187"

#=============================================================================
# INSTALL NGINX EXPORTER
#=============================================================================
log_info "Installing Nginx Exporter ${NGINX_EXPORTER_VERSION}..."

# First, enable nginx stub_status
log_info "Configuring Nginx stub_status..."
cat > /etc/nginx/sites-available/status <<'EOFNGINX'
server {
    listen 8080;
    server_name localhost;

    location /stub_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}
EOFNGINX

ln -sf /etc/nginx/sites-available/status /etc/nginx/sites-enabled/status
nginx -t && systemctl reload nginx
log_success "Nginx stub_status enabled"

# Install nginx exporter
cd /tmp
wget -q https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_EXPORTER_VERSION}/nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz
tar -xzf nginx-prometheus-exporter_${NGINX_EXPORTER_VERSION}_linux_amd64.tar.gz
cp nginx-prometheus-exporter /usr/local/bin/
chown nginx_exporter:nginx_exporter /usr/local/bin/nginx-prometheus-exporter

# Create Nginx Exporter systemd service
cat > /etc/systemd/system/nginx_exporter.service <<'EOFSVC'
[Unit]
Description=Nginx Prometheus Exporter
After=network.target nginx.service
Requires=nginx.service

[Service]
Type=simple
User=nginx_exporter
ExecStart=/usr/local/bin/nginx-prometheus-exporter \
  -nginx.scrape-uri=http://localhost:8080/stub_status

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOFSVC

systemctl daemon-reload
systemctl enable nginx_exporter
systemctl start nginx_exporter

log_success "Nginx Exporter installed and started on port 9113"

#=============================================================================
# INSTALL PROMTAIL
#=============================================================================
log_info "Installing Promtail ${PROMTAIL_VERSION}..."
cd /tmp
wget -q https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
unzip -o promtail-linux-amd64.zip
mv promtail-linux-amd64 /usr/local/bin/promtail
chmod +x /usr/local/bin/promtail

# Create Promtail directories
mkdir -p /etc/promtail
mkdir -p /var/lib/promtail/positions

# Create Promtail configuration
cat > /etc/promtail/promtail-config.yml <<EOFPROMTAIL
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions/positions.yaml

clients:
  - url: http://${MONITORING_IP}:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          __path__: /var/log/syslog

  - job_name: nginx_access
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: access
          __path__: /var/log/nginx/access.log

  - job_name: nginx_error
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: error
          __path__: /var/log/nginx/error.log

  - job_name: bmi_backend
    static_configs:
      - targets:
          - localhost
        labels:
          job: bmi-backend
          __path__: /root/.pm2/logs/*out.log

  - job_name: postgresql
    static_configs:
      - targets:
          - localhost
        labels:
          job: postgresql
          __path__: /var/log/postgresql/*.log
    pipeline_stages:
      - regex:
          expression: '^(?P<timestamp>\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?) \\w+ \\[(?P<pid>\\d+)\\] (?P<level>\\w+):\\s+(?P<message>.*)$'
      - labels:
          level:
EOFPROMTAIL

# Create Promtail systemd service
cat > /etc/systemd/system/promtail.service <<'EOFSVC'
[Unit]
Description=Promtail Log Collector
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOFSVC

systemctl daemon-reload
systemctl enable promtail
systemctl start promtail

log_success "Promtail installed and started on port 9080"

#=============================================================================
# INSTALL BMI CUSTOM APP EXPORTER
#=============================================================================
log_info "Installing BMI Custom Application Exporter..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Create exporter directory
EXPORTER_DIR="/opt/bmi-exporter"
mkdir -p $EXPORTER_DIR
cd $EXPORTER_DIR

# Copy exporter files (assumes they exist in monitoring/exporters/bmi-app-exporter/)
log_info "Setting up custom exporter files..."
cat > package.json <<'EOFPKG'
{
  "name": "bmi-app-exporter",
  "version": "1.0.0",
  "description": "Custom Prometheus exporter for BMI Health Tracker",
  "main": "exporter.js",
  "scripts": {
    "start": "node exporter.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "prom-client": "^15.0.0",
    "pg": "^8.11.3",
    "dotenv": "^16.3.1"
  }
}
EOFPKG

# Create .env file for exporter
cat > .env <<EOFENV
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=${DB_NAME}
DB_HOST=localhost
DB_PORT=5432
EXPORTER_PORT=9091
EOFENV

# Copy the actual exporter code
cat > exporter.js <<'EOFEXP'
const express = require('express');
const client = require('prom-client');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.EXPORTER_PORT || 9091;

// Create PostgreSQL connection pool
const pool = new Pool({
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
});

// Create a Registry
const register = new client.Registry();

// Add default metrics
client.collectDefaultMetrics({ register });

// Custom metrics
const totalMeasurements = new client.Gauge({
  name: 'bmi_measurements_total',
  help: 'Total number of BMI measurements in database',
  registers: [register],
});

const measurementsLast24h = new client.Gauge({
  name: 'bmi_measurements_created_24h',
  help: 'Number of BMI measurements created in last 24 hours',
  registers: [register],
});

const measurementsLastHour = new client.Gauge({
  name: 'bmi_measurements_created_1h',
  help: 'Number of BMI measurements created in last hour',
  registers: [register],
});

const avgBMI = new client.Gauge({
  name: 'bmi_average_value',
  help: 'Average BMI value across all measurements',
  registers: [register],
});

const bmiByCategory = new client.Gauge({
  name: 'bmi_category_count',
  help: 'Count of measurements by BMI category',
  labelNames: ['category'],
  registers: [register],
});

const databaseSize = new client.Gauge({
  name: 'bmi_database_size_bytes',
  help: 'Total size of database in bytes',
  registers: [register],
});

const tableSize = new client.Gauge({
  name: 'bmi_table_size_bytes',
  help: 'Size of measurements table in bytes',
  registers: [register],
});

const dbConnectionPool = new client.Gauge({
  name: 'bmi_db_pool_total',
  help: 'Total number of database connections in pool',
  registers: [register],
});

const dbConnectionsIdle = new client.Gauge({
  name: 'bmi_db_pool_idle',
  help: 'Number of idle database connections',
  registers: [register],
});

const dbConnectionsWaiting = new client.Gauge({
  name: 'bmi_db_pool_waiting',
  help: 'Number of waiting database connections',
  registers: [register],
});

const appHealthy = new client.Gauge({
  name: 'bmi_app_healthy',
  help: 'Application health status (1 = healthy, 0 = unhealthy)',
  registers: [register],
});

// Collection function
async function collectMetrics() {
  try {
    // Total measurements
    const totalResult = await pool.query('SELECT COUNT(*) FROM measurements');
    totalMeasurements.set(parseInt(totalResult.rows[0].count));

    // Measurements last 24 hours
    const last24hResult = await pool.query(
      "SELECT COUNT(*) FROM measurements WHERE created_at > NOW() - INTERVAL '24 hours'"
    );
    measurementsLast24h.set(parseInt(last24hResult.rows[0].count));

    // Measurements last hour
    const lastHourResult = await pool.query(
      "SELECT COUNT(*) FROM measurements WHERE created_at > NOW() - INTERVAL '1 hour'"
    );
    measurementsLastHour.set(parseInt(lastHourResult.rows[0].count));

    // Average BMI
    const avgBMIResult = await pool.query('SELECT AVG(bmi) FROM measurements');
    avgBMI.set(parseFloat(avgBMIResult.rows[0].avg) || 0);

    // BMI by category
    const categoryResult = await pool.query(`
      SELECT 
        CASE 
          WHEN bmi < 18.5 THEN 'underweight'
          WHEN bmi >= 18.5 AND bmi < 25 THEN 'normal'
          WHEN bmi >= 25 AND bmi < 30 THEN 'overweight'
          ELSE 'obese'
        END as category,
        COUNT(*) as count
      FROM measurements
      GROUP BY category
    `);
    
    categoryResult.rows.forEach(row => {
      bmiByCategory.set({ category: row.category }, parseInt(row.count));
    });

    // Database size
    const dbSizeResult = await pool.query(
      "SELECT pg_database_size(current_database()) as size"
    );
    databaseSize.set(parseInt(dbSizeResult.rows[0].size));

    // Table size
    const tableSizeResult = await pool.query(
      "SELECT pg_total_relation_size('measurements') as size"
    );
    tableSize.set(parseInt(tableSizeResult.rows[0].size));

    // Connection pool stats
    dbConnectionPool.set(pool.totalCount);
    dbConnectionsIdle.set(pool.idleCount);
    dbConnectionsWaiting.set(pool.waitingCount);

    // App health
    appHealthy.set(1);
  } catch (error) {
    console.error('Error collecting metrics:', error);
    appHealthy.set(0);
  }
}

// Collect metrics every 15 seconds
setInterval(collectMetrics, 15000);
collectMetrics(); // Initial collection

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Health endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`BMI Custom Exporter running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing connections...');
  await pool.end();
  process.exit(0);
});
EOFEXP

# Install dependencies
log_info "Installing exporter dependencies..."
npm install --production

# Create PM2 ecosystem file
cat > ecosystem.config.js <<'EOFPM2'
module.exports = {
  apps: [{
    name: 'bmi-exporter',
    script: './exporter.js',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
    },
    max_memory_restart: '200M',
    error_file: '/root/.pm2/logs/bmi-exporter-error.log',
    out_file: '/root/.pm2/logs/bmi-exporter-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
};
EOFPM2

# Start with PM2
log_info "Starting BMI Custom Exporter with PM2..."
pm2 start ecosystem.config.js
pm2 save

log_success "BMI Custom Exporter installed and started on port 9091"

#=============================================================================
# FIREWALL CONFIGURATION
#=============================================================================
log_info "Configuring firewall (UFW)..."
ufw allow from $MONITORING_IP to any port 9100 comment 'Node Exporter'
ufw allow from $MONITORING_IP to any port 9187 comment 'PostgreSQL Exporter'
ufw allow from $MONITORING_IP to any port 9113 comment 'Nginx Exporter'
ufw allow from $MONITORING_IP to any port 9091 comment 'BMI Custom Exporter'
ufw reload
log_success "Firewall configured"

#=============================================================================
# CLEANUP
#=============================================================================
log_info "Cleaning up temporary files..."
cd /tmp
rm -rf node_exporter-* postgres_exporter-* nginx-prometheus-exporter* promtail-linux-amd64*
log_success "Cleanup completed"

#=============================================================================
# SUMMARY
#=============================================================================
echo ""
log_success "====================================================================="
log_success "Application Server Exporters Setup Completed Successfully!"
log_success "====================================================================="
echo ""
log_info "Services Status:"
systemctl is-active node_exporter && log_success "✓ Node Exporter: Running on port 9100" || log_error "✗ Node Exporter: Failed"
systemctl is-active postgres_exporter && log_success "✓ PostgreSQL Exporter: Running on port 9187" || log_error "✗ PostgreSQL Exporter: Failed"
systemctl is-active nginx_exporter && log_success "✓ Nginx Exporter: Running on port 9113" || log_error "✗ Nginx Exporter: Failed"
systemctl is-active promtail && log_success "✓ Promtail: Running on port 9080" || log_error "✗ Promtail: Failed"
pm2 list | grep -q bmi-exporter && log_success "✓ BMI Custom Exporter: Running on port 9091" || log_error "✗ BMI Custom Exporter: Failed"

echo ""
log_info "Test Endpoints:"
APP_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "  Node Exporter:       curl http://localhost:9100/metrics"
echo "  PostgreSQL Exporter: curl http://localhost:9187/metrics"
echo "  Nginx Exporter:      curl http://localhost:9113/metrics"
echo "  BMI Custom Exporter: curl http://localhost:9091/metrics"
echo "  Promtail Status:     curl http://localhost:9080/ready"

echo ""
log_warning "Next Steps:"
echo "  1. Verify all exporters are running: systemctl status <service>"
echo "  2. Check Prometheus targets: http://${MONITORING_IP}:9090/targets"
echo "  3. Verify logs flowing to Loki in Grafana"
echo "  4. Import Grafana dashboards"
echo ""

log_info "For detailed documentation, see: monitoring/IMPLEMENTATION_GUIDE.md"
