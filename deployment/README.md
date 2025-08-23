# Thirst Track - Raspberry Pi Production Deployment Guide

This guide provides comprehensive step-by-step instructions for deploying the Thirst Track inventory management application on a Raspberry Pi 4 for production use as a standalone kiosk system.

## 🎯 Deployment Overview

The deployment creates a completely headless and self-contained system with:

- **Frontend**: React application served via nginx, accessible on local network
- **Backend**: Flask API server running as systemd service with Gunicorn
- **Database**: PostgreSQL with automatic backups and monitoring
- **Scanner**: USB barcode scanner integration with automatic device detection
- **Security**: Firewall, fail2ban, automatic updates, and hardened SSH
- **Monitoring**: System health checks and automatic service recovery

## 📋 Prerequisites

### Hardware Requirements
- Raspberry Pi 4 (4GB RAM recommended)
- MicroSD card (32GB minimum, Class 10)
- USB barcode scanner
- Network connection (Ethernet or WiFi)
- Power supply (official Pi 4 adapter recommended)

### Software Requirements
- Raspberry Pi OS Lite (64-bit) - Latest version
- SSH access to the Pi
- Internet connection for package downloads

## 🚀 Quick Start Deployment

### Step 1: Prepare Raspberry Pi

1. **Flash Raspberry Pi OS**:
   ```bash
   # Use Raspberry Pi Imager to flash Pi OS Lite to SD card
   # Enable SSH and configure WiFi if needed
   ```

2. **Initial Pi Setup**:
   ```bash
   # SSH into your Pi
   ssh pi@<pi-ip-address>
   
   # Update system
   sudo apt update && sudo apt upgrade -y
   
   # Install git
   sudo apt install -y git
   ```

### Step 2: Clone and Deploy Application

1. **Clone Repository**:
   ```bash
   cd /home/pi
   git clone https://github.com/Jannisrfst/thirst-track2.git
   cd thirst-track2
   ```

2. **Run Automated Deployment**:
   ```bash
   # Make deployment script executable
   chmod +x deployment/scripts/deploy.sh
   
   # Run full deployment (this will take 15-30 minutes)
   ./deployment/scripts/deploy.sh
   ```

3. **Configure Environment**:
   ```bash
   # Edit environment variables
   nano .env
   
   # Update these critical settings:
   # - DB_PASSWORD=your_secure_password
   # - EMAIL_FROM=your_email@gmail.com
   # - EMAIL_PASSWORD=your_app_password
   # - SECRET_KEY=your_secret_key
   ```

### Step 3: Start Services

```bash
# Start all services
sudo systemctl start thirst-track-backend
sudo systemctl start nginx

# Enable auto-start on boot
sudo systemctl enable thirst-track-backend
sudo systemctl enable nginx
sudo systemctl enable postgresql
```

### Step 4: Test Deployment

```bash
# Run comprehensive test suite
./deployment/scripts/test-deployment.sh

# Check network access
./deployment/scripts/network-info.sh
```

## 📖 Detailed Deployment Steps

### Database Configuration

The deployment automatically sets up PostgreSQL with:
- Optimized configuration for Raspberry Pi
- Secure user and database creation
- Automatic backups (daily at 2 AM)
- Performance monitoring

**Manual database operations**:
```bash
# Create backup
./deployment/scripts/backup-database.sh backup

# Monitor database
./deployment/scripts/monitor-database.sh all

# View database stats
./deployment/scripts/monitor-database.sh stats
```

### Frontend Build Process

The React frontend is built for production with:
- Optimized bundle size
- Asset compression
- Static file serving via nginx

**Manual frontend operations**:
```bash
# Rebuild frontend
./deployment/scripts/build-frontend.sh

# Check build output
ls -la frontend/dist/
```

### Barcode Scanner Setup

USB barcode scanner configuration includes:
- Automatic device detection
- Permission configuration
- Testing utilities

**Scanner configuration**:
```bash
# Detect connected scanners
./deployment/scripts/detect-scanner.sh

# Test scanner functionality
./deployment/scripts/test-scanner.py

# Configure scanner device
./deployment/scripts/configure-scanner.sh
```

### Security Configuration

Security hardening includes:
- UFW firewall with restricted access
- fail2ban for SSH protection
- Automatic security updates
- SSH hardening
- System monitoring

**Security management**:
```bash
# Check firewall status
sudo ufw status verbose

# View fail2ban status
sudo fail2ban-client status

# Check security logs
sudo tail -f /var/log/auth.log
```

## 🔧 Service Management

### Systemd Services

**Backend Service**:
```bash
# Status
sudo systemctl status thirst-track-backend

# Logs
journalctl -u thirst-track-backend -f

# Restart
sudo systemctl restart thirst-track-backend
```

**Nginx Service**:
```bash
# Status
sudo systemctl status nginx

# Test configuration
sudo nginx -t

# Reload configuration
sudo systemctl reload nginx
```

