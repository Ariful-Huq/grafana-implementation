#!/bin/bash

##############################################################################
# Basic Web Server Monitoring Setup Script
# 
# This script sets up monitoring for a web server by installing Node Exporter
# and configuring it to be scraped by your existing Prometheus monitoring server.
#
# Prerequisites:
# - Fresh Ubuntu 22.04 server
# - Git repository cloned
# - SSH access with sudo privileges
#
# Usage: 
#   sudo ./monitoring/Basic_Monitoring_Setup.sh
#
# What this installs:
# - Node Exporter (system metrics: CPU, RAM, disk, network)
# - UFW firewall rules (secure access)
#
##############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Versions
NODE_EXPORTER_VERSION="1.7.0"

# Functions
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

log_step() {
    echo ""
    echo -e "${CYAN}===================================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}===================================================================${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "Please run as root or with sudo"
        exit 1
    fi
}

# Get EC2 Public IP (IMDSv2)
get_ec2_public_ip() {
    # Try to get token for IMDSv2
    local TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
        --connect-timeout 2 2>/dev/null)
    
    if [ -n "$TOKEN" ]; then
        # Use IMDSv2 with token
        local PUBLIC_IP=$(curl -s \
            -H "X-aws-ec2-metadata-token: $TOKEN" \
            --connect-timeout 2 \
            http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    else
        # Fallback to IMDSv1
        local PUBLIC_IP=$(curl -s --connect-timeout 2 \
            http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)
    fi
    
    # Trim whitespace and return
    echo "$PUBLIC_IP" | tr -d '[:space:]'
}

# Banner
clear
echo -e "${GREEN}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║          Basic Web Server Monitoring Setup Script               ║
║                                                                  ║
║  This script will install Node Exporter to monitor:             ║
║  • CPU Usage                                                     ║
║  • Memory/RAM Usage                                              ║
║  • Disk Space                                                    ║
║  • Network Traffic                                               ║
║  • System Load & Uptime                                          ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

check_root

# Get current server info
log_step "STEP 1: Gathering Server Information"

HOSTNAME=$(hostname)
PRIVATE_IP=$(hostname -I | awk '{print $1}')
PUBLIC_IP=$(get_ec2_public_ip)
[ -z "$PUBLIC_IP" ] && PUBLIC_IP="Not available"

log_info "Server Hostname: $HOSTNAME"
log_info "Private IP: $PRIVATE_IP"
log_info "Public IP: $PUBLIC_IP"

# Get monitoring server IP
echo ""
log_info "Please provide your Monitoring Server information:"
echo ""
read -p "Enter MONITORING SERVER PRIVATE IP (e.g., 10.0.12.221): " MONITORING_IP

if [ -z "$MONITORING_IP" ]; then
    log_error "Monitoring server IP is required!"
    exit 1
fi

read -p "Enter MONITORING SERVER PUBLIC IP (for access URLs): " MONITORING_PUBLIC_IP

if [ -z "$MONITORING_PUBLIC_IP" ]; then
    log_warning "No public IP provided. Will use placeholder in URLs."
    MONITORING_PUBLIC_IP="<MONITORING_SERVER_PUBLIC_IP>"
fi

log_info "Will configure access for monitoring server: $MONITORING_IP"
log_info "Monitoring server public access: $MONITORING_PUBLIC_IP"

# Optional: Get server identifier
echo ""
read -p "Enter a name for this server (e.g., PROD01) [default: $HOSTNAME]: " SERVER_NAME
SERVER_NAME=${SERVER_NAME:-$HOSTNAME}

log_info "Server will be identified as: $SERVER_NAME"

# Confirmation
echo ""
log_warning "Ready to install monitoring with these settings:"
echo "  • This Server: $SERVER_NAME ($PRIVATE_IP)"
echo "  • Monitoring Server: $MONITORING_IP"
echo "  • Node Exporter Port: 9100"
echo ""
read -p "Continue with installation? (yes/no): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]] && [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    log_warning "Installation cancelled by user"
    exit 0
fi

#=============================================================================
# SYSTEM UPDATE
#=============================================================================
log_step "STEP 2: Updating System Packages"

apt update
apt upgrade -y
apt install -y curl wget vim htop net-tools ufw

