#!/bin/bash

# Database Monitoring Script
# This script monitors PostgreSQL database health and performance

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

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Function to check database connectivity
check_connectivity() {
    print_header "Database Connectivity"
    
    export PGPASSWORD="$DB_PASSWORD"
    
    if psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        print_status "Database connection: OK"
        return 0
    else
        print_error "Database connection: FAILED"
        return 1
    fi
}

# Function to show database statistics
show_statistics() {
    print_header "Database Statistics"
    
    export PGPASSWORD="$DB_PASSWORD"
    
    # Total entries count
    TOTAL_ENTRIES=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM entries;" | xargs)
    echo "Total entries: $TOTAL_ENTRIES"
    
    # Unique barcodes count
    UNIQUE_BARCODES=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(DISTINCT barcode) FROM entries;" | xargs)
    echo "Unique barcodes: $UNIQUE_BARCODES"
    
    # Entries added today
    TODAY_ENTRIES=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM entries WHERE DATE(created_at) = CURRENT_DATE;" | xargs)
    echo "Entries added today: $TODAY_ENTRIES"
    
    # Entries added this week
    WEEK_ENTRIES=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM entries WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';" | xargs)
    echo "Entries added this week: $WEEK_ENTRIES"
    
    # Database size
    DB_SIZE=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT pg_size_pretty(pg_database_size('$DB_NAME'));" | xargs)
    echo "Database size: $DB_SIZE"
    
    # Table size
    TABLE_SIZE=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT pg_size_pretty(pg_total_relation_size('entries'));" | xargs)
    echo "Entries table size: $TABLE_SIZE"
}

# Function to show top barcodes
show_top_barcodes() {
    print_header "Top 10 Most Scanned Barcodes"
    
    export PGPASSWORD="$DB_PASSWORD"
    
    echo "Barcode          | Count"
    echo "-----------------|------"
    psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT 
            LPAD(barcode, 15) || ' | ' || LPAD(COUNT(*)::text, 5)
        FROM entries 
        GROUP BY barcode 
        ORDER BY COUNT(*) DESC 
        LIMIT 10;
    " | sed 's/^ *//'
}

# Function to show recent activity
show_recent_activity() {
    print_header "Recent Activity (Last 24 Hours)"
    
    export PGPASSWORD="$DB_PASSWORD"
    
    echo "Time                | Barcode"
    echo "-------------------|----------"
    psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "
        SELECT 
            TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI') || ' | ' || barcode
        FROM entries 
        WHERE created_at >= NOW() - INTERVAL '24 hours'
        ORDER BY created_at DESC 
        LIMIT 20;
    " | sed 's/^ *//'
}

# Function to check database performance
check_performance() {
    print_header "Database Performance"
    
    export PGPASSWORD="$DB_PASSWORD"
    
    # Check for slow queries (if logging is enabled)
    echo "Database connections:"
    CONNECTIONS=$(psql -h localhost -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM pg_stat_activity WHERE datname = '$DB_NAME';" | xargs)
    echo "  Active connections: $CONNECTIONS"
    
    # Check index usage
    echo ""
    echo "Index usage on entries table:"
    psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            indexrelname as index_name,
            idx_tup_read as index_reads,
            idx_tup_fetch as index_fetches
        FROM pg_stat_user_indexes 
        WHERE relname = 'entries';
    " 2>/dev/null || echo "  No index statistics available"
    
    # Check table statistics
    echo ""
    echo "Table statistics:"
    psql -h localhost -U "$DB_USER" -d "$DB_NAME" -c "
        SELECT 
            seq_scan as sequential_scans,
            seq_tup_read as sequential_reads,
            idx_scan as index_scans,
            idx_tup_fetch as index_reads,
            n_tup_ins as inserts,
            n_tup_del as deletes
        FROM pg_stat_user_tables 
        WHERE relname = 'entries';
    " 2>/dev/null || echo "  No table statistics available"
}

# Function to check system resources
check_system_resources() {
    print_header "System Resources"
    
    # PostgreSQL process info
    echo "PostgreSQL processes:"
    ps aux | grep postgres | grep -v grep | wc -l | xargs echo "  Process count:"
    
    # Memory usage
    echo ""
    echo "Memory usage:"
    free -h | grep Mem | awk '{print "  Total: " $2 ", Used: " $3 ", Free: " $4}'
    
    # Disk usage for PostgreSQL data directory
    echo ""
    echo "Disk usage:"
    PG_DATA_DIR=$(sudo -u postgres psql -t -c "SHOW data_directory;" | xargs)
    if [ -d "$PG_DATA_DIR" ]; then
        du -sh "$PG_DATA_DIR" | awk '{print "  PostgreSQL data: " $1}'
    fi
    
    # Check available disk space
    df -h / | tail -1 | awk '{print "  Root filesystem: " $3 " used, " $4 " available (" $5 " full)"}'
}

# Function to run health check
health_check() {
    print_header "Database Health Check"
    
    local issues=0
    
    # Check if PostgreSQL service is running
    if systemctl is-active --quiet postgresql; then
        print_status "PostgreSQL service is running"
    else
        print_error "PostgreSQL service is not running"
        ((issues++))
    fi
    
    # Check database connectivity
    if ! check_connectivity > /dev/null 2>&1; then
        print_error "Cannot connect to database"
        ((issues++))
    fi
    
    # Check disk space (warn if > 80% full)
    DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -gt 80 ]; then
        print_warning "Disk usage is high: ${DISK_USAGE}%"
        ((issues++))
    else
        print_status "Disk usage is acceptable: ${DISK_USAGE}%"
    fi
    
    # Check memory usage (warn if > 90% full)
    MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [ "$MEMORY_USAGE" -gt 90 ]; then
        print_warning "Memory usage is high: ${MEMORY_USAGE}%"
        ((issues++))
    else
        print_status "Memory usage is acceptable: ${MEMORY_USAGE}%"
    fi
    
    echo ""
    if [ $issues -eq 0 ]; then
        print_status "All health checks passed!"
    else
        print_warning "$issues issue(s) found"
    fi
    
    return $issues
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [stats|top|recent|performance|resources|health|all]"
    echo ""
    echo "Commands:"
    echo "  stats       - Show database statistics"
    echo "  top         - Show top scanned barcodes"
    echo "  recent      - Show recent activity"
    echo "  performance - Show performance metrics"
    echo "  resources   - Show system resource usage"
    echo "  health      - Run health check"
    echo "  all         - Show all information"
    echo ""
}

# Main script logic
case "$1" in
    stats)
        check_connectivity && show_statistics
        ;;
    top)
        check_connectivity && show_top_barcodes
        ;;
    recent)
        check_connectivity && show_recent_activity
        ;;
    performance)
        check_connectivity && check_performance
        ;;
    resources)
        check_system_resources
        ;;
    health)
        health_check
        ;;
    all)
        if check_connectivity; then
            show_statistics
            echo ""
            show_top_barcodes
            echo ""
            show_recent_activity
            echo ""
            check_performance
            echo ""
            check_system_resources
            echo ""
            health_check
        fi
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
