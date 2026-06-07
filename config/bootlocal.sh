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

# ========================================
# SSH Setup and Startup (Consolidated)
# ========================================
# All SSH configuration happens here to avoid race conditions
# See docs/issues/SSH_FIX_SUMMARY.md Root Cause #5

echo "=== SSH Setup ==="

# Step 1: Ensure openssh.tcz is loaded
if [ ! -x /usr/local/etc/init.d/openssh ]; then
    echo "OpenSSH not found, attempting to load..."
    if [ -f /tmp/tce/optional/openssh.tcz ]; then
        tce-load -i /tmp/tce/optional/openssh.tcz 2>&1 | tee -a /tmp/ssh-setup.log
        if [ ! -x /usr/local/etc/init.d/openssh ]; then
            echo "ERROR: Failed to load openssh.tcz" | tee -a /tmp/ssh-setup.log
            echo "  Check /tmp/ssh-setup.log for details"
        fi
    else
        echo "ERROR: openssh.tcz not found in /tmp/tce/optional/" | tee -a /tmp/ssh-setup.log
        echo "  SSH will not be available"
    fi
fi

# Step 2: Configure SSH (only if openssh loaded successfully)
if [ -x /usr/local/etc/init.d/openssh ]; then
    # Ensure config directory exists
    mkdir -p /usr/local/etc/ssh 2>/dev/null

    # Copy config from .orig if needed
    if [ -f /usr/local/etc/ssh/sshd_config.orig ]; then
        if [ ! -f /usr/local/etc/ssh/sshd_config ]; then
            echo "Installing sshd_config..."
            cp /usr/local/etc/ssh/sshd_config.orig /usr/local/etc/ssh/sshd_config
            chmod 600 /usr/local/etc/ssh/sshd_config
            echo "✓ SSH config installed"
        fi
    else
        echo "WARNING: sshd_config.orig not found" | tee -a /tmp/ssh-setup.log
    fi

    # Generate host keys if missing
    if [ ! -f /usr/local/etc/ssh/ssh_host_rsa_key ]; then
        echo "Generating SSH host keys..."
        if /usr/local/bin/ssh-keygen -A 2>&1 | tee -a /tmp/ssh-setup.log; then
            echo "✓ Host keys generated"
        else
            echo "ERROR: Failed to generate host keys" | tee -a /tmp/ssh-setup.log
        fi
    fi

    # Step 3: Start SSH daemon
    echo "Starting SSH daemon..."

    # Check if already running (prevent double-start)
    if ps | grep -v grep | grep sshd >/dev/null; then
        echo "⚠ SSH already running (started by bootsync.sh?)"
        pkill sshd  # Kill old instance to prevent conflicts
        sleep 1
    fi

    # Start sshd with error output
    if /usr/local/etc/init.d/openssh start 2>&1 | tee -a /tmp/ssh-setup.log; then
        sleep 2

        # Verify it's actually running
        if ps | grep -v grep | grep sshd >/dev/null; then
            echo "✓ SSH running (port 22)"

            # Show listening ports for debugging
            netstat -ln 2>/dev/null | grep ":22 " && echo "  Listening on port 22"
        else
            echo "ERROR: SSH daemon failed to start" | tee -a /tmp/ssh-setup.log
            echo "  Check /tmp/ssh-setup.log and /var/log/messages"
            echo "  Telnet is available as fallback (port 23)"
        fi
    else
        echo "ERROR: Failed to start SSH daemon" | tee -a /tmp/ssh-setup.log
        echo "  Check /tmp/ssh-setup.log for details"
    fi
else
    echo "⚠ OpenSSH not available - using telnet only (port 23)"
fi

echo "=== SSH Setup Complete ==="
echo ""

# Start simple HTTP server for debugging (busybox httpd)
echo "Starting HTTP server on port 80..."
cd /tmp
httpd -p 80 -h /tmp 2>/dev/null &
sleep 1

echo "=== FlossWare VirtOS Ready ==="
date >> /tmp/bootlocal-ran.txt
echo "Reached end of bootlocal.sh" >> /tmp/bootlocal-ran.txt
