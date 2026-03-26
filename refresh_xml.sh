#!/bin/bash

# XML Refresh Script
# This script refreshes from an original XML file while keeping DSMR output format

set -e

# Configuration
ORIGINAL_XML_URL="https://epg.pw/api/epg.xml?lang=en&timezone=QXNpYS9LYXJhY2hp&date=20260326&channel_id=9256"
ORIGINAL_XML_FILE="original.xml"
OUTPUT_DIR="output"
BACKUP_DIR="backup"
PYTHON_SCRIPT="xml_refresh.py"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to download original XML from URL
download_original_xml() {
    print_status "Downloading original XML from URL..."
    
    if command -v curl &> /dev/null; then
        curl -s -o "$ORIGINAL_XML_FILE" "$ORIGINAL_XML_URL"
    elif command -v wget &> /dev/null; then
        wget -q -O "$ORIGINAL_XML_FILE" "$ORIGINAL_XML_URL"
    else
        print_error "Neither curl nor wget is available for downloading!"
        exit 1
    fi
    
    if [ $? -eq 0 ] && [ -f "$ORIGINAL_XML_FILE" ]; then
        print_status "Successfully downloaded XML file"
    else
        print_error "Failed to download XML file!"
        exit 1
    fi
}

# Function to check if required files exist
check_requirements() {
    # Download the latest XML first
    download_original_xml
    
    if [ ! -f "$ORIGINAL_XML_FILE" ]; then
        print_error "Original XML file '$ORIGINAL_XML_FILE' not found!"
        exit 1
    fi
    
    if [ ! -f "$PYTHON_SCRIPT" ]; then
        print_error "Python script '$PYTHON_SCRIPT' not found!"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed!"
        exit 1
    fi
}

# Function to create necessary directories
setup_directories() {
    print_status "Setting up directories..."
    mkdir -p "$OUTPUT_DIR"
    mkdir -p "$BACKUP_DIR"
}

# Function to backup current output
backup_current_output() {
    if [ -f "$OUTPUT_DIR/dsmr_output.xml" ]; then
        print_status "Backing up current DSMR output..."
        cp "$OUTPUT_DIR/dsmr_output.xml" "$BACKUP_DIR/dsmr_output_$(date +%Y%m%d_%H%M%S).xml"
    fi
}

# Function to run the Python refresh script
run_refresh() {
    print_status "Running XML refresh process..."
    python3 "$PYTHON_SCRIPT" --input "$ORIGINAL_XML_FILE" --output "$OUTPUT_DIR/dsmr_output.xml"
    
    if [ $? -eq 0 ]; then
        print_status "XML refresh completed successfully!"
    else
        print_error "XML refresh failed!"
        exit 1
    fi
}

# Function to validate output
validate_output() {
    if [ -f "$OUTPUT_DIR/dsmr_output.xml" ]; then
        print_status "Validating DSMR output..."
        
        # Basic XML validation
        if python3 -c "import xml.etree.ElementTree as ET; ET.parse('$OUTPUT_DIR/dsmr_output.xml')" 2>/dev/null; then
            print_status "Output XML is valid!"
        else
            print_warning "Output XML may have issues"
        fi
        
        # Show file size
        file_size=$(du -h "$OUTPUT_DIR/dsmr_output.xml" | cut -f1)
        print_status "Output file size: $file_size"
    else
        print_error "No output file generated!"
        exit 1
    fi
}

# Main execution
main() {
    print_status "Starting XML refresh process..."
    
    check_requirements
    setup_directories
    backup_current_output
    run_refresh
    validate_output
    
    print_status "Process completed successfully!"
    print_status "DSMR output available at: $OUTPUT_DIR/dsmr_output.xml"
}

# Help function
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -i, --input    Specify input XML file (default: original.xml)"
    echo "  -o, --output   Specify output directory (default: output)"
    echo ""
    echo "This script refreshes from an original XML file while keeping DSMR output format."
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--input)
            ORIGINAL_XML_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main
