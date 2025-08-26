#!/bin/bash

# Database Backup and Restore Script
# This script provides backup and restore functionality for the PostgreSQL database

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
BACKUP_DIR="/home/jannisreufsteck/thirst-track2/backups"
DATE=$(date +%Y%m%d_%H%M%S)

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

# Function to show usage
show_usage() {
    echo "Usage: $0 [backup|restore|list|cleanup]"
    echo ""
    echo "Commands:"
    echo "  backup   - Create a backup of the database"
    echo "  restore  - Restore database from a backup file"
    echo "  list     - List available backup files"
    echo "  cleanup  - Remove old backup files (keeps last 10)"
    echo ""
    echo "Examples:"
    echo "  $0 backup"
    echo "  $0 restore /path/to/backup.sql"
    echo "  $0 list"
    echo "  $0 cleanup"
}

# Function to create backup
create_backup() {
    print_status "Creating database backup..."
    
    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"
    
    # Set backup filename
    BACKUP_FILE="$BACKUP_DIR/thirsttrack_backup_$DATE.sql"
    
    # Export password for pg_dump
    export PGPASSWORD="$DB_PASSWORD"
    
    # Create backup
    if pg_dump -h localhost -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"; then
        print_status "Backup created successfully: $BACKUP_FILE"
        
        # Compress backup
        gzip "$BACKUP_FILE"
        print_status "Backup compressed: $BACKUP_FILE.gz"
        
        # Show backup size
        BACKUP_SIZE=$(du -h "$BACKUP_FILE.gz" | cut -f1)
        print_status "Backup size: $BACKUP_SIZE"
        
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

# Function to restore backup
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        print_error "Please specify backup file to restore"
        echo "Usage: $0 restore <backup_file>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        print_error "Backup file not found: $backup_file"
        return 1
    fi
    
    print_warning "This will replace all existing data in the database!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Restore cancelled"
        return 0
    fi
    
    print_status "Restoring database from: $backup_file"
    
    # Export password
    export PGPASSWORD="$DB_PASSWORD"
    
    # Check if file is compressed
    if [[ "$backup_file" == *.gz ]]; then
        print_status "Decompressing backup file..."
        if gunzip -c "$backup_file" | psql -h localhost -U "$DB_USER" -d "$DB_NAME"; then
            print_status "Database restored successfully"
            return 0
        else
            print_error "Failed to restore database"
            return 1
        fi
    else
        if psql -h localhost -U "$DB_USER" -d "$DB_NAME" < "$backup_file"; then
            print_status "Database restored successfully"
            return 0
        else
            print_error "Failed to restore database"
            return 1
        fi
    fi
}

# Function to list backups
list_backups() {
    print_status "Available backup files:"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi
    
    if [ -z "$(ls -A $BACKUP_DIR/thirsttrack_backup_*.sql.gz 2>/dev/null)" ]; then
        print_warning "No backup files found in $BACKUP_DIR"
        return 1
    fi
    
    echo ""
    ls -lh "$BACKUP_DIR"/thirsttrack_backup_*.sql.gz 2>/dev/null | while read -r line; do
        echo "  $line"
    done
    echo ""
}

# Function to cleanup old backups
cleanup_backups() {
    print_status "Cleaning up old backup files..."
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_warning "Backup directory does not exist: $BACKUP_DIR"
        return 1
    fi
    
    # Keep only the 10 most recent backups
    BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/thirsttrack_backup_*.sql.gz 2>/dev/null | wc -l)
    
    if [ "$BACKUP_COUNT" -le 10 ]; then
        print_status "No cleanup needed. Found $BACKUP_COUNT backup files (keeping up to 10)"
        return 0
    fi
    
    print_status "Found $BACKUP_COUNT backup files, removing oldest..."
    
    # Remove oldest backups, keep newest 10
    ls -t "$BACKUP_DIR"/thirsttrack_backup_*.sql.gz | tail -n +11 | while read -r file; do
        print_status "Removing old backup: $(basename "$file")"
        rm "$file"
    done
    
    NEW_COUNT=$(ls -1 "$BACKUP_DIR"/thirsttrack_backup_*.sql.gz 2>/dev/null | wc -l)
    print_status "Cleanup completed. $NEW_COUNT backup files remaining"
}

# Function to create automatic backup cron job
setup_auto_backup() {
    print_status "Setting up automatic daily backups..."
    
    # Create cron job for daily backups at 2 AM
    CRON_JOB="0 2 * * * /home/jannisreufsteck/thirst-track2/deployment/scripts/backup-database.sh backup && /home/jannisreufsteck/thirst-track2/deployment/scripts/backup-database.sh cleanup"
    
    # Add to crontab if not already present
    if ! crontab -l 2>/dev/null | grep -q "backup-database.sh"; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        print_status "Automatic daily backup scheduled for 2:00 AM"
    else
        print_warning "Automatic backup already configured"
    fi
}

# Main script logic
case "$1" in
    backup)
        create_backup
        ;;
    restore)
        restore_backup "$2"
        ;;
    list)
        list_backups
        ;;
    cleanup)
        cleanup_backups
        ;;
    auto-setup)
        setup_auto_backup
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
