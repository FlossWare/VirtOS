#!/bin/bash
# shellcheck disable=SC2001,SC2004,SC2016,SC2027,SC2034,SC2046,SC2050,SC2064,SC2140,SC2144,SC2155
# BATS Test Helper Functions
# Shared utilities for VirtOS BATS test suites
#
# Usage:
#   # In your .bats file:
#   load test_helper
#
# Available Functions:
#   - setup_test_environment()    # Common setup for all tests
#   - cleanup_test_vm(name)       # Clean up test VMs
#   - skip_if_not_root()          # Skip test if not running as root
#   - require_command(cmd)        # Skip if command not available
#   - find_project_root()         # Locate VirtOS project root
#   - get_virtos_script(name)     # Get path to virtos script

# Setup common test environment
# Call this in setup() function to prepare test environment
setup_test_environment() {
    # Set up PATH to include virtos scripts
    export PATH="${BATS_TEST_DIRNAME}/../config/custom-scripts:$PATH"

    # Create temp directory for test artifacts
    export TEST_TMP="$(mktemp -d)"

    # Ensure cleanup on exit
    trap "rm -rf $TEST_TMP" EXIT
}

# Skip test if not running as root
# Usage: skip_if_not_root
skip_if_not_root() {
    if [ "$(id -u)" -ne 0 ]; then
        skip "This test requires root privileges"
    fi
}

# Skip test if required command not available
# Usage: require_command virsh
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        skip "Required command not found: $cmd"
    fi
}

# Clean up test VM
# Usage: cleanup_test_vm test-vm
cleanup_test_vm() {
    local vm_name="$1"
    virsh destroy "$vm_name" 2>/dev/null || true
    virsh undefine "$vm_name" 2>/dev/null || true
}

# Find project root directory
# Returns path to VirtOS project root
find_project_root() {
    local dir="${BATS_TEST_DIRNAME}"
    while [ "$dir" != "/" ]; do
        if [ -f "$dir/VERSION" ] && [ -f "$dir/README.md" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Get path to virtos script
# Usage: script_path=$(get_virtos_script virtos-create-vm)
get_virtos_script() {
    local script_name="$1"
    local project_root

    project_root="$(find_project_root)"
    if [ -n "$project_root" ]; then
        echo "$project_root/config/custom-scripts/$script_name"
    else
        echo "$script_name"
    fi
}

# Check if running in VirtOS environment
is_virtos_environment() {
    [ -f /usr/local/share/virtos/VERSION ] || [ -d /usr/local/bin/virtos-* ]
}

# Get VirtOS version
get_virtos_version() {
    if [ -f /usr/local/share/virtos/VERSION ]; then
        cat /usr/local/share/virtos/VERSION
    elif [ -f "$(find_project_root)/VERSION" ]; then
        cat "$(find_project_root)/VERSION"
    else
        echo "unknown"
    fi
}