log_success "System updated"

#=============================================================================
# CREATE SERVICE USER
#=============================================================================
log_step "STEP 3: Creating Service User"

useradd --no-create-home --shell /bin/false node_exporter || true

log_success "Service user created"

#=============================================================================
# INSTALL NODE EXPORTER
#=============================================================================
log_step "STEP 4: Installing Node Exporter ${NODE_EXPORTER_VERSION}"

# Stop service if already running
if systemctl is-active --quiet node_exporter 2>/dev/null; then
    log_info "Stopping existing Node Exporter service..."
    systemctl stop node_exporter
fi

cd /tmp

# Download Node Exporter
log_info "Downloading Node Exporter..."
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

if [ $? -ne 0 ]; then
    log_error "Failed to download Node Exporter"
    exit 1
fi

# Extract and install
log_info "Extracting and installing..."
tar -xzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cp node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

log_success "Node Exporter installed"

#=============================================================================
# CREATE SYSTEMD SERVICE
#=============================================================================
log_step "STEP 5: Creating Systemd Service"

cat > /etc/systemd/system/node_exporter.service <<'EOFSVC'
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
EOFSVC

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Wait a moment for service to start
sleep 2

# Check service status
if systemctl is-active --quiet node_exporter; then
    log_success "Node Exporter service started successfully"
else
    log_error "Node Exporter service failed to start"
    systemctl status node_exporter
    exit 1
fi

#=============================================================================
# CONFIGURE FIREWALL
#=============================================================================
log_step "STEP 6: Configuring Firewall (UFW)"

# Check if UFW is active
if ! ufw status | grep -q "Status: active"; then
    log_info "Enabling UFW firewall..."
    # Allow SSH before enabling
    ufw allow 22/tcp
    echo "y" | ufw enable
fi

# Allow common web server ports
log_info "Allowing web server ports..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Allow Node Exporter from monitoring server ONLY
log_info "Allowing Node Exporter access from monitoring server..."
ufw allow from $MONITORING_IP to any port 9100 comment "Node Exporter from Monitoring"

# Reload UFW
ufw reload

log_success "Firewall configured"

#=============================================================================
# VERIFY INSTALLATION
#=============================================================================
log_step "STEP 7: Verifying Installation"

