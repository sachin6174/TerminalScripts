#!/bin/bash

# Script to change user password hint
# Usage: ./change_password_hint.sh -u username -h "new hint"

# Initialize variables
username=""
hint=""

# Function to display usage
usage() {
    echo "Usage: $0 -u <username> -h <hint>"
    echo "  -u  Username to change password hint for"
    echo "  -h  New password hint"
    echo ""
    echo "Example: $0 -u john -h \"Your favorite color\""
    exit 1
}

# Parse command line arguments
while getopts "u:h:" opt; do
    case $opt in
        u)
            username="$OPTARG"
            ;;
        h)
            hint="$OPTARG"
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

# Check if both username and hint are provided
if [ -z "$username" ] || [ -z "$hint" ]; then
    echo "Error: Both username (-u) and hint (-h) are required."
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
    echo "Please run with sudo: sudo $0 -u $username -h \"$hint\""
    exit 1
fi

echo "Changing password hint for user: $username"
echo "New hint: $hint"
echo ""

# Change the password hint using dscl
if dscl . create /Users/$username AuthenticationHint "$hint"; then
    echo "Success: Password hint changed for user '$username'"
    
    # Verify the change
    current_hint=$(dscl . read /Users/$username AuthenticationHint 2>/dev/null | cut -d':' -f2 | sed 's/^ *//')
    if [ "$current_hint" = "$hint" ]; then
        echo "Verification: Hint successfully updated"
    else
        echo "Warning: Hint may not have been updated correctly"
    fi
else
    echo "Error: Failed to change password hint for user '$username'"
    echo "Please check if you have the necessary permissions and the user exists."
    exit 1
fi