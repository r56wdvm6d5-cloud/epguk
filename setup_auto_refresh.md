# Auto Refresh and GitHub Push Setup

This guide shows you how to set up automatic XML refresh and GitHub push functionality.

## Quick Setup

### 1. Configure GitHub Repository

Edit the `auto_refresh_and_push.sh` script and set your GitHub repository URL:

```bash
# Line 9 - Change this to your GitHub repo
GITHUB_REPO_URL="https://github.com/YOUR_USERNAME/YOUR_REPO.git"
```

### 2. Initialize Git Repository

```bash
./auto_refresh_and_push.sh --init-repo
```

### 3. Choose Your Auto-Refresh Method

#### Option A: Single Run (Manual)
```bash
./auto_refresh_and_push.sh --single-run
```

#### Option B: Continuous Mode (Terminal)
```bash
./auto_refresh_and_push.sh --continuous
```

#### Option C: Cron Job (Background)
```bash
./auto_refresh_and_push.sh --setup-cron
```

## Configuration Options

### Edit the script to customize:

- **REFRESH_INTERVAL_MINUTES**: Set refresh frequency (default: 30 minutes)
- **BRANCH**: Target Git branch (default: main)
- **COMMIT_MESSAGE**: Customize commit messages

### Example Customization:
```bash
REFRESH_INTERVAL_MINUTES=15  # Refresh every 15 minutes
BRANCH="gh-pages"             # Push to gh-pages branch
```

## Methods Explained

### Method 1: Single Run
- Runs one refresh cycle
- Checks for changes
- Pushes to GitHub if updates found
- Good for manual testing

### Method 2: Continuous Mode
- Runs indefinitely in terminal
- Refreshes every 30 minutes (or custom interval)
- Shows real-time progress
- Stop with Ctrl+C

### Method 3: Cron Job
- Runs automatically in background
- No terminal needed
- Logs to `cron.log`
- Survives reboots
- Best for production

## Cron Job Management

### View current cron jobs:
```bash
crontab -l
```

### Remove cron job:
```bash
crontab -e
# Delete the line with epg_cron.sh
```

### View cron logs:
```bash
tail -f cron.log
```

## GitHub Setup Requirements

1. **Repository Access**: Ensure you have push access to the target repo
2. **Authentication**: Configure Git credentials or SSH keys
3. **Branch**: Target branch must exist (main, master, gh-pages, etc.)

### Git Authentication Setup

#### Option A: Personal Access Token
```bash
git config --global credential.helper store
git push origin main  # Enter username and token when prompted
```

#### Option B: SSH Key
```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
# Add SSH key to GitHub account
git remote set-url origin git@github.com:username/repo.git
```

## Monitoring

### Check script status:
```bash
# Check last commit
git log --oneline -1

# Check if script is running
ps aux | grep auto_refresh

# Check recent changes
git diff HEAD~1 HEAD output/dsmr_output.xml
```

### Logs location:
- **Continuous mode**: Terminal output
- **Cron mode**: `cron.log` file
- **Git history**: `git log`

## Troubleshooting

### Common Issues:

1. **"Git push failed"**
   - Check repository URL
   - Verify authentication
   - Ensure branch exists

2. **"No changes detected"**
   - XML data hasn't changed
   - Check if source URL updates

3. **"Cron job not running"**
   - Check cron service: `sudo systemctl status cron`
   - Verify cron syntax: `crontab -l`
   - Check permissions

### Debug Mode:
```bash
# Run with verbose output
bash -x ./auto_refresh_and_push.sh --single-run
```

## Security Notes

- Store Git credentials securely
- Use SSH keys for production
- Limit repository permissions
- Monitor cron logs regularly

## Automation Workflow

1. **Download** latest XML from URL
2. **Process** and convert to standard EPG format
3. **Compare** with previous version
4. **Commit** changes if different
5. **Push** to GitHub repository
6. **Repeat** based on interval

Your IPTV client will always have the latest EPG data from the GitHub URL!
