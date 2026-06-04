#!/bin/bash
# Build virtos-platform-java TCZ package
# Integrates platform-java with VirtOS for unified VM/container/app orchestration

set -e
set -u # Fail on unset variables

PACKAGE="virtos-platform-java"
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
if [[ ! "$SCRIPT_DIR" =~ packages/virtos-platform-java$ ]]; then
    echo "ERROR: SCRIPT_DIR doesn't match expected pattern: $SCRIPT_DIR" >&2
    echo "Expected: */packages/virtos-platform-java" >&2
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
mkdir -p "$SCRIPT_DIR/src/usr/local/lib/platform-java"
mkdir -p "$SCRIPT_DIR/src/usr/local/tce.installed"
mkdir -p "$SCRIPT_DIR/src/usr/local/share/doc/platform-java"
mkdir -p "$SCRIPT_DIR/src/etc/platform-java"
mkdir -p "$SCRIPT_DIR/src/var/lib/platform-java/apps"
mkdir -p "$SCRIPT_DIR/src/var/lib/platform-java/vms"
mkdir -p "$SCRIPT_DIR/src/var/lib/platform-java/volumes"

# Create platform-java wrapper script
echo "Creating platform-java wrapper scripts..."
cat >"$SCRIPT_DIR/src/usr/local/bin/platform-java" <<'EOF'
#!/bin/sh
# platform-java command-line interface for VirtOS
# Manages VMs, containers, Java apps, and native binaries

JPLATFORM_HOME="${JPLATFORM_HOME:-/usr/local/lib/platform-java}"
JPLATFORM_DATA="${JPLATFORM_DATA:-/var/lib/platform-java}"
JAVA_HOME="${JAVA_HOME:-/usr/local/java}"

# Check if Java is installed
if [ ! -d "$JAVA_HOME" ]; then
    echo "ERROR: Java not found. Install OpenJDK first."
    echo "  tce-load -wi openjdk-21-jre"
    exit 1
fi

# Check if platform-java is installed
if [ ! -f "$JPLATFORM_HOME/platform-java-launcher.jar" ]; then
    echo "ERROR: platform-java not installed. Run: virtos-platform-java-install"
    exit 1
fi

# Execute platform-java
exec "$JAVA_HOME/bin/java" \
    -Dplatform-java.home="$JPLATFORM_HOME" \
    -Dplatform-java.data="$JPLATFORM_DATA" \
    -jar "$JPLATFORM_HOME/platform-java-launcher.jar" \
    "$@"
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/platform-java"

# Create installation script
cat >"$SCRIPT_DIR/src/usr/local/bin/virtos-platform-java-install" <<'EOF'
#!/bin/sh
# Installs platform-java on VirtOS
# Downloads and configures platform-java with VM management support

set -e

JPLATFORM_VERSION="${JPLATFORM_VERSION:-1.1}"
JPLATFORM_HOME="/usr/local/lib/platform-java"
JPLATFORM_DATA="/var/lib/platform-java"
DOWNLOAD_URL="https://github.com/FlossWare/platform-java/releases/download/v${JPLATFORM_VERSION}"

echo "VirtOS platform-java Installation"
echo "============================="
echo "Version: $JPLATFORM_VERSION"
echo "Home: $JPLATFORM_HOME"
echo "Data: $JPLATFORM_DATA"
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Java
if ! command -v java >/dev/null 2>&1; then
    echo "  Installing OpenJDK 21..."
    tce-load -wi openjdk-21-jre
else
    echo "  Java: $(java -version 2>&1 | head -1)"
fi

# libvirt (for VM management)
if ! command -v virsh >/dev/null 2>&1; then
    echo "  Installing libvirt..."
    tce-load -wi libvirt
else
    echo "  libvirt: $(virsh --version)"
fi

# Docker/Podman (for container management)
if ! command -v docker >/dev/null 2>&1 && ! command -v podman >/dev/null 2>&1; then
    echo "  WARNING: Neither Docker nor Podman found. Container support will be limited."
    echo "  To enable container support, install: tce-load -wi docker"
