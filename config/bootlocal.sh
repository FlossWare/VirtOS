#!/bin/sh
# FlossWare VirtOS - Boot Script
# This script runs at boot time to initialize the virtualization environment

echo "=== FlossWare VirtOS Initializing ==="

# Load KVM kernel modules
echo "Loading KVM modules..."
modprobe kvm
if grep -q "^flags.*vmx" /proc/cpuinfo; then
    echo "  Intel CPU detected, loading kvm-intel"
    modprobe kvm-intel
elif grep -q "^flags.*svm" /proc/cpuinfo; then
    echo "  AMD CPU detected, loading kvm-amd"
    modprobe kvm-amd
else
    echo "  WARNING: No virtualization extensions detected!"
fi

# Verify KVM is available
if [ -c /dev/kvm ]; then
    echo "  KVM ready: /dev/kvm"
    chmod 666 /dev/kvm  # Allow non-root access (adjust for security needs)
else
    echo "  ERROR: /dev/kvm not available"
fi

# Load networking modules
echo "Loading network modules..."
modprobe bridge
modprobe tun
modprobe vhost_net

# Basic network setup
echo "Configuring network..."
/sbin/ifconfig eth0 up
/sbin/udhcpc -i eth0 -b

# Create bridge for virtual machines
echo "Creating VM bridge (br0)..."
if ! brctl show | grep -q br0; then
    brctl addbr br0
    brctl setfd br0 0
    brctl stp br0 off
    ifconfig br0 up
fi

# Enable IP forwarding for NAT
echo "Enabling IP forwarding..."
echo 1 > /proc/sys/net/ipv4/ip_forward

# Set up iptables for NAT
echo "Configuring NAT for VMs/containers..."
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i br0 -j ACCEPT
iptables -A FORWARD -o br0 -j ACCEPT
iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

# Load TCE extensions (if using)
# tce-load -i qemu.tcz
# tce-load -i lxc.tcz
# tce-load -i containerd.tcz

# Set up libvirt group for remote access
echo "Configuring libvirt access..."
if ! grep -q "^libvirt:" /etc/group; then
    addgroup -g 112 libvirt 2>/dev/null || true
fi

# Start services
if [ -x /usr/local/etc/init.d/libvirtd ]; then
    echo "Starting libvirtd..."
    /usr/local/etc/init.d/libvirtd start
fi

# Start SSH for remote access
if [ -x /usr/local/etc/init.d/openssh ]; then
    echo "Starting SSH server..."
    /usr/local/etc/init.d/openssh start
fi

echo "=== FlossWare VirtOS Ready ==="
echo ""
echo "Available virtualization:"
echo "  - KVM/QEMU: " $(which qemu-system-x86_64 >/dev/null 2>&1 && echo "installed" || echo "not installed")
echo "  - LXC:      " $(which lxc-start >/dev/null 2>&1 && echo "installed" || echo "not installed")
echo "  - Containers:" $(which docker >/dev/null 2>&1 && echo "docker" || which podman >/dev/null 2>&1 && echo "podman" || echo "not installed")
echo ""
