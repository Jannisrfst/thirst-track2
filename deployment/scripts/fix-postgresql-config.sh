#!/bin/bash

# Fix PostgreSQL Configuration Script
# This script fixes the pg_hba.conf configuration issue

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DB_NAME="thirsttrack"
DB_USER="thirsttrack_user"

echo -e "${BLUE}=== Fix PostgreSQL Configuration ===${NC}"

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

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    print_error "This script must be run with sudo privileges"
    exit 1
fi

# Find PostgreSQL configuration files
print_status "Locating PostgreSQL configuration files..."

PG_HBA_FILE=$(find /etc/postgresql -name pg_hba.conf | head -1)
PG_CONF_FILE=$(find /etc/postgresql -name postgresql.conf | head -1)

if [ -z "$PG_HBA_FILE" ]; then
    print_error "Could not find pg_hba.conf file"
    exit 1
fi

if [ -z "$PG_CONF_FILE" ]; then
    print_error "Could not find postgresql.conf file"
    exit 1
fi

print_status "Found pg_hba.conf: $PG_HBA_FILE"
print_status "Found postgresql.conf: $PG_CONF_FILE"

# Fix pg_hba.conf
print_status "Configuring pg_hba.conf..."

# Create backup if it doesn't exist
if [ ! -f "$PG_HBA_FILE.backup" ]; then
    print_status "Creating backup of pg_hba.conf..."
    cp "$PG_HBA_FILE" "$PG_HBA_FILE.backup"
else
    print_status "Backup of pg_hba.conf already exists"
fi

# Check if our user entry already exists
if grep -q "local.*$DB_NAME.*$DB_USER" "$PG_HBA_FILE"; then
    print_status "Database user entry already exists in pg_hba.conf"
else
    print_status "Adding database user entry to pg_hba.conf..."
    echo "local   $DB_NAME   $DB_USER   md5" >> "$PG_HBA_FILE"
    print_status "Updated pg_hba.conf for local connections"
fi

# Check postgresql.conf optimization
print_status "Checking postgresql.conf optimization..."

# Create backup if it doesn't exist
if [ ! -f "$PG_CONF_FILE.backup" ]; then
    print_status "Creating backup of postgresql.conf..."
    cp "$PG_CONF_FILE" "$PG_CONF_FILE.backup"
else
    print_status "Backup of postgresql.conf already exists"
fi

# Check if Raspberry Pi optimizations are already applied
if grep -q "# Raspberry Pi optimizations" "$PG_CONF_FILE"; then
    print_status "Raspberry Pi optimizations already applied to postgresql.conf"
else
    print_status "Adding Raspberry Pi optimizations to postgresql.conf..."
    cat >> "$PG_CONF_FILE" << EOF

# Raspberry Pi optimizations
shared_buffers = 64MB
effective_cache_size = 256MB
maintenance_work_mem = 16MB
checkpoint_completion_target = 0.9
wal_buffers = 2MB
default_statistics_target = 100
random_page_cost = 4.0
effective_io_concurrency = 2
work_mem = 2MB
min_wal_size = 80MB
max_wal_size = 1GB

# Connection settings
max_connections = 20
listen_addresses = 'localhost'
port = 5432

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 10MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
EOF
    print_status "PostgreSQL configuration optimized for Raspberry Pi"
fi

# Restart PostgreSQL to apply changes
print_status "Restarting PostgreSQL to apply configuration changes..."
systemctl restart postgresql

# Wait for restart
sleep 5

# Verify PostgreSQL is running
if systemctl is-active --quiet postgresql; then
    print_status "PostgreSQL restarted successfully"
else
    print_error "PostgreSQL failed to restart"
    exit 1
fi

# Test database connection
print_status "Testing database connection..."
if sudo -u postgres psql -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "Database connection test successful"
else
    print_error "Database connection test failed"
    exit 1
fi

print_status "PostgreSQL configuration fixed successfully!"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "✓ pg_hba.conf configured for local connections"
echo "✓ postgresql.conf optimized for Raspberry Pi"
echo "✓ PostgreSQL service restarted"
echo "✓ Database connection verified"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Continue with deployment: ./deployment/scripts/deploy.sh"
echo "2. Or test the current setup: ./deployment/scripts/test-deployment.sh"
