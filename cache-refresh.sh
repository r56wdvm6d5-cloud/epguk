#!/bin/bash

# Jsdelivr Cache Refresh Script - FIXED VERSION
# Repository: r56wdvm6d5-cloud/epguk
# Files: tvshow_epg.xml, TV2_epg.xml, TV2 Github/TV2_epg.xml
# Branch: main

REPO="r56wdvm6d5-cloud/epguk"
FILES=("tvshow_epg.xml" "TV2_epg.xml" "TV2 Github/TV2_epg.xml")
BRANCH="main"

echo "Starting jsdelivr cache refresh for ${REPO} repository"
echo "Press Ctrl+C to stop"
echo "----------------------------------------"

while true; do
    echo "[$(date)] Refreshing cache for all XML files..."
    
    for FILE in "${FILES[@]}"; do
        echo "[$(date)] Processing: $FILE"
        
        # Method 1: Get latest commit SHA first
        LATEST_SHA=$(curl -s "https://api.github.com/repos/${REPO}/commits/${BRANCH}" | grep -o '"sha":"[^"]*' | head -1 | cut -d'"' -f4)
        echo "[$(date)] Latest SHA for $FILE: $LATEST_SHA"
        
        # Method 2: Force refresh using specific commit SHA (most reliable)
        if [ -n "$LATEST_SHA" ]; then
            echo "[$(date)] Forcing refresh with SHA: $LATEST_SHA"
            SHA_RESPONSE=$(curl -s -w "%{http_code}" "https://cdn.jsdelivr.net/gh/${REPO}@${LATEST_SHA}/${FILE}")
            echo "[$(date)] SHA refresh response for $FILE: $SHA_RESPONSE"
            
            # Method 3: Also try main branch with cache-busting
            TIMESTAMP=$(date +%s%N)  # Nanoseconds for uniqueness
            MAIN_RESPONSE=$(curl -s -w "%{http_code}" "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${FILE}?_t=${TIMESTAMP}")
            echo "[$(date)] Main branch refresh response for $FILE: $MAIN_RESPONSE"
        else
            echo "[$(date)] Failed to get latest SHA for $FILE"
        fi
        
        echo "[$(date)] Completed refresh for $FILE"
        echo "---"
    done
    
    echo "[$(date)] Cache refresh cycle completed. Waiting 5 minutes..."
    echo "----------------------------------------"
    sleep 300  # 5 minutes = 300 seconds
done
