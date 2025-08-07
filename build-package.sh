#!/bin/bash
# poopDeck Package Builder
# Creates .mpackage file for Mudlet installation

set -e

echo "🚢 Building poopDeck Package"
echo "============================="

# Configuration
PACKAGE_NAME="poopDeck"
VERSION=$(cat VERSION)
OUTPUT_FILE="${PACKAGE_NAME}-v${VERSION}.mpackage"
BUILD_DIR="build"
TEMP_DIR="${BUILD_DIR}/temp"

echo "📦 Package Configuration:"
echo "   Name: $PACKAGE_NAME"
echo "   Version: $VERSION"
echo "   Output: $OUTPUT_FILE"
echo ""

# Clean and create build directory
echo "🧹 Cleaning build directory..."
rm -rf "$BUILD_DIR"
mkdir -p "$TEMP_DIR"

# Copy source files
echo "📁 Copying source files..."
cp -r src/ "$TEMP_DIR/"
cp mfile "$TEMP_DIR/"

# Copy documentation
echo "📚 Including documentation..."
mkdir -p "$TEMP_DIR/docs"
cp README.md "$TEMP_DIR/docs/"
cp INSTALLATION.md "$TEMP_DIR/docs/"
cp USER_GUIDE.md "$TEMP_DIR/docs/"
cp CONFIGURATION.md "$TEMP_DIR/docs/"
cp TROUBLESHOOTING.md "$TEMP_DIR/docs/"
cp CHANGELOG.md "$TEMP_DIR/docs/"
cp README_TESTING.md "$TEMP_DIR/docs/"

# Copy license if it exists
if [ -f "LICENSE" ]; then
    cp LICENSE "$TEMP_DIR/"
fi

# Validate critical files
echo "✅ Validating package structure..."

# Check mfile
if [ ! -f "$TEMP_DIR/mfile" ]; then
    echo "❌ Error: mfile not found"
    exit 1
fi

# Check source structure
REQUIRED_DIRS=(
    "src/scripts"
    "src/aliases" 
    "src/triggers"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$TEMP_DIR/$dir" ]; then
        echo "❌ Error: Required directory $dir not found"
        exit 1
    fi
done

# Check for critical files
CRITICAL_FILES=(
    "src/scripts/Utilities.lua"
    "src/scripts/Core/Initialize.lua"
    "src/scripts/Core/SessionManager.lua"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ ! -f "$TEMP_DIR/$file" ]; then
        echo "❌ Error: Critical file $file not found"
        exit 1
    fi
done

# Update version in mfile
echo "🔢 Updating version information..."
sed -i.bak "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$TEMP_DIR/mfile"
rm -f "$TEMP_DIR/mfile.bak"

# Validate JSON in mfile
echo "🔍 Validating mfile JSON..."
if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$TEMP_DIR/mfile" >/dev/null || {
        echo "❌ Error: Invalid JSON in mfile"
        exit 1
    }
    echo "✅ mfile JSON is valid"
fi

# Create package archive
echo "📦 Creating package archive..."
cd "$TEMP_DIR"
zip -r "../../$OUTPUT_FILE" . -x "*.DS_Store" "*/.*" || {
    echo "❌ Error: Failed to create package archive"
    exit 1
}
cd ../..

# Verify package was created
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "❌ Error: Package file was not created"
    exit 1
fi

# Package information
PACKAGE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
FILE_COUNT=$(unzip -l "$OUTPUT_FILE" | tail -1 | awk '{print $2}')

echo ""
echo "✅ Package created successfully!"
echo "📦 Package Details:"
echo "   File: $OUTPUT_FILE"
echo "   Size: $PACKAGE_SIZE"
echo "   Files: $FILE_COUNT"
echo ""

# Show package contents
echo "📋 Package Contents:"
unzip -l "$OUTPUT_FILE" | head -30

# Validation checks
echo ""
echo "🔍 Package Validation:"

# Check if package can be read
if unzip -t "$OUTPUT_FILE" >/dev/null 2>&1; then
    echo "✅ Package archive integrity: OK"
else
    echo "❌ Package archive integrity: FAILED"
    exit 1
fi

# Check for required Mudlet structure
if unzip -l "$OUTPUT_FILE" | grep -q "mfile"; then
    echo "✅ Mudlet package structure: OK"
else
    echo "❌ Mudlet package structure: MISSING mfile"
    exit 1
fi

# Installation instructions
echo ""
echo "🎯 Installation Instructions:"
echo "1. Open Mudlet"
echo "2. Go to Package Manager or drag-and-drop the .mpackage file"
echo "3. Select: $OUTPUT_FILE"
echo "4. Restart Mudlet after installation"
echo "5. Type 'poopsail' to verify installation"
echo ""

# Testing recommendation
echo "🧪 Testing Recommendation:"
echo "Before distribution, test the package by:"
echo "1. Installing in a clean Mudlet profile"
echo "2. Verifying all commands work"
echo "3. Testing core functionality"
echo ""

# Cleanup option
read -p "🧹 Remove build directory? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$BUILD_DIR"
    echo "✅ Build directory cleaned"
fi

echo ""
echo "🚢⚓🎣 poopDeck package ready for the high seas!"
echo "📦 Package: $OUTPUT_FILE"