# Thirst Track Deployment Checklist

## 📋 Pre-Deployment Checklist

### Hardware Setup
- [ ] Raspberry Pi 4 (4GB+ RAM recommended)
- [ ] MicroSD card (32GB+, Class 10)
- [ ] USB barcode scanner
- [ ] Network connection (Ethernet/WiFi)
- [ ] Stable power supply

### Software Preparation
- [ ] Raspberry Pi OS Lite (64-bit) flashed to SD card
- [ ] SSH enabled in Pi configuration
- [ ] WiFi configured (if using wireless)
- [ ] Pi accessible via SSH
- [ ] Internet connection working

## 🚀 Deployment Steps

### Step 1: System Preparation
- [ ] SSH into Raspberry Pi
- [ ] Update system packages: `sudo apt update && sudo apt upgrade -y`
- [ ] Install git: `sudo apt install -y git`
- [ ] Clone repository: `git clone https://github.com/Jannisrfst/thirst-track2.git`
- [ ] Navigate to project: `cd thirst-track2`

### Step 2: Automated Deployment
- [ ] Make deployment script executable: `chmod +x deployment/scripts/deploy.sh`
- [ ] Run deployment script: `./deployment/scripts/deploy.sh`
- [ ] Wait for completion (15-30 minutes)
- [ ] Check for any error messages

### Step 3: Configuration
- [ ] Edit environment file: `nano .env`
- [ ] Update database password: `DB_PASSWORD=your_secure_password`
- [ ] Configure email settings: `EMAIL_FROM`, `EMAIL_PASSWORD`
- [ ] Set secret key: `SECRET_KEY=your_secret_key`
- [ ] Save configuration file

### Step 4: Service Startup
- [ ] Start backend service: `sudo systemctl start thirst-track-backend`
- [ ] Start nginx service: `sudo systemctl start nginx`
- [ ] Enable auto-start: `sudo systemctl enable thirst-track-backend nginx postgresql`
- [ ] Check service status: `sudo systemctl status thirst-track-backend nginx postgresql`

### Step 5: Testing
- [ ] Run deployment test: `./deployment/scripts/test-deployment.sh`
- [ ] Check network access: `./deployment/scripts/network-info.sh`
- [ ] Test web interface: Open `http://PI_IP` in browser
- [ ] Test API endpoints: `curl http://localhost:5001/api/entries`

## 🔌 Barcode Scanner Setup

### Scanner Configuration
- [ ] Connect USB barcode scanner
- [ ] Run scanner detection: `./deployment/scripts/detect-scanner.sh`
- [ ] Test scanner: `./deployment/scripts/test-scanner.py`
- [ ] Configure device path: `./deployment/scripts/configure-scanner.sh`
- [ ] Verify scanner integration with app

### Scanner Verification
- [ ] Scanner detected in device list
- [ ] Scanner accessible by pi user
- [ ] Test scan produces correct output
- [ ] Scanned barcodes update inventory
- [ ] No permission errors

## 🔒 Security Verification

### Firewall Configuration
- [ ] UFW firewall enabled: `sudo ufw status`
- [ ] SSH access allowed (port 22)
- [ ] HTTP access allowed (port 80)
- [ ] Backend port restricted to local network (5001)
- [ ] Database port restricted to localhost (5432)

### Security Services
- [ ] fail2ban installed and running: `sudo systemctl status fail2ban`
- [ ] Automatic updates configured
- [ ] SSH hardened (root login disabled)
- [ ] System monitoring active

### Access Control
- [ ] Pi user in input group for scanner access
- [ ] Proper file permissions set
- [ ] Log files accessible and rotating
- [ ] Backup system configured

## 🌐 Network Access Verification

### Local Access
- [ ] Web interface accessible at `http://localhost`
- [ ] All pages load correctly
- [ ] Inventory list displays
- [ ] Add/remove functionality works
- [ ] CSV upload functionality works

### Network Access
- [ ] Web interface accessible from other devices: `http://PI_IP`
- [ ] Mobile devices can access interface
- [ ] QR code generated for easy mobile access
- [ ] No CORS errors in browser console

