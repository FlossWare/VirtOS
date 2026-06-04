#!/bin/bash
# Build virtos-tools TCZ package
# This packages all VirtOS management scripts

set -e
set -u # Fail on unset variables

PACKAGE="virtos-tools"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Validate critical paths before destructive operations
if [ -z "$SCRIPT_DIR" ] || [ ! -d "$SCRIPT_DIR" ]; then
    echo "ERROR: SCRIPT_DIR not set correctly: '$SCRIPT_DIR'" >&2
    exit 1
fi

if [ -z "$PROJECT_ROOT" ] || [ ! -d "$PROJECT_ROOT" ]; then
    echo "ERROR: PROJECT_ROOT not set correctly: '$PROJECT_ROOT'" >&2
    exit 1
fi

# Validate we're in expected location
if [[ ! "$SCRIPT_DIR" =~ packages/virtos-tools$ ]]; then
    echo "ERROR: SCRIPT_DIR doesn't match expected pattern: $SCRIPT_DIR" >&2
    echo "Expected: */packages/virtos-tools" >&2
    exit 1
fi

# Read version from VERSION file
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    VERSION="$(cat "$PROJECT_ROOT/VERSION")"
    echo "Building $PACKAGE v$VERSION (from VERSION file)"
else
    VERSION="0.1"
    echo "Building $PACKAGE v$VERSION (fallback - VERSION file missing)"
fi

echo "=============================="
echo ""

# Clean previous build (validated paths)
echo "Cleaning previous build..."
rm -f "$SCRIPT_DIR/${PACKAGE}.tcz"
rm -f "$SCRIPT_DIR/${PACKAGE}.tcz.md5.txt"
rm -f "$SCRIPT_DIR/${PACKAGE}.tcz.list"

if [ -d "$SCRIPT_DIR/src" ]; then
    rm -rf "$SCRIPT_DIR/src"
else
    echo "  (no previous src/ to clean)"
fi

# Create directory structure
echo "Creating package structure..."
mkdir -p "$SCRIPT_DIR/src/usr/local/bin"
mkdir -p "$SCRIPT_DIR/src/usr/local/lib"
mkdir -p "$SCRIPT_DIR/src/usr/local/tce.installed"
mkdir -p "$SCRIPT_DIR/src/usr/local/share/doc/virtos"
mkdir -p "$SCRIPT_DIR/src/usr/local/share/virtos"

# Copy virtos scripts
echo "Copying VirtOS management scripts..."
SCRIPT_COUNT=0
for script in "$PROJECT_ROOT"/config/custom-scripts/virtos-*; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        cp "$script" "$SCRIPT_DIR/src/usr/local/bin/"
        SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
    fi
done
echo "  Copied $SCRIPT_COUNT scripts"

# Copy add-user utility if present
if [ -f "$PROJECT_ROOT/config/custom-scripts/add-user.sh" ]; then
    cp "$PROJECT_ROOT/config/custom-scripts/add-user.sh" "$SCRIPT_DIR/src/usr/local/bin/"
    echo "  Copied add-user.sh"
fi

