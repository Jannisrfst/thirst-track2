#!/bin/bash

# Security and Network Configuration Script
# This script configures firewall, network access, and security settings for headless operation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Security and Network Configuration ===${NC}"

# Function to print status
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run with sudo privileges"
    exit 1
fi

# Configure UFW (Uncomplicated Firewall)
print_status "Configuring firewall (UFW)..."

# Install UFW if not already installed
apt update
apt install -y ufw

# Reset UFW to defaults
ufw --force reset

# Set default policies
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (important for remote access)
ufw allow ssh
ufw allow 22/tcp

# Allow HTTP for web interface
ufw allow 80/tcp
ufw allow http

# Allow HTTPS (for future SSL setup)
ufw allow 443/tcp
ufw allow https

# Allow Flask backend port (only from local network)
ufw allow from 192.168.0.0/16 to any port 5001
ufw allow from 10.0.0.0/8 to any port 5001
ufw allow from 172.16.0.0/12 to any port 5001

# Allow PostgreSQL only from localhost
ufw allow from 127.0.0.1 to any port 5432

# Enable UFW
ufw --force enable

print_status "Firewall configured successfully"

# Configure fail2ban for SSH protection
print_status "Installing and configuring fail2ban..."

apt install -y fail2ban

# Create fail2ban configuration for SSH
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

# Start and enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban

print_status "fail2ban configured for SSH protection"

# Configure automatic security updates
print_status "Configuring automatic security updates..."

apt install -y unattended-upgrades apt-listchanges

# Configure unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};

Unattended-Upgrade::Package-Blacklist {
};

Unattended-Upgrade::DevRelease "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "02:00";
EOF

# Enable automatic updates
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

print_status "Automatic security updates configured"

# Secure SSH configuration
print_status "Hardening SSH configuration..."

# Backup original SSH config
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Create secure SSH configuration
cat > /etc/ssh/sshd_config.d/99-thirst-track-security.conf << EOF
# Thirst Track Security Configuration

# Disable root login
PermitRootLogin no

# Use only SSH protocol 2
Protocol 2

# Change default port (optional - uncomment if desired)
# Port 2222

# Disable password authentication (uncomment after setting up key-based auth)
# PasswordAuthentication no

# Disable empty passwords
PermitEmptyPasswords no

# Limit login attempts
MaxAuthTries 3
MaxStartups 2

# Disable X11 forwarding
X11Forwarding no

# Disable unused authentication methods
ChallengeResponseAuthentication no
UsePAM yes

# Set login grace time
LoginGraceTime 30

# Allow only specific users (adjust as needed)
AllowUsers jannisreufsteck

# Disable unused features
AllowAgentForwarding no
AllowTcpForwarding no
GatewayPorts no
PermitTunnel no
EOF

# Test SSH configuration
if sshd -t; then
    print_status "SSH configuration is valid"
    systemctl reload ssh
else
    print_error "SSH configuration is invalid, reverting changes"
    rm /etc/ssh/sshd_config.d/99-thirst-track-security.conf
    exit 1
fi

# Configure network settings for kiosk mode
print_status "Configuring network settings..."

# Disable IPv6 if not needed (reduces attack surface)
cat >> /etc/sysctl.conf << EOF

# Thirst Track Security Settings
# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Network security
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
EOF

# Apply sysctl settings
sysctl -p

# Set up log rotation for application logs
print_status "Configuring log rotation..."

cat > /etc/logrotate.d/thirst-track << EOF
/home/jannisreufsteck/thirst-track2/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 jannisreufsteck jannisreufsteck
    postrotate
        systemctl reload thirst-track-backend || true
    endscript
}
EOF

# Create a system monitoring script
print_status "Setting up system monitoring..."

cat > /usr/local/bin/thirst-track-monitor << 'EOF'
#!/bin/bash

# System monitoring script for Thirst Track
LOG_FILE="/var/log/thirst-track-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Function to log messages
log_message() {
    echo "[$DATE] $1" >> "$LOG_FILE"
}

