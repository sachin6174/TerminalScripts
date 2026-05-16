#!/bin/bash

# Variables
while getopts u:p:h: flag
do
    case "${flag}" in
        u) USERNAME=${OPTARG};;
        p) PASSWORD=${OPTARG};;
        h) PASSWORD_HINT=${OPTARG};;
    esac
done

# Create the user
sudo sysadminctl -addUser $USERNAME -fullName "New User" -password $PASSWORD

# Set the password hint
sudo dscl . -create /Users/$USERNAME hint "$PASSWORD_HINT"

# Enable SecureToken for the new user
sudo sysadminctl -secureTokenOn $USERNAME -password $PASSWORD

echo "User $USERNAME created with SecureToken enabled and password hint set."
