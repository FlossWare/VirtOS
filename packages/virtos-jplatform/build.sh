#!/bin/bash
# Build virtos-jplatform TCZ package
# Integrates JPlatform with VirtOS for unified VM/container/app orchestration

set -e

PACKAGE="virtos-jplatform"
VERSION="0.1-alpha"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Building $PACKAGE v$VERSION"
echo "=============================="
echo ""

# Clean previous build
echo "Cleaning previous build..."
rm -f "$SCRIPT_DIR/${PACKAGE}.tcz"
rm -f "$SCRIPT_DIR/${PACKAGE}.tcz.md5.txt"
rm -f "$SCRIPT_DIR/${PACKAGE}.tcz.list"
rm -rf "$SCRIPT_DIR/src"

# Create directory structure
echo "Creating package structure..."
mkdir -p "$SCRIPT_DIR/src/usr/local/bin"
mkdir -p "$SCRIPT_DIR/src/usr/local/lib/jplatform"
mkdir -p "$SCRIPT_DIR/src/usr/local/tce.installed"
mkdir -p "$SCRIPT_DIR/src/usr/local/share/doc/jplatform"
mkdir -p "$SCRIPT_DIR/src/etc/jplatform"
mkdir -p "$SCRIPT_DIR/src/var/lib/jplatform/apps"
mkdir -p "$SCRIPT_DIR/src/var/lib/jplatform/vms"
mkdir -p "$SCRIPT_DIR/src/var/lib/jplatform/volumes"

# Create JPlatform wrapper script
echo "Creating JPlatform wrapper scripts..."
cat > "$SCRIPT_DIR/src/usr/local/bin/jplatform" << 'EOF'
#!/bin/sh
# JPlatform command-line interface for VirtOS
# Manages VMs, containers, Java apps, and native binaries

JPLATFORM_HOME="${JPLATFORM_HOME:-/usr/local/lib/jplatform}"
JPLATFORM_DATA="${JPLATFORM_DATA:-/var/lib/jplatform}"
JAVA_HOME="${JAVA_HOME:-/usr/local/java}"

# Check if Java is installed
if [ ! -d "$JAVA_HOME" ]; then
    echo "ERROR: Java not found. Install OpenJDK first."
    echo "  tce-load -wi openjdk-21-jre"
    exit 1
fi

# Check if JPlatform is installed
if [ ! -f "$JPLATFORM_HOME/jplatform-launcher.jar" ]; then
    echo "ERROR: JPlatform not installed. Run: virtos-jplatform-install"
    exit 1
fi

# Execute JPlatform
exec "$JAVA_HOME/bin/java" \
    -Djplatform.home="$JPLATFORM_HOME" \
    -Djplatform.data="$JPLATFORM_DATA" \
    -jar "$JPLATFORM_HOME/jplatform-launcher.jar" \
    "$@"
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/jplatform"

# Create installation script
cat > "$SCRIPT_DIR/src/usr/local/bin/virtos-jplatform-install" << 'EOF'
#!/bin/sh
# Installs JPlatform on VirtOS
# Downloads and configures JPlatform with VM management support

set -e

JPLATFORM_VERSION="${JPLATFORM_VERSION:-1.1}"
JPLATFORM_HOME="/usr/local/lib/jplatform"
JPLATFORM_DATA="/var/lib/jplatform"
DOWNLOAD_URL="https://github.com/FlossWare/jplatform/releases/download/v${JPLATFORM_VERSION}"

echo "VirtOS JPlatform Installation"
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
sudo mkdir -p /etc/jplatform

# Download JPlatform
echo ""
echo "Downloading JPlatform..."
cd /tmp

# For now, use placeholder until actual release exists
# In production, this would download from GitHub releases
echo "  Note: Using local build (release not yet published)"
if [ -d "/home/tc/jplatform" ]; then
    echo "  Building from source..."
    cd /home/tc/jplatform
    mvn clean package -DskipTests
    sudo cp jplatform-launcher/target/jplatform-launcher-*.jar "$JPLATFORM_HOME/jplatform-launcher.jar"
