#!/bin/bash

# Frontend Build Script for Production Deployment
# This script builds the React frontend for production use

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="/home/pi/thirst-track2"
FRONTEND_DIR="$APP_DIR/frontend"

echo -e "${BLUE}=== Frontend Build Process ===${NC}"

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

# Check if we're in the right directory
if [ ! -d "$FRONTEND_DIR" ]; then
    print_error "Frontend directory not found: $FRONTEND_DIR"
    exit 1
fi

cd $FRONTEND_DIR

# Check if package.json exists
if [ ! -f "package.json" ]; then
    print_error "package.json not found in frontend directory"
    exit 1
fi

# Clean previous build
print_status "Cleaning previous build..."
rm -rf dist/
rm -rf node_modules/.cache/

# Install dependencies
print_status "Installing Node.js dependencies..."
npm ci --production=false

# Set production environment
export NODE_ENV=production

# Build the application
print_status "Building React application for production..."
npm run build

# Verify build output
if [ ! -d "dist" ]; then
    print_error "Build failed - dist directory not created"
    exit 1
fi

if [ ! -f "dist/index.html" ]; then
    print_error "Build failed - index.html not found in dist"
    exit 1
fi

# Check build size
BUILD_SIZE=$(du -sh dist | cut -f1)
print_status "Build completed successfully!"
print_status "Build size: $BUILD_SIZE"

# List build contents
print_status "Build contents:"
ls -la dist/

# Optimize permissions
print_status "Setting proper permissions..."
chmod -R 644 dist/
find dist/ -type d -exec chmod 755 {} \;

print_status "Frontend build process completed!"
echo -e "${YELLOW}Build output location:${NC} $FRONTEND_DIR/dist"
echo -e "${YELLOW}Ready for nginx serving${NC}"
