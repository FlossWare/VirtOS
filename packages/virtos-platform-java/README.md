# VirtOS platform-java Integration Package

Integrates platform-java with VirtOS to provide unified orchestration for virtual machines, containers, Java applications, and native binaries.

## What This Package Provides

**Scripts:**

- `platform-java` - Main CLI for managing all workload types
- `virtos-platform-java-install` - Installs platform-java on VirtOS
- `virtos-platform-java-uninstall` - Removes platform-java from VirtOS
- `virtos-platform-java-info` - Shows installation status and configuration

**Directories:**

- `/usr/local/lib/platform-java/` - platform-java binaries
- `/var/lib/platform-java/apps/` - Deployed applications
- `/var/lib/platform-java/vms/` - Virtual machine disk images
- `/var/lib/platform-java/volumes/` - Persistent storage volumes
- `/etc/platform-java/` - Configuration files

## Installation

### 1. Build the Package

```bash
cd /path/to/VirtOS/packages/virtos-platform-java
./build.sh
```

### 2. Install on VirtOS

Copy the package to your VirtOS system:

```bash
sudo cp virtos-platform-java.tcz* /mnt/sda1/tce/optional/
echo virtos-platform-java.tcz >> /mnt/sda1/tce/onboot.lst
tce-load -i virtos-platform-java
```

### 3. Install platform-java

Once the package is loaded:

```bash
virtos-platform-java-install
```

This will:

- Install OpenJDK 21 (if not present)
- Install libvirt for VM management
- Download/build platform-java
- Create default configuration
- Set up directories

## Usage

### Check Status

```bash
virtos-platform-java-info
```

### Deploy a Virtual Machine

```bash
cat > database-vm.yaml << EOF
applicationId: postgres-vm
name: PostgreSQL Database VM
properties:
  vm.vcpu: "8"
  vm.memory: "32768"  # 32GB
  vm.disk: "/var/lib/platform-java/vms/postgres.qcow2"
  vm.network: "bridge"
  vm.vnc.enabled: "true"
resources:
  cpu: 8
  memory: 32768
EOF

platform-java deploy database-vm.yaml
platform-java start postgres-vm
```

### Deploy a Container

```bash
cat > web-container.yaml << EOF
applicationId: nginx
name: NGINX Web Server
properties:
  container.image: "nginx:alpine"
  container.runtime: "docker"
  container.ports: "80:80,443:443"
  container.volumes: "/var/www:/usr/share/nginx/html:ro"
EOF

platform-java deploy web-container.yaml
platform-java start nginx
```

### Deploy a Java Application

```bash
cat > java-app.yaml << EOF
applicationId: my-service
name: My Java Service
mainClass: "com.example.MyService"
classpath:
  - "/path/to/my-service.jar"
resources:
  maxHeapMB: 2048
  maxThreads: 100
EOF

platform-java deploy java-app.yaml
platform-java start my-service
```

### List All Workloads

```bash
platform-java status
```

### View Logs

```bash
platform-java logs postgres-vm
```

### View Metrics

```bash
platform-java metrics postgres-vm
```

### Stop and Remove

```bash
platform-java stop postgres-vm
platform-java undeploy postgres-vm
```

## Cross-Workload Dependencies

platform-java supports dependencies across all workload types:

```yaml
applicationId: app-vm
name: Application VM
properties:
  vm.vcpu: "4"
  vm.memory: "8192"
  vm.disk: "/var/lib/platform-java/vms/app.qcow2"
dependencies:
  - postgres-vm       # Another VM
  - redis-container   # A container
  - auth-service      # A Java app
```

platform-java ensures:

1. `postgres-vm` starts first
2. `redis-container` starts second
3. `auth-service` starts third
4. `app-vm` starts last (after all dependencies are ready)

## Architecture

```
┌─────────────────────────────────────────┐
│         VirtOS (Infrastructure)         │
│  - KVM/QEMU                             │
│  - Storage                              │
│  - Networking                           │
│  - Multi-cloud federation               │
└─────────────────────────────────────────┘
          ↓ provides
┌─────────────────────────────────────────┐
│    platform-java (Unified Orchestration)    │
│                                         │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │
│  │ VMs  │ │Ctnrs │ │Java  │ │Native│ │
│  │QEMU  │ │Docker│ │Apps  │ │Binary│ │
│  └──────┘ └──────┘ └──────┘ └──────┘ │
│                                         │
│  Unified: API, quotas, monitoring, deps │
└─────────────────────────────────────────┘
```

VirtOS provides the infrastructure (virtualization, storage, networking, multi-cloud).
platform-java provides the orchestration layer (lifecycle management, dependencies, monitoring).

## Configuration

Default configuration at `/etc/platform-java/config.yaml`:

```yaml
platform:
  name: "virtos-platform-java"
  dataDirectory: "/var/lib/platform-java"

vm:
  enabled: true
  libvirtUri: "qemu:///system"
  defaultVcpu: 2
  defaultMemoryMB: 4096
  diskDirectory: "/var/lib/platform-java/vms"

container:
  enabled: true
  runtime: "auto"  # auto-detect: docker, podman, or lxc

resources:
  defaultMaxHeapMB: 2048
  defaultMaxThreads: 100

monitoring:
  enabled: true
  prometheusPort: 9090

api:
  enabled: true
  port: 8080
  host: "0.0.0.0"
```

## Requirements

- **Java**: OpenJDK 21 or later (auto-installed)
- **libvirt**: For VM management (auto-installed)
- **Container runtime**: Docker or Podman (optional, for container support)
- **KVM**: Hardware virtualization support for VMs

## Troubleshooting

### "Java not found"

```bash
tce-load -wi openjdk-21-jre
```

### "libvirt not accessible"

```bash
# Check libvirt is running
sudo /usr/local/etc/init.d/libvirt start

# Add user to libvirt group
sudo addgroup tc libvirt
```

### "Cannot connect to Docker"

```bash
# Start Docker daemon
sudo /usr/local/etc/init.d/docker start

# Add user to docker group
sudo addgroup tc docker
```

### VM fails to start

```bash
# Check KVM is available
lsmod | grep kvm

# Check disk image exists
ls -lh /var/lib/platform-java/vms/

# View libvirt logs
sudo virsh list --all
```

## Documentation

- **platform-java**: <https://github.com/FlossWare/platform-java>
- **VirtOS**: <https://github.com/FlossWare/VirtOS>
- **VM Management**: <https://github.com/FlossWare/platform-java/tree/main/platform-java-vm-management>
- **Container Deployment**: <https://github.com/FlossWare/platform-java/blob/main/CONTAINER_DEPLOYMENT.md>

## License

MIT License - See LICENSE file for details.
