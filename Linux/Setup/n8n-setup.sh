#!/bin/bash

set -e

echo "======================================"
echo "       n8n VPS Setup Script"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required dependencies
print_status "Installing required dependencies..."
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release ufw

# Install Node.js (LTS version)
print_status "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# Verify Node.js and npm installation
print_status "Verifying Node.js installation..."
node_version=$(node --version)
npm_version=$(npm --version)
print_status "Node.js version: $node_version"
print_status "npm version: $npm_version"

# Install n8n globally
print_status "Installing n8n..."
sudo npm install -g n8n

# Create n8n user
print_status "Creating n8n user..."
sudo useradd --system --create-home --shell /bin/bash n8n

# Create n8n directories
print_status "Creating n8n directories..."
sudo mkdir -p /home/n8n/.n8n
sudo chown -R n8n:n8n /home/n8n

# Create n8n configuration file
print_status "Creating n8n configuration..."
sudo tee /home/n8n/.n8n/config > /dev/null <<EOF
{
  "host": "0.0.0.0",
  "port": 5678,
  "protocol": "http"
}
EOF

sudo chown n8n:n8n /home/n8n/.n8n/config

# Create systemd service file
print_status "Creating systemd service file..."
sudo tee /etc/systemd/system/n8n.service > /dev/null <<EOF
[Unit]
Description=n8n workflow automation
After=network.target

[Service]
Type=simple
User=n8n
Group=n8n
ExecStart=/usr/bin/n8n start
WorkingDirectory=/home/n8n
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production
Environment=N8N_HOST=0.0.0.0
Environment=N8N_PORT=5678
Environment=N8N_PROTOCOL=http
Environment=WEBHOOK_URL=http://$(curl -s ifconfig.me):5678/
Restart=on-failure
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=n8n

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable n8n service
print_status "Enabling n8n service..."
sudo systemctl daemon-reload
sudo systemctl enable n8n
sudo systemctl start n8n

# Configure UFW firewall
print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 5678/tcp
print_status "Firewall configured to allow SSH and n8n (port 5678)"

# Wait for n8n to start
print_status "Waiting for n8n to start..."
sleep 10

# Check n8n service status
print_status "Checking n8n service status..."
if sudo systemctl is-active --quiet n8n; then
    print_status "n8n service is running successfully!"
else
    print_error "n8n service failed to start. Checking logs..."
    sudo journalctl -u n8n --no-pager --lines=20
    exit 1
fi

# Get server IP
SERVER_IP=$(curl -s ifconfig.me)

# Create SSL certificate directory (for future use)
print_status "Creating SSL certificate directory..."
sudo mkdir -p /etc/ssl/n8n
sudo chown -R n8n:n8n /etc/ssl/n8n

# Create backup script
print_status "Creating backup script..."
sudo tee /usr/local/bin/n8n-backup.sh > /dev/null <<EOF
#!/bin/bash
BACKUP_DIR="/home/n8n/backups"
DATE=\$(date +%Y%m%d_%H%M%S)

mkdir -p \$BACKUP_DIR

# Stop n8n service
systemctl stop n8n

# Backup n8n data
tar -czf \$BACKUP_DIR/n8n_backup_\$DATE.tar.gz -C /home/n8n .n8n

# Start n8n service
systemctl start n8n

echo "Backup completed: \$BACKUP_DIR/n8n_backup_\$DATE.tar.gz"

# Keep only last 7 backups
find \$BACKUP_DIR -name "n8n_backup_*.tar.gz" -type f -mtime +7 -delete
EOF

sudo chmod +x /usr/local/bin/n8n-backup.sh
sudo chown n8n:n8n /usr/local/bin/n8n-backup.sh

# Create daily backup cron job
print_status "Setting up daily backup cron job..."
echo "0 2 * * * /usr/local/bin/n8n-backup.sh" | sudo crontab -u n8n -

# Create update script
print_status "Creating update script..."
sudo tee /usr/local/bin/n8n-update.sh > /dev/null <<EOF
#!/bin/bash
echo "Stopping n8n service..."
systemctl stop n8n

echo "Updating n8n..."
npm install -g n8n@latest

echo "Starting n8n service..."
systemctl start n8n

echo "n8n updated successfully!"
systemctl status n8n
EOF

sudo chmod +x /usr/local/bin/n8n-update.sh

# Final status check
print_status "Final status check..."
sudo systemctl status n8n --no-pager

echo ""
echo "======================================"
echo "     n8n Installation Complete!"
echo "======================================"
echo ""
print_status "n8n has been successfully installed and configured!"
print_status "Access URL: http://$SERVER_IP:5678"
echo ""
print_status "Service management commands:"
echo "  Start n8n:   sudo systemctl start n8n"
echo "  Stop n8n:    sudo systemctl stop n8n"
echo "  Restart n8n: sudo systemctl restart n8n"
echo "  Status:      sudo systemctl status n8n"
echo "  Logs:        sudo journalctl -u n8n -f"
echo ""
print_status "Backup and maintenance:"
echo "  Manual backup: sudo /usr/local/bin/n8n-backup.sh"
echo "  Update n8n:    sudo /usr/local/bin/n8n-update.sh"
echo ""
print_warning "IMPORTANT SECURITY NOTES:"
echo "1. Set up SSL/TLS certificate for production use"
echo "2. Configure reverse proxy (nginx/apache) if needed"
echo "3. Set up proper authentication in n8n settings"
echo "4. Consider changing the default port"
echo "5. Set up database (PostgreSQL/MySQL) for production"
echo ""
print_status "Next steps:"
echo "1. Open http://$SERVER_IP:5678 in your browser"
echo "2. Complete the initial n8n setup"
echo "3. Configure your first workflow"
echo ""
print_status "Installation completed successfully!"