else
    echo "  ERROR: JPlatform source not found at /home/tc/jplatform"
    echo "  Please clone the repository first or download a release."
    exit 1
fi

# Create default configuration
echo ""
echo "Creating default configuration..."
sudo tee /etc/jplatform/config.yaml > /dev/null << 'YAML_EOF'
# JPlatform Configuration for VirtOS

# Platform settings
platform:
  name: "virtos-jplatform"
  dataDirectory: "/var/lib/jplatform"

# VM management (libvirt)
vm:
  enabled: true
  libvirtUri: "qemu:///system"
  defaultVcpu: 2
  defaultMemoryMB: 4096
  diskDirectory: "/var/lib/jplatform/vms"

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
echo "  jplatform deploy <app.yaml>    # Deploy an application"
echo "  jplatform start <app-id>       # Start application/VM"
echo "  jplatform stop <app-id>        # Stop application/VM"
echo "  jplatform status               # List all applications"
echo "  jplatform help                 # Show full help"
echo ""
echo "Example VM deployment:"
echo "  cat > /tmp/my-vm.yaml << 'EXAMPLE'"
echo "  applicationId: my-vm"
echo "  name: My Virtual Machine"
echo "  properties:"
echo "    vm.vcpu: \"4\""
echo "    vm.memory: \"8192\""
echo "    vm.disk: \"/var/lib/jplatform/vms/my-vm.qcow2\""
echo "    vm.network: \"bridge\""
echo "  EXAMPLE"
echo "  jplatform deploy /tmp/my-vm.yaml"
echo ""
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/virtos-jplatform-install"

# Create uninstall script
cat > "$SCRIPT_DIR/src/usr/local/bin/virtos-jplatform-uninstall" << 'EOF'
#!/bin/sh
# Uninstalls JPlatform from VirtOS

echo "Uninstalling JPlatform..."

# Stop all running applications
if [ -x /usr/local/bin/jplatform ]; then
    echo "  Stopping all JPlatform applications..."
    jplatform shutdown || true
fi

# Remove directories
echo "  Removing JPlatform files..."
sudo rm -rf /usr/local/lib/jplatform
sudo rm -rf /etc/jplatform

echo ""
echo "JPlatform uninstalled."
echo ""
echo "Note: Application data preserved at /var/lib/jplatform"
echo "      To remove data: sudo rm -rf /var/lib/jplatform"
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/virtos-jplatform-uninstall"

# Create status/info script
cat > "$SCRIPT_DIR/src/usr/local/bin/virtos-jplatform-info" << 'EOF'
#!/bin/sh
# Display JPlatform status and configuration

JPLATFORM_HOME="/usr/local/lib/jplatform"
JPLATFORM_DATA="/var/lib/jplatform"

echo "VirtOS JPlatform Status"
echo "======================="
echo ""

# Check installation
if [ ! -d "$JPLATFORM_HOME" ]; then
    echo "Status: NOT INSTALLED"
    echo ""
    echo "Run: virtos-jplatform-install"
    exit 0
fi

echo "Status: INSTALLED"
echo ""

# Version
if [ -f "$JPLATFORM_HOME/jplatform-launcher.jar" ]; then
    echo "JAR: $JPLATFORM_HOME/jplatform-launcher.jar"
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
if [ -x /usr/local/bin/jplatform ] && jplatform status >/dev/null 2>&1; then
    echo "Running Applications:"
    jplatform status
fi
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/bin/virtos-jplatform-info"

# Create post-install script
echo "Creating post-install script..."
cat > "$SCRIPT_DIR/src/usr/local/tce.installed/$PACKAGE" << 'EOF'
#!/bin/sh
# Post-install script for virtos-jplatform

