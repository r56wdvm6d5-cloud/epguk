#!/bin/bash

# GitHub Actions Compatible All EPG Processing and Push Script
# Processes all 7 EPG sources and pushes to GitHub

set -e

# Configuration for GitHub Actions
GITHUB_PUSH_DIR="."  # Current directory in GitHub Actions

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Start the combined process
print_status "Starting all 7 EPG sources processing and GitHub push..."

# Execute the combined processing script
if [ -f "process_and_push_epg_combined_from_github.sh" ]; then
    print_step "Executing process_and_push_epg_combined_from_github.sh..."
    chmod +x "./process_and_push_epg_combined_from_github.sh"
    ./process_and_push_epg_combined_from_github.sh
    
    if [ $? -eq 0 ]; then
        print_success "All EPG processing completed successfully"
    else
        print_error "EPG processing failed"
        exit 1
    fi
else
    print_error "process_and_push_epg_combined_from_github.sh not found"
    exit 1
fi

print_success "All processes completed successfully!"
