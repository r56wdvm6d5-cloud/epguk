#!/bin/bash

# Combined Script: Process Everything + TV3
# This script:
# 1. Runs process_and_push_everything.sh
# 2. Runs process_and_push_tv3.sh
# 
# Location: Github Push (final_multi_system)

set -e

# Configuration
GITHUB_WORK_DIR="/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

# Start of script
print_header "Combined Process: Everything + TV3"

# Change to GitHub working directory
print_status "Changing to GitHub working directory..."
cd "$GITHUB_WORK_DIR"

# Check if required scripts exist
if [ ! -f "./process_and_push_everything.sh" ]; then
    print_error "process_and_push_everything.sh not found in $GITHUB_WORK_DIR"
    exit 1
fi

if [ ! -f "./process_and_push_tv3.sh" ]; then
    print_error "process_and_push_tv3.sh not found in $GITHUB_WORK_DIR"
    exit 1
fi

# Make sure scripts are executable
chmod +x "./process_and_push_everything.sh"
chmod +x "./process_and_push_tv3.sh"

# Step 1: Run process_and_push_everything.sh
print_header "Step 1: Processing Everything (Main System)"
print_status "Executing: ./process_and_push_everything.sh"

if ./process_and_push_everything.sh; then
    print_success "Everything script completed successfully!"
else
    print_error "Everything script failed!"
    exit 1
fi

# Step 2: Run process_and_push_tv3.sh
print_header "Step 2: Processing TV3"
print_status "Executing: ./process_and_push_tv3.sh"

if ./process_and_push_tv3.sh; then
    print_success "TV3 script completed successfully!"
else
    print_error "TV3 script failed!"
    exit 1
fi

# Final success message
print_header "Combined Process Completed Successfully!"
print_success "Both Everything and TV3 scripts have been executed successfully!"
print_success "All EPG files have been processed and pushed to GitHub!"

echo ""
print_status "Summary of operations:"
echo "1. ✓ Processed and pushed all main system EPG files"
echo "2. ✓ Processed and pushed TV3 EPG file"
echo "3. ✓ All files are now available on GitHub repository:"
echo "   - https://github.com/r56wdvm6d5-cloud/epguk"

echo ""
print_status "Scripts executed:"
echo "- ./process_and_push_everything.sh"
echo "- ./process_and_push_tv3.sh"