echo "virtos-jplatform installed."
echo ""
echo "Next steps:"
echo "  1. Install JPlatform: virtos-jplatform-install"
echo "  2. Check status: virtos-jplatform-info"
echo "  3. Deploy apps/VMs: jplatform deploy <descriptor.yaml>"
echo ""
echo "Documentation: /usr/local/share/doc/jplatform/"
EOF
chmod +x "$SCRIPT_DIR/src/usr/local/tce.installed/$PACKAGE"

# Copy documentation
echo "Copying documentation..."
cat > "$SCRIPT_DIR/src/usr/local/share/doc/jplatform/README.md" << 'DOC_EOF'
# JPlatform on VirtOS

JPlatform provides unified orchestration for VMs, containers, Java applications,
and native binaries on VirtOS.

## Quick Start

1. Install JPlatform:
   ```bash
   virtos-jplatform-install
   ```

2. Deploy a virtual machine:
   ```bash
   cat > my-vm.yaml << EOF
   applicationId: test-vm
   name: Test VM
   properties:
     vm.vcpu: "2"
     vm.memory: "4096"
     vm.disk: "/var/lib/jplatform/vms/test.qcow2"
     vm.network: "bridge"
   EOF

   jplatform deploy my-vm.yaml
   jplatform start test-vm
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

   jplatform deploy my-container.yaml
   jplatform start nginx
   ```

## Commands

- `jplatform deploy <yaml>` - Deploy application/VM/container
- `jplatform start <id>` - Start workload
- `jplatform stop <id>` - Stop workload
- `jplatform status` - List all workloads
- `jplatform logs <id>` - View logs
- `jplatform metrics <id>` - View resource usage
- `virtos-jplatform-info` - Show installation status

## Documentation

Full documentation: https://github.com/FlossWare/jplatform
DOC_EOF

# Create package info
echo "Creating package metadata..."
cat > "$SCRIPT_DIR/${PACKAGE}.tcz.info" << 'INFO_EOF'
Title:          virtos-jplatform.tcz
Description:    JPlatform integration for VirtOS - unified VM/container/app orchestration
Version:        0.1-alpha
Author:         FlossWare
Original-site:  https://github.com/FlossWare/jplatform
Copying-policy: MIT
Size:           24K
Extension_by:   FlossWare
Tags:           virtualization orchestration java vm container
Comments:       Integrates JPlatform with VirtOS for managing VMs, containers, Java apps
                and native binaries through a unified API. Requires Java and libvirt.
Change-log:     2026-05-25 Initial release
Current:        2026-05-25
INFO_EOF

# Create dependencies file
cat > "$SCRIPT_DIR/${PACKAGE}.tcz.dep" << 'EOF'
openjdk-21-jre.tcz
libvirt.tcz
EOF

# Create package
echo "Creating TCZ package..."
cd "$SCRIPT_DIR/src"
sudo find usr -not -type d > "$SCRIPT_DIR/${PACKAGE}.tcz.list"
sudo find etc -not -type d >> "$SCRIPT_DIR/${PACKAGE}.tcz.list" 2>/dev/null || true
sudo find var -not -type d >> "$SCRIPT_DIR/${PACKAGE}.tcz.list" 2>/dev/null || true
sudo mksquashfs . "$SCRIPT_DIR/${PACKAGE}.tcz" -noappend -no-xattrs 2>/dev/null

# Generate MD5
echo "Generating MD5 checksum..."
cd "$SCRIPT_DIR"
md5sum "${PACKAGE}.tcz" > "${PACKAGE}.tcz.md5.txt"

echo ""
echo "Package built successfully!"
echo "  Package: $SCRIPT_DIR/${PACKAGE}.tcz"
echo "  Size: $(du -h ${PACKAGE}.tcz | cut -f1)"
echo "  Files: $(wc -l < ${PACKAGE}.tcz.list)"
echo ""
echo "To install:"
echo "  sudo cp ${PACKAGE}.tcz* /mnt/sda1/tce/optional/"
echo "  echo ${PACKAGE}.tcz >> /mnt/sda1/tce/onboot.lst"
echo "  tce-load -i ${PACKAGE}"
