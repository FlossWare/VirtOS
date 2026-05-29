# VirtOS Plugin API

**Version**: 1.0  
**Last Updated**: 2026-05-29  
**Status**: Official

This document describes how to create custom plugins for VirtOS by writing your own `virtos-*` scripts that integrate seamlessly with the existing ecosystem.

## Overview

VirtOS uses a **modular plugin architecture** where all management commands are individual scripts that follow naming and interface conventions. This allows you to:

- ✅ Extend VirtOS with custom functionality
- ✅ Integrate third-party tools
- ✅ Add organization-specific workflows
- ✅ Package plugins as TCZ extensions

## Plugin Architecture

```text
┌─────────────────────────────────────────┐
│         VirtOS Core (virtos-tools)      │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Standard Scripts (virtos-*)     │  │
│  │  - virtos-create-vm              │  │
│  │  - virtos-network                │  │
│  │  - virtos-storage                │  │
│  └──────────────────────────────────┘  │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Common Libraries                │  │
│  │  - virtos-common.sh              │  │
│  │  - virtos-audit.sh               │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
           ↓ Plugin API
┌─────────────────────────────────────────┐
│      Custom Plugins (your code)         │
│                                         │
│  ┌──────────────────────────────────┐  │
│  │  Custom Scripts (virtos-*)       │  │
│  │  - virtos-backup-s3              │  │
│  │  - virtos-notify-slack           │  │
│  │  - virtos-compliance-check       │  │
│  └──────────────────────────────────┘  │
└─────────────────────────────────────────┘
```

## Plugin Conventions

### Naming Convention

**Rule**: All plugins must start with `virtos-` prefix

**Examples**:

- ✅ `virtos-backup-s3` - Backup VMs to AWS S3
- ✅ `virtos-notify-slack` - Send notifications to Slack
- ✅ `virtos-compliance-check` - Run compliance checks
- ❌ `s3-backup` - Wrong (no virtos- prefix)
- ❌ `my-custom-script` - Wrong (no virtos- prefix)

**Reason**: The `virtos-` prefix ensures:

- Easy discovery (`virtos-<tab>` shows all commands)
- Clear ownership (VirtOS ecosystem)
- No conflicts with system commands

### Location

**Standard Locations**:

- `/usr/local/bin/virtos-*` - Installed plugins
- `/opt/virtos/plugins/virtos-*` - Custom plugin directory
- `~/.local/bin/virtos-*` - User-specific plugins

**PATH Priority**:

1. `/usr/local/bin` (highest priority)
2. `/opt/virtos/plugins`
3. `~/.local/bin`

### File Permissions

```bash
# Make script executable
chmod +x virtos-myplugin

# Verify permissions
ls -l virtos-myplugin
# Should show: -rwxr-xr-x
```

## Plugin Template

### Basic Plugin

```bash
#!/bin/sh
# virtos-myplugin - Brief description of what this plugin does
#
# Usage: virtos-myplugin [options] [arguments]
# Description: Detailed explanation

set -e  # Exit on error

# Version
VERSION="1.0"

# Load common library (optional but recommended)
if [ -f /usr/local/lib/virtos-common.sh ]; then
    . /usr/local/lib/virtos-common.sh
fi

# Help function
show_help() {
    cat <<EOF
Usage: virtos-myplugin [OPTIONS] [ARGUMENTS]

Description of what this plugin does.

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version
    -n, --name      VM name (required)
    -f, --force     Force operation

EXAMPLES:
    virtos-myplugin --name web-1
    virtos-myplugin --help

ENVIRONMENT VARIABLES:
    VIRTOS_DEBUG    Enable debug output (set to 1)

EXIT CODES:
    0   Success
    1   Error
    2   Invalid arguments

AUTHOR:
    Your Name <your.email@example.com>

SEE ALSO:
    virtos-create-vm(1), virtos-backup(1)
EOF
}

# Main logic
main() {
    local vm_name=""
    local force=0

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "virtos-myplugin version $VERSION"
                exit 0
                ;;
            -n|--name)
                vm_name="$2"
                shift 2
                ;;
            -f|--force)
                force=1
                shift
                ;;
            *)
                echo "Error: Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                exit 2
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$vm_name" ]; then
        echo "Error: VM name is required (use --name)" >&2
        exit 1
    fi

    # SECURITY: Validate VM name (if using virtos-common.sh)
    if command -v validate_vm_name >/dev/null 2>&1; then
        if ! validate_vm_name "$vm_name" 2>/dev/null; then
            echo "Error: Invalid VM name '$vm_name'" >&2
            exit 1
        fi
    fi

    # Your plugin logic here
    echo "Processing VM: $vm_name"

    # Example: Check if VM exists
    if ! virsh list --all --name | grep -q "^${vm_name}$"; then
        echo "Error: VM '$vm_name' not found" >&2
        exit 1
    fi

    # Example: Do something with the VM
    echo "Plugin operation completed successfully"
}

# Entry point
main "$@"
```

