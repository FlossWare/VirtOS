#!/usr/bin/env bats
# Functional tests for VM creation (virtos-create-vm)

# Test VM configuration
TEST_VM_NAME="virtos-test-vm-$$"
TEST_VM_DISK="/var/tmp/virtos-test-vm-$$.qcow2"
TEST_VM_MEMORY="512"
TEST_VM_VCPUS="1"

setup() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        skip "Tests require root privileges (sudo bats ...)"
    fi

    # Check if libvirt is running
    if ! systemctl is-active --quiet libvirtd; then
        skip "libvirtd service not running"
    fi

    # Clean up any previous test VM
    if virsh list --all --name | grep -q "^${TEST_VM_NAME}$"; then
        virsh destroy "$TEST_VM_NAME" 2>/dev/null || true
        virsh undefine "$TEST_VM_NAME" --remove-all-storage 2>/dev/null || true
    fi
}

teardown() {
    # Clean up test VM and disk
    if virsh list --all --name | grep -q "^${TEST_VM_NAME}$"; then
        virsh destroy "$TEST_VM_NAME" 2>/dev/null || true
        virsh undefine "$TEST_VM_NAME" --remove-all-storage 2>/dev/null || true
    fi
    rm -f "$TEST_VM_DISK"
}

@test "libvirt is operational" {
    virsh version
    virsh list --all
}

@test "can create qcow2 disk image" {
    qemu-img create -f qcow2 "$TEST_VM_DISK" 10G
    [ -f "$TEST_VM_DISK" ]

    # Verify disk format
    qemu-img info "$TEST_VM_DISK" | grep -q "qcow2"
}

@test "can define VM from XML" {
    # Create minimal VM XML
    cat > /tmp/test-vm-$$.xml <<EOF
<domain type='qemu'>
  <name>${TEST_VM_NAME}</name>
  <memory unit='MiB'>${TEST_VM_MEMORY}</memory>
  <vcpu placement='static'>${TEST_VM_VCPUS}</vcpu>
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
    <interface type='network'>
      <source network='default'/>
      <model type='virtio'/>
    </interface>
    <graphics type='vnc' port='-1' autoport='yes'/>
    <console type='pty'/>
  </devices>
</domain>
EOF

    # Create disk
    qemu-img create -f qcow2 "$TEST_VM_DISK" 10G

    # Define VM
    virsh define /tmp/test-vm-$$.xml
    rm -f /tmp/test-vm-$$.xml

    # Verify VM exists
    virsh list --all --name | grep -q "^${TEST_VM_NAME}$"
}

@test "can get VM info" {
    # Create and define test VM
    qemu-img create -f qcow2 "$TEST_VM_DISK" 10G
    cat > /tmp/test-vm-$$.xml <<EOF
<domain type='qemu'>
  <name>${TEST_VM_NAME}</name>
  <memory unit='MiB'>${TEST_VM_MEMORY}</memory>
  <vcpu placement='static'>${TEST_VM_VCPUS}</vcpu>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
  </os>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${TEST_VM_DISK}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
  </devices>
</domain>
EOF
    virsh define /tmp/test-vm-$$.xml
    rm -f /tmp/test-vm-$$.xml

    # Get VM info
    virsh dominfo "$TEST_VM_NAME"
    virsh dominfo "$TEST_VM_NAME" | grep -q "Name:.*${TEST_VM_NAME}"
}

@test "can delete (undefine) VM" {
    # Create and define test VM
    qemu-img create -f qcow2 "$TEST_VM_DISK" 10G
    cat > /tmp/test-vm-$$.xml <<EOF
<domain type='qemu'>
  <name>${TEST_VM_NAME}</name>
  <memory unit='MiB'>${TEST_VM_MEMORY}</memory>
  <vcpu placement='static'>${TEST_VM_VCPUS}</vcpu>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
  </os>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
  </devices>
</domain>
EOF
    virsh define /tmp/test-vm-$$.xml
    rm -f /tmp/test-vm-$$.xml

    # Verify VM exists
    virsh list --all --name | grep -q "^${TEST_VM_NAME}$"

    # Delete VM
    virsh undefine "$TEST_VM_NAME"

    # Verify VM is gone
    ! virsh list --all --name | grep -q "^${TEST_VM_NAME}$"
}

@test "VM creation full workflow" {
    # 1. Create disk
    qemu-img create -f qcow2 "$TEST_VM_DISK" 10G
    [ -f "$TEST_VM_DISK" ]

    # 2. Create VM XML
    cat > /tmp/test-vm-$$.xml <<EOF
<domain type='qemu'>
  <name>${TEST_VM_NAME}</name>
  <memory unit='MiB'>${TEST_VM_MEMORY}</memory>
  <vcpu placement='static'>${TEST_VM_VCPUS}</vcpu>
  <os>
    <type arch='x86_64' machine='pc'>hvm</type>
  </os>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${TEST_VM_DISK}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
  </devices>
</domain>
EOF

    # 3. Define VM
    virsh define /tmp/test-vm-$$.xml
    rm -f /tmp/test-vm-$$.xml

    # 4. Verify VM exists and is stopped
    virsh list --all --name | grep -q "^${TEST_VM_NAME}$"
    virsh domstate "$TEST_VM_NAME" | grep -q "shut off"

    # 5. Get VM info
    virsh dominfo "$TEST_VM_NAME" | grep -q "Name:.*${TEST_VM_NAME}"

    # 6. Clean up
    virsh undefine "$TEST_VM_NAME"
    ! virsh list --all --name | grep -q "^${TEST_VM_NAME}$"
}
