# 📊 Monitoring Stack Implementation Guide

> Complete step-by-step guide to set up comprehensive monitoring for the BMI & Health Tracker application using Prometheus, Grafana, Loki, and exporters.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Decisions](#architecture-decisions)
3. [Prerequisites](#prerequisites)
4. [Part 1: Provision Monitoring Server](#part-1-provision-monitoring-server)
5. [Part 2: Install Monitoring Stack](#part-2-install-monitoring-stack)
6. [Part 3: Configure Application Server](#part-3-configure-application-server)
7. [Part 4: Set Up Dashboards](#part-4-set-up-dashboards)
8. [Part 5: Configure Alerting](#part-5-configure-alerting)
9. [Part 6: Testing & Validation](#part-6-testing--validation)
10. [Part 7: Maintenance & Operations](#part-7-maintenance--operations)

---

## Overview

This guide will help you set up a production-ready monitoring solution with:
- **Prometheus** for metrics collection
- **Grafana** for visualization
- **Loki** for log aggregation
- **Multiple exporters** for comprehensive metrics
- **AlertManager** for notifications

**Estimated Time:** 2-3 hours for complete setup

---

## Architecture Decisions

### Two-Server Setup

**Why not monitor on the same server?**
1. **Resource Isolation:** Monitoring consumes CPU/memory
2. **Reliability:** If app server crashes, monitoring continues
3. **Security:** Separate monitoring from production traffic
4. **Scalability:** Easy to add more app servers later

### Component Selection

| Component | Why This Choice |
|-----------|-----------------|
| **Prometheus** | Industry standard, excellent for time-series metrics |
| **Grafana** | Best visualization tool, extensive dashboard library |
| **Loki** | Lightweight, integrates perfectly with Grafana |
| **Node Exporter** | Official exporter for Linux metrics |
| **PostgreSQL Exporter** | Comprehensive database metrics |

---

## Prerequisites

### Required

- [ ] **Two AWS EC2 Instances:**
  - Application Server (already running BMI app)
  - New Monitoring Server (t2.small minimum, t2.medium recommended)
- [ ] **SSH access** to both servers
- [ ] **Same VPC** or network connectivity between servers
- [ ] **Basic Linux knowledge** (systemd, networking, file editing)

### Server Specifications

**Monitoring Server:**
- **Instance Type:** t2.small (minimum) or t2.medium (recommended)
- **OS:** Ubuntu 22.04 LTS
- **Storage:** 100GB GP3 EBS volume
- **RAM:** 2GB minimum, 4GB recommended
- **vCPUs:** 2 minimum

**Application Server:**
- Your existing BMI app server

### Network Requirements

**Security Group for Monitoring Server (Inbound):**
```
Port 3000  → From Your IP (Grafana Web UI)
Port 9090  → From Your IP (Prometheus Web UI)
Port 9093  → From Your IP (AlertManager Web UI)
Port 3100  → From Application Server IP (Loki)
Port 22    → From Your IP (SSH)
```

**Security Group for Application Server (Inbound):**
```
Port 9100  → From Monitoring Server IP (Node Exporter)
Port 9187  → From Monitoring Server IP (PostgreSQL Exporter)
Port 9113  → From Monitoring Server IP (Nginx Exporter)
Port 9091  → From Monitoring Server IP (Custom App Exporter)
```

---

## Part 1: Provision Monitoring Server

### Step 1.1: Launch EC2 Instance

```bash
# Via AWS Console:
1. Go to EC2 Dashboard
2. Click "Launch Instance"
3. Name: "bmi-monitoring-server"
4. AMI: Ubuntu Server 22.04 LTS
5. Instance Type: t2.small or t2.medium
6. Key Pair: Select existing or create new
7. Network Settings:
   - VPC: Same as application server
   - Subnet: Public subnet
   - Auto-assign Public IP: Enable
8. Storage: 100GB GP3
9. Launch Instance
```

### Step 1.2: Connect to Monitoring Server

```bash
# Get public IP from AWS Console
ssh -i your-key.pem ubuntu@MONITORING_SERVER_IP

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git vim htop net-tools
```

### Step 1.3: Create Directory Structure

```bash
# Create directories for monitoring components
sudo mkdir -p /opt/monitoring/{prometheus,grafana,loki,promtail,alertmanager}
sudo mkdir -p /var/lib/{prometheus,grafana,loki}
sudo mkdir -p /etc/{prometheus,grafana,loki,promtail,alertmanager}

# Set permissions
sudo useradd --no-create-home --shell /bin/false prometheus
sudo useradd --no-create-home --shell /bin/false grafana
sudo useradd --no-create-home --shell /bin/false loki

sudo chown -R prometheus:prometheus /opt/monitoring/prometheus /var/lib/prometheus /etc/prometheus
sudo chown -R grafana:grafana /var/lib/grafana /etc/grafana
sudo chown -R loki:loki /var/lib/loki /etc/loki
```

---

## Part 2: Install Monitoring Stack

### Step 2.1: Install Prometheus

```bash
# Download Prometheus
cd /tmp
PROM_VERSION="2.48.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz

# Extract and install
tar -xzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROM_VERSION}.linux-amd64

sudo cp prometheus promtool /usr/local/bin/
sudo cp -r consoles console_libraries /etc/prometheus/

# Create configuration file
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'bmi-health-tracker'
    environment: 'production'

# AlertManager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - localhost:9093

# Load alerting rules
rule_files:
  - "alert_rules.yml"

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter (System Metrics) - Application Server
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9100']
        labels:
          server: 'bmi-app-server'
          role: 'application'

  # PostgreSQL Exporter - Application Server
  - job_name: 'postgresql'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9187']
        labels:
          server: 'bmi-app-server'
          database: 'bmidb'

  # Nginx Exporter - Application Server
  - job_name: 'nginx'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9113']
        labels:
          server: 'bmi-app-server'
          role: 'webserver'

  # Custom Application Metrics - Application Server
  - job_name: 'bmi-backend'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9091']
        labels:
          server: 'bmi-app-server'
          application: 'bmi-health-tracker'

  # Node Exporter - Monitoring Server (self-monitoring)
  - job_name: 'node_exporter_monitoring'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          server: 'monitoring-server'
          role: 'monitoring'
EOF

# Replace APPLICATION_SERVER_IP with actual IP
# Edit the file:
sudo vim /etc/prometheus/prometheus.yml
# Replace all instances of APPLICATION_SERVER_IP

# Create alert rules
sudo tee /etc/prometheus/alert_rules.yml > /dev/null <<'EOF'
groups:
  - name: instance_alerts
    interval: 30s
    rules:
      # Instance down
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} has been down for more than 1 minute."

      # High CPU usage
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 90% for 5 minutes."

      # High memory usage
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 90% for 5 minutes."

      # Disk space critical
      - alert: DiskSpaceCritical
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Disk space critical on {{ $labels.instance }}"
          description: "Less than 10% disk space remaining."

  - name: application_alerts
    interval: 30s
    rules:
      # High API error rate
      - alert: HighAPIErrorRate
        expr: (rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])) * 100 > 5
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High API error rate"
          description: "More than 5% of requests returning 5xx errors."

      # Database down
      - alert: PostgreSQLDown
        expr: pg_up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PostgreSQL is down"
          description: "PostgreSQL database is not responding."

      # High database connections
      - alert: HighDatabaseConnections
        expr: (pg_stat_database_numbackends / pg_settings_max_connections) * 100 > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High database connection usage"
          description: "Database connections usage is above 80%."
EOF

# Set permissions
sudo chown -R prometheus:prometheus /etc/prometheus

# Create systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --storage.tsdb.retention.time=30d \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start Prometheus
sudo systemctl daemon-reload
sudo systemctl start prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus

# Verify
curl http://localhost:9090/-/healthy
```

### Step 2.2: Install Grafana

```bash
# Add Grafana repository
sudo apt install -y software-properties-common
sudo add-apt-repository "deb https://apt.grafana.com stable main"
wget -q -O - https://apt.grafana.com/gpg.key | sudo apt-key add -

# Install Grafana
sudo apt update
sudo apt install -y grafana

# Start Grafana
sudo systemctl start grafana-server
sudo systemctl enable grafana-server
sudo systemctl status grafana-server

# Verify
curl http://localhost:3000/api/health
```

**Access Grafana:**
- URL: `http://MONITORING_SERVER_IP:3000`
- Default username: `admin`
- Default password: `admin`
- **Change password immediately!**

### Step 2.3: Install Loki

```bash
# Download Loki
cd /tmp
LOKI_VERSION="2.9.3"
wget https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki

# Create configuration
sudo tee /etc/loki/loki-config.yml > /dev/null <<'EOF'
auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

limits_config:
  retention_period: 744h  # 31 days
  ingestion_rate_mb: 10
  ingestion_burst_size_mb: 20

chunk_store_config:
  max_look_back_period: 744h

table_manager:
  retention_deletes_enabled: true
  retention_period: 744h
EOF

# Create systemd service
sudo tee /etc/systemd/system/loki.service > /dev/null <<'EOF'
[Unit]
Description=Loki Log Aggregation System
After=network.target

[Service]
Type=simple
User=loki
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-config.yml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Set permissions and start
sudo chown -R loki:loki /var/lib/loki /etc/loki
sudo systemctl daemon-reload
sudo systemctl start loki
sudo systemctl enable loki
sudo systemctl status loki

# Verify
curl http://localhost:3100/ready
```

### Step 2.4: Install AlertManager

```bash
# Download AlertManager
cd /tmp
AM_VERSION="0.26.0"
wget https://github.com/prometheus/alertmanager/releases/download/v${AM_VERSION}/alertmanager-${AM_VERSION}.linux-amd64.tar.gz
tar -xzf alertmanager-${AM_VERSION}.linux-amd64.tar.gz
cd alertmanager-${AM_VERSION}.linux-amd64

sudo cp alertmanager amtool /usr/local/bin/

# Create configuration
sudo tee /etc/alertmanager/alertmanager.yml > /dev/null <<'EOF'
global:
  resolve_timeout: 5m
  # Email configuration (optional)
  # smtp_smarthost: 'smtp.gmail.com:587'
  # smtp_from: 'your-email@gmail.com'
  # smtp_auth_username: 'your-email@gmail.com'
  # smtp_auth_password: 'your-app-password'

route:
  receiver: 'default-receiver'
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  routes:
    - receiver: 'critical-alerts'
      match:
        severity: critical
      continue: true
    - receiver: 'warning-alerts'
      match:
        severity: warning

receivers:
  - name: 'default-receiver'
    # Add notification methods here

  - name: 'critical-alerts'
    # Email example (uncomment and configure)
    # email_configs:
    #   - to: 'oncall@example.com'
    #     send_resolved: true
    #     headers:
    #       Subject: '[CRITICAL] {{ .GroupLabels.alertname }}'
    
    # Slack example (uncomment and configure)
    # slack_configs:
    #   - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    #     channel: '#alerts'
    #     title: 'CRITICAL Alert'
    #     text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'warning-alerts'
    # Similar configuration for warnings

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOF

# Create systemd service
sudo tee /etc/systemd/system/alertmanager.service > /dev/null <<'EOF'
[Unit]
Description=AlertManager
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager \
  --web.listen-address=0.0.0.0:9093

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Set permissions and start
sudo mkdir -p /var/lib/alertmanager
sudo chown -R prometheus:prometheus /etc/alertmanager /var/lib/alertmanager
sudo systemctl daemon-reload
sudo systemctl start alertmanager
sudo systemctl enable alertmanager
sudo systemctl status alertmanager

# Verify
curl http://localhost:9093/-/healthy
```

### Step 2.5: Install Node Exporter (Monitoring Server Self-Monitoring)

```bash
# Download Node Exporter
cd /tmp
NE_VERSION="1.7.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NE_VERSION}/node_exporter-${NE_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NE_VERSION}.linux-amd64.tar.gz
sudo cp node_exporter-${NE_VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/node_exporter \
  --collector.filesystem.mount-points-exclude='^/(sys|proc|dev|host|etc)($$|/)' \
  --collector.netclass.ignored-devices='^(veth.*|br-.*|docker.*|virbr.*|lo)$$'

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start Node Exporter
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter

# Verify
curl http://localhost:9100/metrics | head
```

---

## Part 3: Configure Application Server

### Step 3.1: Install Node Exporter

```bash
# SSH to application server
ssh -i your-key.pem ubuntu@APPLICATION_SERVER_IP

# Download and install Node Exporter
cd /tmp
NE_VERSION="1.7.0"
wget https://github.com/prometheus/node_exporter/releases/download/v${NE_VERSION}/node_exporter-${NE_VERSION}.linux-amd64.tar.gz
tar -xzf node_exporter-${NE_VERSION}.linux-amd64.tar.gz
sudo cp node_exporter-${NE_VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Create user
sudo useradd --no-create-home --shell /bin/false node_exporter

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'EOF'
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
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter

# Verify
curl http://localhost:9100/metrics | head
```

### Step 3.2: Install PostgreSQL Exporter

```bash
# Download PostgreSQL Exporter
cd /tmp
PG_VERSION="0.15.0"
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v${PG_VERSION}/postgres_exporter-${PG_VERSION}.linux-amd64.tar.gz
tar -xzf postgres_exporter-${PG_VERSION}.linux-amd64.tar.gz
sudo cp postgres_exporter-${PG_VERSION}.linux-amd64/postgres_exporter /usr/local/bin/

# Create user
sudo useradd --no-create-home --shell /bin/false postgres_exporter

# Create environment file with database credentials
sudo tee /etc/default/postgres_exporter > /dev/null <<'EOF'
DATA_SOURCE_NAME="postgresql://bmi_user:YOUR_DB_PASSWORD@localhost:5432/bmidb?sslmode=disable"
EOF

# Replace YOUR_DB_PASSWORD with actual password
sudo vim /etc/default/postgres_exporter

# Create systemd service
sudo tee /etc/systemd/system/postgres_exporter.service > /dev/null <<'EOF'
[Unit]
Description=PostgreSQL Exporter
After=network.target

[Service]
Type=simple
User=postgres_exporter
EnvironmentFile=/etc/default/postgres_exporter
ExecStart=/usr/local/bin/postgres_exporter

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Set permissions
sudo chown postgres_exporter:postgres_exporter /etc/default/postgres_exporter
sudo chmod 600 /etc/default/postgres_exporter

# Start service
sudo systemctl daemon-reload
sudo systemctl start postgres_exporter
sudo systemctl enable postgres_exporter
sudo systemctl status postgres_exporter

# Verify
curl http://localhost:9187/metrics | grep pg_up
```

### Step 3.3: Install Nginx Exporter

```bash
# First, enable Nginx stub_status module
sudo tee -a /etc/nginx/sites-available/bmi-health-tracker > /dev/null <<'EOF'

# Add this location block inside the server block:
location /stub_status {
    stub_status on;
    access_log off;
    allow 127.0.0.1;
    deny all;
}
EOF

# Edit your Nginx configuration to add the stub_status location
sudo vim /etc/nginx/sites-available/bmi-health-tracker
# Add the location /stub_status block above

# Test and reload Nginx
sudo nginx -t
sudo systemctl reload nginx

# Verify stub_status works
curl http://localhost/stub_status

# Download Nginx Exporter
cd /tmp
NGINX_VERSION="0.11.0"
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v${NGINX_VERSION}/nginx-prometheus-exporter_${NGINX_VERSION}_linux_amd64.tar.gz
tar -xzf nginx-prometheus-exporter_${NGINX_VERSION}_linux_amd64.tar.gz
sudo cp nginx-prometheus-exporter /usr/local/bin/

# Create user
sudo useradd --no-create-home --shell /bin/false nginx_exporter

# Create systemd service
sudo tee /etc/systemd/system/nginx_exporter.service > /dev/null <<'EOF'
[Unit]
Description=Nginx Prometheus Exporter
After=network.target

[Service]
Type=simple
User=nginx_exporter
ExecStart=/usr/local/bin/nginx-prometheus-exporter \
  -nginx.scrape-uri=http://localhost/stub_status

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl start nginx_exporter
sudo systemctl enable nginx_exporter
sudo systemctl status nginx_exporter

# Verify
curl http://localhost:9113/metrics | grep nginx
```

### Step 3.4: Create Custom Application Exporter

This exporter will provide application-specific metrics like measurements created, API performance, etc.

```bash
# Create exporter directory
cd /home/ubuntu/bmi-health-tracker
mkdir -p monitoring-exporter
cd monitoring-exporter

# Create package.json
cat > package.json <<'EOF'
{
  "name": "bmi-app-exporter",
  "version": "1.0.0",
  "main": "exporter.js",
  "scripts": {
    "start": "node exporter.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "prom-client": "^15.0.0",
    "pg": "^8.10.0"
  }
}
EOF

# Create exporter script
cat > exporter.js <<'EOF'
require('dotenv').config({ path: '../backend/.env' });
const express = require('express');
const promClient = require('prom-client');
const { Pool } = require('pg');

const app = express();
const PORT = 9091;

// Create a Registry
const register = new promClient.Registry();

// Add default metrics
promClient.collectDefaultMetrics({ register });

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// Custom metrics
const totalMeasurements = new promClient.Gauge({
  name: 'bmi_measurements_total',
  help: 'Total number of measurements in database',
  registers: [register]
});

const measurementsCreatedLast24h = new promClient.Gauge({
  name: 'bmi_measurements_created_24h',
  help: 'Number of measurements created in last 24 hours',
  registers: [register]
});

const averageBMI = new promClient.Gauge({
  name: 'bmi_average_value',
  help: 'Average BMI value of all measurements',
  registers: [register]
});

const bmiCategoryDistribution = new promClient.Gauge({
  name: 'bmi_category_count',
  help: 'Count of measurements by BMI category',
  labelNames: ['category'],
  registers: [register]
});

const databaseSize = new promClient.Gauge({
  name: 'bmi_database_size_bytes',
  help: 'Size of the bmidb database in bytes',
  registers: [register]
});

// Function to collect metrics
async function collectMetrics() {
  try {
    // Total measurements
    const totalResult = await pool.query('SELECT COUNT(*) FROM measurements');
    totalMeasurements.set(parseInt(totalResult.rows[0].count));

    // Measurements in last 24 hours
    const last24hResult = await pool.query(
      "SELECT COUNT(*) FROM measurements WHERE created_at > NOW() - INTERVAL '24 hours'"
    );
    measurementsCreatedLast24h.set(parseInt(last24hResult.rows[0].count));

    // Average BMI
    const avgResult = await pool.query('SELECT AVG(bmi) as avg_bmi FROM measurements');
    if (avgResult.rows[0].avg_bmi) {
      averageBMI.set(parseFloat(avgResult.rows[0].avg_bmi));
    }

    // BMI category distribution
    const categoryResult = await pool.query(
      'SELECT bmi_category, COUNT(*) FROM measurements GROUP BY bmi_category'
    );
    categoryResult.rows.forEach(row => {
      if (row.bmi_category) {
        bmiCategoryDistribution.set({ category: row.bmi_category }, parseInt(row.count));
      }
    });

    // Database size
    const sizeResult = await pool.query(
      "SELECT pg_database_size('bmidb') as size"
    );
    databaseSize.set(parseInt(sizeResult.rows[0].size));

  } catch (error) {
    console.error('Error collecting metrics:', error);
  }
}

// Collect metrics every 15 seconds
setInterval(collectMetrics, 15000);
collectMetrics(); // Initial collection

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (err) {
    res.status(500).end(err);
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`BMI App Exporter running on port ${PORT}`);
});
EOF

# Install dependencies
npm install

# Create PM2 ecosystem file
cat > ecosystem.config.js <<'EOF'
module.exports = {
  apps: [{
    name: 'bmi-app-exporter',
    script: './exporter.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '200M',
    env: {
      NODE_ENV: 'production'
    }
  }]
};
EOF

# Start with PM2
pm2 start ecosystem.config.js
pm2 save

# Verify
curl http://localhost:9091/metrics | grep bmi_
```

### Step 3.5: Install Promtail (Log Shipper)

```bash
# Download Promtail
cd /tmp
PROMTAIL_VERSION="2.9.3"
wget https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail

# Create user
sudo useradd --no-create-home --shell /bin/false promtail

# Create configuration
sudo mkdir -p /etc/promtail
sudo tee /etc/promtail/promtail-config.yml > /dev/null <<'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://MONITORING_SERVER_IP:3100/loki/api/v1/push

scrape_configs:
  # Backend application logs
  - job_name: bmi-backend
    static_configs:
      - targets:
          - localhost
        labels:
          job: bmi-backend
          server: app-server
          __path__: /home/ubuntu/bmi-health-tracker/backend/logs/*.log

  # Nginx access logs
  - job_name: nginx-access
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          log_type: access
          server: app-server
          __path__: /var/log/nginx/access.log

  # Nginx error logs
  - job_name: nginx-error
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          log_type: error
          server: app-server
          __path__: /var/log/nginx/error.log

  # System logs
  - job_name: syslog
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          server: app-server
          __path__: /var/log/syslog

  # PostgreSQL logs
  - job_name: postgresql
    static_configs:
      - targets:
          - localhost
        labels:
          job: postgresql
          server: app-server
          __path__: /var/log/postgresql/*.log
EOF

# Replace MONITORING_SERVER_IP
sudo vim /etc/promtail/promtail-config.yml

# Add promtail user to adm group to read logs
sudo usermod -a -G adm promtail

# Create systemd service
sudo tee /etc/systemd/system/promtail.service > /dev/null <<'EOF'
[Unit]
Description=Promtail Log Collector
After=network.target

[Service]
Type=simple
User=promtail
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yml

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl start promtail
sudo systemctl enable promtail
sudo systemctl status promtail

# Verify
sudo journalctl -u promtail -f
```

---

## Part 4: Set Up Dashboards

### Step 4.1: Configure Grafana Data Sources

```bash
# Access Grafana web UI: http://MONITORING_SERVER_IP:3000
# Login with admin/admin (change password)

# Add Prometheus data source:
1. Go to Configuration (gear icon) → Data Sources
2. Click "Add data source"
3. Select "Prometheus"
4. Configure:
   - Name: Prometheus
   - URL: http://localhost:9090
   - Access: Server (default)
5. Click "Save & Test"

# Add Loki data source:
1. Click "Add data source" again
2. Select "Loki"
3. Configure:
   - Name: Loki
   - URL: http://localhost:3100
   - Access: Server (default)
4. Click "Save & Test"
```

### Step 4.2: Import Pre-built Dashboards

I'll create comprehensive dashboard JSON files in the next step. For now, you can import community dashboards:

```bash
# In Grafana UI:
1. Click "+" → Import
2. Enter dashboard IDs:
   - 1860: Node Exporter Full
   - 9628: PostgreSQL Database
   - 12708: Nginx
3. Select "Prometheus" as data source
4. Click "Import"
```

### Step 4.3: Create Custom Application Dashboard

I'll provide complete dashboard JSON files in the configuration files section below.

---

## Part 5: Configure Alerting

### Step 5.1: Test Alert Rules

```bash
# On monitoring server, check if alerts are loaded
curl http://localhost:9090/api/v1/rules | jq

# View active alerts
curl http://localhost:9090/api/v1/alerts | jq
```

### Step 5.2: Configure Notification Channels

**For Email Notifications:**

```bash
# Edit AlertManager configuration
sudo vim /etc/alertmanager/alertmanager.yml

# Add SMTP configuration in global section:
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'your-email@gmail.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'  # Use App Password, not regular password

# Configure receiver:
receivers:
  - name: 'critical-alerts'
    email_configs:
      - to: 'devops@yourcompany.com'
        send_resolved: true
        headers:
          Subject: '[CRITICAL] BMI App Alert: {{ .GroupLabels.alertname }}'

# Restart AlertManager
sudo systemctl restart alertmanager
```

**For Slack Notifications:**

```bash
# Get Slack webhook URL:
# 1. Go to https://api.slack.com/apps
# 2. Create new app → Incoming Webhooks
# 3. Activate and add to workspace
# 4. Copy webhook URL

# Edit AlertManager config
sudo vim /etc/alertmanager/alertmanager.yml

# Add Slack configuration:
receivers:
  - name: 'critical-alerts'
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
        channel: '#alerts'
        title: '[CRITICAL] {{ .GroupLabels.alertname }}'
        text: |
          {{ range .Alerts }}
          *Alert:* {{ .Labels.alertname }}
          *Description:* {{ .Annotations.description }}
          *Instance:* {{ .Labels.instance }}
          {{ end }}

# Restart AlertManager
sudo systemctl restart alertmanager
```

### Step 5.3: Test Alerts

```bash
# Trigger a test alert by stopping a service
ssh ubuntu@APPLICATION_SERVER_IP
sudo systemctl stop node_exporter

# Wait 1-2 minutes, then check AlertManager
curl http://MONITORING_SERVER_IP:9093/api/v2/alerts | jq

# You should receive notification via configured channel

# Restart the service
sudo systemctl start node_exporter
```

---

## Part 6: Testing & Validation

### Step 6.1: Verify All Targets Are Up

```bash
# Access Prometheus UI
http://MONITORING_SERVER_IP:9090/targets

# All targets should show "UP" status:
✓ prometheus
✓ node_exporter (app server)
✓ node_exporter_monitoring (monitoring server)
✓ postgresql
✓ nginx
✓ bmi-backend

# If any target is DOWN:
1. Check if service is running on application server
2. Verify security group rules
3. Check service logs
```

### Step 6.2: Verify Metrics Collection

```bash
# Test queries in Prometheus
http://MONITORING_SERVER_IP:9090/graph

# Try these queries:
up
node_cpu_seconds_total
pg_up
nginx_up
bmi_measurements_total

# All should return data
```

### Step 6.3: Verify Log Collection

```bash
# Access Grafana → Explore
# Select "Loki" data source
# Query: {job="bmi-backend"}
# Should show backend logs

# Try other queries:
{job="nginx"}
{job="postgresql"}
{job="syslog"}
```

### Step 6.4: Create Test Traffic

```bash
# Generate some API traffic to test metrics
for i in {1..100}; do
  curl -X POST http://APPLICATION_SERVER_IP/api/measurements \
    -H "Content-Type: application/json" \
    -d '{"weightKg":70,"heightCm":175,"age":30,"sex":"male","activity":"moderate"}'
  sleep 1
done

# Check dashboards for updated metrics
```

---

## Part 7: Maintenance & Operations

### Step 7.1: Backup Configurations

```bash
# On monitoring server, create backup script
sudo tee /usr/local/bin/backup-monitoring.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/home/ubuntu/monitoring-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup Prometheus configuration
cp -r /etc/prometheus $BACKUP_DIR/prometheus_$DATE

# Backup Grafana dashboards
cp -r /var/lib/grafana $BACKUP_DIR/grafana_$DATE

# Backup Loki configuration
cp -r /etc/loki $BACKUP_DIR/loki_$DATE

# Backup AlertManager configuration
cp -r /etc/alertmanager $BACKUP_DIR/alertmanager_$DATE

echo "Backup completed: $BACKUP_DIR/*_$DATE"
EOF

sudo chmod +x /usr/local/bin/backup-monitoring.sh

# Run backup
/usr/local/bin/backup-monitoring.sh

# Schedule daily backups
crontab -e
# Add: 0 2 * * * /usr/local/bin/backup-monitoring.sh
```

### Step 7.2: Monitor Monitoring Server

```bash
# Set up alerts for monitoring server itself
# Add to /etc/prometheus/alert_rules.yml

- alert: MonitoringServerDown
  expr: up{job="node_exporter_monitoring"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Monitoring server is down"
    description: "Cannot scrape metrics from monitoring server"
```

### Step 7.3: Regular Maintenance Tasks

```bash
# Weekly: Check disk space
df -h
du -sh /var/lib/prometheus
du -sh /var/lib/loki
du -sh /var/lib/grafana

# Monthly: Clean old metrics/logs if needed
# Prometheus retention is set to 30 days (automatic)
# Loki retention is set to 31 days (automatic)

# Review dashboard performance
# Remove unused dashboards
# Optimize queries if slow
```

---

## Congratulations! 🎉

Your monitoring stack is now fully operational. You have:

✅ Prometheus collecting metrics from all components  
✅ Grafana dashboards for visualization  
✅ Loki aggregating logs from all sources  
✅ AlertManager sending notifications  
✅ Complete observability of your 3-tier application  

### Next Steps:

1. Customize dashboards for your specific needs
2. Fine-tune alert thresholds
3. Add more notification channels
4. Create runbooks for common alerts
5. Train your team on using the tools

---

## Quick Reference Commands

```bash
# Check all monitoring services
sudo systemctl status prometheus grafana-server loki alertmanager

# View Prometheus targets
curl http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Check AlertManager alerts
curl http://localhost:9093/api/v2/alerts | jq

# Tail Loki logs
curl -G -s  "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={job="bmi-backend"}' \
  --data-urlencode 'limit=10' | jq

# Restart all services
sudo systemctl restart prometheus grafana-server loki alertmanager
```

---

**Last Updated:** January 1, 2026  
**Monitoring Stack Version:** Prometheus 2.48.0, Grafana 10.x, Loki 2.9.3
