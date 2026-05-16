#!/bin/bash

# Script to change user privileges between admin and standard
# Usage: ./set_user_type.sh -u username -t admin|standard

# Initialize variables
username=""
user_type=""

# Function to display usage
usage() {
    echo "Usage: $0 -u <username> -t <admin|standard>"
    echo "  -u  Username to change privileges for"
    echo "  -t  User type: 'admin' or 'standard'"
    echo ""
    echo "Examples:"
    echo "  $0 -u john -t admin"
    echo "  $0 -u john -t standard"
    exit 1
}

# Parse command line arguments
while getopts "u:t:" opt; do
    case $opt in
        u)
            username="$OPTARG"
            ;;
        t)
            user_type="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Check if both username and type are provided
if [ -z "$username" ] || [ -z "$user_type" ]; then
    echo "Error: Both username (-u) and type (-t) are required."
    usage
fi

# Validate user type
if [ "$user_type" != "admin" ] && [ "$user_type" != "standard" ]; then
    echo "Error: User type must be 'admin' or 'standard'."
    usage
fi

# Check if user exists
if ! dscl . read /Users/$username &>/dev/null; then
    echo "Error: User '$username' does not exist."
    exit 1
fi

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script requires administrator privileges."
    echo "Please run with sudo: sudo $0 -u $username -t $user_type"
    exit 1
fi

# Check current user type
if dscl . read /Groups/admin GroupMembership 2>/dev/null | grep -q "$username"; then
    current_type="admin"
else
    current_type="standard"
fi

echo "Current user type for '$username': $current_type"
echo "Requested user type: $user_type"
echo ""

# Check if change is needed
if [ "$current_type" = "$user_type" ]; then
    echo "No change needed: User '$username' is already a $user_type user."
    exit 0
fi

# Make the change
if [ "$user_type" = "admin" ]; then
    echo "Promoting '$username' to admin user..."
    if dseditgroup -o edit -a "$username" -t user admin; then
        echo "Success: '$username' is now an admin user."
    else
        echo "Error: Failed to promote '$username' to admin."
        exit 1
    fi
else
    echo "Demoting '$username' to standard user..."
    if dseditgroup -o edit -d "$username" -t user admin; then
        echo "Success: '$username' is now a standard user."
    else
        echo "Error: Failed to demote '$username' to standard user."
        exit 1
    fi
fi

# Verify the change
echo ""
echo "Verifying change..."
if dscl . read /Groups/admin GroupMembership 2>/dev/null | grep -q "$username"; then
    new_type="admin"
else
    new_type="standard"
fi

if [ "$new_type" = "$user_type" ]; then
    echo "Verification successful: '$username' is now a $new_type user."
else
    echo "Warning: Verification failed. User type may not have changed correctly."
    exit 1
fi