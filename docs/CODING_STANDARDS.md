# VirtOS Coding Standards

**Version**: 1.0  
**Last Updated**: 2026-05-29  
**Status**: Official

This document defines coding standards and best practices for VirtOS development. Following these standards ensures consistency, maintainability, and quality across the codebase.

## Table of Contents

- [Shell Script Standards](#shell-script-standards)
- [File Organization](#file-organization)
- [Naming Conventions](#naming-conventions)
- [Code Style](#code-style)
- [Error Handling](#error-handling)
- [Security Practices](#security-practices)
- [Documentation](#documentation)
- [Testing](#testing)
- [Git Workflow](#git-workflow)

---

## Shell Script Standards

### Shebang

**Always use POSIX shell** (`/bin/sh`) for maximum compatibility:

```bash
#!/bin/sh
```

**Why**: Tiny Core Linux uses BusyBox ash, which is POSIX-compliant but not full bash. Using `/bin/sh` ensures scripts work everywhere.

**Avoid**: `#!/bin/bash` unless truly bash-specific features are required.

### Script Header

Every script must include a header comment:

```bash
#!/bin/sh
# virtos-example - Brief one-line description
#
# Usage: virtos-example [options] [arguments]
# Detailed description of what this script does

set -e  # Exit on error
```

**Required elements**:

- Script name and purpose
- Usage pattern
- Detailed description
- `set -e` for error handling

### Strict Mode

**Always** enable strict error handling:

```bash
set -e  # Exit immediately on error
```

**Optionally** use for debugging:

```bash
set -u  # Error on undefined variables (use cautiously)
set -x  # Print commands (debugging only)
```

---

## File Organization

### Directory Structure

```text
config/custom-scripts/
├── virtos-*                # Management scripts
└── lib/
    ├── virtos-common.sh    # Common functions
    └── virtos-audit.sh     # Audit logging
```

### Script Structure

Organize scripts in this order:

```bash
#!/bin/sh
# Header comment

# 1. Strict mode
set -e

# 2. Constants
VERSION="1.0"
CONFIG_FILE="/etc/virtos/config"

# 3. Load libraries
if [ -f /usr/local/lib/virtos-common.sh ]; then
    . /usr/local/lib/virtos-common.sh
fi

# 4. Function definitions
show_help() {
    # Help text
}

validate_input() {
    # Validation logic
}

main() {
    # Main logic
}

# 5. Argument parsing
case "${1:-}" in
    -h|--help) show_help; exit 0 ;;
    --version) echo "$VERSION"; exit 0 ;;
esac

# 6. Entry point
main "$@"
```

---

## Naming Conventions

### Scripts

**Format**: `virtos-<name>`

**Rules**:

- All lowercase
- Hyphen-separated words
- Descriptive, not abbreviated
- ✅ `virtos-create-vm`
- ❌ `virtos-cvm` (too short)
- ❌ `create_vm` (no virtos- prefix)

### Functions

**Format**: `snake_case`

```bash
# Good
validate_vm_name() {
    local vm_name="$1"
    # ...
}

# Bad - camelCase
validateVmName() {  # Wrong
    # ...
}
```

### Variables

**Format**: `snake_case` for local, `UPPER_CASE` for globals/constants

```bash
# Constants (readonly)
readonly VERSION="1.0"
readonly CONFIG_DIR="/etc/virtos"

# Global variables
CURRENT_VM=""
ERROR_COUNT=0

# Local variables
validate_input() {
    local vm_name="$1"
    local cpu_count="$2"
    # ...
}
```

**Always** use `local` for function variables:

```bash
# Good
process_vm() {
    local vm_name="$1"
    local status
    status=$(virsh domstate "$vm_name")
}

# Bad - pollutes global namespace
process_vm() {
    vm_name="$1"  # Wrong - no local
    status=$(virsh domstate "$vm_name")
}
```

---

## Code Style

### Indentation

**Use 4 spaces**, never tabs:

```bash
if [ "$status" = "running" ]; then
    echo "VM is running"
    if [ "$force" -eq 1 ]; then
        echo "Forcing shutdown"
    fi
fi
```

**EditorConfig** enforces this (see `.editorconfig`).

### Line Length

**Target**: 80 characters  
**Maximum**: 120 characters

Break long lines for readability:

```bash
# Good
virsh create-vm \
    --name "$vm_name" \
    --cpu "$cpu_count" \
    --ram "$ram_size"

# Also good - continuation in strings
cat <<EOF
This is a long message that needs to wrap
but remains readable in the source.
EOF
```

### Quoting

**Always quote variables**:

```bash
# Good
echo "VM name: $vm_name"
virsh start "$vm_name"

# Bad - word splitting issues
echo "VM name: $vm_name"  # OK here
virsh start $vm_name      # WRONG - could break on spaces
```

**Exception**: When you WANT word splitting:

```bash
# Intentional word splitting
options="--verbose --force"
command $options  # Correctly splits into two arguments
```

### Conditionals

**Use `[ ]` (POSIX)**, not `[[ ]]` (bash-specific):

```bash
# Good - POSIX
if [ "$status" = "running" ]; then
    echo "Running"
fi

# Bad - bash-specific
if [[ "$status" == "running" ]]; then  # Wrong
    echo "Running"
fi
```

**Use `-eq` for numbers, `=` for strings**:

```bash
# Numbers
if [ "$count" -eq 5 ]; then
    echo "Five"
fi

# Strings
if [ "$status" = "running" ]; then
    echo "Running"
fi
```

**Prefer `case` over multiple `if` statements**:

```bash
# Good
case "$action" in
    start) start_vm "$vm_name" ;;
    stop) stop_vm "$vm_name" ;;
    restart) restart_vm "$vm_name" ;;
    *) echo "Unknown action" >&2; exit 1 ;;
esac

# Less ideal
if [ "$action" = "start" ]; then
    start_vm "$vm_name"
elif [ "$action" = "stop" ]; then
    stop_vm "$vm_name"
# ... etc
fi
```

### Command Substitution

**Use `$(...)`, not backticks**:

```bash
# Good
current_date=$(date +%Y-%m-%d)
vm_count=$(virsh list --name | wc -l)

# Bad
current_date=`date +%Y-%m-%d`  # Wrong - hard to nest
```

---

## Error Handling

### Exit Codes

**Use meaningful exit codes**:

```bash
# 0 = success
# 1 = general error
# 2 = invalid arguments
# Other codes as needed
```

```bash
main() {
    if [ -z "$vm_name" ]; then
        echo "Error: VM name required" >&2
        return 2  # Invalid arguments
    fi

    if ! virsh list --all | grep -q "$vm_name"; then
        echo "Error: VM not found" >&2
        return 1  # General error
    fi

    return 0  # Success
}
```

### Error Messages

**All errors to stderr** using `>&2`:

```bash
# Good
echo "Error: Invalid VM name" >&2
log_error "Operation failed"  # virtos-common.sh

# Bad
echo "Error: Invalid VM name"  # Wrong - stdout
```

**Format**: `Error: <message>`

```bash
echo "Error: VM '$vm_name' not found" >&2
echo "Warning: High CPU usage detected" >&2
echo "Info: Starting backup process" >&2
```

### Error Handling Pattern

```bash
validate_input() {
    local vm_name="$1"

    # Validate
    if [ -z "$vm_name" ]; then
        echo "Error: VM name is required" >&2
        return 1
    fi

    if ! echo "$vm_name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
        echo "Error: Invalid VM name '$vm_name'" >&2
        return 1
    fi

    return 0
}

# Usage
if ! validate_input "$vm_name"; then
    exit 2
fi
```

---

## Security Practices

### Input Validation

**ALWAYS validate user input**:

```bash
# Use virtos-common.sh functions
if ! validate_vm_name "$vm_name"; then
    echo "Error: Invalid VM name" >&2
    exit 1
fi

# Or use regex
if ! echo "$vm_name" | grep -qE '^[a-zA-Z0-9_-]+$'; then
    echo "Error: Invalid VM name" >&2
    exit 1
fi
```

### Command Injection Prevention

**Quote all variables in commands**:

```bash
# Good
virsh start "$vm_name"
cp "$source_file" "$dest_file"

# Bad - command injection risk
virsh start $vm_name     # Wrong
eval "command $user_input"  # NEVER use eval with user input
```

### Path Traversal Prevention

**Block `../` and validate paths**:

```bash
# Check for path traversal
case "$filename" in
    *../*|*./*)
        echo "Error: Path traversal detected" >&2
        exit 1
        ;;
esac

# Or use basename
safe_name=$(basename "$user_filename")
process_file "/var/lib/virtos/$safe_name"
```

### Temporary Files

**Use `mktemp` for temp files**:

```bash
# Good
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT
echo "data" > "$temp_file"

# Bad - predictable path
temp_file="/tmp/myfile.$$"  # Risk of race conditions
```

---

## Documentation

### Function Comments

Document **complex** or **non-obvious** functions:

```bash
# Creates a VM disk image with specified format and size
# Arguments:
#   $1 - VM name (alphanumeric, hyphens, underscores)
#   $2 - Disk size (e.g., "20G", "500M")
#   $3 - Format (qcow2, raw, vmdk)
# Returns:
#   0 - Success
#   1 - Disk creation failed
#   2 - Invalid arguments
create_vm_disk() {
    local vm_name="$1"
    local disk_size="$2"
    local format="$3"

    # Implementation
}
```

**Don't over-document**. Simple functions don't need comments:

```bash
# Bad - obvious function
# Returns the current date
get_current_date() {
    date +%Y-%m-%d
}

# Good - name is self-documenting
get_current_date() {
    date +%Y-%m-%d
}
```

### Inline Comments

**Only for non-obvious logic**:

```bash
# Good - explains WHY
# Retry 3 times because network may be slow to initialize
for i in 1 2 3; do
    if ping -c 1 "$host" >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Bad - explains WHAT (code already shows this)
# Loop 3 times
for i in 1 2 3; do
    # Ping the host
    if ping -c 1 "$host" >/dev/null 2>&1; then
        break
    fi
    # Sleep for 2 seconds
    sleep 2
done
```

### Help Text

**Every script must have `--help`**:

```bash
show_help() {
    cat <<EOF
Usage: virtos-example [OPTIONS] <vm-name>

Description of what this script does.

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version
    -f, --force     Force operation

EXAMPLES:
    virtos-example web-1
    virtos-example --force db-server

EXIT CODES:
    0   Success
    1   Error
    2   Invalid arguments
EOF
}
```

---

## Testing

### Unit Tests (BATS)

Every script should have a BATS test file:

```bash
# tests/virtos-example.bats

@test "virtos-example shows help" {
    run virtos-example --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

@test "virtos-example validates VM name" {
    run virtos-example "../etc/passwd"
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Invalid" ]]
}

@test "virtos-example requires VM name" {
    run virtos-example
    [ "$status" -ne 0 ]
}
```

### Testing Checklist

Before committing:

- [ ] `bash -n script-name` (syntax check)
- [ ] `shellcheck script-name` (linting)
- [ ] `bats tests/script-name.bats` (unit tests)
- [ ] Manual testing with valid input
- [ ] Manual testing with invalid/malicious input
- [ ] `pre-commit run --all-files` (pre-commit hooks)

---

## Git Workflow

### Commit Messages

**Follow Conventional Commits**:

```text
type(scope): subject

body (optional)

footer (optional)
```

**Types**:

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style (formatting, no logic change)
- `refactor:` - Code restructuring
- `test:` - Adding/updating tests
- `chore:` - Maintenance (dependencies, build)

**Examples**:

```text
feat: add VM snapshot rollback to virtos-snapshot

Implements rollback functionality to restore VMs to previous snapshots.
Uses virsh snapshot-revert with domain handling.

Fixes #123
```

```text
fix: prevent command injection in virtos-create-vm

Validates VM names before passing to virsh commands.
Adds regex validation to block shell metacharacters.
```

### Branch Naming

```text
feature/short-description
fix/bug-description
docs/doc-update
refactor/component-name
```

### Pull Requests

- Use the PR template (`.github/pull_request_template.md`)
- Complete all checklist items
- Reference related issues
- Include test results

---

## Enforcement

### Automated Checks

**Pre-commit hooks** (`.pre-commit-config.yaml`):

- ShellCheck (shell linting)
- shfmt (shell formatting)
- Bashate (shell style)
- Markdown linting
- YAML linting
- Secret detection

**Install**:

```bash
pip install pre-commit
pre-commit install
pre-commit install --hook-type commit-msg
```

### CI Validation

**GitHub Actions** validates:

- Syntax (`bash -n`)
- ShellCheck errors
- File permissions
- Version consistency
- Security scanning

---

## Best Practices Summary

### DO

✅ Use `/bin/sh` shebang  
✅ Enable `set -e`  
✅ Quote all variables  
✅ Use `local` for function variables  
✅ Validate all user input  
✅ Send errors to stderr  
✅ Use meaningful exit codes  
✅ Document complex functions  
✅ Write unit tests  
✅ Run pre-commit hooks  

### DON'T

❌ Use bash-specific features without `/bin/bash`  
❌ Use unquoted variables  
❌ Use global variables in functions  
❌ Trust user input  
❌ Use `eval` with user input  
❌ Hardcode credentials  
❌ Use predictable temp file paths  
❌ Skip shellcheck  
❌ Commit without testing  
❌ Use `#!/bin/bash` unless necessary  

---

## Examples

### Good Script Template

See [docs/PLUGIN_API.md](PLUGIN_API.md) for complete plugin templates demonstrating these standards.

### Security Example

```bash
#!/bin/sh
# virtos-secure-example - Demonstrates security best practices

set -e

. /usr/local/lib/virtos-common.sh

process_vm() {
    local vm_name="$1"

    # SECURITY: Validate input
    if ! validate_vm_name "$vm_name"; then
        echo "Error: Invalid VM name" >&2
        return 1
    fi

    # SECURITY: Quote variables
    if ! virsh list --all --name | grep -q "^${vm_name}$"; then
        echo "Error: VM not found" >&2
        return 1
    fi

    # SECURITY: Use safe temp file
    local temp_file
    temp_file=$(mktemp)
    trap 'rm -f "$temp_file"' EXIT

    # Process VM
    virsh dumpxml "$vm_name" > "$temp_file"

    return 0
}

main() {
    local vm_name="$1"

    if [ -z "$vm_name" ]; then
        echo "Usage: $0 <vm-name>" >&2
        return 2
    fi

    process_vm "$vm_name"
}

main "$@"
```

---

## Common VirtOS Patterns

This section documents frequently-used patterns found across VirtOS scripts. Following these patterns ensures consistency and maintainability.

### Version Display Pattern

All virtos-* scripts use a centralized version function:

```bash
# Load common library for version function
if [ -f /usr/local/lib/virtos-common.sh ]; then
    . /usr/local/lib/virtos-common.sh
fi

# Get version with fallback
VERSION=$(get_version 2>/dev/null || echo "0.1")

# In argument parsing
case "${1:-}" in
    -v|--version|version)
        echo "virtos-example version $VERSION"
        exit 0
        ;;
esac
```

**Why**: Centralized version management allows version updates without modifying individual scripts.

### Help Display Pattern

Standard help text format using heredoc:

```bash
show_help() {
    cat <<EOF
Usage: virtos-example [OPTIONS] [ARGUMENTS]

Brief description of what this script does.

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    --option        Example option

ARGUMENTS:
    name            Example argument

EXAMPLES:
    virtos-example --option value
    virtos-example name

EXIT CODES:
    0    Success
    1    General error
    2    Invalid arguments
EOF
}

# In argument parsing
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
esac
```

**Why**: Consistent help format makes scripts easier to learn and use.

### Audit Logging Pattern

Optional audit logging for security-sensitive operations:

```bash
# Load audit library if available
if [ -f /usr/local/lib/virtos-audit.sh ]; then
    . /usr/local/lib/virtos-audit.sh
fi

# Log successful operation
if command_exists log_audit; then
    log_audit "vm_create" "name=$vm_name disk=$disk_size" "success"
fi

# Log failed operation
if command_exists log_audit; then
    log_audit "vm_create" "name=$vm_name error=$error_msg" "failure"
fi
```

**Why**: Provides audit trail for compliance without breaking scripts when audit library is unavailable.

### Common Library Loading Pattern

Two-location library loading for development and production:

```bash
SCRIPT_DIR="$(dirname "$0")"

# Try development location first, fall back to system location
if [ -f "$SCRIPT_DIR/../lib/virtos-common.sh" ]; then
    # shellcheck source=../lib/virtos-common.sh
    . "$SCRIPT_DIR/../lib/virtos-common.sh"
elif [ -f "/usr/local/lib/virtos-common.sh" ]; then
    . "/usr/local/lib/virtos-common.sh"
else
    echo "Error: virtos-common.sh library not found" >&2
    exit 1
fi
```

**Why**: Works in both development (config/custom-scripts/) and installed (/usr/local/bin/) environments.

### Input Validation Pattern

Use virtos-common.sh validation functions:

```bash
# Load common library
. /usr/local/lib/virtos-common.sh

# Validate VM name
if ! validate_vm_name "$vm_name"; then
    echo "Error: Invalid VM name '$vm_name'" >&2
    echo "VM names must be alphanumeric with hyphens/underscores" >&2
    exit 2
fi

# Validate path
if ! validate_path "$config_file"; then
    echo "Error: Invalid path '$config_file'" >&2
    exit 2
fi

# Validate port number
if ! validate_port "$port"; then
    echo "Error: Invalid port number '$port'" >&2
    echo "Port must be 1-65535" >&2
    exit 2
fi
```

**Why**: Centralized validation prevents security vulnerabilities like command injection and path traversal.

### Temporary File Pattern

Safe temporary file handling with automatic cleanup:

```bash
# Create temporary file
temp_file=$(mktemp) || {
    echo "Error: Failed to create temporary file" >&2
    exit 1
}

# Ensure cleanup on exit
trap 'rm -f "$temp_file"' EXIT INT TERM

# Use temporary file
echo "data" > "$temp_file"
process_file "$temp_file"

# Cleanup happens automatically via trap
```

**Why**: Prevents temporary file leaks and ensures cleanup even on script errors or interrupts.

### Dialog/Whiptail UI Pattern

TUI input with fallback to command-line prompts:

```bash
# Check for dialog availability
if command -v dialog >/dev/null 2>&1; then
    DIALOG="dialog"
elif command -v whiptail >/dev/null 2>&1; then
    DIALOG="whiptail"
else
    echo "Error: Neither dialog nor whiptail found" >&2
    exit 1
fi

# Simple input box
result=$($DIALOG --inputbox "Enter VM name:" 8 40 "" 3>&1 1>&2 2>&3) || exit 1

# Menu selection
choice=$($DIALOG --menu "Select action:" 15 50 5 \
    "1" "Create VM" \
    "2" "Delete VM" \
    "3" "List VMs" \
    3>&1 1>&2 2>&3) || exit 1
```

**Why**: Provides user-friendly TUI while remaining scriptable.

### Consistent Error Messages Pattern

Standard error handling with helpful context:

```bash
# Enable exit on error
set -e

# Function-level error handling
create_vm() {
    local vm_name="$1"

    # Check preconditions
    if virsh list --all --name | grep -q "^${vm_name}$"; then
        echo "Error: VM '$vm_name' already exists" >&2
        return 1
    fi

    # Perform operation with error context
    if ! virsh define /tmp/vm-config.xml; then
        echo "Error: Failed to define VM '$vm_name'" >&2
        echo "Check XML configuration in /tmp/vm-config.xml" >&2
        return 1
    fi

    echo "Successfully created VM '$vm_name'"
    return 0
}

# Main execution with error handling
main() {
    local vm_name="$1"

    if [ -z "$vm_name" ]; then
        echo "Error: VM name required" >&2
        echo "Usage: $0 <vm-name>" >&2
        return 2
    fi

    create_vm "$vm_name" || {
        echo "Failed to create VM, check errors above" >&2
        return 1
    }
}

main "$@"
```

**Why**: Provides clear error messages with actionable information for troubleshooting.

### Command Availability Check Pattern

Check for required commands before use:

```bash
# Single command check
if ! command -v virsh >/dev/null 2>&1; then
    echo "Error: virsh not found" >&2
    echo "Install libvirt: sudo apt install libvirt-clients" >&2
    exit 1
fi

# Multiple commands check
check_dependencies() {
    local missing=""

    for cmd in virsh qemu-img ssh; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing="$missing $cmd"
        fi
    done

    if [ -n "$missing" ]; then
        echo "Error: Missing required commands:$missing" >&2
        return 1
    fi

    return 0
}

check_dependencies || exit 1
```

**Why**: Provides clear error messages instead of cryptic "command not found" failures.

### Privilege Check Pattern

Verify script runs with appropriate privileges:

```bash
# Require root/sudo
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root" >&2
    echo "Try: sudo $0 $*" >&2
    exit 1
fi

# Require non-root
if [ "$(id -u)" -eq 0 ]; then
    echo "Error: This script should not be run as root" >&2
    exit 1
fi

# Check for sudo capability (for user-facing scripts)
if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo "Warning: This operation may require sudo privileges" >&2
fi
```

**Why**: Prevents permission errors and security issues from running with wrong privileges.

---

## References

- **Pre-commit Hooks**: [docs/PRE_COMMIT_HOOKS.md](PRE_COMMIT_HOOKS.md)
- **Security Hardening**: [docs/SECURITY-HARDENING.md](SECURITY-HARDENING.md)
- **Plugin Development**: [docs/PLUGIN_API.md](PLUGIN_API.md)
- **Contributing**: [
