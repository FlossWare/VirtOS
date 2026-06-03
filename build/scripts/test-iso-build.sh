#!/bin/bash
# VirtOS ISO Build Testing Script
# Performs end-to-end ISO build and validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
LOG_DIR="/tmp/virtos-iso-test"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test-$(date +%Y%m%d-%H%M%S).log"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1" | tee -a "$LOG_FILE"
}

# Configuration
TEST_PROFILES="${TEST_PROFILES:-minimal}"
SKIP_DOWNLOAD="${SKIP_DOWNLOAD:-0}"
DRY_RUN="${DRY_RUN:-0}"
VERBOSE="${VERBOSE:-0}"

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

test_result() {
    local name="$1"
    local result="$2"

    TESTS_RUN=$((TESTS_RUN + 1))

    if [ "$result" = "pass" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "$name"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "$name"
    fi
}

# Phase 1: Pre-flight checks
phase_preflight() {
    log_info "Phase 1: Pre-flight Checks"
    
    # Check disk space
    AVAILABLE_GB=$(df -BG "$BUILD_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$AVAILABLE_GB" -ge 25 ]; then
        test_result "Disk space check (need 25GB, have ${AVAILABLE_GB}GB)" "pass"
    else
        log_error "Insufficient disk space: ${AVAILABLE_GB}GB (need 25GB)"
        test_result "Disk space check" "fail"
    fi

    # Check required tools
    TOOLS_OK=true
    for tool in bash wget cpio gzip; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            log_warning "Tool not found: $tool"
            TOOLS_OK=false
        fi
    done

    # Check for ISO creation tool (at least one required)
    if ! command -v genisoimage >/dev/null 2>&1 && \
       ! command -v mkisofs >/dev/null 2>&1 && \
       ! command -v xorriso >/dev/null 2>&1; then
        log_warning "No ISO creation tool found (need genisoimage, mkisofs, or xorriso)"
        TOOLS_OK=false
    fi

    if [ "$TOOLS_OK" = "true" ]; then
        test_result "Required build tools available" "pass"
    else
        test_result "Required build tools available" "fail"
    fi

    # Check project structure
    STRUCT_OK=true
    for dir in config/custom-scripts build/scripts packages; do
        if [ ! -d "$PROJECT_ROOT/$dir" ]; then
            log_warning "Directory missing: $dir"
            STRUCT_OK=false
        fi
    done

    if [ "$STRUCT_OK" = "true" ]; then
        test_result "Project structure valid" "pass"
    else
        test_result "Project structure valid" "fail"
    fi

    log_info ""
}

# Phase 2: Validation
phase_validation() {
    log_info "Phase 2: Pre-build Validation"
    
    if "$SCRIPT_DIR/validate-build.sh" >"$LOG_DIR/validate.log" 2>&1; then
        test_result "Build environment validation" "pass"
    else
        test_result "Build environment validation" "fail"
    fi

    # Syntax check
    SYNTAX_OK=true
    for script in "$BUILD_DIR"/scripts/*.sh; do
        if ! bash -n "$script" 2>/dev/null; then
            log_warning "Syntax error in: $(basename "$script")"
            SYNTAX_OK=false
        fi
    done

    if [ "$SYNTAX_OK" = "true" ]; then
        test_result "Build scripts syntax valid" "pass"
    else
        test_result "Build scripts syntax valid" "fail"
    fi

    log_info ""
}

# Phase 3: Build
phase_build() {
    log_info "Phase 3: ISO Build"
    
    for profile in $TEST_PROFILES; do
        log_info "Testing profile: $profile"

        # Backup config
        cp "$BUILD_DIR/build.conf" "$BUILD_DIR/build.conf.bak"

        # Set profile
        sed -i "s/^PROFILE=.*/PROFILE=\"$profile\"/" "$BUILD_DIR/build.conf"

        if [ "$DRY_RUN" = "0" ]; then
            BUILD_LOG="$LOG_DIR/build-$profile.log"

            if [ "$SKIP_DOWNLOAD" = "1" ]; then
                # Skip prepare if downloads exist
                if "$SCRIPT_DIR/customize.sh" >"$BUILD_LOG" 2>&1 && \
                   "$SCRIPT_DIR/iso.sh" >>"$BUILD_LOG" 2>&1; then
                    test_result "Build ISO for profile: $profile" "pass"

                    if ls "$BUILD_DIR/output/VirtOS-"*".iso" >/dev/null 2>&1; then
                        ISO_FILE=$(ls -t "$BUILD_DIR/output/VirtOS-"*".iso" 2>/dev/null | head -1)
                        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
                        log_success "ISO: $(basename "$ISO_FILE") ($ISO_SIZE)"
                        test_result "ISO file created for profile: $profile" "pass"
                    else
                        test_result "ISO file created for profile: $profile" "fail"
                    fi
                else
                    test_result "Build ISO for profile: $profile" "fail"
                fi
            else
                # Full build
                if "$SCRIPT_DIR/prepare.sh" >"$BUILD_LOG" 2>&1 && \
                   "$SCRIPT_DIR/customize.sh" >>"$BUILD_LOG" 2>&1 && \
                   "$SCRIPT_DIR/iso.sh" >>"$BUILD_LOG" 2>&1; then
                    test_result "Build ISO for profile: $profile" "pass"

                    if ls "$BUILD_DIR/output/VirtOS-"*".iso" >/dev/null 2>&1; then
                        ISO_FILE=$(ls -t "$BUILD_DIR/output/VirtOS-"*".iso" 2>/dev/null | head -1)
                        ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)
                        log_success "ISO: $(basename "$ISO_FILE") ($ISO_SIZE)"
                        test_result "ISO file created for profile: $profile" "pass"
                    else
                        test_result "ISO file created for profile: $profile" "fail"
                    fi
                else
                    test_result "Build ISO for profile: $profile" "fail"
                fi
            fi
        fi

        # Restore config
        cp "$BUILD_DIR/build.conf.bak" "$BUILD_DIR/build.conf"
    done

    log_info ""
}

