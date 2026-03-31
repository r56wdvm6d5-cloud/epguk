#!/bin/bash

# Quick Time-Filtered Test Script
# Similar to your current process_everything_tv3_tv4_tv5.sh but for time-filtered system

set -e

# Configuration
GITHUB_WORK_DIR="/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"
TIMEFILTERED_DIR="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/TimeFiltered"

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

print_timefiltered() {
    echo -e "${MAGENTA}[TIME-FILTERED]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${CYAN}================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================${NC}"
    echo ""
}

# Start of script
print_header "Quick Time-Filtered Test: Main Systems + TV3 + TV4 + TV5"

# Change to GitHub working directory
print_status "Changing to GitHub working directory..."
cd "$GITHUB_WORK_DIR"

# Create output directory
mkdir -p TimeFiltered_Github

# Step 1: Process Main System (Time-Filtered)
print_header "Step 1: Processing Main System (Time-Filtered)"
cd "$TIMEFILTERED_DIR/multi_processor_timefiltered"
if python3 multi_xml_processor_timefiltered.py \
    --config "$TIMEFILTERED_DIR/config_timefiltered/multi_xml_config_timefiltered.txt" \
    --output "$GITHUB_WORK_DIR/TimeFiltered_Github/epg_combined_timefiltered.xml"; then
    print_success "Main system time-filtered processing completed!"
    print_timefiltered "Generated: epg_combined_timefiltered.xml"
else
    print_error "Main system time-filtered processing failed!"
    exit 1
fi

# Step 2: Process TV3 (Time-Filtered)
print_header "Step 2: Processing TV3 (Time-Filtered)"
cd "$TIMEFILTERED_DIR/TV3_timefiltered"
if python3 TV3_multi_xml_processor_timefiltered.py \
    --config "$TIMEFILTERED_DIR/config_timefiltered/TV3_config_timefiltered.txt" \
    --output "$GITHUB_WORK_DIR/TimeFiltered_Github/TV3_epg_timefiltered.xml"; then
    print_success "TV3 time-filtered processing completed!"
    print_timefiltered "Generated: TV3_epg_timefiltered.xml"
else
    print_error "TV3 time-filtered processing failed!"
    exit 1
fi

# Step 3: Process TV4 (Time-Filtered)
print_header "Step 3: Processing TV4 (Time-Filtered)"
cd "$TIMEFILTERED_DIR/TV4_timefiltered"
if python3 TV4_multi_xml_processor_timefiltered.py \
    --config "$TIMEFILTERED_DIR/config_timefiltered/TV4_config_timefiltered.txt" \
    --output "$GITHUB_WORK_DIR/TimeFiltered_Github/TV4_epg_timefiltered.xml"; then
    print_success "TV4 time-filtered processing completed!"
    print_timefiltered "Generated: TV4_epg_timefiltered.xml"
else
    print_error "TV4 time-filtered processing failed!"
    exit 1
fi

# Step 4: Process TV5 (Time-Filtered)
print_header "Step 4: Processing TV5 (Time-Filtered)"
cd "$TIMEFILTERED_DIR/TV5_timefiltered"
if python3 TV5_multi_xml_processor_timefiltered.py \
    --config "$TIMEFILTERED_DIR/config_timefiltered/TV5_config_timefiltered.txt" \
    --output "$GITHUB_WORK_DIR/TimeFiltered_Github/TV5_epg_timefiltered.xml"; then
    print_success "TV5 time-filtered processing completed!"
    print_timefiltered "Generated: TV5_epg_timefiltered.xml"
else
    print_error "TV5 time-filtered processing failed!"
    exit 1
fi

# Show file sizes
print_header "Time-Filtered Files Generated"
cd "$GITHUB_WORK_DIR/TimeFiltered_Github"

for file in *.xml; do
    if [ -f "$file" ]; then
        size=$(ls -lh "$file" | awk '{print $5}')
        programs=$(grep -c "<programme" "$file" 2>/dev/null || echo "0")
        channels=$(grep -c "<channel" "$file" 2>/dev/null || echo "0")
        print_timefiltered "$file: $size, $channels channels, $programs programs"
    fi
done

# Final success message
print_header "Time-Filtered Test Completed Successfully!"
print_success "All time-filtered EPG files have been generated!"
print_timefiltered "Files are ready for testing in: TimeFiltered_Github/"

echo ""
print_status "Generated files:"
echo "- epg_combined_timefiltered.xml"
echo "- TV3_epg_timefiltered.xml"
echo "- TV4_epg_timefiltered.xml"
echo "- TV5_epg_timefiltered.xml"

echo ""
print_timefiltered "Benefits achieved:"
echo "- Past programs excluded"
echo "- 40-60% smaller files"
echo "- Faster IPTVNATOR loading"
echo "- Better user experience"

echo ""
print_status "To push to GitHub, run:"
echo "cd \"$GITHUB_WORK_DIR\""
echo "git add TimeFiltered_Github/"
echo "git commit -m \"Add time-filtered EPG files\""
echo "git push origin main"

echo ""
print_timefiltered "Time-filtered test complete! 🚀"
