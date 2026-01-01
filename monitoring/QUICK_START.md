# BMI Health Tracker - Monitoring Quick Start Guide

This guide will help you set up comprehensive monitoring for the BMI Health Tracker application in **under 15 minutes**.

## 📋 Prerequisites

- **Application Server**: EC2 Ubuntu 22.04 with BMI app already running
- **Monitoring Server**: Fresh EC2 Ubuntu 22.04 (t3.medium recommended, 4GB+ RAM)
- SSH access to both servers
- **Both servers in same VPC/subnet** (recommended)
- Security groups configured to allow traffic between servers

### 🔐 Network Configuration (IMPORTANT)

**Use Private IPs for communication:**
- When servers are in the same VPC/subnet, **always use private IPs**
- Private IPs look like: `10.x.x.x`, `172.16-31.x.x`, or `192.168.x.x`
- Find private IP: `hostname -I` or AWS Console → Instance → Private IPv4 addresses

**Benefits of Private IPs:**
- ✅ Better security (traffic stays within VPC)
- ✅ Lower latency (no internet routing)
- ✅ No data transfer costs
- ✅ More reliable connection
- ✅ Exporters not exposed to internet

## 🏗️ Architecture Overview

```
┌─────────────────────────┐         ┌──────────────────────────┐
│  Application Server     │         │  Monitoring Server       │
│  (BMI App Running)      │────────▶│                          │
│                         │         │  ┌────────────────────┐  │
│  Exporters:             │  Metrics│  │ Prometheus         │  │
│  • Node Exporter :9100  │────────▶│  │ (Metrics Storage)  │  │
│  • PostgreSQL    :9187  │         │  └────────┬───────────┘  │
│  • Nginx         :9113  │         │           │              │
│  • BMI Custom    :9091  │         │  ┌────────▼───────────┐  │
│  • Promtail      :9080  │────────▶│  │ Grafana            │  │
│                         │  Logs   │  │ (Visualization)    │  │
└─────────────────────────┘         │  └────────────────────┘  │
                                    │                          │
                                    │  ┌────────────────────┐  │
                                    │  │ Loki               │  │
                                    │  │ (Log Aggregation)  │  │
                                    │  └────────────────────┘  │
                                    │                          │
                                    │  ┌────────────────────┐  │
                                    │  │ AlertManager       │  │
                                    │  │ (Alerting)         │  │
                                    │  └────────────────────┘  │
                                    └──────────────────────────┘
```

## 🚀 Quick Setup (3 Steps)

### Step 1: Setup Monitoring Server (5 minutes)

SSH into your **monitoring server** and run:

```bash
# Clone the repository
cd /tmp
git clone https://github.com/sarowar-dev-ops/single-server-3tier-webapp-monitoring.git
cd single-server-3tier-webapp-monitoring/monitoring/scripts

# Run the setup script (requires sudo)
sudo bash setup-monitoring-server.sh
# When prompted, enter your APPLICATION SERVER PRIVATE IP
# Find it with: hostname -I (on app server)
```

**What this does:**
- ✅ Installs Prometheus, Grafana, Loki, AlertManager
- ✅ Configures all services with systemd
- ✅ Sets up firewall rules
- ✅ Auto-starts all monitoring services

**Access URLs** (replace MONITORING_IP with your monitoring server IP):
- Grafana: `http://MONITORING_IP:3000` (admin/admin)
- Prometheus: `http://MONITORING_IP:9090`
- AlertManager: `http://MONITORING_IP:9093`

### Step 2: Setup Application Exporters (5 minutes)

SSH into your **application server** and run:

```bash
# Clone the repository
cd /tmp
git clone https://github.com/sarowar-dev-ops/single-server-3tier-webapp-monitoring.git
cd single-server-3tier-webapp-monitoring/monitoring/scripts

# Run the setup script (requires sudo)
sudo bash setup-application-exporters.sh
# When prompted, enter:
# - MONITORING SERVER PRIVATE IP (find it with: hostname -I)
# - Database credentials (name, user, password)
```

**What this does:**
- ✅ Installs Node Exporter (system metrics)
- ✅ Installs PostgreSQL Exporter (database metrics)
- ✅ Installs Nginx Exporter (web server metrics)
- ✅ Installs Custom BMI Exporter (application metrics)
- ✅ Installs Promtail (log shipping)
- ✅ Configures firewall to allow monitoring server

### Step 3: Import Grafana Dashboards (2 minutes)

1. Open Grafana: `http://MONITORING_IP:3000`
2. Login with `admin/admin` (change password when prompted)
3. Add Prometheus data source:
   - Click ⚙️ (Configuration) → Data Sources → Add data source
   - Select **Prometheus**
   - URL: `http://localhost:9090`
   - Click **Save & Test**

