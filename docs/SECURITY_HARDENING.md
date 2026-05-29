# VirtOS Security Hardening Guide

**Version**: 1.0  
**Last Updated**: 2026-05-29  
**Status**: Production Guidance

## Overview

This document provides security hardening recommendations for VirtOS deployments. Following these guidelines will significantly improve your security posture and help achieve compliance with common security frameworks.

**Target Audience**: System administrators, security engineers, DevOps teams

## Quick Start Checklist

Use this checklist for rapid hardening assessment:

### Pre-Deployment ✅
- [ ] Review security requirements
- [ ] Plan network segmentation
- [ ] Design access control policies
- [ ] Prepare secrets management
- [ ] Document security architecture

### Initial Hardening ✅
- [ ] Change default passwords
- [ ] Configure firewall rules
- [ ] Enable audit logging
- [ ] Set up encrypted storage
- [ ] Configure secure boot (if supported)

### Post-Deployment ✅
- [ ] Enable monitoring and alerting
- [ ] Configure log retention
- [ ] Test backup/restore
- [ ] Run security scans
- [ ] Document configuration

### Ongoing Maintenance ✅
- [ ] Apply security updates
- [ ] Review audit logs weekly
- [ ] Rotate credentials quarterly
- [ ] Test disaster recovery annually
- [ ] Update documentation

## System Hardening

### 1. Boot Security

#### Secure Boot
**Purpose**: Prevent unauthorized OS modifications

**Recommendations**:
```bash
# Check if secure boot is enabled (UEFI systems)
mokutil --sb-state

# Expected: SecureBoot enabled
```

**VirtOS Status**: ⚠️ Depends on hardware
- UEFI systems: Can enable secure boot
- BIOS systems: Not available

**Best Practice**: Use UEFI hardware with secure boot support

#### GRUB Password Protection
**Purpose**: Prevent unauthorized boot parameter changes

**Implementation**:
```bash
# Generate password hash
grub-mkpasswd-pbkdf2

# Add to /boot/grub/grub.cfg
set superusers="admin"
password_pbkdf2 admin <hash>
```

**VirtOS Status**: ⚠️ Manual configuration required

#### Kernel Parameters
**Purpose**: Harden kernel security

**Recommended Parameters**:
```bash
# Add to bootloader configuration
kernel.yama.ptrace_scope=1           # Restrict ptrace
kernel.kptr_restrict=2               # Hide kernel pointers
kernel.dmesg_restrict=1              # Restrict dmesg
kernel.unprivileged_bpf_disabled=1   # Disable unprivileged BPF
net.core.bpf_jit_harden=2            # Harden BPF JIT
```

**Apply**:
```bash
# Add to /etc/sysctl.conf
cat >> /etc/sysctl.conf <<EOF
kernel.yama.ptrace_scope=1
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
kernel.unprivileged_bpf_disabled=1
net.core.bpf_jit_harden=2
EOF

# Apply immediately
sysctl -p
```

### 2. Filesystem Security

#### Mount Options
**Purpose**: Restrict filesystem capabilities

**Critical Mount Options**:
```bash
# /tmp with restrictions
/dev/sda1 /tmp ext4 defaults,nodev,nosuid,noexec 0 2

# /var/tmp with restrictions
/dev/sda2 /var/tmp ext4 defaults,nodev,nosuid,noexec 0 2

# /home with restrictions
/dev/sda3 /home ext4 defaults,nodev,nosuid 0 2
```

**Explanation**:
- `nodev`: No device files
- `nosuid`: No SUID bit honored
- `noexec`: No execution allowed

#### File Permissions
**Purpose**: Least privilege access

**Critical Files**:
```bash
# Secure sensitive configuration
chmod 600 /etc/virtos/auth.conf
chmod 600 /etc/virtos/secrets.conf
chmod 644 /etc/virtos/*.conf  # Other configs

# Secure log files
chmod 640 /var/log/virtos/*.log
chown root:adm /var/log/virtos/*.log

# Secure management scripts
chmod 755 /usr/local/bin/virtos-*
chown root:root /usr/local/bin/virtos-*
```

