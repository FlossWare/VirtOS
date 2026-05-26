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

            # Validate package was built
            TCZ_FILES=("$package"*.tcz)
            if [ ! -f "${TCZ_FILES[0]}" ]; then
                echo "❌ Build failed: No .tcz file created for $package"
                exit 1
            fi

            # Copy to output directory with validation
            echo "Copying package files to $OUTPUT_DIR..."
            COPIED_COUNT=0
            for file in "$package"*.tcz*; do
                if [ -f "$file" ]; then
                    if cp -v "$file" "$OUTPUT_DIR/"; then
                        COPIED_COUNT=$((COPIED_COUNT + 1))
                    else
                        echo "❌ Failed to copy $file"
                        exit 1
                    fi
                fi
            done

            if [ $COPIED_COUNT -eq 0 ]; then
                echo "❌ No files copied for $package"
                exit 1
            fi

            echo "✓ $package built successfully ($COPIED_COUNT files)"
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
