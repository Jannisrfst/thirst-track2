#!/bin/bash

# Thirst Track Raspberry Pi Deployment Script
# This script automates the complete deployment process

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/home/pi/thirst-track2"
DB_NAME="thirsttrack"
DB_USER="thirsttrack_user"
DB_PASSWORD="secure_password_change_me"

echo -e "${BLUE}=== Thirst Track Raspberry Pi Deployment ===${NC}"
echo "Starting deployment process..."

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

# Check if running as pi user
if [ "$USER" != "pi" ]; then
    print_error "This script must be run as the 'pi' user"
    exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required system packages
print_status "Installing system dependencies..."
sudo apt install -y \
    postgresql postgresql-contrib \
    nginx \
    python3-pip python3-venv python3-dev \
    nodejs npm \
    git curl wget \
    ufw \
    build-essential \
    libpq-dev

# Setup PostgreSQL
print_status "Setting up PostgreSQL database..."
chmod +x deployment/scripts/setup-database.sh
sudo ./deployment/scripts/setup-database.sh

# Setup database backup system
print_status "Setting up database backup system..."
chmod +x deployment/scripts/backup-database.sh
./deployment/scripts/backup-database.sh auto-setup

# Setup application directory
print_status "Setting up application directory..."
if [ ! -d "$APP_DIR" ]; then
    print_error "Application directory $APP_DIR not found. Please clone the repository first."
    exit 1
fi

cd $APP_DIR

# Create Python virtual environment
print_status "Creating Python virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate virtual environment and install Python dependencies
print_status "Installing Python dependencies..."
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install gunicorn psycopg2-binary python-dotenv flask-cors

# Setup environment file
print_status "Setting up environment configuration..."
cp deployment/env/.env.production .env
sed -i "s/DB_PASSWORD=secure_password_change_me/DB_PASSWORD=$DB_PASSWORD/" .env

# Build React frontend
print_status "Building React frontend..."
chmod +x deployment/scripts/build-frontend.sh
./deployment/scripts/build-frontend.sh

# Setup systemd service
print_status "Installing systemd service..."
sudo cp deployment/systemd/thirst-track-backend.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable thirst-track-backend.service

# Setup nginx
print_status "Configuring nginx..."
sudo cp deployment/nginx/thirst-track.conf /etc/nginx/sites-available/
sudo ln -sf /etc/nginx/sites-available/thirst-track.conf /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl enable nginx

# Configure security and network
print_status "Configuring security and network settings..."
chmod +x deployment/scripts/setup-security.sh
sudo ./deployment/scripts/setup-security.sh

# Setup barcode scanner
print_status "Setting up USB barcode scanner..."
chmod +x deployment/scripts/setup-barcode-scanner.sh
sudo ./deployment/scripts/setup-barcode-scanner.sh

# Create logs directory
print_status "Creating logs directory..."
mkdir -p $APP_DIR/logs

# Set proper permissions
print_status "Setting file permissions..."
sudo chown -R pi:pi $APP_DIR
chmod +x deployment/scripts/*.sh
chmod +x wsgi.py

print_status "Deployment configuration complete!"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit .env file with your specific configuration"
echo "2. Run: sudo systemctl start thirst-track-backend"
echo "3. Run: sudo systemctl start nginx"
echo "4. Test the deployment with: ./deployment/scripts/test-deployment.sh"
