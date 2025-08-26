#!/bin/bash

# Database Diagnostic Script for Thirst Track
# This script diagnoses common database issues

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

echo -e "${BLUE}=== Database Diagnostic Report ===${NC}"
echo ""

# Function to print status
print_check() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check 1: Directory permissions
print_info "Checking directory permissions..."
if [ -r "$APP_DIR" ] && [ -x "$APP_DIR" ]; then
    print_check 0 "Application directory is accessible"
else
    print_check 1 "Application directory is not accessible"
    echo "  Directory: $APP_DIR"
    ls -ld "$APP_DIR" 2>/dev/null || echo "  Directory does not exist"
fi

# Check 2: PostgreSQL service
print_info "Checking PostgreSQL service..."
if systemctl is-active --quiet postgresql; then
    print_check 0 "PostgreSQL service is running"
else
    print_check 1 "PostgreSQL service is not running"
fi

# Check 3: Database existence
print_info "Checking database existence..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    print_check 0 "Database '$DB_NAME' exists"
else
    print_check 1 "Database '$DB_NAME' does not exist"
fi

# Check 4: User existence
print_info "Checking database user..."
if sudo -u postgres psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    print_check 0 "User '$DB_USER' exists"
else
    print_check 1 "User '$DB_USER' does not exist"
fi

# Check 5: Table existence and schema
print_info "Checking table schema..."
if sudo -u postgres psql -d "$DB_NAME" -t -c "SELECT 1 FROM information_schema.tables WHERE table_name='entries'" 2>/dev/null | grep -q 1; then
    print_check 0 "Table 'entries' exists"
    
    # Check columns
    echo "  Table structure:"
    sudo -u postgres psql -d "$DB_NAME" -c "
    SELECT column_name, data_type, is_nullable, column_default 
    FROM information_schema.columns 
    WHERE table_name = 'entries' 
    ORDER BY ordinal_position;
    " 2>/dev/null || echo "  Could not retrieve table structure"
    
    # Check for created_at column specifically
    if sudo -u postgres psql -d "$DB_NAME" -t -c "SELECT 1 FROM information_schema.columns WHERE table_name='entries' AND column_name='created_at'" 2>/dev/null | grep -q 1; then
        print_check 0 "Column 'created_at' exists"
    else
        print_check 1 "Column 'created_at' is missing"
    fi
else
    print_check 1 "Table 'entries' does not exist"
fi

# Check 6: Database connection as application user
print_info "Testing database connection..."
export PGPASSWORD="$DB_PASSWORD"
if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
    print_check 0 "Can connect as application user"
    
    # Test basic operations
    if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) FROM entries;" > /dev/null 2>&1; then
        print_check 0 "Can query entries table"
        
        # Show current data count
        ENTRY_COUNT=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM entries;" 2>/dev/null | xargs)
        echo "  Current entries count: $ENTRY_COUNT"
    else
        print_check 1 "Cannot query entries table"
    fi
else
    print_check 1 "Cannot connect as application user"
    echo "  User: $DB_USER"
    echo "  Database: $DB_NAME"
    echo "  Host: localhost"
fi

# Check 7: File permissions
print_info "Checking file permissions..."
if [ -w "$APP_DIR" ]; then
    print_check 0 "Application directory is writable"
else
    print_check 1 "Application directory is not writable"
fi

if [ -d "$APP_DIR/logs" ]; then
    if [ -w "$APP_DIR/logs" ]; then
        print_check 0 "Logs directory is writable"
    else
        print_check 1 "Logs directory is not writable"
    fi
else
    print_check 1 "Logs directory does not exist"
fi

# Check 8: Environment file
print_info "Checking environment configuration..."
if [ -f "$APP_DIR/.env" ]; then
    print_check 0 "Environment file exists"
    
    # Check database configuration in .env
    if grep -q "DB_NAME" "$APP_DIR/.env"; then
        print_check 0 "Database configuration found in .env"
        echo "  Database settings in .env:"
        grep "^DB_" "$APP_DIR/.env" | sed 's/^/    /'
    else
        print_check 1 "Database configuration missing in .env"
    fi
else
    print_check 1 "Environment file does not exist"
fi

echo ""
echo -e "${YELLOW}Diagnostic Summary:${NC}"
echo "If you see any ✗ marks above, run the repair script:"
echo "  sudo ./deployment/scripts/repair-database.sh"
echo ""
echo "For detailed database monitoring:"
echo "  ./deployment/scripts/monitor-database.sh health"