#### Disk Encryption
**Purpose**: Protect data at rest

**LUKS Encryption** (recommended):
```bash
# Encrypt volume
cryptsetup luksFormat /dev/sda2

# Open encrypted volume
cryptsetup luksOpen /dev/sda2 virtos-data

# Mount
mount /dev/mapper/virtos-data /var/lib/libvirt
```

**VirtOS Integration**:
```bash
# Create encrypted VM disk
virtos-create-vm myvm --disk encrypted:50G

# Backup encrypted
virtos-backup myvm --encrypt
```

### 3. Network Security

#### Firewall Configuration
**Purpose**: Restrict network access

**Essential Rules** (iptables):
```bash
# Default deny
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH (change port from 22)
iptables -A INPUT -p tcp --dport 2222 -j ACCEPT

# libvirt management (local only)
iptables -A INPUT -p tcp -s 127.0.0.1 --dport 16509 -j ACCEPT

# VNC for VMs (restrict by IP)
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 5900:5999 -j ACCEPT

# VXLAN (cluster only)
iptables -A INPUT -p udp -s 192.168.100.0/24 --dport 4789 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

**nftables** (modern alternative):
```bash
# /etc/nftables.conf
table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        iif lo accept
        ct state established,related accept
        
        tcp dport 2222 accept  # SSH
        tcp dport 16509 ip saddr 127.0.0.1 accept  # libvirt
    }
}
```

#### Network Segmentation
**Purpose**: Isolate VM traffic

**Recommended Topology**:
```
┌─────────────────────────────────────────┐
│ Management Network (192.168.100.0/24)  │
│ - VirtOS hosts                          │
│ - Admin workstations                    │
└─────────────────────────────────────────┘
           │
┌─────────────────────────────────────────┐
│ VM Network (10.0.0.0/16)                │
│ - Isolated per tenant/project           │
│ - NAT or bridged to DMZ                 │
└─────────────────────────────────────────┘
           │
┌─────────────────────────────────────────┐
│ Storage Network (192.168.200.0/24)     │
│ - iSCSI, NFS, Ceph                      │
│ - No VM access                          │
└─────────────────────────────────────────┘
```

**Implementation**:
```bash
# Create isolated bridge
virtos-network create --name tenant1 --isolated \
    --subnet 10.1.0.0/24

# Create NAT bridge with restricted access
virtos-network create --name dmz --nat \
    --subnet 10.2.0.0/24 --forward-to eth1
```

#### SSH Hardening
**Purpose**: Secure remote access

**/etc/ssh/sshd_config**:
```bash
# Change default port
Port 2222

# Disable root login
PermitRootLogin no

# Key-based auth only
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no

# Disable empty passwords
PermitEmptyPasswords no

# Protocol 2 only
Protocol 2

# Limit users
AllowUsers admin ops

# Limit authentication attempts
MaxAuthTries 3
MaxSessions 5

# Timeouts
ClientAliveInterval 300
ClientAliveCountMax 2

# Strong ciphers only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,diffie-hellman-group-exchange-sha256

# Restart SSH
systemctl restart sshd
```

### 4. Access Control

#### User Management
**Purpose**: Principle of least privilege

**Best Practices**:
```bash
# Create admin group
groupadd virtos-admin

# Create operator group (read-only)
groupadd virtos-operator

# Add user to admin group
usermod -aG virtos-admin alice

# Add user to operator group
usermod -aG virtos-operator bob

# Configure sudoers
cat > /etc/sudoers.d/virtos <<EOF
# Admins can run all virtos commands
%virtos-admin ALL=(ALL) NOPASSWD: /usr/local/bin/virtos-*

# Operators can run read-only commands
%virtos-operator ALL=(ALL) NOPASSWD: /usr/local/bin/virtos-status
%virtos-operator ALL=(ALL) NOPASSWD: /usr/local/bin/virtos-monitor
EOF

chmod 440 /etc/sudoers.d/virtos
```

#### libvirt Access Control
**Purpose**: Restrict VM management

**Configuration**:
```bash
# /etc/libvirt/libvirtd.conf
unix_sock_group = "libvirt"
unix_sock_ro_perms = "0770"
unix_sock_rw_perms = "0770"
auth_unix_ro = "none"
auth_unix_rw = "polkit"

