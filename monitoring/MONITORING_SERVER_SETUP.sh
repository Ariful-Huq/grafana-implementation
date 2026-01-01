#!/bin/bash

#############################################################################
# BMI Health Tracker - Monitoring Server Setup Script
# 
# This script automates the setup of a complete monitoring infrastructure
# including Prometheus, Grafana, Loki, AlertManager, and Node Exporter
#
# Usage: 
#   1. SSH to monitoring server
#   2. git clone <your-repo>
#   3. chmod +x monitoring/MONITORING_SERVER_SETUP.sh
#   4. sudo ./monitoring/MONITORING_SERVER_SETUP.sh
#
# Requirements:
#   - Ubuntu 22.04 LTS
#   - Minimum 4GB RAM, 2 vCPU, 30GB disk
#   - Root or sudo access
#############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Version variables
PROMETHEUS_VERSION="2.48.0"
NODE_EXPORTER_VERSION="1.7.0"
LOKI_VERSION="2.9.3"
ALERTMANAGER_VERSION="0.26.0"

# Log functions
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

print_header() {
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}\n"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root or with sudo"
        exit 1
    fi
}

# Step 2: Initial Server Setup
setup_initial_system() {
    print_header "Step 2: Initial Server Setup"
    
    log_info "Updating system packages..."
    apt update -qq
    DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq
    log_success "System packages updated"
    
    log_info "Installing essential tools..."
    DEBIAN_FRONTEND=noninteractive apt install -y -qq \
        curl wget git vim htop net-tools ufw unzip software-properties-common jq
    log_success "Essential tools installed"
    
    log_info "Configuring firewall (UFW)..."
    # Enable UFW with allowing SSH first
    ufw --force enable
    ufw allow 22/tcp comment 'SSH'
    ufw allow 9090/tcp comment 'Prometheus'
    ufw allow 3000/tcp comment 'Grafana'
    ufw allow 3100/tcp comment 'Loki'
    ufw allow 9093/tcp comment 'AlertManager'
    ufw allow 9100/tcp comment 'Node Exporter'
    log_success "Firewall configured"
    
    log_info "Setting timezone to UTC..."
    timedatectl set-timezone UTC
    log_success "Timezone set"
    
    log_info "Creating service users..."
    useradd --no-create-home --shell /bin/false prometheus 2>/dev/null || true
    useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true
    useradd --no-create-home --shell /bin/false alertmanager 2>/dev/null || true
    useradd --no-create-home --shell /bin/false loki 2>/dev/null || true
    log_success "Service users created"
}

# Step 3: Install Prometheus
install_prometheus() {
    print_header "Step 3: Installing Prometheus ${PROMETHEUS_VERSION}"
    
    log_info "Downloading Prometheus..."
    cd /tmp
    wget -q https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
    log_success "Downloaded Prometheus"
    
    log_info "Extracting and installing Prometheus..."
    tar -xzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
    cd prometheus-${PROMETHEUS_VERSION}.linux-amd64
    
    cp prometheus /usr/local/bin/
    cp promtool /usr/local/bin/
    chown prometheus:prometheus /usr/local/bin/prometheus
    chown prometheus:prometheus /usr/local/bin/promtool
    log_success "Prometheus binaries installed"
    
    log_info "Creating Prometheus directories..."
    mkdir -p /etc/prometheus
    mkdir -p /var/lib/prometheus
    chown prometheus:prometheus /etc/prometheus
    chown prometheus:prometheus /var/lib/prometheus
    
    cp -r consoles /etc/prometheus/
    cp -r console_libraries /etc/prometheus/
    chown -R prometheus:prometheus /etc/prometheus/consoles
    chown -R prometheus:prometheus /etc/prometheus/console_libraries
    log_success "Prometheus directories created"
    
    log_info "Creating Prometheus configuration..."
    cat > /etc/prometheus/prometheus.yml <<'EOF'
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
EOF
    chown prometheus:prometheus /etc/prometheus/prometheus.yml
    log_success "Prometheus configuration created"
    
    log_info "Creating Prometheus systemd service..."
    cat > /etc/systemd/system/prometheus.service <<'EOF'
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
EOF
    log_success "Prometheus service created"
    
    log_info "Starting Prometheus..."
    systemctl daemon-reload
    systemctl enable prometheus
    systemctl start prometheus
    sleep 3
    
    if systemctl is-active --quiet prometheus; then
        log_success "Prometheus is running"
    else
        log_error "Prometheus failed to start"
        journalctl -u prometheus -n 20 --no-pager
        exit 1
    fi
    
    # Verify Prometheus is responding
    log_info "Verifying Prometheus..."
    if curl -s http://localhost:9090/-/healthy | grep -q "Prometheus is Healthy"; then
        log_success "Prometheus health check passed"
    else
        log_warning "Prometheus health check failed, but service is running"
    fi
}

