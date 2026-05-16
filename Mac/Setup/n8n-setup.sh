#!/bin/bash
#  sudo chown -R 501:20 "/Users/sachinkumar/.npm"

set -e

echo "======================================"
echo "       n8n macOS Setup Script"
echo "======================================"

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

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root. Please run as a regular user."
    exit 1
fi

# Check macOS version
print_status "Checking macOS version..."
macos_version=$(sw_vers -productVersion)
print_status "macOS version: $macos_version"

# Install Xcode Command Line Tools if not present
print_header "Installing Xcode Command Line Tools..."
if ! xcode-select -p &> /dev/null; then
    print_status "Installing Xcode Command Line Tools..."
    xcode-select --install
    print_warning "Please complete the Xcode Command Line Tools installation and run this script again."
    read -p "Press Enter when installation is complete..."
else
    print_status "Xcode Command Line Tools already installed"
fi

# Install Homebrew if not present
print_header "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    print_status "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    print_status "Homebrew already installed"
fi

# Fix Homebrew permissions if needed
print_status "Checking Homebrew permissions..."
if [[ $(uname -m) == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
else
    HOMEBREW_PREFIX="/usr/local"
fi

if ! brew --version &> /dev/null || ! test -w "$HOMEBREW_PREFIX"; then
    print_warning "Fixing Homebrew permissions..."
    sudo chown -R $(whoami) "$HOMEBREW_PREFIX"
    sudo chmod -R u+w "$HOMEBREW_PREFIX"
fi

# Update Homebrew
print_status "Updating Homebrew..."
brew update

# Install Node.js
print_header "Installing Node.js..."
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js via Homebrew..."
    brew install node
else
    print_status "Node.js already installed, updating..."
    brew upgrade node || true
fi

# Verify Node.js and npm installation
print_status "Verifying Node.js installation..."
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js version: $node_version"
print_status "npm version: $npm_version"

# Fix npm permissions if needed
print_status "Checking npm permissions..."
if [ -d "$HOME/.npm" ]; then
    print_warning "Fixing npm cache permissions..."
    sudo chown -R $(id -u):$(id -g) "$HOME/.npm"
fi

# Install n8n globally
print_header "Installing n8n..."
print_status "Installing n8n globally..."
npm install -g n8n

# Create n8n directories
print_header "Setting up n8n directories..."
N8N_HOME="$HOME/.n8n"
mkdir -p "$N8N_HOME"
mkdir -p "$N8N_HOME/logs"
mkdir -p "$N8N_HOME/backups"

# Create n8n configuration file
print_status "Creating n8n configuration..."
cat > "$N8N_HOME/config.json" <<EOF
{
  "host": "0.0.0.0",
  "port": 5678,
  "protocol": "http"
}
EOF

# Use localhost instead of local IP to avoid proxy/firewall issues
LOCAL_IP="localhost"

# Create environment file
print_status "Creating environment configuration..."
cat > "$N8N_HOME/.env" <<EOF
N8N_HOST=0.0.0.0
N8N_PORT=5678
N8N_PROTOCOL=http
WEBHOOK_URL=http://$LOCAL_IP:5678/
NODE_ENV=production
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=file
N8N_LOG_FILE_LOCATION=$N8N_HOME/logs/
EOF

# Create launchd plist for auto-start
print_header "Setting up auto-start service..."
PLIST_PATH="$HOME/Library/LaunchAgents/com.n8n.plist"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.n8n</string>
    <key>ProgramArguments</key>
    <array>
        <string>$(which node)</string>
        <string>$(which n8n)</string>
        <string>start</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$HOME</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
        <key>N8N_HOST</key>
        <string>0.0.0.0</string>
        <key>N8N_PORT</key>
        <string>5678</string>
        <key>N8N_PROTOCOL</key>
        <string>http</string>
        <key>WEBHOOK_URL</key>
        <string>http://$LOCAL_IP:5678/</string>
        <key>NODE_ENV</key>
        <string>production</string>
        <key>N8N_LOG_LEVEL</key>
        <string>info</string>
        <key>N8N_LOG_OUTPUT</key>
        <string>file</string>
        <key>N8N_LOG_FILE_LOCATION</key>
        <string>$N8N_HOME/logs/</string>
    </dict>
    <key>StandardOutPath</key>
    <string>$N8N_HOME/logs/n8n.log</string>
    <key>StandardErrorPath</key>
    <string>$N8N_HOME/logs/n8n.error.log</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# Load and start the service
print_status "Loading n8n service..."
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

# Wait for n8n to start
print_status "Waiting for n8n to start..."
sleep 10

# Check if n8n is running
if pgrep -f "n8n start" > /dev/null; then
    print_status "n8n service is running successfully!"
else
    print_error "n8n service failed to start. Checking logs..."
    tail -20 "$N8N_HOME/logs/n8n.error.log" 2>/dev/null || echo "No error logs found"
fi

# Create backup script
print_header "Creating backup and maintenance scripts..."
cat > "$N8N_HOME/backup.sh" <<EOF
#!/bin/bash
BACKUP_DIR="$N8N_HOME/backups"
DATE=\$(date +%Y%m%d_%H%M%S)

# Stop n8n service
launchctl unload "$PLIST_PATH"

# Backup n8n data
tar -czf "\$BACKUP_DIR/n8n_backup_\$DATE.tar.gz" -C "$HOME" .n8n

# Start n8n service
launchctl load "$PLIST_PATH"

echo "Backup completed: \$BACKUP_DIR/n8n_backup_\$DATE.tar.gz"

# Keep only last 7 backups
find "\$BACKUP_DIR" -name "n8n_backup_*.tar.gz" -type f -mtime +7 -delete
EOF

chmod +x "$N8N_HOME/backup.sh"

# Create update script
cat > "$N8N_HOME/update.sh" <<EOF
#!/bin/bash
echo "Stopping n8n service..."
launchctl unload "$PLIST_PATH"

echo "Updating n8n..."
npm install -g n8n@latest

echo "Starting n8n service..."
launchctl load "$PLIST_PATH"

echo "n8n updated successfully!"
sleep 5
if pgrep -f "n8n start" > /dev/null; then
    echo "n8n is running"
else
    echo "n8n failed to start"
fi
EOF

chmod +x "$N8N_HOME/update.sh"

# Create control script
cat > "$N8N_HOME/control.sh" <<EOF
#!/bin/bash

case \$1 in
    start)
        echo "Starting n8n..."
        launchctl load "$PLIST_PATH"
        ;;
    stop)
        echo "Stopping n8n..."
        launchctl unload "$PLIST_PATH"
        ;;
    restart)
        echo "Restarting n8n..."
        launchctl unload "$PLIST_PATH"
        sleep 2
        launchctl load "$PLIST_PATH"
        ;;
    status)
        if pgrep -f "n8n start" > /dev/null; then
            echo "n8n is running"
        else
            echo "n8n is not running"
        fi
        ;;
    logs)
        tail -f "$N8N_HOME/logs/n8n.log"
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
EOF

