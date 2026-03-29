#!/bin/bash

# Auto-refresh script for multi_xml_processor
# Runs multi_xml_processor.py every 30 minutes with latest dates and EPG
# Usage: ./auto_refresh_processor.sh [start|stop|status|restart]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROCESSOR_SCRIPT="$SCRIPT_DIR/multi_xml_processor.py"
CONFIG_FILE="../config_txt/multi_xml_config.txt"
OUTPUT_DIR="../Github"
PID_FILE="$SCRIPT_DIR/.auto_refresh_processor.pid"
LOG_FILE="$SCRIPT_DIR/auto_refresh_processor.log"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

start_refresh() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Auto-refresh processor is already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi
    
    echo "Starting auto-refresh processor (every 30 minutes)..."
    echo "$(date): Auto-refresh processor started" >> "$LOG_FILE"
    
    # Run initial refresh immediately
    echo "$(date): Running initial refresh..." >> "$LOG_FILE"
    run_processor >> "$LOG_FILE" 2>&1
    
    # Start background loop
    (
        while true; do
            sleep 1800  # 30 minutes = 1800 seconds
            echo "$(date): Running scheduled refresh..." >> "$LOG_FILE"
            run_processor >> "$LOG_FILE" 2>&1
        done
    ) &
    
    echo $! > "$PID_FILE"
    echo "Auto-refresh processor started (PID: $!)"
    echo "Log file: $LOG_FILE"
    echo "Output directory: $OUTPUT_DIR"
}

stop_refresh() {
    if [ ! -f "$PID_FILE" ]; then
        echo "Auto-refresh processor is not running"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "$(date): Auto-refresh processor stopped" >> "$LOG_FILE"
        echo "Auto-refresh processor stopped (PID: $PID)"
    else
        echo "Process $PID not found"
    fi
    
    rm -f "$PID_FILE"
}

status_refresh() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Auto-refresh processor is running (PID: $(cat "$PID_FILE"))"
        echo "Log file: $LOG_FILE"
        echo "Output directory: $OUTPUT_DIR"
        echo "Recent logs:"
        tail -10 "$LOG_FILE" 2>/dev/null || echo "No logs available"
    else
        echo "Auto-refresh processor is not running"
    fi
}

run_processor() {
    # Use fixed output filename to replace existing file each time
    OUTPUT_FILE="$OUTPUT_DIR/epg_combined.xml"
    
    echo "Processing EPG with latest dates..."
    echo "Config file: $CONFIG_FILE"
    echo "Output file: $OUTPUT_FILE"
    
    # Check if processor script exists
    if [ ! -f "$PROCESSOR_SCRIPT" ]; then
        echo "Error: Processor script not found: $PROCESSOR_SCRIPT"
        return 1
    fi
    
    # Check if config file exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Error: Config file not found: $CONFIG_FILE"
        return 1
    fi
    
    # Run the Python processor
    cd "$SCRIPT_DIR"
    python3 "$PROCESSOR_SCRIPT" --config "$CONFIG_FILE" --output "$OUTPUT_FILE"
    
    if [ $? -eq 0 ]; then
        echo "Successfully generated: $OUTPUT_FILE"
        echo "EPG file updated with latest data"
    else
        echo "Error: Failed to generate EPG file"
        return 1
    fi
}

case "${1:-start}" in
    start)
        start_refresh
        ;;
    stop)
        stop_refresh
        ;;
    status)
        status_refresh
        ;;
    restart)
        stop_refresh
        sleep 2
        start_refresh
        ;;
    run-once)
        run_processor
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart|run-once}"
        echo ""
        echo "Commands:"
        echo "  start    - Start auto-refresh (runs every 30 minutes)"
        echo "  stop     - Stop auto-refresh"
        echo "  status   - Check status and recent logs"
        echo "  restart  - Restart auto-refresh"
        echo "  run-once - Run processor once immediately"
        exit 1
        ;;
esac
