#!/bin/sh
# FlossWare VirtOS - Boot Script
# Loads TCZ packages and starts services

# Debug output to file
exec 2>/tmp/bootlocal-debug.log
set -x

# Marker file to prove this script ran
date > /tmp/bootlocal-ran.txt
echo "bootlocal.sh started" >> /tmp/bootlocal-ran.txt

echo "=== FlossWare VirtOS Initializing ==="

# Load TCZ packages if they exist
if [ -f /tmp/tce/onboot.lst ]; then
    echo "Loading TCZ packages..."
    while read pkg; do
        [ -z "$pkg" ] && continue
        case "$pkg" in \#*) continue ;; esac
        if [ -f "/tmp/tce/optional/$pkg" ]; then
            echo "  $pkg"
            tce-load -i "/tmp/tce/optional/$pkg" 2>&1 | grep -v "Only user tc" || true
        fi
    done < /tmp/tce/onboot.lst
    echo "TCZ loading complete"
fi

# Load KVM kernel modules (from kvm TCZ package)
modprobe kvm 2>/dev/null
grep -q "^flags.*vmx" /proc/cpuinfo && modprobe kvm-intel 2>/dev/null
grep -q "^flags.*svm" /proc/cpuinfo && modprobe kvm-amd 2>/dev/null

# Basic network (use tools from iproute2/bridge-utils TCZ)
/sbin/ifconfig eth0 up 2>/dev/null
/sbin/udhcpc -i eth0 -b >/dev/null 2>&1

# Start telnet for debugging (no auth, root shell)
echo "Starting telnet on port 23..."
telnetd -l /bin/sh -p 23 2>/dev/null || telnetd -l /bin/sh 2>/dev/null
sleep 1
netstat -ln 2>/dev/null | grep -q ":23 " && echo "✓ Telnet running (port 23)"

# Copy SSH config from .orig (openssh TCZ installs as .orig)
if [ -f /usr/local/etc/ssh/sshd_config.orig ] && [ ! -f /usr/local/etc/ssh/sshd_config ]; then
    cp /usr/local/etc/ssh/sshd_config.orig /usr/local/etc/ssh/sshd_config
    echo "Configured SSH"
fi

# Start SSH
if [ -x /usr/local/etc/init.d/openssh ]; then
    echo "Starting SSH..."
    /usr/local/etc/init.d/openssh start >/dev/null 2>&1
    sleep 2
    ps | grep -v grep | grep sshd >/dev/null && echo "✓ SSH running (port 22)"
fi

# Start simple HTTP server for debugging (busybox httpd)
echo "Starting HTTP server on port 80..."
cd /tmp
httpd -p 80 -h /tmp 2>/dev/null &
sleep 1

echo "=== FlossWare VirtOS Ready ==="
date >> /tmp/bootlocal-ran.txt
echo "Reached end of bootlocal.sh" >> /tmp/bootlocal-ran.txt
