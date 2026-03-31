#!/bin/bash

# Combined Doc2:TV XML Processing and Push Script
# This script:
# 1. Processes XML using DOC2:tvshow multi_xml_processor.py
# 2. Pushes the result to GitHub using manual_push_tvshow.sh

set -e

# Configuration
DOC2_TV_PROCESSOR_DIR="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Doc2:TV/DOC2:tvshow multi_processor"
DOC2_TV_CONFIG="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Doc2:TV/DOC2:tvshow config_txt/DOC2:tvshow_multi_xml_config.txt"
DOC2_TV_OUTPUT="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Doc2:TV/DOC2:tvshow Github/Doc2/tvshow_epg.xml"
GITHUB_PUSH_DIR="/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"

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

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# Start the combined process
print_status "Starting combined Doc2:TV XML processing and GitHub push..."

# Step 1: Process XML using DOC2:tvshow multi_xml_processor.py
print_step "Step 1: Processing XML with DOC2:tvshow multi_xml_processor.py"
print_status "Changing to Doc2:TV processor directory..."
cd "$DOC2_TV_PROCESSOR_DIR"

print_status "Running DOC2:tvshow multi_xml_processor.py..."
print_status "Config: $DOC2_TV_CONFIG"
print_status "Output: $DOC2_TV_OUTPUT"

if [ ! -f "DOC2:tvshow multi_xml_processor.py" ]; then
    print_error "DOC2:tvshow multi_xml_processor.py not found in $DOC2_TV_PROCESSOR_DIR"
    exit 1
fi

if [ ! -f "$DOC2_TV_CONFIG" ]; then
    print_error "Configuration file not found: $DOC2_TV_CONFIG"
    exit 1
fi

# Execute the XML processor
python3 "DOC2:tvshow multi_xml_processor.py" --config "$DOC2_TV_CONFIG" --output "$DOC2_TV_OUTPUT"

# Check if processing was successful
if [ $? -eq 0 ]; then
    print_success "XML processing completed successfully"
else
    print_error "XML processing failed"
    exit 1
fi

# Verify output file was created
if [ ! -f "$DOC2_TV_OUTPUT" ]; then
    print_error "Output file not created: $DOC2_TV_OUTPUT"
    exit 1
fi

print_success "Output file created: $DOC2_TV_OUTPUT"

# Step 2: Push to GitHub using manual_push_tvshow.sh
print_step "Step 2: Pushing to GitHub using manual_push_tvshow.sh"
print_status "Changing to GitHub push directory..."
cd "$GITHUB_PUSH_DIR"

if [ ! -f "manual_push_tvshow.sh" ]; then
    print_error "manual_push_tvshow.sh not found in $GITHUB_PUSH_DIR"
    exit 1
fi

# Make sure the script is executable
chmod +x "./manual_push_tvshow.sh"

print_status "Executing manual push script..."
./manual_push_tvshow.sh

# Check if push was successful
if [ $? -eq 0 ]; then
    print_success "GitHub push completed successfully"
else
    print_error "GitHub push failed"
    exit 1
fi

print_success "Combined process completed successfully!"
echo ""
print_status "Summary:"
echo "- XML processed and saved to: $DOC2_TV_OUTPUT"
echo "- File pushed to GitHub at: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/DOC2%3Atvshow%20Github/Doc2/tvshow_epg.xml"
echo "- Process completed at: $(date '+%Y-%m-%d %H:%M:%S')"
