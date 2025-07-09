#!/bin/bash
# Script to fix Flash Attention GLIBC compatibility issues

echo "Flash Attention GLIBC Compatibility Fixer"
echo "========================================="

# Check current GLIBC version
echo "Checking current GLIBC version..."
GLIBC_VERSION=$(ldd --version | head -n1 | grep -oE '[0-9]+\.[0-9]+')
echo "Current GLIBC version: $GLIBC_VERSION"

# Compare with required version (2.32)
if [ "$(printf '%s\n' "2.32" "$GLIBC_VERSION" | sort -V | head -n1)" = "2.32" ]; then
    echo "✅ GLIBC version is compatible (>= 2.32)"
    echo "The issue might be with the specific Flash Attention wheel."
else
    echo "⚠️  GLIBC version is older than 2.32"
    echo "Flash Attention wheels require GLIBC 2.32 or newer."
fi

echo ""
echo "Solutions:"
echo "1. Uninstall current Flash Attention and install from source (recommended)"
echo "2. Try a different Flash Attention wheel"
echo "3. Use an older version of Flash Attention"

read -p "Do you want to fix Flash Attention by installing from source? (y/n): " choice

if [[ $choice == "y" || $choice == "Y" ]]; then
    echo "Uninstalling current Flash Attention..."
    pip uninstall flash-attn -y
    
    echo "Installing Flash Attention from source..."
    echo "This may take 10-30 minutes depending on your system..."
    
    # Install from source with no isolation to avoid build issues
    MAX_JOBS=4 pip install flash-attn --no-build-isolation
    
    if [ $? -eq 0 ]; then
        echo "✅ Flash Attention installed successfully from source!"
    else
        echo "❌ Installation from source failed."
        echo "You may need to install additional build dependencies:"
        echo "  - CUDA development toolkit"
        echo "  - ninja-build"
        echo "  - pytorch with CUDA support"
    fi
else
    echo "Installation cancelled."
    echo ""
    echo "Alternative solutions:"
    echo "1. Try installing an older version:"
    echo "   pip install flash-attn==2.5.0 --no-build-isolation"
    echo ""
    echo "2. Check available wheels at:"
    echo "   https://github.com/Dao-AILab/flash-attention/releases"
    echo ""
    echo "3. Install dependencies for building from source:"
    echo "   pip install ninja packaging wheel"
fi
