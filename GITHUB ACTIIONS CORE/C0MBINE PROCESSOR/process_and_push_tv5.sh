#!/bin/bash

# GitHub Actions Compatible TV5 Processing and Push Script

set -e

# Configuration for GitHub Actions
TV5_PROCESSOR_DIR="../TV5"
TV5_CONFIG="../TV5/TV5.txt"
TV5_OUTPUT="../TV5_epg.xml"

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

# Start TV5 processing
print_status "Starting TV5 EPG processing and GitHub push..."

print_step "Processing TV5..."
print_status "Changing to $TV5_PROCESSOR_DIR..."
cd "$TV5_PROCESSOR_DIR"

if [ ! -f "TV5_multi_xml_processor.py" ]; then
    print_error "TV5_multi_xml_processor.py not found in $TV5_PROCESSOR_DIR"
    exit 1
fi

if [ ! -f "$TV5_CONFIG" ]; then
    print_error "Config file not found: $TV5_CONFIG"
    exit 1
fi

print_status "Running TV5_multi_xml_processor.py..."
python3 "TV5_multi_xml_processor.py" --config "$TV5_CONFIG" --output "$TV5_OUTPUT"

if [ $? -eq 0 ]; then
    print_success "TV5 processing completed successfully"
else
    print_error "TV5 processing failed"
    exit 1
fi

# Push to GitHub
print_step "Pushing TV5_epg.xml to GitHub..."
print_status "Adding TV5_epg.xml to git..."
git add "$TV5_OUTPUT"

if git diff --staged --quiet; then
    print_status "Committing changes..."
    git commit -m "Auto update TV5_epg.xml - $(date '+%Y-%m-%d %H:%M:%S')"
    
    print_status "Pushing to GitHub..."
    git push origin main
    
    if [ $? -eq 0 ]; then
        print_success "TV5_epg.xml pushed to GitHub successfully"
    else
        print_error "Failed to push to GitHub"
        exit 1
    fi
else
    print_status "No changes to commit"
fi

print_success "TV5 process completed successfully!"
