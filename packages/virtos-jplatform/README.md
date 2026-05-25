# VirtOS JPlatform Integration Package

Integrates JPlatform with VirtOS to provide unified orchestration for virtual machines, containers, Java applications, and native binaries.

## What This Package Provides

**Scripts:**
- `jplatform` - Main CLI for managing all workload types
- `virtos-jplatform-install` - Installs JPlatform on VirtOS
- `virtos-jplatform-uninstall` - Removes JPlatform from VirtOS
- `virtos-jplatform-info` - Shows installation status and configuration

**Directories:**
- `/usr/local/lib/jplatform/` - JPlatform binaries
- `/var/lib/jplatform/apps/` - Deployed applications
- `/var/lib/jplatform/vms/` - Virtual machine disk images
- `/var/lib/jplatform/volumes/` - Persistent storage volumes
- `/etc/jplatform/` - Configuration files

## Installation

### 1. Build the Package

```bash
cd /path/to/VirtOS/packages/virtos-jplatform
./build.sh
```

### 2. Install on VirtOS

Copy the package to your VirtOS system:

```bash
sudo cp virtos-jplatform.tcz* /mnt/sda1/tce/optional/
echo virtos-jplatform.tcz >> /mnt/sda1/tce/onboot.lst
tce-load -i virtos-jplatform
```

### 3. Install JPlatform

Once the package is loaded:

```bash
virtos-jplatform-install
```

This will:
- Install OpenJDK 21 (if not present)
- Install libvirt for VM management
- Download/build JPlatform
- Create default configuration
- Set up directories

## Usage

### Check Status

```bash
virtos-jplatform-info
```

### Deploy a Virtual Machine

```bash
cat > database-vm.yaml << EOF
applicationId: postgres-vm
name: PostgreSQL Database VM
properties:
  vm.vcpu: "8"
  vm.memory: "32768"  # 32GB
  vm.disk: "/var/lib/jplatform/vms/postgres.qcow2"
  vm.network: "bridge"
  vm.vnc.enabled: "true"
resources:
  cpu: 8
  memory: 32768
EOF

jplatform deploy database-vm.yaml
jplatform start postgres-vm
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

jplatform deploy web-container.yaml
jplatform start nginx
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

jplatform deploy java-app.yaml
jplatform start my-service
```

### List All Workloads

```bash
jplatform status
```

### View Logs

```bash
jplatform logs postgres-vm
```

### View Metrics

```bash
jplatform metrics postgres-vm
```

### Stop and Remove

```bash
jplatform stop postgres-vm
jplatform undeploy postgres-vm
```

## Cross-Workload Dependencies

JPlatform supports dependencies across all workload types:

```yaml
applicationId: app-vm
name: Application VM
properties:
  vm.vcpu: "4"
  vm.memory: "8192"
  vm.disk: "/var/lib/jplatform/vms/app.qcow2"
dependencies:
  - postgres-vm       # Another VM
  - redis-container   # A container
  - auth-service      # A Java app
```

JPlatform ensures:
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
│    JPlatform (Unified Orchestration)    │
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
JPlatform provides the orchestration layer (lifecycle management, dependencies, monitoring).

## Configuration

Default configuration at `/etc/jplatform/config.yaml`:

```yaml
platform:
  name: "virtos-jplatform"
  dataDirectory: "/var/lib/jplatform"

vm:
  enabled: true
  libvirtUri: "qemu:///system"
  defaultVcpu: 2
  defaultMemoryMB: 4096
  diskDirectory: "/var/lib/jplatform/vms"

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
ls -lh /var/lib/jplatform/vms/

# View libvirt logs
sudo virsh list --all
```

## Documentation

- **JPlatform**: https://github.com/FlossWare/jplatform
- **VirtOS**: https://github.com/FlossWare/VirtOS
- **VM Management**: https://github.com/FlossWare/jplatform/tree/main/jplatform-vm-management
- **Container Deployment**: https://github.com/FlossWare/jplatform/blob/main/CONTAINER_DEPLOYMENT.md

## License

MIT License - See LICENSE file for details.
