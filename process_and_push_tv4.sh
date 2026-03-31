#!/bin/bash

# Combined Script: Process TV4 XML and Push to GitHub
# This script:
# 1. Runs the TV4 multi-XML processor to generate/update TV4_epg.xml
# 2. Pushes the TV4_epg.xml file to GitHub

set -e

# Configuration
TV4_PROCESSOR_DIR="/Users/ah/CascadeProjects/windsurf-project/final_multi_system/TV4/TV4 multi_processor"
TV4_CONFIG_FILE="../TV4 config_txt/TV4.txt"
TV4_OUTPUT_FILE="../TV4 Github/TV4_epg.xml"
GITHUB_WORK_DIR="/Users/ah/CascadeProjects/windsurf-project/Github Push (final_multi_system)"
GITHUB_REPO_URL="https://github.com/r56wdvm6d5-cloud/epguk.git"
BRANCH="main"
TARGET_PATH="TV4 Github/TV4_epg.xml"

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Start of script
print_header "TV4 Process and Push Script"

# Step 1: Process TV4 XML
print_header "Step 1: Processing TV4 XML"

# Check if TV4 processor exists
if [ ! -f "$TV4_PROCESSOR_DIR/TV4 multi_xml_processor.py" ]; then
    print_error "TV4 processor not found: $TV4_PROCESSOR_DIR/TV4 multi_xml_processor.py"
    exit 1
fi

# Check if TV4 config exists
if [ ! -f "$TV4_PROCESSOR_DIR/$TV4_CONFIG_FILE" ]; then
    print_error "TV4 config file not found: $TV4_PROCESSOR_DIR/$TV4_CONFIG_FILE"
    exit 1
fi

print_status "Changing to TV4 processor directory..."
cd "$TV4_PROCESSOR_DIR"

print_status "Running TV4 multi-XML processor..."
print_status "Command: python3 \"TV4 multi_xml_processor.py\" --config \"$TV4_CONFIG_FILE\" --output \"$TV4_OUTPUT_FILE\""

if python3 "TV4 multi_xml_processor.py" --config "$TV4_CONFIG_FILE" --output "$TV4_OUTPUT_FILE"; then
    print_success "TV4 XML processing completed successfully!"
    
    # Check if output file was created
    if [ -f "$TV4_OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$TV4_OUTPUT_FILE" | cut -f1)
        print_success "Output file created: $TV4_OUTPUT_FILE (Size: $FILE_SIZE)"
    else
        print_error "Output file not found after processing: $TV4_OUTPUT_FILE"
        exit 1
    fi
else
    print_error "TV4 XML processing failed!"
    exit 1
fi

# Step 2: Push to GitHub
print_header "Step 2: Pushing to GitHub"

# Change to GitHub working directory
print_status "Changing to GitHub working directory..."
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

# Copy source file to working directory
print_status "Copying TV4_epg.xml from TV4 folder..."
cp "$TV4_PROCESSOR_DIR/$TV4_OUTPUT_FILE" "./TV4_epg.xml"

# Create TV4 Github directory structure in the git repo (preserving GitHub structure)
mkdir -p "TV4 Github"

# Copy file to the target path
print_status "Placing file in target directory structure..."
cp "./TV4_epg.xml" "$TARGET_PATH"

# Stage the files
print_status "Staging files for commit..."
git add "TV4_epg.xml"
git add "$TARGET_PATH"

# Check if there are changes to commit
if git diff --cached --quiet; then
    print_warning "No changes to commit. The file is already up to date."
    print_success "TV4 processing completed, but no push needed (file unchanged)"
    exit 0
fi

# Commit with timestamp
COMMIT_MESSAGE="Auto process and push TV4_epg.xml - $(date '+%Y-%m-%d %H:%M:%S')"
print_status "Committing changes..."
git commit -m "$COMMIT_MESSAGE"

# Force push to GitHub
print_status "Force pushing to GitHub repository..."
git push --force-with-lease origin main

# Cleanup temporary file
rm -f "./TV4_epg.xml"

# Final success message
print_header "Process Completed Successfully!"
print_success "TV4 XML has been processed and pushed to GitHub!"
print_success "GitHub URL: https://github.com/r56wdvm6d5-cloud/epguk/blob/main/TV4%20Github/TV4_epg.xml"

echo ""
print_status "Summary:"
echo "- TV4 Processor: $TV4_PROCESSOR_DIR/TV4 multi_xml_processor.py"
echo "- Config File: $TV4_CONFIG_FILE"
echo "- Output File: $TV4_OUTPUT_FILE"
echo "- GitHub Target: $TARGET_PATH"
echo "- Repository: $GITHUB_REPO_URL"
echo "- Branch: $BRANCH"
echo "- GitHub directory structure preserved intact"
