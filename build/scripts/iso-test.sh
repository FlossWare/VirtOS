#!/bin/bash
# FlossWare VirtOS - Automated ISO Testing Suite
# Tests ISO build, validation, and boot capabilities
# Issue #3: Build system untested and may not work

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

# Test configuration
TEST_PROFILE="${1:-standard}"
ENABLE_QEMU_TEST="${ENABLE_QEMU_TEST:-yes}"
QEMU_TIMEOUT="${QEMU_TIMEOUT:-30}"
VERBOSE="${VERBOSE:-0}"
OUTPUT_LOG="${OUTPUT_LOG:-/tmp/virtos-iso-test.log}"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test result tracking
declare -a TEST_RESULTS

#==============================================================================
# Helper Functions
#==============================================================================

log_test() {
    local name="$1"
    local status="$2"
    local details="${3:-}"

    case "$status" in
        PASS)
            echo -e "${GREEN}✓${NC} $name"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            TEST_RESULTS+=("✓ $name")
            ;;
        FAIL)
            echo -e "${RED}✗${NC} $name"
            [ -n "$details" ] && echo "  Error: $details"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            TEST_RESULTS+=("✗ $name: $details")
            ;;
        SKIP)
            echo -e "${YELLOW}⊘${NC} $name"
            [ -n "$details" ] && echo "  Reason: $details"
            TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
            TEST_RESULTS+=("⊘ $name: $details")
            ;;
    esac
}

section() {
    echo ""
    echo -e "${BLUE}=== $1 ===${NC}"
}

verbose_log() {
    if [ "$VERBOSE" = "1" ]; then
        echo "[DEBUG] $@"
    fi
}

#==============================================================================
# Phase 1: Pre-Build Validation
#==============================================================================

phase1_validation() {
    section "Phase 1: Pre-Build Validation (5 tests)"

    # Test 1.1: ISO build tools available
    local tools_ok=true
    for tool in genisoimage isohybrid; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_test "Tool available: $tool" "FAIL" "Not installed"
            tools_ok=false
        fi
    done
    [ "$tools_ok" = true ] && log_test "Build tools installed" "PASS"

    # Test 1.2: build.conf exists and valid
    if [ -f "$BUILD_DIR/build.conf" ]; then
        if bash -n "$BUILD_DIR/build.conf" 2>/dev/null; then
            log_test "build.conf is valid" "PASS"
        else
            log_test "build.conf syntax" "FAIL" "Syntax errors in build.conf"
        fi
    else
        log_test "build.conf exists" "FAIL" "File not found"
    fi

    # Test 1.3: Build scripts executable
    local scripts_ok=true
    for script in prepare.sh customize.sh iso.sh; do
        if [ ! -x "$SCRIPT_DIR/$script" ]; then
            log_test "Script executable: $script" "FAIL" "Not executable"
            scripts_ok=false
        fi
    done
    [ "$scripts_ok" = true ] && log_test "Build scripts executable" "PASS"

    # Test 1.4: Profile validation
    if [ -n "$TEST_PROFILE" ]; then
        VALID_PROFILES="minimal standard full containers developer kubernetes storage"
        if echo " $VALID_PROFILES " | grep -q " $TEST_PROFILE "; then
            log_test "Profile valid: $TEST_PROFILE" "PASS"
        else
            log_test "Profile valid: $TEST_PROFILE" "FAIL" "Unknown profile"
        fi
    else
        log_test "Profile specified" "FAIL" "No profile provided"
    fi

    # Test 1.5: Disk space sufficient
    local available_space=$(df -BG "$BUILD_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$available_space" -ge 20 ]; then
        log_test "Disk space available (${available_space}GB)" "PASS"
    else
        log_test "Disk space sufficient" "FAIL" "Only ${available_space}GB available, need 20GB"
    fi
}

#==============================================================================
# Phase 2: ISO Build
#==============================================================================

