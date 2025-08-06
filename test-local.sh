#!/bin/bash
# Local test runner for poopDeck tests without requiring Mudlet
# This provides a fallback testing approach when the GitHub action fails

echo "🧪 Running poopDeck Tests Locally"
echo "=================================="

# Check if busted is installed
if ! command -v busted &> /dev/null; then
    echo "❌ Busted not found. Please install it:"
    echo "   luarocks install busted"
    exit 1
fi

# Run tests with verbose output
echo "Running tests with Busted..."
busted --verbose --output=spec

# Check test results
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed!"
    echo "🚢 poopDeck seamonster logic is ready for combat!"
else
    echo ""
    echo "❌ Some tests failed!"
    echo "🔧 Please review the test results above"
    exit 1
fi