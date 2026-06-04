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

    # Validate ISO file path to prevent command injection
    if [[ ! "$ISO_FILE" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
        log_error "Invalid ISO filename: contains unsafe characters"
        exit 1
    fi

    if [ ! -f "$ISO_FILE" ]; then
        log_error "ISO file does not exist: $ISO_FILE"
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

    # Use mktemp for secure temporary file creation (fixes #597)
    SERIAL_FILE=$(mktemp /tmp/virtos-boot-serial-XXXXXX.log)
    trap 'rm -f "$SERIAL_FILE"' EXIT

    # Build QEMU command as array to avoid eval and command injection (fixes #578, #581)
    QEMU_ARGS=(
        -m "$QEMU_MEMORY"
        -smp "$QEMU_CPUS"
        -cdrom "$ISO_FILE"
        -boot d
    )

    if [ "$USE_KVM" = "1" ]; then
        QEMU_ARGS+=(-enable-kvm)
    fi

    if [ "$HEADLESS" = "1" ]; then
        QEMU_ARGS+=(-display none)
    else
        QEMU_ARGS+=(-vnc :99)
    fi

    QEMU_ARGS+=(-serial "file:$SERIAL_FILE")

    # Execute QEMU directly without eval to prevent command injection
    qemu-system-x86_64 "${QEMU_ARGS[@]}" &
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

    # Terminate QEMU gracefully (fixes #594 - race condition)
    if [ -n "$QEMU_PID" ] && kill -0 "$QEMU_PID" 2>/dev/null; then
        kill -TERM "$QEMU_PID" 2>/dev/null || true
        # Wait up to 5 seconds for graceful shutdown
        for i in {1..50}; do
            if ! kill -0 "$QEMU_PID" 2>/dev/null; then
                break
            fi
            sleep 0.1
        done
        # Force kill if still running
        if kill -0 "$QEMU_PID" 2>/dev/null; then
            kill -KILL "$QEMU_PID" 2>/dev/null || true
            sleep 0.5
        fi
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
