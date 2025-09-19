#!/bin/bash

# Setup script for Android release keystore environment variables
# Run this script with: source setup-keystore-env.sh

# Prompt for keystore information
read -p "Enter your keystore file path: " store_file
read -s -p "Enter your keystore password: " store_password
read -p "Enter your key alias: " key_alias
read -s -p "Enter your key password: " key_password

# Set environment variables
export STORE_FILE="$store_file"
export STORE_PASSWORD="$store_password"
export KEY_ALIAS="$key_alias"
export KEY_PASSWORD="$key_password"
