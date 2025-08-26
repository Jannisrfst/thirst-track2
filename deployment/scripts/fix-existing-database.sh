#!/bin/bash

# Fix Existing Database Script for Thirst Track
# This script fixes permissions and user access for an existing PostgreSQL database

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

echo -e "${BLUE}=== Fix Existing Database Script ===${NC}"
echo "This script will configure your existing 'thirsttrack' database for the deployment."
echo ""

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

# Step 1: Fix directory permissions (main issue causing "Permission denied")
print_status "Fixing directory permissions..."
chmod 755 /home/jannisreufsteck
chmod 755 "$APP_DIR"
chown -R jannisreufsteck:jannisreufsteck "$APP_DIR"

# Create logs directory if it doesn't exist
mkdir -p "$APP_DIR/logs"
chmod 755 "$APP_DIR/logs"
chown jannisreufsteck:jannisreufsteck "$APP_DIR/logs"

print_status "Directory permissions fixed"

# Step 2: Verify PostgreSQL is running
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

# Step 3: Verify existing database
print_status "Verifying existing database..."
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    print_status "Found existing database '$DB_NAME'"
else
    print_error "Database '$DB_NAME' not found. Please ensure your database is named 'thirsttrack'"
    echo "Available databases:"
    sudo -u postgres psql -l
    exit 1
fi

# Step 4: Create or verify deployment user
print_status "Setting up deployment user..."
if sudo -u postgres psql -t -c "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1; then
    print_status "User '$DB_USER' already exists"
    # Update password in case it's different
    sudo -u postgres psql -c "ALTER USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
else
    print_status "Creating deployment user '$DB_USER'..."
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
fi

# Step 5: Grant necessary permissions to deployment user
print_status "Granting permissions to deployment user..."
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;"

# Grant permissions on all existing tables
sudo -u postgres psql -d "$DB_NAME" -c "
-- Grant permissions on all existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;

-- Grant permissions on all existing sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;

-- Grant default privileges for future tables and sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $DB_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $DB_USER;
"

# Step 6: Show existing database structure
print_status "Current database structure:"
echo ""
echo "Tables in database '$DB_NAME':"
sudo -u postgres psql -d "$DB_NAME" -c "
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
"

echo ""
echo "Structure of 'entries' table (if it exists):"
sudo -u postgres psql -d "$DB_NAME" -c "
SELECT column_name, data_type, is_nullable, column_default 
FROM information_schema.columns 
WHERE table_name = 'entries' 
ORDER BY ordinal_position;
" 2>/dev/null || echo "Table 'entries' not found"

# Step 7: Test connection as deployment user
print_status "Testing database connection as deployment user..."
export PGPASSWORD="$DB_PASSWORD"

if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT current_database(), current_user;" > /dev/null 2>&1; then
    print_status "Connection test successful"
    
    # Show connection details
    echo "Connection details:"
    psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT current_database() as database, current_user as user, version();"
    
else
    print_error "Connection test failed"
    echo "Troubleshooting information:"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Host: localhost"
    echo "  Port: 5432"
    exit 1
fi

# Step 8: Test basic operations (if entries table exists)
if sudo -u postgres psql -d "$DB_NAME" -t -c "SELECT 1 FROM information_schema.tables WHERE table_name='entries'" | grep -q 1; then
    print_status "Testing basic operations on 'entries' table..."
    
    # Test select
    if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT COUNT(*) as total_entries FROM entries;" > /dev/null 2>&1; then
        print_status "Can query entries table"
        
        # Show current count
        ENTRY_COUNT=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM entries;" | xargs)
        echo "  Current entries in database: $ENTRY_COUNT"
    else
        print_warning "Cannot query entries table - check table permissions"
    fi
    
    # Test insert (with cleanup)
    TEST_BARCODE="deployment_test_$(date +%s)"
    if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "INSERT INTO entries (barcode) VALUES ('$TEST_BARCODE');" > /dev/null 2>&1; then
        print_status "Can insert into entries table"
        # Clean up test data
        psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM entries WHERE barcode='$TEST_BARCODE';" > /dev/null 2>&1
    else
        print_warning "Cannot insert into entries table - check table permissions"
    fi
else
    print_warning "Table 'entries' not found - deployment may create it"
fi

print_status "Database configuration completed successfully!"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "✓ Directory permissions fixed"
echo "✓ PostgreSQL service verified"
echo "✓ Existing database '$DB_NAME' found and configured"
echo "✓ Deployment user '$DB_USER' configured with proper permissions"
echo "✓ Database connection tested successfully"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Continue with your deployment: ./deployment/scripts/deploy.sh"
echo "2. The deployment will now use your existing database"
echo "3. Test after deployment: ./deployment/scripts/test-deployment.sh"
echo ""
echo -e "${YELLOW}Database credentials for .env file:${NC}"
echo "DB_NAME=$DB_NAME"
echo "DB_USER=$DB_USER"
echo "DB_PASSWORD=$DB_PASSWORD"
echo "DB_HOST=localhost"
echo "DB_PORT=5432"
