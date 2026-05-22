# Microservices on VirtOS

VirtOS provides a complete platform for deploying microservice architectures. This guide shows how to run microservices using the container runtimes and orchestration tools included in VirtOS.

## Overview

VirtOS supports microservices through:
- **Container Runtimes** - Docker, Podman, containerd (all optional)
- **docker-compose** - Simple multi-service orchestration
- **K3s (Kubernetes)** - Production-grade orchestration (optional)
- **Clustering** - Deploy across multiple VirtOS hosts
- **Networking** - Bridge networking, NAT, service discovery

## Philosophy

VirtOS provides the **infrastructure layer** - compute, networking, storage. Microservice tools (service mesh, monitoring, message brokers) are **applications** that you deploy on VirtOS using containers or K3s.

**VirtOS is the soil, not the garden.** You choose what to plant.

## Quick Start Examples

### Example 1: Simple API + Database (docker-compose)

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - db-data:/var/lib/postgresql/data
    networks:
      - backend
  
  api:
    image: myorg/api:v1
    environment:
      DATABASE_URL: postgres://postgres:secret@db:5432/myapp
    depends_on:
      - db
    networks:
      - backend
      - frontend
    ports:
      - "8080:8080"
  
  worker:
    image: myorg/worker:v1
    environment:
      DATABASE_URL: postgres://postgres:secret@db:5432/myapp
    depends_on:
      - db
    networks:
      - backend
    deploy:
      replicas: 3

networks:
  frontend:
  backend:

volumes:
  db-data:
```

Deploy:

```bash
docker-compose up -d

# View status
docker-compose ps

# View logs
docker-compose logs -f api

# Scale workers
docker-compose up -d --scale worker=5
```

### Example 2: Multi-Tier App (K3s)

Create `app.yaml`:

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
  namespace: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: database
  template:
    metadata:
      labels:
        app: database
    spec:
      containers:
      - name: postgres
        image: postgres:15
        env:
        - name: POSTGRES_PASSWORD
          value: secret
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: data
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: database
  namespace: myapp
spec:
  selector:
    app: database
  ports:
  - port: 5432
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  namespace: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: myorg/api:v1
        env:
        - name: DATABASE_URL
          value: postgres://postgres:secret@database:5432/myapp
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: api
  namespace: myapp
spec:
  selector:
    app: api
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: worker
  namespace: myapp
spec:
  replicas: 5
  selector:
    matchLabels:
      app: worker
  template:
    metadata:
      labels:
        app: worker
    spec:
      containers:
      - name: worker
        image: myorg/worker:v1
        env:
        - name: DATABASE_URL
          value: postgres://postgres:secret@database:5432/myapp
```

Deploy:

```bash
sudo k3s kubectl apply -f app.yaml

# View status
sudo k3s kubectl get all -n myapp

# Scale
sudo k3s kubectl scale deployment/worker -n myapp --replicas=10

# View logs
sudo k3s kubectl logs -n myapp -l app=api -f
```

## Architecture Patterns

### 1. Single Host Development

**Best for:** Development, testing, small deployments

**Setup:**
- VirtOS with Docker or Podman
- docker-compose for orchestration
- Local storage
- Single network bridge

**Pros:**
- Simple setup
- Fast iteration
- Low resource usage

**Cons:**
- No high availability
- Limited scaling
- Single point of failure

### 2. Multi-Host with docker-compose

**Best for:** Small production, staging environments

**Setup:**
- Multiple VirtOS hosts with Docker
- docker-compose on each host
- Manual load balancing (nginx, HAProxy)
- Shared storage (NFS, optional)

**Example:**
```bash
# Host 1: API servers
docker-compose -f api-compose.yml up -d

# Host 2: Worker servers  
docker-compose -f worker-compose.yml up -d

# Host 3: Database
docker-compose -f db-compose.yml up -d
```

### 3. K3s Cluster

**Best for:** Production, auto-scaling, high availability

**Setup:**
- Multiple VirtOS hosts with K3s
- Automatic orchestration
- Built-in load balancing
- Service discovery
- Self-healing

**Example:**
```bash
# Deploy once, K3s handles placement
kubectl apply -f app.yaml

# K3s automatically:
# - Spreads pods across nodes
# - Load balances traffic
# - Restarts failed containers
# - Scales based on load
```

## Common Microservice Patterns

### API Gateway Pattern

**Using nginx:**

