#!/bin/sh
# FlossWare VirtOS - Early Boot Script
# This script runs during tc-config (before bootlocal.sh)
# Keep minimal - main SSH setup is in bootlocal.sh

# Set tc user password early (needed for both telnet and SSH fallback)
echo "tc:virtos" | chpasswd 2>/dev/null

# Start telnet as backup access (no auth, for debugging)
telnetd -l /bin/sh 2>/dev/null

# Note: SSH setup moved to bootlocal.sh to avoid race conditions
# See docs/issues/SSH_FIX_SUMMARY.md for details
