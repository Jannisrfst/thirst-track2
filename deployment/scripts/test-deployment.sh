#!/bin/bash

# Thirst Track Deployment Testing Script
# This script tests all components of the deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/home/pi/thirst-track2"
API_URL="http://localhost:5001"
WEB_URL="http://localhost"

echo -e "${BLUE}=== Thirst Track Deployment Test ===${NC}"

# Function to print test results
test_pass() {
    echo -e "${GREEN}✓ PASS:${NC} $1"
}

test_fail() {
    echo -e "${RED}✗ FAIL:${NC} $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
}

test_info() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

FAILED_TESTS=0

# Test 1: Check if services are running
test_info "Checking system services..."

if systemctl is-active --quiet postgresql; then
    test_pass "PostgreSQL service is running"
else
    test_fail "PostgreSQL service is not running"
fi

if systemctl is-active --quiet nginx; then
    test_pass "Nginx service is running"
else
    test_fail "Nginx service is not running"
fi

if systemctl is-active --quiet thirst-track-backend; then
    test_pass "Thirst Track backend service is running"
else
    test_fail "Thirst Track backend service is not running"
fi

# Test 2: Check database connectivity
test_info "Testing database connectivity..."
if sudo -u postgres psql -d thirsttrack -c "SELECT 1;" > /dev/null 2>&1; then
    test_pass "Database connection successful"
else
    test_fail "Database connection failed"
fi

# Test 3: Check if database table exists
test_info "Checking database schema..."
if sudo -u postgres psql -d thirsttrack -c "SELECT * FROM entries LIMIT 1;" > /dev/null 2>&1; then
    test_pass "Database table 'entries' exists and accessible"
else
    test_fail "Database table 'entries' not found or not accessible"
fi

# Test 4: Test Flask API endpoints
test_info "Testing Flask API endpoints..."

# Test API health
if curl -s -f "$API_URL/api/entries" > /dev/null; then
    test_pass "API endpoint /api/entries is responding"
else
    test_fail "API endpoint /api/entries is not responding"
fi

# Test API add endpoint
test_info "Testing API add functionality..."
RESPONSE=$(curl -s -X POST "$API_URL/api/add" \
    -H "Content-Type: application/json" \
    -d '{"barcode":"test123","quantity":1}' \
    -w "%{http_code}")

if [[ "$RESPONSE" == *"200" ]]; then
    test_pass "API add endpoint is working"
else
    test_fail "API add endpoint failed (Response: $RESPONSE)"
fi

# Test 5: Test web frontend
test_info "Testing web frontend..."

if curl -s -f "$WEB_URL" > /dev/null; then
    test_pass "Web frontend is accessible"
else
    test_fail "Web frontend is not accessible"
fi

# Test if React app is properly built
if [ -f "$APP_DIR/frontend/dist/index.html" ]; then
    test_pass "React frontend build files exist"
else
    test_fail "React frontend build files not found"
fi

# Test 6: Check file permissions
test_info "Checking file permissions..."

if [ -r "$APP_DIR/.env" ]; then
    test_pass "Environment file is readable"
else
    test_fail "Environment file is not readable"
fi

if [ -x "$APP_DIR/venv/bin/python" ]; then
    test_pass "Python virtual environment is accessible"
else
    test_fail "Python virtual environment is not accessible"
fi

# Test 7: Check network accessibility
test_info "Testing network accessibility..."

# Get Pi's IP address
PI_IP=$(hostname -I | awk '{print $1}')
echo "Pi IP Address: $PI_IP"

if curl -s -f "http://$PI_IP" > /dev/null; then
    test_pass "Web interface accessible via Pi IP ($PI_IP)"
else
    test_fail "Web interface not accessible via Pi IP ($PI_IP)"
fi

# Test 8: Check USB device access (for barcode scanner)
test_info "Checking USB device access..."

if ls /dev/input/event* > /dev/null 2>&1; then
    test_pass "Input devices found (potential barcode scanner support)"
    echo "Available input devices:"
    ls -la /dev/input/event*
else
    test_fail "No input devices found"
fi

# Test 9: Check log files
test_info "Checking application logs..."

if journalctl -u thirst-track-backend --no-pager -n 5 > /dev/null 2>&1; then
    test_pass "Backend service logs accessible"
    echo "Recent backend logs:"
    journalctl -u thirst-track-backend --no-pager -n 3
else
    test_fail "Backend service logs not accessible"
fi

# Test 10: Memory and CPU usage
test_info "Checking system resources..."

MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')

echo "Memory usage: ${MEMORY_USAGE}%"
echo "CPU load: ${CPU_LOAD}"

if (( $(echo "$MEMORY_USAGE < 80" | bc -l) )); then
    test_pass "Memory usage is acceptable (${MEMORY_USAGE}%)"
else
    test_fail "Memory usage is high (${MEMORY_USAGE}%)"
fi

# Summary
echo -e "\n${BLUE}=== Test Summary ===${NC}"
if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}All tests passed! Deployment is successful.${NC}"
    echo -e "\n${YELLOW}Access your application at:${NC}"
    echo "- Local: http://localhost"
    echo "- Network: http://$PI_IP"
    echo -e "\n${YELLOW}Service management commands:${NC}"
    echo "- Check status: sudo systemctl status thirst-track-backend"
    echo "- View logs: journalctl -u thirst-track-backend -f"
    echo "- Restart: sudo systemctl restart thirst-track-backend"
else
    echo -e "${RED}$FAILED_TESTS test(s) failed. Please check the issues above.${NC}"
    exit 1
fi