```yaml
# nginx-gateway.yml
version: '3.8'
services:
  gateway:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    networks:
      - frontend
  
  users-api:
    image: myorg/users-api:v1
    networks:
      - frontend
  
  orders-api:
    image: myorg/orders-api:v1
    networks:
      - frontend

networks:
  frontend:
```

**nginx.conf:**
```nginx
http {
    upstream users {
        server users-api:8080;
    }
    
    upstream orders {
        server orders-api:8080;
    }
    
    server {
        listen 80;
        
        location /api/users {
            proxy_pass http://users;
        }
        
        location /api/orders {
            proxy_pass http://orders;
        }
    }
}
```

### Event-Driven Pattern

**Using NATS message broker:**

```yaml
# event-driven.yml
version: '3.8'
services:
  nats:
    image: nats:alpine
    ports:
      - "4222:4222"
    networks:
      - backend
  
  publisher:
    image: myorg/publisher:v1
    environment:
      NATS_URL: nats://nats:4222
    networks:
      - backend
  
  subscriber-1:
    image: myorg/subscriber:v1
    environment:
      NATS_URL: nats://nats:4222
    networks:
      - backend
    deploy:
      replicas: 3

networks:
  backend:
```

### Service Discovery Pattern

**Using K3s built-in DNS:**

```yaml
# Service A can reach Service B via DNS
apiVersion: v1
kind: Service
metadata:
  name: service-b
spec:
  selector:
    app: service-b
  ports:
  - port: 8080

# From Service A, connect to: http://service-b:8080
# K3s DNS automatically resolves service-b to correct pods
```

## Observability

### Logging Stack (Loki + Promtail + Grafana)

Deploy on K3s:

```bash
# Add Grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Loki stack
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.enabled=true \
  --set prometheus.enabled=true

# Get Grafana password
kubectl get secret --namespace monitoring loki-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode

# Access Grafana
kubectl port-forward --namespace monitoring \
  svc/loki-grafana 3000:80
```

### Metrics (Prometheus + Grafana)

```bash
# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Access Prometheus
kubectl port-forward -n monitoring \
  svc/prometheus-kube-prometheus-prometheus 9090:9090

# Access Grafana
kubectl port-forward -n monitoring \
  svc/prometheus-grafana 3000:80
```

### Distributed Tracing (Jaeger)

```bash
# Install Jaeger operator
kubectl create namespace observability
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.51.0/jaeger-operator.yaml -n observability

# Deploy Jaeger instance
cat <<EOF | kubectl apply -f -
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: observability
spec:
  strategy: allInOne
EOF

# Access Jaeger UI
kubectl port-forward -n observability \
  svc/jaeger-query 16686:16686
```

## Service Mesh (Optional)

### Linkerd (Lightweight)

```bash
# Install Linkerd CLI
curl -sL https://run.linkerd.io/install | sh

# Install Linkerd
linkerd install | kubectl apply -f -

# Verify
linkerd check

# Inject into namespace
kubectl get deploy -n myapp -o yaml | \
  linkerd inject - | \
  kubectl apply -f -

# View dashboard
linkerd dashboard
```

### Istio (Full-Featured)

```bash
# Install istioctl
curl -L https://istio.io/downloadIstio | sh -

# Install Istio
istioctl install --set profile=default -y

# Enable injection
kubectl label namespace myapp istio-injection=enabled

# Redeploy apps to inject sidecars
kubectl rollout restart deployment -n myapp

# View with Kiali
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml
kubectl port-forward -n istio-system svc/kiali 20001:20001
```

## Message Brokers

### NATS (Recommended - Lightweight)

```bash
# Docker
docker run -d --name nats -p 4222:4222 nats:alpine

# K3s
helm repo add nats https://nats-io.github.io/k8s/helm/charts/
helm install nats nats/nats --namespace messaging --create-namespace
```

**Why NATS:**
- Lightweight (~10MB)
- Cloud-native
- High performance
- Simple deployment

### RabbitMQ (Traditional)

```bash
# Docker
docker run -d --name rabbitmq \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:management

# K3s
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install rabbitmq bitnami/rabbitmq \
  --namespace messaging \
  --create-namespace
```

### Kafka (High Throughput)

```bash
# K3s (with Strimzi operator)
kubectl create namespace kafka
kubectl create -f 'https://strimzi.io/install/latest?namespace=kafka' -n kafka

# Create Kafka cluster
cat <<EOF | kubectl apply -f -
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: my-cluster
  namespace: kafka
spec:
  kafka:
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF
```

## Databases for Microservices

### PostgreSQL (Relational)

```yaml
# docker-compose
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
```