4. Add Loki data source:
   - Click ⚙️ (Configuration) → Data Sources → Add data source
   - Select **Loki**
   - URL: `http://localhost:3100`
   - Click **Save & Test**

5. Import dashboards:
   - The monitoring server already has the repo in `/tmp/single-server-3tier-webapp-monitoring/`
   - Click ➕ → Import
   - Upload `/tmp/single-server-3tier-webapp-monitoring/monitoring/grafana/dashboards/system-overview.json`
   - Select Prometheus data source
   - Click **Import**
   - Repeat for `bmi-application-metrics.json`
   
   **Or use curl to import:**
   ```bash
   # SSH to monitoring server
   cd /tmp/single-server-3tier-webapp-monitoring/monitoring/grafana/dashboards
   # Dashboards are ready to import via Grafana UI
   ```

## ✅ Verification

### Check Monitoring Server Services

```bash
# On monitoring server
sudo systemctl status prometheus grafana-server loki alertmanager node_exporter
```

All services should show **active (running)** in green.

### Check Application Server Exporters

```bash
# On application server
sudo systemctl status node_exporter postgres_exporter nginx_exporter promtail
pm2 list  # Should show bmi-exporter running
```

### Verify Prometheus Targets

1. Open: `http://MONITORING_IP:9090/targets`
2. All targets should be **UP** (green):
   - `node_exporter` (app-server)
   - `postgresql` (app-server)
   - `nginx` (app-server)
   - `bmi-backend` (app-server)
   - `prometheus` (monitoring-server)

### Test Metrics Endpoints

From your local machine:

```bash
# Replace APP_SERVER_IP with your application server IP
curl http://APP_SERVER_IP:9100/metrics  # Node Exporter
curl http://APP_SERVER_IP:9187/metrics  # PostgreSQL Exporter
curl http://APP_SERVER_IP:9113/metrics  # Nginx Exporter
curl http://APP_SERVER_IP:9091/metrics  # BMI Custom Exporter
```

Each should return Prometheus-formatted metrics.

## 📊 What You Can Monitor Now

### System Metrics
- **CPU Usage**: Real-time CPU utilization per core
- **Memory Usage**: Used, available, cached memory
- **Disk Usage**: Disk space, I/O operations
- **Network Traffic**: Bandwidth in/out per interface

### Application Metrics
- **Total BMI Measurements**: All-time count
- **Recent Activity**: Measurements in last 24h and 1h
- **Average BMI**: Population-wide average
- **BMI Distribution**: Count by category (underweight, normal, overweight, obese)
- **Database Size**: Total DB and table sizes
- **Connection Pool**: Active, idle, waiting connections
- **Health Status**: Application health indicator

### Database Metrics
- **PostgreSQL Performance**: Query rates, transactions
- **Connection Stats**: Active connections, max connections
- **Cache Hit Ratio**: Query cache efficiency
- **Replication Lag**: If using replication
- **Lock Statistics**: Table and row locks

### Web Server Metrics
- **Nginx Requests**: Requests per second
- **Response Codes**: 2xx, 3xx, 4xx, 5xx counts
- **Active Connections**: Current concurrent connections
- **Request Duration**: Response time percentiles

### Logs (via Loki)
- **Backend Logs**: PM2 application logs
- **Nginx Access**: HTTP request logs
- **Nginx Error**: Web server error logs
- **PostgreSQL**: Database query and error logs
- **System Logs**: Syslog for OS events

## 🔔 Alert Examples

The monitoring stack includes pre-configured alerts:

- 🔴 **Critical**: Server down, disk >90% full, memory >95%
- 🟡 **Warning**: High CPU >80%, many DB connections >80%
- 🔵 **Info**: New deployment, backup completed

Configure notifications in AlertManager:
```bash
sudo nano /etc/alertmanager/alertmanager.yml
# Add email, Slack, PagerDuty, or Discord webhooks
sudo systemctl restart alertmanager
```

## 🎯 Common Queries

### Top 5 Most Common BMI Values
```promql
topk(5, bmi_category_count)
```

### Database Query Rate
```promql
rate(pg_stat_database_xact_commit_total[5m])
```

### API Request Rate (from Nginx)
```promql
rate(nginx_http_requests_total[5m])
```

### Memory Usage Percentage
```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) 
/ node_memory_MemTotal_bytes * 100
```

### 95th Percentile Response Time
```promql
histogram_quantile(0.95, rate(nginx_http_request_duration_seconds_bucket[5m]))
```

## 🔧 Troubleshooting

### Target Shows "DOWN" in Prometheus