# Add users to libvirt group
usermod -aG libvirt alice

# Polkit rules (/etc/polkit-1/rules.d/50-libvirt.rules)
polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.manage" &&
        subject.isInGroup("virtos-admin")) {
        return polkit.Result.YES;
    }
});
```

#### RBAC (Future Enhancement)
**Status**: ⚠️ Not yet implemented (see Issue #116)

**Planned Roles**:
- **Super Admin**: Full system access
- **Admin**: VM management, no system changes
- **Operator**: VM start/stop, monitoring
- **Viewer**: Read-only access

### 5. Audit Logging

**Status**: ✅ Implemented (Issue #108)

**Configuration**:
```bash
# Enable audit logging
virtos-audit enable

# Configure retention
echo "90" > /etc/virtos/audit-retention-days

# View logs
virtos-audit query --since "2026-05-01"

# Export for SIEM
virtos-audit export --format json > /var/log/virtos/audit-export.json
```

**What's Logged**:
- VM lifecycle events (create, start, stop, delete)
- Configuration changes
- Authentication/authorization events
- Network and storage operations
- Security-sensitive actions

**Compliance**: PCI-DSS, HIPAA, SOX, GDPR

See: [AUDIT_LOGGING.md](AUDIT_LOGGING.md)

### 6. Secrets Management

**Status**: ⚠️ Partial implementation (see Issue #116)

**Current Capabilities**:
```bash
# Store secret (file-based)
virtos-secrets store myvm/password --file /tmp/password.txt

# Retrieve secret
virtos-secrets get myvm/password

# Rotate secret
virtos-secrets rotate myvm/password
```

**Limitations**:
- File-based storage (not as secure as Vault)
- No automatic rotation
- Limited access control

**Recommended**: Integrate HashiCorp Vault (planned)

### 7. VM Security

#### VM Isolation
**Purpose**: Prevent VM-to-VM attacks

**SELinux/AppArmor**:
```bash
# Enable SELinux (Fedora/RHEL)
setenforce 1
sed -i 's/SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# Verify VM confinement
ps -eZ | grep qemu

# Expected: system_u:system_r:svirt_t:s0:c...
```

#### Resource Limits
**Purpose**: Prevent resource exhaustion attacks

**Configuration**:
```bash
# CPU limits
virtos-quota set myvm --cpu-quota 80%

# Memory limits
virtos-quota set myvm --memory-limit 8G

# Disk I/O limits
virtos-quota set myvm --disk-read-iops 1000 --disk-write-iops 500

# Network bandwidth limits
virtos-quota set myvm --net-ingress 100M --net-egress 100M
```

#### VM Template Security
**Purpose**: Secure baseline images

**Best Practices**:
```bash
# Create hardened template
virtos-template create ubuntu-hardened --from ubuntu-22.04

# Apply hardening
virtos-template exec ubuntu-hardened <<'EOF'
# Remove unnecessary packages
apt-get purge -y telnet rsh-client

# Disable root login
passwd -l root

# Enable automatic updates
apt-get install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Configure firewall
ufw default deny incoming
ufw default allow outgoing
ufw enable

# Harden SSH (inside VM)
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
EOF

# Seal template
virtos-template seal ubuntu-hardened
```

## Compliance Frameworks

### CIS Benchmarks

**VirtOS Alignment**:

| CIS Control | VirtOS Implementation | Status |
|-------------|----------------------|--------|
| 1.1 Ensure separate partition | Manual configuration | ⚠️ |
| 1.2 Use encrypted filesystems | LUKS support | ✅ |
| 2.1 Ensure firewall enabled | iptables/nftables | ✅ |
| 3.1 Ensure SSH hardened | Manual configuration | ⚠️ |
| 4.1 Enable audit logging | virtos-audit | ✅ |
| 5.1 Restrict file permissions | virtos-common.sh | ✅ |
| 6.1 User account management | Manual | ⚠️ |
| 7.1 Network segmentation | virtos-network | ✅ |

**Legend**: ✅ Implemented | ⚠️ Manual configuration required

**Automated CIS Hardening** (future):
```bash
# Apply CIS Level 1 hardening
virtos-harden --profile cis-level-1