fi

# Create directories
echo ""
echo "Creating directories..."
sudo mkdir -p "$JPLATFORM_HOME"
sudo mkdir -p "$JPLATFORM_DATA/apps"
sudo mkdir -p "$JPLATFORM_DATA/vms"
sudo mkdir -p "$JPLATFORM_DATA/volumes"
sudo mkdir -p "$JPLATFORM_DATA/logs"
sudo mkdir -p /etc/platform-java

# Download platform-java
echo ""
echo "Downloading platform-java..."
cd /tmp

# For now, use placeholder until actual release exists
# In production, this would download from GitHub releases
echo "  Note: Using local build (release not yet published)"
if [ -d "/home/tc/platform-java" ]; then
    echo "  Building from source..."
    cd /home/tc/platform-java
    mvn clean package -DskipTests
    sudo cp platform-java-launcher/target/platform-java-launcher-*.jar "$JPLATFORM_HOME/platform-java-launcher.jar"
else
    echo "  ERROR: platform-java source not found at /home/tc/platform-java"
    echo "  Please clone the repository first or download a release."
    exit 1
fi

# Create default configuration
echo ""
echo "Creating default configuration..."
sudo tee /etc/platform-java/config.yaml > /dev/null << 'YAML_EOF'
# platform-java Configuration for VirtOS

# Platform settings
platform:
  name: "virtos-platform-java"
  dataDirectory: "/var/lib/platform-java"

# VM management (libvirt)
vm:
  enabled: true
  libvirtUri: "qemu:///system"
  defaultVcpu: 2
  defaultMemoryMB: 4096
  diskDirectory: "/var/lib/platform-java/vms"

# Container management
container:
  enabled: true
  runtime: "auto"  # auto-detect: docker, podman, or lxc

# Resource limits
resources:
  defaultMaxHeapMB: 2048
  defaultMaxThreads: 100

# Monitoring
monitoring:
  enabled: true
  prometheusPort: 9090

# REST API
api:
  enabled: true
  port: 8080
  host: "0.0.0.0"
YAML_EOF

# Set permissions
echo ""
echo "Setting permissions..."
sudo chown -R root:staff "$JPLATFORM_HOME"
sudo chmod -R 755 "$JPLATFORM_HOME"
sudo chown -R root:staff "$JPLATFORM_DATA"
sudo chmod -R 775 "$JPLATFORM_DATA"

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  platform-java deploy <app.yaml>    # Deploy an application"
echo "  platform-java start <app-id>       # Start application/VM"
echo "  platform-java stop <app-id>        # Stop application/VM"
echo "  platform-java status               # List all applications"
echo "  platform-java help                 # Show full help"
echo ""
echo "Example VM deployment:"
echo "  cat > /tmp/my-vm.yaml << 'EXAMPLE'"
echo "  applicationId: my-vm"
echo "  name: My Virtual Machine"
echo "  properties:"
echo "    vm.vcpu: \"4\""
echo "    vm.memory: \"8192\""
echo "    vm.disk: \"/var/lib/platform-java/vms/my-vm.qcow2\""
echo "    vm.network: \"bridge\""
echo "  EXAMPLE"
echo "  platform-java deploy /tmp/my-vm.yaml"
echo ""
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/virtos-platform-java-install"

# Create uninstall script
cat >"$SCRIPT_DIR/src/usr/local/bin/virtos-platform-java-uninstall" <<'EOF'
#!/bin/sh
# Uninstalls platform-java from VirtOS

echo "Uninstalling platform-java..."

# Stop all running applications
if [ -x /usr/local/bin/platform-java ]; then
    echo "  Stopping all platform-java applications..."
    platform-java shutdown || true
fi

# Remove directories
echo "  Removing platform-java files..."
sudo rm -rf /usr/local/lib/platform-java
sudo rm -rf /etc/platform-java