# Step 4: Install Node Exporter
install_node_exporter() {
    print_header "Step 4: Installing Node Exporter ${NODE_EXPORTER_VERSION}"
    
    log_info "Downloading Node Exporter..."
    cd /tmp
    wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
    log_success "Downloaded Node Exporter"
    
    log_info "Extracting and installing Node Exporter..."
    tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
    cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
    chown node_exporter:node_exporter /usr/local/bin/node_exporter
    log_success "Node Exporter installed"
    
    log_info "Creating Node Exporter systemd service..."
    cat > /etc/systemd/system/node_exporter.service <<'EOF'
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
    log_success "Node Exporter service created"
    
    log_info "Starting Node Exporter..."
    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter
    sleep 2
    
    if systemctl is-active --quiet node_exporter; then
        log_success "Node Exporter is running"
    else
        log_error "Node Exporter failed to start"
        journalctl -u node_exporter -n 20 --no-pager
        exit 1
    fi
    
    # Verify metrics endpoint
    log_info "Verifying Node Exporter metrics..."
    if curl -s http://localhost:9100/metrics | grep -q "node_cpu_seconds_total"; then
        log_success "Node Exporter metrics available"
    else
        log_warning "Node Exporter metrics check inconclusive"
    fi
}

# Step 5: Install Grafana
install_grafana() {
    print_header "Step 5: Installing Grafana"
    
    log_info "Adding Grafana repository..."
    add-apt-repository -y "deb https://packages.grafana.com/oss/deb stable main" >/dev/null 2>&1
    wget -q -O - https://packages.grafana.com/gpg.key | apt-key add - >/dev/null 2>&1
    apt update -qq
    log_success "Grafana repository added"
    
    log_info "Installing Grafana..."
    DEBIAN_FRONTEND=noninteractive apt install -y -qq grafana
    log_success "Grafana installed"
    
    log_info "Configuring Grafana for network access..."
    # Backup original config
    cp /etc/grafana/grafana.ini /etc/grafana/grafana.ini.backup
    
    # Update http_addr to listen on all interfaces
    sed -i 's/^;http_addr =.*/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini
    sed -i 's/^http_addr = 127.0.0.1/http_addr = 0.0.0.0/' /etc/grafana/grafana.ini
    log_success "Grafana configured for network access"
    
    log_info "Starting Grafana..."
    systemctl daemon-reload
    systemctl enable grafana-server
    systemctl start grafana-server
    sleep 5
    
    if systemctl is-active --quiet grafana-server; then
        log_success "Grafana is running"
    else
        log_error "Grafana failed to start"
        journalctl -u grafana-server -n 20 --no-pager
        exit 1
    fi
    
    # Wait for Grafana to be ready
    log_info "Waiting for Grafana to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health | grep -q "ok"; then
            log_success "Grafana is healthy"
            break
        fi
        sleep 2
    done
}

