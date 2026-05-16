#!/bin/bash
# Quickly fetch local and public IP addresses
# Domain: Network

echo "🌐 Fetching IP Addresses..."

# Local IP
if command -v ip &> /dev/null; then
    LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7}')
else
    LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [[ -z "$LOCAL_IP" ]]; then
        LOCAL_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -n 1)
    fi
fi

echo "🏠 Local IP (LAN):  $LOCAL_IP"

# Public IP
PUBLIC_IP=$(curl -s https://api.ipify.org || curl -s https://icanhazip.com)
echo "🌍 Public IP (WAN): $PUBLIC_IP"
