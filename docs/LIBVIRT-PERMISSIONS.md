# Fixing libvirt Permission Issues on Fedora

**Problem**: "Authentication required - system policy prevents management of local virtualized systems"

**Platform**: Fedora 44 (and similar Red Hat-based systems)

**Last Updated**: 2026-05-29

---

## Quick Fix (Most Common Solution)

**TL;DR**: Add your user to the `libvirt` group and log out/in.

```bash
# Add yourself to libvirt group
sudo usermod -aG libvirt $USER

# Log out and log back in
# OR use this to avoid logout:
newgrp libvirt

# Test it works
virsh list --all
```

✅ **This fixes the issue 90% of the time.**

---

## Understanding the Problem

### What's Happening

When you try to use `virsh`, `virt-manager`, or other libvirt tools, you get:

```text
error: authentication unavailable: no polkit agent available to authenticate action 'org.libvirt.unix.manage'
```

or

```text
Authentication required - system policy prevents management of local virtualized systems
```

### Why It Happens

- **libvirt** uses Unix sockets for communication: `/var/run/libvirt/libvirt-sock`
- This socket is owned by `root:libvirt` with permissions `srwxrwx---`
- Only users in the `libvirt` group can access it
- **PolicyKit** (polkit) enforces this access control

### What Doesn't Work

❌ Running with `sudo` all the time (bad security practice)  
❌ Changing socket permissions (reverted on reboot)  
❌ Using `qemu:///session` (limited functionality)

---

## Solution 1: Add User to libvirt Group (Recommended)

### Step 1: Add User to Group

```bash
# Add your current user
sudo usermod -aG libvirt $USER

# Verify you're in the group
groups $USER
# Should show: ... libvirt ...
```

### Step 2: Apply Group Changes

**Option A: Log out and log back in** (cleanest)

```bash
# Log out from your desktop session
# Log back in
```

**Option B: Use newgrp** (no logout needed)

```bash
# Start a new shell with the group active
newgrp libvirt

# Now run your virsh/virt-manager commands from this shell
```

**Option C: Restart your session** (for GUI)

```bash
# For GNOME
gnome-session-quit --no-prompt

# For KDE
qdbus org.kde.ksmserver /KSMServer logout 0 0 0
```

### Step 3: Restart libvirt Service

```bash
# Restart libvirt daemon
sudo systemctl restart libvirtd

# Enable it to start on boot (if not already)
sudo systemctl enable libvirtd
```

### Step 4: Verify It Works

```bash
# Test virsh (should work without sudo)
virsh list --all

# Output should be:
# Id   Name   State
# ----------------------
# (empty list is fine, no error is success)

# Test connection
virsh uri
# Should show: qemu:///system

# Test creating a network (real test)
virsh net-list --all
```

If all these work **without asking for password**, you're done! ✅

---

## Solution 2: Create PolicyKit Rule (Advanced)

If adding to the group doesn't work, create a PolicyKit rule.

### Step 1: Create libvirt Rule

```bash
# Create polkit rule for libvirt group
sudo tee /etc/polkit-1/rules.d/50-libvirt.rules > /dev/null <<'EOF'
/* Allow users in libvirt group to manage VMs without password */
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("libvirt")) {
            return polkit.Result.YES;
    }
});
EOF
```

### Step 2: Restart polkit

```bash
# Restart PolicyKit service
sudo systemctl restart polkit

# Verify the rule was loaded
pkaction --action-id org.libvirt.unix.manage --verbose
```

### Step 3: Test

```bash
# Test without sudo
virsh list --all

# Should work without password prompt
```

---

## Solution 3: User-Specific PolicyKit Rule

For a specific user (more restrictive, better security):

### Create User Rule

```bash
# Replace 'sfloess' with your username
sudo tee /etc/polkit-1/rules.d/80-libvirt-manage.rules > /dev/null <<EOF
/* Allow specific user to manage libvirt */
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.user == "$(whoami)") {
            return polkit.Result.YES;
    }
});
EOF

# Restart polkit
sudo systemctl restart polkit
```

