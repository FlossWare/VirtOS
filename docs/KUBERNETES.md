# Kubernetes on VirtOS

VirtOS supports running Kubernetes across your cluster for container orchestration.

## Why Kubernetes on VirtOS?

### Use Cases

✅ **Multi-host container orchestration** - Deploy containers across VirtOS cluster  
✅ **Auto-scaling** - Scale workloads based on demand  
✅ **Self-healing** - Automatically restart failed containers  
✅ **Load balancing** - Distribute traffic across replicas  
✅ **GitOps workflows** - Declarative infrastructure  
✅ **Learning platform** - Practice K8s in home lab  

### Why K3s (Not Full Kubernetes)?

VirtOS uses **K3s** - a lightweight, certified Kubernetes distribution:

| Feature | Full Kubernetes | K3s |
|---------|----------------|-----|
| **Size** | ~500MB+ | ~50MB |
| **Memory** | 2GB+ per node | 512MB+ per node |
| **Philosophy** | Data center | Edge, IoT, home lab |
| **Fit for VirtOS** | ❌ Too heavy | ✅ Perfect! |

K3s is **production-ready** and **100% Kubernetes compliant** - just optimized for resource-constrained environments.

## Architecture Options

### Option 1: K3s Cluster on VirtOS Hosts (Recommended)

Run K3s directly on VirtOS hosts - containers across all machines:

```
┌─────────────────────────────────────────────────┐
│  VirtOS Cluster                                 │
│                                                 │
│  virtos-1           virtos-2           virtos-3 │
│  ├─ K3s Server     ├─ K3s Agent      ├─ K3s Agent
│  ├─ Containers     ├─ Containers     ├─ Containers
│  └─ VMs (optional) └─ VMs (optional) └─ VMs     │
│                                                 │
│  Kubernetes manages containers across all nodes│
└─────────────────────────────────────────────────┘
```

**Best for**: Pure container workloads, microservices, cloud-native apps

### Option 2: K3s in VMs

Run K3s cluster inside VMs on VirtOS:

```
┌─────────────────────────────────────────────────┐
│  VirtOS Cluster                                 │
│                                                 │
│  virtos-1           virtos-2           virtos-3 │
│  ├─ VM: k3s-1      ├─ VM: k3s-2      ├─ VM: k3s-3
│  │   └─ K3s        │   └─ K3s        │   └─ K3s
│  └─ Other VMs      └─ Other VMs      └─ Other VMs
│                                                 │
│  K3s isolated in VMs, VirtOS manages VMs       │
└─────────────────────────────────────────────────┘
```

**Best for**: Isolation, testing K8s, learning, multi-tenancy

### Option 3: Hybrid

K3s on hosts + traditional VMs side-by-side:

```
┌─────────────────────────────────────────────────┐
│  VirtOS Cluster                                 │
│                                                 │
│  virtos-1           virtos-2           virtos-3 │
│  ├─ K3s (containers)                            │
│  │   └─ Web apps, APIs, microservices          │
│  ├─ VMs (traditional)                           │
│  │   └─ Databases, Windows, legacy apps        │
│                                                 │
│  Best of both worlds!                           │
└─────────────────────────────────────────────────┘
```

**Best for**: Home labs, mixed workloads, gradual K8s adoption

## Quick Start - K3s on VirtOS Hosts

### 1. Build Profile

Use the **kubernetes** profile or enable in build.conf:

```bash
# In build/build.conf
PROFILE="kubernetes"
# OR
INCLUDE_K3S="yes"
```

### 2. Install on First Node (Server)

On `virtos-1`:

```bash
# Install K3s server (control plane)
curl -sfL https://get.k3s.io | sh -

# Get node token for joining other nodes
sudo cat /var/lib/rancher/k3s/server/node-token
# Save this token!

# Verify
sudo k3s kubectl get nodes
```

### 3. Join Other Nodes (Agents)

On `virtos-2` and `virtos-3`:

```bash
# Replace with your virtos-1 IP and token
curl -sfL https://get.k3s.io | K3S_URL=https://virtos-1.local:6443 \
  K3S_TOKEN=<token-from-step-2> sh -

# Verify on virtos-1
sudo k3s kubectl get nodes
# Should show all 3 nodes
```

### 4. Deploy an Application

