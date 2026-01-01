# BMI Health Tracker - Monitoring Infrastructure Guide

> **Target Audience:** Aspiring DevOps Engineers  
> **Purpose:** Complete guide to understanding and implementing production-grade monitoring

---

## 📋 Table of Contents

1. [What is Monitoring & Why It Matters](#1-what-is-monitoring--why-it-matters)
2. [Monitoring Tools Overview](#2-monitoring-tools-overview)
3. [Tools in Our Three-Tier Architecture](#3-tools-in-our-three-tier-architecture)
4. [Detailed Tool Configuration](#4-detailed-tool-configuration)
5. [DevOps Concepts Explained](#5-devops-concepts-explained)

---

## 1. What is Monitoring & Why It Matters

### What is Monitoring?

**Monitoring** is the practice of continuously observing and collecting data about your systems, applications, and infrastructure to:
- Track performance and health
- Detect problems before users notice
- Understand usage patterns and trends
- Make informed decisions about scaling and optimization
- Meet SLAs (Service Level Agreements)

Think of it like the dashboard in your car - you need to see:
- **Speed** (performance metrics)
- **Fuel level** (resource utilization)
- **Warning lights** (alerts)
- **Trip computer** (historical data)

### Why is Monitoring Critical?

#### 1. **Prevent Downtime** 💰
- Average cost of downtime: **$5,600 per minute** for enterprise
- Early detection saves money and reputation
- Example: Get alerted when disk space reaches 85% before it hits 100%

#### 2. **User Experience** 👥
- Users expect < 3 second page load times
- 53% of users abandon slow websites
- Monitoring helps maintain fast response times

#### 3. **Capacity Planning** 📊
- Know when to scale up/down
- Optimize costs by right-sizing resources
- Predict future growth needs

#### 4. **Troubleshooting** 🔍
- Quickly identify root cause of issues
- Reduce MTTR (Mean Time To Resolution)
- Understand what happened during incidents

#### 5. **Security** 🔒
- Detect unusual traffic patterns
- Monitor failed login attempts
- Track unauthorized access

#### 6. **Compliance** 📋
- Audit trails for regulations (GDPR, HIPAA, SOC2)
- Performance SLA reporting
- Data retention requirements

### Monitoring in DevOps Culture

In traditional IT:
```
Development → QA → Operations (monitors in production)
```

In DevOps:
```
Development + Operations = Continuous Monitoring
(Monitoring starts from development, not after deployment)
```

**Key DevOps Monitoring Principles:**
- **Shift-Left Monitoring:** Test monitoring in development
- **Observable by Design:** Build apps with monitoring in mind
- **Automate Everything:** No manual log checking
- **Actionable Alerts:** Every alert needs an action
- **Blameless Culture:** Metrics for learning, not punishment

### The Three Pillars of Observability

Modern monitoring goes beyond simple uptime checks. It includes three pillars:

```
┌─────────────────────────────────────────┐
│          OBSERVABILITY                  │
├─────────────────────────────────────────┤
│                                         │
│  📊 METRICS      📝 LOGS      🔗 TRACES │
│  (Numbers)       (Events)     (Flows)   │
│                                         │
│  • CPU: 75%      • Error 500  • Request │
│  • Memory: 4GB   • User login • Journey │
│  • Requests/s    • SQL query  • Latency │
│                                         │
└─────────────────────────────────────────┘
```

**Metrics:** Aggregated numerical data over time
- "What is happening?"
- Example: CPU usage is 80%

**Logs:** Detailed event records
- "Why did it happen?"
- Example: Application crashed due to OutOfMemoryError

**Traces:** Request flow through distributed systems
- "Where did it happen?"
- Example: API call took 2.3s (0.5s in app, 1.8s in database)

### What Happens Without Monitoring?

**Real-World Disaster Scenarios:**

❌ **Scenario 1: Silent Failures**
```
Website appears up → Actually serving 500 errors → Users leaving → Revenue loss
```
Without monitoring: You only know when sales team reports "no orders today"

✅ **With Monitoring:**
```
Error rate spike → Alert in 30 seconds → Team investigates → Fixed in 5 minutes
```

❌ **Scenario 2: Slow Death**
```
Memory leak → Gradual slowdown → Eventually crashes → Users affected for hours
```
Without monitoring: "Server just randomly crashes sometimes"

✅ **With Monitoring:**
```
Memory trend shows leak → Alert before crash → Deploy fix → Zero downtime
```

❌ **Scenario 3: Capacity Crisis**
```
Traffic grows → Server maxed out → Can't handle Black Friday traffic → Lost sales
```
Without monitoring: "We just need bigger servers" (expensive guessing)

✅ **With Monitoring:**
```
Historical data → Forecast growth → Plan scaling → Smooth Black Friday
```

### Monitoring vs Logging vs Debugging

| Aspect | Monitoring | Logging | Debugging |
|--------|-----------|---------|-----------|
| **When** | Continuously (24/7) | Continuously (24/7) | During incidents |
| **Purpose** | Track health & performance | Record events & errors | Find root cause |
| **Data Volume** | Low (aggregated) | Medium to High | N/A |
| **Retention** | Long-term (months) | Short to medium (days/weeks) | N/A |
| **Cost** | Low | Medium to High | Developer time |
| **Example** | "CPU is at 80%" | "OutOfMemoryError at line 42" | Stepping through code |

### ROI of Monitoring

**Costs:**
- Infrastructure: ~$50-200/month for small-medium app
- Tools: $0 (open-source) to $500+/month (commercial)
- Setup time: 1-2 days initial, ongoing maintenance

**Returns:**
- Prevent one major outage: **$10,000 - $100,000+** saved
- Reduce troubleshooting time: **50-80%** faster resolution
- Optimize resources: **20-40%** cost savings
- Improve user satisfaction: **Better retention & revenue**

**Example:**
```
Cost: $100/month monitoring
Prevented: 1 hour downtime/month = $5,600 saved
ROI: 5,500% return on investment
```

---

## 2. Monitoring Tools Overview

This section introduces the monitoring tools in our stack and explains their **general purpose** in any IT environment.

### 🔧 Core Monitoring Tools

#### 1. **Prometheus** - Metrics Collection & Storage
![Type: Time-Series Database]

**What it does (General):**
- Collects numerical metrics (CPU, memory, requests/sec, etc.)
- Stores data efficiently in time-series format
- Provides powerful query language (PromQL)
- Evaluates alerting rules
- Scrapes metrics from targets via HTTP

**Think of it as:** A continuous data recorder that pulls numbers every few seconds

**Responsibility:**
- ✅ Metric collection
- ✅ Metric storage
- ✅ Metric querying
- ✅ Alert triggering
- ❌ NOT for logs or traces
- ❌ NOT for visualization (uses Grafana for that)

**Industry Usage:**
- Used by: Google, DigitalOcean, SoundCloud (creator)
- Alternative to: Nagios, Zabbix, DataDog (commercial)

---

#### 2. **Grafana** - Visualization Platform
![Type: Dashboard & Analytics]

**What it does (General):**
- Creates beautiful, interactive dashboards
- Connects to multiple data sources (Prometheus, Loki, MySQL, etc.)
- Provides templated dashboards
- User management and access control
- Annotations and alerts visualization

**Think of it as:** A universal TV screen that can display data from any channel

**Responsibility:**
- ✅ Data visualization
- ✅ Dashboard creation
- ✅ User interface
- ✅ Multi-datasource queries
- ❌ NOT for data storage
- ❌ NOT for data collection

**Industry Usage:**
- Used by: PayPal, eBay, Bloomberg
- Alternative to: Kibana, DataDog UI, New Relic

---

#### 3. **Loki** - Log Aggregation System
![Type: Log Management]

**What it does (General):**
- Collects and indexes logs from multiple sources
- Stores log data efficiently (indexes labels, not content)
- Provides LogQL for querying logs
- Integrates seamlessly with Grafana
- Cost-effective log storage

**Think of it as:** A library that organizes books (logs) by tags, not by reading every page

**Responsibility:**
- ✅ Log aggregation
- ✅ Log storage
- ✅ Log querying
- ✅ Label-based indexing
- ❌ NOT for metrics
- ❌ NOT for full-text search (by design)

**Industry Usage:**
- Created by: Grafana Labs
- Alternative to: Elasticsearch/ELK, Splunk, CloudWatch Logs

---

#### 4. **AlertManager** - Alert Management & Notification
![Type: Alert Routing]

**What it does (General):**
- Receives alerts from Prometheus
- Groups and deduplicates similar alerts
- Routes alerts to different channels (email, Slack, PagerDuty)
- Silences alerts during maintenance
- Manages alert inhibition rules

**Think of it as:** A smart notification center that decides who to notify and when

**Responsibility:**
- ✅ Alert routing
- ✅ Alert grouping
- ✅ Notification delivery
- ✅ Alert silencing
- ❌ NOT for creating alerts (Prometheus does that)
- ❌ NOT for visualizing alerts (Grafana does that)

**Industry Usage:**
- Part of: Prometheus ecosystem
- Alternative to: PagerDuty (commercial), Opsgenie, VictorOps

---

### 📡 Exporters - Metric Collectors

Exporters are small programs that expose metrics in Prometheus format.

#### 5. **Node Exporter** - System Metrics
![Type: Hardware & OS Metrics]

**What it does (General):**
- Monitors CPU usage, load average
- Tracks memory and swap usage
- Reports disk space and I/O
- Network traffic statistics
- System uptime and processes

**Think of it as:** A health monitor that checks vital signs of your server

**Metrics Example:**
```
CPU: 75% used
Memory: 3.2GB / 4GB
Disk: 45% used
Network: 15 Mbps in, 8 Mbps out
```

**Responsibility:**
- ✅ Hardware metrics
- ✅ OS-level metrics
- ✅ Filesystem metrics
- ❌ NOT for application metrics

---

#### 6. **PostgreSQL Exporter** - Database Metrics
![Type: Database Monitoring]

**What it does (General):**
- Monitors database connections
- Tracks query performance
- Reports transaction rates
- Measures cache hit ratios
- Table and index sizes

**Think of it as:** A database performance analyzer

**Metrics Example:**
```
Active connections: 23
Queries/sec: 145
Cache hit ratio: 98.5%
Deadlocks: 0
```

**Responsibility:**
- ✅ Database health
- ✅ Query performance
- ✅ Connection pooling
- ❌ NOT for query logs (use Loki)

---

#### 7. **Nginx Exporter** - Web Server Metrics
![Type: Web Server Monitoring]

**What it does (General):**
- Tracks HTTP requests
- Monitors active connections
- Reports response status codes
- Measures bandwidth usage

**Think of it as:** A web traffic analyzer

**Metrics Example:**
```
Requests/sec: 250
Active connections: 45
2xx responses: 95%
5xx errors: 0.5%
```

**Responsibility:**
- ✅ HTTP traffic metrics
- ✅ Connection states
- ✅ Response codes
- ❌ NOT for access logs (use Loki)

---

#### 8. **Custom Application Exporter** - Business Metrics
![Type: Application-Specific]

**What it does (General):**
- Exposes application-specific metrics
- Business KPIs (orders, signups, revenue)
- Application health checks
- Custom performance metrics

**Think of it as:** Your app's personal reporter

**Metrics Example:**
```
Orders today: 1,234
Revenue: $45,678
Active users: 567
Cart abandonment: 23%
```

**Responsibility:**
- ✅ Business metrics
- ✅ Application KPIs
- ✅ Custom logic
- ✅ Health endpoints

---

### 📤 Log Shippers

#### 9. **Promtail** - Log Forwarder
![Type: Log Collection Agent]

**What it does (General):**
- Tails log files continuously
- Adds labels to logs (hostname, app name)
- Forwards logs to Loki
- Handles log parsing and filtering

**Think of it as:** A mail carrier that picks up logs and delivers to Loki

**Responsibility:**
- ✅ Log file tailing
- ✅ Log labeling
- ✅ Push to Loki
- ❌ NOT for log storage
- ❌ NOT for log analysis

---

### Tool Categories Summary

```
┌─────────────────────────────────────────────────┐
│          MONITORING STACK                       │
├─────────────────────────────────────────────────┤
│                                                 │
│  📊 METRICS LAYER                               │
│    • Prometheus (collect & store)               │
│    • Node Exporter (system)                     │
│    • PostgreSQL Exporter (database)             │
│    • Nginx Exporter (web server)                │
│    • Custom Exporter (application)              │
│                                                 │
│  📝 LOGS LAYER                                  │
│    • Loki (collect & store)                     │
│    • Promtail (forward)                         │
│                                                 │
│  🎨 VISUALIZATION LAYER                         │
│    • Grafana (dashboards)                       │
│                                                 │
│  🚨 ALERTING LAYER                              │
│    • AlertManager (notifications)               │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 3. Tools in Our Three-Tier Architecture

Now let's see **exactly** what each tool monitors in our BMI Health Tracker application.

### 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONITORING SERVER                            │
│                  (Dedicated EC2 Instance)                       │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐           │
│  │ Prometheus  │  │   Grafana   │  │    Loki     │           │
│  │   :9090     │  │    :3000    │  │   :3100     │           │
│  │             │  │             │  │             │           │
│  │ • Scrapes   │  │ • Queries   │  │ • Receives  │           │
│  │   metrics   │  │   Prom/Loki │  │   logs from │           │
│  │ • Evaluates │  │ • Shows     │  │   Promtail  │           │
│  │   alerts    │  │   dashboards│  │ • Indexes   │           │
│  └──────┬──────┘  └─────────────┘  └──────▲──────┘           │
│         │                                   │                  │
│  ┌──────▼──────┐  ┌─────────────┐         │                  │
│  │AlertManager │  │ Node Exp    │         │                  │
│  │   :9093     │  │   :9100     │         │                  │
│  │             │  │             │         │                  │
│  │ • Routes    │  │ • Self      │         │                  │
│  │   alerts    │  │   monitor   │         │                  │
│  └─────────────┘  └─────────────┘         │                  │
└────────────────────────────────────────────┼──────────────────┘
                                             │
                    Scrape Metrics (Pull)    │
                    Push Logs (Push)         │
                                             │
┌────────────────────────────────────────────┼──────────────────┐
│                    APPLICATION SERVER       │                  │
│                   (BMI Health Tracker)      │                  │
│                                             │                  │
│  ┌─────────────────────────────────────────┼──────────┐      │
│  │         THREE-TIER APPLICATION          │          │      │
│  │                                          │          │      │
│  │  [Frontend: React + Vite]                         │      │
│  │         ↕                                          │      │
│  │  [Backend: Node.js + Express]  ←─────┐            │      │
│  │         ↕                             │            │      │
│  │  [Database: PostgreSQL]               │            │      │
│  │                                       │            │      │
│  └───────────────────────────────────────┼────────────┘      │
│                                          │                   │
│  ┌──────────────────────────────────────┼────────────┐      │
│  │         MONITORING EXPORTERS         │            │      │
│  │                                       │            │      │
│  │  Node Exporter (:9100) ──────────────┼────────────┤      │
│  │  • Monitors: Server CPU, RAM, Disk   │ Scraped by │      │
│  │                                       │ Prometheus │      │
│  │  PostgreSQL Exporter (:9187) ────────┼────────────┤      │
│  │  • Monitors: Database performance    │            │      │
│  │                                       │            │      │
│  │  Nginx Exporter (:9113) ─────────────┼────────────┤      │
│  │  • Monitors: Web traffic, requests   │            │      │
│  │                                       │            │      │
│  │  BMI Custom Exporter (:9091) ────────┼────────────┘      │
│  │  • Monitors: App-specific metrics               │      │
│  │    (measurements, BMI calculations)              │      │
│  └─────────────────────────────────────────────────┘      │
│                                                            │
│  ┌─────────────────────────────────────────────────┐      │
│  │         LOG COLLECTION                          │      │
│  │                                                  │      │
│  │  Promtail (:9080) ──────────────────────────────┼──────┘
│  │  • Tails: Nginx access/error logs              │
│  │  • Tails: PostgreSQL logs                      │
│  │  • Tails: System logs (/var/log/syslog)       │
│  │  • Pushes to: Loki on monitoring server       │
│  └────────────────────────────────────────────────┘
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 📊 What Each Tool Monitors in BMI App

#### **Monitoring Server Tools**

##### 1. Prometheus - The Data Hub
**What it monitors:**
```
✓ All 4 exporters on application server
✓ Its own health
✓ Node Exporter on monitoring server (self-monitoring)
```

**Configuration (`prometheus.yml`):**
```yaml
scrape_configs:
  # Application Server Targets
  - job_name: 'node_exporter'
    targets: ['10.0.2.115:9100']  # System metrics
  
  - job_name: 'postgresql'
    targets: ['10.0.2.115:9187']  # Database metrics
  
  - job_name: 'nginx'
    targets: ['10.0.2.115:9113']  # Web server metrics
  
  - job_name: 'bmi-backend'
    targets: ['10.0.2.115:9091']  # Application metrics
```

**Alert Rules:**
```yaml
- alert: HighCPUUsage
  expr: cpu_usage > 80
  for: 10m
  
- alert: DiskSpaceLow
  expr: disk_usage > 85
  for: 5m
  
- alert: InstanceDown
  expr: up == 0
  for: 5m
```

**What it tracks specifically:**
- Is each exporter responding? (up/down)
- How many metrics are being collected?
- Storage space used by TSDB
- Scrape duration and errors

---

##### 2. Grafana - The Dashboard
**What it displays:**

**System Dashboard (via Node Exporter):**
- CPU usage per core
- Memory usage (used/free/cached)
- Disk space on root partition
- Network traffic (bytes in/out)
- System load average

**Database Dashboard (via PostgreSQL Exporter):**
- Active database connections
- Queries per second
- Transaction commit rate
- Table sizes for `measurements` table
- Cache hit ratio
- Deadlocks

**Web Server Dashboard (via Nginx Exporter):**
- HTTP requests per second
- Response codes breakdown (2xx, 3xx, 4xx, 5xx)
- Active connections
- Bytes transferred

**Application Dashboard (via BMI Custom Exporter):**
- Total BMI measurements in database
- Measurements added today/this hour
- Average BMI value
- BMI category distribution:
  - Underweight: < 18.5
  - Normal: 18.5-24.9
  - Overweight: 25-29.9
  - Obese: ≥ 30
- Application health status
- Database connection pool stats

**Log Explorer (via Loki):**
- Nginx access logs (who accessed what)
- Nginx error logs (4xx/5xx errors)
- PostgreSQL query logs
- System logs

---

##### 3. Loki - The Log Store
**What it stores:**

**From Application Server:**
```
📝 Nginx Access Logs:
   192.168.1.1 - GET /api/measurements 200 - 0.234s
   10.0.2.45 - POST /api/measurements 201 - 0.456s

📝 Nginx Error Logs:
   [error] Connection to upstream failed
   [warn] Rate limiting applied to 1.2.3.4

📝 PostgreSQL Logs:
   LOG: duration: 12.345 ms statement: SELECT * FROM measurements
   ERROR: duplicate key value violates unique constraint

📝 System Logs:
   systemd[1]: Started BMI Backend Service
   kernel: Out of memory: Kill process 1234
```

**Organization:**
- Indexed by labels: `{job="nginx", host="app-server", type="access"}`
- Queryable by time range
- Retention: 7 days

---

##### 4. AlertManager - The Notification Manager
**What it handles:**

**Critical Alerts (immediate notification):**
- Application server down
- Database connection failures
- Disk space critical (>95%)
- Memory exhausted

**Warning Alerts (batched notification):**
- High CPU usage (>80%)
- High memory usage (>85%)
- Slow database queries
- Error rate increased

**Routing:**
```yaml
routes:
  - severity: critical
    receiver: pagerduty  # Wake up on-call engineer
  
  - severity: warning
    receiver: slack      # Notify team channel
```

---

#### **Application Server Tools**

##### 5. Node Exporter - OS Metrics
**Monitoring the BMI application server itself:**

**CPU Metrics:**
```
• CPU idle time per core
• System vs user CPU time
• I/O wait time
```

**Memory Metrics:**
```
• Total memory: 4GB
• Used memory: 2.1GB
• Free memory: 1.9GB
• Cached: 1.2GB
• Swap usage: 0MB
```

**Disk Metrics:**
```
• Disk space on /: 15GB / 30GB (50% used)
• Disk I/O operations per second
• Read/write bytes
```

**Network Metrics:**
```
• eth0 receive: 15 Mbps
• eth0 transmit: 8 Mbps
• Packets dropped: 0
• Errors: 0
```

---

##### 6. PostgreSQL Exporter - Database Metrics
**Monitoring the `bmi_tracker` database:**

**Connection Metrics:**
```
• Total connections: 10
• Active queries: 3
• Idle connections: 7
• Max connections: 100
```

**Performance Metrics:**
```
• Transactions per second: 45
• Rows fetched per second: 1,234
• Rows inserted per second: 23
• Cache hit ratio: 99.2%
```

**Table-Specific:**
```
measurements table:
  • Total rows: 15,432
  • Table size: 3.2 MB
  • Index size: 1.1 MB
  • Sequential scans: 12
  • Index scans: 45,678
```

**Slow Queries:**
```
• Queries > 1 second: 2 (in last hour)
• Deadlocks: 0
• Locks waiting: 0
```

---

##### 7. Nginx Exporter - Web Traffic Metrics
**Monitoring Nginx serving the BMI frontend:**

**Request Metrics:**
```
• Requests/second: 45
• Total requests today: 123,456
```

**Status Codes:**
```
• 2xx (Success): 95.2%
• 3xx (Redirect): 2.1%
• 4xx (Client Error): 2.5%
• 5xx (Server Error): 0.2%
```

**Connection Metrics:**
```
• Active connections: 23
• Reading: 5
• Writing: 12
• Waiting (keep-alive): 6
```

**Upstream (Backend) Metrics:**
```
• Backend response time: 234ms avg
• Backend errors: 0
```

---

##### 8. BMI Custom Exporter - Application Metrics
**Monitoring BMI-specific business logic:**

**User Activity:**
```
bmi_measurements_total: 15,432
  • All-time measurements in database

bmi_measurements_created_24h: 234
  • New measurements today

bmi_measurements_created_1h: 12
  • New measurements this hour
```

**BMI Analytics:**
```
bmi_average_value: 24.3
  • Average BMI across all users

bmi_category_count:
  • underweight: 1,234 (8%)
  • normal: 8,456 (55%)
  • overweight: 4,123 (27%)
  • obese: 1,619 (10%)
```

**Application Health:**
```
bmi_app_healthy: 1
  • 1 = healthy, 0 = unhealthy

bmi_db_pool_total: 10
  • Database connection pool size

bmi_db_pool_idle: 7
  • Idle database connections

bmi_database_size_bytes: 3,356,672
  • Total database size (3.2 MB)
```

**Custom Code (exporter.js):**
```javascript
// Collects data from PostgreSQL
const totalResult = await pool.query('SELECT COUNT(*) FROM measurements');
totalMeasurements.set(parseInt(totalResult.rows[0].count));

// Calculates BMI distribution
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
```

---

##### 9. Promtail - Log Collector
**Tailing logs from BMI application components:**

**Nginx Logs:**
```yaml
- job_name: nginx_access
  static_configs:
    - targets: [localhost]
      labels:
        job: nginx
        type: access
        host: bmi-app-server
      __path__: /var/log/nginx/access.log

- job_name: nginx_error
  static_configs:
    - targets: [localhost]
      labels:
        job: nginx
        type: error
        host: bmi-app-server
      __path__: /var/log/nginx/error.log
```

**What it captures:**
```
Access log: Who used the BMI calculator?
10.0.1.45 - POST /api/measurements {"weight": 70, "height": 175}
10.0.1.46 - GET /api/measurements?limit=10

Error log: What went wrong?
[error] upstream timed out (110: Connection timed out)
[warn] 1024 worker_connections are not enough
```

**PostgreSQL Logs:**
```yaml
- job_name: postgresql
  static_configs:
    - targets: [localhost]
      labels:
        job: postgresql
        host: bmi-app-server
      __path__: /var/log/postgresql/*.log
```

**System Logs:**
```yaml
- job_name: system
  static_configs:
    - targets: [localhost]
      labels:
        job: syslog
        host: bmi-app-server
      __path__: /var/log/syslog
```

---

### 🎯 Complete Monitoring Coverage

```
BMI Health Tracker Application
├── Infrastructure Layer
│   └── Node Exporter monitors:
│       • CPU, Memory, Disk, Network
│
├── Database Layer
│   └── PostgreSQL Exporter monitors:
│       • Connections, Queries, Performance
│
├── Web Server Layer
│   └── Nginx Exporter monitors:
│       • HTTP requests, Status codes, Connections
│
├── Application Layer
│   └── BMI Custom Exporter monitors:
│       • Measurements count, BMI analytics, Health
│
└── Logging Layer
    └── Promtail collects:
        • Access logs, Error logs, Database logs
```

**Nothing is unmonitored!** Every layer of the three-tier architecture has dedicated monitoring.
- **Version:** 2.48.0
- **Purpose:** Time-series database that collects and stores metrics
- **Port:** 9090
- **What it does:**
  - Scrapes metrics from exporters every 15 seconds
  - Evaluates alerting rules
  - Stores data in TSDB (Time Series Database)
  - Provides HTTP API for queries

#### 2. **Grafana** (Visualization Platform)
- **Version:** Latest (from apt repository)
- **Purpose:** Dashboards and visualization
- **Port:** 3000
- **What it does:**
  - Connects to Prometheus as datasource
  - Connects to Loki for logs
  - Creates interactive dashboards
  - User authentication and management

#### 3. **Loki** (Log Aggregation)
- **Version:** 2.9.3
- **Purpose:** Log aggregation and indexing
- **Port:** 3100 (HTTP), 9096 (gRPC)
- **What it does:**
  - Receives logs from Promtail agents
  - Indexes logs efficiently (indexes metadata, not content)
  - Stores logs in filesystem or object storage
  - Provides query API for Grafana

#### 4. **AlertManager** (Alert Routing)
- **Version:** 0.26.0
- **Purpose:** Alert management and notification routing
- **Port:** 9093
- **What it does:**
  - Receives alerts from Prometheus
  - Groups and deduplicates alerts
  - Routes to notification channels (email, Slack, etc.)
  - Manages alert silences and inhibitions

#### 5. **Node Exporter** (System Metrics)
- **Version:** 1.7.0
- **Purpose:** Exposes hardware and OS metrics
- **Port:** 9100
- **What it does:**
  - Monitors CPU, memory, disk, network
  - Exposes metrics in Prometheus format
  - Runs as systemd service

---

### On Application Server

#### 1. **Node Exporter** (System Metrics)
- **Version:** 1.7.0
- **Port:** 9100
- **Metrics exposed:** 
  - CPU usage by core
  - Memory (used, free, cached)
  - Disk space and I/O
  - Network traffic

#### 2. **PostgreSQL Exporter** (Database Metrics)
- **Version:** 0.15.0
- **Port:** 9187
- **Metrics exposed:**
  - Database connections
  - Query performance
  - Transaction rates
  - Table sizes
  - Cache hit ratios

#### 3. **Nginx Exporter** (Web Server Metrics)
- **Version:** 0.11.0
- **Port:** 9113
- **Metrics exposed:**
  - Active connections
  - Requests per second
  - Response codes (2xx, 4xx, 5xx)
  - Bytes sent/received

#### 4. **BMI Custom Exporter** (Application Metrics)
- **Technology:** Node.js + Express + prom-client
- **Port:** 9091
- **Custom metrics:**
  - Total measurements count
  - Measurements in last 24h/1h
  - Average BMI value
  - BMI category distribution
  - Database size metrics
  - Connection pool stats

#### 5. **Promtail** (Log Shipper)
- **Version:** 2.9.3
- **Port:** 9080 (HTTP for status)
- **What it ships:**
  - System logs (`/var/log/syslog`)
  - Nginx access logs
  - Nginx error logs
  - PostgreSQL logs

---

---

## 4. Detailed Tool Configuration

This section provides **exact settings, APIs, and URLs** for each tool in our BMI monitoring project.

### 🔧 Monitoring Server Configuration

---

#### Prometheus Configuration

**Installation Location:**
- Binary: `/usr/local/bin/prometheus`
- Config: `/etc/prometheus/prometheus.yml`
- Data: `/var/lib/prometheus/`
- Service: `/etc/systemd/system/prometheus.service`

**Network Configuration:**
```bash
# Listen on all interfaces (accessible via IP)
--web.listen-address=0.0.0.0:9090
```

**Access URLs:**
- **Web UI:** `http://<PUBLIC_IP>:9090`
- **Private:** `http://10.0.14.162:9090`
- **Localhost:** `http://localhost:9090`

**API Endpoints:**

| Endpoint | Method | Purpose | Example Usage |
|----------|--------|---------|---------------|
| `/metrics` | GET | Prometheus own metrics | `curl http://localhost:9090/metrics` |
| `/api/v1/query` | POST/GET | Instant query | `curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=up'` |
| `/api/v1/query_range` | POST/GET | Range query (time-series) | `curl -G http://localhost:9090/api/v1/query_range --data-urlencode 'query=rate(requests[5m])' --data-urlencode 'start=2026-01-01T00:00:00Z' --data-urlencode 'end=2026-01-01T12:00:00Z' --data-urlencode 'step=15s'` |
| `/api/v1/targets` | GET | List scrape targets | `curl http://localhost:9090/api/v1/targets \| jq '.data.activeTargets[] \| {job: .labels.job, instance: .labels.instance, health: .health}'` |
| `/api/v1/alerts` | GET | Active alerts | `curl http://localhost:9090/api/v1/alerts` |
| `/api/v1/rules` | GET | Loaded alerting rules | `curl http://localhost:9090/api/v1/rules` |
| `/api/v1/label/<name>/values` | GET | List label values | `curl http://localhost:9090/api/v1/label/job/values` |
| `/api/v1/series` | POST/GET | Find time series | `curl -G http://localhost:9090/api/v1/series --data-urlencode 'match[]=up'` |
| `/-/reload` | POST | Reload configuration | `curl -X POST http://localhost:9090/-/reload` |
| `/-/healthy` | GET | Health check | `curl http://localhost:9090/-/healthy` |
| `/-/ready` | GET | Readiness check | `curl http://localhost:9090/-/ready` |

**Configuration File (`prometheus.yml`):**
```yaml
global:
  scrape_interval: 15s           # How often to scrape targets
  evaluation_interval: 15s       # How often to evaluate rules
  external_labels:
    cluster: 'bmi-health-tracker'
    environment: 'production'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        labels:
          role: 'monitoring'

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['10.0.2.115:9100']
        labels:
          server: 'bmi-app-server'
          role: 'application'

  - job_name: 'postgresql'
    static_configs:
      - targets: ['10.0.2.115:9187']
        labels:
          server: 'bmi-app-server'
          database: 'bmidb'

  - job_name: 'nginx'
    static_configs:
      - targets: ['10.0.2.115:9113']
        labels:
          server: 'bmi-app-server'
          role: 'webserver'

  - job_name: 'bmi-backend'
    static_configs:
      - targets: ['10.0.2.115:9091']
        labels:
          server: 'bmi-app-server'
          application: 'bmi-health-tracker'

  - job_name: 'node_exporter_monitoring'
    static_configs:
      - targets: ['localhost:9100']
        labels:
          server: 'monitoring-server'
          role: 'monitoring'
```

**Alert Rules (`alert_rules.yml`):**
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
          description: "{{ $labels.instance }} has been down for 5+ minutes"

      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "High CPU on {{ $labels.instance }}"

      - alert: HighMemoryUsage
        expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 85
        for: 10m
        labels:
          severity: warning

      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 15
        for: 5m
        labels:
          severity: critical
```

**Service Management:**
```bash
# Start/Stop/Restart
sudo systemctl start prometheus
sudo systemctl stop prometheus
sudo systemctl restart prometheus

# Status check
sudo systemctl status prometheus

# View logs
sudo journalctl -u prometheus -f

# Reload config without restart
curl -X POST http://localhost:9090/-/reload

# Validate config
promtool check config /etc/prometheus/prometheus.yml

# Validate rules
promtool check rules /etc/prometheus/alert_rules.yml
```

**Storage Settings:**
```bash
# Data retention: 15 days
--storage.tsdb.retention.time=15d

# Storage path
--storage.tsdb.path=/var/lib/prometheus/

# Check disk usage
du -sh /var/lib/prometheus/
```

---

#### Grafana Configuration

**Installation Location:**
- Config: `/etc/grafana/grafana.ini`
- Data: `/var/lib/grafana/`
- Plugins: `/var/lib/grafana/plugins/`
- Service: `/lib/systemd/system/grafana-server.service`

**Network Configuration:**
```ini
[server]
http_addr = 0.0.0.0    # Listen on all interfaces
http_port = 3000
domain = localhost
```

**Access URLs:**
- **Web UI:** `http://<PUBLIC_IP>:3000`
- **Private:** `http://10.0.14.162:3000`
- **Default Credentials:** `admin` / `admin` (change on first login)

**API Endpoints:**

| Endpoint | Method | Purpose | Example |
|----------|--------|---------|---------|
| `/api/health` | GET | Health check | `curl http://localhost:3000/api/health` |
| `/api/datasources` | GET | List datasources | `curl -u admin:admin http://localhost:3000/api/datasources` |
| `/api/datasources` | POST | Create datasource | See below |
| `/api/dashboards/db` | POST | Create dashboard | Import JSON |
| `/api/search` | GET | Search dashboards | `curl -u admin:admin http://localhost:3000/api/search` |
| `/api/annotations` | POST | Create annotation | Event marking |
| `/api/user` | GET | Current user info | `curl -u admin:admin http://localhost:3000/api/user` |
| `/api/org/users` | GET | List org users | `curl -u admin:admin http://localhost:3000/api/org/users` |

**Add Prometheus Datasource (via API):**
```bash
curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Prometheus",
    "type": "prometheus",
    "url": "http://localhost:9090",
    "access": "proxy",
    "isDefault": true,
    "basicAuth": false
  }'
```

**Add Loki Datasource (via API):**
```bash
curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Loki",
    "type": "loki",
    "url": "http://localhost:3100",
    "access": "proxy",
    "basicAuth": false
  }'
```

**Import Dashboard:**
```bash
# Via Dashboard ID (e.g., 1860 for Node Exporter Full)
# Go to: Dashboards → Import → Enter ID: 1860 → Select Prometheus datasource

# Via JSON file
curl -X POST http://admin:admin@localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dashboard.json
```

**Service Management:**
```bash
sudo systemctl start grafana-server
sudo systemctl stop grafana-server
sudo systemctl restart grafana-server
sudo systemctl status grafana-server
sudo journalctl -u grafana-server -f
```

**Configuration File Locations:**
```bash
# Main config
/etc/grafana/grafana.ini

# Datasources (provisioning)
/etc/grafana/provisioning/datasources/

# Dashboards (provisioning)
/etc/grafana/provisioning/dashboards/

# Plugins
/var/lib/grafana/plugins/

# Database (SQLite by default)
/var/lib/grafana/grafana.db
```

---

#### Loki Configuration

**Installation Location:**
- Binary: `/usr/local/bin/loki`
- Config: `/etc/loki/loki-config.yml`
- Data: `/var/lib/loki/`
- Service: `/etc/systemd/system/loki.service`

**Access URLs:**
- **HTTP API:** `http://<PUBLIC_IP>:3100`
- **Private:** `http://10.0.14.162:3100`
- **gRPC:** Port 9096

**API Endpoints:**

| Endpoint | Method | Purpose | Example |
|----------|--------|---------|---------|
| `/ready` | GET | Readiness check | `curl http://localhost:3100/ready` |
| `/metrics` | GET | Loki internal metrics | `curl http://localhost:3100/metrics` |
| `/loki/api/v1/push` | POST | Push logs (Promtail uses this) | Used internally |
| `/loki/api/v1/query` | GET | Instant log query | `curl -G http://localhost:3100/loki/api/v1/query --data-urlencode 'query={job="nginx"}'` |
| `/loki/api/v1/query_range` | GET | Log range query | `curl -G http://localhost:3100/loki/api/v1/query_range --data-urlencode 'query={job="nginx"}' --data-urlencode 'start=1640995200000000000' --data-urlencode 'end=1641081600000000000'` |
| `/loki/api/v1/labels` | GET | List all labels | `curl http://localhost:3100/loki/api/v1/labels` |
| `/loki/api/v1/label/<name>/values` | GET | Get label values | `curl http://localhost:3100/loki/api/v1/label/job/values` |
| `/loki/api/v1/tail` | GET | Live tail (WebSocket) | Used by Grafana Explore |

**Configuration File (`loki-config.yml`):**
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

limits_config:
  retention_period: 168h           # 7 days
  reject_old_samples: true
  reject_old_samples_max_age: 168h
  ingestion_rate_mb: 16            # Max 16MB/sec per tenant
  ingestion_burst_size_mb: 24

chunk_store_config:
  max_look_back_period: 168h

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h
```

**Query Examples (LogQL):**
```bash
# All logs from nginx job
curl -G http://localhost:3100/loki/api/v1/query \
  --data-urlencode 'query={job="nginx"}'

# Error logs only
curl -G http://localhost:3100/loki/api/v1/query \
  --data-urlencode 'query={job="nginx"} |= "error"'

# 5xx errors
curl -G http://localhost:3100/loki/api/v1/query \
  --data-urlencode 'query={job="nginx"} | json | status_code >= 500'

# Rate of logs
curl -G http://localhost:3100/loki/api/v1/query \
  --data-urlencode 'query=rate({job="nginx"}[5m])'
```

**Service Management:**
```bash
sudo systemctl start loki
sudo systemctl stop loki
sudo systemctl restart loki
sudo systemctl status loki
sudo journalctl -u loki -f
```

---

#### AlertManager Configuration

**Installation Location:**
- Binary: `/usr/local/bin/alertmanager`
- Config: `/etc/alertmanager/alertmanager.yml`
- Data: `/var/lib/alertmanager/`
- Service: `/etc/systemd/system/alertmanager.service`

**Network Configuration:**
```bash
--web.listen-address=0.0.0.0:9093
```

**Access URLs:**
- **Web UI:** `http://<PUBLIC_IP>:9093`
- **Private:** `http://10.0.14.162:9093`

**API Endpoints:**

| Endpoint | Method | Purpose | Example |
|----------|--------|---------|---------|
| `/-/healthy` | GET | Health check | `curl http://localhost:9093/-/healthy` |
| `/-/ready` | GET | Readiness check | `curl http://localhost:9093/-/ready` |
| `/api/v2/alerts` | GET | Get active alerts | `curl http://localhost:9093/api/v2/alerts` |
| `/api/v2/alerts` | POST | Post alerts (Prometheus uses) | Internal |
| `/api/v2/silences` | GET | List silences | `curl http://localhost:9093/api/v2/silences` |
| `/api/v2/silences` | POST | Create silence | See below |
| `/api/v2/status` | GET | AlertManager status | `curl http://localhost:9093/api/v2/status` |

**Configuration File (`alertmanager.yml`):**
```yaml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@your-domain.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 12h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical-receiver'
    - match:
        severity: warning
      receiver: 'warning-receiver'

receivers:
  - name: 'default'
    email_configs:
      - to: 'team@your-domain.com'
        headers:
          Subject: '[BMI] {{ .GroupLabels.alertname }}'

  - name: 'critical-receiver'
    email_configs:
      - to: 'oncall@your-domain.com'
        headers:
          Subject: '[CRITICAL] {{ .GroupLabels.alertname }}'
  
  - name: 'warning-receiver'
    email_configs:
      - to: 'team@your-domain.com'
        headers:
          Subject: '[WARNING] {{ .GroupLabels.alertname }}'

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
```

**Create Silence (via API):**
```bash
curl -X POST http://localhost:9093/api/v2/silences \
  -H "Content-Type: application/json" \
  -d '{
    "matchers": [
      {
        "name": "alertname",
        "value": "HighCPUUsage",
        "isRegex": false
      }
    ],
    "startsAt": "2026-01-01T12:00:00Z",
    "endsAt": "2026-01-01T14:00:00Z",
    "createdBy": "admin",
    "comment": "Planned maintenance"
  }'
```

**Service Management:**
```bash
sudo systemctl start alertmanager
sudo systemctl stop alertmanager
sudo systemctl restart alertmanager
sudo systemctl status alertmanager
sudo journalctl -u alertmanager -f
```

---

### 🖥️ Application Server Configuration

---

#### Node Exporter Configuration

**Installation Location:**
- Binary: `/usr/local/bin/node_exporter`
- Service: `/etc/systemd/system/node_exporter.service`

**Access URL:**
- **Metrics:** `http://10.0.2.115:9100/metrics`

**Service File:**
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

**Common Metrics:**
```bash
# CPU metrics
node_cpu_seconds_total{cpu="0",mode="idle"}
node_cpu_seconds_total{cpu="0",mode="system"}
node_cpu_seconds_total{cpu="0",mode="user"}

# Memory metrics
node_memory_MemTotal_bytes
node_memory_MemAvailable_bytes
node_memory_MemFree_bytes
node_memory_Cached_bytes

# Disk metrics
node_filesystem_size_bytes{mountpoint="/"}
node_filesystem_avail_bytes{mountpoint="/"}
node_disk_io_time_seconds_total

# Network metrics
node_network_receive_bytes_total{device="eth0"}
node_network_transmit_bytes_total{device="eth0"}
```

---

#### PostgreSQL Exporter Configuration

**Installation Location:**
- Binary: `/usr/local/bin/postgres_exporter`
- Config: `/etc/default/postgres_exporter`
- Service: `/etc/systemd/system/postgres_exporter.service`

**Access URL:**
- **Metrics:** `http://10.0.2.115:9187/metrics`

**Environment File (`/etc/default/postgres_exporter`):**
```bash
DATA_SOURCE_NAME=postgresql://bmi_user:YOUR_PASSWORD@localhost:5432/bmi_tracker?sslmode=disable
```

**Service File:**
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

**Common Metrics:**
```bash
# Database up
pg_up

# Connections
pg_stat_database_numbackends{datname="bmi_tracker"}

# Transaction stats
pg_stat_database_xact_commit{datname="bmi_tracker"}
pg_stat_database_xact_rollback{datname="bmi_tracker"}

# Rows
pg_stat_database_tup_fetched{datname="bmi_tracker"}
pg_stat_database_tup_inserted{datname="bmi_tracker"}

# Cache
pg_stat_database_blks_hit{datname="bmi_tracker"}
pg_stat_database_blks_read{datname="bmi_tracker"}
```

---

#### Nginx Exporter Configuration

**Installation Location:**
- Binary: `/usr/local/bin/nginx-prometheus-exporter`
- Service: `/etc/systemd/system/nginx_exporter.service`

**Access URL:**
- **Metrics:** `http://10.0.2.115:9113/metrics`

**Nginx stub_status Configuration:**
```nginx
# /etc/nginx/sites-available/status
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

**Service File:**
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

**Common Metrics:**
```bash
# Requests
nginx_http_requests_total

# Connections
nginx_connections_active
nginx_connections_accepted
nginx_connections_handled

# Connection states
nginx_connections_reading
nginx_connections_writing
nginx_connections_waiting
```

---

#### BMI Custom Exporter Configuration

**Installation Location:**
- App: `/opt/bmi-exporter/`
- Files:
  - `exporter.js` (main app)
  - `package.json`
  - `.env` (environment variables)
  - `ecosystem.config.js` (PM2 config)

**Access URL:**
- **Metrics:** `http://10.0.2.115:9091/metrics`
- **Health:** `http://10.0.2.115:9091/health`
- **Root:** `http://10.0.2.115:9091/`

**Environment File (`.env`):**
```bash
DB_USER=bmi_user
DB_PASSWORD=your_password_here
DB_NAME=bmi_tracker
DB_HOST=localhost
DB_PORT=5432
EXPORTER_PORT=9091
```

**PM2 Configuration (`ecosystem.config.js`):**
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
    autorestart: true
  }]
};
```

**Custom Metrics Exposed:**
```bash
# Business metrics
bmi_measurements_total
bmi_measurements_created_24h
bmi_measurements_created_1h
bmi_average_value

# Category distribution
bmi_category_count{category="underweight"}
bmi_category_count{category="normal"}
bmi_category_count{category="overweight"}
bmi_category_count{category="obese"}

# Database metrics
bmi_database_size_bytes
bmi_table_size_bytes

# Application health
bmi_app_healthy
bmi_db_pool_total
bmi_db_pool_idle
bmi_db_pool_waiting
```

**Health Check Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-01T12:00:00.000Z",
  "uptime": 86400.5,
  "dbConnections": {
    "total": 10,
    "idle": 7,
    "waiting": 0
  }
}
```

**PM2 Management:**
```bash
# Start
pm2 start ecosystem.config.js

# Status
pm2 status

# Logs
pm2 logs bmi-exporter
pm2 logs bmi-exporter --lines 100

# Restart
pm2 restart bmi-exporter

# Stop
pm2 stop bmi-exporter

# Startup on boot
pm2 startup
pm2 save
```

---

#### Promtail Configuration

**Installation Location:**
- Binary: `/usr/local/bin/promtail`
- Config: `/etc/promtail/promtail-config.yml`
- Positions: `/var/lib/promtail/positions/`
- Service: `/etc/systemd/system/promtail.service`

**Access URL:**
- **Ready Check:** `http://10.0.2.115:9080/ready`
- **Metrics:** `http://10.0.2.115:9080/metrics`

**Configuration File (`promtail-config.yml`):**
```yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions/positions.yaml

clients:
  - url: http://10.0.14.162:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: syslog
          host: bmi-app-server
          __path__: /var/log/syslog

  - job_name: nginx_access
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: access
          host: bmi-app-server
          __path__: /var/log/nginx/access.log

  - job_name: nginx_error
    static_configs:
      - targets:
          - localhost
        labels:
          job: nginx
          type: error
          host: bmi-app-server
          __path__: /var/log/nginx/error.log

  - job_name: postgresql
    static_configs:
      - targets:
          - localhost
        labels:
          job: postgresql
          host: bmi-app-server
          __path__: /var/log/postgresql/*.log
```

**Service File:**
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

---

### 🔒 Firewall Configuration

**Monitoring Server (UFW):**
```bash
# Public access
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 3000/tcp comment 'Grafana UI'
sudo ufw allow 9090/tcp comment 'Prometheus UI'
sudo ufw allow 9093/tcp comment 'AlertManager UI'

# From application server (private IP)
sudo ufw allow from 10.0.2.115 to any port 3100 comment 'Loki'
sudo ufw allow from 10.0.2.115 to any port 9100 comment 'Node Exporter'

# Check rules
sudo ufw status numbered
```

**Application Server (UFW):**
```bash
# Public access
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# From monitoring server only (private IP)
sudo ufw allow from 10.0.14.162 to any port 9100 comment 'Node Exporter'
sudo ufw allow from 10.0.14.162 to any port 9187 comment 'PostgreSQL Exporter'
sudo ufw allow from 10.0.14.162 to any port 9113 comment 'Nginx Exporter'
sudo ufw allow from 10.0.14.162 to any port 9091 comment 'BMI Exporter'

# Check rules
sudo ufw status numbered
```

---

### 📊 Port Reference Table

| Port | Service | Server | Protocol | Access | Purpose |
|------|---------|--------|----------|--------|---------|
| 22 | SSH | Both | TCP | Public | Remote access |
| 80 | HTTP | App | TCP | Public | Web traffic |
| 443 | HTTPS | App | TCP | Public | Secure web |
| 3000 | Grafana | Monitoring | HTTP | Public | Dashboards UI |
| 3100 | Loki | Monitoring | HTTP/gRPC | VPC | Log ingestion |
| 9080 | Promtail | App | HTTP | VPC | Status endpoint |
| 9090 | Prometheus | Monitoring | HTTP | Public | Metrics & UI |
| 9091 | BMI Exporter | App | HTTP | VPC | App metrics |
| 9093 | AlertManager | Monitoring | HTTP | Public | Alerts UI |
| 9096 | Loki gRPC | Monitoring | gRPC | VPC | High-perf logs |
| 9100 | Node Exporter | Both | HTTP | VPC | System metrics |
| 9113 | Nginx Exporter | App | HTTP | VPC | Web metrics |
| 9187 | PostgreSQL Exp | App | HTTP | VPC | DB metrics |

**VPC = Virtual Private Cloud (internal network only)**

---

## 5. DevOps Concepts Explained

This section covers essential monitoring concepts every DevOps engineer should understand.

---

### 🔄 Pull vs Push Models

Understanding when to pull and when to push is fundamental to monitoring architecture.

#### Pull Model (Prometheus Approach)

**How it works:**
```
Monitoring Server ──HTTP GET──> Application Server
                                (Exporter on :9100)
                 <──Metrics────
```

**Process:**
1. Prometheus initiates connection to exporter
2. Prometheus sends HTTP GET request to `/metrics` endpoint
3. Exporter returns metrics in Prometheus text format
4. Prometheus stores metrics with timestamp
5. Connection closes
6. Repeat every `scrape_interval` (default: 15s)

**Advantages:**
- ✅ **Security:** Firewall-friendly (app server doesn't need to know monitoring server)
- ✅ **Discovery:** Easy service discovery (monitoring server controls targets)
- ✅ **Monitoring the monitors:** Can detect if exporter is down
- ✅ **Simple exporters:** Exporters are stateless HTTP servers
- ✅ **Pull on demand:** Can manually scrape anytime for testing

**Disadvantages:**
- ❌ **Network requirements:** Monitoring server must reach all targets
- ❌ **Short-lived jobs:** Hard to monitor jobs that finish before scrape
- ❌ **Scalability:** Monitoring server can become bottleneck

**Real-world example in our setup:**
```bash
# Prometheus configuration
scrape_configs:
  - job_name: 'node_exporter'
    scrape_interval: 15s
    static_configs:
      - targets: ['10.0.2.115:9100']

# What happens:
# Every 15 seconds:
# Prometheus → HTTP GET http://10.0.2.115:9100/metrics
# Node Exporter → Returns current metrics
# Prometheus → Stores with timestamp
```

---

#### Push Model (Loki Approach)

**How it works:**
```
Application Server ──HTTP POST──> Monitoring Server
(Promtail)                        (Loki on :3100)
```

**Process:**
1. Promtail tails log files
2. Promtail batches log lines (default: every 1s or 1MB)
3. Promtail initiates connection to Loki
4. Promtail sends HTTP POST to `/loki/api/v1/push`
5. Loki stores logs
6. Loki responds with 204 No Content
7. Connection closes

**Advantages:**
- ✅ **Short-lived jobs:** Catch data before job ends
- ✅ **Firewall friendly:** Only outbound connections from app server
- ✅ **Buffering:** Can queue data during network issues
- ✅ **Lower latency:** Data sent immediately
- ✅ **NAT traversal:** Works even if app server has private IP

**Disadvantages:**
- ❌ **Configuration:** Each client needs to know server location
- ❌ **Authentication:** Need to secure push endpoint
- ❌ **Monitoring gaps:** If client fails, data is lost
- ❌ **Resource usage:** Clients use more CPU/memory for batching

**Real-world example in our setup:**
```yaml
# Promtail configuration
clients:
  - url: http://10.0.14.162:3100/loki/api/v1/push

# What happens:
# Continuous:
# 1. Promtail detects new log line in /var/log/nginx/access.log
# 2. Promtail adds to batch
# 3. Every 1 second or when batch reaches 1MB:
#    Promtail → HTTP POST to Loki with JSON payload
#    Loki → Stores logs
#    Loki → Responds with 204
```

---

#### Hybrid Approach (Best of Both)

Our monitoring uses **both models** where it makes sense:

| Data Type | Model | Tool | Why? |
|-----------|-------|------|------|
| **Metrics** | Pull | Prometheus | Metrics are always available, pull is simpler |
| **Logs** | Push | Loki via Promtail | Logs are events, push ensures nothing missed |
| **Alerts** | Push | AlertManager | Alerts are events requiring immediate action |
| **Queries** | Pull | Grafana | User initiates queries on demand |

---

###  📊 Metrics vs Logs vs Traces

The three pillars of observability serve different purposes.

#### Metrics (Numbers over Time)

**What:** Aggregated numerical measurements

**Format:**
```
metric_name{label="value"} numeric_value timestamp
cpu_usage_percent{instance="app-01"} 75.2 1640995200
```

**Characteristics:**
- Cheap to store (small size)
- Fast to query
- Good for trends and alerting
- Loses individual event details

**When to use:**
- System resources (CPU, memory, disk)
- Request rates and latencies
- Error rates
- Business KPIs (orders, revenue)

**Example queries:**
```promql
# Current CPU usage
cpu_usage_percent

# Request rate over 5 minutes
rate(http_requests_total[5m])

# 95th percentile latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**Storage:** Time-series database (Prometheus)

---

#### Logs (Event Records)

**What:** Detailed text records of events

**Format:**
```
timestamp level source message additional_context
2026-01-01T12:00:00Z ERROR nginx Connection refused to upstream server=10.0.2.115 request_id=abc123
```

**Characteristics:**
- Expensive to store (large size)
- Slow to query (must scan)
- Rich context for debugging
- Every detail preserved

**When to use:**
- Debugging errors
- Audit trails
- Understanding user behavior
- Root cause analysis

**Example queries (LogQL):**
```logql
# All errors
{job="nginx"} |= "error"

# 500 status codes
{job="nginx"} | json | status_code >= 500

# Slow requests
{job="nginx"} | json | response_time_ms > 1000
```

**Storage:** Log aggregation system (Loki)

---

#### Traces (Request Flows)

**What:** End-to-end request journey through services

**Format:**
```
Trace ID: abc123
├─ Span: API Gateway (120ms)
│  ├─ Span: Authentication (20ms)
│  ├─ Span: BMI Service (80ms)
│  │  └─ Span: Database Query (50ms)
│  └─ Span: Response (20ms)
```

**Characteristics:**
- Very detailed (full request path)
- Expensive to store and process
- Essential for distributed systems
- Shows dependencies

**When to use:**
- Distributed systems (microservices)
- Performance optimization
- Understanding service dependencies
- Finding bottlenecks

**Tools:** Jaeger, Zipkin, Tempo

**Note:** Not implemented in our current BMI app (single server, monolithic)

---

#### Comparison Table

| Aspect | Metrics | Logs | Traces |
|--------|---------|------|--------|
| **Data Volume** | Low (KB/day) | High (MB-GB/day) | Very High (GB/day) |
| **Storage Cost** | $ | $$ | $$$ |
| **Query Speed** | Fast (ms) | Slow (seconds) | Medium (seconds) |
| **Detail Level** | Low | High | Very High |
| **Retention** | Long (months-years) | Short (days-weeks) | Very Short (hours-days) |
| **Alerting** | Excellent | Poor | Not used |
| **Debugging** | Poor | Excellent | Excellent |
| **Cardinality** | Low | High | Very High |

---

#### When to Use What?

**Scenario 1: Website is slow**
1. **Metrics:** Check if CPU/memory/disk is high → Not high
2. **Metrics:** Check request latency → Latency spiked at 2:15 PM
3. **Logs:** Search logs at 2:15 PM → See database timeout errors
4. **Logs:** Find slow query → `SELECT * FROM huge_table`
5. **Traces:** (if available) See query took 5 seconds in database span

**Scenario 2: Alert fired - High Error Rate**
1. **Alert:** Triggered by metrics (error_rate > 5%)
2. **Metrics:** Confirm spike in 5xx errors
3. **Logs:** Find actual error messages
4. **Logs:** Identify affected users/requests
5. **Fix:** Deploy hotfix
6. **Metrics:** Verify error rate dropped

**Scenario 3: User reports "payment failed"**
1. **Logs:** Search by user ID or transaction ID
2. **Logs:** Find error: "Payment gateway timeout"
3. **Traces:** (if available) See call to payment service took 30s
4. **Metrics:** Check payment service response time
5. **Fix:** Increase timeout or investigate payment service

---

### 📈 PromQL - Prometheus Query Language

PromQL is the language for querying metrics. Master these concepts:

#### Metric Types

**1. Counter** (only increases)
```promql
# Total HTTP requests since server start
http_requests_total

# How to use: rate() for per-second rate
rate(http_requests_total[5m])  # Requests/sec over last 5 minutes
```

**2. Gauge** (can go up or down)
```promql
# Current memory usage
node_memory_MemAvailable_bytes

# How to use: directly or with aggregations
node_memory_MemAvailable_bytes / 1024 / 1024  # Convert to MB
```

**3. Histogram** (distribution of values)
```promql
# Request duration buckets
http_request_duration_seconds_bucket{le="0.1"}  # Requests <= 100ms
http_request_duration_seconds_bucket{le="0.5"}  # Requests <= 500ms

# How to use: histogram_quantile()
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

**4. Summary** (similar to histogram, precomputed quantiles)
```promql
# 95th percentile from summary
rpc_duration_seconds{quantile="0.95"}
```

---

#### Common Query Patterns

**1. Calculate Rate**
```promql
# Request rate
rate(http_requests_total[5m])

# Always use rate() with counters
# Never use counter values directly (they only increase)
```

**2. Calculate Percentage**
```promql
# CPU usage percentage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Error rate percentage
(rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])) * 100
```

**3. Aggregate Across Instances**
```promql
# Average CPU across all servers
avg(cpu_usage_percent)

# Total requests across all servers
sum(rate(http_requests_total[5m]))

# Max memory usage
max(memory_usage_bytes)

# Count of servers
count(up == 1)
```

**4. Filter by Labels**
```promql
# Metrics from specific instance
cpu_usage_percent{instance="10.0.2.115:9100"}

# Metrics from job
up{job="node_exporter"}

# Regex matching
http_requests_total{status=~"5.."}  # All 5xx errors
http_requests_total{path!="/health"}  # Exclude health checks
```

**5. Time Shifting**
```promql
# Current value
http_requests_total

# Value 1 hour ago
http_requests_total offset 1h

# Compare to 1 hour ago
http_requests_total - http_requests_total offset 1h
```

---

#### Real BMI App Queries

**System Health:**
```promql
# Is application server up?
up{job="node_exporter", instance="10.0.2.115:9100"}

# CPU usage
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle", instance="10.0.2.115:9100"}[5m])) * 100)

# Memory usage percentage
(node_memory_MemTotal_bytes{instance="10.0.2.115:9100"} - node_memory_MemAvailable_bytes{instance="10.0.2.115:9100"}) / node_memory_MemTotal_bytes{instance="10.0.2.115:9100"} * 100

# Disk usage
100 - ((node_filesystem_avail_bytes{instance="10.0.2.115:9100", mountpoint="/"} / node_filesystem_size_bytes{instance="10.0.2.115:9100", mountpoint="/"}) * 100)
```

**Database Metrics:**
```promql
# Database connections
pg_stat_database_numbackends{datname="bmi_tracker"}

# Queries per second
rate(pg_stat_database_xact_commit{datname="bmi_tracker"}[5m])

# Cache hit ratio (higher is better)
(pg_stat_database_blks_hit{datname="bmi_tracker"} / (pg_stat_database_blks_hit{datname="bmi_tracker"} + pg_stat_database_blks_read{datname="bmi_tracker"})) * 100
```

**Web Server Metrics:**
```promql
# Requests per second
rate(nginx_http_requests_total{instance="10.0.2.115:9113"}[5m])

# Active connections
nginx_connections_active{instance="10.0.2.115:9113"}
```

**Application Metrics:**
```promql
# Total BMI measurements
bmi_measurements_total

# Measurements added today
bmi_measurements_created_24h

# Average BMI
bmi_average_value

# BMI category distribution
bmi_category_count

# Application health (1=healthy, 0=unhealthy)
bmi_app_healthy
```

---

### 🚨 Alert Rules Concepts

Alerts notify you when something needs attention. Design them carefully to avoid alert fatigue.

#### Alert Anatomy

```yaml
- alert: HighCPUUsage            # Alert name
  expr: cpu_usage_percent > 80   # Condition (PromQL)
  for: 10m                       # Duration threshold must be true
  labels:                        # Labels added to alert
    severity: warning
    component: system
  annotations:                   # Human-readable details
    summary: "High CPU on {{ $labels.instance }}"
    description: "CPU usage is {{ $value }}% for 10+ minutes"
```

#### Alert States

```
INACTIVE ──condition met──> PENDING ──duration met──> FIRING
   ↑                            │                        │
   │                            │                        │
   └───────condition not met────┴────condition not met──┘
```

**Example timeline:**
```
12:00 - CPU = 75% → INACTIVE
12:05 - CPU = 85% → PENDING (started, needs 10 min)
12:10 - CPU = 87% → PENDING (5 min elapsed)
12:15 - CPU = 82% → FIRING (10 min elapsed, alert sent)
12:20 - CPU = 70% → INACTIVE (resolved, recovery sent)
```

---

#### Alert Design Best Practices

**1. Actionable Alerts**
❌ Bad: "Disk usage high"
✅ Good: "Disk usage 92% on /var/log - cleanup required within 1 hour"

**2. Appropriate Severity**
```yaml
# Critical: Immediate action required (wake someone up)
severity: critical
examples:
  - Service completely down
  - Data loss imminent
  - Security breach

# Warning: Action needed soon (during business hours)
severity: warning
examples:
  - High resource usage
  - Degraded performance
  - Elevated error rate

# Info: FYI, no immediate action
severity: info
examples:
  - Deployment completed
  - Maintenance window started
```

**3. Reasonable Thresholds**
```yaml
# Too sensitive (alert fatigue)
❌ expr: cpu_usage_percent > 50  for: 1m

# Better
✅ expr: cpu_usage_percent > 80  for: 10m

# Even better (with buffer)
✅ expr: cpu_usage_percent > 80  for: 10m
   firing: notify
   expr: cpu_usage_percent > 70  for: 15m
   firing: resolve when < 70
```

**4. Include Context**
```yaml
annotations:
  summary: "High memory usage on {{ $labels.instance }}"
  description: |
    Memory usage: {{ $value | humanizePercentage }}
    Instance: {{ $labels.instance }}
    Job: {{ $labels.job }}
    Runbook: https://wiki.company.com/runbooks/high-memory
```

---

#### Real Alert Examples for BMI App

**System Alerts:**
```yaml
- alert: InstanceDown
  expr: up{job="node_exporter"} == 0
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Server {{ $labels.instance }} is down"
    description: "No response for 5 minutes. Check server status immediately."

- alert: HighCPUUsage
  expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High CPU on {{ $labels.instance }}"
    description: "CPU usage {{ $value }}% for 10+ minutes"

- alert: DiskSpaceCritical
  expr: (node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100 < 10
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Disk almost full on {{ $labels.instance }}"
    description: "Only {{ $value }}% free. Cleanup required immediately."
```

**Database Alerts:**
```yaml
- alert: DatabaseDown
  expr: pg_up == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "PostgreSQL is down"
    description: "Database not responding for 1 minute"

- alert: TooManyConnections
  expr: pg_stat_database_numbackends{datname="bmi_tracker"} > 80
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "High database connections"
    description: "{{ $value }} connections to bmi_tracker (max: 100)"

- alert: SlowQueries
  expr: rate(pg_stat_database_tup_fetched{datname="bmi_tracker"}[5m]) < 100
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "Database performance degraded"
```

**Application Alerts:**
```yaml
- alert: BMIApplicationUnhealthy
  expr: bmi_app_healthy == 0
  for: 2m
  labels:
    severity: critical
  annotations:
    summary: "BMI application health check failing"
    description: "Application reports unhealthy status"

- alert: NoRecentMeasurements
  expr: increase(bmi_measurements_total[1h]) == 0
  for: 2h
  labels:
    severity: warning
  annotations:
    summary: "No BMI measurements recorded"
    description: "No new measurements in 2 hours. Check if users can access the app."
```

**Web Server Alerts:**
```yaml
- alert: HighErrorRate
  expr: (rate(nginx_http_requests_total{status=~"5.."}[5m]) / rate(nginx_http_requests_total[5m])) * 100 > 5
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High HTTP 5xx error rate"
    description: "{{ $value }}% of requests failing"
```

---

### 🎯 Monitoring Best Practices

#### The Four Golden Signals (Google SRE)

Monitor these four metrics for any user-facing system:

**1. Latency** (How long does it take?)
```promql
# Request duration
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

Alert when: P95 latency > 1 second
```

**2. Traffic** (How much demand?)
```promql
# Requests per second
rate(http_requests_total[5m])

Alert when: Unusual traffic pattern (too high or too low)
```

**3. Errors** (How many requests are failing?)
```promql
# Error rate
(rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])) * 100

Alert when: Error rate > 1%
```

**4. Saturation** (How full is your service?)
```promql
# Examples:
cpu_usage_percent
memory_usage_percent
disk_usage_percent
connection_pool_utilization

Alert when: > 80% capacity
```

---

#### The RED Method (for Services)

Track these three metrics for each service:

**R**ate: Requests per second
```promql
rate(http_requests_total[5m])
```

**E**rrors: Failed requests per second
```promql
rate(http_requests_total{status=~"5.."}[5m])
```

**D**uration: Request latency
```promql
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

---

#### The USE Method (for Resources)

Track these three metrics for each resource:

**U**tilization: % of time resource is busy
```promql
# CPU utilization
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**S**aturation: Amount of queued work
```promql
# Load average (should be < number of CPUs)
node_load1

# Connection pool queue
pg_stat_activity_count{state="active"} / pg_settings_max_connections
```

**E**rrors: Error count
```promql
# Disk errors
rate(node_disk_io_time_seconds_total{device="sda"}[5m])
```

---

### 🔒 Network Security & Private IPs

#### Why Private IPs for Monitoring?

**Security Benefits:**
```
Public IP: Exposed to internet
├─ Risk: Port scanning
├─ Risk: DDoS attacks
├─ Risk: Credential stuffing
└─ Risk: Vulnerability exploitation

Private IP: Internal network only
├─ ✓ Not routable from internet
├─ ✓ Requires VPN/bastion to access
├─ ✓ Reduced attack surface
└─ ✓ Network segmentation
```

**Cost Benefits:**
```
Public IP communication:
├─ Data transfer costs (inter-region)
├─ Egress charges
└─ Example: $0.09 per GB

Private IP communication:
├─ Free within VPC
├─ Lower latency
└─ Example: $0.00 per GB
```

**Our Architecture:**
```
Internet
   │
   ├──► Monitoring Server :3000 (Grafana UI) - Public
   ├──► Monitoring Server :9090 (Prometheus UI) - Public
   │
VPC Private Network (10.0.0.0/16)
   │
   ├──► Monitoring Server :3100 (Loki) - Private
   │      ▲
   │      │ Push logs
   │      │
   ├──► Application Server exporters - Private
   │    • :9100 Node Exporter
   │    • :9187 PostgreSQL Exporter
   │    • :9113 Nginx Exporter
   │    • :9091 BMI Exporter
   │
   └──► Prometheus scrapes via private IPs
```

---

#### Firewall Strategy

**Principle of Least Privilege:** Only open ports that are absolutely necessary

**Monitoring Server Rules:**
```bash
# Public access (your IP only)
ufw allow from YOUR_IP to any port 22    # SSH
ufw allow from YOUR_IP to any port 3000  # Grafana
ufw allow from YOUR_IP to any port 9090  # Prometheus
ufw allow from YOUR_IP to any port 9093  # AlertManager

# Private access (from application server only)
ufw allow from 10.0.2.115 to any port 3100  # Loki (logs)
ufw allow from 10.0.2.115 to any port 9100  # Node Exporter
```

**Application Server Rules:**
```bash
# Public access
ufw allow 22      # SSH
ufw allow 80      # HTTP
ufw allow 443     # HTTPS

# Private access (from monitoring server only)
ufw allow from 10.0.14.162 to any port 9100  # Node Exporter
ufw allow from 10.0.14.162 to any port 9187  # PostgreSQL Exporter
ufw allow from 10.0.14.162 to any port 9113  # Nginx Exporter
ufw allow from 10.0.14.162 to any port 9091  # BMI Exporter
```

---

#### Security Best Practices

**1. Authentication**
```bash
# Grafana: Change default password immediately
# Prometheus: Add HTTP basic auth via reverse proxy (Nginx)
# AlertManager: Configure auth for webhook receivers
```

**2. Encryption**
```bash
# Use TLS for Grafana
# Use HTTPS for Prometheus (via reverse proxy)
# Encrypt Loki communication (optional for internal network)
```

**3. Network Segmentation**
```
Public Subnet: Load balancers, bastion hosts
Private Subnet: Application servers, databases
Monitoring Subnet: Monitoring stack (isolated)
```

**4. Secrets Management**
```bash
# Don't commit passwords to git
# Use environment variables
# Use AWS Secrets Manager or HashiCorp Vault
# Restrict file permissions (chmod 600)
```

**5. Audit Logging**
```bash
# Enable Grafana audit logs
# Monitor failed SSH attempts
# Alert on unauthorized access attempts
```

---

### 📚 Summary & Next Steps

**You've learned:**
- ✅ Why monitoring is critical for production systems
- ✅ What each monitoring tool does (Prometheus, Grafana, Loki, exporters)
- ✅ How tools work together in our BMI app
- ✅ Exact configuration, APIs, and URLs for each tool
- ✅ Pull vs Push models
- ✅ Metrics vs Logs vs Traces
- ✅ PromQL query language
- ✅ Alert design best practices
- ✅ Monitoring methodologies (Four Golden Signals, RED, USE)
- ✅ Network security with private IPs

**Next steps to become monitoring expert:**
1. **Practice PromQL:** Write 10 queries per day
2. **Build dashboards:** Create custom Grafana dashboards
3. **Design alerts:** Start with critical, add warnings later
4. **Learn LogQL:** Query Loki logs effectively
5. **Study incidents:** Use monitoring to find root causes
6. **Optimize costs:** Right-size retention and scrape intervals
7. **Add tracing:** Implement Jaeger or Tempo (next level)
8. **Automate:** Infrastructure as Code (Terraform/Ansible)

**Recommended reading:**
- [Site Reliability Engineering Book (Google)](https://sre.google/books/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Fundamentals](https://grafana.com/tutorials/grafana-fundamentals/)
- [The Art of Monitoring (James Turnbull)](https://artofmonitoring.com/)

---

## 🤝 Troubleshooting Guide

**Common issues and solutions:**

**Problem: Can't access Prometheus UI via IP**
```bash
# Check if listening on all interfaces
sudo netstat -tulpn | grep 9090
# Should show: :::9090 or 0.0.0.0:9090

# If shows 127.0.0.1:9090, edit systemd service:
sudo nano /etc/systemd/system/prometheus.service
# Add: --web.listen-address=0.0.0.0:9090

sudo systemctl daemon-reload
sudo systemctl restart prometheus
```

**Problem: Prometheus can't scrape targets**
```bash
# Test connectivity from monitoring server
curl http://10.0.2.115:9100/metrics

# Check firewall on application server
sudo ufw status

# Allow monitoring server
sudo ufw allow from 10.0.14.162 to any port 9100
```

**Problem: No logs in Loki**
```bash
# Check Promtail is running
sudo systemctl status promtail

# Check Promtail can reach Loki
curl http://10.0.14.162:3100/ready

# Check Loki labels
curl http://localhost:3100/loki/api/v1/labels

# View Promtail logs
sudo journalctl -u promtail -f
```

**Problem: Grafana shows "No data"**
```bash
# Test Prometheus datasource
curl -u admin:admin http://localhost:3000/api/datasources

# Test query manually
curl -G http://localhost:9090/api/v1/query --data-urlencode 'query=up'

# Check Grafana logs
sudo journalctl -u grafana-server -f
```

---

**Last Updated:** January 2026  
**Author:** BMI Health Tracker Monitoring Team  
**Version:** 1.0  
**Monitoring Stack:** Prometheus 2.48.0 • Grafana Latest • Loki 2.9.3 • AlertManager 0.26.0

**Communication Method:** HTTP GET Requests

```
Prometheus                           Node Exporter (App Server)
    |                                          |
    |── HTTP GET /metrics ──────────────────>  |
    |                                          |
    |  <────────── Metrics Data ────────────── |
    |  (Prometheus text format)                |
```

**Example Request:**
```bash
curl http://10.0.2.115:9100/metrics
```

**Example Response:**
```
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 12345.67
node_cpu_seconds_total{cpu="0",mode="system"} 123.45
```

**Key Points:**
- Prometheus initiates all connections (security benefit)
- Exporters are stateless HTTP servers
- Metrics endpoint is always `/metrics`
- Scrape interval defined in `prometheus.yml`

---

### 2. Promtail → Loki (Push Model)

**Communication Method:** HTTP POST with JSON payload

```
Promtail (App Server)                    Loki (Monitoring Server)
    |                                            |
    |─ POST /loki/api/v1/push ─────────────────> |
    |  (JSON with log streams)                   |
    |                                            |
    |  <────────── 204 No Content ─────────────  |
```

**Example Promtail Push:**
```json
{
  "streams": [
    {
      "stream": {
        "job": "nginx",
        "host": "app-server",
        "filename": "/var/log/nginx/access.log"
      },
      "values": [
        ["1640995200000000000", "192.168.1.1 - GET /api/health 200"]
      ]
    }
  ]
}
```

**Key Points:**
- Promtail tails log files continuously
- Pushes logs in batches
- Adds labels (job, host, filename)
- Loki indexes labels, not log content

---

### 3. Grafana → Prometheus (Query)

**Communication Method:** HTTP API Calls

```
Grafana (Browser)                      Prometheus
    |                                        |
    |── HTTP POST /api/v1/query ──────────>  |
    |  {query: "up{job='node_exporter'}"}   |
    |                                        |
    |  <────── JSON Response ──────────────  |
    |  {status: "success", data: {...}}     |
```

**Example API Request:**
```bash
curl -X POST http://localhost:9090/api/v1/query \
  -d 'query=up{job="node_exporter"}' \
  -d 'time=1640995200'
```

**Example Response:**
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {"job": "node_exporter", "instance": "10.0.2.115:9100"},
        "value": [1640995200, "1"]
      }
    ]
  }
}
```

**Key Points:**
- Grafana uses PromQL (Prometheus Query Language)
- Supports instant queries and range queries
- Data returned in JSON format
- Grafana transforms to visual charts

---

### 4. Grafana → Loki (Query)

**Communication Method:** HTTP API with LogQL

```
Grafana                                Loki
    |                                      |
    |── GET /loki/api/v1/query_range ────> |
    |  ?query={job="nginx"}                |
    |  &start=1640990000&end=1640995200    |
    |                                      |
    |  <────── JSON Response ─────────────  |
```

**Example LogQL Query:**
```
{job="nginx"} |= "error" | json | status_code >= 500
```

**Key Points:**
- LogQL is similar to PromQL but for logs
- Can filter by labels
- Supports log parsing (json, regex)
- Returns actual log lines

---

### 5. Prometheus → AlertManager (Alerts)

**Communication Method:** HTTP POST

```
Prometheus                             AlertManager
    |                                         |
    |── POST /api/v2/alerts ───────────────>  |
    |  (Alert JSON payload)                   |
    |                                         |
    |  <────── 200 OK ─────────────────────   |
```

**Example Alert Payload:**
```json
[
  {
    "labels": {
      "alertname": "HighCPUUsage",
      "instance": "10.0.2.115:9100",
      "severity": "warning"
    },
    "annotations": {
      "summary": "High CPU usage on 10.0.2.115",
      "description": "CPU usage is above 80%"
    },
    "startsAt": "2024-01-01T12:00:00Z",
    "endsAt": "0001-01-01T00:00:00Z"
  }
]
```

---

## 🌐 API Endpoints & URLs

### Monitoring Server APIs

#### Prometheus (Port 9090)

| Endpoint | Method | Purpose | Example |
|----------|--------|---------|---------|
| `/metrics` | GET | Prometheus own metrics | `curl http://localhost:9090/metrics` |
| `/api/v1/query` | POST | Instant query | `curl -X POST http://localhost:9090/api/v1/query -d 'query=up'` |
| `/api/v1/query_range` | POST | Range query | For time-series data |
| `/api/v1/targets` | GET | List all scrape targets | `curl http://localhost:9090/api/v1/targets` |
| `/api/v1/alerts` | GET | Active alerts | `curl http://localhost:9090/api/v1/alerts` |
| `/api/v1/rules` | GET | Alerting rules | `curl http://localhost:9090/api/v1/rules` |
| `/-/reload` | POST | Reload config | `curl -X POST http://localhost:9090/-/reload` |
| `/-/healthy` | GET | Health check | `curl http://localhost:9090/-/healthy` |

#### Grafana (Port 3000)

| Endpoint | Method | Purpose | Auth Required |
|----------|--------|---------|---------------|
| `/api/health` | GET | Health check | No |
| `/api/datasources` | GET | List datasources | Yes |
| `/api/dashboards` | GET | List dashboards | Yes |
| `/api/search` | GET | Search dashboards | Yes |
| `/api/annotations` | POST | Create annotation | Yes |
| `/login` | POST | User login | No |

**Authentication:**
- Basic Auth: `admin:admin` (default)
- API Key: Create in Settings → API Keys

#### Loki (Port 3100)

| Endpoint | Method | Purpose | Example |
|----------|--------|---------|---------|
| `/ready` | GET | Readiness check | `curl http://localhost:3100/ready` |
| `/metrics` | GET | Loki metrics | `curl http://localhost:3100/metrics` |
| `/loki/api/v1/push` | POST | Push logs (Promtail) | Used by Promtail |
| `/loki/api/v1/query` | GET | Instant log query | `curl "http://localhost:3100/loki/api/v1/query?query={job=\"nginx\"}"` |
| `/loki/api/v1/query_range` | GET | Log range query | For time ranges |
| `/loki/api/v1/labels` | GET | List all labels | `curl http://localhost:3100/loki/api/v1/labels` |

#### AlertManager (Port 9093)

| Endpoint | Method | Purpose | Example |
|----------|--------|---------|---------|
| `/-/healthy` | GET | Health check | `curl http://localhost:9093/-/healthy` |
| `/api/v2/alerts` | GET | Get active alerts | `curl http://localhost:9093/api/v2/alerts` |
| `/api/v2/alerts` | POST | Post alerts (Prometheus) | Used by Prometheus |
| `/api/v2/silences` | GET | List silences | `curl http://localhost:9093/api/v2/silences` |
| `/api/v2/silences` | POST | Create silence | Silence alerts temporarily |

---

### Application Server Exporters

#### Node Exporter (Port 9100)

```bash
# Get all metrics
curl http://10.0.2.115:9100/metrics

# Sample metrics
node_cpu_seconds_total
node_memory_MemAvailable_bytes
node_filesystem_avail_bytes
node_network_receive_bytes_total
```

#### PostgreSQL Exporter (Port 9187)

```bash
# Get database metrics
curl http://10.0.2.115:9187/metrics

# Sample metrics
pg_up
pg_stat_database_numbackends
pg_stat_database_tup_fetched
pg_stat_database_blks_hit
```

#### Nginx Exporter (Port 9113)

```bash
# Get web server metrics
curl http://10.0.2.115:9113/metrics

# Sample metrics
nginx_http_requests_total
nginx_connections_active
nginx_connections_accepted
```

#### BMI Custom Exporter (Port 9091)

```bash
# Get application metrics
curl http://10.0.2.115:9091/metrics

# Custom business metrics
bmi_measurements_total
bmi_measurements_created_24h
bmi_average_value
bmi_category_count{category="normal"}
bmi_app_healthy
```

**Health Check:**
```bash
curl http://10.0.2.115:9091/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-01-01T12:00:00Z",
  "uptime": 86400,
  "dbConnections": {
    "total": 10,
    "idle": 8,
    "waiting": 0
  }
}
```

---

## 📊 Data Flow Explained

### Metrics Collection Flow

```
1. Application Activity
   └─> Node Exporter collects OS metrics (every 1s internally)
   └─> PostgreSQL Exporter queries database stats
   └─> Nginx Exporter reads nginx stub_status
   └─> BMI Exporter queries database for app metrics

2. Prometheus Scrapes (every 15s)
   └─> HTTP GET to each exporter's /metrics endpoint
   └─> Parses Prometheus text format
   └─> Stores in TSDB with timestamp

3. Data Storage
   └─> Stored in /var/lib/prometheus/
   └─> Retention: 15 days (configurable)
   └─> Organized in 2-hour blocks

4. Alerting
   └─> Prometheus evaluates rules every 15s
   └─> If threshold breached, creates alert
   └─> Sends to AlertManager via HTTP POST

5. Visualization
   └─> User opens Grafana dashboard
   └─> Grafana queries Prometheus API
   └─> Prometheus returns data
   └─> Grafana renders charts
```

### Log Collection Flow

```
1. Application Logs
   └─> Applications write to log files
       • /var/log/nginx/access.log
       • /var/log/nginx/error.log
       • /var/log/postgresql/*.log
       • /var/log/syslog

2. Promtail Tailing
   └─> Promtail watches configured log files
   └─> Detects new log lines
   └─> Adds labels (job, host, filename)
   └─> Batches logs together

3. Push to Loki
   └─> HTTP POST to http://monitoring-server:3100/loki/api/v1/push
   └─> JSON payload with log streams
   └─> Loki acknowledges with 204

4. Loki Indexing
   └─> Indexes labels (not content)
   └─> Stores chunks in filesystem
   └─> Compresses old data
   └─> Retention: 7 days

5. Querying Logs
   └─> User queries in Grafana Explore
   └─> Grafana sends LogQL query to Loki
   └─> Loki searches index
   └─> Returns matching log lines
```

---

## 🔌 Ports & Protocols

### Port Reference Table

| Port | Service | Protocol | Direction | Purpose |
|------|---------|----------|-----------|---------|
| 22 | SSH | TCP | Inbound | Remote server access |
| 3000 | Grafana | HTTP | Inbound | Web UI for dashboards |
| 3100 | Loki | HTTP/gRPC | Inbound | Log ingestion & queries |
| 9090 | Prometheus | HTTP | Inbound | Metrics queries & UI |
| 9091 | BMI Exporter | HTTP | Monitoring → App | Custom app metrics |
| 9093 | AlertManager | HTTP | Inbound | Alert management UI |
| 9096 | Loki gRPC | gRPC | Inbound | High-performance log push |
| 9100 | Node Exporter | HTTP | Monitoring → App/Self | System metrics |
| 9113 | Nginx Exporter | HTTP | Monitoring → App | Web server metrics |
| 9187 | PostgreSQL Exporter | HTTP | Monitoring → App | Database metrics |

### Network Security

**Monitoring Server Firewall (UFW):**
```bash
# Public access (from your IP)
22/tcp    - SSH
3000/tcp  - Grafana UI
9090/tcp  - Prometheus UI
9093/tcp  - AlertManager UI

# From application server only (private IP)
3100/tcp  - Loki log ingestion
9100/tcp  - Node Exporter (self-monitoring)
```

**Application Server Firewall:**
```bash
# Public access
22/tcp    - SSH
80/tcp    - HTTP (BMI app)
443/tcp   - HTTPS (BMI app)

# From monitoring server only (private IP)
9100/tcp  - Node Exporter
9113/tcp  - Nginx Exporter
9187/tcp  - PostgreSQL Exporter
9091/tcp  - BMI Custom Exporter
```

### Why Private IPs?

When servers are in the same VPC/subnet:
- ✅ No internet exposure of metrics
- ✅ Lower latency
- ✅ No data transfer costs
- ✅ Better security (internal network)

---

## 🎓 Key Concepts for DevOps

### 1. Pull vs Push Models

**Pull Model (Prometheus):**
```
Monitoring Server → Scrapes → Application Server
```
- Monitoring server controls when to collect
- Exporters don't need to know monitoring server location
- Easy to add/remove targets
- Natural service discovery integration

**Push Model (Loki):**
```
Application Server → Pushes → Monitoring Server
```
- Application controls when to send
- Good for short-lived jobs
- Reduces monitoring server connections
- Can buffer during network issues

### 2. Metrics vs Logs

**Metrics (Prometheus):**
- Numerical time-series data
- Efficient storage (counters, gauges, histograms)
- Fast queries for trends
- Example: `cpu_usage_percent{instance="app-01"} = 75.2`

**Logs (Loki):**
- Text-based event data
- Context and details about what happened
- Debugging and troubleshooting
- Example: `192.168.1.1 - GET /api/health 500 - 0.523s`

### 3. Service Discovery

Prometheus supports dynamic target discovery:
- **Static configs:** Manually defined in `prometheus.yml`
- **File-based:** Reads targets from JSON/YAML files
- **Kubernetes:** Auto-discovers pods/services
- **EC2:** Auto-discovers instances by tags
- **Consul/Etcd:** Service mesh integration

### 4. PromQL Basics

**Common queries:**
```promql
# Is service up?
up{job="node_exporter"}

# CPU usage percentage
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Request rate
rate(nginx_http_requests_total[5m])

# 95th percentile response time
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))
```

### 5. Alert Rules

Alert rules have three states:
- **Inactive:** Condition not met
- **Pending:** Condition met, waiting for `for` duration
- **Firing:** Condition met for duration, alert sent

**Example rule:**
```yaml
- alert: HighCPUUsage
  expr: cpu_usage_percent > 80
  for: 10m  # Must be true for 10 minutes
  labels:
    severity: warning
  annotations:
    summary: "High CPU on {{ $labels.instance }}"
```

### 6. Grafana Dashboard Concepts

**Data Sources:**
- Define where data comes from (Prometheus, Loki, etc.)
- Connection settings (URL, auth)
- Query language specific to source

**Panels:**
- Individual visualizations (graph, table, stat)
- Contains one or more queries
- Transformations and thresholds

**Variables:**
- Dynamic filters (e.g., select server)
- Used in queries: `{instance="$server"}`
- Allows interactive dashboards

### 7. Monitoring Best Practices

**The Four Golden Signals:**
1. **Latency:** Time to service a request
2. **Traffic:** Demand on your system
3. **Errors:** Rate of failed requests
4. **Saturation:** How "full" your service is

**RED Method (for services):**
- **Rate:** Requests per second
- **Errors:** Failed requests per second
- **Duration:** Request latency

**USE Method (for resources):**
- **Utilization:** % time resource is busy
- **Saturation:** Queued work
- **Errors:** Error count

### 8. High Availability Considerations

For production:
- **Prometheus:** Run multiple instances with federation
- **Grafana:** Use external database (MySQL/PostgreSQL)
- **Loki:** Distributed mode with object storage (S3)
- **AlertManager:** Cluster mode for deduplication

### 9. Data Retention Strategy

**Metrics (Prometheus):**
- Short-term: 15-30 days in Prometheus
- Long-term: Use Thanos or Cortex for downsampling

**Logs (Loki):**
- Hot storage: 7 days (recent logs)
- Archive: Move to object storage
- Compliance: Retain per regulations

### 10. Observability Triangle

```
        Metrics (What's wrong?)
           /\
          /  \
         /    \
        /      \
       /________\
    Logs      Traces
  (Why?)    (Where?)
```

- **Metrics:** Aggregated numbers (alerts trigger here)
- **Logs:** Detailed events (troubleshooting)
- **Traces:** Request flow (distributed systems)

---

## 🔧 Troubleshooting Communication

### Test Prometheus Scraping

```bash
# From monitoring server
curl http://10.0.2.115:9100/metrics

# Check Prometheus targets
curl http://localhost:9090/api/v1/targets | jq

# Manual scrape test
promtool check metrics http://10.0.2.115:9100/metrics
```

### Test Loki Push

```bash
# From application server
curl -X POST http://10.0.14.162:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{"streams": [{"stream": {"job": "test"}, "values": [["'$(date +%s%N)'", "test log"]]}]}'

# Check Loki labels
curl http://localhost:3100/loki/api/v1/labels | jq
```

### Test Grafana Datasources

```bash
# Test Prometheus datasource
curl -u admin:admin http://localhost:3000/api/datasources/proxy/1/api/v1/query?query=up

# Test Loki datasource
curl -u admin:admin http://localhost:3000/api/datasources/proxy/2/loki/api/v1/labels
```

### Network Connectivity

```bash
# Test port connectivity from monitoring server
telnet 10.0.2.115 9100
nc -zv 10.0.2.115 9100

# Check if service is listening
sudo netstat -tulpn | grep 9100

# Check firewall rules
sudo ufw status numbered
```

---

## 📚 Additional Resources

### Official Documentation
- [Prometheus Docs](https://prometheus.io/docs/)
- [Grafana Docs](https://grafana.com/docs/grafana/latest/)
- [Loki Docs](https://grafana.com/docs/loki/latest/)
- [PromQL Cheat Sheet](https://promlabs.com/promql-cheat-sheet/)

### Learning Path
1. ✅ Understand metrics vs logs vs traces
2. ✅ Deploy monitoring stack (you're here!)
3. ⏭️ Write custom exporters
4. ⏭️ Master PromQL queries
5. ⏭️ Create effective dashboards
6. ⏭️ Set up meaningful alerts
7. ⏭️ Implement distributed tracing (Jaeger/Tempo)

### Common Queries Examples

**Check service health:**
```promql
up{job="node_exporter"}
```

**CPU usage by server:**
```promql
100 - (avg by(instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memory usage:**
```promql
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100
```

**Disk usage:**
```promql
100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)
```

**HTTP request rate:**
```promql
rate(nginx_http_requests_total[5m])
```

**Database connections:**
```promql
pg_stat_database_numbackends{datname="bmi_tracker"}
```

**Custom app metrics:**
```promql
bmi_measurements_created_24h
bmi_category_count
bmi_app_healthy
```

---

## 🎯 Next Steps

1. **Explore Grafana:** Import dashboard ID 1860 for Node Exporter metrics
2. **Write Queries:** Practice PromQL in Prometheus UI
3. **Create Alerts:** Define thresholds for your application
4. **Custom Dashboards:** Build dashboards specific to BMI app
5. **Log Analysis:** Use LogQL to analyze application logs
6. **Scale Up:** Add more application servers to monitoring

---

## 🤝 Contributing

This guide is maintained as part of the BMI Health Tracker project. For improvements or corrections, please refer to the repository's contribution guidelines.

---

**Last Updated:** January 2026  
**Monitoring Stack Version:** Prometheus 2.48.0, Grafana Latest, Loki 2.9.3