echo ""
echo "platform-java uninstalled."
echo ""
echo "Note: Application data preserved at /var/lib/platform-java"
echo "      To remove data: sudo rm -rf /var/lib/platform-java"
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/virtos-platform-java-uninstall"

# Create status/info script
cat >"$SCRIPT_DIR/src/usr/local/bin/virtos-platform-java-info" <<'EOF'
#!/bin/sh
# Display platform-java status and configuration

JPLATFORM_HOME="/usr/local/lib/platform-java"
JPLATFORM_DATA="/var/lib/platform-java"

echo "VirtOS platform-java Status"
echo "======================="
echo ""

# Check installation
if [ ! -d "$JPLATFORM_HOME" ]; then
    echo "Status: NOT INSTALLED"
    echo ""
    echo "Run: virtos-platform-java-install"
    exit 0
fi

echo "Status: INSTALLED"
echo ""

# Version
if [ -f "$JPLATFORM_HOME/platform-java-launcher.jar" ]; then
    echo "JAR: $JPLATFORM_HOME/platform-java-launcher.jar"
fi

# Data directory
echo "Data: $JPLATFORM_DATA"
if [ -d "$JPLATFORM_DATA" ]; then
    echo "  Apps: $(find $JPLATFORM_DATA/apps -maxdepth 1 -type d 2>/dev/null | wc -l) deployed"
    echo "  VMs: $(find $JPLATFORM_DATA/vms -maxdepth 1 -name '*.qcow2' 2>/dev/null | wc -l) disk images"
    echo "  Volumes: $(find $JPLATFORM_DATA/volumes -maxdepth 1 -type d 2>/dev/null | wc -l) volumes"
fi

echo ""

# Prerequisites
echo "Prerequisites:"
echo "  Java: $(command -v java >/dev/null 2>&1 && java -version 2>&1 | head -1 || echo 'NOT FOUND')"
echo "  libvirt: $(command -v virsh >/dev/null 2>&1 && virsh --version || echo 'NOT FOUND')"
echo "  Container runtime:"
if command -v docker >/dev/null 2>&1; then
    echo "    Docker: $(docker --version)"
elif command -v podman >/dev/null 2>&1; then
    echo "    Podman: $(podman --version)"
else
    echo "    NONE (install docker or podman for container support)"
fi

echo ""

# Running applications
if [ -x /usr/local/bin/platform-java ] && platform-java status >/dev/null 2>&1; then
    echo "Running Applications:"
    platform-java status
fi
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/virtos-platform-java-info"

# Create post-install script
echo "Creating post-install script..."
cat >"$SCRIPT_DIR/src/usr/local/tce.installed/$PACKAGE" <<'EOF'
#!/bin/sh
# Post-install script for virtos-platform-java

echo "virtos-platform-java installed."
echo ""
echo "Next steps:"
echo "  1. Install platform-java: virtos-platform-java-install"
echo "  2. Check status: virtos-platform-java-info"
echo "  3. Deploy apps/VMs: platform-java deploy <descriptor.yaml>"
echo ""
echo "Documentation: /usr/local/share/doc/platform-java/"
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/tce.installed/$PACKAGE"

# Copy documentation
echo "Copying documentation..."
cat >"$SCRIPT_DIR/src/usr/local/share/doc/platform-java/README.md" <<'DOC_EOF'
# platform-java on VirtOS

platform-java provides unified orchestration for VMs, containers, Java applications,
and native binaries on VirtOS.

## Quick Start

1. Install platform-java:
   ```bash
   virtos-platform-java-install
   ```

2. Deploy a virtual machine:
   ```bash
   cat > my-vm.yaml << EOF
   applicationId: test-vm
   name: Test VM
   properties:
     vm.vcpu: "2"
     vm.memory: "4096"
     vm.disk: "/var/lib/platform-java/vms/test.qcow2"
     vm.network: "bridge"
   EOF

   platform-java deploy my-vm.yaml
   platform-java start test-vm
   ```

