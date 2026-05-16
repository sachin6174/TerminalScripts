#!/bin/bash

# Script to change user privileges between admin and standard
# Usage: ./change_user_privileges.sh username

# Check if username is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <username>"
    echo "This script will toggle user privileges between admin and standard"
    echo ""
    echo "Example: $0 john"
    exit 1
fi

username="$1"

# Check if user exists
if ! dscl . read /Users/$username &>/dev/null; then
    echo "Error: User '$username' does not exist."
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script requires administrator privileges."
    echo "Please run with sudo: sudo $0 $username"
    exit 1
fi

# Check current user type
if dscl . read /Groups/admin GroupMembership 2>/dev/null | grep -q "$username"; then
    current_type="admin"
else
    current_type="standard"
fi

echo "Current user type for '$username': $current_type"
echo ""

# Ask for confirmation and new privilege level
echo "What would you like to change '$username' to?"
echo "1) Admin user"
echo "2) Standard user"
echo "3) Cancel"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        if [ "$current_type" = "admin" ]; then
            echo "User '$username' is already an admin user."
        else
            echo "Promoting '$username' to admin user..."
            if dseditgroup -o edit -a "$username" -t user admin; then
                echo "Success: '$username' is now an admin user."
            else
                echo "Error: Failed to promote '$username' to admin."
                exit 1
            fi
        fi
        ;;
    2)
        if [ "$current_type" = "standard" ]; then
            echo "User '$username' is already a standard user."
        else
            echo "Demoting '$username' to standard user..."
            if dseditgroup -o edit -d "$username" -t user admin; then
                echo "Success: '$username' is now a standard user."
            else
                echo "Error: Failed to demote '$username' to standard user."
                exit 1
            fi
        fi
        ;;
    3)
        echo "Operation cancelled."
        exit 0
        ;;
    *)
        echo "Invalid choice. Operation cancelled."
        exit 1
        ;;
esac

# Verify the change
echo ""
echo "Verifying change..."
if dscl . read /Groups/admin GroupMembership 2>/dev/null | grep -q "$username"; then
    new_type="admin"
else
    new_type="standard"
fi

echo "Current user type for '$username': $new_type"

# Show admin group members
echo ""
echo "Current admin users:"
dscl . read /Groups/admin GroupMembership 2>/dev/null | cut -d':' -f2 | tr ' ' '\n' | grep -v '^$' | sort