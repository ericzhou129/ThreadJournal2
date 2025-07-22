#!/bin/bash

# Script to run architecture tests for CI/CD pipelines
# This script will fail with non-zero exit code if architecture violations are found

set -e  # Exit on error

echo "🏗️  Running ThreadJournal2 Architecture Tests..."
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Find the project directory
PROJECT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$PROJECT_DIR"

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ xcodebuild not found. Please install Xcode.${NC}"
    exit 1
fi

# Run the architecture tests
echo "Running architecture compliance tests..."

# Build and test only the architecture tests
xcodebuild test \
    -project ThreadJournal2.xcodeproj \
    -scheme ThreadJournal2 \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -only-testing:ThreadJournal2Tests/ArchitectureCITests \
    -quiet \
    | grep -E "(Test Case|error:|warning:|failed|passed)" \
    || TEST_RESULT=$?

# Check the result
if [ ${TEST_RESULT:-0} -eq 0 ]; then
    echo -e "${GREEN}✅ All architecture tests passed!${NC}"
    echo "Clean Architecture boundaries are properly maintained."
    exit 0
else
    echo -e "${RED}❌ Architecture tests failed!${NC}"
    echo -e "${YELLOW}Please fix the violations before committing.${NC}"
    echo ""
    echo "Common violations:"
    echo "  • Domain layer importing UI frameworks"
    echo "  • Application layer importing persistence frameworks"
    echo "  • Use cases with multiple public methods"
    echo "  • Repository implementations outside Infrastructure layer"
    echo ""
    echo "Run tests locally with: ./run-architecture-tests.sh"
    exit 1
fi