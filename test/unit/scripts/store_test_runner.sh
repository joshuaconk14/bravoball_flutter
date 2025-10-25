#!/bin/bash

# BravoBall Flutter Test Runner
# This script runs comprehensive tests for the premium/store implementation

echo "🧪 Starting BravoBall Test Suite..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to run tests with nice output
run_test_suite() {
    local test_name="$1"
    local test_path="$2"
    
    echo -e "\n${BLUE}Running $test_name...${NC}"
    echo "----------------------------------------"
    
    if flutter test "$test_path" --reporter=expanded; then
        echo -e "${GREEN}✅ $test_name PASSED${NC}"
        return 0
    else
        echo -e "${RED}❌ $test_name FAILED${NC}"
        return 1
    fi
}

# Function to generate mocks
generate_mocks() {
    echo -e "\n${YELLOW}Generating mocks...${NC}"
    flutter packages pub run build_runner build --delete-conflicting-outputs
}

# Function to run all tests
run_all_tests() {
    local failed_tests=0
    
    echo -e "\n${BLUE}🧪 Running All Tests${NC}"
    echo "========================"
    
    # Generate mocks first
    generate_mocks
    
    # Unit Tests
    run_test_suite "StoreService Unit Tests" "test/services/store_service_test.dart" || ((failed_tests++))
    
    # Widget Tests
    run_test_suite "StorePage Widget Tests" "test/features/store_page_test.dart" || ((failed_tests++))
    run_test_suite "Streak Dialog Tests" "test/widgets/streak_dialogs_test.dart" || ((failed_tests++))
    
    # Integration Tests (if they exist)
    if [ -f "test/integration/premium_purchase_test.dart" ]; then
        run_test_suite "Premium Purchase Integration Tests" "test/integration/premium_purchase_test.dart" || ((failed_tests++))
    fi
    
    # Calendar Tests (if they exist)
    if [ -f "test/features/calendar_display_test.dart" ]; then
        run_test_suite "Calendar Display Tests" "test/features/calendar_display_test.dart" || ((failed_tests++))
    fi
    
    # Summary
    echo -e "\n${BLUE}Test Summary${NC}"
    echo "============"
    
    if [ $failed_tests -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        echo -e "${GREEN}Your premium/store implementation is working correctly.${NC}"
    else
        echo -e "${RED}❌ $failed_tests test suite(s) failed${NC}"
        echo -e "${YELLOW}Please review the failed tests above and fix the issues.${NC}"
    fi
    
    return $failed_tests
}

# Function to run specific test categories
run_unit_tests() {
    echo -e "\n${BLUE}🔬 Running Unit Tests${NC}"
    echo "====================="
    generate_mocks
    run_test_suite "StoreService Unit Tests" "test/services/store_service_test.dart"
}

run_widget_tests() {
    echo -e "\n${BLUE}🎨 Running Widget Tests${NC}"
    echo "======================="
    generate_mocks
    run_test_suite "StorePage Widget Tests" "test/features/store_page_test.dart"
    run_test_suite "Streak Dialog Tests" "test/widgets/streak_dialogs_test.dart"
}

run_integration_tests() {
    echo -e "\n${BLUE}🔗 Running Integration Tests${NC}"
    echo "============================="
    generate_mocks
    if [ -f "test/integration/premium_purchase_test.dart" ]; then
        run_test_suite "Premium Purchase Integration Tests" "test/integration/premium_purchase_test.dart"
    else
        echo -e "${YELLOW}⚠️  Integration tests not found${NC}"
    fi
}

# Function to run tests with coverage
run_with_coverage() {
    echo -e "\n${BLUE}📊 Running Tests with Coverage${NC}"
    echo "==============================="
    
    generate_mocks
    
    # Run tests with coverage
    flutter test --coverage
    
    # Generate coverage report
    if command -v genhtml &> /dev/null; then
        genhtml coverage/lcov.info -o coverage/html
        echo -e "${GREEN}📈 Coverage report generated in coverage/html/index.html${NC}"
    else
        echo -e "${YELLOW}⚠️  genhtml not found. Install lcov to generate HTML coverage reports.${NC}"
    fi
}

# Function to run tests in watch mode
run_watch_mode() {
    echo -e "\n${BLUE}👀 Running Tests in Watch Mode${NC}"
    echo "================================"
    echo -e "${YELLOW}Tests will re-run automatically when files change.${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop.${NC}"
    
    generate_mocks
    flutter test --watch
}

# Function to show help
show_help() {
    echo -e "${BLUE}BravoBall Test Runner${NC}"
    echo "==================="
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  all          Run all tests (default)"
    echo "  unit         Run unit tests only"
    echo "  widget       Run widget tests only"
    echo "  integration  Run integration tests only"
    echo "  coverage     Run tests with coverage report"
    echo "  watch        Run tests in watch mode"
    echo "  mocks        Generate mocks only"
    echo "  help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Run all tests"
    echo "  $0 unit              # Run unit tests only"
    echo "  $0 coverage          # Run with coverage"
    echo "  $0 watch             # Run in watch mode"
}

# Main script logic
case "${1:-all}" in
    "all")
        run_all_tests
        ;;
    "unit")
        run_unit_tests
        ;;
    "widget")
        run_widget_tests
        ;;
    "integration")
        run_integration_tests
        ;;
    "coverage")
        run_with_coverage
        ;;
    "watch")
        run_watch_mode
        ;;
    "mocks")
        generate_mocks
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