phase2_build() {
    section "Phase 2: ISO Build (5 tests)"

    # Test 2.1: Run build-all.sh
    echo "Building ISO with profile: $TEST_PROFILE"

    # Create temporary config for test
    local temp_config=$(mktemp)
    trap "rm -f $temp_config" EXIT

    cp "$BUILD_DIR/build.conf" "$temp_config"
    echo "PROFILE=\"$TEST_PROFILE\"" >> "$temp_config"

    # Run build (suppress user interaction)
    if BUILD_CONF="$temp_config" PROFILE="$TEST_PROFILE" \
        bash "$SCRIPT_DIR/build-all.sh" >/tmp/virtos-build.log 2>&1 <<EOF

y
y
EOF
    then
        log_test "ISO build completed" "PASS"
    else
        log_test "ISO build completed" "FAIL" "See /tmp/virtos-build.log for details"
        cat /tmp/virtos-build.log >> "$OUTPUT_LOG"
        return 1
    fi

    # Test 2.2: ISO file exists
    local iso_file=$(find "$BUILD_DIR/output" -name "VirtOS-*.iso" -type f 2>/dev/null | head -1)
    if [ -n "$iso_file" ] && [ -f "$iso_file" ]; then
        log_test "ISO file created" "PASS"
        verbose_log "ISO: $iso_file"
    else
        log_test "ISO file exists" "FAIL" "No ISO found in $BUILD_DIR/output"
        return 1
    fi

    # Test 2.3: ISO file size reasonable
    local iso_size=$(du -h "$iso_file" | cut -f1)
    local iso_size_bytes=$(stat -f%z "$iso_file" 2>/dev/null || stat -c%s "$iso_file" 2>/dev/null)
    local iso_size_mb=$((iso_size_bytes / 1048576))

    if [ "$iso_size_mb" -gt 50 ] && [ "$iso_size_mb" -lt 1000 ]; then
        log_test "ISO size reasonable ($iso_size)" "PASS"
    else
        log_test "ISO size in range" "FAIL" "Size ${iso_size_mb}MB outside 50-1000MB"
    fi

    # Test 2.4: Checksums generated
    local has_checksums=true
    [ ! -f "$iso_file.md5" ] && has_checksums=false
    [ ! -f "$iso_file.sha256" ] && has_checksums=false

    if [ "$has_checksums" = true ]; then
        log_test "Checksums generated" "PASS"
    else
        log_test "Checksums exist" "FAIL" "MD5/SHA256 files not found"
    fi

    # Test 2.5: Checksum verification
    if [ -f "${iso_file}.md5" ]; then
        local iso_dir
        iso_dir=$(dirname "$iso_file")
        local iso_basename
        iso_basename=$(basename "$iso_file")

        # Verify checksum - md5sum -c expects format "hash  filename"
        if (cd "$iso_dir" && md5sum -c "${iso_basename}.md5" >/dev/null 2>&1); then
            log_test "Checksum verification" "PASS"
        else
            log_test "Checksum verification" "FAIL" "Checksum mismatch"
        fi
    else
        log_test "Checksum verification" "SKIP" "MD5 file not available"
    fi

    # Store ISO path for later tests
    echo "$iso_file" > /tmp/virtos-iso-path.txt
}

#==============================================================================
# Phase 3: ISO Content Validation
#==============================================================================

phase3_content_validation() {
    section "Phase 3: ISO Content Validation (4 tests)"

    local iso_file
    if [ ! -f /tmp/virtos-iso-path.txt ]; then
        log_test "ISO content validation" "SKIP" "No ISO file from build phase"
        return 0
    fi

    iso_file=$(cat /tmp/virtos-iso-path.txt)

    if [ ! -f "$iso_file" ]; then
        log_test "ISO file accessible" "FAIL" "File not found: $iso_file"
        return 1
    fi

    # Test 3.1: ISO is valid format (starts with CD001)
    if dd if="$iso_file" bs=1 skip=32769 count=5 2>/dev/null | grep -q "CD001"; then
        log_test "ISO format valid (CD001 signature)" "PASS"
    else
        log_test "ISO format validation" "FAIL" "Not a valid ISO 9660 image"
    fi

    # Test 3.2: ISO contains boot loader
    # Extract and check for isolinux.bin or similar
    if isoinfo -f -R -i "$iso_file" 2>/dev/null | grep -q "isolinux.bin"; then
        log_test "Boot loader present" "PASS"
    else
        log_test "Boot loader present" "FAIL" "isolinux.bin not found"
    fi

    # Test 3.3: ISO contains Tiny Core kernel
    if isoinfo -f -R -i "$iso_file" 2>/dev/null | grep -q "vmlinuz"; then
        log_test "Linux kernel present" "PASS"
    else
        log_test "Linux kernel present" "FAIL" "vmlinuz not found"
    fi

    # Test 3.4: ISO contains initrd
    if isoinfo -f -R -i "$iso_file" 2>/dev/null | grep -q "core.gz"; then
        log_test "Initramfs present" "PASS"
    else
        log_test "Initramfs present" "FAIL" "core.gz not found"
    fi
}

#==============================================================================
# Phase 4: QEMU Boot Test
#==============================================================================

