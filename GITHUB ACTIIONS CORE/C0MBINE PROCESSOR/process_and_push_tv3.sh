#!/bin/bash

# GitHub Actions Compatible TV3 Processing and Push Script

set -e

# Configuration for GitHub Actions
TV3_PROCESSOR_DIR="../TV3"
TV3_CONFIG="../TV3/TV3.txt"
TV3_OUTPUT="../TV3_epg.xml"

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

# Start TV3 processing
print_status "Starting TV3 EPG processing and GitHub push..."

print_step "Processing TV3..."
print_status "Changing to $TV3_PROCESSOR_DIR..."
cd "$TV3_PROCESSOR_DIR"

if [ ! -f "TV3_multi_xml_processor.py" ]; then
    print_error "TV3_multi_xml_processor.py not found in $TV3_PROCESSOR_DIR"
    exit 1
fi

if [ ! -f "$TV3_CONFIG" ]; then
    print_error "Config file not found: $TV3_CONFIG"
    exit 1
fi

print_status "Running TV3_multi_xml_processor.py..."
python3 "TV3_multi_xml_processor.py" --config "$TV3_CONFIG" --output "$TV3_OUTPUT"

if [ $? -eq 0 ]; then
    print_success "TV3 processing completed successfully"
else
    print_error "TV3 processing failed"
    exit 1
fi

# Push to GitHub
print_step "Pushing TV3_epg.xml to GitHub..."
print_status "Adding TV3_epg.xml to git..."
git add "$TV3_OUTPUT"

if git diff --staged --quiet; then
    print_status "Committing changes..."
    git commit -m "Auto update TV3_epg.xml - $(date '+%Y-%m-%d %H:%M:%S')"
    
    print_status "Pushing to GitHub..."
    git push origin main
    
    if [ $? -eq 0 ]; then
        print_success "TV3_epg.xml pushed to GitHub successfully"
    else
        print_error "Failed to push to GitHub"
        exit 1
    fi
else
    print_status "No changes to commit"
fi

print_success "TV3 process completed successfully!"
