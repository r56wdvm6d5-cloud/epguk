#!/bin/bash

# Combined All XML Processing and Push Script
# This script:
# 1. Processes and pushes Doc2 XML
# 2. Processes and pushes Doc2:TV XML  
# 3. Processes and pushes TV2 XML
# 
# Location: Github Push (final_multi_system)

set -e

# Configuration
GITHUB_PUSH_DIR="/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
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

print_section() {
    echo -e "${MAGENTA}[SECTION]${NC} $1"
}

# Start the combined process
print_status "Starting combined XML processing and GitHub push for all sources..."
echo ""

# Section 1: Doc2 Processing and Push
print_section "Section 1: Doc2 XML Processing and Push"
print_step "Executing process_and_push_doc2.sh..."

cd "$GITHUB_PUSH_DIR/Doc2"

if [ ! -f "process_and_push_doc2.sh" ]; then
    print_error "process_and_push_doc2.sh not found in $GITHUB_PUSH_DIR/Doc2"
    exit 1
fi

# Make sure the script is executable
chmod +x "./process_and_push_doc2.sh"

# Execute Doc2 processing and push
./process_and_push_doc2.sh

# Check if Doc2 processing was successful
if [ $? -eq 0 ]; then
    print_success "Doc2 processing and push completed successfully"
else
    print_error "Doc2 processing and push failed"
    exit 1
fi

echo ""
print_section "Section 2: Doc2:TV XML Processing and Push"
print_step "Executing process_and_push_tvshow.sh..."

cd "$GITHUB_PUSH_DIR"

if [ ! -f "process_and_push_tvshow.sh" ]; then
    print_error "process_and_push_tvshow.sh not found in $GITHUB_PUSH_DIR"
    exit 1
fi

# Make sure the script is executable
chmod +x "./process_and_push_tvshow.sh"

# Execute Doc2:TV processing and push
./process_and_push_tvshow.sh

# Check if Doc2:TV processing was successful
if [ $? -eq 0 ]; then
    print_success "Doc2:TV processing and push completed successfully"
else
    print_error "Doc2:TV processing and push failed"
    exit 1
fi

echo ""
print_section "Section 3: TV2 XML Processing and Push"
print_step "Executing process_and_push_tv2.sh..."

cd "$GITHUB_PUSH_DIR"

if [ ! -f "process_and_push_tv2.sh" ]; then
    print_error "process_and_push_tv2.sh not found in $GITHUB_PUSH_DIR"
    exit 1
fi

# Make sure the script is executable
chmod +x "./process_and_push_tv2.sh"

# Execute TV2 processing and push
./process_and_push_tv2.sh

# Check if TV2 processing was successful
if [ $? -eq 0 ]; then
    print_success "TV2 processing and push completed successfully"
else
    print_error "TV2 processing and push failed"
    exit 1
fi

echo ""
print_success "All combined processes completed successfully!"
echo ""
print_status "Summary:"
echo "- Doc2 XML processed and pushed to: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/Doc2/Doc2%20Github/Doc2_Doc2_epg.xml"
echo "- Doc2:TV XML processed and pushed to: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/DOC2%3Atvshow%20Github/Doc2/tvshow_epg.xml"
echo "- TV2 XML processed and pushed to: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/TV2%20Github/TV2_epg.xml"
echo ""
print_status "Process completed at: $(date '+%Y-%m-%d %H:%M:%S')"
