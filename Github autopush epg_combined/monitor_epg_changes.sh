#!/bin/bash

# AUTO1 EPG Monitor Script
# Monitors EPG file changes and triggers auto-push

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EPG_FILE="$SCRIPT_DIR/epg_combined.xml"
PID_FILE="$SCRIPT_DIR/.monitor_auto1.pid"
LOG_FILE="$SCRIPT_DIR/monitor_auto1.log"
AUTO_PUSH_SCRIPT="$SCRIPT_DIR/auto_push_epg.sh"

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
    echo -e "${GREEN}[AUTO1-MONITOR]${NC} $1"
    log_message "INFO: $1"
}

print_error() {
    echo -e "${RED}[AUTO1-MONITOR]${NC} $1"
    log_message "ERROR: $1"
}

print_warning() {
    echo -e "${YELLOW}[AUTO1-MONITOR]${NC} $1"
    log_message "WARNING: $1"
}

# Function to check if monitoring is already running
check_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            print_warning "Monitor is already running (PID: $pid)"
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

# Function to monitor file changes
monitor_file() {
    local check_interval=60  # Check every 60 seconds
    local last_hash=""
    
    print_status "Starting AUTO1 EPG file monitoring..."
    
    # Check if already running
    if ! check_running; then
        exit 1
    fi
    
    # Save PID
    echo $$ > "$PID_FILE"
    
    # Get initial hash
    last_hash=$(get_current_hash)
    print_status "Initial EPG file hash: $last_hash"
    
    # Monitor loop
    while true; do
        # Check if EPG file exists
        if [ ! -f "$EPG_FILE" ]; then
            print_error "EPG file not found: $EPG_FILE"
            sleep $check_interval
            continue
        fi
        
        # Get current hash
        local current_hash=$(get_current_hash)
        
        # Check if file changed
        if [ "$current_hash" != "$last_hash" ]; then
            print_status "EPG file changed!"
            print_status "Old hash: $last_hash"
            print_status "New hash: $current_hash"
            
            # Trigger auto-push
            if [ -f "$AUTO_PUSH_SCRIPT" ]; then
                print_status "Triggering auto-push..."
                "$AUTO_PUSH_SCRIPT" push
            else
                print_error "Auto-push script not found: $AUTO_PUSH_SCRIPT"
            fi
            
            # Update last hash
            last_hash="$current_hash"
        fi
        
        # Wait before next check
        sleep $check_interval
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
    
    # Show EPG file info
    if [ -f "$EPG_FILE" ]; then
        local file_size=$(stat -c%s "$EPG_FILE" 2>/dev/null || stat -f%z "$EPG_FILE" 2>/dev/null || echo "Unknown")
        local current_hash=$(get_current_hash)
        print_status "EPG file size: $file_size bytes"
        print_status "Current hash: $current_hash"
    else
        print_warning "EPG file not found: $EPG_FILE"
    fi
}

# Function to restart monitoring
restart_monitoring() {
    print_status "Restarting AUTO1 monitoring..."
    stop_monitoring
    sleep 2
    monitor_file
}

# Function to show usage
show_usage() {
    echo "AUTO1 EPG Monitor Script"
    echo "Usage: $0 [start|stop|restart|status|help]"
    echo ""
    echo "Commands:"
    echo "  start   - Start monitoring EPG file changes"
    echo "  stop    - Stop monitoring"
    echo "  restart - Restart monitoring"
    echo "  status  - Check monitoring status"
    echo "  help    - Show this help"
    echo ""
    echo "Files:"
    echo "  EPG File: $EPG_FILE"
    echo "  PID File: $PID_FILE"
    echo "  Log File: $LOG_FILE"
}

# Main script logic
case "$1" in
    start)
        monitor_file
        ;;
    stop)
        stop_monitoring
        ;;
    restart)
        restart_monitoring
        ;;
    status)
        check_status
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
