#!/bin/sh
# Copyright (c) 2026 FlossWare
# Licensed under the GNU General Public License v3.0. See LICENSE file in the project root.
# VirtOS Common Functions Library
# Shared validation, error handling, and utility functions for virtos-* scripts
#
# Usage:
#   if [ -f /usr/local/lib/virtos-common.sh ]; then
#       . /usr/local/lib/virtos-common.sh
#   fi
#
# Available Validation Functions (use these to prevent injection attacks):
#   validate_hostname()      - Validates hostnames/domain names
#   validate_vm_name()       - Validates VM names (alphanumeric, hyphens, underscores)
#   validate_ip()            - Validates IPv4 addresses
#   validate_number()        - Validates positive integers
#   validate_disk_size()     - Validates disk sizes (e.g., 10G, 500M)
#   validate_path()          - Validates file paths (prevents command injection)
#   validate_network_mode()  - Validates network modes (nat, bridge, isolated)
#   sanitize_input()         - Removes dangerous characters from input
#
# See: https://github.com/FlossWare/VirtOS/issues/82

VERSION="1.0"

# Colors (if terminal supports it)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

#==============================================================================
# Version Management
#==============================================================================

# Get VirtOS version from system
# Tries multiple locations to find version information
# Returns: Version string (e.g., "0.13")
get_version() {
    # Try package metadata first (installed system)
    if [ -f /usr/local/share/virtos/VERSION ]; then
        cat /usr/local/share/virtos/VERSION
        return 0
    fi

    # Try system version file
    if [ -f /etc/virtos/version.txt ]; then
        grep '^Version:' /etc/virtos/version.txt | awk '{print $2}' | head -1
        return 0
    fi

    # Try TCE installed package info
    if [ -f /usr/local/tce.installed/virtos-tools ]; then
        grep 'Version' /usr/local/tce.installed/virtos-tools | head -1 | awk '{print $2}'
        return 0
    fi

    # Fallback version
    echo "0.13"
}

#==============================================================================
# Input Validation Functions
#==============================================================================

# Validate hostname (alphanumeric, dash, underscore only)
validate_hostname() {
    local hostname="$1"
    if [ -z "$hostname" ]; then
        return 1
    fi
    # Allow alphanumeric, dash, underscore, max 253 chars
    echo "$hostname" | grep -qE '^[a-zA-Z0-9_-]{1,253}$'
}

# Validate VM name (alphanumeric, dash, underscore only)
validate_vm_name() {
    local name="$1"
    if [ -z "$name" ]; then
        return 1
    fi
    # VM names: alphanumeric, dash, underscore, max 64 chars
    echo "$name" | grep -qE '^[a-zA-Z0-9_-]{1,64}$'
}

# Validate IP address
validate_ip() {
    local ip="$1"
    if [ -z "$ip" ]; then
        return 1
    fi
    # Basic IPv4 validation
    echo "$ip" | grep -qE '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

# Validate number (positive integer)
validate_number() {
    local num="$1"
    if [ -z "$num" ]; then
        return 1
    fi
    echo "$num" | grep -qE '^[0-9]+$'
}

# Validate disk size format (e.g., 20G, 500M, 1T)
validate_disk_size() {
    local size="$1"
    if [ -z "$size" ]; then
        return 1
    fi
    echo "$size" | grep -qE '^[0-9]+[KMGT]$'
}

# Validate path (no special chars that could be command injection)
validate_path() {
    local path="$1"
    if [ -z "$path" ]; then
        return 1
    fi
    # Disallow: ; & | $ ` < > ( ) { } [ ] ! \ " '
    echo "$path" | grep -qE '^[a-zA-Z0-9/_.-]+$'
}

# Sanitize input for shell commands (escape dangerous characters)
sanitize_input() {
    local input="$1"
    # Remove dangerous characters
    echo "$input" | tr -d ';|&$`<>(){}[]!\\\"'"'"
}

#==============================================================================
# Error Handling Functions
#==============================================================================

# Print error message and exit
die() {
    local msg="$1"
    local exit_code="${2:-1}"
    echo "${RED}Error: ${msg}${NC}" >&2
    exit "$exit_code"
}

# Print warning message (non-fatal)
warn() {
    local msg="$1"
    echo "${YELLOW}Warning: ${msg}${NC}" >&2
}

# Print info message
info() {
    local msg="$1"
    echo "${BLUE}${msg}${NC}"
}

# Print success message
success() {
    local msg="$1"
    echo "${GREEN}${msg}${NC}"
}

#==============================================================================
# Command Availability Checks
#==============================================================================

# Check if command exists
require_command() {
    local cmd="$1"
    local msg="${2:-Command '$cmd' is required but not found}"

    if ! command -v "$cmd" >/dev/null 2>&1; then
        die "$msg" 127
    fi
}

# Check if running as root
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        die "This command must be run as root. Use: sudo $0 $*" 1
    fi
}

