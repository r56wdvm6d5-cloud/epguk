#!/bin/bash

# Manual/Force Push Script for epg_combined.xml
# This script manually pushes the epg_combined.xml file to GitHub root directory

set -e

# Configuration (using the active document path)
SOURCE_FILE="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/Github/auto1/epg_combined.xml"
GITHUB_WORK_DIR="/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"
GITHUB_REPO_URL="https://github.com/r56wdvm6d5-cloud/epguk.git"
BRANCH="main"
TARGET_FILE="epg_combined.xml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    print_error "Source file not found: $SOURCE_FILE"
    exit 1
fi

print_status "Starting manual push process for epg_combined.xml"

# Change to GitHub working directory
cd "$GITHUB_WORK_DIR"

# Ensure git repository is properly configured
if [ ! -d ".git" ]; then
    print_error "Not a git repository: $GITHUB_WORK_DIR"
    exit 1
fi

# Check git remote
if ! git remote get-url origin &>/dev/null; then
    print_warning "Git remote 'origin' not found, setting it up..."
    git remote add origin "$GITHUB_REPO_URL"
fi

# Pull latest changes to avoid conflicts
print_status "Pulling latest changes from remote..."
git pull origin main || print_warning "Pull failed, continuing with force push..."

# Copy the source file to working directory
print_status "Copying epg_combined.xml from source..."
cp "$SOURCE_FILE" "./$TARGET_FILE"

# Stage the file
print_status "Staging file for commit..."
git add "$TARGET_FILE"

# Check if there are changes to commit
if git diff --cached --quiet; then
    print_warning "No changes to commit. The file is already up to date."
    exit 0
fi

# Commit with timestamp
COMMIT_MESSAGE="Manual force push epg_combined.xml - $(date '+%Y-%m-%d %H:%M:%S')"
print_status "Committing changes..."
git commit -m "$COMMIT_MESSAGE"

# Force push to GitHub
print_status "Force pushing to GitHub repository..."
git push --force-with-lease origin main

# Cleanup temporary file (if different from target)
if [ "$TARGET_FILE" != "epg_combined.xml" ]; then
    rm -f "./epg_combined.xml"
fi

print_success "epg_combined.xml has been successfully pushed to GitHub!"
print_success "File location: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/epg_combined.xml"

echo ""
print_status "Summary:"
echo "- Source: $SOURCE_FILE"
echo "- Target: $TARGET_FILE (root directory)"
echo "- Repository: $GITHUB_REPO_URL"
echo "- Branch: $BRANCH"
echo "- GitHub directory structure preserved intact"
