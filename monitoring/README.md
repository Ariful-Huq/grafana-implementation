# 📊 Complete Monitoring Stack for BMI & Health Tracker

> Comprehensive monitoring solution using Prometheus, Grafana, Loki, and various exporters for complete observability of your 3-tier application.

![Monitoring Stack](https://img.shields.io/badge/Prometheus-E6522C?style=flat&logo=prometheus&logoColor=white)
![Grafana](https://img.shields.io/badge/Grafana-F46800?style=flat&logo=grafana&logoColor=white)
![Loki](https://img.shields.io/badge/Loki-F46800?style=flat&logo=loki&logoColor=white)
![Node Exporter](https://img.shields.io/badge/Node%20Exporter-37D100?style=flat)

---

## 📋 Table of Contents

- [What is This Monitoring Stack?](#what-is-this-monitoring-stack)
- [Architecture Overview](#architecture-overview)
- [Components](#components)
- [What Gets Monitored?](#what-gets-monitored)
- [Quick Start](#quick-start)
- [Access Information](#access-information)
- [Available Dashboards](#available-dashboards)
- [Alerting](#alerting)
- [Cost Estimation](#cost-estimation)
- [Troubleshooting](#troubleshooting)

---

## 🎯 What is This Monitoring Stack?

This monitoring solution provides **complete observability** for your BMI & Health Tracker application deployed on AWS EC2. It monitors:

✅ **Infrastructure Metrics** (CPU, Memory, Disk, Network)  
✅ **Application Metrics** (API response times, request rates, errors)  
✅ **Database Metrics** (Connections, queries, performance)  
✅ **Web Server Metrics** (Nginx requests, response codes)  
✅ **Process Metrics** (PM2 process health)  
✅ **Application Logs** (Backend logs, Nginx logs, system logs)  
✅ **Custom Business Metrics** (Measurements created, BMI calculations)

### Why Separate Monitoring Server?

Running monitoring on a separate server provides:
- **Isolation:** Monitoring doesn't compete for resources with your application
- **Reliability:** If application server fails, monitoring continues working
- **Security:** Monitoring server can be in private subnet with restricted access
- **Scalability:** Easy to add more application servers to monitor

---

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         INTERNET / VPC                           │
└────────┬────────────────────────────────────────────┬───────────┘
         │                                             │
         │                                             │
┌────────▼─────────────────────────────┐  ┌───────────▼────────────────────┐
│   APPLICATION SERVER (EC2)            │  │  MONITORING SERVER (EC2)       │
│   IP: 10.0.1.10 (private)             │  │  IP: 10.0.1.20 (private)       │
│   Public: Your-App-IP                 │  │  Public: Your-Monitor-IP       │
│                                       │  │                                │
│  ┌──────────────────────────────────┐│  │ ┌────────────────────────────┐ │
│  │  Your Application                ││  │ │  Prometheus (Port 9090)    │ │
│  │  - Frontend (Nginx)              ││  │ │  - Scrapes metrics         │ │
│  │  - Backend API (PM2)             ││  │ │  - Stores time-series data │ │
│  │  - PostgreSQL Database           ││  │ │  - Query engine            │ │
│  └──────────────────────────────────┘│  │ └────────────────────────────┘ │
│                                       │  │                                │
│  ┌──────────────────────────────────┐│  │ ┌────────────────────────────┐ │
│  │  Exporters (Metrics Sources)     ││  │ │  Grafana (Port 3000)       │ │
│  │                                   ││  │ │  - Visualizations          │ │
│  │  1. Node Exporter (9100)         ││  │ │  - Dashboards              │ │
│  │     → System metrics             ││  │ │  - Alerts                  │ │
│  │                                   ││  │ │  - User interface          │ │
│  │  2. PostgreSQL Exporter (9187)   ││  │ └────────────────────────────┘ │
│  │     → Database metrics           ││  │                                │
│  │                                   ││  │ ┌────────────────────────────┐ │
│  │  3. Nginx Exporter (9113)        ││  │ │  Loki (Port 3100)          │ │
│  │     → Web server metrics         ││  │ │  - Log aggregation         │ │
│  │                                   ││  │ │  - Log storage             │ │
│  │  4. Custom App Exporter (9091)   ││  │ │  - Log querying            │ │
│  │     → Business metrics           ││  │ └────────────────────────────┘ │
│  └──────────────────────────────────┘│  │                                │
│                                       │  │ ┌────────────────────────────┐ │
│  ┌──────────────────────────────────┐│  │ │  AlertManager (Port 9093)  │ │
│  │  Promtail (Log Shipper)          ││  │ │  - Alert routing           │ │
│  │  - Collects logs                 ││  │ │  - Notifications           │ │
│  │  - Ships to Loki                 ││  │ │  - Grouping/silencing      │ │
│  └──────────────────────────────────┘│  │ └────────────────────────────┘ │
│                                       │  │                                │
│                Metrics ──────────────────→ Prometheus                     │
│                Logs ─────────────────────→ Loki                           │
│                                       │  │                                │
└───────────────────────────────────────┘  └────────────────────────────────┘
         Application Server                      Monitoring Server
         (Your BMI App Runs Here)               (Observability Tools)
```

### Data Flow

**Metrics Collection:**
```
Application Server Exporters → Prometheus (pulls every 15s) → Grafana (queries & displays)
```

**Log Collection:**
```
Application Server Logs → Promtail (tails files) → Loki (stores) → Grafana (queries & displays)
```

**Alerting:**
```
Prometheus (evaluates rules) → AlertManager (routes) → Notifications (Email/Slack/PagerDuty)
```

---

## 🧩 Components

### Monitoring Server Components

| Component | Port | Purpose | Storage |
|-----------|------|---------|---------|
| **Prometheus** | 9090 | Metrics collection & storage | 50GB recommended |
| **Grafana** | 3000 | Visualization & dashboards | 10GB |
| **Loki** | 3100 | Log aggregation | 50GB recommended |
| **AlertManager** | 9093 | Alert routing & notification | 5GB |

### Application Server Components

| Component | Port | Purpose |
|-----------|------|---------|
| **Node Exporter** | 9100 | Linux system metrics |
| **PostgreSQL Exporter** | 9187 | Database metrics |
| **Nginx Exporter** | 9113 | Web server metrics |
| **Custom App Exporter** | 9091 | Application business metrics |
| **Promtail** | 9080 | Log collection agent |

---

## 📊 What Gets Monitored?

### 1. Infrastructure Metrics (Node Exporter)

**System Resources:**
- CPU usage (user, system, idle, iowait)
- Memory usage (used, available, cached, buffers)
- Disk usage (space, inodes)
- Disk I/O (read/write operations, throughput)
- Network traffic (bytes in/out, packets, errors)
- System load (1m, 5m, 15m averages)

**OS Metrics:**
- Process count
- Context switches
- Interrupts
- File descriptor usage
- Uptime

**Example Queries:**
```promql
# CPU usage percentage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

# Disk space used percentage
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

### 2. Database Metrics (PostgreSQL Exporter)

**Connection Pool:**
- Active connections
- Idle connections
- Waiting connections
- Max connections limit

**Query Performance:**
- Query execution time
- Slow queries (>1s)
- Queries per second
- Transaction rate

**Database Health:**
- Table sizes
- Index usage
- Cache hit ratio
- Deadlocks
- Row statistics (inserts, updates, deletes)

**BMI App Specific:**
- Total measurements count
- Measurements created per hour
- Average BMI values
- Database size growth

**Example Queries:**
```promql
# Active database connections
pg_stat_database_numbackends{datname="bmidb"}

# Cache hit ratio (should be >90%)
rate(pg_stat_database_blks_hit{datname="bmidb"}[5m]) / 
(rate(pg_stat_database_blks_hit{datname="bmidb"}[5m]) + 
 rate(pg_stat_database_blks_read{datname="bmidb"}[5m]))

# Queries per second
rate(pg_stat_database_xact_commit{datname="bmidb"}[5m])
```

### 3. Web Server Metrics (Nginx Exporter)

**Request Metrics:**
- Requests per second
- Response codes (2xx, 3xx, 4xx, 5xx)
- Request processing time
- Request size/response size

**Connection Metrics:**
- Active connections
- Reading/Writing/Waiting connections
- Accepted/Handled connections

**Endpoint Metrics:**
- `/api/measurements` request rate
- `/api/measurements/trends` latency
- Static file serving performance

**Example Queries:**
```promql
# Request rate
rate(nginx_http_requests_total[5m])

# 5xx error rate
rate(nginx_http_requests_total{status=~"5.."}[5m])

# Average response time
rate(nginx_http_request_duration_seconds_sum[5m]) / 
rate(nginx_http_request_duration_seconds_count[5m])
```

### 4. Application Metrics (PM2 + Custom Exporter)

**Process Health:**
- Process status (online/stopped/errored)
- CPU usage per process
- Memory usage per process
- Restart count
- Uptime

**API Performance:**
- Request duration by endpoint
- Request rate by endpoint
- Error rate by endpoint
- Active requests

**Business Metrics:**
- Total measurements created
- BMI calculations performed
- Average BMI value
- Users active (if multi-user)
- Database query latency

**Example Custom Metrics:**
```promql
# API request duration (95th percentile)
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket{endpoint="/api/measurements"}[5m]))

# Measurement creation rate
rate(bmi_measurements_created_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / 
rate(http_requests_total[5m])
```

### 5. Log Collection (Loki + Promtail)

**Application Logs:**
- PM2 backend logs (out.log, err.log)
- Backend console logs
- Request/response logs

**Web Server Logs:**
- Nginx access logs
- Nginx error logs

**System Logs:**
- Syslog
- Authentication logs
- PostgreSQL logs

**Log Queries (LogQL):**
```logql
# All backend errors in last hour
{job="bmi-backend"} |= "error" | json

# Failed API requests
{job="nginx"} | json | status >= 500

# Database connection errors
{job="postgresql"} |= "connection" |= "failed"

# Top 10 API endpoints by request count
topk(10, sum by (path) (rate({job="nginx"}[5m])))
```

---

## 🚀 Quick Start

### Prerequisites

1. **Two EC2 Instances:**
   - Application Server (already running BMI app)
   - Monitoring Server (new t2.small or better)

2. **Network Configuration:**
   - Both servers in same VPC/subnet (**use private IPs**)
   - Security groups allowing traffic between servers on ports:
     - 9100, 9187, 9113, 9091 (exporters: app → monitoring)
     - 3100 (Loki: app → monitoring)
   - Monitoring server Grafana (port 3000) accessible from your IP
   
   **Private IP Communication:**
   - Monitoring pulls metrics from app server via private IP
   - App server sends logs to monitoring via private IP
   - Keeps all monitoring traffic within VPC (secure & fast)

### Installation Steps

Follow the detailed guide in [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for complete setup instructions.

**TL;DR:**
```bash
# On Monitoring Server
cd /tmp
git clone https://github.com/sarowar-dev-ops/single-server-3tier-webapp-monitoring.git
cd single-server-3tier-webapp-monitoring/monitoring/scripts
sudo bash setup-monitoring-server.sh

# On Application Server
cd /tmp
git clone https://github.com/sarowar-dev-ops/single-server-3tier-webapp-monitoring.git
cd single-server-3tier-webapp-monitoring/monitoring/scripts
sudo bash setup-application-exporters.sh
```

---

## 🔐 Access Information

### Default Credentials

| Service | URL | Username | Default Password |
|---------|-----|----------|------------------|
| **Grafana** | http://monitoring-server-ip:3000 | admin | admin |
| **Prometheus** | http://monitoring-server-ip:9090 | - | - |
| **AlertManager** | http://monitoring-server-ip:9093 | - | - |

⚠️ **Security Note:** Change Grafana admin password immediately after first login!

### Firewall Rules Required

**Monitoring Server Inbound:**
- Port 3000 (Grafana) - Your IP only
- Port 9090 (Prometheus) - Your IP only
- Port 3100 (Loki) - Application server IP
- Port 9093 (AlertManager) - Your IP only

**Application Server Outbound:**
- All exporters accessible to Monitoring server IP only

---

## 📈 Available Dashboards

### 1. System Overview Dashboard
**File:** `grafana/dashboards/system-overview.json`  
**Panels:**
- CPU usage by core
- Memory usage (used/cached/free)
- Disk I/O and space
- Network throughput
- System load
- Top processes

### 2. Application Performance Dashboard
**File:** `grafana/dashboards/application-performance.json`  
**Panels:**
- API request rate
- Response time percentiles (p50, p95, p99)
- Error rate by endpoint
- Active connections
- PM2 process health
- Request/response size

### 3. Database Dashboard
**File:** `grafana/dashboards/database-performance.json`  
**Panels:**
- Active connections
- Query duration
- Cache hit ratio
- Table sizes
- Transaction rate
- Slow queries
- Deadlocks
- BMI measurements count

### 4. Web Server Dashboard
**File:** `grafana/dashboards/nginx-performance.json`  
**Panels:**
- Requests per second
- Response codes distribution
- Active connections
- Request processing time
- Top endpoints by traffic
- Geographic distribution (if GeoIP enabled)

### 5. Business Metrics Dashboard
**File:** `grafana/dashboards/business-metrics.json`  
**Panels:**
- Measurements created per hour/day
- Average BMI trend
- BMI category distribution
- Activity level distribution
- User engagement metrics
- Data growth rate

### 6. Logs Dashboard
**File:** `grafana/dashboards/logs-viewer.json`  
**Panels:**
- Live log stream
- Error logs
- API request logs
- Database logs
- Log volume over time
- Top error messages

### 7. Alerts Dashboard
**Panels:**
- Active alerts
- Alert history
- Alert frequency
- Mean time to resolution

---

## 🔔 Alerting

### Pre-configured Alerts

#### Critical Alerts (Immediate Action)

1. **Instance Down**
   - Trigger: Server unreachable for 1 minute
   - Action: Check server status, restart if needed

2. **High CPU Usage**
   - Trigger: CPU >90% for 5 minutes
   - Action: Investigate processes, scale up if needed

3. **High Memory Usage**
   - Trigger: Memory >90% for 5 minutes
   - Action: Check for memory leaks, restart services

4. **Disk Space Critical**
   - Trigger: Disk >90% full
   - Action: Clean logs, expand volume

5. **Database Down**
   - Trigger: PostgreSQL not responding
   - Action: Restart PostgreSQL, check logs

6. **Backend Down**
   - Trigger: PM2 process stopped
   - Action: Restart with PM2, check logs

#### Warning Alerts (Monitor Closely)

1. **High API Error Rate**
   - Trigger: >5% requests returning 5xx errors for 5 minutes

2. **Slow API Responses**
   - Trigger: p95 latency >1 second for 5 minutes

3. **Database Connection Pool Exhausted**
   - Trigger: >80% connections used

4. **High Disk I/O Wait**
   - Trigger: I/O wait >30% for 5 minutes

5. **SSL Certificate Expiring**
   - Trigger: Certificate expires in <30 days

### Alert Channels

Configure in `alertmanager/alertmanager.yml`:
- Email notifications
- Slack webhooks
- PagerDuty integration
- SMS via Twilio
- Discord webhooks

---

## 💰 Cost Estimation

### AWS EC2 Costs (us-east-1, January 2026)

**Monitoring Server:**
- Instance: t2.small (2 vCPU, 2GB RAM)
- Cost: ~$17/month
- Storage: 100GB GP3 EBS (~$8/month)
- **Total: ~$25/month**

**Network Transfer:**
- Metrics scraping: ~5GB/month (<$1)
- Log shipping: ~10GB/month (<$1)
- **Total: ~$2/month**

**Grand Total: ~$27/month**

### Cost Optimization Tips

1. **Use Reserved Instances:** Save 30-40% with 1-year commitment
2. **Right-size Storage:** Start with 50GB, expand as needed
3. **Configure Log Retention:** Keep logs for 30 days instead of forever
4. **Optimize Scrape Interval:** Use 30s instead of 15s if acceptable

---

## 🔧 Troubleshooting

### Prometheus Not Scraping Targets

**Symptoms:**
- Targets show as "down" in Prometheus UI
- No metrics appearing in Grafana

**Check:**
```bash
# On monitoring server
curl http://application-server-ip:9100/metrics  # Node Exporter
curl http://application-server-ip:9187/metrics  # PostgreSQL Exporter
curl http://application-server-ip:9113/metrics  # Nginx Exporter

# Check Prometheus logs
sudo journalctl -u prometheus -f
```

**Fix:**
- Verify security group rules
- Check exporter service status
- Verify prometheus.yml configuration

### Grafana Not Showing Data

**Symptoms:**
- Dashboards load but show "No Data"
- Queries return empty results

**Check:**
```bash
# Test Prometheus data source
curl http://localhost:9090/api/v1/query?query=up

# Check Grafana logs
sudo journalctl -u grafana-server -f
```

**Fix:**
- Verify Prometheus data source configuration in Grafana
- Check time range in dashboard
- Verify metrics exist in Prometheus

### Logs Not Appearing in Loki

**Symptoms:**
- Logs dashboard shows no data
- Promtail not shipping logs

**Check:**
```bash
# On application server
sudo systemctl status promtail
sudo journalctl -u promtail -f

# Test Loki connectivity
curl http://monitoring-server-ip:3100/ready
```

**Fix:**
- Verify Promtail configuration
- Check file paths in promtail.yml
- Ensure log files are readable by promtail user

### High Memory Usage on Monitoring Server

**Symptoms:**
- Prometheus using >1.5GB RAM
- System swapping to disk

**Fix:**
```bash
# Reduce retention time
vim /etc/prometheus/prometheus.yml
# Change: --storage.tsdb.retention.time=15d (instead of 30d)

# Reduce scrape interval
# Change: scrape_interval: 30s (instead of 15s)

# Restart Prometheus
sudo systemctl restart prometheus
```

---

## 📚 Learn More

### Prometheus
- [Official Documentation](https://prometheus.io/docs/)
- [Query Language (PromQL)](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Best Practices](https://prometheus.io/docs/practices/)

### Grafana
- [Getting Started](https://grafana.com/docs/grafana/latest/getting-started/)
- [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [Alerting Guide](https://grafana.com/docs/grafana/latest/alerting/)

### Loki
- [Official Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Query Language](https://grafana.com/docs/loki/latest/logql/)

### Exporters
- [Node Exporter](https://github.com/prometheus/node_exporter)
- [PostgreSQL Exporter](https://github.com/prometheus-community/postgres_exporter)
- [Nginx Exporter](https://github.com/nginxinc/nginx-prometheus-exporter)

---

## 🎯 Next Steps

After setting up monitoring:

1. ✅ Verify all targets are UP in Prometheus
2. ✅ Import all Grafana dashboards
3. ✅ Configure alert notifications
4. ✅ Test alerts by triggering conditions
5. ✅ Set up regular backup of Prometheus data
6. ✅ Document your alert runbooks
7. ✅ Train team on dashboard usage

---

## 📝 Monitoring Checklist

- [ ] Monitoring server provisioned and accessible
- [ ] Prometheus installed and running
- [ ] Grafana installed and accessible
- [ ] Loki installed for log aggregation
- [ ] AlertManager configured
- [ ] Node Exporter on application server
- [ ] PostgreSQL Exporter configured
- [ ] Nginx Exporter set up
- [ ] Custom app exporter deployed
- [ ] Promtail shipping logs
- [ ] All dashboards imported
- [ ] Alert rules configured
- [ ] Notification channels tested
- [ ] Documentation reviewed
- [ ] Team trained on tools

---

**🎉 Happy Monitoring!**

For detailed implementation steps, see [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)

Last Updated: January 1, 2026
