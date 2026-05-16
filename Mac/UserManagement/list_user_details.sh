#!/bin/bash

# Script to list all users with detailed information
# Compatible with macOS

echo "=== USER DETAILS REPORT ==="
echo "Generated on: $(date)"
echo "=========================================="
echo

# Get all users (excluding system users typically below UID 500)
for user in $(dscl . list /Users | grep -v '^_' | grep -v '^daemon' | grep -v '^nobody'); do
    echo "----------------------------------------"
    echo "USERNAME: $user"
    
    # Check if user exists in dscl
    if dscl . read /Users/$user &>/dev/null; then
        
        # Admin or Standard user
        if dscl . read /Groups/admin GroupMembership 2>/dev/null | grep -q "$user"; then
            echo "USER TYPE: Admin"
        else
            echo "USER TYPE: Standard"
        fi
        
        # Last password change date
        passwd_change=$(dscl . read /Users/$user passwordpolicyoptions 2>/dev/null | grep "passwordLastSetTime" | cut -d'=' -f2 | tr -d ' ')
        if [ ! -z "$passwd_change" ]; then
            # Convert from epoch time
            passwd_date=$(date -r "$passwd_change" 2>/dev/null || echo "Unknown")
            echo "LAST PASSWORD CHANGE: $passwd_date"
        else
            echo "LAST PASSWORD CHANGE: Unknown"
        fi
        
        # Last login time
        last_login=$(last -1 "$user" 2>/dev/null | head -1 | awk '{print $4, $5, $6, $7}')
        if [ ! -z "$last_login" ] && [ "$last_login" != "   " ]; then
            echo "LAST LOGIN: $last_login"
        else
            echo "LAST LOGIN: Never or Unknown"
        fi
        
        # Last logout time (from last command)
        last_logout=$(last "$user" 2>/dev/null | head -1 | awk '{if ($9 != "") print $8, $9; else print "Still logged in"}')
        if [ ! -z "$last_logout" ] && [ "$last_logout" != " " ]; then
            echo "LAST LOGOUT: $last_logout"
        else
            echo "LAST LOGOUT: Unknown"
        fi
        
        # Password hint change (not easily accessible on macOS, requires admin privileges)
        echo "LAST PASSWORD HINT CHANGE: Not available without admin privileges"
        
        # Secure token status
        secure_token=$(sysadminctl -secureTokenStatus "$user" 2>/dev/null | grep "Secure token" | awk '{print $NF}')
        if [ ! -z "$secure_token" ]; then
            echo "SECURE TOKEN STATUS: $secure_token"
        else
            echo "SECURE TOKEN STATUS: Unknown (requires admin privileges)"
        fi
        
        # User creation date
        creation_date=$(dscl . read /Users/$user CreationDate 2>/dev/null | cut -d' ' -f2-)
        if [ ! -z "$creation_date" ]; then
            echo "USER CREATION DATE: $creation_date"
        else
            # Try alternative method using account creation
            uid=$(dscl . read /Users/$user UniqueID 2>/dev/null | awk '{print $2}')
            if [ ! -z "$uid" ]; then
                echo "USER CREATION DATE: Unable to determine exactly"
            else
                echo "USER CREATION DATE: Unknown"
            fi
        fi
        
    else
        echo "ERROR: Unable to read user information"
    fi
    
    echo "----------------------------------------"
    echo
done

echo "=== END OF REPORT ==="
echo
echo "Note: Some information may require administrator privileges to access."
echo "Run with 'sudo' for more complete information where applicable."