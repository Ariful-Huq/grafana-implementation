# BMI Health Tracker - Complete Monitoring Solution

## 📁 Monitoring Directory Structure

```
monitoring/
├── README.md                           # Overview and architecture
├── IMPLEMENTATION_GUIDE.md             # Detailed setup instructions
├── QUICK_START.md                      # 15-minute quick setup guide
│
├── scripts/
│   ├── setup-monitoring-server.sh      # Automated monitoring server setup
│   └── setup-application-exporters.sh  # Automated exporter installation
│
├── prometheus/
│   ├── prometheus.yml                  # Prometheus configuration
│   └── alert_rules.yml                 # Alert rules (20+ alerts)
│
├── grafana/
│   └── dashboards/
│       ├── system-overview.json        # System metrics dashboard
│       └── bmi-application-metrics.json # BMI-specific metrics dashboard
│
├── loki/
│   └── loki-config.yml                 # Loki log aggregation config
│
├── promtail/
│   └── promtail-config.yml             # Promtail log shipping config
│
├── alertmanager/
│   └── alertmanager.yml                # Alert routing and notifications
│
└── exporters/
    └── bmi-app-exporter/
        ├── package.json                # NPM dependencies
        ├── exporter.js                 # Custom Prometheus exporter (15+ metrics)
        └── ecosystem.config.js         # PM2 configuration
```

## 🎯 What This Monitoring Solution Provides

### 1. Infrastructure Monitoring
- **CPU Usage**: Per-core utilization, load averages
- **Memory**: Total, used, available, cached, swap
- **Disk**: Space usage, I/O operations, read/write throughput
- **Network**: Traffic in/out, packets, errors, drops
- **System**: Uptime, processes, file descriptors, interrupts

**Data Source**: Node Exporter (port 9100)

### 2. Database Monitoring
- **Performance**: Query rate, transactions per second
- **Connections**: Active, idle, max connections, connection errors
- **Cache**: Buffer cache hit ratio, shared buffer usage
- **Locks**: Table locks, row locks, deadlocks
- **Size**: Database size, table sizes, index sizes
- **Replication**: Lag (if applicable), streaming status

**Data Source**: PostgreSQL Exporter (port 9187)

### 3. Web Server Monitoring
- **Requests**: Total requests, requests per second
- **Status Codes**: 2xx, 3xx, 4xx, 5xx breakdown
- **Connections**: Active, reading, writing, waiting
- **Performance**: Request processing time
- **Errors**: Connection errors, timeouts

**Data Source**: Nginx Exporter (port 9113)

### 4. Application-Specific Monitoring
- **Business Metrics**:
  - Total BMI measurements (all-time)
  - Measurements created in last 24 hours
  - Measurements created in last hour
  - Average BMI value (population-wide)
  - BMI distribution by category (underweight, normal, overweight, obese)
  - Average age of measurements
  - Average daily calories
  
- **Database Health**:
  - Database size in bytes
  - Measurements table size in bytes
  - Connection pool statistics (total, idle, waiting)
  
- **Application Health**:
  - Health check status (1 = healthy, 0 = unhealthy)
  - Metric collection errors counter

**Data Source**: Custom BMI Exporter (port 9091)

### 5. Log Aggregation
- **Backend Logs**: PM2 application logs (stdout/stderr)
- **Nginx Access Logs**: HTTP requests with details
- **Nginx Error Logs**: Web server errors and warnings
- **PostgreSQL Logs**: Database queries, errors, slow queries
- **System Logs**: OS-level syslog events

**Data Source**: Loki + Promtail

### 6. Alerting
Pre-configured alerts for:
- **Critical**: Instance down, disk >90%, memory >95%, database down
- **Warning**: High CPU >80%, high memory >90%, many DB connections >80%
- **Info**: High API error rate, slow queries, unusual traffic patterns

**Data Source**: AlertManager with Prometheus rules

## 🏗️ Architecture

### Two-Server Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     APPLICATION SERVER                          │
│                     (EC2 Ubuntu 22.04)                          │
│                                                                 │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────────┐   │
│  │   Nginx     │   │   Node.js    │   │   PostgreSQL     │   │
│  │   (Port 80) │──▶│   Backend    │──▶│   Database       │   │
│  │             │   │   (Port 3000)│   │   (Port 5432)    │   │
│  └─────────────┘   └──────────────┘   └──────────────────┘   │
│         │                  │                    │              │
│         │                  │                    │              │
│  ┌──────▼──────────────────▼────────────────────▼──────────┐  │
│  │              EXPORTERS (Metrics Collection)             │  │
│  │                                                          │  │
│  │  • Node Exporter (9100)      - System metrics           │  │
│  │  • PostgreSQL Exporter (9187) - DB metrics              │  │
│  │  • Nginx Exporter (9113)     - Web server metrics       │  │
│  │  • BMI Custom Exporter (9091) - App metrics             │  │
│  │  • Promtail (9080)           - Log shipping             │  │
│  └──────────────────────────────────────────────────────────┘  │
│                          │                                      │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           │ Metrics & Logs
                           │ (15s scrape interval)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                     MONITORING SERVER                           │
