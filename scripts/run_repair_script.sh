#!/bin/bash

# User Data Repair Script Runner
# This script runs the Dart repair script with proper Flutter environment

echo "🔧 User Data Repair Script Runner"
echo "================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the Flutter project root directory"
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Error: Firebase CLI is not installed"
    echo "   Install it with: npm install -g firebase-tools"
    exit 1
fi

echo "✅ Environment checks passed"

# Create scripts directory if it doesn't exist
mkdir -p scripts

# Run the repair script
echo "🚀 Running user data repair script..."
echo "   Make sure you're logged into Firebase CLI: firebase login"
echo ""

# Run the script using dart directly
dart run scripts/repair_user_data.dart

echo ""
echo "🎉 Script execution completed!"
echo "   Check the output above for any errors or success messages."
