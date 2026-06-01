#!/usr/bin/env bats
# Functional tests for VM lifecycle (start, stop, status)

TEST_VM_NAME="virtos-test-lifecycle-$$"
TEST_VM_DISK="/var/tmp/virtos-test-lifecycle-$$.qcow2"

setup() {
    if [ "$EUID" -ne 0 ]; then
        skip "Tests require root privileges"
    fi

    if ! systemctl is-active --quiet libvirtd; then
        skip "libvirtd service not running"
    fi

    # Clean up any previous test VM
    if virsh list --all --name | grep -q "^${TEST_VM_NAME}$"; then
        virsh destroy "$TEST_VM_NAME" 2>/dev/null || true
        virsh undefine "$TEST_VM_NAME" --remove-all-storage 2>/dev/null || true
    fi
    rm -f "$TEST_VM_DISK"
}

teardown() {
    if virsh list --all --name | grep -q "^${TEST_VM_NAME}$"; then
        virsh destroy "$TEST_VM_NAME" 2>/dev/null || true
        virsh undefine "$TEST_VM_NAME" --remove-all-storage 2>/dev/null || true
    fi
    rm -f "$TEST_VM_DISK"
}

create_test_vm() {
    qemu-img create -f qcow2 "$TEST_VM_DISK" 5G

    cat > /tmp/test-vm-$$.xml <<EOF
<domain type='qemu'>
  <name>${TEST_VM_NAME}</name>
  <memory unit='MiB'>256</memory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
    <boot dev='hd'/>
  </os>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${TEST_VM_DISK}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
  </devices>
</domain>
EOF

    virsh define /tmp/test-vm-$$.xml
    rm -f /tmp/test-vm-$$.xml
}

@test "VM starts successfully" {
    create_test_vm

    # Start VM
    virsh start "$TEST_VM_NAME"

    # Verify VM is running
    virsh list --name | grep -q "^${TEST_VM_NAME}$"
    virsh domstate "$TEST_VM_NAME" | grep -q "running"
}

@test "VM can be stopped (shutdown)" {
    create_test_vm
    virsh start "$TEST_VM_NAME"

    # Destroy (force stop) VM
    virsh destroy "$TEST_VM_NAME"

    # Verify VM is stopped
    virsh domstate "$TEST_VM_NAME" | grep -q "shut off"
}

@test "VM status can be queried" {
    create_test_vm

    # Check stopped state
    virsh domstate "$TEST_VM_NAME" | grep -q "shut off"

    # Start VM
    virsh start "$TEST_VM_NAME"

    # Check running state
    virsh domstate "$TEST_VM_NAME" | grep -q "running"

    # Stop VM
    virsh destroy "$TEST_VM_NAME"

    # Check stopped state again
    virsh domstate "$TEST_VM_NAME" | grep -q "shut off"
}

@test "VM full lifecycle: create → start → stop → delete" {
    # 1. Create
    create_test_vm
    virsh list --all --name | grep -q "^${TEST_VM_NAME}$"

    # 2. Start
    virsh start "$TEST_VM_NAME"
    virsh domstate "$TEST_VM_NAME" | grep -q "running"

    # 3. Stop
    virsh destroy "$TEST_VM_NAME"
    virsh domstate "$TEST_VM_NAME" | grep -q "shut off"

    # 4. Delete
    virsh undefine "$TEST_VM_NAME"
    ! virsh list --all --name | grep -q "^${TEST_VM_NAME}$"
}

@test "multiple VMs can exist simultaneously" {
    local vm1="virtos-test-multi-1-$$"
    local vm2="virtos-test-multi-2-$$"
    local disk1="/var/tmp/virtos-test-multi-1-$$.qcow2"
    local disk2="/var/tmp/virtos-test-multi-2-$$.qcow2"

    # Create VM 1
    qemu-img create -f qcow2 "$disk1" 5G
    cat > /tmp/test-vm-1-$$.xml <<EOF
<domain type='qemu'>
  <name>${vm1}</name>
  <memory unit='MiB'>128</memory>
  <vcpu>1</vcpu>
  <os><type arch='x86_64' machine='pc'>hvm</type></os>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${disk1}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
  </devices>
</domain>
EOF
    virsh define /tmp/test-vm-1-$$.xml
    rm -f /tmp/test-vm-1-$$.xml

    # Create VM 2
    qemu-img create -f qcow2 "$disk2" 5G
    cat > /tmp/test-vm-2-$$.xml <<EOF
<domain type='qemu'>
  <name>${vm2}</name>
  <memory unit='MiB'>128</memory>
  <vcpu>1</vcpu>
  <os><type arch='x86_64' machine='pc'>hvm</type></os>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${disk2}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
  </devices>
</domain>
EOF
    virsh define /tmp/test-vm-2-$$.xml
    rm -f /tmp/test-vm-2-$$.xml

    # Verify both exist
    virsh list --all --name | grep -q "^${vm1}$"
    virsh list --all --name | grep -q "^${vm2}$"

    # Clean up
    virsh undefine "$vm1" 2>/dev/null || true
    virsh undefine "$vm2" 2>/dev/null || true
    rm -f "$disk1" "$disk2"
}
