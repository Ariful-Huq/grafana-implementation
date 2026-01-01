# Basic Web Server Monitoring Setup Guide

**Monitor Any Ubuntu Web Server with Your Existing Monitoring Infrastructure**

This guide shows you how to add monitoring for a new Ubuntu web server to your existing monitoring system at `http://44.244.230.26:3000`.

You'll be able to monitor:
- 💻 **CPU Usage** - Processor utilization
- 🧠 **Memory/RAM** - Memory consumption
- 💾 **Disk Space** - Storage usage
- 🌐 **Network Traffic** - Bandwidth usage
- 🔧 **System Services** - Service status

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Create Ubuntu Web Server](#step-1-create-ubuntu-web-server)
3. [Step 2: Install Node Exporter](#step-2-install-node-exporter)
4. [Step 3: Configure Firewall](#step-3-configure-firewall)
5. [Step 4: Add Server to Prometheus](#step-4-add-server-to-prometheus)
6. [Step 5: View Metrics in Grafana](#step-5-view-metrics-in-grafana)
7. [Step 6: Create Custom Dashboard](#step-6-create-custom-dashboard)
8. [Optional: Monitor Specific Services](#optional-monitor-specific-services)

---

## Prerequisites

✅ **Monitoring Server Running:**
- Prometheus: `http://44.244.230.26:9090`
- Grafana: `http://44.244.230.26:3000`

✅ **Access Requirements:**
- AWS Account
- SSH access to servers
- Monitoring server private IP: `10.0.12.221`

---

## Step 1: Create Ubuntu Web Server

### 1.1 Launch EC2 Instance

1. **AWS Console → EC2 → Launch Instance**

2. **Configuration:**
   | Setting | Value |
   |---------|-------|
   | Name | `PROD01` |
   | AMI | Ubuntu Server 22.04 LTS |
   | Instance Type | t2.micro or t3.small |
   | Key Pair | Same as monitoring server (or new) |
   | VPC | **Same VPC as monitoring server** |
   | Subnet | Any subnet in same VPC |
   | Auto-assign Public IP | Enable |

3. **Security Group:**
   
   Create: `web-server-sg`

   | Type | Protocol | Port | Source | Description |
   |------|----------|------|--------|-------------|
   | SSH | TCP | 22 | Your IP/32 | SSH access |
   | HTTP | TCP | 80 | 0.0.0.0/0 | Web traffic |
   | HTTPS | TCP | 443 | 0.0.0.0/0 | Secure web traffic |
   | Custom TCP | TCP | 9100 | 10.0.12.221/32 | Node Exporter (monitoring server only) |

   **Important:** Port 9100 should ONLY allow the monitoring server's **private IP** (10.0.12.221), not 0.0.0.0/0!

4. **Storage:** 8-30 GB gp3 SSD

5. **Launch Instance**

### 1.2 Connect to Server

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@<WEB_SERVER_PUBLIC_IP>
```

### 1.3 Update System

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget vim htop
```

**Checkpoint:** ✅ Connected to web server successfully

---

## Step 2: Install Node Exporter

Node Exporter collects system metrics (CPU, RAM, disk, network) and exposes them for Prometheus.

### 2.1 Create Service User

```bash
sudo useradd --no-create-home --shell /bin/false node_exporter
```

### 2.2 Download and Install

```bash
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar -xzf node_exporter-1.7.0.linux-amd64.tar.gz
sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
```

### 2.3 Create Systemd Service

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

Save and exit (Ctrl+X, Y, Enter).

### 2.4 Start Node Exporter

```bash
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter
```

**Expected output:**
```
● node_exporter.service - Node Exporter
   Active: active (running)
```

### 2.5 Test Node Exporter

```bash
curl http://localhost:9100/metrics | head -30
```

**Expected output (sample):**
```
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 1234.56
node_cpu_seconds_total{cpu="0",mode="system"} 78.90

# HELP node_memory_MemTotal_bytes Memory information field MemTotal_bytes.
# TYPE node_memory_MemTotal_bytes gauge
node_memory_MemTotal_bytes 1.073741824e+09
```

**Checkpoint:** ✅ Node Exporter running and exposing metrics on port 9100

---

## Step 3: Configure Firewall

### 3.1 Get Server IPs

```bash
# Get your web server's private IP
hostname -I
# Example output: 10.0.8.145

# Note: Monitoring server private IP: 10.0.12.221
```

### 3.2 Configure UFW Firewall

```bash
# Enable UFW
sudo ufw enable

# Allow SSH (CRITICAL - do this first!)
sudo ufw allow 22/tcp

# Allow web traffic
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow Node Exporter ONLY from monitoring server
sudo ufw allow from 10.0.12.221 to any port 9100 comment 'Node Exporter from Monitoring'

# Check rules
sudo ufw status numbered
```

**Expected output:**
```
Status: active

     To                         Action      From
     --                         ------      ----
[ 1] 22/tcp                     ALLOW IN    Anywhere
[ 2] 80/tcp                     ALLOW IN    Anywhere
[ 3] 443/tcp                    ALLOW IN    Anywhere
[ 4] 9100                       ALLOW IN    10.0.12.221              # Node Exporter from Monitoring
```

**Checkpoint:** ✅ Firewall configured - Node Exporter accessible only from monitoring server

---

## Step 4: Add Server to Prometheus

Now configure Prometheus (on monitoring server) to scrape metrics from this web server.

### 4.1 SSH to Monitoring Server

```bash
# From your local machine
ssh -i your-key.pem ubuntu@44.244.230.26
```

### 4.2 Edit Prometheus Configuration

```bash
sudo nano /etc/prometheus/prometheus.yml
```

### 4.3 Add New Scrape Target

**Scroll to the `scrape_configs:` section and add:**

```yaml
  - job_name: 'web_server_01'
    static_configs:
      - targets: ['10.0.8.145:9100']  # Replace with YOUR web server's PRIVATE IP
        labels:
          instance: 'PROD01'
          environment: 'production'
          role: 'web'
```

**Full example (showing context):**

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

  # NEW WEB SERVER - ADD THIS
  - job_name: 'web_server_01'
    static_configs:
      - targets: ['10.0.8.145:9100']  # Your web server's private IP
        labels:
          instance: 'PROD01'
          environment: 'production'
          role: 'web'
```

**Important:** Use the **PRIVATE IP** of your web server (10.0.x.x), not the public IP!

Save and exit (Ctrl+X, Y, Enter).

### 4.4 Validate Configuration

```bash
promtool check config /etc/prometheus/prometheus.yml
```

**Expected output:**
```
Checking /etc/prometheus/prometheus.yml
  SUCCESS: 1 rule files found
```

### 4.5 Reload Prometheus

```bash
curl -X POST http://localhost:9090/-/reload
```

**Alternative (if reload doesn't work):**
```bash
sudo systemctl restart prometheus
sudo systemctl status prometheus
```

### 4.6 Verify Target in Prometheus

**Option 1: Command line test from monitoring server:**
```bash
curl http://10.0.8.145:9100/metrics | head -10
```

If you see metrics, connectivity is working!

**Option 2: Prometheus Web UI:**

1. Open: `http://44.244.230.26:9090`
2. Click **Status → Targets**
3. Look for `web_server_01` job
4. State should be **UP** (green)
5. Last Scrape should show recent time

**If target shows DOWN:**
- Check private IP is correct in prometheus.yml
- Verify firewall allows 10.0.12.221 on port 9100
- Check Node Exporter is running on web server: `sudo systemctl status node_exporter`
- Test connectivity from monitoring server: `telnet 10.0.8.145 9100`

**Checkpoint:** ✅ Prometheus showing `web_server_01` target as **UP**

---

## Step 5: View Metrics in Grafana

### 5.1 Access Grafana

Open: `http://44.244.230.26:3000`

Login with your credentials.

### 5.2 Quick Metrics Check

1. **Click Explore (compass icon) in left menu**

2. **Select "Prometheus" datasource**

3. **Try these queries:**

   **CPU Usage:**
   ```
   100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle",instance="PROD01"}[5m])) * 100)
   ```

   **Memory Usage (%):**
   ```
   (node_memory_MemTotal_bytes{instance="PROD01"} - node_memory_MemAvailable_bytes{instance="PROD01"}) / node_memory_MemTotal_bytes{instance="PROD01"} * 100
   ```

   **Disk Usage (%):**
   ```
   (node_filesystem_size_bytes{instance="PROD01",mountpoint="/"} - node_filesystem_avail_bytes{instance="PROD01",mountpoint="/"}) / node_filesystem_size_bytes{instance="PROD01",mountpoint="/"} * 100
   ```

   **Network Traffic (received):**
   ```
   rate(node_network_receive_bytes_total{instance="PROD01"}[5m])
   ```

4. **Click "Run query"** - you should see current values!

**Checkpoint:** ✅ Metrics visible in Grafana Explore

---

## Step 6: Create Custom Dashboard

### 6.1 Import Pre-built Dashboard (Easiest Method)

1. **In Grafana, click ☰ → Dashboards**

2. **Click "New" → "Import"**

3. **Enter Dashboard ID: `1860`** (popular Node Exporter dashboard)
   - Click "Load"

4. **Configure Import:**
   - Name: `Web Servers - System Metrics`
   - Folder: `General`
   - Prometheus datasource: `Prometheus`
   - Click "Import"

5. **Filter to your server:**
   - At top of dashboard, find "Host" dropdown
   - Select `PROD01`

**You should now see:**
- CPU Usage graphs
- Memory Usage graphs
- Disk Space graphs
- Network Traffic graphs
- System Load
- Uptime

### 6.2 Create Simple Custom Dashboard (Manual Method)

If you want a custom dashboard from scratch:

1. **☰ → Dashboards → New Dashboard**

2. **Click "Add visualization"**

3. **Create CPU Panel:**
   - Datasource: Prometheus
   - Query:
     ```
     100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle",instance="PROD01"}[5m])) * 100)
     ```
   - Legend: `CPU Usage %`
   - Panel title: `CPU Usage`
   - Click "Apply"

4. **Add Memory Panel:**
   - Click "Add" → "Visualization"
   - Query:
     ```
     (node_memory_MemTotal_bytes{instance="PROD01"} - node_memory_MemAvailable_bytes{instance="PROD01"}) / node_memory_MemTotal_bytes{instance="PROD01"} * 100
     ```
   - Panel title: `Memory Usage %`
   - Click "Apply"

5. **Add Disk Space Panel:**
   - Click "Add" → "Visualization"
   - Query:
     ```
     (node_filesystem_size_bytes{instance="PROD01",mountpoint="/"} - node_filesystem_avail_bytes{instance="PROD01",mountpoint="/"}) / node_filesystem_size_bytes{instance="PROD01",mountpoint="/"} * 100
     ```
   - Panel title: `Disk Usage %`
   - Click "Apply"

6. **Add Network Traffic Panel:**
   - Click "Add" → "Visualization"
   - Query A:
     ```
     rate(node_network_receive_bytes_total{instance="PROD01",device!~"lo|veth.*"}[5m])
     ```
   - Legend: `Received`
   - Query B (click "+ Query"):
     ```
     rate(node_network_transmit_bytes_total{instance="PROD01",device!~"lo|veth.*"}[5m])
     ```
   - Legend: `Transmitted`
   - Panel title: `Network Traffic`
   - Click "Apply"

7. **Save Dashboard:**
   - Click 💾 (Save icon)
   - Name: `Web Server - PROD01`
   - Click "Save"

**Checkpoint:** ✅ Dashboard showing live metrics from web server

---

## Step 7: Monitor Multiple Web Servers

To add more web servers, repeat:

### 7.1 On Each New Web Server:

```bash
# Install Node Exporter (Steps 2.1-2.4)
# Configure firewall (Step 3.2)
```

### 7.2 On Monitoring Server:

Edit Prometheus config:

```bash
sudo nano /etc/prometheus/prometheus.yml
```

Add new scrape jobs:

```yaml
  - job_name: 'web_server_02'
    static_configs:
      - targets: ['10.0.9.123:9100']  # Second server's private IP
        labels:
          instance: 'web-server-02'
          environment: 'production'
          role: 'web'

  - job_name: 'web_server_03'
    static_configs:
      - targets: ['10.0.10.45:9100']  # Third server's private IP
        labels:
          instance: 'web-server-03'
          environment: 'staging'
          role: 'web'
```

Reload Prometheus:

```bash
curl -X POST http://localhost:9090/-/reload
```

### 7.3 View All Servers in Grafana:

In the imported dashboard (ID 1860), use the "Host" dropdown to switch between servers, or select "All" to see combined view.

---

## Optional: Monitor Specific Services

### Monitor Nginx Web Server

If your web server runs Nginx:

**1. Enable Nginx stub_status:**

```bash
sudo nano /etc/nginx/sites-available/status
```

```nginx
server {
    listen 8080;
    server_name localhost;

    location /stub_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        allow 10.0.12.221;  # Allow monitoring server
        deny all;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/status /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**2. Install Nginx Exporter:**

```bash
cd /tmp
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
tar -xzf nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz

sudo useradd --no-create-home --shell /bin/false nginx_exporter
sudo cp nginx-prometheus-exporter /usr/local/bin/
sudo chown nginx_exporter:nginx_exporter /usr/local/bin/nginx-prometheus-exporter
```

**3. Create service:**

```bash
sudo nano /etc/systemd/system/nginx_exporter.service
```

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

```bash
sudo systemctl daemon-reload
sudo systemctl enable nginx_exporter
sudo systemctl start nginx_exporter
```

**4. Update firewall:**

```bash
sudo ufw allow from 10.0.12.221 to any port 9113 comment 'Nginx Exporter'
```

**5. Add to Prometheus:**

On monitoring server:

```bash
sudo nano /etc/prometheus/prometheus.yml
```

```yaml
  - job_name: 'nginx_web_server_01'
    static_configs:
      - targets: ['10.0.8.145:9113']  # Your web server's private IP
        labels:
          instance: 'PROD01'
```

```bash
curl -X POST http://localhost:9090/-/reload
```

---

## Troubleshooting

### Target Shows DOWN in Prometheus

**1. Test connectivity from monitoring server:**

```bash
# SSH to monitoring server (44.244.230.26)
ssh ubuntu@44.244.230.26

# Test connection to web server
curl http://10.0.8.145:9100/metrics
```

If this fails, check:

**2. Verify Node Exporter is running on web server:**

```bash
# On web server
sudo systemctl status node_exporter
curl http://localhost:9100/metrics | head
```

**3. Check firewall on web server:**

```bash
# On web server
sudo ufw status numbered
# Should show rule allowing 10.0.12.221 on port 9100
```

**4. Check security group in AWS:**

- AWS Console → EC2 → Security Groups
- Find web server's security group
- Verify inbound rule: TCP port 9100 from 10.0.12.221/32

**5. Verify private IP in Prometheus config:**

```bash
# On monitoring server
cat /etc/prometheus/prometheus.yml | grep -A5 web_server_01
```

### No Data in Grafana

**1. Check Prometheus has data:**

- Open: `http://44.244.230.26:9090`
- Status → Targets → Verify target is UP
- Graph → Query: `up{instance="PROD01"}` → Execute
- Should return 1

**2. Check Grafana datasource:**

- Grafana → Configuration → Data Sources → Prometheus
- Click "Test" → Should succeed

**3. Verify query in Grafana:**

- Use Explore with simple query: `up{instance="PROD01"}`

### High CPU/Memory on Web Server

This is normal if you're stress testing. To generate load:

```bash
# Install stress tool
sudo apt install -y stress

# Generate CPU load
stress --cpu 2 --timeout 60

# Generate memory load
stress --vm 1 --vm-bytes 500M --timeout 60
```

Watch metrics update in Grafana in real-time!

---

## Summary

### What You've Accomplished:

✅ **Created a new Ubuntu web server**  
✅ **Installed Node Exporter for system metrics**  
✅ **Configured secure firewall rules**  
✅ **Added server to Prometheus monitoring**  
✅ **Created Grafana dashboard to visualize:**
   - CPU usage
   - Memory usage
   - Disk space
   - Network traffic
   - System load

### Access Your Monitoring:

- **Grafana Dashboard:** `http://44.244.230.26:3000`
- **Prometheus Targets:** `http://44.244.230.26:9090/targets`

### Key Metrics Available:

| Metric | Query |
|--------|-------|
| CPU % | `100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| Memory % | `(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100` |
| Disk % | `(node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_avail_bytes{mountpoint="/"}) / node_filesystem_size_bytes{mountpoint="/"} * 100` |
| Network In | `rate(node_network_receive_bytes_total[5m])` |
| Network Out | `rate(node_network_transmit_bytes_total[5m])` |
| Uptime | `node_time_seconds - node_boot_time_seconds` |

### Next Steps:

1. **Set up alerts** for high CPU/memory/disk usage
2. **Add more web servers** following the same process
3. **Monitor specific services** (Nginx, Apache, etc.)
4. **Create custom dashboards** for your specific needs
5. **Configure log shipping** with Promtail (see main MANUAL_SETUP_GUIDE.md)

---

**Need Help?**

- Check logs: `sudo journalctl -u node_exporter -f`
- Verify connectivity: `telnet <IP> 9100`
- Test metrics: `curl http://localhost:9100/metrics`
- Prometheus status: `http://44.244.230.26:9090/targets`

**You're now monitoring your web server!** 🎉