# Phase 4: ISO Validation
phase_iso_validation() {
    log_info "Phase 4: ISO Validation"
    
    if ls "$BUILD_DIR/output/VirtOS-"*".iso" >/dev/null 2>&1; then
        ISO_FILE=$(ls -t "$BUILD_DIR/output/VirtOS-"*".iso" 2>/dev/null | head -1)

        if [ -f "$ISO_FILE" ] && [ -s "$ISO_FILE" ]; then
            test_result "ISO file exists and has content" "pass"
        else
            test_result "ISO file exists and has content" "fail"
        fi

        # Check size
        ISO_SIZE_MB=$(($(stat -c%s "$ISO_FILE") / 1024 / 1024))

        if [ "$ISO_SIZE_MB" -ge 50 ] && [ "$ISO_SIZE_MB" -le 1000 ]; then
            test_result "ISO size reasonable (${ISO_SIZE_MB}MB)" "pass"
        else
            test_result "ISO size reasonable (${ISO_SIZE_MB}MB)" "fail"
        fi

        # Check checksums
        if [ -f "$ISO_FILE.md5" ]; then
            cd "$BUILD_DIR/output"
            if md5sum -c "$(basename "$ISO_FILE").md5" >/dev/null 2>&1; then
                test_result "ISO MD5 checksum valid" "pass"
            else
                test_result "ISO MD5 checksum valid" "fail"
            fi
        fi
    else
        test_result "ISO file exists" "fail"
    fi

    log_info ""
}

# Print summary
print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo "ISO Build Test Summary"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Tests Run:    $TESTS_RUN"
    echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [ "$TESTS_RUN" -gt 0 ]; then
        PASS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
        echo "Pass Rate: $PASS_RATE%"
    fi
    echo ""

    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

# Main
echo ""
echo -e "${BLUE}========================================${NC}"
echo "VirtOS ISO Build Testing"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Profiles: $TEST_PROFILES"
echo "Log: $LOG_FILE"
echo ""

phase_preflight
phase_validation
phase_build
phase_iso_validation
print_summary