# Test Node Exporter locally
log_info "Testing Node Exporter endpoint..."
METRICS_TEST=$(curl -s http://localhost:9100/metrics | head -5)

if [ -n "$METRICS_TEST" ]; then
    log_success "Node Exporter is responding on port 9100"
    echo ""
    log_info "Sample metrics:"
    echo "$METRICS_TEST"
else
    log_error "Node Exporter is not responding"
    exit 1
fi

# Check listening port
log_info "Checking listening ports..."
if netstat -tulpn | grep -q ":9100"; then
    log_success "Node Exporter is listening on port 9100"
else
    log_warning "Could not verify port 9100 (netstat check failed)"
fi

#=============================================================================
# CLEANUP
#=============================================================================
log_step "STEP 8: Cleaning Up"

cd /tmp
rm -rf node_exporter-*

log_success "Cleanup completed"

#=============================================================================
# FINAL SUMMARY
#=============================================================================
echo ""
log_step "INSTALLATION COMPLETE!"

echo ""
log_success "╔════════════════════════════════════════════════════════════════╗"
log_success "║  Node Exporter Successfully Installed and Running!             ║"
log_success "╚════════════════════════════════════════════════════════════════╝"
echo ""

log_info "Server Information:"
echo "  • Server Name: ${GREEN}$SERVER_NAME${NC}"
echo "  • Private IP: ${GREEN}$PRIVATE_IP${NC}"
echo "  • Public IP: ${GREEN}$PUBLIC_IP${NC}"
echo "  • Node Exporter Port: ${GREEN}9100${NC}"
echo "  • Status: ${GREEN}Running${NC}"
echo ""

log_info "Test Endpoints:"
echo "  Local: ${CYAN}curl http://localhost:9100/metrics${NC}"
echo "  From Monitoring Server: ${CYAN}curl http://$PRIVATE_IP:9100/metrics${NC}"
echo ""

log_info "Service Management:"
echo "  Check Status:  ${CYAN}sudo systemctl status node_exporter${NC}"
echo "  View Logs:     ${CYAN}sudo journalctl -u node_exporter -f${NC}"
echo "  Restart:       ${CYAN}sudo systemctl restart node_exporter${NC}"
echo ""

log_warning "═══════════════════════════════════════════════════════════════"
log_warning "NEXT STEPS: Configure Prometheus on Monitoring Server"
log_warning "═══════════════════════════════════════════════════════════════"
echo ""
log_info "1. SSH to your Monitoring Server (IP: $MONITORING_IP)"
echo ""
log_info "2. Edit Prometheus configuration:"
echo -e "   ${CYAN}sudo nano /etc/prometheus/prometheus.yml${NC}"
echo ""
log_info "3. Add this scrape config to the scrape_configs section:"
echo ""
echo -e "${YELLOW}  - job_name: '${SERVER_NAME}'${NC}"
echo -e "${YELLOW}    static_configs:${NC}"
echo -e "${YELLOW}      - targets: ['${PRIVATE_IP}:9100']${NC}"
echo -e "${YELLOW}        labels:${NC}"
echo -e "${YELLOW}          instance: '${SERVER_NAME}'${NC}"
echo -e "${YELLOW}          environment: 'production'${NC}"
echo -e "${YELLOW}          role: 'web'${NC}"
echo ""
log_info "4. Reload Prometheus:"
echo -e "   ${CYAN}curl -X POST http://localhost:9090/-/reload${NC}"
echo ""
log_info "5. Verify target in Prometheus UI:"
echo -e "   ${CYAN}http://${MONITORING_PUBLIC_IP}:9090/targets${NC}"
echo "   Look for job '${SERVER_NAME}' - should be UP (green)"
echo ""
log_info "6. View metrics in Grafana:"
echo -e "   ${CYAN}http://${MONITORING_PUBLIC_IP}:3000${NC}"
echo "   • Go to Explore"
echo -e "   • Query: ${CYAN}up{instance=\"${SERVER_NAME}\"}${NC}"
echo "   • Import Dashboard ID 1860 for full system metrics"
echo ""

log_success "═══════════════════════════════════════════════════════════════"
log_success "Setup Complete! Your server is ready to be monitored."
log_success "═══════════════════════════════════════════════════════════════"
echo ""

# Create a summary file
SUMMARY_FILE="/root/monitoring-setup-summary.txt"
cat > $SUMMARY_FILE <<EOF
═══════════════════════════════════════════════════════════════
Web Server Monitoring Setup Summary
═══════════════════════════════════════════════════════════════

Installation Date: $(date)
Server Name: $SERVER_NAME
Private IP: $PRIVATE_IP
Public IP: $PUBLIC_IP
Monitoring Server: $MONITORING_IP

Node Exporter: Running on port 9100

═══════════════════════════════════════════════════════════════
Prometheus Configuration to Add
═══════════════════════════════════════════════════════════════

Add this to /etc/prometheus/prometheus.yml on monitoring server:

  - job_name: '$SERVER_NAME'
    static_configs:
      - targets: ['$PRIVATE_IP:9100']
        labels:
          instance: '$SERVER_NAME'
          environment: 'production'
          role: 'web'

Then reload Prometheus:
  curl -X POST http://localhost:9090/-/reload

═══════════════════════════════════════════════════════════════
Verification Commands
═══════════════════════════════════════════════════════════════

Test locally:
  curl http://localhost:9100/metrics

Check service:
  sudo systemctl status node_exporter

View logs:
  sudo journalctl -u node_exporter -f

Check firewall:
  sudo ufw status

═══════════════════════════════════════════════════════════════
Grafana Dashboard
═══════════════════════════════════════════════════════════════

Import Dashboard ID: 1860
Filter by Host: $SERVER_NAME

This dashboard shows:
  • CPU Usage
  • Memory Usage
  • Disk Space
  • Network Traffic
  • System Load

═══════════════════════════════════════════════════════════════
EOF

log_info "Summary saved to: ${GREEN}$SUMMARY_FILE${NC}"
log_info "View anytime with: ${CYAN}cat $SUMMARY_FILE${NC}"
echo ""
