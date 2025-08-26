#!/bin/bash

# PostgreSQL Database Setup Script for Raspberry Pi
# This script installs and configures PostgreSQL for the Thirst Track application

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
DB_PASSWORD="secure_password_change_me"
POSTGRES_VERSION="13"

echo -e "${BLUE}=== PostgreSQL Database Setup ===${NC}"

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

# Update package list
print_status "Updating package list..."
apt update

# Install PostgreSQL
print_status "Installing PostgreSQL..."
apt install -y postgresql postgresql-contrib postgresql-client

# Start and enable PostgreSQL service
print_status "Starting PostgreSQL service..."
systemctl start postgresql
systemctl enable postgresql

# Wait for PostgreSQL to be ready
print_status "Waiting for PostgreSQL to be ready..."
sleep 5

# Check if PostgreSQL is running
if ! systemctl is-active --quiet postgresql; then
    print_error "PostgreSQL failed to start"
    exit 1
fi

print_status "PostgreSQL is running successfully"

# Create database and user
print_status "Creating database and user..."

# Switch to postgres user and create database
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;" 2>/dev/null || print_warning "Database $DB_NAME already exists"

# Create user with password
sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || print_warning "User $DB_USER already exists"

# Grant privileges
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"

# Create the entries table (only if it doesn't exist)
print_status "Checking/creating database schema..."

# Check if entries table already exists
if sudo -u postgres psql -d $DB_NAME -t -c "SELECT 1 FROM information_schema.tables WHERE table_name='entries'" | grep -q 1; then
    print_status "Table 'entries' already exists - using existing table"
else
    print_status "Creating new 'entries' table..."
    sudo -u postgres psql -d $DB_NAME -c "
    CREATE TABLE entries (
        id SERIAL PRIMARY KEY,
        barcode VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX idx_entries_barcode ON entries(barcode);
    CREATE INDEX idx_entries_created_at ON entries(created_at);
    "
    print_status "Table 'entries' created successfully"
fi

# Grant table permissions (for all existing tables and sequences)
print_status "Granting permissions on database objects..."
sudo -u postgres psql -d $DB_NAME -c "
-- Grant permissions on all existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;

-- Grant permissions on all existing sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;

-- Grant default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
"

# Configure PostgreSQL for local connections
print_status "Configuring PostgreSQL authentication..."

# Find and backup original pg_hba.conf
PG_HBA_FILE=$(find /etc/postgresql -name pg_hba.conf | head -1)
if [ -f "$PG_HBA_FILE" ]; then
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
else
    print_warning "Could not find pg_hba.conf file"
fi

# Configure PostgreSQL settings for better performance on Pi
print_status "Optimizing PostgreSQL configuration for Raspberry Pi..."

PG_CONF_FILE=$(find /etc/postgresql -name postgresql.conf | head -1)
if [ -f "$PG_CONF_FILE" ]; then
    # Backup original config if backup doesn't exist
    if [ ! -f "$PG_CONF_FILE.backup" ]; then
        print_status "Creating backup of postgresql.conf..."
        cp "$PG_CONF_FILE" "$PG_CONF_FILE.backup"
    else
        print_status "Backup of postgresql.conf already exists"
    fi
    
    # Optimize for Raspberry Pi (limited resources)
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
else
    print_warning "Could not find postgresql.conf file"
fi

# Restart PostgreSQL to apply configuration changes
print_status "Restarting PostgreSQL to apply configuration..."
systemctl restart postgresql

# Wait for restart
sleep 5

# Test database connection
print_status "Testing database connection..."
if sudo -u postgres psql -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "Database connection test successful"
else
    print_error "Database connection test failed"
    exit 1
fi

# Test application user connection
print_status "Testing application user connection..."
export PGPASSWORD="$DB_PASSWORD"
if psql -h localhost -U $DB_USER -d $DB_NAME -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "Application user connection test successful"
else
    print_error "Application user connection test failed"
    exit 1
fi

# Create a test entry
print_status "Creating test data..."
export PGPASSWORD="$DB_PASSWORD"
psql -h localhost -U $DB_USER -d $DB_NAME -c "INSERT INTO entries (barcode) VALUES ('test123456');"

# Verify test data
TEST_COUNT=$(psql -h localhost -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM entries WHERE barcode='test123456';" | xargs)
if [ "$TEST_COUNT" = "1" ]; then
    print_status "Test data created successfully"
else
    print_error "Failed to create test data"
    exit 1
fi

# Clean up test data
psql -h localhost -U $DB_USER -d $DB_NAME -c "DELETE FROM entries WHERE barcode='test123456';"

print_status "Database setup completed successfully!"
echo -e "${YELLOW}Database Configuration:${NC}"
echo "  Database Name: $DB_NAME"
echo "  Username: $DB_USER"
echo "  Password: $DB_PASSWORD"
echo "  Host: localhost"
echo "  Port: 5432"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Update your .env file with these database credentials"
echo "2. Test the application connection"
echo "3. Consider changing the default password for security"
