#!/bin/bash

# GitHub Actions Compatible TV4 Processing and Push Script

set -e

# Configuration for GitHub Actions
TV4_PROCESSOR_DIR="../TV4"
TV4_CONFIG="../TV4/TV4.txt"
TV4_OUTPUT="../TV4_epg.xml"

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

# Start TV4 processing
print_status "Starting TV4 EPG processing and GitHub push..."

print_step "Processing TV4..."
print_status "Changing to $TV4_PROCESSOR_DIR..."
cd "$TV4_PROCESSOR_DIR"

if [ ! -f "TV4_multi_xml_processor.py" ]; then
    print_error "TV4_multi_xml_processor.py not found in $TV4_PROCESSOR_DIR"
    exit 1
fi

if [ ! -f "$TV4_CONFIG" ]; then
    print_error "Config file not found: $TV4_CONFIG"
    exit 1
fi

print_status "Running TV4_multi_xml_processor.py..."
python3 "TV4_multi_xml_processor.py" --config "$TV4_CONFIG" --output "$TV4_OUTPUT"

if [ $? -eq 0 ]; then
    print_success "TV4 processing completed successfully"
else
    print_error "TV4 processing failed"
    exit 1
fi

# Push to GitHub
print_step "Pushing TV4_epg.xml to GitHub..."
print_status "Adding TV4_epg.xml to git..."
git add "$TV4_OUTPUT"

if git diff --staged --quiet; then
    print_status "Committing changes..."
    git commit -m "Auto update TV4_epg.xml - $(date '+%Y-%m-%d %H:%M:%S')"
    
    print_status "Pushing to GitHub..."
    git push origin main
    
    if [ $? -eq 0 ]; then
        print_success "TV4_epg.xml pushed to GitHub successfully"
    else
        print_error "Failed to push to GitHub"
        exit 1
    fi
else
    print_status "No changes to commit"
fi

print_success "TV4 process completed successfully!"