### Advanced Plugin (with Common Library)

```bash
#!/bin/sh
# virtos-backup-s3 - Backup VMs to AWS S3
set -e

VERSION="1.0"

# Load common library
if [ -f /usr/local/lib/virtos-common.sh ]; then
    . /usr/local/lib/virtos-common.sh
else
    echo "Error: virtos-common.sh not found" >&2
    exit 1
fi

# Load audit library (optional)
if [ -f /usr/local/lib/virtos-audit.sh ]; then
    . /usr/local/lib/virtos-audit.sh
fi

show_help() {
    cat <<EOF
Usage: virtos-backup-s3 [OPTIONS] <vm-name>

Backup a VM to AWS S3 bucket.

OPTIONS:
    -b, --bucket <name>    S3 bucket name (required)
    -r, --region <region>  AWS region (default: us-east-1)
    -c, --compress         Compress backup before upload
    -h, --help             Show this help
    -v, --version          Show version

EXAMPLES:
    virtos-backup-s3 --bucket my-backups --compress web-1

ENVIRONMENT:
    AWS_ACCESS_KEY_ID      AWS access key
    AWS_SECRET_ACCESS_KEY  AWS secret key

EXIT CODES:
    0   Success
    1   Error
    2   Invalid arguments
EOF
}

backup_to_s3() {
    local vm_name="$1"
    local bucket="$2"
    local region="$3"
    local compress="$4"

    # SECURITY: Validate VM name
    if ! validate_vm_name "$vm_name"; then
        log_error "Invalid VM name: $vm_name"
        return 1
    fi

    # AUDIT: Log backup operation
    if command -v audit_log >/dev/null 2>&1; then
        audit_log "backup_s3" "start" "vm=$vm_name bucket=$bucket"
    fi

    # Check if VM exists
    if ! virsh list --all --name | grep -q "^${vm_name}$"; then
        log_error "VM not found: $vm_name"
        return 1
    fi

    # Create backup
    local backup_file="/tmp/${vm_name}-$(date +%Y%m%d-%H%M%S).qcow2"

    log_info "Creating backup: $backup_file"
    virsh dumpxml "$vm_name" > "${backup_file}.xml"

    # Get disk path
    local disk_path
    disk_path=$(virsh domblklist "$vm_name" | awk '/vda|sda/ {print $2}')

    if [ -z "$disk_path" ]; then
        log_error "Could not find disk for VM: $vm_name"
        return 1
    fi

    # Copy disk
    cp "$disk_path" "$backup_file"

    # Compress if requested
    if [ "$compress" -eq 1 ]; then
        log_info "Compressing backup..."
        gzip "$backup_file"
        backup_file="${backup_file}.gz"
    fi

    # Upload to S3
    log_info "Uploading to S3: s3://${bucket}/${vm_name}/"
    aws s3 cp "$backup_file" "s3://${bucket}/${vm_name}/" --region "$region"
    aws s3 cp "${backup_file}.xml" "s3://${bucket}/${vm_name}/" --region "$region"

    # Cleanup
    rm -f "$backup_file" "${backup_file}.xml"

    # AUDIT: Log completion
    if command -v audit_log >/dev/null 2>&1; then
        audit_log "backup_s3" "success" "vm=$vm_name bucket=$bucket"
    fi

    log_success "Backup completed: s3://${bucket}/${vm_name}/"
}

main() {
    local vm_name=""
    local bucket=""
    local region="us-east-1"
    local compress=0

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) show_help; exit 0 ;;
            -v|--version) echo "virtos-backup-s3 $VERSION"; exit 0 ;;
            -b|--bucket) bucket="$2"; shift 2 ;;
            -r|--region) region="$2"; shift 2 ;;
            -c|--compress) compress=1; shift ;;
            -*) echo "Error: Unknown option: $1" >&2; exit 2 ;;
            *) vm_name="$1"; shift ;;
        esac
    done

    # Validate required arguments
    if [ -z "$vm_name" ] || [ -z "$bucket" ]; then
        echo "Error: VM name and bucket are required" >&2
        show_help
        exit 2
    fi

    # Check dependencies
    if ! command -v aws >/dev/null 2>&1; then
        echo "Error: AWS CLI not installed" >&2
        exit 1
    fi

    backup_to_s3 "$vm_name" "$bucket" "$region" "$compress"
}

main "$@"
```

## Using Common Libraries

### virtos-common.sh Functions

