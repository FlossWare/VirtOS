# Container Runtime Comparison

For FlossWare VirtOS, we support multiple container runtimes as optional components.

## All Container Runtimes - Choose What You Need

FlossWare supports **all three** major container runtimes as optional TCZ extensions. Choose based on your needs:

### Option 1: Docker

**Install Size**: ~70MB  
**Best for**: Home lab, quick experiments, learning, docker-compose workflows

**Pros**:

- Most familiar interface (`docker run`, `docker-compose`)
- Massive ecosystem - Docker Hub has everything
- Great documentation and community
- docker-compose makes multi-container apps trivial
- Better desktop/dev experience
- Excellent for following tutorials

**Cons**:

- Larger footprint than alternatives
- Daemon-based (not as minimal)
- Root privileges required (security consideration)
- More resource overhead

**Use when**: Running pre-built images, following tutorials, docker-compose projects, home lab convenience

### Option 2: Podman

**Install Size**: ~40MB  
**Best for**: Security-focused, rootless containers, modern container workflows

**Pros**:

- **Rootless by default** (better security)
- Docker-compatible CLI (`alias docker=podman` just works)
- **No daemon needed** (fork-exec model)
- Pod support (like Kubernetes)
- Can run systemd in containers
- Modern architecture
- Compatible with docker-compose (via podman-compose)

**Cons**:

- Medium size (between Docker and containerd)
- Some edge-case Docker features missing
- Networking can be more complex
- Smaller community than Docker (but growing fast)

**Use when**: Security is priority, want rootless containers, RHEL/Fedora background, modern best practices

### Option 3: containerd

**Install Size**: ~25MB  
**Best for**: Minimal footprint, Kubernetes, production-like environments

**Pros**:

- **Smallest footprint** - most minimal
- Industry standard (used by Kubernetes, Docker)
- No unnecessary features
- Better aligned with Tiny Core philosophy
- OCI compliant
- Production-grade

**Cons**:

- Less user-friendly CLI (`ctr` is lower-level)
- No docker-compose equivalent built-in
- Requires more manual configuration
- Steeper learning curve

**Use when**: Absolute minimal overhead, learning K8s internals, production deployments, embedded systems

## FlossWare Approach: All Three Available

**All container runtimes are optional TCZ extensions** - you choose what to install!

### Build-Time Choices (build.conf)

```bash
INCLUDE_DOCKER="yes"       # Include Docker extension
INCLUDE_PODMAN="yes"       # Include Podman extension
INCLUDE_CONTAINERD="yes"   # Include containerd extension
```

### Runtime Loading

```bash
# Load what you need
tce-load -i docker       # Full-featured, familiar
tce-load -i podman       # Rootless, secure, daemon-free
tce-load -i containerd   # Minimal, K8s-ready

# Can have all installed, run one at a time
# Or run multiple if needed (different use cases)
```

### Profile Recommendations

**Standard Profile** (default): Docker + Podman

- Docker for ease of use and docker-compose
- Podman for security-conscious workloads

**Minimal Profile**: containerd only

- Smallest footprint
- Production-grade

**Developer Profile**: All three

- Experiment with all options
- Learn differences
- Maximum flexibility

**Container-Focused Profile**: Docker + Podman + containerd

- All container options, minimal VM support

## Integration Strategy

### Docker Setup

```bash
# Boot-time (if selected)
tce-load -i docker
/usr/local/etc/init.d/docker start

# Create bridge
brctl addbr docker0

# Configure daemon
cat > /etc/docker/daemon.json << EOF
{
  "bridge": "docker0",
  "storage-driver": "overlay2"
}
EOF
```

### containerd Setup

```bash
# Boot-time (if selected)
tce-load -i containerd
/usr/local/etc/init.d/containerd start

# Configure CNI networking
mkdir -p /etc/cni/net.d
cat > /etc/cni/net.d/10-bridge.conf << EOF
{
  "cniVersion": "0.4.0",
  "name": "bridge",
  "type": "bridge",
  "bridge": "cni0",
  "isGateway": true,
  "ipMasq": true,
  "ipam": {
    "type": "host-local",
    "subnet": "10.88.0.0/16"
  }
}
EOF
```

## Compatibility Matrix

| Feature | Docker | containerd | Podman |
|---------|--------|------------|--------|
| OCI images | ✅ | ✅ | ✅ |
| Docker Hub | ✅ | ✅ | ✅ |
| docker-compose | ✅ | ❌ (external) | ✅ (podman-compose) |
| Rootless | ❌ | ⚠️ (complex) | ✅ |
| Kubernetes | ✅ (via shim) | ✅ (native) | ✅ |
| Daemonless | ❌ | ❌ | ✅ |
| Size | Large | Small | Medium |

## CLI Comparison

### Docker

```bash
docker run -d -p 80:80 nginx
docker ps
docker logs <container>
docker-compose up
```

### containerd

```bash
ctr image pull docker.io/library/nginx:latest
ctr run -d docker.io/library/nginx:latest nginx1
ctr task ls
ctr task exec --exec-id bash1 nginx1 bash
```

### Podman

```bash
podman run -d -p 80:80 nginx
podman ps
podman logs <container>
podman-compose up
```

## Final Recommendation

**For FlossWare VirtOS (Home Lab + Dev)**:

1. **Ship with Docker by default** - best UX for target audience
2. **Include containerd as alternative** - for minimal installs
3. **Document both** - let users choose
4. **Future**: Add Podman if security/rootless becomes priority

## Next Steps

1. Test Docker TCZ in Tiny Core 15.x
2. Test containerd TCZ availability
3. Build custom packages if needed
4. Create integration scripts for both
5. Document switching between them