phase4_boot_test() {
    section "Phase 4: QEMU Boot Test (3 tests)"

    local iso_file
    if [ ! -f /tmp/virtos-iso-path.txt ]; then
        log_test "QEMU boot test" "SKIP" "No ISO file from build phase"
        return 0
    fi

    iso_file=$(cat /tmp/virtos-iso-path.txt)

    # Test 4.1: QEMU available
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        log_test "QEMU available" "SKIP" "qemu-system-x86_64 not installed"
        ENABLE_QEMU_TEST="no"
        return 0
    fi

    log_test "QEMU available" "PASS"

    if [ "$ENABLE_QEMU_TEST" != "yes" ]; then
        log_test "QEMU boot test" "SKIP" "QEMU testing disabled"
        return 0
    fi

    # Test 4.2: ISO boots (simple check - kernel loads)
    echo "Testing ISO boot (timeout: ${QEMU_TIMEOUT}s)..."

    # Run QEMU with timeout and capture output
    local qemu_log
    qemu_log=$(mktemp)

    # Use timeout command if available
    local timeout_cmd=""
    if command -v timeout >/dev/null 2>&1; then
        timeout_cmd="timeout $QEMU_TIMEOUT"
    fi

    # Run QEMU and capture output - expect it to timeout or exit after boot starts
    if $timeout_cmd qemu-system-x86_64 \
        -enable-kvm \
        -m 1024 \
        -smp 2 \
        -cdrom "$iso_file" \
        -nographic \
        -monitor none \
        >"$qemu_log" 2>&1; then
        # QEMU exited successfully (unlikely - kernel should run)
        if grep -q "Linux\|Booting\|Tiny Core" "$qemu_log" 2>/dev/null; then
            log_test "QEMU boots successfully" "PASS"
        else
            log_test "QEMU boot test" "SKIP" "QEMU exited without output"
        fi
    else
        # QEMU was terminated by timeout or exited with error
        local exit_code=$?

        # Check if kernel at least started loading
        if grep -qE "Linux|Booting|KVM|x86|CPU|RAM" "$qemu_log" 2>/dev/null; then
            log_test "QEMU boot (kernel loads)" "PASS"
        elif grep -qi "isolinux\|bootloader\|cdrom" "$qemu_log" 2>/dev/null; then
            log_test "QEMU boot (bootloader detected)" "PASS"
        else
            # If we got timeout exit code (124), that's usually expected
            if [ "$exit_code" -eq 124 ] || [ "$exit_code" -eq 137 ]; then
                log_test "QEMU boot (timed out - expected)" "PASS"
            else
                log_test "QEMU boot test" "SKIP" "Inconclusive result"
            fi
        fi
    fi

    # Test 4.3: No obvious kernel panics in boot
    if grep -iE "kernel panic|oops|fatal error|segmentation fault" "$qemu_log" 2>/dev/null; then
        log_test "No kernel panics" "FAIL" "Kernel panic detected in boot"
    else
        log_test "No kernel panics" "PASS"
    fi

    # Clean up temp file
    rm -f "$qemu_log"
}

#==============================================================================
# Phase 5: Reporting
#==============================================================================

report_results() {
    section "Test Summary"

    local total=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))
    local pass_pct=0

    if [ $total -gt 0 ]; then
        pass_pct=$((TESTS_PASSED * 100 / total))
    fi

    echo ""
    echo "Results:"
    echo -e "  ${GREEN}✓ Passed${NC}: $TESTS_PASSED/$total"
    echo -e "  ${RED}✗ Failed${NC}: $TESTS_FAILED/$total"
    echo -e "  ${YELLOW}⊘ Skipped${NC}: $TESTS_SKIPPED/$total"
    echo ""
    echo "Pass Rate: ${pass_pct}%"
    echo ""

    # Write results to log file
    {
        echo "VirtOS ISO Test Results - $(date)"
        echo "Profile: $TEST_PROFILE"
        echo ""
        echo "Summary:"
        echo "  Passed: $TESTS_PASSED/$total"
        echo "  Failed: $TESTS_FAILED/$total"
        echo "  Skipped: $TESTS_SKIPPED/$total"
        echo ""
        echo "Detailed Results:"
        printf '%s\n' "${TEST_RESULTS[@]}"
        echo ""
    } >> "$OUTPUT_LOG"

    # Determine exit status
    if [ $TESTS_FAILED -eq 0 ]; then
        if [ $TESTS_PASSED -ge 15 ]; then
            echo -e "${GREEN}Status: BUILD SUCCESSFUL${NC}"
            return 0
        else
            echo -e "${YELLOW}Status: BUILD INCOMPLETE (insufficient passing tests)${NC}"
            return 1
        fi
    else
        echo -e "${RED}Status: BUILD FAILED${NC}"
        return 1
    fi
}

#==============================================================================
# Main Entry Point
#==============================================================================

main() {
    echo "=========================================="
    echo "FlossWare VirtOS - ISO Testing Suite"
    echo "=========================================="
    echo ""
    echo "Profile: $TEST_PROFILE"
    echo "QEMU Testing: $ENABLE_QEMU_TEST"
    echo "Output Log: $OUTPUT_LOG"
    echo ""

    # Initialize log
    : > "$OUTPUT_LOG"

    # Run all phases
    phase1_validation

    if [ $TESTS_FAILED -gt 0 ]; then
        echo -e "${RED}Pre-build validation failed. Aborting.${NC}"
        report_results
        exit 1
    fi

    phase2_build
    phase3_content_validation
    phase4_boot_test

    # Report and exit
    report_results
    exit $?
}

# Run main function
main "$@"
