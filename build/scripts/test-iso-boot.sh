#!/bin/bash
# VirtOS ISO Boot Testing Script
# Tests ISO boot in QEMU with automated checks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
BOOT_TIMEOUT="${BOOT_TIMEOUT:-120}"
QEMU_MEMORY="${QEMU_MEMORY:-2048}"
QEMU_CPUS="${QEMU_CPUS:-2}"
HEADLESS="${HEADLESS:-0}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

# Find latest ISO
find_latest_iso() {
    ISO_FILE=$(ls -t "$BUILD_DIR/output/VirtOS-"*".iso" 2>/dev/null | head -1)
    if [ -z "$ISO_FILE" ]; then
        log_error "No ISO found in $BUILD_DIR/output/"
        exit 1
    fi
    echo "$ISO_FILE"
}

# Check QEMU
check_qemu() {
    log_info "Checking QEMU availability..."

    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        log_error "qemu-system-x86_64 not found"
        exit 1
    fi

    log_success "QEMU found"

    if [ -c /dev/kvm ]; then
        log_success "KVM available"
        USE_KVM=1
    else
        log_warning "KVM not available"
        USE_KVM=0
    fi
}

# Run boot test
run_boot_test() {
    ISO_FILE="$1"

    log_info "Starting ISO boot test..."
    log_info "ISO: $(basename "$ISO_FILE")"
    log_info "Memory: ${QEMU_MEMORY}MB"
    log_info "Timeout: ${BOOT_TIMEOUT}s"
    echo ""

    SERIAL_FILE="/tmp/virtos-boot-serial-$$.log"

    QEMU_CMD="qemu-system-x86_64"
    QEMU_CMD="$QEMU_CMD -m $QEMU_MEMORY"
    QEMU_CMD="$QEMU_CMD -smp $QEMU_CPUS"
    QEMU_CMD="$QEMU_CMD -cdrom $ISO_FILE"
    QEMU_CMD="$QEMU_CMD -boot d"

    if [ "$USE_KVM" = "1" ]; then
        QEMU_CMD="$QEMU_CMD -enable-kvm"
    fi

    if [ "$HEADLESS" = "1" ]; then
        QEMU_CMD="$QEMU_CMD -display none"
    else
        QEMU_CMD="$QEMU_CMD -vnc :99"
    fi

    QEMU_CMD="$QEMU_CMD -serial file:$SERIAL_FILE"

    eval "$QEMU_CMD" &
    QEMU_PID=$!

    BOOT_SUCCESS=0
    ELAPSED=0

    log_info "Waiting for boot (max ${BOOT_TIMEOUT}s)..."

    while [ $ELAPSED -lt "$BOOT_TIMEOUT" ]; do
        if [ ! -d "/proc/$QEMU_PID" ]; then
            break
        fi

        if [ -f "$SERIAL_FILE" ]; then
            if grep -qE "(BusyBox|shell|virtos)" "$SERIAL_FILE" 2>/dev/null; then
                BOOT_SUCCESS=1
                break
            fi
        fi

        if [ $((ELAPSED % 10)) -eq 0 ]; then
            echo -ne "."
        fi

        sleep 1
        ELAPSED=$((ELAPSED + 1))
    done

    echo ""

    # Terminate QEMU
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill -TERM "$QEMU_PID" 2>/dev/null || true
        sleep 2
        kill -KILL "$QEMU_PID" 2>/dev/null || true
    fi

    # Print results
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo "Boot Test Results"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    if [ -f "$SERIAL_FILE" ]; then
        log_info "Serial output (last 20 lines):"
        echo "---"
        tail -20 "$SERIAL_FILE"
        echo "---"
    fi

    if [ "$BOOT_SUCCESS" = "1" ]; then
        echo -e "${GREEN}✓ Boot test PASSED${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Boot test INCONCLUSIVE${NC}"
        return 1
    fi
}

# Main
echo ""
echo -e "${BLUE}========================================${NC}"
echo "VirtOS ISO Boot Test"
echo -e "${BLUE}========================================${NC}"
echo ""

check_qemu

ISO_FILE=$(find_latest_iso)
log_success "Found ISO: $(basename "$ISO_FILE")"
echo ""

run_boot_test "$ISO_FILE"
