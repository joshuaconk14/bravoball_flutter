#!/bin/bash

# RevenueCat Test Runner Script
# This script helps you run the RevenueCat test applications

echo "🚀 RevenueCat Test Runner"
echo "========================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"
echo ""

# Function to run a test app
run_test_app() {
    local app_name=$1
    local file_path=$2
    
    echo "📱 Running $app_name..."
    echo "   File: $file_path"
    echo ""
    
    if [ ! -f "$file_path" ]; then
        echo "❌ File not found: $file_path"
        return 1
    fi
    
    echo "🔧 Getting dependencies..."
    flutter pub get
    
    echo "🏃 Running $app_name..."
    flutter run "$file_path"
}

# Main menu
echo "Select a test to run:"
echo "1. Basic RevenueCat Test (revenuecat_test_app.dart)"
echo "2. Apple Pay Focused Test (revenuecat_apple_pay_test.dart)"
echo "3. Exit"
echo ""

read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        run_test_app "Basic RevenueCat Test" "revenuecat_test_app.dart"
        ;;
    2)
        run_test_app "Apple Pay Test" "revenuecat_apple_pay_test.dart"
        ;;
    3)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac
