#!/bin/bash
# FlossWare VirtOS - Complete Build Pipeline
#
# Usage: ./build-all.sh [--non-interactive] [--profile <name>]
#
# Builds a complete VirtOS ISO from Tiny Core base with customizations.
# Runs in three phases: Prepare, Customize, Build ISO
#
# Options:
#   --non-interactive    Run without user prompts (for CI/CD)
#   --profile <name>     Override PROFILE in build.conf
#   --help               Show this help message

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$BUILD_DIR")"

NON_INTERACTIVE=false
OVERRIDE_PROFILE=""

# Parse command-line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --profile)
            OVERRIDE_PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            grep "^#" "$0" | head -15 | sed 's/^# //'
            exit 0
            ;;
        *)
            echo "ERROR: Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Export NON_INTERACTIVE so sub-scripts (iso.sh) can use it
export NON_INTERACTIVE

# Source and validate build configuration
if [ -f "$BUILD_DIR/build.conf" ]; then
    # shellcheck disable=SC1091
    source "$BUILD_DIR/build.conf"
else
    echo "ERROR: build.conf not found at $BUILD_DIR/build.conf" >&2
    exit 1
fi

# Validate profile name (prevent command injection)
validate_profile_name() {
    local profile="$1"
    # Profile names must be alphanumeric, hyphens, underscores only
    if ! echo "$profile" | grep -qE '^[a-zA-Z0-9_-]+$'; then
        echo "ERROR: Invalid profile name '$profile' (must contain only alphanumeric, hyphens, underscores)" >&2
        return 1
    fi
    # Check length (max 64 chars)
    if [ ${#profile} -gt 64 ]; then
        echo "ERROR: Profile name too long (max 64 characters)" >&2
        return 1
    fi
    return 0
}

# Override profile if specified on command line
if [ -n "$OVERRIDE_PROFILE" ]; then
    # Validate before using
    if ! validate_profile_name "$OVERRIDE_PROFILE"; then
        exit 1
    fi
    PROFILE="$OVERRIDE_PROFILE"
fi

# Validate and load profile if set
if [ -n "${PROFILE:-}" ]; then
    # Validate profile name format first (security)
    if ! validate_profile_name "$PROFILE"; then
        exit 1
    fi

    VALID_PROFILES="minimal standard full containers developer kubernetes storage"

    if ! echo " $VALID_PROFILES " | grep -q " $PROFILE "; then
        echo "ERROR: Invalid profile '$PROFILE'" >&2
        echo "" >&2
        echo "Valid profiles:" >&2
        for p in $VALID_PROFILES; do
            echo "  - $p" >&2
        done
        echo "" >&2
        echo "Edit build/build.conf to select a valid profile or use --profile" >&2
        exit 1
    fi

    # Load profile configuration to override build.conf settings
    if [ -f "$BUILD_DIR/profiles/$PROFILE.conf" ]; then
        # shellcheck disable=SC1090
        source "$BUILD_DIR/profiles/$PROFILE.conf"
    fi
fi

# Export PROFILE so sub-scripts can use it
export PROFILE

# Helper function for prompts
prompt_continue() {
    local prompt_msg="$1"
    if [ "$NON_INTERACTIVE" = true ]; then
        echo "$prompt_msg [auto-continuing]"
        return 0
    fi

    read -p "$prompt_msg [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1
    fi
    return 0
}

echo "=========================================="
echo "FlossWare VirtOS - Full Build Pipeline"
echo "=========================================="
echo ""
if [ -n "${PROFILE:-}" ]; then
    echo "Profile: $PROFILE"
else
    echo "Profile: custom"
fi
echo "Non-interactive: $NON_INTERACTIVE"
echo ""

# Step 1: Prepare
echo "Step 1/3: Preparing build environment..."
"$SCRIPT_DIR/prepare.sh"

if ! prompt_continue "Preparation complete. Continue to customization?"; then
    echo "Build stopped by user"
    exit 0
fi

# Step 2: Customize
echo ""
echo "Step 2/3: Customizing system..."
"$SCRIPT_DIR/customize.sh"

if ! prompt_continue "Customization complete. Continue to ISO build?"; then
    echo "Build stopped by user"
    exit 0
fi

# Step 3: Build ISO
echo ""
echo "Step 3/3: Building ISO..."
"$SCRIPT_DIR/iso.sh"

echo ""
echo "=========================================="
echo "Build pipeline complete!"
echo "=========================================="
