# VirtOS Audit Logging

**Last Updated**: 2026-05-29  
**Status**: Implemented  
**Related Issue**: [#108](https://github.com/FlossWare/VirtOS/issues/108)

---

## Overview

VirtOS provides comprehensive audit logging for all sensitive operations. Every create, delete, modify, and security-related action is logged with full context for compliance, security investigation, and troubleshooting.

**Key Features**:
- ✅ Centralized audit log (`/var/log/virtos-audit.log`)
- ✅ Structured log format (machine-parseable)
- ✅ User attribution (who performed the action)
- ✅ Source tracking (IP address for remote sessions)
- ✅ Success/failure logging
- ✅ Query and analysis tools (`virtos-audit`)
- ✅ Automatic rotation and compression
- ✅ Fallback to syslog if audit log unavailable

---

## Quick Start

### View Recent Events
```bash
# Show last 10 audit events
virtos-audit recent

# Show last 50 events
virtos-audit recent 50
```

### Query Audit Log
```bash
# Find all events by user
virtos-audit query user admin

# Find all VM deletion events
virtos-audit query action vm.delete

# Find all failed operations
virtos-audit query result failed

# Find events on specific date
virtos-audit query date "2026-05-29"
```

### Monitor in Real-Time
```bash
# Watch audit log (like tail -f)
virtos-audit watch
```

### Statistics
```bash
# Show audit log statistics
virtos-audit stats
```

---

## Log Format

### Structure

Each audit entry follows this structured format:

```
[TIMESTAMP] version=X.Y host=HOSTNAME pid=PID user=USER source=SOURCE action=ACTION resource="RESOURCE" result=RESULT [error="ERROR"] [context]
```

### Example Entries

```
[2026-05-29 14:32:15 +0000] version=1.0 host=virtos-01 pid=12345 user=admin source=192.168.1.50 action=vm.delete resource="web-server" result=success

[2026-05-29 14:35:22 +0000] version=1.0 host=virtos-01 pid=12347 user=operator source=192.168.1.51 action=snapshot.create resource="database/snap-1" result=success

[2026-05-29 14:40:10 +0000] version=1.0 host=virtos-01 pid=12350 user=admin source=192.168.1.50 action=storage.delete resource="pool-backup" result=failed error="pool in use"

[2026-05-29 14:45:30 +0000] version=1.0 host=virtos-01 pid=12355 user=guest source=192.168.1.100 action=vm.delete resource="production-db" result=denied error="access denied"
```

### Fields

| Field | Description | Example |
|-------|-------------|---------|
| **TIMESTAMP** | Date and time (ISO 8601) | `2026-05-29 14:32:15 +0000` |
| **version** | Audit log format version | `1.0` |
| **host** | Hostname where action occurred | `virtos-01` |
| **pid** | Process ID | `12345` |
| **user** | User who performed action | `admin` |
| **source** | Source IP (or "local") | `192.168.1.50` or `local` |
| **action** | Action performed | `vm.delete` |
| **resource** | Resource affected | `"web-server"` |
| **result** | Outcome | `success`, `failed`, `denied`, `skipped` |
| **error** | Error message (optional) | `"pool in use"` |
| **context** | Additional metadata (optional) | `duration=5.2s size=10GB` |

---

## Result Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| **success** | Operation completed successfully | VM created, snapshot deleted |
| **failed** | Operation failed (technical error) | Disk full, network timeout |
| **denied** | Operation denied (permission/policy) | User lacks permission, policy violation |
| **skipped** | Operation skipped (already exists) | VM already running, duplicate resource |

---

## Action Categories

### VM Operations
- `vm.create` - Virtual machine created
- `vm.delete` - Virtual machine deleted
- `vm.start` - Virtual machine started
- `vm.stop` - Virtual machine stopped
- `vm.pause` - Virtual machine paused
- `vm.resume` - Virtual machine resumed
- `vm.migrate` - Virtual machine migrated
- `vm.clone` - Virtual machine cloned
- `vm.modify` - Virtual machine configuration modified

### Snapshot Operations
- `snapshot.create` - Snapshot created
- `snapshot.delete` - Snapshot deleted
- `snapshot.restore` - Snapshot restored
- `snapshot.list` - Snapshots listed (query only, rarely logged)

### Storage Operations
- `storage.pool.create` - Storage pool created
- `storage.pool.delete` - Storage pool deleted
- `storage.volume.create` - Storage volume created
- `storage.volume.delete` - Storage volume deleted
- `storage.volume.attach` - Volume attached to VM
- `storage.volume.detach` - Volume detached from VM

### Network Operations
- `network.create` - Network created
- `network.delete` - Network deleted
- `network.modify` - Network configuration modified
- `network.attach` - Network attached to VM
- `network.detach` - Network detached from VM

### Backup Operations
- `backup.create` - Backup created
- `backup.delete` - Backup deleted
- `backup.restore` - Backup restored
- `backup.verify` - Backup verified

### Security Operations
- `security.policy.change` - Security policy changed
- `security.permission.change` - Permissions modified
- `security.user.create` - User created
- `security.user.delete` - User deleted
- `security.user.modify` - User modified
- `security.firewall.change` - Firewall rules changed

### System Operations
- `system.config.change` - System configuration changed
- `system.service.start` - Service started
- `system.service.stop` - Service stopped
- `system.upgrade` - System upgraded
- `system.reboot` - System rebooted

---

## Using Audit Logging in Scripts

### Basic Usage

```bash
#!/bin/sh
# Source audit library
. /usr/local/lib/virtos-audit.sh

# Log successful operation
audit_success "vm.create" "myvm"

# Log failed operation
audit_fail "vm.delete" "myvm" "VM not found"

# Log denied operation
audit_deny "vm.delete" "production-db" "User lacks permission"
```

### Full Example

```bash
#!/bin/sh
# virtos-vm-delete with audit logging

. /usr/local/lib/virtos-common.sh
. /usr/local/lib/virtos-audit.sh

VM_NAME="$1"

# Validate input
if ! validate_name "$VM_NAME"; then
    audit_fail "vm.delete" "$VM_NAME" "Invalid VM name"
    echo "Error: Invalid VM name" >&2
    exit 1
fi

# Check if VM exists
if ! virsh dominfo "$VM_NAME" >/dev/null 2>&1; then
    audit_fail "vm.delete" "$VM_NAME" "VM not found"
    echo "Error: VM not found" >&2
    exit 1
fi

# Delete VM
if virsh undefine "$VM_NAME" --remove-all-storage; then
    audit_success "vm.delete" "$VM_NAME"
    echo "VM deleted: $VM_NAME"
else
    audit_fail "vm.delete" "$VM_NAME" "virsh undefine failed"
    echo "Error: Failed to delete VM" >&2
    exit 1
fi
```

### With Context

```bash
# Add context to audit log (key=value pairs)
START_TIME=$(date +%s)
# ... operation ...
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

audit_success "vm.migrate" "myvm" "duration=${DURATION}s dest=host2"
# Logs: ... action=vm.migrate resource="myvm" result=success duration=5s dest=host2
```

---

## Audit Log Management

### Log Rotation

VirtOS audit logs are automatically rotated using logrotate:

**Configuration**: `/etc/logrotate.d/virtos-audit`
```
/var/log/virtos-audit.log {
    daily
    rotate 90
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root virtos
}
```

**Manual Rotation**:
```bash
# Rotate audit log manually
sudo virtos-audit rotate
```

### Retention Policy

**Default**: 90 days (configurable via logrotate)

**Compliance Requirements**:
- PCI-DSS: 1 year (365 days)
- HIPAA: 6 years (2190 days)
- SOX: 7 years (2555 days)
- GDPR: Varies (30 days to 6 years)

**Adjust Retention**:
```bash
# Edit logrotate configuration
sudo vi /etc/logrotate.d/virtos-audit

# Change "rotate 90" to desired number of days
# Example for 1 year:
rotate 365
```

### Export Audit Logs

```bash
# Export to file
virtos-audit export /backup/audit-export-$(date +%Y%m%d).log

# Export to stdout (pipe to remote system)
virtos-audit export | ssh backup-server 'cat > /backup/virtos-audit.log'

# Export specific date range
virtos-audit query date "2026-05" > /backup/may-2026-audit.log
```

---

## Querying Audit Logs

### Find Security Events

```bash
# All denied operations
virtos-audit query result denied

# All failed operations
virtos-audit query result failed

# Security policy changes
virtos-audit query action security.policy.change
```

### Find User Actions

```bash
# All actions by specific user
virtos-audit query user admin

# All VM deletions by user
virtos-audit query action vm.delete | grep "user=admin"
```

### Find Resource Changes

```bash
# All operations on specific VM
virtos-audit query resource "production-db"

# All storage operations
virtos-audit query action storage
```

### Date-Based Queries

```bash
# All events today
virtos-audit query date "$(date +%Y-%m-%d)"

# All events in May 2026
virtos-audit query date "2026-05"

# All events on specific day
virtos-audit query date "2026-05-29"
```

---

## Integration with SIEM

### Remote Syslog

Forward audit logs to remote syslog server:

```bash
# Configure rsyslog to forward virtos-audit logs
cat >> /etc/rsyslog.d/virtos-audit.conf <<EOF
# Forward VirtOS audit logs to SIEM
:programname, isequal, "virtos-audit" @@siem.example.com:514
EOF

# Restart rsyslog
sudo systemctl restart rsyslog
```

### Splunk

```bash
# Configure Splunk forwarder
cat >> /opt/splunkforwarder/etc/system/local/inputs.conf <<EOF
[monitor:///var/log/virtos-audit.log]
sourcetype = virtos:audit
index = security
EOF

# Restart Splunk forwarder
sudo /opt/splunkforwarder/bin/splunk restart
```

### ELK Stack (Elasticsearch, Logstash, Kibana)

**Logstash Configuration**:
```ruby
input {
  file {
    path => "/var/log/virtos-audit.log"
    type => "virtos-audit"
  }
}

filter {
  grok {
    match => {
      "message" => "\[%{TIMESTAMP_ISO8601:timestamp}\] version=%{DATA:version} host=%{HOSTNAME:host} pid=%{NUMBER:pid} user=%{USER:user} source=%{IPORHOST:source_ip} action=%{DATA:action} resource=\"%{DATA:resource}\" result=%{WORD:result}( error=\"%{DATA:error}\")?"
    }
  }
}

output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "virtos-audit-%{+YYYY.MM.dd}"
  }
}
```

---

## Compliance Use Cases

### PCI-DSS Compliance

**Requirement 10.2**: Implement automated audit trails for all system components to reconstruct events

**VirtOS Coverage**:
- ✅ 10.2.1 - All individual user accesses (user field)
- ✅ 10.2.2 - All actions by privileged users (root actions logged)
- ✅ 10.2.3 - All audit trail accesses (virtos-audit query)
- ✅ 10.2.4 - Invalid logical access attempts (denied actions)
- ✅ 10.2.5 - Identification/authentication mechanisms (user field)
- ✅ 10.2.7 - Creation/deletion of system-level objects (VM/storage ops)

### HIPAA Compliance

**§164.312(b)**: Audit controls - Implement hardware, software, and/or procedural mechanisms that record and examine activity

**VirtOS Coverage**:
- ✅ User access logging (user field)
- ✅ Resource access logging (resource field)
- ✅ Timestamp of activity (timestamp field)
- ✅ Success/failure indication (result field)
- ✅ Retention policy configurable (logrotate)

### SOX Compliance

**Section 404**: Management assessment of internal controls

**VirtOS Coverage**:
- ✅ Audit trail of changes to systems (all operations logged)
- ✅ User attribution (who made changes)
- ✅ Timestamp of changes (when changes occurred)
- ✅ Retention policy (7+ years configurable)

---

## Security Considerations

### Protecting Audit Logs

**File Permissions**:
```bash
# Audit log permissions (read/write for root, read for virtos group)
chmod 640 /var/log/virtos-audit.log
chown root:virtos /var/log/virtos-audit.log
```

**Append-Only Attribute** (Linux):
```bash
# Make audit log append-only (requires root)
sudo chattr +a /var/log/virtos-audit.log

# Prevent deletion or modification, only appending allowed
# To remove: sudo chattr -a /var/log/virtos-audit.log
```

**SELinux Context** (if using SELinux):
```bash
# Set appropriate SELinux context
sudo chcon -t var_log_t /var/log/virtos-audit.log
```

### Detecting Tampering

**Hash Verification**:
```bash
# Generate hash of audit log
sha256sum /var/log/virtos-audit.log > audit-log.sha256

# Verify later
sha256sum -c audit-log.sha256
```

**Integrity Monitoring** (AIDE, Tripwire):
```bash
# Add audit log to AIDE monitoring
echo '/var/log/virtos-audit.log p' >> /etc/aide.conf
aide --init
```

---

## Troubleshooting

### Audit Log Not Writing

**Symptom**: No entries in audit log

**Check**:
1. Log file exists and is writable:
   ```bash
   ls -l /var/log/virtos-audit.log
   ```

2. Permissions correct:
   ```bash
   sudo chmod 640 /var/log/virtos-audit.log
   ```

3. Disk space available:
   ```bash
   df -h /var/log
   ```

4. Check syslog as fallback:
   ```bash
   grep virtos-audit /var/log/syslog
   ```

### Audit Log Too Large

**Symptom**: Audit log consuming too much disk space

**Solution**:
```bash
# Immediate: Rotate manually
sudo virtos-audit rotate

# Long-term: Adjust retention
sudo vi /etc/logrotate.d/virtos-audit
# Reduce "rotate 90" to smaller number
```

### Performance Impact

**Symptom**: Operations slow due to audit logging

**Check**:
- Disk I/O on /var/log filesystem
- Audit log size (should be rotated)

**Optimize**:
- Use separate disk for /var/log
- Disable synchronous writes (less safe but faster):
  ```bash
  # Mount /var/log with async option (NOT recommended for compliance)
  ```

---

## See Also

- [virtos-security](https://github.com/FlossWare/VirtOS/blob/main/packages/virtos-tools/src/usr/local/bin/virtos-security) - Security hardening
- [virtos-security-advanced](https://github.com/FlossWare/VirtOS/blob/main/packages/virtos-tools/src/usr/local/bin/virtos-security-advanced) - Advanced security features
- [GitHub Issue #108](https://github.com/FlossWare/VirtOS/issues/108) - Audit logging requirement
- [SECURITY_HARDENING.md](SECURITY_HARDENING.md) - Security best practices

---

**Document Version**: 1.0  
**Author**: VirtOS Team  
**License**: Same as VirtOS project (GPL-3.0)