# Copy common library
echo "Copying common library..."
if [ -d "$PROJECT_ROOT/config/custom-scripts/lib" ]; then
    cp -r "$PROJECT_ROOT/config/custom-scripts/lib"/* "$SCRIPT_DIR/src/usr/local/lib/" 2>/dev/null || true
    echo "  Copied library files"
fi

# Create build metadata files
echo "Creating build metadata..."
if [ -f "$PROJECT_ROOT/VERSION" ]; then
    cp "$PROJECT_ROOT/VERSION" "$SCRIPT_DIR/src/usr/local/share/virtos/VERSION"
    echo "  VERSION: $(cat "$PROJECT_ROOT/VERSION")"
else
    echo "$VERSION" >"$SCRIPT_DIR/src/usr/local/share/virtos/VERSION"
    echo "  VERSION: $VERSION (fallback)"
fi

date -u +"%Y-%m-%d %H:%M:%S UTC" >"$SCRIPT_DIR/src/usr/local/share/virtos/BUILD_DATE"
echo "  BUILD_DATE: $(cat "$SCRIPT_DIR/src/usr/local/share/virtos/BUILD_DATE")"

# Use pre-extracted git commit if available (from build-all.sh), otherwise extract it
if [ -n "${VIRTOS_GIT_COMMIT:-}" ]; then
    echo "$VIRTOS_GIT_COMMIT" >"$SCRIPT_DIR/src/usr/local/share/virtos/GIT_COMMIT"
    echo "  GIT_COMMIT: ${VIRTOS_GIT_COMMIT:0:7} (from build-all.sh)"
elif command -v git >/dev/null 2>&1 && [ -d "$PROJECT_ROOT/.git" ]; then
    cd "$PROJECT_ROOT"
    git rev-parse HEAD >"$SCRIPT_DIR/src/usr/local/share/virtos/GIT_COMMIT"
    echo "  GIT_COMMIT: $(cat "$SCRIPT_DIR/src/usr/local/share/virtos/GIT_COMMIT" | cut -c1-7)"
else
    echo "unknown" >"$SCRIPT_DIR/src/usr/local/share/virtos/GIT_COMMIT"
    echo "  GIT_COMMIT: unknown"
fi

# Create post-install script
echo "Creating post-install script..."
cat >"$SCRIPT_DIR/src/usr/local/tce.installed/$PACKAGE" <<'EOF'
#!/bin/sh
# Post-install script for virtos-tools

# Ensure all scripts are executable
chmod +x /usr/local/bin/virtos-* 2>/dev/null || true
chmod +x /usr/local/bin/add-user.sh 2>/dev/null || true

# Create config directory
mkdir -p /etc/virtos

# Show welcome message
cat << 'WELCOME'

╔══════════════════════════════════════════╗
║   VirtOS Management Tools Installed      ║
╠══════════════════════════════════════════╣
║  Run: virtos-tui                         ║
║       virtos-setup                       ║
║       virtos-cluster status              ║
╚══════════════════════════════════════════╝

WELCOME

# List available commands
echo "Available commands:"
ls -1 /usr/local/bin/virtos-* 2>/dev/null | sed 's|/usr/local/bin/||' | head -10
echo "  ... and more"
echo ""
echo "Documentation: /usr/local/share/doc/virtos/"
EOF

chmod +x "$SCRIPT_DIR/src/usr/local/tce.installed/$PACKAGE"

# Add documentation
echo "Adding documentation..."
cat >"$SCRIPT_DIR/src/usr/local/share/doc/virtos/README" <<'EOF'
VirtOS Management Tools
=======================

This package contains the complete set of VirtOS management utilities.

Quick Start
-----------

1. Run the setup wizard:
   sudo virtos-setup

2. Launch the TUI:
   virtos-tui

3. Check cluster status:
   virtos-cluster status

Management Tools
----------------

System Setup:
  virtos-setup        - Initial system configuration
  virtos-tui          - Text-based management interface

Virtualization:
  virtos-create-vm    - Create new virtual machines
  virtos-template     - VM template management
  virtos-snapshot     - VM snapshot management
  virtos-migrate      - Live VM migration

Clustering:
  virtos-cluster      - Cluster management
  virtos-ha           - High availability configuration

Backup & Recovery:
  virtos-backup       - Backup and restore VMs
  virtos-dr           - Disaster recovery management

Monitoring:
  virtos-monitor      - System monitoring
  virtos-telemetry    - Metrics collection

Security:
  virtos-auth         - Authentication management
  virtos-security     - Security hardening
  virtos-secrets      - Secrets management

Storage:
  virtos-storage      - Storage pool management

Networking:
  virtos-network      - Network configuration

And many more! Run any command with --help for usage information.

Documentation: https://github.com/FlossWare/VirtOS/tree/main/docs
EOF

# Check if we have mksquashfs (Tiny Core) or need to skip actual packaging
if command -v mksquashfs >/dev/null 2>&1; then
    echo "Creating TCZ package..."
    cd "$SCRIPT_DIR/src"
    mksquashfs . "../${PACKAGE}.tcz" -noappend -b 4096 -comp xz

    # Generate file list
    echo "Generating file list..."
    cd "$SCRIPT_DIR"
    unsquashfs -l "${PACKAGE}.tcz" 2>/dev/null | tail -n +4 | sed 's/^squashfs-root//' >"${PACKAGE}.tcz.list"

    # Generate checksum
    echo "Generating checksum..."
    md5sum "${PACKAGE}.tcz" >"${PACKAGE}.tcz.md5.txt"

    # Get size
    SIZE=$(du -h "${PACKAGE}.tcz" | cut -f1)

    echo ""
    echo "=============================="
    echo "✓ Package built successfully!"
    echo "=============================="
    echo "Package: ${PACKAGE}.tcz"
    echo "Size: $SIZE"
    echo "Scripts: $SCRIPT_COUNT"
    echo ""
    echo "Files:"
    echo "  ${PACKAGE}.tcz          - The package"
    echo "  ${PACKAGE}.tcz.md5.txt  - Checksum"
    echo "  ${PACKAGE}.tcz.list     - File listing"
    echo "  ${PACKAGE}.tcz.info     - Package info"
    echo "  ${PACKAGE}.tcz.dep      - Dependencies"
    echo ""
else
    echo ""
    echo "=============================="
    echo "⚠ Package structure created"
    echo "=============================="
    echo "Cannot create TCZ package (mksquashfs not found)"
    echo "This is normal when building on non-Tiny Core systems."
    echo ""
    echo "Package contents prepared in: src/"
    echo "Scripts: $SCRIPT_COUNT"
    echo ""
    echo "To build the actual TCZ:"
    echo "  1. Copy this directory to a Tiny Core system"
    echo "  2. Install: tce-load -wi squashfs-tools"
    echo "  3. Run: ./build.sh"
    echo ""
fi

echo "Package build complete!"
