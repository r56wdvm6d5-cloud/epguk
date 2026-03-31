#!/bin/bash
cd "$(dirname "$0")"
echo "Updating EPG data and pushing to GitHub..."
./process_and_push_tvshow.sh
echo "Starting jsdelivr cache refresh..."
./run-refresh.sh
