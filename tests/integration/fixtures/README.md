# Integration Test Fixtures

This directory contains fixtures for VirtOS integration tests.

## VM Fixtures

### test-vm.yaml
Platform-java workload definition for a test VM. Used by platform-java integration tests.

**Spec**:
- Memory: 512M
- CPU: 1
- Disk: 5G
- Network: NAT
- Autostart: false

**Usage**:
```bash
platform-java deploy fixtures/test-vm.yaml
platform-java start test-vm
```

### test-vm-minimal.xml
Minimal libvirt domain XML for direct virsh testing. Used by VM lifecycle tests.

**Spec**:
- Memory: 512 MiB
- vCPU: 1
- Disk: /var/lib/libvirt/images/test-vm.qcow2 (qcow2)
- Network: default (NAT)
- Architecture: x86_64/KVM

**Usage**:
```bash
# Create disk image
qemu-img create -f qcow2 /var/lib/libvirt/images/test-vm.qcow2 2G

# Define VM
virsh define fixtures/test-vm-minimal.xml

# Start VM
virsh start test-vm
```

## Container Fixtures

### test-container.yaml
Platform-java container workload definition. Used by container integration tests.

**Spec**:
- Image: nginx:alpine
- Ports: 8080:80
- Resources: 256M memory, 0.5 CPU

**Usage**:
```bash
platform-java deploy fixtures/test-container.yaml
platform-java start test-nginx
```

## Multi-Tier Application Fixtures

### multi-tier-db.yaml
Database tier (PostgreSQL VM) for multi-tier integration tests.

**Spec**:
- VM with PostgreSQL
- Memory: 1024M
- CPU: 2
- Disk: 10G

### multi-tier-app.yaml
Application tier (Spring Boot container) for multi-tier integration tests.

**Spec**:
- Container with Spring Boot application
- Depends on: postgres-db
- Ports: 8080:8080

### multi-tier-web.yaml
Web tier (NGINX container) for multi-tier integration tests.

**Spec**:
- Container with NGINX reverse proxy
- Depends on: spring-app
- Ports: 80:80

**Full Workflow**:
```bash
# Deploy all tiers
platform-java deploy fixtures/multi-tier-db.yaml
platform-java deploy fixtures/multi-tier-app.yaml
platform-java deploy fixtures/multi-tier-web.yaml

# Start in dependency order (automatic)
platform-java start nginx-web
# This will start: postgres-db → spring-app → nginx-web

# Verify
curl http://localhost/api/health
```

## Test Requirements

### For VM Tests
- libvirt-daemon-system
- qemu-kvm
- qemu-utils (qemu-img)
- virsh
- Sufficient disk space in /var/lib/libvirt/images

### For Container Tests
- docker or podman
- platform-java CLI

### For Platform-Java Tests
- platform-java installed
- Java runtime (JRE 17+)
- Both libvirt and container runtime

## Cleanup

Test fixtures should be cleaned up by test teardown functions, but manual cleanup:

```bash
# VMs
virsh destroy test-vm 2>/dev/null || true
virsh undefine test-vm --remove-all-storage 2>/dev/null || true

# Containers via platform-java
platform-java stop test-nginx
platform-java remove test-nginx

# Multi-tier
platform-java stop nginx-web
platform-java remove nginx-web spring-app postgres-db
```