```bash
# Load the library
. /usr/local/lib/virtos-common.sh

# Validation functions
validate_vm_name "web-1"           # Returns 0 if valid
validate_resource_name "my-pool"   # Validates pool/network names
validate_path "/var/lib/libvirt"   # Prevents path traversal

# Logging functions
log_info "Starting operation"      # Info message
log_warning "Potential issue"      # Warning message
log_error "Operation failed"       # Error message
log_success "Operation completed"  # Success message
log_debug "Debug info"             # Debug message (if VIRTOS_DEBUG=1)

# Utility functions
get_version                        # Returns current VirtOS version
require_root                       # Exit if not running as root
check_command virsh                # Check if command exists
```

### virtos-audit.sh Functions

```bash
# Load the library
. /usr/local/lib/virtos-audit.sh

# Audit logging
audit_log "operation" "status" "details"

# Examples
audit_log "vm_create" "start" "name=web-1 cpu=4 ram=8192"
audit_log "vm_create" "success" "name=web-1 uuid=abc-123"
audit_log "vm_delete" "failure" "name=web-1 error=permission_denied"
```

## Integration Points

### Calling Other VirtOS Commands

```bash
# Check if VM exists using virtos-list (if it exists)
if command -v virtos-list >/dev/null 2>&1; then
    vm_list=$(virtos-list)
fi

# Create VM using standard command
virtos-create-vm --name "$vm_name" --cpu 2 --ram 4096 --disk 20G

# Use libvirt directly (more reliable)
virsh list --all --name | grep -q "^${vm_name}$"
```

### TUI Integration

If you want your plugin to appear in `virtos-tui`:

```bash
# Contact maintainers to add your plugin to the menu
# Or fork virtos-tui and add your own menu item

# In virtos-tui (example):
dialog --menu "Custom Operations" 20 60 10 \
    "1" "My Plugin - Custom Operation" \
    "2" "Back"

case "$choice" in
    1)
        # Call your plugin
        virtos-myplugin --interactive
        ;;
esac
```

### API Integration

If you want to expose your plugin via `virtos-api`:

```bash
# Example: Add endpoint in virtos-api

handle_custom_endpoint() {
    local vm_name="$1"

    # Call your plugin
    if virtos-myplugin --name "$vm_name" --format json; then
        http_response "200 OK" "application/json" '{"status":"success"}'
    else
        http_response "500 Internal Server Error" "application/json" \
            '{"error":"Plugin failed"}'
    fi
}
```

## Packaging as TCZ Extension

### Directory Structure

```text
virtos-myplugin/
├── usr/
│   └── local/
│       └── bin/
│           └── virtos-myplugin
└── usr/
    └── local/
        └── share/
            └── doc/
                └── virtos-myplugin/
                    ├── README
                    └── LICENSE
```

### Build Script

```bash
#!/bin/bash
# build-plugin.sh

PLUGIN_NAME="virtos-myplugin"
VERSION="1.0"

# Create package directory
mkdir -p /tmp/${PLUGIN_NAME}/usr/local/bin
mkdir -p /tmp/${PLUGIN_NAME}/usr/local/share/doc/${PLUGIN_NAME}

# Copy files
cp ${PLUGIN_NAME} /tmp/${PLUGIN_NAME}/usr/local/bin/
chmod +x /tmp/${PLUGIN_NAME}/usr/local/bin/${PLUGIN_NAME}

# Add documentation
cat > /tmp/${PLUGIN_NAME}/usr/local/share/doc/${PLUGIN_NAME}/README <<EOF
${PLUGIN_NAME} - Custom VirtOS Plugin
Version: ${VERSION}
Description: Your plugin description
EOF

# Create TCZ package
cd /tmp
mksquashfs ${PLUGIN_NAME} ${PLUGIN_NAME}.tcz -noappend
md5sum ${PLUGIN_NAME}.tcz > ${PLUGIN_NAME}.tcz.md5.txt

# Create .info file
cat > ${PLUGIN_NAME}.tcz.info <<EOF
Title:          ${PLUGIN_NAME}.tcz
Description:    Custom VirtOS plugin
Version:        ${VERSION}
Author:         Your Name
Original-site:  https://github.com/yourusername/${PLUGIN_NAME}
Copying-policy: GPLv3
Size:           $(du -h ${PLUGIN_NAME}.tcz | cut -f1)
Extension_by:   your-github-username
Tags:           virtos plugin
Comments:       Custom plugin for VirtOS
Change-log:     ${VERSION} - Initial release
Current:        ${VERSION}
EOF

echo "Package created: ${PLUGIN_NAME}.tcz"
```

## Testing Your Plugin

### Manual Testing