# Step 6: Install Loki
install_loki() {
    print_header "Step 6: Installing Loki ${LOKI_VERSION}"
    
    log_info "Downloading Loki..."
    cd /tmp
    wget -q https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
    unzip -q loki-linux-amd64.zip
    log_success "Downloaded Loki"
    
    log_info "Installing Loki..."
    mv loki-linux-amd64 /usr/local/bin/loki
    chmod +x /usr/local/bin/loki
    log_success "Loki binary installed"
    
    log_info "Creating Loki directories..."
    mkdir -p /etc/loki
    mkdir -p /var/lib/loki/{wal,chunks,boltdb-shipper-active,boltdb-shipper-cache,boltdb-shipper-compactor,rules,rules-temp}
    chown -R loki:loki /var/lib/loki
    log_success "Loki directories created"
    
    log_info "Creating Loki configuration..."
    cat > /etc/loki/loki-config.yml <<'EOF'
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
EOF
    chown loki:loki /etc/loki/loki-config.yml
    log_success "Loki configuration created"
    
    log_info "Creating Loki systemd service..."
    cat > /etc/systemd/system/loki.service <<'EOF'
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
    log_success "Loki service created"
    
    log_info "Starting Loki..."
    systemctl daemon-reload
    systemctl enable loki
    systemctl start loki
    sleep 3
    
    if systemctl is-active --quiet loki; then
        log_success "Loki is running"
    else
        log_error "Loki failed to start"
        journalctl -u loki -n 20 --no-pager
        exit 1
    fi
    
    # Verify Loki
    log_info "Verifying Loki..."
    if curl -s http://localhost:3100/ready | grep -q "ready"; then
        log_success "Loki is ready"
    else
        log_warning "Loki readiness check inconclusive"
    fi
}

# Step 7: Install AlertManager
install_alertmanager() {
    print_header "Step 7: Installing AlertManager ${ALERTMANAGER_VERSION}"
    
    log_info "Downloading AlertManager..."
    cd /tmp
    wget -q https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
    log_success "Downloaded AlertManager"
    
    log_info "Extracting and installing AlertManager..."
    tar -xzf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
    cd alertmanager-${ALERTMANAGER_VERSION}.linux-amd64
    
    cp alertmanager /usr/local/bin/
    cp amtool /usr/local/bin/
    chown alertmanager:alertmanager /usr/local/bin/alertmanager
    chown alertmanager:alertmanager /usr/local/bin/amtool
    log_success "AlertManager binaries installed"
    
    log_info "Creating AlertManager directories..."
    mkdir -p /etc/alertmanager
    mkdir -p /var/lib/alertmanager
    chown alertmanager:alertmanager /etc/alertmanager
    chown alertmanager:alertmanager /var/lib/alertmanager
    log_success "AlertManager directories created"
    
    log_info "Creating AlertManager configuration..."
    cat > /etc/alertmanager/alertmanager.yml <<'EOF'
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
EOF
    chown alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
    log_success "AlertManager configuration created"
    
    log_info "Creating AlertManager systemd service..."
    cat > /etc/systemd/system/alertmanager.service <<'EOF'
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
EOF
    log_success "AlertManager service created"
    
    log_info "Starting AlertManager..."
    systemctl daemon-reload
    systemctl enable alertmanager
    systemctl start alertmanager
    sleep 2
    
    if systemctl is-active --quiet alertmanager; then
        log_success "AlertManager is running"
    else
        log_error "AlertManager failed to start"
        journalctl -u alertmanager -n 20 --no-pager
        exit 1
    fi
    
    # Verify AlertManager
    log_info "Verifying AlertManager..."
    if curl -s http://localhost:9093/-/healthy | grep -q "OK"; then
        log_success "AlertManager is healthy"
    else
        log_warning "AlertManager health check inconclusive"
    fi
}

# Step 8: Configure Prometheus with Alert Rules
configure_prometheus_alerts() {
    print_header "Step 8: Configuring Prometheus Alert Rules"
    
    log_info "Creating alert rules directory..."
    mkdir -p /etc/prometheus/alerts
    chown prometheus:prometheus /etc/prometheus/alerts
    log_success "Alert rules directory created"
    
    log_info "Creating basic alert rules..."
    cat > /etc/prometheus/alerts/basic_alerts.yml <<'EOF'
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
EOF
    chown prometheus:prometheus /etc/prometheus/alerts/basic_alerts.yml
    log_success "Alert rules created"
    
    log_info "Validating alert rules..."
    if /usr/local/bin/promtool check rules /etc/prometheus/alerts/basic_alerts.yml; then
        log_success "Alert rules are valid"
    else
        log_error "Alert rules validation failed"
        exit 1
    fi
    
    log_info "Reloading Prometheus configuration..."
    if curl -X POST http://localhost:9090/-/reload; then
        log_success "Prometheus configuration reloaded"
    else
        log_warning "Prometheus reload via API failed, restarting service..."
        systemctl restart prometheus
        sleep 3
    fi
    
    # Verify alerts are loaded
    log_info "Verifying alert rules in Prometheus..."
    sleep 2
    if curl -s http://localhost:9090/api/v1/rules | grep -q "basic_alerts"; then
        log_success "Alert rules loaded successfully"
    else
        log_warning "Could not verify alert rules"
    fi
}