# Check if libvirt is available
require_libvirt() {
    require_command virsh "libvirt is required. Install: apt install libvirt-daemon-system"

    # Check if libvirtd is running
    if ! systemctl is-active --quiet libvirtd 2>/dev/null; then
        warn "libvirtd service is not running"
        info "Start with: sudo systemctl start libvirtd"
    fi
}

# Check if qemu-img is available
require_qemu_img() {
    require_command qemu-img "qemu-img is required. Install: apt install qemu-utils"
}

#==============================================================================
# VM Operation Helpers
#==============================================================================

# Check if VM exists
vm_exists() {
    local vm_name="$1"
    virsh list --all --name 2>/dev/null | grep -qx "$vm_name"
}

# Check if VM is running
vm_is_running() {
    local vm_name="$1"
    virsh list --name 2>/dev/null | grep -qx "$vm_name"
}

# Get VM state
vm_state() {
    local vm_name="$1"
    virsh domstate "$vm_name" 2>/dev/null || echo "not-found"
}

# Require VM exists
require_vm_exists() {
    local vm_name="$1"
    if ! vm_exists "$vm_name"; then
        die "VM '$vm_name' not found. List VMs with: virsh list --all"
    fi
}

#==============================================================================
# Confirmation Prompts
#==============================================================================

# Ask yes/no question (returns 0 for yes, 1 for no)
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    if [ "$default" = "y" ]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    printf "%s" "$prompt"
    read -r response

    # Default if empty
    if [ -z "$response" ]; then
        response="$default"
    fi

    case "$response" in
        [Yy]|[Yy][Ee][Ss]) return 0 ;;
        *) return 1 ;;
    esac
}

# Confirm destructive operation
confirm_destructive() {
    local operation="$1"
    local target="$2"

    echo "${RED}WARNING: Destructive operation${NC}"
    echo "Operation: $operation"
    echo "Target: $target"
    echo ""

    if ! confirm "Are you absolutely sure you want to continue?" "n"; then
        echo "Operation cancelled."
        exit 0
    fi
}

#==============================================================================
# File/Directory Helpers
#==============================================================================

# Create directory with error handling
safe_mkdir() {
    local dir="$1"

    if ! validate_path "$dir"; then
        die "Invalid directory path: $dir"
    fi

    if ! mkdir -p "$dir" 2>/dev/null; then
        die "Failed to create directory: $dir"
    fi
}

# Check if file exists and is readable
require_file() {
    local file="$1"
    local msg="${2:-File not found: $file}"

    if [ ! -f "$file" ]; then
        die "$msg"
    fi

    if [ ! -r "$file" ]; then
        die "File not readable: $file"
    fi
}

#==============================================================================
# Logging
#==============================================================================

LOG_FILE="/var/log/virtos/virtos.log"

# Log message to file (if log directory exists)
log_message() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Only log if log directory exists
    if [ -d "/var/log/virtos" ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

log_info() {
    log_message "INFO" "$@"
}

log_warn() {
    log_message "WARN" "$@"
}

log_error() {
    log_message "ERROR" "$@"
}

#==============================================================================
# Network Validation
#==============================================================================

# Check if host is reachable
host_reachable() {
    local host="$1"
    local timeout="${2:-2}"
    ping -c 1 -W "$timeout" "$host" >/dev/null 2>&1
}

# Validate network mode
validate_network_mode() {
    local mode="$1"
    case "$mode" in
        bridged|bridge|nat|isolated|none) return 0 ;;
        *) return 1 ;;
    esac
}

#==============================================================================
# Resource Validation
#==============================================================================

# Check if system has enough free memory
check_free_memory() {
    local required_mb="$1"
    local free_mb=$(free -m | awk '/^Mem:/ {print $7}')

    if [ "$free_mb" -lt "$required_mb" ]; then
        warn "Low free memory: ${free_mb}MB available, ${required_mb}MB required"
        return 1
    fi
    return 0
}

# Check if system has enough free disk space
check_free_disk() {
    local path="$1"
    local required_mb="$2"
    local free_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

    if [ "$free_mb" -lt "$required_mb" ]; then
        warn "Low disk space on $path: ${free_mb}MB available, ${required_mb}MB required"
        return 1
    fi
    return 0
}

#==============================================================================
# Initialization
#==============================================================================

# Create log directory if it doesn't exist
if [ -w "/var/log" ] && [ ! -d "/var/log/virtos" ]; then
    mkdir -p "/var/log/virtos" 2>/dev/null || true
fi

# Export functions and variables for use by sourcing scripts
export RED GREEN YELLOW BLUE NC