**PostgreSQL Service**:
```bash
# Status
sudo systemctl status postgresql

# Connect to database
psql -h localhost -U thirsttrack_user -d thirsttrack
```

### Log Management

**Application Logs**:
```bash
# Backend logs
tail -f logs/thirst-track.log

# Access logs
tail -f logs/access.log

# Error logs
tail -f logs/error.log
```

**System Logs**:
```bash
# System monitor logs
tail -f /var/log/thirst-track-monitor.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

## 🌐 Network Access

### Local Network Access

After deployment, the application is accessible via:

- **Local**: `http://localhost`
- **Network**: `http://<pi-ip-address>`

**Get network information**:
```bash
./deployment/scripts/network-info.sh
```

### Mobile Access

The network info script generates a QR code for easy mobile access:
```bash
# Install QR code generator (if not already installed)
sudo apt install qrencode

# Display QR code for mobile access
./deployment/scripts/network-info.sh
```

### Port Configuration

Default ports:
- **80**: Web interface (nginx)
- **5001**: Backend API (internal)
- **5432**: PostgreSQL (localhost only)
- **22**: SSH (restricted)

## 🔍 Testing and Verification

### Automated Testing

```bash
# Full system test
./deployment/scripts/test-deployment.sh

# Database health check
./deployment/scripts/monitor-database.sh health

# Scanner test
./deployment/scripts/test-scanner.py
```

### Manual Testing

1. **Web Interface**:
   - Open browser to `http://<pi-ip>`
   - Verify inventory list loads
   - Test adding/removing items
   - Test CSV upload functionality

2. **Barcode Scanner**:
   - Connect USB scanner
   - Run scanner test script
   - Scan test barcode
   - Verify inventory updates

3. **API Endpoints**:
   ```bash
   # Test API directly
   curl http://localhost:5001/api/entries
   curl -X POST http://localhost:5001/api/add \
        -H "Content-Type: application/json" \
        -d '{"barcode":"123456","quantity":1}'
   ```

## 🛠️ Troubleshooting

### Common Issues

**Service won't start**:
```bash
# Check service status
sudo systemctl status thirst-track-backend

# Check logs for errors
journalctl -u thirst-track-backend --no-pager

# Restart service
sudo systemctl restart thirst-track-backend
```

**Database connection issues**:
```bash
# Test database connection
./deployment/scripts/monitor-database.sh health

# Check PostgreSQL status
sudo systemctl status postgresql

# Reset database password
sudo -u postgres psql -c "ALTER USER thirsttrack_user PASSWORD 'new_password';"
```

**Scanner not working**:
```bash
# Check device permissions
ls -la /dev/input/event*

# Detect scanner
./deployment/scripts/detect-scanner.sh

# Test scanner
./deployment/scripts/test-scanner.py
```

**Network access issues**:
```bash
# Check firewall
sudo ufw status

# Check nginx configuration
sudo nginx -t

# Check network info
./deployment/scripts/network-info.sh
```

### Log Analysis

**Check all logs**:
```bash
# Application logs
find logs/ -name "*.log" -exec tail -20 {} \;

# System logs
journalctl --since "1 hour ago" | grep -i error

# Nginx logs
sudo tail -50 /var/log/nginx/error.log
```

## 🔄 Maintenance

### Regular Maintenance Tasks

**Daily** (automated):
- Database backup
- Log rotation
- System monitoring
- Security updates

**Weekly** (manual):
```bash
# Check system health
./deployment/scripts/test-deployment.sh

# Review logs
./deployment/scripts/monitor-database.sh all

# Clean old backups
./deployment/scripts/backup-database.sh cleanup
```

**Monthly** (manual):
```bash
# Update system packages
sudo apt update && sudo apt upgrade

# Review security logs
sudo fail2ban-client status

# Check disk usage
df -h
```

### Backup and Recovery

**Create backup**:
```bash
# Database backup
./deployment/scripts/backup-database.sh backup

# Full system backup (optional)
sudo rsync -av /home/pi/thirst-track2/ /backup/location/
```

**Restore from backup**:
```bash
# Restore database
./deployment/scripts/backup-database.sh restore /path/to/backup.sql.gz
```

## 📞 Support

### Getting Help

1. **Check logs** for error messages
2. **Run test scripts** to identify issues
3. **Review this documentation** for solutions
4. **Check GitHub issues** for known problems

### Useful Commands

```bash
# Quick status check
sudo systemctl status thirst-track-backend nginx postgresql

# View all logs
journalctl -f

# Network diagnostics
./deployment/scripts/network-info.sh

# Database diagnostics
./deployment/scripts/monitor-database.sh health
```

---

## 🎉 Deployment Complete!

Your Thirst Track system is now ready for production use. The system will:

- ✅ Start automatically on boot
- ✅ Restart services if they crash
- ✅ Backup data automatically
- ✅ Monitor system health
- ✅ Accept barcode scanner input
- ✅ Serve web interface on local network

Access your application at: `http://<your-pi-ip-address>`