│                     (EC2 Ubuntu 22.04)                          │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │               PROMETHEUS (Port 9090)                   │    │
│  │         • Metrics collection & storage                 │    │
│  │         • 30-day retention                             │    │
│  │         • 6 scrape jobs configured                     │    │
│  └────────────────┬───────────────────────────────────────┘    │
│                   │                                             │
│                   ▼                                             │
│  ┌────────────────────────────────────────────────────────┐    │
│  │               GRAFANA (Port 3000)                      │    │
│  │         • Data visualization                           │    │
│  │         • Pre-built dashboards                         │    │
│  │         • User authentication                          │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │                 LOKI (Port 3100)                       │    │
│  │         • Log aggregation & storage                    │    │
│  │         • 31-day retention                             │    │
│  │         • 5 log sources configured                     │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │              ALERTMANAGER (Port 9093)                  │    │
│  │         • Alert routing & deduplication                │    │
│  │         • Notification channels (email/Slack/etc)      │    │
│  │         • Inhibition rules                             │    │
│  └────────────────────────────────────────────────────────┘    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 📊 Available Dashboards

### 1. System Overview Dashboard
**File**: `grafana/dashboards/system-overview.json`

**Panels**:
- CPU Usage (gauge + time series)
- Memory Usage (gauge + time series)
- Disk Usage (gauge)
- Network Traffic (time series)
- Disk I/O (time series)

**Use Cases**:
- Monitor server resource utilization
- Identify performance bottlenecks
- Capacity planning
- Detect unusual resource consumption

### 2. BMI Application Metrics Dashboard
**File**: `grafana/dashboards/bmi-application-metrics.json`

**Panels**:
- Total Measurements (stat)
- Measurements Last 24h (stat)
- Average BMI (stat with color thresholds)
- BMI Distribution by Category (pie chart)
- Total Measurements Growth (time series)
- BMI Categories Over Time (stacked bars)
- Average BMI Trend (time series)
- Database Size (stat)
- Measurements Table Size (stat)
- Database Connection Pool (time series)
- Application Health (stat with status)

**Use Cases**:
- Track user engagement and growth
- Monitor data quality (BMI averages)
- Detect unusual patterns
- Database capacity planning
- Application health monitoring

## 🔔 Alert Rules

### Critical Alerts (Immediate Action Required)

1. **InstanceDown**: Exporter not reachable for 5+ minutes
2. **CriticalMemoryUsage**: Memory usage > 95%
3. **DiskSpaceCritical**: Disk usage > 90%
4. **PostgreSQLDown**: Database not responding
5. **NginxDown**: Web server not responding

### Warning Alerts (Investigation Needed)

1. **HighCPUUsage**: CPU usage > 90% for 10+ minutes
2. **HighMemoryUsage**: Memory usage > 90% for 10+ minutes
3. **DiskSpaceWarning**: Disk usage > 80%
4. **TooManyDatabaseConnections**: DB connections > 80% of max
5. **HighAPIErrorRate**: API errors > 5% for 5+ minutes

### Informational Alerts

1. **LowDiskSpace**: Disk usage > 70%
2. **HighNetworkTraffic**: Unusual network activity
3. **SlowQueries**: PostgreSQL slow query log entries

## 🚀 Quick Start Commands

### Deploy Monitoring Server
```bash
# On monitoring server
wget https://raw.githubusercontent.com/your-repo/monitoring/scripts/setup-monitoring-server.sh
chmod +x setup-monitoring-server.sh
sudo ./setup-monitoring-server.sh
# Enter application server IP when prompted
```

### Deploy Application Exporters
```bash
# On application server
wget https://raw.githubusercontent.com/your-repo/monitoring/scripts/setup-application-exporters.sh
chmod +x setup-application-exporters.sh
sudo ./setup-application-exporters.sh
# Enter monitoring server IP and DB credentials when prompted
```

### Access Monitoring
```bash
# Grafana (Web UI)
http://MONITORING_IP:3000
# Login: admin/admin (change password!)

# Prometheus (Metrics & Queries)
http://MONITORING_IP:9090

# AlertManager (Alerts)
http://MONITORING_IP:9093
```

## 🔍 Useful Prometheus Queries

### System Metrics