### Test

```bash
virsh list --all
# Should work for your user only
```

---

## Solution 4: For virt-manager Specifically

If using `virt-manager` GUI:

### Step 1: Add to Both Groups

```bash
# Add to both libvirt and kvm groups
sudo usermod -aG libvirt,kvm $USER

# Verify
groups $USER
```

### Step 2: Configure libvirt Default URI

```bash
# Create libvirt config directory
mkdir -p ~/.config/libvirt

# Set default URI to qemu:///system
echo 'uri_default = "qemu:///system"' > ~/.config/libvirt/libvirt.conf
```

### Step 3: Launch virt-manager

```bash
# Log out and back in, then:
virt-manager

# Or use sg to test without logout:
sg libvirt -c virt-manager
```

---

## Verification Checklist

Run these commands to verify everything is configured correctly:

```bash
# 1. Check you're in libvirt group
groups $USER | grep libvirt
# ✅ Should show: ... libvirt ...

# 2. Check libvirt socket exists
ls -la /var/run/libvirt/libvirt-sock
# ✅ Should show: srwxrwx--- 1 root libvirt ...

# 3. Check libvirt is running
sudo systemctl status libvirtd
# ✅ Should show: active (running)

# 4. Test virsh connection
virsh list --all
# ✅ Should list VMs (or empty list) without error

# 5. Test virsh URI
virsh uri
# ✅ Should show: qemu:///system

# 6. Test creating a test VM (dry run)
virsh domcapabilities
# ✅ Should show XML capabilities without error
```

All ✅ = You're good to go!

---

## Troubleshooting

### Still Getting "Authentication Required"

**Problem**: Even after adding to group and logging out

**Solution**:

```bash
# 1. Check if libvirtd is actually running
sudo systemctl status libvirtd

# 2. If not running, start it
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# 3. Check socket permissions
ls -la /var/run/libvirt/libvirt-sock

# 4. If socket doesn't exist, libvirtd isn't running properly
# Check logs:
sudo journalctl -u libvirtd -n 50

# 5. Restart libvirt
sudo systemctl restart libvirtd
```

---

### "Connection refused" or "Failed to connect socket"

**Problem**: libvirtd not running or socket not accessible

**Solution**:

```bash
# Check libvirt is installed
rpm -qa | grep libvirt

# Install if missing
sudo dnf install @virtualization

# Start services
sudo systemctl start libvirtd
sudo systemctl start virtlogd
sudo systemctl start virtqemud

# Enable on boot
sudo systemctl enable libvirtd
```

---

### "No polkit agent available"

**Problem**: No authentication agent running (headless systems)

**Solution 1**: Install polkit agent (for GUI)

```bash
# For GNOME
sudo dnf install polkit-gnome

# For KDE
sudo dnf install polkit-kde
```

**Solution 2**: Use PolicyKit rules (headless)

```bash
# Create the rule (see Solution 2 above)
sudo tee /etc/polkit-1/rules.d/50-libvirt.rules > /dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("libvirt")) {
            return polkit.Result.YES;
    }
});
EOF

sudo systemctl restart polkit
```

---

### Group Membership Not Taking Effect

**Problem**: Added to group but still doesn't work

**Solution**:

```bash
# 1. Verify group was added
getent group libvirt
# Should show: libvirt:x:...:yourusername

# 2. Kill all your user processes (forces re-login)
sudo pkill -u $USER

# 3. Log back in

# 4. Verify group is active in current session
id | grep libvirt
# Should show: ... groups=...,libvirt,...

# 5. If still not showing, you MUST log out/in
# newgrp only works for that specific shell
```

---

### virt-manager Works, virsh Doesn't (or vice versa)

**Problem**: Inconsistent behavior between tools

**Solution**:

