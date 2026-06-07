#!/bin/bash
# Download TCZ packages from Tiny Core repository
# These will be bundled into the ISO for offline installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
TCZ_DIR="$BUILD_DIR/workspace/tcz"

# Tiny Core 15.x repository
TC_MIRROR="http://tinycorelinux.net/15.x/x86_64/tcz"

echo "=== Downloading TCZ Packages ==="
echo "Repository: $TC_MIRROR"
echo "Destination: $TCZ_DIR"
echo ""

mkdir -p "$TCZ_DIR"

# Core packages that definitely exist in TC repo
CORE_PACKAGES=(
    "bash.tcz"
    "openssh.tcz"
    "vim.tcz"
    "bridge-utils.tcz"
    "iptables.tcz"
    "iproute2.tcz"
    "htop.tcz"
    "dialog.tcz"
)

# Track downloaded packages to avoid duplicates
declare -A DOWNLOADED_PACKAGES

# Download function with recursive dependency resolution
download_tcz() {
    local pkg="$1"
    local depth="${2:-0}"
    local indent=""

    # Create indent for nested dependencies
    for ((i=0; i<depth; i++)); do
        indent="  $indent"
    done

    # Skip if already downloaded
    if [ -n "${DOWNLOADED_PACKAGES[$pkg]}" ]; then
        echo "${indent}⏭️  $pkg (already downloaded)"
        return 0
    fi

    local url="$TC_MIRROR/$pkg"

    echo "${indent}Downloading $pkg..."
    if wget -q "$url" -O "$TCZ_DIR/$pkg" 2>/dev/null; then
        DOWNLOADED_PACKAGES[$pkg]=1
        echo "${indent}  ✅ $pkg ($(du -h "$TCZ_DIR/$pkg" | cut -f1))"

        # Download .md5.txt for verification
        if wget -q "$TC_MIRROR/${pkg}.md5.txt" -O "$TCZ_DIR/${pkg}.md5.txt" 2>/dev/null; then
            # Verify checksum
            if (cd "$TCZ_DIR" && md5sum -c "${pkg}.md5.txt" >/dev/null 2>&1); then
                echo "${indent}  🔒 Checksum verified"
            fi
        fi

        # Download and process .dep file (dependency list)
        local dep_file="$TCZ_DIR/${pkg}.dep"
        if wget -q "$TC_MIRROR/${pkg}.dep" -O "$dep_file" 2>/dev/null; then
            # Count dependencies
            local dep_count=$(grep -c "^[^#]" "$dep_file" 2>/dev/null || echo 0)
            if [ "$dep_count" -gt 0 ]; then
                echo "${indent}  📦 $dep_count dependencies found"

                # Recursively download each dependency
                while IFS= read -r dep_pkg; do
                    # Skip empty lines and comments
                    [ -z "$dep_pkg" ] && continue
                    case "$dep_pkg" in \#*) continue ;; esac

                    # Recursively download dependency
                    download_tcz "$dep_pkg" $((depth + 1))
                done < "$dep_file"
            fi
        fi

        return 0
    else
        echo "${indent}  ⚠️  $pkg not available in repository"
        return 1
    fi
}

# Download core packages
echo "Core packages:"
for pkg in "${CORE_PACKAGES[@]}"; do
    download_tcz "$pkg" || true
done

echo ""
echo "Note: QEMU and libvirt are complex packages that may need to be"
echo "      compiled from source or obtained from a different repository."
echo ""

# Count what we got
DOWNLOADED=$(ls -1 "$TCZ_DIR"/*.tcz 2>/dev/null | wc -l)
TOTAL_SIZE=$(du -sh "$TCZ_DIR" 2>/dev/null | cut -f1)

echo ""
echo "=== Download Complete ==="
echo "Downloaded: $DOWNLOADED packages (including dependencies)"
echo "Total size: $TOTAL_SIZE"
echo "Location: $TCZ_DIR"
echo ""
echo "Package list:"
ls -1h "$TCZ_DIR"/*.tcz 2>/dev/null | xargs -n1 basename | sort | sed 's/^/  - /'
echo ""
echo "To bundle into ISO, run: bash scripts/customize.sh"
