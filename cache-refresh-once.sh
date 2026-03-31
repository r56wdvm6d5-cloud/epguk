#!/bin/bash

# Single-Run Jsdelivr Cache Update Script
# Runs once, finds latest timestamp, forces update, then stops

REPO="r56wdvm6d5-cloud/epguk"
FILE="tvshow_epg.xml"
BRANCH="main"

echo "=== Single-Run Jsdelivr Cache Update ==="
echo "Repository: $REPO"
echo "File: $FILE"
echo "Branch: $BRANCH"
echo "----------------------------------------"

# Step 1: Get latest timestamp from GitHub
echo "[1] Getting latest timestamp from GitHub..."
GITHUB_CONTENT=$(curl -s "https://raw.githubusercontent.com/${REPO}/${BRANCH}/${FILE}")
LATEST_TIMESTAMP=$(echo "$GITHUB_CONTENT" | grep -o 'date="[^"]*' | head -1 | cut -d'"' -f2)

if [ -z "$LATEST_TIMESTAMP" ]; then
    echo "❌ Failed to get timestamp from GitHub"
    echo "🔍 Debug: First 200 chars of GitHub content:"
    echo "$GITHUB_CONTENT" | head -c 200
    exit 1
fi

echo "✅ Latest GitHub timestamp: $LATEST_TIMESTAMP"

# Step 2: Get current jsdelivr timestamp
echo "[2] Checking current jsdelivr timestamp..."
JSD_CONTENT=$(curl -s "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${FILE}")
CURRENT_TIMESTAMP=$(echo "$JSD_CONTENT" | grep -o 'date="[^"]*' | head -1 | cut -d'"' -f2)

echo "📊 Current jsdelivr timestamp: $CURRENT_TIMESTAMP"

# Step 3: Compare timestamps
if [ "$LATEST_TIMESTAMP" = "$CURRENT_TIMESTAMP" ]; then
    echo "✅ Jsdelivr is already up-to-date!"
    echo "🎯 Target timestamp: $LATEST_TIMESTAMP"
    echo "📋 Current timestamp: $CURRENT_TIMESTAMP"
    echo "🔚 Script completed - no update needed"
    exit 0
fi

echo "⚠️  Jsdelivr needs update!"
echo "🎯 Target timestamp: $LATEST_TIMESTAMP"
echo "📋 Current timestamp: $CURRENT_TIMESTAMP"

# Step 3: Force update to latest version
echo "[3] Forcing jsdelivr update to latest version..."

# Method 1: Get latest commit SHA (fixed)
echo "📝 Getting latest commit SHA..."
LATEST_SHA=$(curl -s "https://api.github.com/repos/${REPO}/commits/${BRANCH}" | grep '"sha"' | head -1 | cut -d'"' -f4)
echo "📝 Latest commit SHA: $LATEST_SHA"

# Method 2: Force refresh with SHA
if [ -n "$LATEST_SHA" ] && [ "$LATEST_SHA" != "null" ]; then
    echo "🔄 Forcing refresh with commit SHA..."
    SHA_RESPONSE=$(curl -s -w "%{http_code}" "https://cdn.jsdelivr.net/gh/${REPO}@${LATEST_SHA}/${FILE}")
    echo "📊 SHA refresh response: $SHA_RESPONSE"
    
    # Method 3: Force refresh main branch with cache-busting
    TIMESTAMP=$(date +%s%N)
    MAIN_RESPONSE=$(curl -s -w "%{http_code}" "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${FILE}?_t=${TIMESTAMP}")
    echo "📊 Main branch refresh response: $MAIN_RESPONSE"
    
    # Method 4: Try purge endpoint
    PURGE_RESPONSE=$(curl -s -w "%{http_code}" -X PURGE "https://purge.jsdelivr.net/gh/${REPO}@${BRANCH}/${FILE}")
    echo "📊 Purge response: $PURGE_RESPONSE"
    
    # Method 5: Multiple refresh attempts
    echo "🔄 Multiple refresh attempts..."
    for i in {1..5}; do
        TIMESTAMP=$(date +%s%N)
        REFRESH_RESPONSE=$(curl -s -w "%{http_code}" "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${FILE}?t=${TIMESTAMP}")
        echo "📊 Refresh attempt $i: $REFRESH_RESPONSE"
        sleep 1
    done
else
    echo "❌ Failed to get valid commit SHA"
fi

# Step 5: Verify update
echo "[4] Verifying update..."
sleep 3  # Wait a moment for jsdelivr to process

UPDATED_CONTENT=$(curl -s "https://cdn.jsdelivr.net/gh/${REPO}@${BRANCH}/${FILE}")
UPDATED_TIMESTAMP=$(echo "$UPDATED_CONTENT" | grep -o 'date="[^"]*' | head -1 | cut -d'"' -f2)

echo "📊 Updated jsdelivr timestamp: $UPDATED_TIMESTAMP"

if [ "$UPDATED_TIMESTAMP" = "$LATEST_TIMESTAMP" ]; then
    echo "✅ SUCCESS! Jsdelivr updated to latest version"
    echo "🎯 Target: $LATEST_TIMESTAMP"
    echo "📋 Result: $UPDATED_TIMESTAMP"
else
    echo "❌ Update incomplete"
    echo "🎯 Target: $LATEST_TIMESTAMP"
    echo "📋 Result: $UPDATED_TIMESTAMP"
fi

echo "🔚 Script completed"
echo "========================================"