# Check if services are running
if ! systemctl is-active --quiet thirst-track-backend; then
    log_message "WARNING: Thirst Track backend service is not running"
    systemctl start thirst-track-backend
fi

if ! systemctl is-active --quiet nginx; then
    log_message "WARNING: Nginx service is not running"
    systemctl start nginx
fi

if ! systemctl is-active --quiet postgresql; then
    log_message "WARNING: PostgreSQL service is not running"
    systemctl start postgresql
fi

# Check disk space
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    log_message "CRITICAL: Disk usage is at ${DISK_USAGE}%"
fi

# Check memory usage
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$MEMORY_USAGE" -gt 95 ]; then
    log_message "CRITICAL: Memory usage is at ${MEMORY_USAGE}%"
fi

# Check if web interface is responding
if ! curl -s -f http://localhost > /dev/null; then
    log_message "WARNING: Web interface is not responding"
fi

log_message "System check completed"
EOF

chmod +x /usr/local/bin/thirst-track-monitor

# Set up cron job for monitoring
print_status "Setting up monitoring cron job..."

# Add monitoring cron job (every 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/thirst-track-monitor") | crontab -

# Create network information script
print_status "Creating network information script..."

cat > /home/jannisreufsteck/thirst-track2/deployment/scripts/network-info.sh << 'EOF'
#!/bin/bash

# Network Information Script
# Shows current network configuration and access information

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Thirst Track Network Information ===${NC}"
echo ""

# Get IP addresses
echo -e "${YELLOW}Network Interfaces:${NC}"
ip addr show | grep -E "inet " | grep -v "127.0.0.1" | while read line; do
    IP=$(echo $line | awk '{print $2}' | cut -d'/' -f1)
    INTERFACE=$(echo $line | awk '{print $NF}')
    echo "  $INTERFACE: $IP"
done

echo ""

# Get primary IP
PRIMARY_IP=$(hostname -I | awk '{print $1}')
echo -e "${YELLOW}Primary IP Address:${NC} $PRIMARY_IP"

echo ""
echo -e "${YELLOW}Access URLs:${NC}"
echo "  Local: http://localhost"
echo "  Network: http://$PRIMARY_IP"

echo ""
echo -e "${YELLOW}Service Status:${NC}"
systemctl is-active --quiet nginx && echo "  Nginx: Running" || echo "  Nginx: Stopped"
systemctl is-active --quiet thirst-track-backend && echo "  Backend: Running" || echo "  Backend: Stopped"
systemctl is-active --quiet postgresql && echo "  Database: Running" || echo "  Database: Stopped"

echo ""
echo -e "${YELLOW}Firewall Status:${NC}"
ufw status | head -5

echo ""
echo -e "${YELLOW}QR Code for Network Access:${NC}"
if command -v qrencode > /dev/null; then
    qrencode -t ansiutf8 "http://$PRIMARY_IP"
else
    echo "  Install qrencode to display QR code: sudo apt install qrencode"
    echo "  URL: http://$PRIMARY_IP"
fi
EOF

chmod +x /home/jannisreufsteck/thirst-track2/deployment/scripts/network-info.sh

# Install QR code generator for easy mobile access
print_status "Installing QR code generator..."
apt install -y qrencode

print_status "Security and network configuration completed!"
echo ""
echo -e "${YELLOW}Security Summary:${NC}"
echo "✓ Firewall (UFW) configured and enabled"
echo "✓ fail2ban installed for SSH protection"
echo "✓ Automatic security updates enabled"
echo "✓ SSH hardened"
echo "✓ Network security settings applied"
echo "✓ Log rotation configured"
echo "✓ System monitoring enabled"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run: /home/jannisreufsteck/thirst-track2/deployment/scripts/network-info.sh"
echo "2. Consider setting up SSH key authentication"
echo "3. Test firewall rules with: sudo ufw status verbose"
echo "4. Monitor logs with: tail -f /var/log/thirst-track-monitor.log"