# Configure Grafana datasources
configure_grafana_datasources() {
    print_header "Configuring Grafana Datasources"
    
    log_info "Waiting for Grafana API to be ready..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/api/health | grep -q "ok"; then
            break
        fi
        sleep 2
    done
    
    log_info "Adding Prometheus datasource to Grafana..."
    curl -s -X POST http://admin:admin@localhost:3000/api/datasources \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Prometheus",
            "type": "prometheus",
            "url": "http://localhost:9090",
            "access": "proxy",
            "isDefault": true,
            "basicAuth": false
        }' > /dev/null 2>&1 || log_warning "Prometheus datasource might already exist"
    log_success "Prometheus datasource added"
    
    log_info "Adding Loki datasource to Grafana..."
    curl -s -X POST http://admin:admin@localhost:3000/api/datasources \
        -H "Content-Type: application/json" \
        -d '{
            "name": "Loki",
            "type": "loki",
            "url": "http://localhost:3100",
            "access": "proxy",
            "basicAuth": false
        }' > /dev/null 2>&1 || log_warning "Loki datasource might already exist"
    log_success "Loki datasource added"
}

# Final verification
final_verification() {
    print_header "Final Verification"
    
    log_info "Checking all services status..."
    
    services=("prometheus" "node_exporter" "grafana-server" "loki" "alertmanager")
    all_running=true
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            log_success "$service is running"
        else
            log_error "$service is NOT running"
            all_running=false
        fi
    done
    
    if [ "$all_running" = false ]; then
        log_error "Some services are not running. Please check the logs."
        exit 1
    fi
    
    log_info "Checking network binding..."
    netstat -tulpn | grep -E '9090|3000|3100|9093|9100' > /tmp/monitoring_ports.txt || true
    
    if grep -q ":::9090" /tmp/monitoring_ports.txt || grep -q "0.0.0.0:9090" /tmp/monitoring_ports.txt; then
        log_success "Prometheus listening on all interfaces (port 9090)"
    else
        log_warning "Prometheus might only be listening on localhost"
    fi
    
    if grep -q ":::3000" /tmp/monitoring_ports.txt || grep -q "0.0.0.0:3000" /tmp/monitoring_ports.txt; then
        log_success "Grafana listening on all interfaces (port 3000)"
    else
        log_warning "Grafana might only be listening on localhost"
    fi
    
    log_info "Checking Prometheus targets..."
    targets=$(curl -s http://localhost:9090/api/v1/targets | jq -r '.data.activeTargets[].health' 2>/dev/null || echo "")
    if echo "$targets" | grep -q "up"; then
        log_success "Prometheus targets are up"
    else
        log_warning "Could not verify Prometheus targets"
    fi
    
    rm -f /tmp/monitoring_ports.txt
}

# Generate summary
generate_summary() {
    print_header "Installation Summary"
    
    # Get server IPs
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")
    
    cat > /root/monitoring-setup-summary.txt <<EOF
=================================================================
BMI Health Tracker - Monitoring Server Setup Complete
=================================================================

Installation Date: $(date)
Private IP: $PRIVATE_IP
Public IP: $PUBLIC_IP

Services Installed:
-------------------
✓ Prometheus ${PROMETHEUS_VERSION}
✓ Node Exporter ${NODE_EXPORTER_VERSION}
✓ Grafana (latest from repository)
✓ Loki ${LOKI_VERSION}
✓ AlertManager ${ALERTMANAGER_VERSION}

Service Status:
---------------
$(systemctl is-active prometheus >/dev/null 2>&1 && echo "✓ Prometheus: Running" || echo "✗ Prometheus: Not Running")
$(systemctl is-active node_exporter >/dev/null 2>&1 && echo "✓ Node Exporter: Running" || echo "✗ Node Exporter: Not Running")
$(systemctl is-active grafana-server >/dev/null 2>&1 && echo "✓ Grafana: Running" || echo "✗ Grafana: Not Running")
$(systemctl is-active loki >/dev/null 2>&1 && echo "✓ Loki: Running" || echo "✗ Loki: Not Running")
$(systemctl is-active alertmanager >/dev/null 2>&1 && echo "✓ AlertManager: Running" || echo "✗ AlertManager: Not Running")

Access URLs:
------------
Prometheus:   http://${PUBLIC_IP}:9090
Grafana:      http://${PUBLIC_IP}:3000
AlertManager: http://${PUBLIC_IP}:9093

Grafana Default Credentials:
----------------------------
Username: admin
Password: admin
(You will be prompted to change on first login)

Configuration Files:
--------------------
Prometheus:   /etc/prometheus/prometheus.yml
Grafana:      /etc/grafana/grafana.ini
Loki:         /etc/loki/loki-config.yml
AlertManager: /etc/alertmanager/alertmanager.yml
Alert Rules:  /etc/prometheus/alerts/basic_alerts.yml

Data Directories:
-----------------
Prometheus:   /var/lib/prometheus
Loki:         /var/lib/loki
Grafana:      /var/lib/grafana
AlertManager: /var/lib/alertmanager

Useful Commands:
----------------
# Check service status
sudo systemctl status prometheus
sudo systemctl status grafana-server
sudo systemctl status loki
sudo systemctl status alertmanager

# View logs
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f

# Reload Prometheus config
curl -X POST http://localhost:9090/-/reload

# Restart services
sudo systemctl restart prometheus
sudo systemctl restart grafana-server

Next Steps:
-----------
1. Access Grafana at http://${PUBLIC_IP}:3000 and change default password
2. Verify Prometheus targets at http://${PUBLIC_IP}:9090/targets
3. Add application servers using monitoring/Basic_Monitoring_Setup.sh
4. Configure email alerts in AlertManager
5. Import Grafana dashboards (recommended: Dashboard ID 1860 for Node Exporter)

Firewall Rules:
---------------
$(sudo ufw status numbered | grep -E '22|9090|3000|3100|9093|9100')

=================================================================
Setup completed successfully!
For detailed documentation, see: monitoring/MANUAL_SETUP_GUIDE.md
=================================================================
EOF
    
    cat /root/monitoring-setup-summary.txt
    
    log_success "Setup summary saved to: /root/monitoring-setup-summary.txt"
}

# Main execution
main() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   BMI Health Tracker - Monitoring Server Setup               ║
║   Automated Installation Script                              ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}\n"
    
    log_info "Starting monitoring server setup..."
    log_info "This will take approximately 5-10 minutes..."
    echo ""
    
    check_root
    
    # Execute setup steps
    setup_initial_system
    install_prometheus
    install_node_exporter
    install_grafana
    install_loki
    install_alertmanager
    configure_prometheus_alerts
    configure_grafana_datasources
    final_verification
    generate_summary
    
    echo ""
    print_header "Setup Complete!"
    
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "N/A")
    
    echo -e "${GREEN}Monitoring server setup completed successfully!${NC}\n"
    echo -e "Access your monitoring services:"
    echo -e "  ${BLUE}Prometheus:${NC}   http://${PUBLIC_IP}:9090"
    echo -e "  ${BLUE}Grafana:${NC}      http://${PUBLIC_IP}:3000 (admin/admin)"
    echo -e "  ${BLUE}AlertManager:${NC} http://${PUBLIC_IP}:9093"
    echo ""
    echo -e "Private IP for application server configuration: ${YELLOW}${PRIVATE_IP}${NC}"
    echo ""
    echo -e "Next steps:"
    echo -e "  1. Access Grafana and change default password"
    echo -e "  2. Add application servers using: ${YELLOW}monitoring/Basic_Monitoring_Setup.sh${NC}"
    echo -e "  3. Configure AlertManager for email notifications"
    echo ""
    echo -e "Full summary saved to: ${YELLOW}/root/monitoring-setup-summary.txt${NC}"
    echo ""
}

# Run main function
main "$@"
