#!/bin/bash
# VirtOS Build Validation
# Checks prerequisites and environment before building

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

# Source common build functions for logging and utilities
# shellcheck source=packages/build-common.sh
source "$PROJECT_ROOT/packages/build-common.sh"

ERRORS=0
WARNINGS=0

# Override error/warning to increment counters
_error() { error "$1"; ERRORS=$((ERRORS + 1)); }
_warning() { warning "$1"; WARNINGS=$((WARNINGS + 1)); }

# Use prefixed versions for this script
error() { _error "$1"; }
warning() { _warning "$1"; }

echo "VirtOS Build Validation"
echo "======================="

# Check operating system
section "System Information"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    success "OS: $PRETTY_NAME"
else
    warning "Cannot detect OS version"
fi

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    success "Architecture: $ARCH"
else
    error "Architecture $ARCH not supported (x86_64 required)"
fi

# Check disk space
section "Disk Space"
BUILD_SPACE=$(df -BG "$BUILD_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$BUILD_SPACE" -ge 20 ]; then
    success "Available space: ${BUILD_SPACE}GB (requirement: 20GB)"
else
    error "Insufficient disk space: ${BUILD_SPACE}GB (need 20GB)"
fi

# Check RAM
section "Memory"
TOTAL_RAM=$(free -g | grep Mem | awk '{print $2}')
if [ "$TOTAL_RAM" -ge 4 ]; then
    success "Total RAM: ${TOTAL_RAM}GB (requirement: 4GB)"
else
    warning "Low RAM: ${TOTAL_RAM}GB (recommended: 4GB)"
fi

# Check required commands
section "Build Tools"
REQUIRED_TOOLS=(
    "bash:bash"
    "wget:wget"
    "cpio:cpio"
    "gzip:gzip"
    "find:findutils"
    "sudo:sudo"
    "md5sum:coreutils"
    "sha256sum:coreutils"
)

for tool_info in "${REQUIRED_TOOLS[@]}"; do
    tool="${tool_info%%:*}"
    package="${tool_info##*:}"

    if command -v "$tool" >/dev/null 2>&1; then
        success "$tool found"
    else
        error "$tool not found (install: $package)"
    fi
done

# Check for ISO creation tool (at least one required)
ISO_TOOL_FOUND=false
if command -v genisoimage >/dev/null 2>&1; then
    success "genisoimage found (ISO creation)"
    ISO_TOOL_FOUND=true
fi
if command -v mkisofs >/dev/null 2>&1; then
    success "mkisofs found (ISO creation)"
    ISO_TOOL_FOUND=true
fi
if command -v xorriso >/dev/null 2>&1; then
    success "xorriso found (ISO creation)"
    ISO_TOOL_FOUND=true
fi

if [ "$ISO_TOOL_FOUND" = false ]; then
    error "No ISO creation tool found (install one of: genisoimage, xorriso, or mkisofs)"
fi

# Check for isohybrid (optional, for USB boot)
if command -v isohybrid >/dev/null 2>&1; then
    success "isohybrid found (USB boot support)"
else
    warning "isohybrid not found - ISO will not be USB-bootable (install: syslinux-utils)"
fi

# Check optional tools
section "Optional Tools (for testing)"
OPTIONAL_TOOLS=(
    "qemu-system-x86_64:qemu"
    "shellcheck:shellcheck"
    "git:git"
)

for tool_info in "${OPTIONAL_TOOLS[@]}"; do
    tool="${tool_info%%:*}"
    package="${tool_info##*:}"

    if command -v "$tool" >/dev/null 2>&1; then
        success "$tool found"
    else
        info "$tool not found (install: $package) - optional"
    fi
done