### Redis (Cache/Session Store)

```yaml
# docker-compose
services:
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
```

### MongoDB (Document Store)

```yaml
# docker-compose
services:
  mongo:
    image: mongo:latest
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: secret
    volumes:
      - mongo-data:/data/db
    ports:
      - "27017:27017"
```

## CI/CD Integration

### GitLab Runner on VirtOS

```bash
# Install GitLab Runner
docker run -d --name gitlab-runner \
  --restart always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v gitlab-runner-config:/etc/gitlab-runner \
  gitlab/gitlab-runner:latest

# Register runner
docker exec -it gitlab-runner \
  gitlab-runner register \
  --url https://gitlab.com \
  --executor docker \
  --docker-image docker:latest
```

### Jenkins on K3s

```bash
helm repo add jenkins https://charts.jenkins.io
helm repo update

helm install jenkins jenkins/jenkins \
  --namespace ci-cd \
  --create-namespace \
  --set controller.serviceType=LoadBalancer
```

## Production Best Practices

### 1. Resource Limits

Always set resource limits:

```yaml
# K3s
spec:
  containers:
  - name: api
    resources:
      requests:
        memory: "256Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"
        cpu: "500m"
```

### 2. Health Checks

```yaml
# K3s
spec:
  containers:
  - name: api
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5
      periodSeconds: 5
```

### 3. Configuration Management

Use ConfigMaps and Secrets:

```bash
# Create ConfigMap
kubectl create configmap app-config \
  --from-file=config.json

# Create Secret
kubectl create secret generic db-credentials \
  --from-literal=password=secret123

# Use in deployment
spec:
  containers:
  - name: api
    envFrom:
    - configMapRef:
        name: app-config
    - secretRef:
        name: db-credentials
```

### 4. Persistent Storage

```yaml
# K3s with PersistentVolumeClaim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-storage
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
spec:
  containers:
  - name: database
    volumeMounts:
    - name: data
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: db-storage
```

### 5. Network Policies

Restrict traffic between services:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-policy
  namespace: myapp
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
```

## Migration Path

### Phase 1: Development (Single Host)
- VirtOS with Docker
- docker-compose
- Local testing

### Phase 2: Staging (Multi-Host)
- Multiple VirtOS instances
- virtos-cluster for coordination
- Still using docker-compose

### Phase 3: Production (K3s)
- K3s cluster across VirtOS hosts
- Automated orchestration
- Monitoring and logging
- Service mesh (optional)

## Example Templates

For ready-to-deploy examples, see:
**https://github.com/FlossWare/VirtOS-Examples**

Available templates:
- `microservices-basic/` - Simple API + DB + Worker
- `microservices-k8s/` - K3s multi-tier app
- `api-gateway/` - nginx API gateway pattern
- `event-driven/` - NATS messaging
- `observability/` - Prometheus + Grafana + Loki
- `service-mesh/` - Linkerd setup
- `ci-cd/` - Jenkins + GitLab Runner

## Tools Comparison

| Tool | Size | Complexity | Best For |
|------|------|------------|----------|
| docker-compose | Small | Low | Dev, small apps |
| K3s | ~50MB | Medium | Production, scaling |
| Linkerd | ~50MB | Medium | Service mesh (simple) |
| Istio | ~200MB | High | Full service mesh |
| NATS | ~10MB | Low | Messaging (simple) |
| RabbitMQ | ~40MB | Medium | Traditional messaging |
| Kafka | ~100MB+ | High | Event streaming |
| Prometheus | ~30MB | Medium | Metrics |
| Grafana | ~30MB | Low | Dashboards |

## Getting Help

1. Check example templates: [VirtOS-Examples](https://github.com/FlossWare/VirtOS-Examples)
2. See [KUBERNETES.md](KUBERNETES.md) for K3s details
3. See [CLUSTERING.md](CLUSTERING.md) for multi-host setup
4. See [CONTAINER-RUNTIMES.md](CONTAINER-RUNTIMES.md) for runtime comparison

## Summary

**VirtOS provides the platform:**
- Container runtimes (Docker, Podman, containerd)
- Orchestration (K3s optional)
- Networking (bridge, NAT, service discovery)
- Clustering (multi-host coordination)

**You deploy the applications:**
- Your microservices
- Message brokers
- Databases
- Monitoring tools
- Service mesh

**Start simple, scale as needed:**
1. docker-compose for development
2. Multi-host for staging
3. K3s for production
4. Add observability when needed
5. Add service mesh if required

VirtOS is the foundation - build your architecture on top!