3. Deploy a container:
   ```bash
   cat > my-container.yaml << EOF
   applicationId: nginx
   name: NGINX Web Server
   properties:
     container.image: "nginx:alpine"
     container.runtime: "docker"
     container.ports: "80:80"
   EOF

   platform-java deploy my-container.yaml
   platform-java start nginx
   ```

## Commands

- `platform-java deploy <yaml>` - Deploy application/VM/container
- `platform-java start <id>` - Start workload
- `platform-java stop <id>` - Stop workload
- `platform-java status` - List all workloads
- `platform-java logs <id>` - View logs
- `platform-java metrics <id>` - View resource usage
- `virtos-platform-java-info` - Show installation status

## Documentation

Full documentation: https://github.com/FlossWare/platform-java
DOC_EOF

# Create build metadata
echo "Creating build metadata..."

# Use pre-extracted git commit if available (from build-all.sh)
if [ -n "${VIRTOS_GIT_COMMIT:-}" ]; then
    GIT_COMMIT="$VIRTOS_GIT_COMMIT"
elif command -v git >/dev/null 2>&1 && [ -d "$PROJECT_ROOT/.git" ]; then
    GIT_COMMIT="$(cd "$PROJECT_ROOT" && git rev-parse HEAD)"
else
    GIT_COMMIT="unknown"
fi
echo "  GIT_COMMIT: ${GIT_COMMIT:0:7}"

# Create package info
echo "Creating package metadata..."

# Read version from VERSION file (single source of truth)
if [ -f "$SCRIPT_DIR/../../VERSION" ]; then
    PACKAGE_VERSION=$(cat "$SCRIPT_DIR/../../VERSION")
else
    PACKAGE_VERSION="0.1-alpha"
    echo "Warning: VERSION file not found, using default version $PACKAGE_VERSION"
fi

cat >"$SCRIPT_DIR/${PACKAGE}.tcz.info" <<INFO_EOF
Title:          virtos-platform-java.tcz
Description:    platform-java integration for VirtOS - unified VM/container/app orchestration
Version:        ${PACKAGE_VERSION}
Author:         FlossWare
Original-site:  https://github.com/FlossWare/platform-java
Copying-policy: MIT
Size:           24K
Extension_by:   FlossWare
Tags:           virtualization orchestration java vm container
Comments:       Integrates platform-java with VirtOS for managing VMs, containers, Java apps
                and native binaries through a unified API. Requires Java and libvirt.
Change-log:     2026-05-25 Initial release
Current:        2026-05-25
INFO_EOF

# Create dependencies file
cat >"$SCRIPT_DIR/${PACKAGE}.tcz.dep" <<'EOF'
openjdk-21-jre.tcz
libvirt.tcz
EOF

# Create package
echo "Creating TCZ package..."
cd "$SCRIPT_DIR/src"
sudo find usr -not -type d | sudo tee "$SCRIPT_DIR/${PACKAGE}.tcz.list"
sudo find etc -not -type d | sudo tee -a "$SCRIPT_DIR/${PACKAGE}.tcz.list" 2>/dev/null || true
sudo find var -not -type d | sudo tee -a "$SCRIPT_DIR/${PACKAGE}.tcz.list" 2>/dev/null || true
sudo mksquashfs . "$SCRIPT_DIR/${PACKAGE}.tcz" -noappend -no-xattrs 2>/dev/null

# Generate MD5
echo "Generating MD5 checksum..."
cd "$SCRIPT_DIR"
md5sum "${PACKAGE}.tcz" >"${PACKAGE}.tcz.md5.txt"

echo ""
echo "Package built successfully!"
echo "  Package: $SCRIPT_DIR/${PACKAGE}.tcz"
echo "  Size: $(du -h ${PACKAGE}.tcz | cut -f1)"
echo "  Files: $(wc -l <${PACKAGE}.tcz.list)"
echo ""
echo "To install:"
echo "  sudo cp ${PACKAGE}.tcz* /mnt/sda1/tce/optional/"
echo "  echo ${PACKAGE}.tcz >> /mnt/sda1/tce/onboot.lst"
echo "  tce-load -i ${PACKAGE}"
