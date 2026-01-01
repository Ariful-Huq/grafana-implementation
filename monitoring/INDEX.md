# 🎯 Monitoring Folder - Quick Navigation Guide

## 📖 Documentation (Start Here!)

### For Beginners
1. **[QUICK_START.md](./QUICK_START.md)** ⭐ **START HERE**
   - 15-minute quick setup guide
   - Step-by-step instructions with screenshots
   - Perfect for first-time setup
   - **Read this first!**

2. **[README.md](./README.md)**
   - Architecture overview with diagrams
   - Component descriptions
   - What gets monitored
   - Dashboard previews

### For Advanced Setup
3. **[IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)**
   - Detailed manual setup instructions
   - Troubleshooting section
   - Configuration explanations
   - Security hardening

4. **[MONITORING_SUMMARY.md](./MONITORING_SUMMARY.md)**
   - Complete reference document
   - All available metrics
   - Prometheus query examples
   - Maintenance procedures

---

## 🚀 Automated Setup Scripts

### Quick Deploy (Recommended)
```bash
# 1. Setup monitoring server (run on monitoring server)
./scripts/setup-monitoring-server.sh

# 2. Setup application exporters (run on application server)
./scripts/setup-application-exporters.sh
```

**Files**:
- [scripts/setup-monitoring-server.sh](./scripts/setup-monitoring-server.sh) - Installs Prometheus, Grafana, Loki, AlertManager
- [scripts/setup-application-exporters.sh](./scripts/setup-application-exporters.sh) - Installs all exporters and Promtail

---

## ⚙️ Configuration Files

### Prometheus (Metrics Collection)
- [prometheus/prometheus.yml](./prometheus/prometheus.yml) - Main configuration with scrape targets
- [prometheus/alert_rules.yml](./prometheus/alert_rules.yml) - 20+ alert rules (CPU, memory, disk, DB, etc.)

**What it does**: Collects metrics from all exporters every 15 seconds

### Grafana (Visualization)
- [grafana/dashboards/system-overview.json](./grafana/dashboards/system-overview.json) - CPU, memory, disk, network
- [grafana/dashboards/bmi-application-metrics.json](./grafana/dashboards/bmi-application-metrics.json) - BMI-specific business metrics

**What it does**: Visualizes metrics in beautiful dashboards

### Loki (Log Aggregation)
- [loki/loki-config.yml](./loki/loki-config.yml) - Log storage and retention (31 days)

**What it does**: Stores and indexes logs from application server

### Promtail (Log Shipping)
- [promtail/promtail-config.yml](./promtail/promtail-config.yml) - Which logs to collect and ship

**What it does**: Collects logs from app server and sends to Loki

### AlertManager (Alerting)
- [alertmanager/alertmanager.yml](./alertmanager/alertmanager.yml) - Alert routing and notifications

**What it does**: Sends alerts via email, Slack, PagerDuty, Discord

---

## 🔌 Custom Exporter (Application Metrics)

**Location**: [exporters/bmi-app-exporter/](./exporters/bmi-app-exporter/)

**Files**:
- `package.json` - NPM dependencies
- `exporter.js` - Custom metrics collector (400+ lines)
- `ecosystem.config.js` - PM2 process configuration

**Custom Metrics Provided**:
- `bmi_measurements_total` - Total measurements count
- `bmi_measurements_created_24h` - Measurements in last 24h
- `bmi_measurements_created_1h` - Measurements in last hour
- `bmi_average_value` - Average BMI value
- `bmi_category_count{category="..."}` - Count by category
- `bmi_database_size_bytes` - Database size
- `bmi_table_size_bytes` - Table size
- `bmi_db_pool_*` - Connection pool stats
- `bmi_app_healthy` - Health status (1=healthy, 0=unhealthy)

**How to use**:
```bash
# View metrics
curl http://localhost:9091/metrics

# Check health
curl http://localhost:9091/health
```

---

## 📊 Complete File Tree

```
monitoring/
│
├── 📄 README.md                               # Architecture & overview
├── 📄 QUICK_START.md                          # ⭐ 15-minute setup guide
├── 📄 IMPLEMENTATION_GUIDE.md                 # Detailed manual setup
├── 📄 MONITORING_SUMMARY.md                   # Complete reference
├── 📄 INDEX.md                                # This file
│
├── 📁 scripts/                                # Automation scripts
│   ├── setup-monitoring-server.sh             # Monitoring server setup
│   └── setup-application-exporters.sh         # Application exporters setup
│
├── 📁 prometheus/                             # Metrics collection
│   ├── prometheus.yml                         # Scrape configuration
│   └── alert_rules.yml                        # Alert definitions
│
├── 📁 grafana/                                # Visualization
│   └── dashboards/
│       ├── system-overview.json               # System metrics dashboard
│       └── bmi-application-metrics.json       # Application dashboard
│
├── 📁 loki/                                   # Log aggregation
│   └── loki-config.yml                        # Loki configuration
│
├── 📁 promtail/                               # Log shipping
│   └── promtail-config.yml                    # Log collection config
│
├── 📁 alertmanager/                           # Alert routing
│   └── alertmanager.yml                       # Notification config
│
└── 📁 exporters/                              # Custom metrics
    └── bmi-app-exporter/
        ├── package.json                       # Dependencies
        ├── exporter.js                        # Custom exporter code
        └── ecosystem.config.js                # PM2 config
```

