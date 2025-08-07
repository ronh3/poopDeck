#!/bin/bash
# Enhanced test runner for poopDeck tests
# Runs comprehensive test suite including new fishing and integration tests

echo "🧪 Running poopDeck Comprehensive Tests"
echo "========================================"

# Check if busted is installed
if ! command -v busted &> /dev/null; then
    echo "❌ Busted not found. Please install it:"
    echo "   luarocks install busted"
    echo "   Or install via your system package manager"
    exit 1
fi

# Display test environment info
echo "🔍 Test Environment:"
echo "   Lua Version: $(lua -v 2>&1 | head -1)"
echo "   Busted Version: $(busted --version 2>&1 | head -1)"
echo "   Working Directory: $(pwd)"
echo ""

# Run tests with detailed output and coverage
echo "📋 Complete Test Suite Overview:"
echo "   ├── 🐙 Seamonster Auto-Fire Logic"
echo "   ├── 🎣 Fishing System (Core functionality)"
echo "   ├── ⚙️  Command Integration (User interface)"
echo "   ├── 🔄 Auto-Resume Functionality (Primary user concern)"
echo "   ├── 💾 Configuration Persistence (Session data)"
echo "   ├── 🚢 Navigation & Ship Management"
echo "   ├── 🪟 Status Window Service"
echo "   ├── 🔔 Notification System (Seamonster timers)"
echo "   ├── 📢 Prompt Spam Reduction"
echo "   ├── 🛡️  Error Handling Service"
echo "   ├── 🏗️  Core Architecture (BaseClass, inheritance)"
echo "   └── 🎭 Session Manager Integration"
echo ""

echo "🚀 Running tests with Busted..."
echo "----------------------------------------"

# Run with verbose output and specification format
if busted --verbose --output=spec --coverage; then
    echo ""
    echo "✅ All tests passed successfully!"
    echo "🎉 Complete System Test Results:"
    echo "   🐙 Seamonster Auto-Fire: Combat ready"
    echo "   🎣 Fishing System: Auto-resume working"
    echo "   ⚙️  Command Integration: All commands verified"
    echo "   🔄 Auto-Resume Logic: Fish escape handling confirmed"
    echo "   💾 Configuration: Persistence working"
    echo "   🚢 Navigation: Ship management operational"
    echo "   🪟 Status Windows: Display system ready"
    echo "   🔔 Notifications: Seamonster timers functional"
    echo "   📢 Prompt Management: Spam reduction active"
    echo "   🛡️  Error Handling: Recovery systems online"
    echo "   🏗️  Core Architecture: BaseClass inheritance verified"
    echo "   🎭 Session Manager: All services integrated"
    echo ""
    echo "🚢⚓🎣 poopDeck is fully tested and ready for the high seas!"
else
    TEST_EXIT_CODE=$?
    echo ""
    echo "❌ Some tests failed!"
    echo "🔧 Test Failure Analysis:"
    echo "   Exit Code: $TEST_EXIT_CODE"
    echo "   Please review the test results above"
    echo ""
    echo "💡 Troubleshooting Tips:"
    echo "   • Check for missing dependencies"
    echo "   • Verify mock functions are properly initialized"
    echo "   • Ensure all test files are in spec/ directory"
    echo "   • Run individual test files to isolate issues:"
    echo "     busted spec/fishing_spec.lua"
    echo "     busted spec/auto_resume_spec.lua"
    echo "     busted spec/command_integration_spec.lua"
    echo ""
    exit $TEST_EXIT_CODE
fi