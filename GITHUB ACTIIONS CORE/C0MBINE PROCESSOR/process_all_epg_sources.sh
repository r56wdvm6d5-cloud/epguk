#!/bin/bash

# Unified EPG Processor - Handles all 7 EPG sources in one execution
# GitHub Actions Compatible

set -euo pipefail

# Configuration for GitHub Actions
MULTI_PROCESSOR_DIR="../DOC1"
MULTI_CONFIG="../DOC1/multi_xml_config.txt"
MULTI_OUTPUT="../epg_combined.xml"

DOC2_PROCESSOR_DIR="../Doc2TV"
DOC2_CONFIG="../Doc2TV/Doc2tvshow multi_xml_config.txt"
DOC2_OUTPUT="../Doc2_Doc2_epg.xml"

DOCTV_PROCESSOR_DIR="../Doc2TV"
DOCTV_CONFIG="../Doc2TV/DOC2tvshow multi_xml_config.txt"
DOCTV_OUTPUT="../tvshow_epg.xml"

TV2_PROCESSOR_DIR="../TV2"
TV2_CONFIG="../TV2/TV2.txt"
TV2_OUTPUT="../TV2_epg.xml"

TV3_PROCESSOR_DIR="../TV3"
TV3_CONFIG="../TV3/TV3.txt"
TV3_OUTPUT="../TV3_epg.xml"

TV4_PROCESSOR_DIR="../TV4"
TV4_CONFIG="../TV4/TV4.txt"
TV4_OUTPUT="../TV4_epg.xml"

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

# Function to process a single XML source
process_xml_source() {
    local processor_dir="$1"
    local config_file="$2"
    local output_file="$3"
    local source_name="$4"
    local processor_filename="$5"
    
    print_step "Processing $source_name..."
    print_status "Changing to $processor_dir..."
    cd "$processor_dir"
    
    if [ ! -f "$processor_filename" ]; then
        print_error "$processor_filename not found in $processor_dir"
        return 1
    fi
    
    if [ ! -f "$config_file" ]; then
        print_error "Config file not found: $config_file"
        return 1
    fi
    
    print_status "Running $processor_filename..."
    python3 "$processor_filename" --config "$config_file" --output "$output_file"
    
    if [ $? -eq 0 ]; then
        print_success "$source_name processing completed successfully"
        return 0
    else
        print_error "$source_name processing failed"
        return 1
    fi
}

# Function to safely add and commit files
safe_git_commit() {
    local files=("$@")
    local has_changes=false
    
    print_status "Checking for changes in files: ${files[*]}"
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            git add "$file"
            has_changes=true
            print_status "Added $file to git"
        fi
    done
    
    if [ "$has_changes" = true ]; then
        print_status "Committing changes..."
        git commit -m "Auto update all EPG files - $(date '+%Y-%m-%d %H:%M:%S')" || {
            print_warning "Git commit failed - no changes detected"
            return 0
        }
        
        print_status "Pushing to GitHub..."
        git push origin main || {
            print_error "Failed to push to GitHub"
            return 1
        }
        
        print_success "All EPG files pushed to GitHub successfully"
    else
        print_status "No changes to commit"
    fi
}

# Start unified processing
print_status "Starting unified EPG processing for all 7 sources..."

# Process all 7 sources with correct filenames
process_xml_source "$MULTI_PROCESSOR_DIR" "$MULTI_CONFIG" "$MULTI_OUTPUT" "Multi-XML Combined" "multi_xml_processor.py" || exit 1
process_xml_source "$DOC2_PROCESSOR_DIR" "$DOC2_CONFIG" "$DOC2_OUTPUT" "Doc2" "Doc2tvshow multi_xml_processor.py" || exit 1
process_xml_source "$DOCTV_PROCESSOR_DIR" "$DOCTV_CONFIG" "$DOCTV_OUTPUT" "Doc2:TV" "DOC2tvshow multi_xml_processor.py" || exit 1
process_xml_source "$TV2_PROCESSOR_DIR" "$TV2_CONFIG" "$TV2_OUTPUT" "TV2" "TV2_multi_xml_processor.py" || exit 1
process_xml_source "$TV3_PROCESSOR_DIR" "$TV3_CONFIG" "$TV3_OUTPUT" "TV3" "TV3_multi_xml_processor.py" || exit 1
process_xml_source "$TV4_PROCESSOR_DIR" "$TV4_CONFIG" "$TV4_OUTPUT" "TV4" "TV4_multi_xml_processor.py" || exit 1
process_xml_source "$TV5_PROCESSOR_DIR" "$TV5_CONFIG" "$TV5_OUTPUT" "TV5" "TV5_multi_xml_processor.py" || exit 1

# Push all outputs to GitHub safely
safe_git_commit "$MULTI_OUTPUT" "$DOC2_OUTPUT" "$DOCTV_OUTPUT" "$TV2_OUTPUT" "$TV3_OUTPUT" "$TV4_OUTPUT" "$TV5_OUTPUT"

print_success "All 7 EPG sources processed and pushed successfully!"