```bash
# 1. Syntax check
bash -n virtos-myplugin

# 2. ShellCheck (if available)
shellcheck virtos-myplugin

# 3. Test help
./virtos-myplugin --help

# 4. Test version
./virtos-myplugin --version

# 5. Test with valid input
./virtos-myplugin --name test-vm

# 6. Test with invalid input
./virtos-myplugin --name "../etc/passwd"  # Should fail validation
./virtos-myplugin --name "test; rm -rf /" # Should fail validation
```

### Automated Tests (BATS)

```bash
# tests/virtos-myplugin.bats

@test "virtos-myplugin shows help" {
    run virtos-myplugin --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-myplugin shows version" {
    run virtos-myplugin --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ "version" ]]
}

@test "virtos-myplugin validates VM name" {
    run virtos-myplugin --name "../etc/passwd"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Invalid" ]]
}

@test "virtos-myplugin requires VM name" {
    run virtos-myplugin
    [ "$status" -eq 1 ]
    [[ "$output" =~ "required" ]]
}
```

## Security Best Practices

### Input Validation

```bash
# ALWAYS validate user input
validate_vm_name "$vm_name" || {
    echo "Error: Invalid VM name" >&2
    exit 1
}

# Use regex validation
if ! echo "$input" | grep -qE '^[a-zA-Z0-9_-]+$'; then
    echo "Error: Invalid input format" >&2
    exit 1
fi
```

### Command Injection Prevention

```bash
# BAD - Vulnerable to command injection
virsh start $vm_name

# GOOD - Quoted and validated
validate_vm_name "$vm_name" || exit 1
virsh start "$vm_name"

# BETTER - Use arrays for complex commands
cmd=(virsh start "$vm_name")
"${cmd[@]}"
```

### Path Traversal Prevention

```bash
# BAD - Vulnerable to path traversal
cat /var/lib/virtos/$filename

# GOOD - Validate no path traversal
case "$filename" in
    *../*|*./*)
        echo "Error: Path traversal detected" >&2
        exit 1
        ;;
esac
cat "/var/lib/virtos/$filename"

# BETTER - Use basename
safe_filename=$(basename "$filename")
cat "/var/lib/virtos/$safe_filename"
```

## Example Plugins

### 1. Slack Notifications

```bash
#!/bin/sh
# virtos-notify-slack - Send VM events to Slack
# Usage: virtos-notify-slack --vm web-1 --event started

send_slack_notification() {
    local vm_name="$1"
    local event="$2"
    local webhook_url="$SLACK_WEBHOOK_URL"

    curl -X POST "$webhook_url" \
        -H 'Content-Type: application/json' \
        -d "{\"text\":\"VM $vm_name: $event\"}"
}
```

### 2. Compliance Check

```bash
#!/bin/sh
# virtos-compliance-check - Check VM compliance
# Usage: virtos-compliance-check --vm web-1

check_compliance() {
    local vm_name="$1"
    local violations=0

    # Check CPU limit
    local cpu=$(virsh dominfo "$vm_name" | grep "CPU(s)" | awk '{print $2}')
    if [ "$cpu" -gt 8 ]; then
        echo "VIOLATION: CPU exceeds limit (max: 8, actual: $cpu)"
        violations=$((violations + 1))
    fi

    # Check memory limit
    local mem=$(virsh dominfo "$vm_name" | grep "Max memory" | awk '{print $3}')
    if [ "$mem" -gt 32768 ]; then
        echo "VIOLATION: Memory exceeds limit (max: 32GB, actual: ${mem}MB)"
        violations=$((violations + 1))
    fi

    return $violations
}
```

## Publishing Your Plugin

### 1. GitHub Repository

```text
your-plugin/
├── README.md
├── LICENSE
├── virtos-myplugin
├── build.sh
├── tests/
│   └── virtos-myplugin.bats
└── examples/
    └── example-usage.sh
```

### 2. Documentation

Include in README.md:

- Description and purpose
- Installation instructions
- Usage examples
- Dependencies
- License

### 3. Distribution

Options for distributing your plugin:

- GitHub releases (recommended)
- TCZ repository (packagecloud.io)
- Docker image with plugin pre-installed
- Direct download from your website

## Getting Help

### Resources

- **Core Documentation**: See docs/ARCHITECTURE.md
- **Security Guidelines**: See docs/SECURITY-HARDENING.md
- **Common Library**: Read /usr/local/lib/virtos-common.sh source
- **Examples**: Look at existing virtos-* scripts in /usr/local/bin

### Community

- **GitHub Issues**: <https://github.com/FlossWare/VirtOS/issues>
- **Discussions**: Use "plugin-development" label
- **Contributing**: See CONTRIBUTING.md

## Version History

- **1.0** (2026-05-29) - Initial plugin API documentation

---

**Questions?** File an issue: <https://github.com/FlossWare/VirtOS/issues>
