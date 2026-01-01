# Network Configuration Guide

## 🌐 Overview

The BMI Health Tracker monitoring solution uses a **two-server architecture** with servers communicating via **private IP addresses** within the same VPC.

## 🏗️ Network Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS VPC (10.0.0.0/16)                       │
│                                                                     │
│  ┌─────────────────────────────┐  ┌─────────────────────────────┐ │
│  │   APPLICATION SERVER         │  │   MONITORING SERVER         │ │
│  │   Private IP: 10.0.1.10      │  │   Private IP: 10.0.1.20     │ │
│  │   Public IP: X.X.X.X         │  │   Public IP: Y.Y.Y.Y        │ │
│  │                              │  │                             │ │
│  │  Exporters (Listen):         │  │  Services (Listen):         │ │
│  │  • :9100 (Node Exporter)     │  │  • :9090 (Prometheus)       │ │
│  │  • :9187 (PostgreSQL)  ────────────▶ Scrapes Metrics         │ │
│  │  • :9113 (Nginx)             │  │  • :3100 (Loki)             │ │
│  │  • :9091 (BMI Custom)        │  │    ◀────── Receives Logs   │ │
│  │                              │  │  • :9093 (AlertManager)     │ │
│  │  Promtail (Send):            │  │  • :3000 (Grafana)          │ │
│  │  • Sends logs to :3100  ─────────▶                            │ │
│  │                              │  │                             │ │
│  └──────────────────────────────┘  └─────────────────────────────┘ │
│                                                                     │
│  Communication: PRIVATE IPs (10.0.1.x) - Stays within VPC          │
│  User Access: PUBLIC IP - Only to Grafana :3000                    │
└─────────────────────────────────────────────────────────────────────┘
```

## 🔐 Why Private IPs?

### When Servers Are in Same VPC/Subnet

**Always use Private IPs** for the following reasons:

### 1. **Security** 🛡️
- Traffic never leaves the VPC
- Exporters not exposed to internet
- Reduces attack surface
- No need to expose monitoring ports publicly

### 2. **Performance** ⚡
- Lower latency (no internet routing)
- Direct VPC network path
- More consistent connection
- Higher throughput

### 3. **Cost** 💰
- No data transfer charges between EC2 instances in same AZ
- Reduced data transfer costs for cross-AZ
- No NAT gateway charges for this traffic

### 4. **Reliability** ✅
- No dependency on internet connectivity
- More stable connection
- Less packet loss
- Better SLA

## 📋 IP Address Types

### Private IP Ranges (RFC 1918)

| Range | Example | Used By |
|-------|---------|---------|
| 10.0.0.0/8 | 10.0.1.10 | AWS Default VPC |
| 172.16.0.0/12 | 172.31.45.67 | AWS Custom VPCs |
| 192.168.0.0/16 | 192.168.1.100 | Local Networks |

### How to Find Private IP

**On Linux:**
```bash
# Method 1: Simple
hostname -I

# Method 2: Detailed
ip addr show | grep "inet " | grep -v 127.0.0.1

# Method 3: AWS metadata
curl http://169.254.169.254/latest/meta-data/local-ipv4

