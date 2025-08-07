#!/bin/bash
# Comprehensive test runner with individual test file execution
# Useful for debugging specific test failures

echo "🧪 poopDeck Comprehensive Test Suite"
echo "====================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
TEST_FILES=()

# Function to run individual test file
run_test_file() {
    local test_file=$1
    local test_name=$2
    
    echo -e "${BLUE}📋 Running: $test_name${NC}"
    echo "   File: $test_file"
    
    if [ ! -f "$test_file" ]; then
        echo -e "   ${RED}❌ Test file not found${NC}"
        return 1
    fi
    
    # Run the test and capture output
    local output
    if output=$(busted "$test_file" --output=spec 2>&1); then
        echo -e "   ${GREEN}✅ PASSED${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "   ${RED}❌ FAILED${NC}"
        echo "   Error output:"
        echo "$output" | sed 's/^/      /'
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Check dependencies
echo "🔍 Checking Dependencies..."
if ! command -v busted &> /dev/null; then
    echo -e "${RED}❌ Busted not found. Please install it:${NC}"
    echo "   luarocks install busted"
    exit 1
fi

if ! command -v lua &> /dev/null; then
    echo -e "${RED}❌ Lua not found. Please install Lua.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies satisfied${NC}"
echo "   Lua: $(lua -v 2>&1 | head -1)"
echo "   Busted: $(busted --version 2>&1 | head -1)"
echo ""

# Define test files with descriptions
declare -A TEST_DESCRIPTIONS
TEST_DESCRIPTIONS[spec/spec_helper.lua]="Test Environment Setup"
TEST_DESCRIPTIONS[spec/seamonster_spec.lua]="Seamonster Auto-Fire Logic"
TEST_DESCRIPTIONS[spec/fishing_spec.lua]="Fishing System Core"
TEST_DESCRIPTIONS[spec/command_integration_spec.lua]="Command Integration"
TEST_DESCRIPTIONS[spec/auto_resume_spec.lua]="Auto-Resume Functionality"
TEST_DESCRIPTIONS[spec/configuration_persistence_spec.lua]="Configuration Persistence"
TEST_DESCRIPTIONS[spec/navigation_ship_management_spec.lua]="Navigation & Ship Management"
TEST_DESCRIPTIONS[spec/status_window_service_spec.lua]="Status Window Service"
TEST_DESCRIPTIONS[spec/notification_system_spec.lua]="Notification System"
TEST_DESCRIPTIONS[spec/prompt_spam_reduction_spec.lua]="Prompt Spam Reduction"
TEST_DESCRIPTIONS[spec/error_handling_service_spec.lua]="Error Handling Service"
TEST_DESCRIPTIONS[spec/core_architecture_spec.lua]="Core Architecture"
TEST_DESCRIPTIONS[spec/session_manager_integration_spec.lua]="Session Manager Integration"

# Run individual test files
echo "🚀 Running Individual Test Suites..."
echo "-------------------------------------"

# Skip spec_helper as it's not a test file
for test_file in spec/seamonster_spec.lua spec/fishing_spec.lua spec/command_integration_spec.lua spec/auto_resume_spec.lua spec/configuration_persistence_spec.lua spec/navigation_ship_management_spec.lua spec/status_window_service_spec.lua spec/notification_system_spec.lua spec/prompt_spam_reduction_spec.lua spec/error_handling_service_spec.lua spec/core_architecture_spec.lua spec/session_manager_integration_spec.lua; do
    if [ -f "$test_file" ]; then
        TEST_FILES+=("$test_file")
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        echo ""
        run_test_file "$test_file" "${TEST_DESCRIPTIONS[$test_file]}"
    else
        echo -e "${YELLOW}⚠️  Test file not found: $test_file${NC}"
    fi
done

echo ""
echo "============================================="
echo "🎯 Test Suite Summary"
echo "============================================="
echo "Total Test Files: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo "🚢⚓🎣 poopDeck is fully tested and ready for deployment!"
    echo ""
    echo "✅ Complete System Verification:"
    echo "   🐙 Seamonster auto-fire logic with weapon management"
    echo "   🎣 Fishing system with robust auto-resume functionality"
    echo "   ⚙️  Complete command integration and user interface"
    echo "   🔄 Auto-resume logic for fish escape scenarios"
    echo "   💾 Configuration persistence across sessions"
    echo "   🚢 Navigation and ship management operations"
    echo "   🪟 Status window display and management system"
    echo "   🔔 Notification system with seamonster spawn timers"
    echo "   📢 Prompt spam reduction and message throttling"
    echo "   🛡️  Comprehensive error handling and recovery"
    echo "   🏗️  Core architecture with BaseClass inheritance"
    echo "   🎭 Session manager coordinating all services"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}❌ $FAILED_TESTS TEST(S) FAILED${NC}"
    echo ""
    echo "🔧 Next Steps:"
    echo "   1. Review the error output above"
    echo "   2. Fix the failing tests"
    echo "   3. Run individual test files to debug:"
    for test_file in "${TEST_FILES[@]}"; do
        echo "      busted $test_file"
    done
    echo "   4. Re-run this script when ready"
    echo ""
    exit 1
fi