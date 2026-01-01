# BMI Health Tracker - Manual Monitoring Setup Guide

**Complete Step-by-Step Manual Installation Without Automation Scripts**

This guide walks you through setting up a complete monitoring infrastructure for the BMI Health Tracker application manually, without using automation scripts. Each step includes verification to ensure everything works before moving forward.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Create AWS EC2 Monitoring Server](#step-1-create-aws-ec2-monitoring-server)
3. [Step 2: Initial Server Setup](#step-2-initial-server-setup)
4. [Step 3: Install Prometheus](#step-3-install-prometheus)
5. [Step 4: Install Node Exporter (Monitoring Server)](#step-4-install-node-exporter-monitoring-server)
6. [Step 5: Install Grafana](#step-5-install-grafana)
7. [Step 6: Install Loki](#step-6-install-loki)
8. [Step 7: Install AlertManager](#step-7-install-alertmanager)
9. [Step 8: Configure Prometheus with All Targets](#step-8-configure-prometheus-with-all-targets)
10. [Step 9: Setup Application Server Exporters](#step-9-setup-application-server-exporters)
11. [Step 10: Configure Grafana Dashboards](#step-10-configure-grafana-dashboards)
12. [Step 11: Final Verification](#step-11-final-verification)
13. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- AWS Account with EC2 permissions
- SSH client (Terminal on Mac/Linux, PuTTY on Windows)
- Basic knowledge of Linux commands
- Text editor familiarity (nano or vim)
- Existing BMI application server with PostgreSQL and Nginx

---

## Step 1: Create AWS EC2 Monitoring Server

### 1.1 Launch EC2 Instance

1. **Log into AWS Console**
   - Navigate to EC2 Dashboard
   - Click "Launch Instance"

2. **Configure Instance Settings**

   | Setting | Value | Notes |
   |---------|-------|-------|
   | Name | `bmi-monitoring-server` | Or your preferred name |
   | AMI | Ubuntu Server 22.04 LTS (64-bit x86) | Free tier eligible |
   | Instance Type | `t3.medium` | 2 vCPU, 4 GB RAM (minimum) |
   | Key Pair | Create new or use existing | Download and save .pem file |

3. **Network Configuration**
   - **VPC**: Select your VPC (or default)
   - **Subnet**: Public subnet
   - **Auto-assign Public IP**: Enable

4. **Security Group Rules**
   
   Create new security group: `monitoring-server-sg`

   **Inbound Rules:**

   | Type | Protocol | Port | Source | Description |
   |------|----------|------|---------|-------------|
   | SSH | TCP | 22 | Your IP/32 | SSH access |
   | Custom TCP | TCP | 9090 | Your IP/32 | Prometheus UI |
   | Custom TCP | TCP | 3000 | Your IP/32 | Grafana UI |
   | Custom TCP | TCP | 3100 | VPC CIDR or 0.0.0.0/0 | Loki (log ingestion) |
   | Custom TCP | TCP | 9093 | Your IP/32 | AlertManager UI |
   | Custom TCP | TCP | 9100 | VPC CIDR | Node Exporter |

5. **Storage Configuration**
   - Root volume: 30 GB gp3 SSD
   - Delete on termination: Enabled (default)

6. **Launch Instance**
   - Review settings
   - Click "Launch Instance"
   - Wait for state: "running" (2-3 minutes)

### 1.2 Connect to Instance

1. **Set correct permissions on key file:**
   ```bash
   chmod 400 your-key.pem
   ```

2. **Connect via SSH:**
   ```bash
   ssh -i your-key.pem ubuntu@<PUBLIC_IP>
   ```

3. **Verify resources:**
   ```bash
   # Check RAM
   free -h
   # Output should show ~4GB total
   
   # Check CPU
   nproc
   # Output should show 2
   
   # Check disk space
   df -h
   # Output should show ~30GB on /
   ```

**Checkpoint:** Confirm you can SSH successfully and see expected resources.

---

## Step 2: Initial Server Setup

### 2.1 Update System Packages

```bash
sudo apt update
sudo apt upgrade -y
```

### 2.2 Install Essential Tools

```bash
sudo apt install -y curl wget git vim htop net-tools ufw
```

### 2.3 Configure Firewall (UFW)

```bash
# Enable UFW
sudo ufw enable

# Allow SSH (IMPORTANT: Do this first!)
sudo ufw allow 22/tcp

# Allow monitoring ports
sudo ufw allow 9090/tcp comment 'Prometheus'
sudo ufw allow 3000/tcp comment 'Grafana'
sudo ufw allow 3100/tcp comment 'Loki'
sudo ufw allow 9093/tcp comment 'AlertManager'
sudo ufw allow 9100/tcp comment 'Node Exporter'

# Check status
sudo ufw status
```

### 2.4 Set Timezone (Optional)

```bash
sudo timedatectl set-timezone UTC
timedatectl
```

### 2.5 Create Service Users

```bash
sudo useradd --no-create-home --shell /bin/false prometheus
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo useradd --no-create-home --shell /bin/false alertmanager
```

**Checkpoint:** Verify users created:
```bash
id prometheus
id node_exporter
id alertmanager
```

---

## Step 3: Install Prometheus

### 3.1 Download Prometheus

```bash
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-amd64.tar.gz
```

### 3.2 Extract and Install

```bash
tar -xzf prometheus-2.48.0.linux-amd64.tar.gz
cd prometheus-2.48.0.linux-amd64

# Copy binaries
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/

# Set ownership
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
```

### 3.3 Create Directories

```bash
sudo mkdir -p /etc/prometheus
sudo mkdir -p /var/lib/prometheus

sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
```

### 3.4 Copy Configuration Files

```bash
sudo cp -r consoles /etc/prometheus/
sudo cp -r console_libraries /etc/prometheus/

sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
```

### 3.5 Create Basic Prometheus Configuration

```bash
sudo nano /etc/prometheus/prometheus.yml
```

**Paste this configuration:**

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'bmi-monitoring'
    environment: 'production'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - localhost:9093

rule_files:
  - "alerts/*.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: 'monitoring-server'

  - job_name: 'node_exporter_monitoring'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'monitoring-server'
```

Save and exit (Ctrl+X, Y, Enter).

### 3.6 Set Permissions

```bash
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
```

### 3.7 Create Systemd Service

```bash
sudo nano /etc/systemd/system/prometheus.service
```

**Paste this content:**

```ini
[Unit]
Description=Prometheus Monitoring System
Documentation=https://prometheus.io/docs/introduction/overview/
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --storage.tsdb.retention.time=15d \
  --web.enable-lifecycle \
  --web.listen-address=0.0.0.0:9090

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Save and exit.

**Important:** The `--web.listen-address=0.0.0.0:9090` flag makes Prometheus listen on all network interfaces (not just localhost). This is **required** for accessing Prometheus via IP address or from browser.

### 3.8 Start Prometheus

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable and start
sudo systemctl enable prometheus
sudo systemctl start prometheus

# Check status
sudo systemctl status prometheus
```

### 3.9 Verify Prometheus

**Test from command line:**
```bash
curl http://localhost:9090/-/healthy
# Should return: Prometheus is Healthy.
```

**Test from browser:**
- Open: `http://<MONITORING_SERVER_PUBLIC_IP>:9090`
- You should see Prometheus UI
- Go to Status → Targets
- You should see "prometheus" target as UP

### 3.10 Verify Network Access

**Test network binding:**
```bash
# Check what interfaces Prometheus is listening on
sudo netstat -tulpn | grep prometheus
```

**Expected output:**
```
tcp6       0      0 :::9090                 :::*                    LISTEN      12345/prometheus
```

The `:::9090` or `0.0.0.0:9090` means it's listening on **all network interfaces**.

**Test from private IP:**
```bash
# Get your private IP
hostname -I

# Test with private IP (replace with your actual IP)
curl http://10.0.12.221:9090/-/healthy
# Should return: Prometheus is Healthy.
```

**If localhost works but IP address doesn't:**
- Service is only listening on 127.0.0.1
- Check that `--web.listen-address=0.0.0.0:9090` is in systemd service file
- Run: `sudo systemctl daemon-reload && sudo systemctl restart prometheus`

**Checkpoint:** Prometheus accessible via localhost, private IP, and public IP.

---

## Step 4: Install Node Exporter (Monitoring Server)

### 4.1 Download Node Exporter

```bash
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
```

### 4.2 Extract and Install

```bash
tar -xzf node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

### 4.3 Create Systemd Service

```bash
sudo nano /etc/systemd/system/node_exporter.service
```

**Paste this content:**

```ini
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
```

Save and exit.

### 4.4 Start Node Exporter

```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
```

### 4.5 Verify Node Exporter

```bash
curl http://localhost:9100/metrics | head -20
# Should show metrics like node_cpu_seconds_total, etc.
```

**Check in Prometheus:**
- Go to Prometheus UI: `http://<PUBLIC_IP>:9090`
- Status → Targets
- You should now see both "prometheus" and "node_exporter_monitoring" as UP

**Checkpoint:** Node Exporter metrics visible in Prometheus targets.

---

## Step 5: Install Grafana

### 5.1 Add Grafana Repository

```bash
sudo apt-get install -y software-properties-common
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo apt-get update
```

### 5.2 Install Grafana

```bash
sudo apt-get install -y grafana
```

### 5.3 Configure Grafana Network Access

**Edit Grafana configuration:**
```bash
sudo nano /etc/grafana/grafana.ini
```

**Find the `[server]` section and update (around line 30-40):**

```ini
[server]
# The IP address to bind to, empty will bind to all interfaces
http_addr = 0.0.0.0
http_port = 3000
```

Save and exit (Ctrl+X, Y, Enter).

**Note:** Setting `http_addr = 0.0.0.0` allows Grafana to be accessible from any IP address, not just localhost.

### 5.4 Start Grafana

```bash
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sudo systemctl status grafana-server
```

**Verify network binding:**
```bash
sudo netstat -tulpn | grep 3000
# Should show: :::3000 or 0.0.0.0:3000
```

### 5.5 Access Grafana

1. **Open browser:**
   ```
   http://<MONITORING_SERVER_PUBLIC_IP>:3000
   ```

2. **Login with defaults:**
   - Username: `admin`
   - Password: `admin`
   - You'll be prompted to change password (use a strong password)

### 5.6 Add Prometheus Data Source

1. **In Grafana UI:**
   - Click ☰ (menu) → Connections → Data Sources
   - Click "Add data source"
   - Select "Prometheus"

2. **Configure:**
   - Name: `Prometheus`
   - URL: `http://localhost:9090`
   - Access: `Server (default)`
   - Scrape interval: `15s`

3. **Save & Test:**
   - Click "Save & Test"
   - Should show: "Successfully queried the Prometheus API"

**Checkpoint:** Grafana accessible and Prometheus datasource connected.

---

## Step 6: Install Loki

### 6.1 Download Loki

```bash
cd /tmp
wget https://github.com/grafana/loki/releases/download/v2.9.3/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
sudo mv loki-linux-amd64 /usr/local/bin/loki
sudo chmod +x /usr/local/bin/loki
```

### 6.2 Create Loki User and Directories

```bash
sudo useradd --no-create-home --shell /bin/false loki
sudo mkdir -p /etc/loki
sudo mkdir -p /var/lib/loki/wal
sudo mkdir -p /var/lib/loki/chunks
sudo chown -R loki:loki /var/lib/loki
```

### 6.3 Create Loki Configuration

```bash
sudo nano /etc/loki/loki-config.yml
```

**Paste this configuration:**

```yaml
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
    - from: 2023-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /var/lib/loki/boltdb-shipper-active
    cache_location: /var/lib/loki/boltdb-shipper-cache
    cache_ttl: 24h
    shared_store: filesystem
  filesystem:
    directory: /var/lib/loki/chunks

compactor:
  working_directory: /var/lib/loki/boltdb-shipper-compactor
  shared_store: filesystem

limits_config:
  retention_period: 168h
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 16
  ingestion_burst_size_mb: 24

chunk_store_config:
  max_look_back_period: 168h

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h

ruler:
  storage:
    type: local
    local:
      directory: /var/lib/loki/rules
  rule_path: /var/lib/loki/rules-temp
  alertmanager_url: http://localhost:9093
  ring:
    kvstore:
      store: inmemory
  enable_api: true
```

Save and exit.

### 6.4 Set Permissions

```bash
sudo chown loki:loki /etc/loki/loki-config.yml
```

### 6.5 Create Systemd Service

```bash
sudo nano /etc/systemd/system/loki.service
```

**Paste this content:**

```ini
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
```

Save and exit.

### 6.6 Start Loki

```bash
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki
sudo systemctl status loki
```

### 6.7 Verify Loki

```bash
curl http://localhost:3100/ready
# Should return: ready

curl http://localhost:3100/metrics | head -20
# Should show Loki metrics
```

### 6.8 Add Loki to Grafana

1. **In Grafana UI:**
   - ☰ → Connections → Data Sources
   - Click "Add data source"
   - Select "Loki"

2. **Configure:**
   - Name: `Loki`
   - URL: `http://localhost:3100`
   - Access: `Server (default)`

3. **Save & Test:**
   - Click "Save & Test"
   - Should show: "Data source connected and labels found"

**Checkpoint:** Loki running and connected to Grafana.

---

## Step 7: Install AlertManager

### 7.1 Download AlertManager

```bash
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
```

### 7.2 Extract and Install

```bash
tar -xzf alertmanager-0.26.0.linux-amd64.tar.gz
cd alertmanager-0.26.0.linux-amd64

sudo cp alertmanager /usr/local/bin/
sudo cp amtool /usr/local/bin/

sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool
```

### 7.3 Create Directories

```bash
sudo mkdir -p /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager

sudo chown alertmanager:alertmanager /etc/alertmanager
sudo chown alertmanager:alertmanager /var/lib/alertmanager
```

### 7.4 Create AlertManager Configuration

```bash
sudo nano /etc/alertmanager/alertmanager.yml
```

**Paste this basic configuration:**

```yaml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'localhost:25'
  smtp_from: 'alertmanager@bmi-tracker.local'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical'
    - match:
        severity: warning
      receiver: 'warning'

receivers:
  - name: 'default'
    # Add your notification channels here (email, slack, etc.)
  
  - name: 'critical'
    # Critical alerts configuration
  
  - name: 'warning'
    # Warning alerts configuration

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'cluster', 'service']
```

Save and exit.

### 7.5 Set Permissions

```bash
sudo chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
```

### 7.6 Create Systemd Service

```bash
sudo nano /etc/systemd/system/alertmanager.service
```

**Paste this content:**

```ini
[Unit]
Description=AlertManager
After=network.target

[Service]
Type=simple
User=alertmanager
ExecStart=/usr/local/bin/alertmanager \
  --config.file=/etc/alertmanager/alertmanager.yml \
  --storage.path=/var/lib/alertmanager/ \
  --web.listen-address=0.0.0.0:9093 \
  --web.external-url=http://localhost:9093

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Save and exit.

**Note:** The `--web.listen-address=0.0.0.0:9093` flag makes AlertManager accessible from the network.

### 7.7 Start AlertManager

```bash
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
sudo systemctl status alertmanager
```

### 7.8 Verify AlertManager

```bash
curl http://localhost:9093/-/healthy
# Should return: OK
```

**Test in browser:**
- Open: `http://<MONITORING_SERVER_PUBLIC_IP>:9093`
- You should see AlertManager UI

**Verify network binding:**
```bash
sudo netstat -tulpn | grep 9093
# Should show: :::9093 or 0.0.0.0:9093
```

**Checkpoint:** AlertManager UI accessible and running on all interfaces.

---

## Step 8: Configure Prometheus with All Targets

### 8.1 Create Alert Rules Directory

```bash
sudo mkdir -p /etc/prometheus/alerts
sudo chown prometheus:prometheus /etc/prometheus/alerts
```

### 8.2 Create Basic Alert Rules

```bash
sudo nano /etc/prometheus/alerts/basic_alerts.yml
```

**Paste this content:**

```yaml
groups:
  - name: basic_alerts
    interval: 30s
    rules:
      - alert: InstanceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Instance {{ $labels.instance }} down"
          description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."

      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 10 minutes."

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85% for more than 10 minutes."

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk space is below 15% on root filesystem."
```

Save and exit.

### 8.3 Set Permissions

```bash
sudo chown prometheus:prometheus /etc/prometheus/alerts/basic_alerts.yml
```

### 8.4 Reload Prometheus

```bash
curl -X POST http://localhost:9090/-/reload
```

Or restart:
```bash
sudo systemctl restart prometheus
```

### 8.5 Verify Alerts

**In Prometheus UI:**
- Go to: `http://<PUBLIC_IP>:9090`
- Click "Alerts" in the top menu
- You should see your alert rules listed

**Checkpoint:** Alert rules visible in Prometheus.

---

## Step 9: Setup Application Server Exporters

Now we'll configure exporters on your existing application server that has the BMI application, PostgreSQL, and Nginx.

### 9.1 Connect to Application Server

```bash
ssh -i your-key.pem ubuntu@<APPLICATION_SERVER_IP>
```

### 9.2 Update and Install Dependencies

```bash
sudo apt update
sudo apt install -y curl wget unzip
```

### 9.3 Install Node Exporter on Application Server

**Download:**
```bash
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -xzf node_exporter-1.7.0.linux-amd64.tar.gz
```

**Install:**
```bash
sudo useradd --no-create-home --shell /bin/false node_exporter
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

**Create service:**
```bash
sudo nano /etc/systemd/system/node_exporter.service
```

Paste:
```ini
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
```

**Start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
```

**Verify:**
```bash
curl http://localhost:9100/metrics | head
```

### 9.4 Install PostgreSQL Exporter

**Download:**
```bash
cd /tmp
wget https://github.com/prometheus-community/postgres_exporter/releases/download/v0.15.0/postgres_exporter-0.15.0.linux-amd64.tar.gz
tar -xzf postgres_exporter-0.15.0.linux-amd64.tar.gz
```

**Install:**
```bash
sudo useradd --no-create-home --shell /bin/false postgres_exporter
sudo cp postgres_exporter-0.15.0.linux-amd64/postgres_exporter /usr/local/bin/
sudo chown postgres_exporter:postgres_exporter /usr/local/bin/postgres_exporter
```

**Create environment file:**
```bash
sudo nano /etc/default/postgres_exporter
```

Paste (update with your actual database credentials):
```
DATA_SOURCE_NAME=postgresql://bmi_user:YOUR_DB_PASSWORD@localhost:5432/bmi_tracker?sslmode=disable
```

**Set permissions:**
```bash
sudo chmod 600 /etc/default/postgres_exporter
sudo chown postgres_exporter:postgres_exporter /etc/default/postgres_exporter
```

**Create service:**
```bash
sudo nano /etc/systemd/system/postgres_exporter.service
```

Paste:
```ini
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
```

**Start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable postgres_exporter
sudo systemctl start postgres_exporter
sudo systemctl status postgres_exporter
```

**Verify:**
```bash
curl http://localhost:9187/metrics | head
```

### 9.5 Install Nginx Exporter

**Configure Nginx stub_status first:**
```bash
sudo nano /etc/nginx/sites-available/status
```

Paste:
```nginx
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
```

**Enable configuration:**
```bash
sudo ln -s /etc/nginx/sites-available/status /etc/nginx/sites-enabled/status
sudo nginx -t
sudo systemctl reload nginx
```

**Test stub_status:**
```bash
curl http://localhost:8080/stub_status
# Should show nginx statistics
```

**Download Nginx Exporter:**
```bash
cd /tmp
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
tar -xzf nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
```

**Install:**
```bash
sudo useradd --no-create-home --shell /bin/false nginx_exporter
sudo cp nginx-prometheus-exporter /usr/local/bin/
sudo chown nginx_exporter:nginx_exporter /usr/local/bin/nginx-prometheus-exporter
```

**Create service:**
```bash
sudo nano /etc/systemd/system/nginx_exporter.service
```

Paste:
```ini
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
```

**Start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable nginx_exporter
sudo systemctl start nginx_exporter
sudo systemctl status nginx_exporter
```

**Verify:**
```bash
curl http://localhost:9113/metrics | head
```

### 9.6 Install Promtail (Log Shipping)

**Download:**
```bash
cd /tmp
wget https://github.com/grafana/loki/releases/download/v2.9.3/promtail-linux-amd64.zip
unzip promtail-linux-amd64.zip
sudo mv promtail-linux-amd64 /usr/local/bin/promtail
sudo chmod +x /usr/local/bin/promtail
```

**Create directories:**
```bash
sudo mkdir -p /etc/promtail
sudo mkdir -p /var/lib/promtail/positions
```

**Create configuration:**
```bash
sudo nano /etc/promtail/promtail-config.yml
```

Paste (replace `MONITORING_SERVER_PRIVATE_IP` with actual IP):
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions/positions.yaml

clients:
  - url: http://MONITORING_SERVER_PRIVATE_IP:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          host: application-server
          __path__: /var/log/syslog

  - job_name: nginx_access
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: access
          host: application-server
          __path__: /var/log/nginx/access.log

  - job_name: nginx_error
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: error
          host: application-server
          __path__: /var/log/nginx/error.log

  - job_name: postgresql
    static_configs:
      - targets:
          - localhost
        labels:
          job: postgresql
          host: application-server
          __path__: /var/log/postgresql/*.log
```

**Create service:**
```bash
sudo nano /etc/systemd/system/promtail.service
```

Paste:
```ini
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
```

**Start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable promtail
sudo systemctl start promtail
sudo systemctl status promtail
```

**Verify:**
```bash
curl http://localhost:9080/ready
# Should return: ready
```

### 9.7 Configure Firewall on Application Server

Allow monitoring server to scrape metrics:

```bash
# Get monitoring server IP (use private IP if in same VPC)
MONITORING_IP="<MONITORING_SERVER_PRIVATE_IP>"

sudo ufw allow from $MONITORING_IP to any port 9100 comment 'Node Exporter'
sudo ufw allow from $MONITORING_IP to any port 9187 comment 'PostgreSQL Exporter'
sudo ufw allow from $MONITORING_IP to any port 9113 comment 'Nginx Exporter'
sudo ufw reload
```

### 9.8 Update Prometheus Configuration

**Back on monitoring server**, update Prometheus to scrape application server:

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Add these scrape configs (replace `APPLICATION_SERVER_IP` with actual private IP):

```yaml
  - job_name: 'node_exporter_app'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9100']
        labels:
          instance: 'application-server'

  - job_name: 'postgres_exporter'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9187']
        labels:
          instance: 'application-server'

  - job_name: 'nginx_exporter'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9113']
        labels:
          instance: 'application-server'
```

**Reload Prometheus:**
```bash
curl -X POST http://localhost:9090/-/reload
```

Or:
```bash
sudo systemctl restart prometheus
```

### 9.9 Verify Application Server Targets

**In Prometheus UI:**
- Go to: `http://<MONITORING_SERVER_IP>:9090`
- Click Status → Targets
- You should see all exporters (node, postgres, nginx) showing UP status

**In Grafana:**
- Go to Explore
- Select Loki datasource
- Query: `{job="nginx"}` or `{job="syslog"}`
- You should see logs from application server

**Checkpoint:** All exporters showing UP in Prometheus, logs visible in Loki.

---

## Step 10: Install BMI Custom Application Exporter

This custom exporter collects application-specific business metrics from your BMI Health Tracker.

### 10.1 Install Node.js (if not already installed)

**On application server:**

```bash
# Check if Node.js is installed
node --version

# If not installed, install Node.js 20.x
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt install -y nodejs

# Verify installation
node --version
npm --version
```

### 10.2 Install PM2 Process Manager

```bash
sudo npm install -g pm2

# Verify installation
pm2 --version
```

### 10.3 Create Exporter Directory

```bash
sudo mkdir -p /opt/bmi-exporter
sudo chown ubuntu:ubuntu /opt/bmi-exporter
cd /opt/bmi-exporter
```

### 10.4 Create package.json

```bash
nano package.json
```

**Paste this content:**

```json
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
```

Save and exit.

### 10.5 Create Exporter Application

```bash
nano exporter.js
```

**Paste this complete code:**

```javascript
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

// Add default metrics (Node.js process metrics)
client.collectDefaultMetrics({ register });

// Custom BMI Application Metrics
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

// Metrics collection function
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
    
    // Reset all categories to 0 first
    bmiByCategory.set({ category: 'underweight' }, 0);
    bmiByCategory.set({ category: 'normal' }, 0);
    bmiByCategory.set({ category: 'overweight' }, 0);
    bmiByCategory.set({ category: 'obese' }, 0);
    
    // Set actual values
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

    // App health (1 = healthy)
    appHealthy.set(1);
    
    console.log(`[${new Date().toISOString()}] Metrics collected successfully`);
  } catch (error) {
    console.error('Error collecting metrics:', error);
    appHealthy.set(0);
  }
}

// Collect metrics every 15 seconds
setInterval(collectMetrics, 15000);

// Initial collection on startup
collectMetrics();

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', register.contentType);
    res.end(await register.metrics());
  } catch (error) {
    res.status(500).end(error.message);
  }
});

// Health endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    dbConnections: {
      total: pool.totalCount,
      idle: pool.idleCount,
      waiting: pool.waitingCount
    }
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.send(`
    <h1>BMI Custom Application Exporter</h1>
    <ul>
      <li><a href="/metrics">Metrics</a></li>
      <li><a href="/health">Health</a></li>
    </ul>
  `);
});

// Start server
app.listen(PORT, () => {
  console.log(`BMI Custom Exporter running on port ${PORT}`);
  console.log(`Metrics available at: http://localhost:${PORT}/metrics`);
  console.log(`Health check at: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing connections...');
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, closing connections...');
  await pool.end();
  process.exit(0);
});
```

Save and exit.

### 10.6 Create PM2 Ecosystem Configuration

```bash
nano ecosystem.config.js
```

**Paste this content:**

```javascript
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
    error_file: '/var/log/pm2/bmi-exporter-error.log',
    out_file: '/var/log/pm2/bmi-exporter-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    autorestart: true,
    watch: false
  }]
};
```

Save and exit.

### 10.7 Create Environment Configuration

```bash
nano .env
```

**Paste this content (update with your actual database credentials):**

```bash
DB_USER=bmi_user
DB_PASSWORD=your_database_password_here
DB_NAME=bmi_tracker
DB_HOST=localhost
DB_PORT=5432
EXPORTER_PORT=9091
```

Save and exit.

**Set secure permissions:**
```bash
chmod 600 .env
```

### 10.8 Install Dependencies

```bash
npm install --production
```

**Expected output:**
```
added 50+ packages
```

### 10.9 Create PM2 Log Directory

```bash
sudo mkdir -p /var/log/pm2
sudo chown ubuntu:ubuntu /var/log/pm2
```

### 10.10 Start Exporter with PM2

```bash
# Start the exporter
pm2 start ecosystem.config.js

# Check status
pm2 status

# View logs
pm2 logs bmi-exporter --lines 20
```

**Expected PM2 status output:**
```
┌─────┬──────────────┬─────────┬─────────┬─────────┬──────────┐
│ id  │ name         │ mode    │ ↺       │ status  │ cpu      │
├─────┼──────────────┼─────────┼─────────┼─────────┼──────────┤
│ 0   │ bmi-exporter │ fork    │ 0       │ online  │ 0%       │
└─────┴──────────────┴─────────┴─────────┴─────────┴──────────┘
```

### 10.11 Save PM2 Configuration

```bash
# Save PM2 process list
pm2 save

# Generate startup script
pm2 startup

# Follow the command it outputs (copy and run it)
# It will look like:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
```

### 10.12 Test Exporter Endpoints

**Test metrics endpoint:**
```bash
curl http://localhost:9091/metrics
```

**Expected output (sample):**
```
# HELP bmi_measurements_total Total number of BMI measurements in database
# TYPE bmi_measurements_total gauge
bmi_measurements_total 150

# HELP bmi_measurements_created_24h Number of BMI measurements created in last 24 hours
# TYPE bmi_measurements_created_24h gauge
bmi_measurements_created_24h 25

# HELP bmi_average_value Average BMI value across all measurements
# TYPE bmi_average_value gauge
bmi_average_value 24.5

# HELP bmi_category_count Count of measurements by BMI category
# TYPE bmi_category_count gauge
bmi_category_count{category="underweight"} 10
bmi_category_count{category="normal"} 80
bmi_category_count{category="overweight"} 45
bmi_category_count{category="obese"} 15

# HELP bmi_app_healthy Application health status
# TYPE bmi_app_healthy gauge
bmi_app_healthy 1
```

**Test health endpoint:**
```bash
curl http://localhost:9091/health
```

**Expected output:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-01T12:34:56.789Z",
  "uptime": 123.456,
  "dbConnections": {
    "total": 1,
    "idle": 1,
    "waiting": 0
  }
}
```

**Test web interface:**
```bash
curl http://localhost:9091/
```

### 10.13 Configure Firewall

```bash
# Allow monitoring server to access exporter
MONITORING_IP="<MONITORING_SERVER_PRIVATE_IP>"
sudo ufw allow from $MONITORING_IP to any port 9091 comment 'BMI Custom Exporter'
sudo ufw reload
sudo ufw status
```

### 10.14 Add to Prometheus Configuration

**On monitoring server:**

```bash
sudo nano /etc/prometheus/prometheus.yml
```

**Add this scrape config (replace APPLICATION_SERVER_IP with actual private IP):**

```yaml
  - job_name: 'bmi_custom_exporter'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9091']
        labels:
          instance: 'application-server'
          app: 'bmi-tracker'
```

**Full example of scrape_configs section:**
```yaml
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          instance: 'monitoring-server'

  - job_name: 'node_exporter_monitoring'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          instance: 'monitoring-server'

  - job_name: 'node_exporter_app'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9100']
        labels:
          instance: 'application-server'

  - job_name: 'postgres_exporter'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9187']
        labels:
          instance: 'application-server'

  - job_name: 'nginx_exporter'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9113']
        labels:
          instance: 'application-server'

  - job_name: 'bmi_custom_exporter'
    static_configs:
      - targets: ['APPLICATION_SERVER_IP:9091']
        labels:
          instance: 'application-server'
          app: 'bmi-tracker'
```

Save and exit.

### 10.15 Reload Prometheus

```bash
curl -X POST http://localhost:9090/-/reload
```

Or restart:
```bash
sudo systemctl restart prometheus
```

### 10.16 Verify in Prometheus

**From monitoring server, test connectivity:**
```bash
curl http://<APPLICATION_SERVER_IP>:9091/metrics | head -30
```

**In Prometheus UI:**
1. Open: `http://<MONITORING_SERVER_IP>:9090`
2. Go to Status → Targets
3. Find "bmi_custom_exporter" job
4. Status should be **UP** (green)
5. Last Scrape should show recent time

**Test queries in Prometheus:**
1. Go to Graph tab
2. Try these queries:
   ```
   bmi_measurements_total
   bmi_average_value
   bmi_category_count
   bmi_app_healthy
   ```
3. Click "Execute" - you should see current values

### 10.17 Verify Metrics in Grafana

**In Grafana:**
1. Go to Explore (compass icon)
2. Select "Prometheus" datasource
3. Query: `bmi_measurements_total`
4. Click "Run query"
5. You should see the metric value

**Create a quick dashboard panel:**
1. Go to Dashboards → New Dashboard
2. Add visualization
3. Query: `bmi_category_count`
4. Visualization: Bar chart
5. You should see distribution by category

### 10.18 Monitor Exporter Logs

```bash
# View real-time logs
pm2 logs bmi-exporter

# View last 50 lines
pm2 logs bmi-exporter --lines 50

# View only errors
pm2 logs bmi-exporter --err
```

**Healthy logs should show:**
```
[2026-01-01T12:34:56.789Z] Metrics collected successfully
[2026-01-01T12:35:11.790Z] Metrics collected successfully
```

### 10.19 Troubleshooting BMI Exporter

**If exporter not starting:**
```bash
# Check PM2 status
pm2 status

# View detailed logs
pm2 logs bmi-exporter --lines 100

# Check for errors
pm2 logs bmi-exporter --err --lines 50

# Restart exporter
pm2 restart bmi-exporter
```

**If database connection fails:**
```bash
# Verify .env file
cat /opt/bmi-exporter/.env

# Test database connection manually
psql -U bmi_user -d bmi_tracker -h localhost -c "SELECT COUNT(*) FROM measurements;"

# Check PostgreSQL is running
sudo systemctl status postgresql
```

**If Prometheus can't scrape:**
```bash
# From monitoring server, test connectivity
telnet <APPLICATION_SERVER_IP> 9091

# Check firewall on application server
sudo ufw status | grep 9091

# Check if exporter is listening
sudo netstat -tulpn | grep 9091
```

**If metrics show 0 or NaN:**
```bash
# Verify measurements table exists and has data
psql -U bmi_user -d bmi_tracker -c "SELECT COUNT(*) FROM measurements;"

# Check exporter logs for SQL errors
pm2 logs bmi-exporter --err

# Manually test queries in database
psql -U bmi_user -d bmi_tracker -c "SELECT AVG(bmi) FROM measurements;"
```

**Common Issues:**

1. **Port 9091 already in use:**
   ```bash
   # Check what's using the port
   sudo lsof -i :9091
   
   # Change port in .env file
   nano /opt/bmi-exporter/.env
   # Set EXPORTER_PORT=9092
   
   # Restart exporter
   pm2 restart bmi-exporter
   ```

2. **High memory usage:**
   ```bash
   # Check memory
pm2 list
   
   # Reduce max_memory_restart in ecosystem.config.js
   nano /opt/bmi-exporter/ecosystem.config.js
   # Change: max_memory_restart: '150M'
   
   # Restart
   pm2 restart bmi-exporter
   ```

3. **Connection pool exhausted:**
   ```bash
   # Check current connections
   curl http://localhost:9091/health
   
   # Restart to reset pool
   pm2 restart bmi-exporter
   ```

### 10.20 Test BMI Exporter Metrics

**Create test data to verify metrics:**

```bash
# Connect to database
psql -U bmi_user -d bmi_tracker

# Insert test measurements
INSERT INTO measurements (weight_kg, height_cm, bmi) VALUES 
(70, 175, 22.9),
(85, 180, 26.2),
(60, 165, 22.0);

# Exit psql
\q
```

**Wait 15 seconds (collection interval), then check metrics:**
```bash
curl http://localhost:9091/metrics | grep bmi_measurements_total
```

The count should have increased by 3.

**Verify in Prometheus:**
1. Go to Prometheus UI Graph tab
2. Query: `bmi_measurements_total`
3. Click Execute
4. You should see the increased count

**Checkpoint:** 
- ✅ BMI Custom Exporter running (pm2 status shows "online")
- ✅ Metrics endpoint accessible (curl returns metrics)
- ✅ Health endpoint returns OK
- ✅ Prometheus showing target as UP
- ✅ Metrics queryable in Prometheus and Grafana
- ✅ Metrics update every 15 seconds

---

## Step 11: Configure Grafana Dashboards

### 10.1 Import System Metrics Dashboard

1. **In Grafana UI:**
   - Click ☰ → Dashboards
   - Click "New" → "Import"

2. **Import Node Exporter Dashboard:**
   - Dashboard ID: `1860` (popular Node Exporter dashboard)
   - Click "Load"
   - Select Prometheus datasource
   - Click "Import"

3. **Verify:**
   - You should see system metrics for both monitoring and application servers
   - CPU, Memory, Disk, Network graphs should be populated

### 10.2 Create Custom BMI Application Dashboard

1. **Create New Dashboard:**
   - ☰ → Dashboards → New Dashboard
   - Click "Add visualization"

2. **Add PostgreSQL Metrics Panel:**
   - Select Prometheus datasource
   - Query: `pg_stat_database_numbackends{datname="bmi_tracker"}`
   - Panel title: "Database Connections"
   - Save panel

3. **Add Nginx Metrics Panel:**
   - Add new panel
   - Query: `rate(nginx_http_requests_total[5m])`
   - Panel title: "Nginx Requests/sec"
   - Save panel

4. **Save Dashboard:**
   - Click Save (disk icon)
   - Name: "BMI Application Metrics"
   - Save

### 10.3 Create Log Dashboard

1. **Create New Dashboard:**
   - ☰ → Dashboards → New Dashboard
   - Add visualization

2. **Add Logs Panel:**
   - Select Loki datasource
   - Switch to "Code" mode
   - Query: `{job=~"nginx|syslog|postgresql"}`
   - Visualization: "Logs"
   - Save panel

3. **Add Log Rate Panel:**
   - Add new panel
   - Query: `rate({job=~"nginx|syslog"}[5m])`
   - Visualization: "Time series"
   - Panel title: "Log Rate"
   - Save panel

4. **Save Dashboard:**
   - Name: "Application Logs"
   - Save

**Checkpoint:** Dashboards showing data from all sources.

---

## Step 12: Final Verification

### 12.1 Check All Services Status

**On Monitoring Server:**
```bash
# Check all services
sudo systemctl status prometheus
sudo systemctl status node_exporter
sudo systemctl status grafana-server
sudo systemctl status loki
sudo systemctl status alertmanager

# All should show: active (running)
```

**On Application Server:**
```bash
# Check all exporters
sudo systemctl status node_exporter
sudo systemctl status postgres_exporter
sudo systemctl status nginx_exporter
sudo systemctl status promtail

# All should show: active (running)
```

**On Application Server:**
```bash
# Check all exporters and BMI exporter
sudo systemctl status node_exporter
sudo systemctl status postgres_exporter
sudo systemctl status nginx_exporter
sudo systemctl status promtail
pm2 status bmi-exporter

# All should show: active (running) or online
```

### 12.2 Verify Metrics Collection

```bash
# On monitoring server - query Prometheus
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq

# Should show all targets with value: 1 (UP)
```

### 12.3 Access All UIs

Verify you can access:

1. **Prometheus:** `http://<MONITORING_SERVER_IP>:9090`
   - Status → Targets: All should be UP

2. **Grafana:** `http://<MONITORING_SERVER_IP>:3000`
   - Login as admin
   - Check dashboards have data

3. **AlertManager:** `http://<MONITORING_SERVER_IP>:9093`
   - Should show alerts (if any)

4. **Loki (via Grafana):**
   - Grafana → Explore → Loki
   - Query: `{job="nginx"}`
   - Should show logs

### 12.4 Generate Test Load

**On application server:**
```bash
# Generate some traffic
for i in {1..100}; do
  curl -s http://localhost > /dev/null
done
```

**Check in Grafana:**
- BMI Application Metrics dashboard
- You should see spike in Nginx requests

### 12.5 Test Alerting (Optional)

**Simulate high CPU:**
```bash
# On application server
stress --cpu 2 --timeout 600
```

**Check AlertManager:**
- After ~10 minutes, you should see "HighCPUUsage" alert
- Go to: `http://<MONITORING_IP>:9093`

---

## Step 13: Troubleshooting

### Services Only Accessible on Localhost

**Symptoms:**
- `curl http://localhost:9090` works ✅
- `curl http://<PRIVATE_IP>:9090` fails ❌
- Browser access via public IP fails ❌

**Cause:** Service is only listening on 127.0.0.1 (localhost), not on all network interfaces.

**Solution for Prometheus:**
```bash
sudo nano /etc/systemd/system/prometheus.service
```

Ensure this line is present in `ExecStart`:
```
--web.listen-address=0.0.0.0:9090
```

Then restart:
```bash
sudo systemctl daemon-reload
sudo systemctl restart prometheus
sudo netstat -tulpn | grep 9090
# Should show: :::9090 (all interfaces)
```

**Solution for Grafana:**
```bash
sudo nano /etc/grafana/grafana.ini
```

Find `[server]` section, ensure:
```ini
http_addr = 0.0.0.0
```

```bash
sudo systemctl restart grafana-server
sudo netstat -tulpn | grep 3000
```

**Solution for AlertManager:**
```bash
sudo nano /etc/systemd/system/alertmanager.service
```

Ensure in `ExecStart`:
```
--web.listen-address=0.0.0.0:9093
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart alertmanager
sudo netstat -tulpn | grep 9093
```

**Verify all services:**
```bash
# Check what each service is listening on
sudo netstat -tulpn | grep -E '9090|3000|3100|9093'
```

**Expected output:**
```
tcp6       0      0 :::9090                 :::*                    LISTEN      1234/prometheus
tcp        0      0 0.0.0.0:3000            0.0.0.0:*               LISTEN      5678/grafana-server
tcp6       0      0 :::3100                 :::*                    LISTEN      9012/loki
tcp6       0      0 :::9093                 :::*                    LISTEN      3456/alertmanager
```

**Also check:**
1. **AWS Security Group:** Verify inbound rules allow your IP to access these ports
2. **UFW Firewall:** `sudo ufw status` - ensure ports are allowed
3. **Service logs:** `sudo journalctl -u prometheus -n 50` for binding errors

---

### Prometheus Not Starting



**Check logs:**
```bash
sudo journalctl -u prometheus -f
```

**Common issues:**
- Configuration syntax error: `promtool check config /etc/prometheus/prometheus.yml`
- Permission issues: `sudo chown -R prometheus:prometheus /etc/prometheus`
- Port already in use: `sudo netstat -tulpn | grep 9090`

### Exporter Not Reachable from Prometheus

**Test connectivity:**
```bash
# From monitoring server
curl http://<APP_SERVER_IP>:9100/metrics

# If fails, check:
# 1. Firewall rules on app server
sudo ufw status

# 2. Service running
sudo systemctl status node_exporter

# 3. Network connectivity
ping <APP_SERVER_IP>
telnet <APP_SERVER_IP> 9100
```

### Grafana Not Showing Data

**Check datasource:**
- Grafana → Configuration → Data Sources
- Test connection to Prometheus and Loki
- Check URLs are correct (use `localhost` for local services)

**Check query:**
- Go to Explore
- Run simple query: `up`
- Should return metrics

### Loki Not Receiving Logs

**Check Promtail:**
```bash
# On application server
sudo systemctl status promtail
sudo journalctl -u promtail -f

# Check targets
curl http://localhost:9080/targets
```

**Check connectivity:**
```bash
# From application server to monitoring server
curl http://<MONITORING_IP>:3100/ready
```

**Check firewall:**
```bash
# On monitoring server
sudo ufw status | grep 3100
```

### High Memory Usage on Monitoring Server

**Reduce retention:**
```bash
sudo nano /etc/prometheus/prometheus.yml
# Change: --storage.tsdb.retention.time=7d

sudo systemctl restart prometheus
```

**Reduce Loki retention:**
```bash
sudo nano /etc/loki/loki-config.yml
# Change: retention_period: 72h

sudo systemctl restart loki
```

### Can't Access Web UIs

**Check service is running:**
```bash
sudo systemctl status grafana-server
```

**Check firewall:**
```bash
sudo ufw status | grep 3000
```

**Check security group:**
- AWS Console → EC2 → Security Groups
- Ensure port 3000 is open to your IP

**Check listening ports:**
```bash
sudo netstat -tulpn | grep :3000
```

---

## Summary of Services and Ports

### Monitoring Server

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Prometheus | 9090 | http://IP:9090 | Metrics collection |
| Grafana | 3000 | http://IP:3000 | Visualization |
| Loki | 3100 | http://IP:3100 | Log aggregation |
| AlertManager | 9093 | http://IP:9093 | Alert management |
| Node Exporter | 9100 | http://localhost:9100/metrics | System metrics |

### Application Server

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| Node Exporter | 9100 | http://localhost:9100/metrics | System metrics |
| PostgreSQL Exporter | 9187 | http://localhost:9187/metrics | Database metrics |
| Nginx Exporter | 9113 | http://localhost:9113/metrics | Web server metrics |
| Promtail | 9080 | http://localhost:9080/ready | Log shipping |
| BMI Custom Exporter | 9091 | http://localhost:9091/metrics | Application metrics |

---

## Next Steps

1. **Configure Email Alerts:**
   - Update AlertManager configuration with SMTP settings
   - Test alert notifications

2. **Setup Backup:**
   - Backup Grafana database: `/var/lib/grafana`
   - Backup Prometheus data: `/var/lib/prometheus`
   - Backup configurations: `/etc/prometheus`, `/etc/grafana`

3. **Secure Access:**
   - Configure Nginx reverse proxy for Grafana
   - Add SSL/TLS certificates
   - Implement authentication for Prometheus

4. **Optimize Performance:**
   - Adjust scrape intervals based on needs
   - Configure recording rules for complex queries
   - Set appropriate retention periods

5. **Create More Dashboards:**
   - Database performance metrics
   - Application-specific metrics
   - Business metrics (user signups, BMI calculations, etc.)

---

## Useful Commands

```bash
# Restart all monitoring services
sudo systemctl restart prometheus grafana-server loki alertmanager node_exporter

# Check all service status
sudo systemctl status prometheus grafana-server loki alertmanager node_exporter

# View logs
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f
sudo journalctl -u loki -f

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload

# Query Prometheus
curl 'http://localhost:9090/api/v1/query?query=up'

# Check Loki
curl http://localhost:3100/ready

# Test alert rules
promtool check rules /etc/prometheus/alerts/*.yml

# Test Prometheus config
promtool check config /etc/prometheus/prometheus.yml

# PM2 commands for BMI exporter
pm2 list
pm2 status bmi-exporter
pm2 logs bmi-exporter
pm2 restart bmi-exporter
pm2 stop bmi-exporter
pm2 start bmi-exporter
```

---

## Maintenance

### Daily
- Check Grafana dashboards for anomalies
- Review active alerts in AlertManager

### Weekly
- Review disk space usage on monitoring server
- Check all targets are UP in Prometheus
- Verify log shipping is working

### Monthly
- Review and update alert rules
- Check for new versions of exporters
- Optimize dashboard queries
- Review retention policies

---

**Congratulations!** You have successfully set up a complete monitoring infrastructure for your BMI Health Tracker application.

---

## 🧑‍💻 Author
**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)

---