# Method 4: Network interface
ifconfig eth0 | grep "inet " | awk '{print $2}'
```

**On AWS Console:**
1. Go to EC2 → Instances
2. Select instance
3. Look for "Private IPv4 addresses" field

## 🔧 Security Group Configuration

### Application Server Security Group

**Inbound Rules:**

| Type | Protocol | Port | Source | Purpose |
|------|----------|------|--------|---------|
| SSH | TCP | 22 | Your IP | Management |
| HTTP | TCP | 80 | 0.0.0.0/0 | Application Access |
| HTTPS | TCP | 443 | 0.0.0.0/0 | Application Access |
| Custom TCP | TCP | 9100 | Monitoring SG | Node Exporter |
| Custom TCP | TCP | 9187 | Monitoring SG | PostgreSQL Exporter |
| Custom TCP | TCP | 9113 | Monitoring SG | Nginx Exporter |
| Custom TCP | TCP | 9091 | Monitoring SG | BMI Custom Exporter |

**Outbound Rules:**
- All traffic to 0.0.0.0/0 (for package downloads, Promtail → Loki)

### Monitoring Server Security Group

**Inbound Rules:**

| Type | Protocol | Port | Source | Purpose |
|------|----------|------|--------|---------|
| SSH | TCP | 22 | Your IP | Management |
| Custom TCP | TCP | 3000 | Your IP | Grafana Access |
| Custom TCP | TCP | 3100 | App Server SG | Loki (logs from Promtail) |
| Custom TCP | TCP | 9090 | Your IP | Prometheus (optional) |
| Custom TCP | TCP | 9093 | Your IP | AlertManager (optional) |

**Outbound Rules:**
- All traffic to 0.0.0.0/0 (for package downloads)
- Or specific: TCP to App Server SG on ports 9100, 9187, 9113, 9091

## 🚀 Setup Configuration

### During Monitoring Server Setup

```bash
sudo bash setup-monitoring-server.sh
```

**Prompt:**
```
Enter APPLICATION SERVER PRIVATE IP address: 10.0.1.10
```

**What gets configured:**
- Prometheus scrape targets use `10.0.1.10:9100`, `10.0.1.10:9187`, etc.
- No internet exposure of exporter ports

### During Application Server Setup

```bash
sudo bash setup-application-exporters.sh
```

**Prompt:**
```
Enter MONITORING SERVER PRIVATE IP address: 10.0.1.20
```

**What gets configured:**
- Promtail sends logs to `http://10.0.1.20:3100`
- Firewall allows monitoring server's private IP
- No internet exposure needed

## ✅ Verification

### 1. Check Private IPs Are Configured

**On Monitoring Server:**
```bash
# Check Prometheus targets use private IPs
cat /etc/prometheus/prometheus.yml | grep "targets:"
# Should show: ['10.0.1.10:9100'] not public IPs
```

**On Application Server:**
```bash
# Check Promtail uses private IP
cat /etc/promtail/promtail-config.yml | grep "url:"
# Should show: http://10.0.1.20:3100 not public IP

# Check firewall rules
sudo ufw status
# Should show monitoring server's private IP allowed
```

### 2. Test Connectivity (Private IPs)

**From Monitoring Server:**
```bash
# Get monitoring server's private IP
MY_IP=$(hostname -I | awk '{print $1}')
echo "My private IP: $MY_IP"

# Test connection to application server (replace with actual private IP)
APP_PRIVATE_IP="10.0.1.10"

# Test each exporter
curl http://$APP_PRIVATE_IP:9100/metrics | head  # Node Exporter
curl http://$APP_PRIVATE_IP:9187/metrics | head  # PostgreSQL
curl http://$APP_PRIVATE_IP:9113/metrics | head  # Nginx
curl http://$APP_PRIVATE_IP:9091/metrics | head  # BMI Custom

# Test with telnet
telnet $APP_PRIVATE_IP 9100
```

**From Application Server:**
```bash
# Get application server's private IP
MY_IP=$(hostname -I | awk '{print $1}')
echo "My private IP: $MY_IP"

# Test connection to monitoring server
MONITOR_PRIVATE_IP="10.0.1.20"

# Test Loki
curl http://$MONITOR_PRIVATE_IP:3100/ready
# Should return: ready

# Test with telnet
telnet $MONITOR_PRIVATE_IP 3100
```

### 3. Verify in Prometheus

1. Open Prometheus: `http://MONITORING_PUBLIC_IP:9090`
2. Go to Status → Targets
3. Check that all targets show **private IPs** in their endpoint URLs
4. All should be **UP** (green)

## 🔍 Troubleshooting

### Issue: Targets Showing as DOWN

**Cause:** Using wrong IP type or security groups misconfigured

