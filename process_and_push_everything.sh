#!/bin/bash

# Combined All XML Processing and Push Script (with epg_combined from Github folder)
# This script:
# 1. Processes and pushes epg_combined.xml from Github folder
# 2. Processes and pushes all other XML sources (Doc2, Doc2:TV, TV2)
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
print_status "Starting combined XML processing and GitHub push for all sources (including epg_combined from Github folder)..."
echo ""

# Section 1: epg_combined.xml Processing and Push from Github folder
print_section "Section 1: epg_combined.xml Processing and Push (from Github folder)"
print_step "Executing process_and_push_epg_combined_from_github.sh..."

cd "$GITHUB_PUSH_DIR"

if [ ! -f "process_and_push_epg_combined_from_github.sh" ]; then
    print_error "process_and_push_epg_combined_from_github.sh not found in $GITHUB_PUSH_DIR"
    exit 1
fi

# Make sure the script is executable
chmod +x "./process_and_push_epg_combined_from_github.sh"

# Execute epg_combined processing and push
./process_and_push_epg_combined_from_github.sh

# Check if epg_combined processing was successful
if [ $? -eq 0 ]; then
    print_success "epg_combined processing and push completed successfully"
else
    print_error "epg_combined processing and push failed"
    exit 1
fi

echo ""
print_section "Section 2: All Other XML Sources Processing and Push"
print_step "Executing process_and_push_all.sh..."

cd "$GITHUB_PUSH_DIR"

if [ ! -f "process_and_push_all.sh" ]; then
    print_error "process_and_push_all.sh not found in $GITHUB_PUSH_DIR"
    exit 1
fi

# Make sure the script is executable
chmod +x "./process_and_push_all.sh"

# Execute all other processing and push
./process_and_push_all.sh

# Check if all other processing was successful
if [ $? -eq 0 ]; then
    print_success "All other XML processing and push completed successfully"
else
    print_error "All other XML processing and push failed"
    exit 1
fi

echo ""
print_success "All combined processes completed successfully!"
echo ""
print_status "Summary:"
echo "- epg_combined.xml processed and pushed to: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/epg_combined.xml"
echo "- Doc2 XML processed and pushed to: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/Doc2/Doc2%20Github/Doc2_Doc2_epg.xml"
echo "- Doc2:TV XML processed and pushed to: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/DOC2%3Atvshow%20Github/Doc2/tvshow_epg.xml"
echo "- TV2 XML processed and pushed to: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/TV2%20Github/TV2_epg.xml"
echo ""
print_status "Process completed at: $(date '+%Y-%m-%d %H:%M:%S')"
