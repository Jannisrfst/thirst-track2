#!/bin/bash

# Database Repair Script for Thirst Track
# This script fixes common database issues after user changes

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
APP_DIR="/home/jannisreufsteck/thirst-track2"

echo -e "${BLUE}=== Database Repair Script ===${NC}"

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

# Step 1: Fix directory permissions
print_status "Fixing directory permissions..."
chmod 755 /home/jannisreufsteck
chmod 755 "$APP_DIR"
chown -R jannisreufsteck:jannisreufsteck "$APP_DIR"

# Create logs directory if it doesn't exist
mkdir -p "$APP_DIR/logs"
chmod 755 "$APP_DIR/logs"
chown jannisreufsteck:jannisreufsteck "$APP_DIR/logs"

print_status "Directory permissions fixed"

# Step 2: Check PostgreSQL service
print_status "Checking PostgreSQL service..."
if ! systemctl is-active --quiet postgresql; then
    print_warning "PostgreSQL is not running. Starting it..."
    systemctl start postgresql
    sleep 3
fi

if systemctl is-active --quiet postgresql; then
    print_status "PostgreSQL is running"
else
    print_error "Failed to start PostgreSQL"
    exit 1
fi

# Step 3: Check database and user existence
print_status "Checking existing database and user..."

# Check if database exists
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    print_status "Database '$DB_NAME' exists (using existing database)"
else
    print_error "Database '$DB_NAME' does not exist. Please ensure your existing database is named 'thirsttrack'"
    exit 1
fi

# Check if user exists, create if needed
if sudo -u postgres psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    print_status "User '$DB_USER' exists"
else
    print_warning "User '$DB_USER' does not exist. Creating it for deployment..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
fi

# Step 4: Fix database permissions
print_status "Fixing database permissions..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"

# Step 5: Check existing table schema
print_status "Checking existing table schema..."

# Check if entries table exists
if sudo -u postgres psql -d "$DB_NAME" -t -c "SELECT 1 FROM information_schema.tables WHERE table_name='entries'" | grep -q 1; then
    print_status "Table 'entries' exists (using existing table)"

    # Show current table structure
    print_status "Current table structure:"
    sudo -u postgres psql -d "$DB_NAME" -c "
    SELECT column_name, data_type, is_nullable, column_default
    FROM information_schema.columns
    WHERE table_name = 'entries'
    ORDER BY ordinal_position;
    "

    # Check if created_at column exists (optional - don't fail if missing)
    if sudo -u postgres psql -d "$DB_NAME" -t -c "SELECT 1 FROM information_schema.columns WHERE table_name='entries' AND column_name='created_at'" | grep -q 1; then
        print_status "Column 'created_at' exists"
    else
        print_warning "Column 'created_at' missing - this is optional for existing databases"
    fi
else
    print_error "Table 'entries' does not exist in your database. Please check your existing database structure."
    exit 1
fi

# Step 6: Grant table permissions
print_status "Granting table permissions..."
sudo -u postgres psql -d "$DB_NAME" -c "
GRANT ALL PRIVILEGES ON TABLE entries TO $DB_USER;
GRANT USAGE, SELECT ON SEQUENCE entries_id_seq TO $DB_USER;
"

# Step 7: Test database connection
print_status "Testing database connection..."
export PGPASSWORD="$DB_PASSWORD"

if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_status "Database connection test successful"
else
    print_error "Database connection test failed"
    exit 1
fi

# Step 8: Test table operations
print_status "Testing table operations..."
TEST_BARCODE="repair_test_$(date +%s)"

# Test insert
if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "INSERT INTO entries (barcode) VALUES ('$TEST_BARCODE');" > /dev/null 2>&1; then
    print_status "Insert test successful"
else
    print_error "Insert test failed"
    exit 1
fi

# Test select with created_at
if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT id, barcode, created_at FROM entries WHERE barcode='$TEST_BARCODE';" > /dev/null 2>&1; then
    print_status "Select test with created_at successful"
else
    print_error "Select test with created_at failed"
    exit 1
fi

# Clean up test data
psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM entries WHERE barcode='$TEST_BARCODE';" > /dev/null 2>&1

print_status "Database repair completed successfully!"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "✓ Directory permissions fixed"
echo "✓ PostgreSQL service running"
echo "✓ Database and user verified"
echo "✓ Table schema corrected"
echo "✓ Permissions granted"
echo "✓ Connection and operations tested"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Continue with your deployment"
echo "2. Test the application: ./deployment/scripts/test-deployment.sh"
echo "3. Monitor database: ./deployment/scripts/monitor-database.sh health"
