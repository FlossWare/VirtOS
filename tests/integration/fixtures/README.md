# Integration Test Fixtures

This directory contains sample workload definitions for testing JPlatform integration with VirtOS.

## Available Fixtures

### Single Workloads

#### `test-vm.yaml`
Basic virtual machine workload for testing VM lifecycle operations.

```bash
jplatform deploy test-vm.yaml
jplatform start test-vm
jplatform status test-vm
jplatform stop test-vm
jplatform delete test-vm
```

**Spec**:
- Memory: 512MB
- CPU: 1 core
- Disk: 5GB
- Network: NAT

#### `test-container.yaml`
NGINX container workload for testing container operations.

```bash
jplatform deploy test-container.yaml
jplatform start nginx-test
curl http://localhost:8080
jplatform stop nginx-test
jplatform delete nginx-test
```

**Spec**:
- Image: nginx:latest
- Ports: 80 → 8080
- Memory: 256MB limit, 128MB request
- CPU: 0.5 limit, 0.25 request

### Multi-Tier Application

A 3-tier web application demonstrating dependency resolution and mixed workload types (VMs + containers).

#### `multi-tier-db.yaml`
PostgreSQL database tier (Virtual Machine).

**Spec**:
- Memory: 1024MB
- CPU: 2 cores
- Disk: 20GB
- Role: Database backend

#### `multi-tier-app.yaml`
Java application tier (Container) - depends on database tier.

**Spec**:
- Image: openjdk:17-slim
- Ports: 8080
- Memory: 512MB limit
- Depends on: `database-tier`

#### `multi-tier-web.yaml`
NGINX web tier (Container) - depends on application tier.

**Spec**:
- Image: nginx:latest
- Ports: 80, 443
- Memory: 256MB limit
- Depends on: `application-tier`
- Includes NGINX reverse proxy configuration

#### Deploying Multi-Tier App

```bash
# Deploy all tiers
jplatform deploy multi-tier-db.yaml
jplatform deploy multi-tier-app.yaml
jplatform deploy multi-tier-web.yaml

# Start web tier (should auto-start dependencies)
jplatform start web-tier

# Verify all tiers are running
jplatform status database-tier
jplatform status application-tier
jplatform status web-tier

# Access the application
curl http://localhost

# Cleanup
jplatform delete web-tier
jplatform delete application-tier
jplatform delete database-tier
```

## Usage in Tests

These fixtures are referenced in integration tests:

- `tests/integration/02-jplatform.bats`: JPlatform integration tests
- Test functions use these fixtures to validate workload deployment, lifecycle management, and dependency resolution

## Customization

You can modify these fixtures for different test scenarios:

1. **Resource Limits**: Adjust memory/CPU for different constraint testing
2. **Networks**: Change network configuration to test different topologies
3. **Dependencies**: Modify `depends_on` to test complex dependency graphs
4. **Images**: Use different container images for compatibility testing
5. **Volumes**: Add volume mounts for persistent storage testing

## Requirements

To use these fixtures, you need:

- VirtOS runtime environment
- JPlatform installed (`virtos-jplatform.tcz`)
- libvirt/QEMU for VM workloads
- Docker or Podman for container workloads

## Validation

Validate fixture syntax:

```bash
# Check YAML syntax
yamllint fixtures/*.yaml

# Dry-run deployment (doesn't create resources)
jplatform deploy --dry-run test-vm.yaml
```

## Adding New Fixtures

When creating new fixtures:

1. Follow the same YAML structure (apiVersion, kind, metadata, spec)
2. Use descriptive names that indicate the fixture purpose
3. Add resource limits to prevent test resource exhaustion
4. Document dependencies clearly in `depends_on`
5. Update this README with the new fixture details