```bash
# On virtos-1 (or any node with kubectl access)
sudo k3s kubectl create deployment nginx --image=nginx
sudo k3s kubectl scale deployment nginx --replicas=3
sudo k3s kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Check pods distributed across cluster
sudo k3s kubectl get pods -o wide
```

**Result**: Nginx running across all 3 VirtOS nodes with automatic load balancing!

## Configuration

### VirtOS Build Configuration

In `build/build.conf`:

```bash
#==============================================================================
# KUBERNETES (yes/no)
#==============================================================================

# Enable Kubernetes support
INCLUDE_K3S="yes"

# K3s installation method
K3S_INSTALL="online"         # online, offline, manual
K3S_VERSION="latest"         # or specific version like "v1.28.5+k3s1"

# K3s configuration
K3S_ROLE="server"            # server, agent, both
K3S_DATASTORE="sqlite"       # sqlite, etcd, mysql, postgres

# Auto-start K3s at boot
AUTOSTART_K3S="no"           # Set to yes for production clusters
```

### K3s Server Configuration

Create `/etc/rancher/k3s/config.yaml` on server node:

```yaml
# K3s Server Configuration
write-kubeconfig-mode: "0644"
tls-san:
  - "virtos-1.local"
  - "192.168.1.101"

# Disable built-in components (optional)
disable:
  - traefik        # Use your own ingress
  - servicelb      # Use MetalLB instead

# Cluster CIDR
cluster-cidr: "10.42.0.0/16"
service-cidr: "10.43.0.0/16"

# Resource limits
kube-apiserver-arg:
  - "max-requests-inflight=400"
```

### K3s Agent Configuration

Create `/etc/rancher/k3s/config.yaml` on agent nodes:

```yaml
# K3s Agent Configuration
server: https://virtos-1.local:6443
token: <your-server-token>

# Node labels
node-label:
  - "node.kubernetes.io/instance-type=virtos"
  - "topology.kubernetes.io/zone=homelab"

# Resource reservations
kubelet-arg:
  - "system-reserved=cpu=500m,memory=512Mi"
  - "kube-reserved=cpu=500m,memory=512Mi"
```

## Integration with VirtOS Features

### With Clustering

K3s automatically integrates with VirtOS cluster discovery:

```bash
# VirtOS discovers nodes
virtos-cluster list
# Shows: virtos-1, virtos-2, virtos-3

# K3s uses same nodes
sudo k3s kubectl get nodes
# Shows: virtos-1, virtos-2, virtos-3

# Same infrastructure, dual management!
```

### With Container Runtimes

K3s works with VirtOS container runtimes:

- **containerd** (default) - K3s uses built-in containerd
- **Docker** - Can configure K3s to use Docker instead
- **Podman** - Not directly supported by K3s

```bash
# Use Docker runtime (if preferred)
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--docker" sh -
```

### With libvirt/VMs

Run K3s AND traditional VMs side-by-side:

```bash
# K3s manages containers
sudo k3s kubectl get pods --all-namespaces

# libvirt manages VMs
virsh list --all

# Both on same VirtOS infrastructure!
```

## Profiles

### New: kubernetes Profile

```bash
# build/build.conf
PROFILE="kubernetes"
```

Includes:

- K3s
- kubectl
- Helm (package manager)
- All container runtimes
- Minimal VMs (KVM available but not primary focus)
- Networking optimized for K8s
- ~250MB ISO

vs **containers** profile:

- containers = Docker/Podman/containerd without orchestration
- kubernetes = Same + K3s orchestration layer

## Common Workflows

### Deploy a Web App

```bash
# Create deployment
cat <<EOF | sudo k3s kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 6
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: mywebapp:latest
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  selector:
    app: webapp
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
EOF

# K3s distributes 6 replicas across virtos-1, virtos-2, virtos-3
# Automatically load balances traffic
```

### Persistent Storage

Use VirtOS cluster storage for K8s persistent volumes:

```bash
# Install NFS provisioner
sudo k3s kubectl apply -f \
  https://raw.githubusercontent.com/kubernetes-sigs/nfs-subdir-external-provisioner/master/deploy/rbac.yaml

# Configure NFS (using VirtOS shared storage)
cat <<EOF | sudo k3s kubectl apply -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: virtos-1.local
    path: /mnt/cluster-storage
EOF
```