**Solution:**
```bash
# 1. Verify private IPs
# On each server:
hostname -I

# 2. Check Prometheus config uses private IPs
cat /etc/prometheus/prometheus.yml | grep targets

# 3. Test connectivity from monitoring to app server
# On monitoring server:
curl http://APP_PRIVATE_IP:9100/metrics

# 4. Check security group allows private IP
# On application server:
sudo ufw status | grep 9100
```

### Issue: Can't Access Grafana

**Cause:** Trying to use private IP from external network

**Solution:**
- Access Grafana using **public IP**: `http://MONITORING_PUBLIC_IP:3000`
- Only internal communication (metrics/logs) uses private IPs
- User access always uses public IP (or domain name)

### Issue: Logs Not Appearing in Loki

**Cause:** Promtail configured with wrong IP or Loki port blocked

**Solution:**
```bash
# 1. Check Promtail config
cat /etc/promtail/promtail-config.yml | grep url
# Should be: http://MONITORING_PRIVATE_IP:3100

# 2. Test from app server
curl http://MONITORING_PRIVATE_IP:3100/ready

# 3. Check monitoring server security group allows port 3100 from app server

# 4. Check Promtail logs
sudo journalctl -u promtail -f
```

## 📊 Network Traffic Flow

### Metrics Collection (Pull Model)

```
Prometheus (Monitoring)  ──HTTP GET──▶  Exporter (Application)
   :9090                                     :9100, :9187, :9113, :9091
   
Every 15 seconds, Prometheus pulls metrics from each exporter
Uses: Private IP communication
```

### Log Shipping (Push Model)

```
Promtail (Application)  ──HTTP POST──▶  Loki (Monitoring)
   :9080                                    :3100
   
Continuously pushes logs as they're generated
Uses: Private IP communication
```

### User Access

```
Your Browser  ──HTTPS──▶  Grafana (Monitoring)
                             :3000 (Public IP)
   
You access Grafana via public IP from anywhere
Uses: Public IP
```

## 🎯 Best Practices

1. **Always Use Private IPs for Internal Communication**
   - Between application and monitoring servers
   - Within VPC traffic

2. **Use Public IPs Only For**
   - SSH access to servers
   - Grafana web interface access
   - Application public-facing services

3. **Security Group Configuration**
   - Reference security groups by ID, not CIDR blocks
   - Allows automatic IP updates when instances change
   - Example: Source = `sg-xxxxx` instead of `10.0.1.20/32`

4. **Network Segmentation**
   - Consider separate subnets for app and monitoring
   - Use Network ACLs for additional security layer
   - Monitor VPC flow logs for traffic analysis

5. **Documentation**
   - Document the private IPs used
   - Update configs if instances are recreated
   - Use Elastic IPs for public access (optional)

## 📝 Configuration Summary

| Communication Path | Direction | IP Type | Ports | Protocol |
|-------------------|-----------|---------|-------|----------|
| Prometheus → Exporters | Pull | Private | 9100, 9187, 9113, 9091 | HTTP |
| Promtail → Loki | Push | Private | 3100 | HTTP |
| User → Grafana | Access | Public | 3000 | HTTP |
| User → SSH | Access | Public | 22 | SSH |

## 🔗 Additional Resources

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [RFC 1918 - Private Address Space](https://tools.ietf.org/html/rfc1918)
- [Prometheus Security Best Practices](https://prometheus.io/docs/operating/security/)

---

**Key Takeaway:** Use **private IPs** for all monitoring traffic between servers in the same VPC. This ensures security, performance, and cost efficiency. Only use **public IPs** for external user access to Grafana.

---

## 🧑‍💻 Author
**Md. Sarowar Alam**  
Lead DevOps Engineer, Hogarth Worldwide  
📧 Email: sarowar@hotmail.com  
🔗 LinkedIn: [linkedin.com/in/sarowar](https://www.linkedin.com/in/sarowar/)

---
