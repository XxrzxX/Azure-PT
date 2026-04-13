#!/bin/bash

# Generates an SSH key pair (Ed25519 by default) for the Azure Terraform Lab.

KEY_NAME="lab_ssh_key"
KEY_TYPE="rsa"
COMMENT="azure-terraform-lab"

# Build the full path for the key in the current directory
KEY_PATH="./$KEY_NAME"

# Check if the key already exists
if [ -f "$KEY_PATH" ]; then
    echo -e "\033[1;33mWarning: SSH Key '$KEY_NAME' already exists in this directory.\033[0m"
    read -p "Do you want to overwrite it? (y/N) " choice
    case "$choice" in 
      y|Y ) 
        echo "Removing existing keys..."
        rm -f "$KEY_PATH" "${KEY_PATH}.pub"
        ;;
      * ) 
        echo "Aborting key generation. Keeping existing keys."
        exit 0
        ;;
    esac
fi

echo -e "\033[1;36mGenerating $KEY_TYPE SSH internal key pair: $KEY_NAME...\033[0m"

# ssh-keygen command
# -N '' sets an empty passphrase.
ssh-keygen -t "$KEY_TYPE" -f "$KEY_PATH" -C "$COMMENT" -N ''

if [ $? -eq 0 ]; then
    echo -e "\n\033[1;32mSuccessfully generated SSH keys!\033[0m"
    echo -e "\033[1;30mPrivate Key: $(readlink -f $KEY_PATH)\033[0m"
    echo -e "\033[1;30mPublic Key:  $(readlink -f ${KEY_PATH}.pub)\033[0m"
    echo -e "\n\033[1;36mYou can now reference this in your main.tf using:\033[0m"
    echo "public_key = file(\"\${path.module}/$KEY_NAME.pub\")"
else
    echo -e "\033[1;31mFailed to generate SSH keys. Please ensure ssh-keygen is installed.\033[0m"
    exit 1
fi