**CPU Usage %**:
```promql
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memory Usage %**:
```promql
((node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes) * 100
```

**Disk Usage %**:
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} * 100) / node_filesystem_size_bytes{mountpoint="/"})
```

**Network Traffic (bytes/sec)**:
```promql
rate(node_network_receive_bytes_total[5m])
rate(node_network_transmit_bytes_total[5m])
```

### Database Metrics

**Active Connections**:
```promql
pg_stat_database_numbackends{datname="bmi_tracker"}
```

**Queries per Second**:
```promql
rate(pg_stat_database_xact_commit_total{datname="bmi_tracker"}[5m])
```

**Cache Hit Ratio %**:
```promql
(pg_stat_database_blks_hit{datname="bmi_tracker"} / (pg_stat_database_blks_hit{datname="bmi_tracker"} + pg_stat_database_blks_read{datname="bmi_tracker"})) * 100
```

### Application Metrics

**BMI Measurements Growth Rate**:
```promql
rate(bmi_measurements_total[1h])
```

**Average BMI by Category**:
```promql
bmi_category_count / sum(bmi_category_count) * 100
```

**Database Connection Pool Usage %**:
```promql
(bmi_db_pool_total - bmi_db_pool_idle) / bmi_db_pool_total * 100
```

### Web Server Metrics

**Requests per Second**:
```promql
rate(nginx_http_requests_total[5m])
```

**4xx Error Rate %**:
```promql
(rate(nginx_http_requests_total{status=~"4.."}[5m]) / rate(nginx_http_requests_total[5m])) * 100
```

**5xx Error Rate %**:
```promql
(rate(nginx_http_requests_total{status=~"5.."}[5m]) / rate(nginx_http_requests_total[5m])) * 100
```

## 📝 Log Queries (Loki)

### Application Logs
```logql
{job="bmi-backend"} |= "error"
{job="bmi-backend"} |= "BMI calculated"
{job="bmi-backend"} | json | line_format "{{.level}}: {{.message}}"
```

### Nginx Access Logs
```logql
{job="nginx", type="access"} |= "POST /api/measurements"
{job="nginx", type="access"} |~ "5[0-9]{2}"  # 5xx errors
```

### PostgreSQL Logs
```logql
{job="postgresql"} |= "ERROR"
{job="postgresql"} |= "slow query"
```

### System Logs
```logql
{job="syslog"} |= "error" or "failed"
{job="syslog"} |= "out of memory"
```

## 🔧 Maintenance

### Update Prometheus Configuration
```bash
# Edit config
sudo nano /etc/prometheus/prometheus.yml

# Reload (no downtime)
curl -X POST http://localhost:9090/-/reload

# Or restart
sudo systemctl restart prometheus
```

### Add New Alert Rule
```bash
# Edit alert rules
sudo nano /etc/prometheus/alert_rules.yml

# Reload Prometheus
curl -X POST http://localhost:9090/-/reload
```

### Backup Grafana Dashboards
```bash
# Export all dashboards
curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/search?type=dash-db | \
  jq -r '.[] | .uid' | \
  xargs -I {} curl -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/dashboards/uid/{} > dashboard-{}.json
```

### Clean Old Prometheus Data
```bash
# Prometheus auto-deletes data older than retention period (30 days)
# To manually clean:
sudo systemctl stop prometheus
sudo rm -rf /var/lib/prometheus/data/*
sudo systemctl start prometheus
```

## 🔐 Security Best Practices

1. **Change Default Passwords**:
   ```bash
   # Grafana: Login and change admin password
   # Or use CLI:
   grafana-cli admin reset-admin-password NEW_PASSWORD
   ```

2. **Restrict Access**:
   ```bash
   # Configure security groups to allow only:
   # - Your IP → Grafana (port 3000)
   # - App server IP → Loki (port 3100)
   # - App server IP → Prometheus (port 9090) for scraping
   ```

3. **Enable HTTPS**:
   ```bash
   # Use Let's Encrypt for Grafana
   sudo apt install certbot
   sudo certbot certonly --standalone -d monitoring.yourdomain.com
   
   # Configure Grafana to use SSL
   sudo nano /etc/grafana/grafana.ini
   # Set:
   # protocol = https
   # cert_file = /etc/letsencrypt/live/monitoring.yourdomain.com/fullchain.pem
   # cert_key = /etc/letsencrypt/live/monitoring.yourdomain.com/privkey.pem
   ```

4. **Secure Exporters**:
   ```bash
   # Exporters should only be accessible from monitoring server
   # Use UFW to restrict:
   sudo ufw allow from MONITORING_IP to any port 9100
   sudo ufw allow from MONITORING_IP to any port 9187
   sudo ufw allow from MONITORING_IP to any port 9113
   sudo ufw allow from MONITORING_IP to any port 9091
   ```

## 📈 Performance Considerations

### Monitoring Server Sizing

| Server Size | Max Targets | Retention | Storage |
|-------------|-------------|-----------|---------|
| t3.small (2GB RAM) | Up to 10 targets | 15 days | 20GB |
| t3.medium (4GB RAM) | Up to 50 targets | 30 days | 50GB |
| t3.large (8GB RAM) | Up to 200 targets | 90 days | 100GB |

**Recommendation**: Start with t3.medium (4GB RAM, 2 vCPU) for single application server.

### Scrape Interval Tuning

- **15 seconds** (default): Good balance between granularity and overhead
- **30 seconds**: Reduce load on small systems
- **5 seconds**: High-frequency monitoring for critical systems

Edit in `prometheus.yml`:
```yaml
global:
  scrape_interval: 15s  # Change as needed
```

### Storage Optimization

Prometheus storage usage formula:
```
Storage = Retention_days × Samples_per_day × 2 bytes
Samples_per_day = Targets × Metrics_per_target × (86400 / scrape_interval)
```

Example (1 app server, 1000 metrics, 15s scrape):
```
Storage = 30 days × (1 × 1000 × 5760) × 2 bytes
        = 30 × 5,760,000 × 2 bytes
        ≈ 345 MB
```

## 🆘 Troubleshooting

### Service Not Starting
```bash
# Check logs
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f
sudo journalctl -u loki -f

# Check config syntax
promtool check config /etc/prometheus/prometheus.yml
```

### High CPU Usage
```bash
# Check Prometheus queries
# Expensive queries cause high CPU
# Optimize dashboard queries with rate() and avg()

# Reduce scrape frequency
# Edit prometheus.yml: scrape_interval: 30s
```

### Disk Full
```bash
# Reduce Prometheus retention
# Edit prometheus.service:
# --storage.tsdb.retention.time=15d

# Reduce Loki retention
# Edit loki-config.yml:
# retention_period: 360h  # 15 days
```

## 📚 Additional Resources

- **Prometheus Documentation**: https://prometheus.io/docs/
- **Grafana Tutorials**: https://grafana.com/tutorials/
- **Loki Best Practices**: https://grafana.com/docs/loki/latest/best-practices/
- **Node Exporter Metrics**: https://github.com/prometheus/node_exporter
- **PostgreSQL Exporter**: https://github.com/prometheus-community/postgres_exporter

## 🎓 Learning Path for Junior DevOps

1. **Start Here**:
   - Read `QUICK_START.md` and complete setup (15 min)
   - Explore Grafana dashboards
   - Try example Prometheus queries

2. **Week 1**:
   - Understand metrics vs logs
   - Learn PromQL basics
   - Create custom dashboard panel

3. **Week 2**:
   - Configure custom alert rule
   - Setup email notifications
   - Analyze alert history

4. **Week 3**:
   - Write advanced PromQL queries
   - Create custom exporter
   - Optimize dashboard performance

5. **Week 4**:
   - Implement backup strategy
   - Setup high availability
   - Document runbooks for alerts

## 📦 Files Summary

| File | Lines | Purpose |
|------|-------|---------|
| setup-monitoring-server.sh | 400+ | Automated monitoring stack installation |
| setup-application-exporters.sh | 450+ | Automated exporter deployment |
| prometheus.yml | 70+ | Prometheus scrape configuration |
| alert_rules.yml | 200+ | Alert definitions for all components |
| loki-config.yml | 40+ | Loki log aggregation setup |
| promtail-config.yml | 60+ | Log collection configuration |
| alertmanager.yml | 50+ | Alert routing and notifications |
| exporter.js | 400+ | Custom BMI application metrics |
| system-overview.json | 500+ | System monitoring dashboard |
| bmi-application-metrics.json | 600+ | Application-specific dashboard |

**Total**: ~2,800 lines of configuration and code

## 🎉 Summary

This monitoring solution provides:

✅ **Complete Observability**: Metrics, logs, and alerts for entire stack
✅ **Production-Ready**: Battle-tested components (Prometheus, Grafana, Loki)
✅ **Easy Setup**: Automated scripts for 15-minute deployment
✅ **Custom Metrics**: BMI-specific business metrics
✅ **Pre-built Dashboards**: 2 comprehensive Grafana dashboards
✅ **Smart Alerting**: 20+ pre-configured alerts with severity levels
✅ **Cost-Effective**: ~$35-40/month on AWS
✅ **Scalable**: Easily extend to monitor multiple servers
✅ **Documented**: Comprehensive guides for all skill levels

**Perfect for**: Junior DevOps engineers learning monitoring, production deployments, or anyone needing reliable observability for a 3-tier web application.