1. **Verify you used PRIVATE IPs:**
   ```bash
   # On application server - check private IP
   hostname -I
   # Or
   ip addr show | grep "inet " | grep -v 127.0.0.1
   
   # Verify Prometheus config has correct private IP
   # On monitoring server:
   cat /etc/prometheus/prometheus.yml | grep targets
   ```

2. **Check exporter is running:**
   ```bash
   # On application server
   sudo systemctl status node_exporter
   # If not running:
   sudo systemctl start node_exporter
   ```

3. **Check firewall:**
   ```bash
   # On application server
   sudo ufw status
   # Should show monitoring server PRIVATE IP allowed on exporter ports
   ```

4. **Test connectivity using PRIVATE IPs:**
   ```bash
   # From monitoring server (use private IPs)
   telnet APP_SERVER_PRIVATE_IP 9100
   curl http://APP_SERVER_PRIVATE_IP:9100/metrics
   ```

### No Logs in Loki

1. **Check Promtail status:**
   ```bash
   # On application server
   sudo systemctl status promtail
   sudo journalctl -u promtail -f  # View logs
   ```

2. **Check Promtail can reach Loki:**
   ```bash
   # On application server
   curl http://MONITORING_IP:3100/ready
   # Should return "ready"
   ```

3. **Verify log file permissions:**
   ```bash
   # Promtail needs read access
   ls -la /var/log/nginx/*.log
   ls -la /root/.pm2/logs/*.log
   ```

### Grafana Dashboard Shows "No Data"

1. **Verify data source connection:**
   - Go to Configuration → Data Sources
   - Click "Test" on Prometheus and Loki
   - Both should show "Data source is working"

2. **Check time range:**
   - Dashboard time picker (top right)
   - Try "Last 5 minutes" or "Last 1 hour"

3. **Check if metrics exist in Prometheus:**
   - Go to Prometheus: `http://MONITORING_IP:9090`
   - Execute query: `up`
   - Should show all exporters

### Custom BMI Exporter Not Working

1. **Check PM2 status:**
   ```bash
   pm2 list
   pm2 logs bmi-exporter
   ```

2. **Check database connection:**
   ```bash
   # Verify .env file
   cat /opt/bmi-exporter/.env
   
   # Test DB connection
   psql -U bmi_user -d bmi_tracker -h localhost -c "SELECT COUNT(*) FROM measurements;"
   ```

3. **Restart exporter:**
   ```bash
   pm2 restart bmi-exporter
   pm2 save
   ```

## 📚 Next Steps

1. **Customize Alert Rules**: Edit `/etc/prometheus/alert_rules.yml`
2. **Add More Dashboards**: Explore [Grafana Labs](https://grafana.com/grafana/dashboards/)
3. **Configure Notifications**: Setup email/Slack in AlertManager
4. **Enable HTTPS**: Add SSL certificates for Grafana
5. **Setup Backup**: Backup Prometheus data and Grafana dashboards
6. **Add More Metrics**: Create custom exporters for business KPIs

## 🆘 Support

- **Documentation**: See `monitoring/IMPLEMENTATION_GUIDE.md` for detailed setup
- **Alert Configuration**: See `monitoring/prometheus/alert_rules.yml`
- **Custom Metrics**: See `monitoring/exporters/bmi-app-exporter/exporter.js`

## 🔐 Security Checklist

- [ ] Change Grafana admin password
- [ ] Restrict monitoring server access (security groups)
- [ ] Use strong database passwords in exporter configs
- [ ] Enable Grafana authentication (LDAP/OAuth)
- [ ] Setup HTTPS for Grafana with valid SSL certificate
- [ ] Rotate AlertManager webhook secrets
- [ ] Regular updates: `sudo apt update && sudo apt upgrade`

## 📊 Monitoring Ports Reference

| Service | Port | Protocol | Access |
|---------|------|----------|--------|
| Grafana | 3000 | HTTP | Public (with auth) |
| Prometheus | 9090 | HTTP | Internal only |
| AlertManager | 9093 | HTTP | Internal only |
| Loki | 3100 | HTTP | Internal only |
| Node Exporter | 9100 | HTTP | Monitoring server only |
| PostgreSQL Exporter | 9187 | HTTP | Monitoring server only |
| Nginx Exporter | 9113 | HTTP | Monitoring server only |
| BMI Custom Exporter | 9091 | HTTP | Monitoring server only |
| Promtail | 9080 | HTTP | Internal only |

---

**Estimated Total Setup Time**: ~15 minutes

**Cost Estimate** (AWS):
- Application Server: Existing (no additional cost)
- Monitoring Server (t3.medium): ~$30/month
- Data Transfer: ~$5-10/month
- **Total**: ~$35-40/month

**🎉 Congratulations!** You now have a production-grade monitoring system for your BMI Health Tracker application!