---

## 🎯 Quick Access by Task

### "I want to set this up quickly"
→ Read [QUICK_START.md](./QUICK_START.md) and run the automation scripts

### "I need to understand the architecture"
→ Read [README.md](./README.md) for architecture diagrams

### "I want to customize the setup"
→ Read [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) for manual steps

### "I need to troubleshoot an issue"
→ Check troubleshooting sections in [QUICK_START.md](./QUICK_START.md) or [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)

### "I want to add more alerts"
→ Edit [prometheus/alert_rules.yml](./prometheus/alert_rules.yml)

### "I want to customize dashboards"
→ Import [grafana/dashboards/*.json](./grafana/dashboards/) and modify in Grafana UI

### "I need to see all available metrics"
→ Check [MONITORING_SUMMARY.md](./MONITORING_SUMMARY.md) → Prometheus Queries section

### "I want to modify log collection"
→ Edit [promtail/promtail-config.yml](./promtail/promtail-config.yml)

### "I need to add custom application metrics"
→ Edit [exporters/bmi-app-exporter/exporter.js](./exporters/bmi-app-exporter/exporter.js)

---

## 🎓 Learning Path

### Day 1: Setup
1. Read [QUICK_START.md](./QUICK_START.md)
2. Run automation scripts
3. Access Grafana and explore dashboards

### Day 2: Understanding
1. Read [README.md](./README.md) to understand architecture
2. Explore Prometheus UI and run sample queries
3. View logs in Loki through Grafana

### Day 3: Customization
1. Read [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md)
2. Create a custom alert rule
3. Modify a dashboard panel

### Day 4: Advanced
1. Read [MONITORING_SUMMARY.md](./MONITORING_SUMMARY.md)
2. Write advanced PromQL queries
3. Add a custom metric to the exporter

---

## 📈 Monitoring Stack Components

| Component | Port | Config File | Purpose |
|-----------|------|-------------|---------|
| **Prometheus** | 9090 | `prometheus/prometheus.yml` | Metrics storage & queries |
| **Grafana** | 3000 | Auto-configured | Visualization & dashboards |
| **Loki** | 3100 | `loki/loki-config.yml` | Log aggregation |
| **AlertManager** | 9093 | `alertmanager/alertmanager.yml` | Alert routing |
| **Node Exporter** | 9100 | None (default) | System metrics |
| **PostgreSQL Exporter** | 9187 | Environment vars | Database metrics |
| **Nginx Exporter** | 9113 | Command args | Web server metrics |
| **BMI Custom Exporter** | 9091 | `exporters/bmi-app-exporter/.env` | Application metrics |
| **Promtail** | 9080 | `promtail/promtail-config.yml` | Log shipping |

---

## ✅ Pre-Flight Checklist

Before deploying, ensure you have:

- [ ] Two EC2 Ubuntu 22.04 servers (application + monitoring)
- [ ] Security groups allowing traffic between servers
- [ ] SSH access to both servers
- [ ] Database credentials for PostgreSQL exporter
- [ ] Read [QUICK_START.md](./QUICK_START.md)

---

## 🆘 Need Help?

1. **Setup Issues**: Check [QUICK_START.md](./QUICK_START.md) → Troubleshooting section
2. **Configuration Issues**: Check [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) → Troubleshooting
3. **Advanced Questions**: Check [MONITORING_SUMMARY.md](./MONITORING_SUMMARY.md) → Additional Resources
4. **Component-Specific**: Check official documentation:
   - Prometheus: https://prometheus.io/docs/
   - Grafana: https://grafana.com/docs/
   - Loki: https://grafana.com/docs/loki/

---

## 📊 Stats

- **Total Configuration Files**: 12
- **Total Documentation Files**: 5
- **Automation Scripts**: 2
- **Pre-built Dashboards**: 2
- **Pre-configured Alerts**: 20+
- **Custom Metrics**: 15+
- **Log Sources**: 5
- **Total Lines of Code**: ~2,800

---

## 🎉 Ready to Start?

**For quick setup (recommended)**:
```bash
# 1. Open QUICK_START.md
# 2. Follow the 3-step process
# 3. You'll be monitoring in ~15 minutes!
```

**For understanding first**:
```bash
# 1. Read README.md for architecture
# 2. Read QUICK_START.md for setup
# 3. Execute the scripts
```

---

**Happy Monitoring! 🚀**

*Last Updated: 2024*
*Version: 1.0*
*Maintained by: DevOps Team*
