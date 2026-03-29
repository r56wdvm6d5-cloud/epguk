#!/bin/bash

# AUTO1 EPG Auto-Push Script
# Monitors and pushes changes to epg_combined.xml

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EPG_FILE="$SCRIPT_DIR/epg_combined.xml"
PID_FILE="$SCRIPT_DIR/monitor_auto1.pid"
LOG_FILE="$SCRIPT_DIR/auto1_push.log"
HASH_FILE="$SCRIPT_DIR/.last_hash_auto1"
MTIME_FILE="$SCRIPT_DIR/.last_mtime_auto1"
SOURCE_HASH_FILE="$SCRIPT_DIR/.last_hash_source"
SOURCE_MTIME_FILE="$SCRIPT_DIR/.last_mtime_source"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}[AUTO1-PUSH]${NC} $1"
    log_message "INFO: $1"
}

print_error() {
    echo -e "${RED}[AUTO1-PUSH]${NC} $1"
    log_message "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}[AUTO1-PUSH]${NC} $1"
    log_message "WARNING: $1"
}

# Function to check if auto-push is already running
check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            print_warning "Auto-push is already running (PID: $pid)"
            return 1
        else
            rm -f "$PID_FILE"
        fi
    fi
    return 0
}

# Function to get current hash of EPG file
get_current_hash() {
    if [ -f "$EPG_FILE" ]; then
        md5sum "$EPG_FILE" | cut -d' ' -f1
    else
        echo ""
    fi
}

# Function to get file modification time
get_mtime() {
    if [ -f "$1" ]; then
        stat -f "%m" "$1" 2>/dev/null || stat -c "%Y" "$1" 2>/dev/null
    else
        echo "0"
    fi
}

# Function to get last stored hash
get_last_hash() {
    if [ -f "$HASH_FILE" ]; then
        cat "$HASH_FILE"
    else
        echo ""
    fi
}

# Function to get last stored mtime
get_last_mtime() {
    if [ -f "$MTIME_FILE" ]; then
        cat "$MTIME_FILE"
    else
        echo "0"
    fi
}

# Function to update last hash
update_last_hash() {
    echo "$1" > "$HASH_FILE"
}

# Function to update last mtime
update_last_mtime() {
    echo "$1" > "$MTIME_FILE"
}

# Function to push to GitHub
push_to_github() {
    print_status "Changes detected, pushing to GitHub..."
    
    # Change to the final_multi_system directory for git operations
    cd "/Users/ah/CascadeProjects/windsurf-project/final_multi_system"
    
    # Add the updated file
    git add "Github/epg_combined.xml"
    
    # Commit with timestamp
    local commit_msg="Auto-update EPG combined XML file (AUTO1) - $(date '+%Y-%m-%d %H:%M:%S')"
    git commit -m "$commit_msg"
    
    # Push to GitHub
    if git push origin main; then
        print_status "Successfully pushed to GitHub"
        return 0
    else
        print_error "Failed to push to GitHub"
        return 1
    fi
}

# Function to monitor and auto-push
monitor_and_push() {
    print_status "Starting AUTO1 EPG monitoring..."
    
    # Check if already running
    if ! check_running; then
        exit 1
    fi
    
    # Save PID
    echo $$ > "$PID_FILE"
    
    # Get initial hash and mtime
    local last_hash=$(get_last_hash)
    local last_mtime=$(get_last_mtime)
    print_status "Initial hash: $last_hash"
    print_status "Initial mtime: $last_mtime"
    
    # Monitor loop
    while true; do
        # Check if EPG file exists
        if [ ! -f "$EPG_FILE" ]; then
            print_error "EPG file not found: $EPG_FILE"
            sleep 60
            continue
        fi
        
        # Get current hash and mtime
        local current_hash=$(get_current_hash)
        local current_mtime=$(get_mtime "$EPG_FILE")
        
        # Check if file changed
        if [ "$current_hash" != "$last_hash" ] || [ "$current_mtime" != "$last_mtime" ]; then
            print_status "EPG file changed (hash: $current_hash, mtime: $current_mtime)"
            
            # Copy to final_multi_system Github directory
            cp "$EPG_FILE" "/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Github/epg_combined.xml"
            
            # Push to GitHub
            if push_to_github; then
                # Update last hash and mtime
                update_last_hash "$current_hash"
                update_last_mtime "$current_mtime"
                last_hash="$current_hash"
                last_mtime="$current_mtime"
                print_status "Updated last hash: $last_hash"
                print_status "Updated last mtime: $last_mtime"
            else
                print_error "Push failed, will retry next cycle"
            fi
        fi
        
        # Wait before next check
        sleep 60  # Check every minute
    done
}

# Function to stop monitoring
stop_monitoring() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid
            print_status "Stopped AUTO1 monitoring (PID: $pid)"
        else
            print_warning "AUTO1 monitoring was not running"
        fi
        rm -f "$PID_FILE"
    else
        print_warning "AUTO1 monitoring was not running"
    fi
}

# Function to check status
check_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            print_status "AUTO1 monitoring is running (PID: $pid)"
        else
            print_warning "Stale PID file found"
        fi
    else
        print_status "AUTO1 monitoring is not running"
    fi
    
    # Show current hash info
    local last_hash=$(get_last_hash)
    local current_hash=$(get_current_hash)
    local last_mtime=$(get_last_mtime)
    local current_mtime=$(get_mtime "$EPG_FILE")
    print_status "Last hash: $last_hash"
    print_status "Current hash: $current_hash"
    print_status "Last mtime: $last_mtime"
    print_status "Current mtime: $current_mtime"
}

# Function to manual push
manual_push() {
    print_status "Performing manual push..."
    
    # Copy to final_multi_system Github directory
    if [ -f "$EPG_FILE" ]; then
        cp "$EPG_FILE" "/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Github/epg_combined.xml"
        push_to_github
        
        # Update hash and mtime
        local current_hash=$(get_current_hash)
        local current_mtime=$(get_mtime "$EPG_FILE")
        update_last_hash "$current_hash"
        update_last_mtime "$current_mtime"
        print_status "Manual push completed"
    else
        print_error "EPG file not found: $EPG_FILE"
    fi
}

# Function to show usage
show_usage() {
    echo "AUTO1 EPG Auto-Push Script"
    echo "Usage: $0 [start|stop|status|push|help]"
    echo ""
    echo "Commands:"
    echo "  start   - Start monitoring and auto-push"
    echo "  stop    - Stop monitoring"
    echo "  status  - Check status"
    echo "  push    - Manual push"
    echo "  help    - Show this help"
}

# Main script logic
case "$1" in
    start)
        monitor_and_push
        ;;
    stop)
        stop_monitoring
        ;;
    status)
        check_status
        ;;
    push)
        manual_push
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
