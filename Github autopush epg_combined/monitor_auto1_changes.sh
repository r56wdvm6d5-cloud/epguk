#!/bin/bash

# AUTO1 EPG Monitor Script
# Monitors changes in ../Github/epg_combined.xml and copies to auto1 directory

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/.monitor_auto1.pid"
LOG_FILE="$SCRIPT_DIR/monitor_auto1.log"

# File paths
SOURCE_FILE="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Github/epg_combined.xml"
AUTO1_FILE="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Github/auto1/epg_combined.xml"

# Function to start monitoring
start_monitor() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            echo "AUTO1 Monitor is already running (PID: $pid)"
            return 1
        else
            rm -f "$PID_FILE"
        fi
    fi
    
    echo "Starting AUTO1 EPG Monitor..."
    nohup bash -c "
        while true; do
            if [ -f '$SOURCE_FILE' ]; then
                current_hash=\$(md5sum '$SOURCE_FILE' | cut -d' ' -f1)
                if [ ! -f '$SCRIPT_DIR/.last_source_hash' ]; then
                    echo '\$current_hash' > '$SCRIPT_DIR/.last_source_hash'
                    echo '$current_hash' > '$SCRIPT_DIR/.last_auto1_hash'
                    if cp '$SOURCE_FILE' '$AUTO1_FILE'; then
                        echo \"\$(date): Copied source to auto1 directory\"
                    fi
                elif [ '\$current_hash' != \$(cat '$SCRIPT_DIR/.last_source_hash' 2>/dev/null) ]; then
                    echo \"\$(date): Source file changed (hash: \$current_hash)\"
                    echo '\$current_hash' > '$SCRIPT_DIR/.last_source_hash'
                    if cp '$SOURCE_FILE' '$AUTO1_FILE'; then
                        echo \"\$(date): Copied updated source to auto1 directory\"
                        echo \"\$(date): Triggering auto-push...\"
                        if [ -f '$SCRIPT_DIR/auto_push_epg.sh' ]; then
                            '$SCRIPT_DIR/auto_push_epg.sh' push
                        fi
                    else
                        echo \"\$(date): Failed to copy to auto1 directory\"
                    fi
                fi
            else
                echo \"\$(date): Source file not found: $SOURCE_FILE\"
            fi
            sleep 60
        done
    " > "$LOG_FILE" 2>&1 &
    
    echo $! > "$PID_FILE"
    echo "AUTO1 Monitor started (PID: $!)"
}

# Function to stop monitoring
stop_monitor() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            kill $pid
            echo "AUTO1 Monitor stopped (PID: $pid)"
        else
            echo "AUTO1 Monitor was not running"
        fi
        rm -f "$PID_FILE"
    else
        echo "AUTO1 Monitor was not running"
    fi
}

# Function to check status
check_status() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p $pid > /dev/null 2>&1; then
            echo "AUTO1 Monitor is running (PID: $pid)"
        else
            echo "AUTO1 Monitor is not running (stale PID file)"
            rm -f "$PID_FILE"
        fi
    else
        echo "AUTO1 Monitor is not running"
    fi
}

# Main script logic
case "$1" in
    start)
        start_monitor
        ;;
    stop)
        stop_monitor
        ;;
    restart)
        stop_monitor
        sleep 2
        start_monitor
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
