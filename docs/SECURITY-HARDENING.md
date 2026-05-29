# VirtOS Security Hardening Guide

**Last Updated**: 2026-05-29  
**Security Level**: Production Deployment

**Recent Updates**:
- ✅ **2026-05-29**: Comprehensive input validation audit completed (Issue #96)
  - All management scripts validated (virtos-network, virtos-storage, virtos-backup)
  - Command injection prevention implemented
  - 9 functions secured across 3 critical scripts

## Overview

This guide provides comprehensive security hardening procedures for VirtOS hosts and virtual machines. Follow these recommendations before deploying to production.

## Security Layers

VirtOS security operates at multiple layers:

```
┌─────────────────────────────────────────┐
│   Application Security (in VMs)         │
├─────────────────────────────────────────┤
│   VM Isolation & Hardening              │
├─────────────────────────────────────────┤
│   Host Operating System Security        │
├─────────────────────────────────────────┤
│   Network Security & Firewalls          │
├─────────────────────────────────────────┤
│   Physical Security & Access Control    │
└─────────────────────────────────────────┘
```

## Pre-Deployment Security Checklist

Complete before production deployment:

### Critical (Must Complete)

- [ ] Enable SELinux or AppArmor
- [ ] Configure host firewall (iptables/nftables)
- [ ] Disable root SSH login
- [ ] Set up SSH key authentication only
- [ ] Change all default passwords
- [ ] Enable audit logging
- [ ] Configure NTP for accurate timestamps
- [ ] Set up centralized logging
- [ ] Enable automatic security updates
- [ ] Configure secrets manager (virtos-secrets)

### Recommended

- [ ] Enable disk encryption
- [ ] Set up intrusion detection (IDS)
- [ ] Configure file integrity monitoring
- [ ] Enable VM network isolation
- [ ] Set up backup encryption
- [ ] Configure security monitoring alerts
- [ ] Document security policies
- [ ] Train administrators on security

## Host Operating System Hardening

### 1. Kernel Security Parameters

```bash
# Edit sysctl configuration
sudo vi /etc/sysctl.conf

# Add security parameters
# Restrict kernel messages
kernel.dmesg_restrict=1
kernel.kptr_restrict=2

# Network security
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1
net.ipv4.tcp_syncookies=1

# IPv6 (if not needed, disable it)
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1

# Apply settings
sudo sysctl -p
```

### 2. Disable Unnecessary Services

```bash
# List running services
systemctl list-units --type=service --state=running

# Disable unnecessary services (examples)
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon

# Keep only essential services:
# - sshd (remote access)
# - libvirtd (virtualization)
# - firewalld/iptables (firewall)
# - chronyd/ntpd (time sync)
```

### 3. SELinux/AppArmor Configuration

#### For SELinux (Red Hat/CentOS based)

```bash
# Check SELinux status
getenforce
# Should show: Enforcing

# If disabled, enable it
sudo vi /etc/selinux/config
# Set: SELINUX=enforcing

# Reboot to apply
sudo reboot

# Install libvirt SELinux policies
sudo yum install libvirt-selinux

# Verify libvirt context
ps auxZ | grep libvirt
```

#### For AppArmor (Debian/Ubuntu based - Tiny Core alternative)

```bash
# Note: Tiny Core Linux doesn't have AppArmor by default
# Alternative: Use namespace isolation and seccomp

# Enable strict seccomp for QEMU
sudo vi /etc/libvirt/qemu.conf

# Add:
seccomp_sandbox = 1
```

### 4. Firewall Configuration

```bash
# Install iptables (if not present)
tce-load -wi iptables

# Create firewall rules script
sudo vi /opt/firewall.sh

#!/bin/sh
# VirtOS Firewall Configuration

# Default policies: DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH (from specific IP range if possible)
iptables -A INPUT -p tcp --dport 22 -s 192.168.1.0/24 -j ACCEPT

# Allow libvirt management (from specific IPs)
iptables -A INPUT -p tcp --dport 16509 -s 192.168.1.0/24 -j ACCEPT

# Allow VNC consoles (from specific IPs)
iptables -A INPUT -p tcp --dport 5900:5999 -s 192.168.1.0/24 -j ACCEPT

# Allow VM traffic on bridge
iptables -A FORWARD -i virbr0 -o virbr0 -j ACCEPT
iptables -A FORWARD -i virbr0 -j ACCEPT
iptables -A FORWARD -o virbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# NAT for VM internet access
iptables -t nat -A POSTROUTING -s 192.168.122.0/24 -j MASQUERADE

# Log dropped packets (debugging)
iptables -A INPUT -j LOG --log-prefix "FW-DROP-INPUT: " --log-level 4
iptables -A FORWARD -j LOG --log-prefix "FW-DROP-FORWARD: " --log-level 4

# Save rules
iptables-save > /etc/iptables.rules

# Make executable
chmod +x /opt/firewall.sh

# Apply firewall on boot
echo "/opt/firewall.sh" >> /opt/bootlocal.sh

# Apply now
sudo /opt/firewall.sh
```

## SSH Hardening

### 1. Disable Root Login

```bash
# Edit SSH config
sudo vi /etc/ssh/sshd_config

# Disable root login
PermitRootLogin no

# Disable password authentication (use keys only)
PasswordAuthentication no
PubkeyAuthentication yes

# Disable empty passwords
PermitEmptyPasswords no

# Limit authentication attempts
MaxAuthTries 3

# Limit concurrent sessions
MaxSessions 2

# Set idle timeout
ClientAliveInterval 300
ClientAliveCountMax 2

# Only allow specific users (optional)
AllowUsers admin operator

# Restart SSH
sudo /usr/local/etc/init.d/openssh restart
```

### 2. SSH Key Authentication

```bash
# Generate SSH key (on your workstation)
ssh-keygen -t ed25519 -C "admin@virtos"

# Copy key to VirtOS host
ssh-copy-id admin@virtos-host

# Test key authentication
ssh admin@virtos-host

# If working, disable password auth (see above)
```

### 3. Two-Factor Authentication (Recommended)

```bash
# Install Google Authenticator PAM module
tce-load -wi google-authenticator

# Configure for user
google-authenticator

# Edit PAM SSH config
sudo vi /etc/pam.d/sshd

# Add:
auth required pam_google_authenticator.so

# Edit SSH config
sudo vi /etc/ssh/sshd_config

# Enable challenge-response
ChallengeResponseAuthentication yes

# Restart SSH
sudo /usr/local/etc/init.d/openssh restart
```

## VM Isolation and Security

### 1. Network Isolation

```bash
# Create isolated networks for different security zones

# DMZ network (public-facing VMs)
virtos-network bridge-create dmz-network
virtos-network configure dmz-network --isolated

# Internal network (backend services)
virtos-network bridge-create internal-network
virtos-network configure internal-network --isolated --no-internet

# Database network (database VMs only)
virtos-network bridge-create db-network
virtos-network configure db-network --isolated --no-internet

# Firewall rules between zones
sudo iptables -A FORWARD -i dmz-br -o internal-br -m state --state NEW -j DROP
sudo iptables -A FORWARD -i dmz-br -o db-br -j DROP
```

### 2. Resource Limits

```bash
# Prevent resource exhaustion attacks

# Limit CPU for non-critical VMs
virsh setmaxmem dev-vm 4194304 --config
virsh setvcpus dev-vm 2 --maximum --config

# Set memory ballooning
virsh qemu-monitor-command web-server --hmp "balloon 2048"

# Limit disk I/O
virsh blkdeviotune web-server vda --total-iops-sec 1000

# Limit network bandwidth
virsh domiftune web-server vnet0 --inbound 10240 --outbound 10240
```

### 3. VM Security Hardening

```bash
# Disable unnecessary VM features

# Edit VM XML
virsh edit <vm-name>

# Remove or disable:
# - USB redirection (if not needed)
<controller type='usb' model='none'/>

# - Sound card
<!-- <sound model='ich6'/> -->

# - Graphics (for headless servers)
<graphics type='spice' autoport='no'/>

# Enable security features:
# - AppArmor/SELinux
<seclabel type='dynamic' model='apparmor'/>

# - SecComp sandbox
<seccomp enabled='yes'/>
```

## Credential and Secrets Management

### 1. Set Up Secrets Manager

```bash
# Initialize HashiCorp Vault (recommended)
virtos-secrets setup-manager vault \
    --address https://vault.example.com \
    --token $VAULT_TOKEN

# Or use local encrypted storage
virtos-secrets setup-manager local \
    --encryption-key /root/.secrets-key
```

### 2. Store Secrets Securely

```bash
# NEVER hardcode credentials in scripts or configs

# BAD (don't do this):
MYSQL_PASSWORD="supersecret123"

# GOOD (use secrets manager):
MYSQL_PASSWORD=$(virtos-secrets get-secret databases/mysql/root-password)

# Store secrets
virtos-secrets store-secret vm/web-01/ssh-key "$(cat ~/.ssh/id_rsa)"
virtos-secrets store-secret vm/db-01/admin-password "SecurePassword123!"

# Rotate secrets regularly
virtos-secrets rotate-secret vm/web-01/ssh-key
```

### 3. Encrypt Sensitive Data

```bash
# Encrypt VM disks (LUKS)
virtos-storage create-encrypted-volume \
    --pool default \
    --name db-01-disk \
    --size 100G \
    --passphrase-from-secret databases/disk-encryption

# Encrypt backups
virtos-backup configure \
    --encryption enabled \
    --encryption-key /root/.backup-key

# Encrypt migration data
virtos-migrate configure \
    --encryption enabled \
    --tls-verify
```

## Audit Logging

### 1. Enable System Audit

```bash
# Install audit daemon
tce-load -wi audit

# Configure audit rules
sudo vi /etc/audit/audit.rules

# Monitor virtos commands
-a always,exit -F path=/usr/local/bin/virtos-create-vm -F perm=x -k virtos-vm-create
-a always,exit -F path=/usr/local/bin/virtos-backup -F perm=x -k virtos-backup
-a always,exit -F path=/usr/local/bin/virtos-auth -F perm=x -k virtos-auth

# Monitor libvirt
-w /etc/libvirt/ -p wa -k libvirt-config
-w /var/lib/libvirt/ -p wa -k libvirt-data

# Monitor SSH
-w /etc/ssh/sshd_config -p wa -k ssh-config
-w /root/.ssh/ -p wa -k root-ssh

# Monitor sudo
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=4294967295 -k sudo

# Start audit daemon
sudo service auditd start

# Make persistent
echo "auditd start" >> /opt/bootlocal.sh
```

### 2. Centralized Logging

```bash
# Forward logs to central syslog server
sudo vi /etc/rsyslog.conf

# Add:
*.* @@syslog.example.com:514

# Or use TLS for encryption
*.* @@(o)syslog.example.com:6514

# Restart rsyslog
sudo /etc/init.d/rsyslog restart
```

### 3. Log Retention

```bash
# Configure log rotation
sudo vi /etc/logrotate.d/virtos

/var/log/virtos/*.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}

/var/log/libvirt/**/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
}
```

## Security Monitoring

### 1. File Integrity Monitoring

```bash
# Install AIDE (Advanced Intrusion Detection Environment)
tce-load -wi aide

# Initialize database
sudo aide --init

# Move database
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Check integrity daily
echo "0 2 * * * /usr/bin/aide --check" | sudo crontab -

# Receive alerts on changes
sudo vi /etc/aide/aide.conf

# Add email notification
MAILTO=security@example.com
```

### 2. Intrusion Detection

```bash
# Install OSSEC (optional, for advanced security)
# Or use Snort/Suricata for network IDS

# Simple intrusion detection: monitor auth logs
sudo vi /opt/check-intrusion.sh

#!/bin/sh
# Alert on failed SSH attempts

FAILED_LOGINS=$(grep "Failed password" /var/log/auth.log | wc -l)

if [ $FAILED_LOGINS -gt 10 ]; then
    echo "WARNING: $FAILED_LOGINS failed SSH attempts detected" | \
        mail -s "Security Alert: VirtOS Host" security@example.com
fi

# Run hourly
echo "0 * * * * /opt/check-intrusion.sh" | sudo crontab -
```

### 3. Vulnerability Scanning

```bash
# Weekly vulnerability scan
sudo vi /opt/vuln-scan.sh

#!/bin/sh
# Check for known vulnerabilities

# Update CVE database
tce-load -i cve-checker

# Scan system
cve-checker --report /root/vuln-$(date +%Y%m%d).txt

# Email report
mail -s "Vulnerability Report: VirtOS" security@example.com < /root/vuln-$(date +%Y%m%d).txt

# Run weekly
echo "0 0 * * 0 /opt/vuln-scan.sh" | sudo crontab -
```

## Incident Response Plan

### Detection

1. **Automated alerts** trigger (IDS, file integrity, auth failures)
2. **Manual detection** (unusual activity, performance degradation)
3. **User report** (suspicious behavior, access denied)

### Response Procedure

```bash
# 1. Isolate affected systems
virsh destroy <compromised-vm>
virtos-network bridge-detach <compromised-vm> <network>

# 2. Preserve evidence
virtos-snapshot create <compromised-vm> forensics-$(date +%s)
virtos-backup create-backup <compromised-vm> incident-$(date +%s)

# 3. Analyze
virsh console <compromised-vm>  # Check logs
virsh domblklist <compromised-vm>  # Mount disk for analysis

# 4. Contain
# Isolate network, block IP addresses, revoke credentials

# 5. Eradicate
# Remove malware, patch vulnerabilities, rebuild if needed

# 6. Recover
virtos-backup restore-backup <vm> <clean-backup>

# 7. Lessons learned
# Document incident, update procedures
```

## Security Update Process

### Monthly Security Patching

```bash
# First Tuesday of each month

# 1. Check for security updates
virtos-update check-security

# 2. Test in staging
virtos-dr replicate-to-staging
ssh staging-host virtos-update apply-security

# 3. Apply to production (maintenance window)
virtos-update apply-security --schedule "Sat 02:00"

# 4. Verify
virtos-update verify-security
```

### Emergency Patches

```bash
# Critical CVE discovered

# 1. Assess severity
# Read: https://nvd.nist.gov/vuln/detail/CVE-XXXX-XXXXX

# 2. Apply patch immediately
virtos-update emergency-patch CVE-XXXX-XXXXX

# 3. Restart affected services
sudo systemctl restart libvirtd

# 4. Verify patch
grep CVE-XXXX-XXXXX /var/log/virtos-update.log
```

## Compliance Checklist

### PCI-DSS Requirements

- [ ] Firewall configured between VMs and external networks
- [ ] Default passwords changed
- [ ] VM data encrypted (disk encryption)
- [ ] Transmission data encrypted (TLS for migration, backups)
- [ ] Antivirus on Windows VMs
- [ ] Access control (virtos-auth)
- [ ] Unique IDs for users
- [ ] Physical access restrictions
- [ ] Audit trails enabled
- [ ] Regular security testing

### HIPAA Requirements

- [ ] Access controls (virtos-auth + RBAC)
- [ ] Audit logging (all access to PHI logged)
- [ ] Data encryption at rest and in transit
- [ ] Backup and disaster recovery
- [ ] Automatic logoff (SSH timeouts)
- [ ] Emergency access procedures
- [ ] Security awareness training
- [ ] Incident response plan

## Security Testing

### Penetration Testing Checklist

- [ ] External network scan (nmap from outside)
- [ ] Internal network scan (from VM to host)
- [ ] SSH brute force resistance test
- [ ] Web interface vulnerabilities (if applicable)
- [ ] Privilege escalation attempts
- [ ] VM escape attempts
- [ ] Data exfiltration testing
- [ ] DDoS resilience
- [ ] Social engineering resistance

### Regular Security Audits

```bash
# Quarterly security audit script
sudo vi /opt/security-audit.sh

#!/bin/sh
echo "VirtOS Security Audit - $(date)"
echo "================================"

# Check firewall
echo "Firewall rules:"
iptables -L -n | head -20

# Check SSH config
echo "SSH configuration:"
grep -E "PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config

# Check for weak passwords (if using passwords)
echo "Checking weak passwords..."
john --test /etc/shadow

# Check file permissions
echo "Checking sensitive file permissions:"
ls -l /etc/libvirt/
ls -l /root/.ssh/

# Check for unnecessary services
echo "Running services:"
systemctl list-units --type=service --state=running | grep -v "loaded active"

# Generate report
mail -s "VirtOS Security Audit" security@example.com < /tmp/audit.log
```

## Getting Help

- **Security issues**: security@flossware.org (private)
- **Security advisories**: [github.com/FlossWare/VirtOS/security/advisories](https://github.com/FlossWare/VirtOS/security/advisories)
- **CVE tracking**: Subscribe to virtos-security mailing list

---

**Security Hardening Guide Version**: 1.0 (2026-05-26)  
**Applies to**: VirtOS 0.80+  
**Related**: [ADMIN-GUIDE.md](ADMIN-GUIDE.md), [INCIDENT-RESPONSE.md](INCIDENT-RESPONSE.md)
