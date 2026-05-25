#!/bin/bash
# Build all VirtOS packages

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "VirtOS Package Builder"
echo "======================"
echo

# List of packages to build (in dependency order)
PACKAGES=(
    # Core VirtOS management tools
    "virtos-tools"

    # JPlatform integration
    "virtos-jplatform"

    # Future packages:
    # "qemu-kvm"
    # "libvirt"
    # "docker"
    # "lxc"
)

# Build each package
for package in "${PACKAGES[@]}"; do
    if [ -d "$SCRIPT_DIR/$package" ]; then
        echo "Building $package..."
        cd "$SCRIPT_DIR/$package"

        if [ -x "./build.sh" ]; then
            ./build.sh

            # Copy to output directory
            cp -v *.tcz* "$OUTPUT_DIR/" 2>/dev/null || true

            echo "✓ $package built successfully"
        else
            echo "⚠ No build.sh found for $package (skipping)"
        fi

        cd "$SCRIPT_DIR"
        echo
    else
        echo "⚠ Package directory not found: $package (skipping)"
        echo
    fi
done

echo "======================"
echo "Build complete!"
echo "Packages in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