### GitOps with Flux/ArgoCD

```bash
# Install Flux
curl -s https://fluxcd.io/install.sh | sudo bash
flux bootstrap github \
  --owner=your-github-user \
  --repository=homelab-k8s \
  --path=clusters/virtos

# Now git commits deploy to your VirtOS cluster!
```

## Management Tools

### kubectl

```bash
# Included with K3s
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -A

# Or install standalone kubectl
# Already included if INCLUDE_K3S="yes"
```

### Helm

```bash
# Install Helm (package manager)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install apps via Helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-nginx bitnami/nginx
```

### k9s (Terminal UI)

```bash
# Install k9s (interactive cluster management)
wget https://github.com/derailed/k9s/releases/download/v0.31.7/k9s_Linux_amd64.tar.gz
tar xzf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/

# Run
k9s
```

### Lens / OpenLens (Desktop GUI)

From your desktop:

```bash
# Copy kubeconfig from virtos-1
scp vmadmin@virtos-1.local:/etc/rancher/k3s/k3s.yaml ~/.kube/virtos-config

# Edit to use virtos-1.local instead of 127.0.0.1
sed -i 's/127.0.0.1/virtos-1.local/g' ~/.kube/virtos-config

# Open in Lens
# Add cluster with ~/.kube/virtos-config
```

## Networking

### Service Types

**ClusterIP** (default):

```bash
# Internal only
kubectl expose deployment myapp --port=80
```

**NodePort**:

```bash
# Accessible on each node's IP:port
kubectl expose deployment myapp --port=80 --type=NodePort
# Access: http://virtos-1.local:30080
```

**LoadBalancer**:

```bash
# External IP (uses K3s built-in load balancer)
kubectl expose deployment myapp --port=80 --type=LoadBalancer
# K3s assigns IP from service CIDR
```

### Ingress

K3s includes Traefik ingress by default:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp
spec:
  rules:
  - host: myapp.virtos.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp
            port:
              number: 80
```

Access via: `http://myapp.virtos.local`

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
spec:
  podSelector:
    matchLabels:
      app: backend
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

## Comparison: Direct Container Management vs K3s

| Feature | Docker/Podman Direct | K3s Orchestration |
|---------|---------------------|-------------------|
| **Learning Curve** | Easy | Moderate |
| **Overhead** | Low (~50MB) | Higher (~200MB) |
| **Multi-host** | Manual | Automatic |
| **Scaling** | Manual | Automatic |
| **Self-healing** | No | Yes |
| **Load balancing** | Manual | Automatic |
| **Rolling updates** | Manual | Built-in |
| **Best for** | Simple apps, learning | Production, complex apps |

**Recommendation**:

- Learning/home lab: Start with Docker/Podman
- Production workloads: Use K3s
- Hybrid: Both! Run K3s for microservices, Docker for one-offs

## Resource Requirements

### Minimum per Node

- **Server node**: 1 vCPU, 1GB RAM, 10GB storage
- **Agent node**: 1 vCPU, 512MB RAM, 5GB storage
- **Production**: 2+ vCPU, 2GB+ RAM per node

### VirtOS Recommendations

```bash
# Small cluster (home lab)
virtos-1: 4 vCPU, 8GB RAM  (K3s server + workloads)
virtos-2: 2 vCPU, 4GB RAM  (K3s agent)
virtos-3: 2 vCPU, 4GB RAM  (K3s agent)

# Medium cluster
virtos-1: 8 vCPU, 16GB RAM (K3s server + HA)
virtos-2: 8 vCPU, 16GB RAM (K3s server + HA)
virtos-3: 4 vCPU, 8GB RAM  (K3s agent)
```

## High Availability

For production, run multiple K3s servers:

```bash
# virtos-1 (server)
curl -sfL https://get.k3s.io | sh -

# virtos-2 (server, joins cluster)
curl -sfL https://get.k3s.io | \
  K3S_URL=https://virtos-1.local:6443 \
  K3S_TOKEN=<token> sh -s - server

# virtos-3 (server, joins cluster)
curl -sfL https://get.k3s.io | \
  K3S_URL=https://virtos-1.local:6443 \
  K3S_TOKEN=<token> sh -s - server

# 3-node HA control plane!
```

## Monitoring