# Apply CIS Level 2 hardening (stricter)
virtos-harden --profile cis-level-2

# Audit compliance
virtos-harden --audit
```

### PCI-DSS

**Relevant Requirements**:

**Requirement 2.2**: Develop configuration standards
- ✅ This document provides baseline
- ⚠️ Need formal change control process

**Requirement 8**: Identify and authenticate users
- ✅ SSH key-based authentication
- ✅ Audit logging (virtos-audit)
- ⚠️ RBAC not yet implemented

**Requirement 10**: Track and monitor access
- ✅ Audit logging (virtos-audit)
- ✅ 90-day retention
- ✅ Log export for SIEM

**Requirement 11**: Test security regularly
- ⚠️ External security audit needed (Issue #116)
- ⚠️ Penetration testing required

### HIPAA

**Relevant Controls**:

**164.312(a)(1)**: Access Control
- ✅ User authentication
- ⚠️ RBAC needed for role-based access
- ✅ Audit logging

**164.312(b)**: Audit Controls
- ✅ virtos-audit implementation
- ✅ Activity logging
- ✅ Log retention

**164.312(c)(1)**: Integrity Controls
- ✅ File permissions
- ✅ Input validation (virtos-common.sh)
- ✅ Change tracking (git)

**164.312(d)**: Person or Entity Authentication
- ✅ SSH key authentication
- ✅ User attribution in logs

**164.312(e)(1)**: Transmission Security
- ✅ Encrypted channels (SSH, TLS)
- ⚠️ VNC encryption recommended

## Security Monitoring

### Log Monitoring

**Critical Logs**:
```bash
# System logs
/var/log/messages
/var/log/secure
/var/log/audit/audit.log

