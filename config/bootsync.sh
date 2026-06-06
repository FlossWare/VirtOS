#!/bin/sh
# FlossWare VirtOS - Boot Script
# This script runs during tc-config and sets up SSH access

# Load openssh.tcz if it exists
if [ -f /tmp/tce/optional/openssh.tcz ]; then
    tce-load -i /tmp/tce/optional/openssh.tcz >/dev/null 2>&1
fi

# Set up SSH configuration and keys
if [ -x /usr/local/etc/init.d/openssh ]; then
    # Ensure config directory exists
    mkdir -p /usr/local/etc/ssh

    # Copy config from .orig if needed
    if [ -f /usr/local/etc/ssh/sshd_config.orig ] && [ ! -f /usr/local/etc/ssh/sshd_config ]; then
        cp /usr/local/etc/ssh/sshd_config.orig /usr/local/etc/ssh/sshd_config
    fi

    # Generate host keys if they don't exist
    if [ ! -f /usr/local/etc/ssh/ssh_host_rsa_key ]; then
        /usr/local/bin/ssh-keygen -A >/dev/null 2>&1
    fi

    # Set tc user password to 'virtos' for testing
    echo "tc:virtos" | chpasswd >/dev/null 2>&1

    # Start SSH daemon
    /usr/local/etc/init.d/openssh start >/dev/null 2>&1
fi

# Also start telnet as backup
telnetd -l /bin/sh >/dev/null 2>&1