```bash
# 1. Check what URI each is using

# For virsh:
virsh uri
# Should show: qemu:///system

# For virt-manager, check connection details in GUI
# File → Add Connection → Check URI

# 2. Set consistent default
echo 'uri_default = "qemu:///system"' > ~/.config/libvirt/libvirt.conf

# 3. For virt-manager specifically
mkdir -p ~/.config/libvirt
cat > ~/.config/libvirt/libvirt.conf <<EOF
uri_default = "qemu:///system"
EOF
```

---

## Quick Reference Commands

### Check Status

```bash
# Am I in libvirt group?
groups | grep libvirt

# Is libvirtd running?
systemctl status libvirtd

# Can I connect?
virsh list --all

# What URI am I using?
virsh uri
```

### Fix Permissions

```bash
# Add to group
sudo usermod -aG libvirt $USER

# Apply without logout
newgrp libvirt

# Restart service
sudo systemctl restart libvirtd
```

### Emergency: Need Access NOW

```bash
# Run with group elevation (temporary)
sg libvirt -c "virsh list --all"
sg libvirt -c virt-manager

# Or run this shell session with the group
newgrp libvirt
# Now all commands in this shell have libvirt access
```

---

## Security Considerations

### Why Not Just Use sudo?

❌ **Bad Practice**:

```bash
# Don't do this every time
sudo virsh list --all
sudo virt-manager
```

**Why it's bad**:

- VMs run as root (security risk)
- Breaks file permissions
- Causes ownership issues
- Not how libvirt is designed

✅ **Correct Practice**:

```bash
# Add user to group once (one-time setup)
sudo usermod -aG libvirt $USER

# Then use without sudo
virsh list --all
virt-manager
```

### PolicyKit Rules vs Group Membership

| Approach | Security | Flexibility | Recommended |
|----------|----------|-------------|-------------|
| **libvirt group** | Good | Standard | ✅ Yes (most users) |
| **Polkit rule (group)** | Good | High | ✅ Yes (if group doesn't work) |
| **Polkit rule (user)** | Better | Low | ⚠️ Single user only |
| **Always sudo** | Poor | N/A | ❌ Never do this |

---

## For VirtOS Users

If you're testing VirtOS ISOs or virtos-* scripts:

### Before Building VirtOS

```bash
# 1. Install virtualization packages
sudo dnf install @virtualization

# 2. Add yourself to groups
sudo usermod -aG libvirt,kvm $USER

# 3. Log out and back in

# 4. Start services
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# 5. Verify
virsh list --all
# Should work without sudo
```

### Testing VirtOS

```bash
# Now you can test VirtOS ISOs
qemu-system-x86_64 -enable-kvm -m 2048 \
    -cdrom VirtOS-*.iso

# Or use virt-manager
virt-manager

# virtos-* scripts will also work
export PATH="$PWD/packages/virtos-tools/src/usr/local/bin:$PATH"
virtos-create-vm test --cpu 2 --ram 2048
```

---

## Related Documentation

- [libvirt Authentication](https://libvirt.org/auth.html)
- [PolicyKit Configuration](https://www.freedesktop.org/software/polkit/docs/latest/)
- [Fedora Virtualization Guide](https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/)
- [VirtOS Runtime Testing](../RUNTIME_TESTING_PLAN.md)

---

## Still Having Issues?

### Check Logs

```bash
# libvirt logs
sudo journalctl -u libvirtd -f

# polkit logs
sudo journalctl -u polkit -f

# System logs
sudo journalctl -xe
```

### Get Help

1. **VirtOS Issues**: <https://github.com/FlossWare/VirtOS/issues>
2. **Fedora Forums**: <https://discussion.fedoraproject.org/>
3. **libvirt Mailing List**: <https://libvirt.org/contact.html>

---

**Summary**: Add yourself to the `libvirt` group, log out and back in, and you're done!

```bash
sudo usermod -aG libvirt $USER
# Log out and log back in
virsh list --all  # Should work!
```