# VirtOS logs
/var/log/virtos/audit.log
/var/log/virtos/virtos-*.log
/var/log/libvirt/libvirtd.log
/var/log/libvirt/qemu/*.log
```

**Monitoring Commands**:
```bash
# Watch failed SSH attempts
tail -f /var/log/secure | grep "Failed password"

# Watch VM lifecycle events
virtos-audit query --filter "action=create,start,stop,delete"

# Watch permission denied errors
virtos-audit query --filter "result=failure"

# Daily security summary
virtos-audit summary --since "1 day ago"
```

### Intrusion Detection

**Host-based IDS** (recommended):

**AIDE** (Advanced Intrusion Detection Environment):
```bash
# Install
apt-get install aide  # Ubuntu/Debian
yum install aide      # RHEL/CentOS

# Initialize database
aide --init

# Check for changes
aide --check

# Add to cron
echo "0 2 * * * /usr/sbin/aide --check" > /etc/cron.d/aide
```

**OSSEC** (Host Intrusion Detection):
```bash
# Install agent
wget https://github.com/ossec/ossec-hids/releases/latest
./install.sh

# Configure
vi /var/ossec/etc/ossec.conf

# Start
/var/ossec/bin/ossec-control start
```

### Vulnerability Scanning

**Trivy** (Already in CI):
```bash
# Scan packages
trivy rootfs /

# Scan specific package
trivy fs /usr/local/bin/virtos-create-vm
```

**OpenVAS** (Comprehensive scanning):
```bash
# Run external scan from another host
openvas-cli -h virtos.example.com
```

## Incident Response

### Preparation

**Response Team**:
- Security lead
- System administrator
- Network administrator
- Management representative

**Contact Information**:
```bash
# /etc/virtos/incident-response.conf
SECURITY_LEAD_EMAIL="security@example.com"
SECURITY_LEAD_PHONE="+1-555-0001"
ADMIN_EMAIL="admin@example.com"
ADMIN_PAGER="555-0002"
```

### Detection

**Indicators of Compromise** (IOCs):
- Unexpected VM creation
- Permission denied errors (brute force)
- Unusual network traffic
- Resource exhaustion
- Failed authentication attempts
- New user accounts

**Automated Alerting**:
```bash
# Alert on failed logins
virtos-monitor alert --trigger "failed-login-count > 5" \
    --action "email security@example.com"

# Alert on VM creation
virtos-monitor alert --trigger "vm-created" \
    --action "email admin@example.com"

# Alert on high CPU
virtos-monitor alert --trigger "cpu-usage > 90%" \
    --action "email ops@example.com"
```

### Containment

**Immediate Actions**:
```bash
# Isolate compromised VM
virtos-network isolate <vm-name>

# Suspend compromised VM
virsh suspend <vm-name>

# Take snapshot for forensics
virtos-snapshot create <vm-name> --name incident-$(date +%s)

# Block attacker IP
iptables -A INPUT -s <attacker-ip> -j DROP
```

### Eradication

**Steps**:
1. Identify root cause
2. Patch vulnerabilities
3. Remove malware/backdoors
4. Rebuild compromised systems
5. Update firewall rules

### Recovery

**Steps**:
1. Restore from clean backup
2. Verify integrity
3. Monitor for reinfection
4. Update documentation

**Restore from Backup**:
```bash
# Restore VM
virtos-backup restore <vm-name> --from <backup-date>

# Verify integrity
virtos-snapshot diff <vm-name> --baseline <clean-snapshot>
```

### Post-Incident

**Actions**:
1. Document incident
2. Conduct lessons learned
3. Update procedures
4. Update security controls
5. Train team on findings

## Update Management

### System Updates

**Automatic Updates** (recommended):
```bash
# Configure unattended-upgrades (Ubuntu/Debian)
apt-get install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Configure automatic updates (RHEL/CentOS)
yum install yum-cron
systemctl enable yum-cron
systemctl start yum-cron
```

**Manual Updates**:
```bash
# VirtOS update
virtos-update check
virtos-update apply

# System updates
apt-get update && apt-get upgrade      # Ubuntu/Debian
yum update                              # RHEL/CentOS
```

### Patch Management

**Prioritization**:
1. **Critical**: Apply within 24 hours
2. **High**: Apply within 7 days
3. **Medium**: Apply within 30 days
4. **Low**: Apply during maintenance window

**Testing Process**:
1. Test in development environment
2. Test in staging environment
3. Apply to 10% of production
4. Monitor for issues
5. Roll out to remaining systems

## Security Benchmarking

### OpenSCAP

**Run Security Scan**:
```bash
# Install OpenSCAP
apt-get install libopenscap8   # Ubuntu/Debian
yum install openscap-scanner   # RHEL/CentOS

# Download security guide
wget https://github.com/ComplianceAsCode/content/releases/latest

# Run scan
oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_pci-dss \
    --results results.xml ssg-ubuntu2204-ds.xml

# Generate report
oscap xccdf generate report results.xml > security-report.html
```

### Lynis

**Security Audit**:
```bash
# Install Lynis
git clone https://github.com/CISOfy/lynis
cd lynis

# Run audit
./lynis audit system

# View results
cat /var/log/lynis.log

# Generate report
./lynis show report
```

## References

### VirtOS Documentation
- [Audit Logging](AUDIT_LOGGING.md)
- [Architecture](ARCHITECTURE.md)
- [Troubleshooting](TROUBLESHOOTING.md)

### External Resources
- **CIS Benchmarks**: https://www.cisecurity.org/cis-benchmarks/
- **NIST Cybersecurity Framework**: https://www.nist.gov/cyberframework
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **SANS Security**: https://www.sans.org/security-resources/

### Tools
- **Trivy**: https://github.com/aquasecurity/trivy
- **AIDE**: https://aide.github.io/
- **OSSEC**: https://www.ossec.net/
- **OpenSCAP**: https://www.open-scap.org/
- **Lynis**: https://cisofy.com/lynis/

## Changelog

### Version 1.0 (2026-05-29)
- Initial release
- Comprehensive hardening guidelines
- Compliance framework mapping
- Incident response procedures

---

**Last Updated**: 2026-05-29  
**Version**: 1.0  
**Related Issues**: #116 (Security Roadmap), #108 (Audit Logging)  
**Maintained By**: VirtOS Security Team