# Check project structure
section "Project Structure"
REQUIRED_DIRS=(
    "build/scripts"
    "config"
    "config/custom-scripts"
    "config/profiles"
    "docs"
    "kernel"
    "packages"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        success "$dir/ exists"
    else
        error "$dir/ missing"
    fi
done

# Check required files
REQUIRED_FILES=(
    "build/build.conf"
    "build/scripts/prepare.sh"
    "build/scripts/customize.sh"
    "build/scripts/iso.sh"
    "config/bootlocal.sh"
    "config/sysctl.conf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        success "$file exists"
    else
        error "$file missing"
    fi
done

# Check script permissions
section "Script Permissions"
BUILD_SCRIPTS=(
    "build/scripts/prepare.sh"
    "build/scripts/customize.sh"
    "build/scripts/iso.sh"
    "build/scripts/build-all.sh"
)

for script in "${BUILD_SCRIPTS[@]}"; do
    if [ -x "$PROJECT_ROOT/$script" ]; then
        success "$(basename "$script") is executable"
    else
        error "$(basename "$script") is not executable (run: chmod +x $script)"
    fi
done

# Check virtos scripts
section "VirtOS Management Scripts"
VIRTOS_SCRIPT_COUNT=$(find "$PROJECT_ROOT/config/custom-scripts" -name "virtos-*" -type f -executable | wc -l)
if [ "$VIRTOS_SCRIPT_COUNT" -gt 0 ]; then
    success "Found $VIRTOS_SCRIPT_COUNT virtos-* management scripts"
else
    error "No executable virtos-* scripts found in config/custom-scripts/"
fi

# Syntax check all scripts
if command -v bash >/dev/null 2>&1; then
    section "Syntax Check"
    SYNTAX_ERRORS=0

    # Check build scripts
    for script in "$PROJECT_ROOT"/build/scripts/*.sh; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                success "$(basename "$script") syntax OK"
            else
                error "$(basename "$script") has syntax errors"
                SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
            fi
        fi
    done

    # Check sample of virtos scripts
    VIRTOS_CHECKED=0
    for script in "$PROJECT_ROOT"/config/custom-scripts/virtos-*; do
        if [ -f "$script" ] && [ -x "$script" ] && [ $VIRTOS_CHECKED -lt 5 ]; then
            if bash -n "$script" 2>/dev/null; then
                success "$(basename "$script") syntax OK"
            else
                error "$(basename "$script") has syntax errors"
                SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
            fi
            VIRTOS_CHECKED=$((VIRTOS_CHECKED + 1))
        fi
    done

    if [ $VIRTOS_CHECKED -lt "$VIRTOS_SCRIPT_COUNT" ]; then
        info "Checked $VIRTOS_CHECKED of $VIRTOS_SCRIPT_COUNT scripts (sample)"
    fi
fi

# Check network connectivity
section "Network Connectivity"
if ping -c 1 tinycorelinux.net >/dev/null 2>&1; then
    success "Can reach tinycorelinux.net"
else
    warning "Cannot reach tinycorelinux.net (required for downloads)"
fi

# Check build configuration
section "Build Configuration"
if [ -f "$BUILD_DIR/build.conf" ]; then
    # shellcheck disable=SC1090
    # shellcheck disable=SC1091
    source "$BUILD_DIR/build.conf"

    success "Profile: ${PROFILE:-custom}"
    success "TC Version: ${TC_VERSION:-15.x}"

    # Count enabled features
    FEATURES=0
    [ "$INCLUDE_KVM" = "yes" ] && FEATURES=$((FEATURES + 1)) && info "  - KVM/QEMU enabled"
    [ "$INCLUDE_LXC" = "yes" ] && FEATURES=$((FEATURES + 1)) && info "  - LXC enabled"
    [ "$INCLUDE_DOCKER" = "yes" ] && FEATURES=$((FEATURES + 1)) && info "  - Docker enabled"
    [ "$INCLUDE_PODMAN" = "yes" ] && FEATURES=$((FEATURES + 1)) && info "  - Podman enabled"
    [ "$INCLUDE_CONTAINERD" = "yes" ] && FEATURES=$((FEATURES + 1)) && info "  - containerd enabled"

    success "Enabled features: $FEATURES"
else
    error "build.conf not found or not readable"
fi

# Summary
section "Validation Summary"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo "Ready to build VirtOS ISO."
    echo ""
    echo "To build:"
    echo "  cd build/scripts"
    echo "  ./build-all.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Warnings: $WARNINGS${NC}"
    echo "You can proceed but some features may not work."
    echo ""
    echo "To build anyway:"
    echo "  cd build/scripts"
    echo "  ./build-all.sh"
    exit 0
else
    echo -e "${RED}✗ Errors: $ERRORS${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ Warnings: $WARNINGS${NC}"
    fi
    echo ""
    echo "Fix the errors above before building."
    echo ""
    echo "Common fixes:"
    echo "  - Install build tools: sudo apt install genisoimage syslinux-utils cpio"
    echo "  - Fix permissions: chmod +x build/scripts/*.sh"
    echo "  - Free disk space: need at least 20GB"
    exit 1
fi
