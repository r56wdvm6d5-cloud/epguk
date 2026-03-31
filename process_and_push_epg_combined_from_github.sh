#!/bin/bash

# Combined Multi-XML Processing and Push Script (from Github folder)
# This script:
# 1. Processes XML using multi_xml_processor.py
# 2. Pushes the result from Github folder to GitHub using manual_push_epg_combined_from_github.sh

set -e

# Configuration
MULTI_PROCESSOR_DIR="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/multi_processor"
MULTI_CONFIG="../config_txt/multi_xml_config.txt"
MULTI_OUTPUT="../Github/epg_combined.xml"
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
print_status "Starting combined Multi-XML processing and GitHub push (from Github folder)..."

# Step 1: Process XML using multi_xml_processor.py
print_step "Step 1: Processing XML with multi_xml_processor.py"
print_status "Changing to multi_processor directory..."
cd "$MULTI_PROCESSOR_DIR"

print_status "Running multi_xml_processor.py..."
print_status "Config: $MULTI_CONFIG"
print_status "Output: $MULTI_OUTPUT"

if [ ! -f "multi_xml_processor.py" ]; then
    print_error "multi_xml_processor.py not found in $MULTI_PROCESSOR_DIR"
    exit 1
fi

if [ ! -f "$MULTI_CONFIG" ]; then
    print_error "Configuration file not found: $MULTI_CONFIG"
    exit 1
fi

# Execute the XML processor
python3 multi_xml_processor.py --config "$MULTI_CONFIG" --output "$MULTI_OUTPUT"

# Check if processing was successful
if [ $? -eq 0 ]; then
    print_success "XML processing completed successfully"
else
    print_error "XML processing failed"
    exit 1
fi

# Verify output file was created
OUTPUT_FILE_FULL_PATH="$(cd "$(dirname "$MULTI_OUTPUT")" && pwd)/$(basename "$MULTI_OUTPUT")"
if [ ! -f "$OUTPUT_FILE_FULL_PATH" ]; then
    print_error "Output file not created: $OUTPUT_FILE_FULL_PATH"
    exit 1
fi

print_success "Output file created: $OUTPUT_FILE_FULL_PATH"

# Step 2: Push to GitHub using manual_push_epg_combined_from_github.sh
print_step "Step 2: Pushing to GitHub using manual_push_epg_combined_from_github.sh"
print_status "Changing to GitHub push directory..."
cd "$GITHUB_PUSH_DIR"

if [ ! -f "manual_push_epg_combined_from_github.sh" ]; then
    print_error "manual_push_epg_combined_from_github.sh not found in $GITHUB_PUSH_DIR"
    exit 1
fi

# Make sure the script is executable
chmod +x "./manual_push_epg_combined_from_github.sh"

print_status "Executing manual push script..."
./manual_push_epg_combined_from_github.sh

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
echo "- XML processed and saved to: $OUTPUT_FILE_FULL_PATH"
echo "- File pushed to GitHub at: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/epg_combined.xml"
echo "- Process completed at: $(date '+%Y-%m-%d %H:%M:%S')"