### API Testing
- [ ] GET `/api/entries` returns inventory data
- [ ] POST `/api/add` successfully adds items
- [ ] POST `/api/decrement` successfully removes items
- [ ] POST `/api/upload` handles CSV uploads
- [ ] Error handling works correctly

## 💾 Database Verification

### Database Setup
- [ ] PostgreSQL service running
- [ ] Database `thirsttrack` created
- [ ] User `thirsttrack_user` created with proper permissions
- [ ] Tables created with correct schema
- [ ] Indexes created for performance

### Database Operations
- [ ] Can connect to database: `./deployment/scripts/monitor-database.sh health`
- [ ] Can insert test data
- [ ] Can query inventory data
- [ ] Backup system working: `./deployment/scripts/backup-database.sh backup`
- [ ] Automatic backups scheduled

### Performance
- [ ] Database responds quickly to queries
- [ ] No connection timeout errors
- [ ] Memory usage acceptable
- [ ] Disk space sufficient

## 🔄 Auto-Start Verification

### Service Auto-Start
- [ ] Reboot Pi: `sudo reboot`
- [ ] Wait for boot completion
- [ ] Check all services started automatically
- [ ] Web interface accessible after reboot
- [ ] Scanner functionality works after reboot

### Service Recovery
- [ ] Stop backend service: `sudo systemctl stop thirst-track-backend`
- [ ] Wait 5 minutes for monitoring to detect
- [ ] Verify service automatically restarts
- [ ] Check monitoring logs: `tail -f /var/log/thirst-track-monitor.log`

## 📊 Performance Verification

### System Resources
- [ ] Memory usage < 80%: `free -h`
- [ ] Disk usage < 80%: `df -h`
- [ ] CPU load acceptable: `top`
- [ ] No swap usage under normal load

### Application Performance
- [ ] Web pages load in < 3 seconds
- [ ] API responses in < 1 second
- [ ] Database queries complete quickly
- [ ] Scanner input processed immediately

### Load Testing
- [ ] Multiple simultaneous users can access interface
- [ ] Rapid barcode scanning doesn't cause errors
- [ ] Large CSV uploads process successfully
- [ ] System remains stable under load

## 📝 Documentation and Handover

### Documentation Complete
- [ ] Deployment README.md reviewed
- [ ] Quick start guide available
- [ ] Troubleshooting guide accessible
- [ ] All scripts documented

### User Training
- [ ] Web interface demonstrated
- [ ] Barcode scanner usage explained
- [ ] CSV upload process shown
- [ ] Basic troubleshooting covered

### Maintenance Setup
- [ ] Backup schedule explained
- [ ] Log monitoring demonstrated
- [ ] Service restart procedures documented
- [ ] Update procedures explained

## ✅ Final Verification

### Complete System Test
- [ ] All services running and healthy
- [ ] Web interface fully functional
- [ ] Barcode scanner working correctly
- [ ] Database operations successful
- [ ] Network access from multiple devices
- [ ] Security measures active
- [ ] Monitoring and backups operational

### Production Readiness
- [ ] System stable for 24+ hours
- [ ] No critical errors in logs
- [ ] Performance meets requirements
- [ ] All features tested and working
- [ ] Documentation complete
- [ ] Handover completed

## 🎉 Deployment Complete!

**Congratulations! Your Thirst Track system is now ready for production use.**

### Quick Access Information:
- **Web Interface**: `http://YOUR_PI_IP`
- **SSH Access**: `ssh pi@YOUR_PI_IP`
- **Service Management**: `sudo systemctl status thirst-track-backend`
- **Logs**: `journalctl -u thirst-track-backend -f`
- **Database**: `./deployment/scripts/monitor-database.sh`
- **Scanner**: `./deployment/scripts/detect-scanner.sh`

### Emergency Contacts:
- System Administrator: _______________
- Technical Support: _______________
- Network Administrator: _______________

---

**Date Deployed**: _______________  
**Deployed By**: _______________  
**System Version**: _______________  
**Pi IP Address**: _______________
