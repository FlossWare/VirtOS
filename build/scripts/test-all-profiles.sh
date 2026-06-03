#!/bin/bash
# VirtOS - Test All Build Profiles
# Builds and validates all 7 profiles sequentially

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

# All available profiles
PROFILES="minimal standard full containers developer kubernetes storage"

# Configuration
VERBOSE="${VERBOSE:-0}"
PARALLEL="${PARALLEL:-0}"
DRY_RUN="${DRY_RUN:-0}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
LOG_DIR="/tmp/virtos-profile-tests"
mkdir -p "$LOG_DIR"

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

# Test single profile
test_profile() {
    local profile="$1"

    log_info "Testing profile: $profile"

    # Backup current config
    cp "$BUILD_DIR/build.conf" "$BUILD_DIR/build.conf.bak"

    # Set profile
    sed -i "s/^PROFILE=.*/PROFILE=\"$profile\"/" "$BUILD_DIR/build.conf"

    if [ "$DRY_RUN" = "1" ]; then
        log_info "DRY RUN: Would build profile $profile"
        cp "$BUILD_DIR/build.conf.bak" "$BUILD_DIR/build.conf"
        return 0
    fi

    # Build
    BUILD_LOG="$LOG_DIR/profile-$profile.log"
    log_info "Building... (see $BUILD_LOG)"

    if TEST_PROFILES="$profile" SKIP_DOWNLOAD=1 \
        "$SCRIPT_DIR/test-iso-build.sh" \
        >"$BUILD_LOG" 2>&1; then

        # Check ISO
        if ls "$BUILD_DIR/output/VirtOS-"*".iso" >/dev/null 2>&1; then
            ISO_FILE=$(ls -t "$BUILD_DIR/output/VirtOS-"*".iso" 2>/dev/null | head -1)
            ISO_SIZE=$(du -h "$ISO_FILE" | cut -f1)

            log_success "Profile $profile complete: $ISO_SIZE"
            echo "$profile:PASS:$ISO_SIZE" >> "$LOG_DIR/results.txt"
        else
            log_error "Profile $profile: No ISO created"
            echo "$profile:FAIL:No ISO" >> "$LOG_DIR/results.txt"
        fi
    else
        log_error "Profile $profile: Build failed"
        echo "$profile:FAIL:Build error" >> "$LOG_DIR/results.txt"
    fi

    # Restore config
    cp "$BUILD_DIR/build.conf.bak" "$BUILD_DIR/build.conf"
    echo ""
}

# Main
echo ""
echo -e "${BLUE}========================================${NC}"
echo "VirtOS Profile Testing"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Profiles to test: $PROFILES"
echo "Log directory: $LOG_DIR"
if [ "$DRY_RUN" = "1" ]; then
    echo -e "${YELLOW}DRY RUN MODE${NC}"
fi
echo ""

> "$LOG_DIR/results.txt"

log_info "Running builds SEQUENTIALLY"
echo ""

for profile in $PROFILES; do
    test_profile "$profile"
done

# Print summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo "Test Summary"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ -f "$LOG_DIR/results.txt" ]; then
    PASS=0
    FAIL=0

    while IFS=':' read -r profile status size; do
        if [ "$status" = "PASS" ]; then
            echo -e "${GREEN}✓${NC} $profile: $size"
            PASS=$((PASS + 1))
        else
            echo -e "${RED}✗${NC} $profile: FAILED"
            FAIL=$((FAIL + 1))
        fi
    done < "$LOG_DIR/results.txt"

    echo ""
    echo "Results: $PASS passed, $FAIL failed"
    echo ""

    if [ $FAIL -eq 0 ]; then
        echo -e "${GREEN}✓ All profiles tested successfully!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some profiles failed${NC}"
        exit 1
    fi
fi