### Built-in Metrics

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View resource usage
kubectl top nodes
kubectl top pods
```

### Prometheus + Grafana

```bash
# Install kube-prometheus-stack
helm repo add prometheus-community \
  https://prometheus-community.github.io/helm-charts

helm install monitoring prometheus-community/kube-prometheus-stack

# Access Grafana
kubectl port-forward svc/monitoring-grafana 3000:80
# Open: http://localhost:3000
```

## Use Cases

### 1. Microservices Platform

Deploy cloud-native apps across VirtOS cluster:

- Auto-scaling based on load
- Rolling updates
- Service mesh (Istio/Linkerd)
- CI/CD integration

### 2. Development Environment

Local K8s for dev/test:

- Match production (cloud) architecture
- Test Kubernetes manifests
- Learn K8s without cloud costs

### 3. Home Lab Services

Self-hosted apps:

- Media server (Plex, Jellyfin)
- Home automation
- Network services (Pi-hole, VPN)
- Databases and caches

### 4. Edge Computing

Run K3s on VirtOS at edge locations:

- IoT data processing
- Local ML inference
- Distributed applications

## Troubleshooting

### Nodes Not Joining

```bash
# Check K3s server is running
sudo systemctl status k3s

# Check firewall
sudo iptables -L | grep 6443

# Verify token
sudo cat /var/lib/rancher/k3s/server/node-token

# Check DNS resolution
ping virtos-1.local
```

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check node resources
kubectl top nodes
```

### Network Issues

```bash
# Check CNI
kubectl get pods -n kube-system | grep flannel

# Test pod-to-pod
kubectl run test --image=busybox -it --rm -- ping <other-pod-ip>
```

## When to Use Kubernetes on VirtOS

### ✅ Good Fit

- Running microservices across multiple VirtOS hosts
- Need auto-scaling and self-healing
- Want GitOps workflows
- Learning Kubernetes in home lab
- Cloud-native application development
- ≥3 VirtOS nodes available

### ❌ Not Ideal

- Single VirtOS host (Docker Compose is simpler)
- Only running VMs (use libvirt/virt-manager)
- Very limited resources (<4GB RAM total)
- Just learning containers (start with Docker first)
- Need Windows containers (use VMs)

## Migration Path

### Phase 1: Docker/Podman (Current)

- Direct container management
- Learning basics
- Simple deployments

### Phase 2: Docker Compose

- Multi-container apps
- Service definitions
- Still single-host

### Phase 3: K3s

- Multi-host orchestration
- Production workloads
- Auto-scaling, HA

**Recommendation**: Start simple, add K3s when you need orchestration!

## Quick Reference

| Task | Command |
|------|---------|
| Install K3s server | `curl -sfL https://get.k3s.io \| sh -` |
| Install K3s agent | `curl -sfL https://get.k3s.io \| K3S_URL=https://server:6443 K3S_TOKEN=<token> sh -` |
| Get nodes | `sudo k3s kubectl get nodes` |
| Deploy app | `sudo k3s kubectl create deployment <name> --image=<image>` |
| Scale app | `sudo k3s kubectl scale deployment <name> --replicas=3` |
| Expose service | `sudo k3s kubectl expose deployment <name> --port=80` |
| Get pods | `sudo k3s kubectl get pods -o wide` |
| Check logs | `sudo k3s kubectl logs <pod>` |
| Uninstall K3s | `sudo /usr/local/bin/k3s-uninstall.sh` |

## See Also

- [CLUSTERING.md](CLUSTERING.md) - VirtOS multi-host setup
- [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) - Docker/Podman/containerd
- [REMOTE-ACCESS.md](REMOTE-ACCESS.md) - Remote management
- [K3s Documentation](https://docs.k3s.io/)

## Example: Full Stack on VirtOS K3s

```yaml
# Deploy complete app stack
---
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
        app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: node:alpine
        ports:
        - containerPort: 3000
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
  namespace: myapp
spec:
  selector:
    app: frontend
  ports:
  - port: 80
  type: LoadBalancer
---
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: myapp
spec:
  selector:
    app: backend
  ports:
  - port: 3000
  type: ClusterIP
```

Apply: `sudo k3s kubectl apply -f stack.yaml`

**Result**: Full-stack app with 3 frontend and 3 backend replicas distributed across VirtOS cluster!
