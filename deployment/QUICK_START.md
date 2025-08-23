# Thirst Track - Quick Start Guide

## 🚀 5-Minute Setup

### Prerequisites
- Raspberry Pi 4 with Pi OS Lite
- Internet connection
- SSH access

### One-Command Deployment

```bash
# Clone and deploy in one go
cd /home/pi && \
git clone https://github.com/Jannisrfst/thirst-track2.git && \
cd thirst-track2 && \
chmod +x deployment/scripts/deploy.sh && \
./deployment/scripts/deploy.sh
```

### Post-Deployment Configuration

1. **Edit environment variables**:
   ```bash
   nano .env
   # Change: DB_PASSWORD, EMAIL_FROM, EMAIL_PASSWORD, SECRET_KEY
   ```

2. **Start services**:
   ```bash
   sudo systemctl start thirst-track-backend nginx
   sudo systemctl enable thirst-track-backend nginx postgresql
   ```

3. **Test deployment**:
   ```bash
   ./deployment/scripts/test-deployment.sh
   ```

4. **Get network info**:
   ```bash
   ./deployment/scripts/network-info.sh
   ```

## 📱 Access Your Application

- **Local**: http://localhost
- **Network**: http://YOUR_PI_IP
- **Mobile**: Scan QR code from network-info script

## 🔧 Essential Commands

### Service Management
```bash
# Check status
sudo systemctl status thirst-track-backend

# View logs
journalctl -u thirst-track-backend -f

# Restart service
sudo systemctl restart thirst-track-backend
```

### Database Operations
```bash
# Monitor database
./deployment/scripts/monitor-database.sh stats

# Create backup
./deployment/scripts/backup-database.sh backup

# Health check
./deployment/scripts/monitor-database.sh health
```

### Scanner Setup
```bash
# Detect scanner
./deployment/scripts/detect-scanner.sh

# Test scanner
./deployment/scripts/test-scanner.py

# Configure scanner
./deployment/scripts/configure-scanner.sh
```

### System Monitoring
```bash
# Full system test
./deployment/scripts/test-deployment.sh

# Network information
./deployment/scripts/network-info.sh

# Check firewall
sudo ufw status
```

## 🆘 Quick Troubleshooting

### Service Issues
```bash
# If backend won't start
sudo systemctl restart thirst-track-backend
journalctl -u thirst-track-backend --no-pager

# If web interface not accessible
sudo systemctl restart nginx
sudo nginx -t
```

### Database Issues
```bash
# If database connection fails
sudo systemctl restart postgresql
./deployment/scripts/monitor-database.sh health
```

### Scanner Issues
```bash
# If scanner not working
./deployment/scripts/detect-scanner.sh
sudo reboot  # May be needed for udev rules
```

## 📋 Daily Operations

### Check System Health
```bash
./deployment/scripts/test-deployment.sh
```

### View Recent Activity
```bash
./deployment/scripts/monitor-database.sh recent
```

### Check Logs
```bash
tail -f logs/thirst-track.log
```

## 🔄 Maintenance

### Weekly
```bash
# System health check
./deployment/scripts/test-deployment.sh

# Clean old backups
./deployment/scripts/backup-database.sh cleanup
```

### Monthly
```bash
# Update system
sudo apt update && sudo apt upgrade

# Check security
sudo fail2ban-client status
```

## 📞 Need Help?

1. Check logs: `journalctl -u thirst-track-backend -f`
2. Run tests: `./deployment/scripts/test-deployment.sh`
3. Review full documentation: `deployment/README.md`

---

**Your Thirst Track system is ready! 🎉**

Access it at: http://YOUR_PI_IP
