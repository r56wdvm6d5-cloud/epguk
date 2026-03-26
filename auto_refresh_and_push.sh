#!/bin/bash

# Auto Refresh and Push Script
# This script automatically refreshes XML and pushes to GitHub

set -e

# Configuration
REPO_DIR="/Users/ah/CascadeProjects/windsurf-project"
OUTPUT_FILE="output/dsmr_output.xml"
GITHUB_REPO_URL="https://github.com/r56wdvm6d5-cloud/epguk"
BRANCH="main"
COMMIT_MESSAGE="Auto-update EPG XML - $(date '+%Y-%m-%d %H:%M:%S')"
REFRESH_INTERVAL_MINUTES=30  # Refresh every 30 minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_git() {
    echo -e "${BLUE}[GIT]${NC} $1"
}

# Function to check if git is configured
check_git_config() {
    print_status "Checking Git configuration..."
    
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed!"
        exit 1
    fi
    
    # Check if repo URL is set
    if [ -z "$GITHUB_REPO_URL" ]; then
        print_warning "GitHub repository URL not configured!"
        echo "Please edit this script and set GITHUB_REPO_URL variable"
        echo "Example: GITHUB_REPO_URL='https://github.com/username/repo.git'"
        exit 1
    fi
    
    # Check if we're in a git repo or need to initialize
    if [ ! -d ".git" ]; then
        print_status "Initializing Git repository..."
        git init
        git remote add origin "$GITHUB_REPO_URL"
    fi
    
    # Check git user config
    if ! git config user.name &> /dev/null; then
        print_warning "Git user.name not configured. Setting default..."
        git config user.name "EPG Auto Updater"
    fi
    
    if ! git config user.email &> /dev/null; then
        print_warning "Git user.email not configured. Setting default..."
        git config user.email "epg-updater@example.com"
    fi
}

# Function to refresh XML
refresh_xml() {
    print_status "Refreshing XML data..."
    
    # Run the main refresh script
    if ./refresh_xml.sh; then
        print_status "XML refresh completed successfully"
        return 0
    else
        print_error "XML refresh failed"
        return 1
    fi
}

# Function to check if there are changes
check_changes() {
    print_status "Checking for changes..."
    
    if [ ! -f "$OUTPUT_FILE" ]; then
        print_warning "Output file does not exist"
        return 1
    fi
    
    # Check if git status shows changes
    if git status --porcelain | grep -q "$OUTPUT_FILE"; then
        print_status "Changes detected in output file"
        return 0
    else
        print_status "No changes detected"
        return 1
    fi
}

# Function to commit and push changes
commit_and_push() {
    print_status "Committing and pushing changes..."
    
    # Add the output file to git
    git add "$OUTPUT_FILE"
    
    # Commit with timestamp
    git commit -m "$COMMIT_MESSAGE"
    
    # Push to GitHub
    print_git "Pushing to GitHub..."
    if git push origin "$BRANCH"; then
        print_status "Successfully pushed to GitHub"
        return 0
    else
        print_error "Failed to push to GitHub"
        return 1
    fi
}

# Function to setup initial repository
setup_initial_repo() {
    print_status "Setting up initial repository..."
    
    # Add all files
    git add .
    
    # Initial commit
    git commit -m "Initial commit - EPG auto-refresh setup"
    
    # Push to GitHub
    git push -u origin "$BRANCH" || print_warning "Initial push failed - you may need to push manually"
}

# Function to run single refresh cycle
run_refresh_cycle() {
    print_status "Starting refresh cycle..."
    
    # Change to repo directory
    cd "$REPO_DIR"
    
    # Refresh XML
    if refresh_xml; then
        # Check if there are changes and push if needed
        if check_changes; then
            commit_and_push
        else
            print_status "No changes to push"
        fi
    else
        print_error "Refresh cycle failed"
        return 1
    fi
    
    print_status "Refresh cycle completed"
}

# Function to run continuous mode
run_continuous() {
    print_status "Starting continuous auto-refresh mode..."
    print_status "Refresh interval: $REFRESH_INTERVAL_MINUTES minutes"
    print_status "Press Ctrl+C to stop"
    
    while true; do
        run_refresh_cycle
        
        print_status "Waiting $REFRESH_INTERVAL_MINUTES minutes until next refresh..."
        sleep $((REFRESH_INTERVAL_MINUTES * 60))
    done
}

# Function to setup cron job
setup_cron() {
    print_status "Setting up cron job for automatic refresh..."
    
    # Create cron script
    cat > /tmp/epg_cron.sh << EOF
#!/bin/bash
cd "$REPO_DIR"
"$REPO_DIR/auto_refresh_and_push.sh" --single-run >> "$REPO_DIR/cron.log" 2>&1
EOF
    
    chmod +x /tmp/epg_cron.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "*/$REFRESH_INTERVAL_MINUTES * * * * /tmp/epg_cron.sh") | crontab -
    
    print_status "Cron job setup complete!"
    print_status "The script will run every $REFRESH_INTERVAL_MINUTES minutes"
    print_status "Logs will be saved to: $REPO_DIR/cron.log"
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -s, --single-run    Run single refresh cycle"
    echo "  -c, --continuous    Run continuous auto-refresh"
    echo "  --setup-cron        Setup cron job for automatic refresh"
    echo "  --init-repo         Initialize and push initial repository"
    echo ""
    echo "Before running:"
    echo "1. Edit this script and set GITHUB_REPO_URL"
    echo "2. Ensure you have Git access to the repository"
}

# Main execution
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--single-run)
            check_git_config
            run_refresh_cycle
            ;;
        -c|--continuous)
            check_git_config
            run_continuous
            ;;
        --setup-cron)
            check_git_config
            setup_cron
            ;;
        --init-repo)
            check_git_config
            setup_initial_repo
            ;;
        "")
            print_error "Please specify an option. Use --help for usage."
            exit 1
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
