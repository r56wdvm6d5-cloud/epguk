#!/bin/bash

# Manual Force Push Script for EPG Combined XML
# Provides manual force push functionality with EXPLAIN mode

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EPG_FILE="$SCRIPT_DIR/epg_combined.xml"
LOG_FILE="$SCRIPT_DIR/manual_force_push.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[MANUAL-PUSH]${NC} $1"
    log_message "INFO: $1"
}

print_error() {
    echo -e "${RED}[MANUAL-PUSH]${NC} $1"
    log_message "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}[MANUAL-PUSH]${NC} $1"
    log_message "WARNING: $1"
}

print_info() {
    echo -e "${BLUE}[MANUAL-PUSH]${NC} $1"
    log_message "INFO: $1"
}

# Function to show explanation
show_explain() {
    print_info "=== MANUAL FORCE PUSH SCRIPT EXPLANATION ==="
    echo ""
    print_info "PURPOSE:"
    echo "  This script manually forces a push of the epg_combined.xml file to GitHub."
    echo "  It bypasses any automatic monitoring and directly pushes changes."
    echo ""
    print_info "WHAT IT DOES:"
    echo "  1. Copies epg_combined.xml to the final_multi_system/Github/ directory"
    echo "  2. Changes to the final_multi_system directory for git operations"
    echo "  3. Adds the file to git staging area"
    echo "  4. Creates a commit with timestamp"
    echo "  5. Force pushes to GitHub (overwrites remote history)"
    echo ""
    print_info "FORCE PUSH WARNING:"
    echo "  - This uses 'git push --force' which overwrites remote history"
    echo "  - Only use if you're sure you want to replace remote content"
    echo "  - Can cause issues if others are working on the same branch"
    echo ""
    print_info "FILES INVOLVED:"
    echo "  Source: $EPG_FILE"
    echo "  Target: /Users/ah/CascadeProjects/windsurf-project/final_multi_system/Github/epg_combined.xml"
    echo "  Log: $LOG_FILE"
    echo ""
    print_info "USAGE:"
    echo "  $0 EXPLAIN    - Show this explanation"
    echo "  $0            - Perform the manual force push"
    echo ""
}

# Function to perform manual force push
manual_force_push() {
    print_status "Starting manual force push..."
    
    # Check if EPG file exists
    if [ ! -f "$EPG_FILE" ]; then
        print_error "EPG file not found: $EPG_FILE"
        exit 1
    fi
    
    print_status "EPG file found: $EPG_FILE"
    
    # Show file info
    local file_size=$(stat -f%z "$EPG_FILE" 2>/dev/null || stat -c%s "$EPG_FILE" 2>/dev/null)
    local file_mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$EPG_FILE" 2>/dev/null || stat -c "%y" "$EPG_FILE" 2>/dev/null | cut -d'.' -f1)
    print_status "File size: $file_size bytes"
    print_status "Last modified: $file_mtime"
    
    # Copy to final_multi_system Github directory
    print_status "Copying to final_multi_system/Github/ directory..."
    cp "$EPG_FILE" "/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Github/epg_combined.xml"
    
    if [ $? -eq 0 ]; then
        print_status "File copied successfully"
    else
        print_error "Failed to copy file"
        exit 1
    fi
    
    # Change to the final_multi_system directory for git operations
    print_status "Changing to final_multi_system directory..."
    cd "/Users/ah/CascadeProjects/windsurf-project/final_multi_system"
    
    # Check git status
    print_status "Checking git status..."
    git status
    
    # Add the updated file
    print_status "Adding file to git staging area..."
    git add "Github/epg_combined.xml"
    
    # Commit with timestamp
    local commit_msg="Manual force update EPG combined XML file - $(date '+%Y-%m-%d %H:%M:%S')"
    print_status "Creating commit: $commit_msg"
    git commit -m "$commit_msg"
    
    # Force push to GitHub
    print_warning "FORCE PUSHING to GitHub (this overwrites remote history)..."
    if git push --force origin main; then
        print_status "Successfully force pushed to GitHub"
        print_status "Manual force push completed successfully"
    else
        print_error "Failed to force push to GitHub"
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Manual Force Push Script for EPG Combined XML"
    echo "Usage: $0 [EXPLAIN]"
    echo ""
    echo "Commands:"
    echo "  EXPLAIN - Show detailed explanation of what this script does"
    echo "  (no args) - Perform the manual force push"
}

# Main script logic
case "$1" in
    EXPLAIN|explain)
        show_explain
        ;;
    help|--help|-h)
        show_usage
        ;;
    "")
        manual_force_push
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
