#!/bin/bash
# VM Test Helper Functions
# Common functions for VM integration tests

# Wait for VM to reach a specific state
# Usage: wait_for_vm_state <vm-name> <expected-state> [timeout-seconds]
wait_for_vm_state() {
    local vm_name="$1"
    local expected_state="$2"
    local timeout="${3:-30}"
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        local current_state=$(virsh domstate "$vm_name" 2>/dev/null | tr '[:upper:]' '[:lower:]')

        if [[ "$current_state" =~ "$expected_state" ]]; then
            return 0
        fi

        sleep 1
        elapsed=$((elapsed + 1))
    done

    return 1
}

# Check if VM exists
# Usage: vm_exists <vm-name>
vm_exists() {
    local vm_name="$1"
    virsh list --all --name 2>/dev/null | grep -q "^${vm_name}\$"
}

# Get VM state
# Usage: get_vm_state <vm-name>
get_vm_state() {
    local vm_name="$1"
    virsh domstate "$vm_name" 2>/dev/null || echo "undefined"
}

# Force cleanup VM (for test teardown)
# Usage: force_cleanup_vm <vm-name>
force_cleanup_vm() {
    local vm_name="$1"

    if vm_exists "$vm_name"; then
        # Destroy if running
        virsh destroy "$vm_name" 2>/dev/null || true

        # Delete all snapshots
        virsh snapshot-list "$vm_name" --name 2>/dev/null | while read snapshot; do
            [ -n "$snapshot" ] && virsh snapshot-delete "$vm_name" "$snapshot" --metadata 2>/dev/null || true
        done

        # Undefine with storage cleanup
        virsh undefine "$vm_name" --remove-all-storage 2>/dev/null || true
    fi

    # Cleanup any orphaned disk files
    local disk_path="/var/lib/libvirt/images/${vm_name}.qcow2"
    if [ -f "$disk_path" ]; then
        sudo rm -f "$disk_path" 2>/dev/null || true
    fi
}

# Create test disk image
# Usage: create_test_disk <path> <size>
create_test_disk() {
    local path="$1"
    local size="$2"

    qemu-img create -f qcow2 "$path" "$size" >/dev/null 2>&1
}

# Get VM memory (in MiB)
# Usage: get_vm_memory <vm-name>
get_vm_memory() {
    local vm_name="$1"
    virsh dominfo "$vm_name" 2>/dev/null | grep "Max memory:" | awk '{print $3}'
}

# Get VM vCPU count
# Usage: get_vm_vcpu <vm-name>
get_vm_vcpu() {
    local vm_name="$1"
    virsh dominfo "$vm_name" 2>/dev/null | grep "CPU(s):" | awk '{print $2}'
}

# Check if snapshot exists
# Usage: snapshot_exists <vm-name> <snapshot-name>
snapshot_exists() {
    local vm_name="$1"
    local snapshot_name="$2"
    virsh snapshot-list "$vm_name" --name 2>/dev/null | grep -q "^${snapshot_name}\$"
}

# Count snapshots for VM
# Usage: count_snapshots <vm-name>
count_snapshots() {
    local vm_name="$1"
    virsh snapshot-list "$vm_name" --name 2>/dev/null | grep -v '^$' | wc -l
}

# Get VM disk path from XML
# Usage: get_vm_disk_path <vm-name>
get_vm_disk_path() {
    local vm_name="$1"
    virsh dumpxml "$vm_name" 2>/dev/null | grep -oP "(?<=<source file=').*?(?='/>)" | head -1
}

# Check if VM has network interface
# Usage: vm_has_network <vm-name>
vm_has_network() {
    local vm_name="$1"
    virsh dumpxml "$vm_name" 2>/dev/null | grep -q "<interface"
}

# Export helper functions
export -f wait_for_vm_state
export -f vm_exists
export -f get_vm_state
export -f force_cleanup_vm
export -f create_test_disk
export -f get_vm_memory
export -f get_vm_vcpu
export -f snapshot_exists
export -f count_snapshots
export -f get_vm_disk_path
export -f vm_has_network