chmod +x "$N8N_HOME/control.sh"

# Set up daily backup using cron
print_status "Setting up daily backup cron job..."
(crontab -l 2>/dev/null; echo "0 2 * * * $N8N_HOME/backup.sh") | crontab -

# Create desktop shortcut
print_status "Creating desktop shortcut..."
cat > "$HOME/Desktop/n8n.command" <<EOF
#!/bin/bash
open http://localhost:5678
EOF

chmod +x "$HOME/Desktop/n8n.command"

# Configure macOS firewall (if enabled)
print_header "Configuring macOS firewall..."
if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
    print_status "macOS firewall is enabled, adding n8n rule..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add $(which node)
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp $(which node)
else
    print_status "macOS firewall is disabled"
fi

# Final status check
print_header "Final status check..."
sleep 5
if pgrep -f "n8n start" > /dev/null; then
    print_status "n8n is running successfully!"
else
    print_warning "n8n may not be running. Check logs: $N8N_HOME/logs/"
fi

echo ""
echo "======================================"
echo "     n8n Installation Complete!"
echo "======================================"
echo ""
print_status "n8n has been successfully installed and configured!"
print_status "Access URL: http://localhost:5678"
print_status "Desktop shortcut created: ~/Desktop/n8n.command"
echo ""
print_status "Service management commands:"
echo "  Control script: $N8N_HOME/control.sh {start|stop|restart|status|logs}"
echo "  Direct commands:"
echo "    Start:   launchctl load $PLIST_PATH"
echo "    Stop:    launchctl unload $PLIST_PATH"
echo "    Status:  pgrep -f 'n8n start'"
echo "    Logs:    tail -f $N8N_HOME/logs/n8n.log"
echo ""
print_status "Backup and maintenance:"
echo "  Manual backup: $N8N_HOME/backup.sh"
echo "  Update n8n:    $N8N_HOME/update.sh"
echo "  Daily backup:  Configured via cron at 2 AM"
echo ""
print_status "File locations:"
echo "  n8n data:      $N8N_HOME"
echo "  Configuration: $N8N_HOME/config.json"
echo "  Environment:   $N8N_HOME/.env"
echo "  Logs:          $N8N_HOME/logs/"
echo "  Backups:       $N8N_HOME/backups/"
echo "  Service:       $PLIST_PATH"
echo ""
print_warning "IMPORTANT SECURITY NOTES:"
echo "1. Set up SSL/TLS certificate for production use"
echo "2. Configure proper authentication in n8n settings"
echo "3. Consider changing the default port"
echo "4. Set up database (PostgreSQL/MySQL) for production"
echo "5. Configure network access restrictions if needed"
echo ""
print_status "Next steps:"
echo "1. Open http://localhost:5678 in your browser"
echo "2. Complete the initial n8n setup"
echo "3. Configure your first workflow"
echo ""
print_status "Installation completed successfully!"
print_status "Double-click n8n.command on Desktop to open n8n in browser"