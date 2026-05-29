# VirtOS REST API Reference

**Last Updated**: 2026-05-29  
**API Version**: v1  
**Server**: virtos-api

## Overview

The VirtOS REST API provides programmatic access to VM management, cluster status, and system health.

**Base URL**: `http://localhost:8080/api/v1`  
**Authentication**: Basic Auth (optional, via virtos-auth)  
**Content-Type**: `application/json`

## Quick Start

### Start the API Server

```bash
# Start on default port (8080)
virtos-api

# Start on custom port
virtos-api --port 9090

# Start on specific interface
virtos-api --host 192.168.1.100 --port 8080
```

### Example Request

```bash
# List all VMs
curl http://localhost:8080/api/v1/vms

# Get VM details
curl http://localhost:8080/api/v1/vms/web-01

# Start a VM
curl -X POST http://localhost:8080/api/v1/vms/web-01/start
```

## Authentication

**Optional** - Basic HTTP authentication using VirtOS users.

```bash
# With authentication
curl -u admin:password http://localhost:8080/api/v1/vms

# Without authentication (if virtos-auth not configured)
curl http://localhost:8080/api/v1/vms
```

**Note**: Authentication is only enforced if `virtos-auth` is configured.

## Endpoints

### Virtual Machines

#### List VMs

**GET** `/api/v1/vms`

Returns a list of all virtual machines.

**Request**: None

**Response** (200 OK):
```json
{
  "vms": [
    {
      "name": "web-01",
      "state": "running",
      "id": 1,
      "cpu": 4,
      "memory": 8388608
    },
    {
      "name": "db-01",
      "state": "shut off",
      "id": 2,
      "cpu": 8,
      "memory": 16777216
    }
  ]
}
```

**Fields**:
- `name` (string): VM name
- `state` (string): VM state (running, shut off, paused, etc.)
- `id` (integer): VM ID
- `cpu` (integer): Number of vCPUs
- `memory` (integer): RAM in KB

**Errors**:
- `500 Internal Server Error`: virsh command failed

**Example**:
```bash
curl http://localhost:8080/api/v1/vms
```

---

#### Get VM Details

**GET** `/api/v1/vms/{name}`

Get detailed information for a specific VM.

**Parameters**:
- `name` (string, path, required): VM name

**Response** (200 OK):
```json
{
  "name": "web-01",
  "state": "running",
  "id": 1,
  "cpu": 4,
  "memory": 8388608,
  "uuid": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Errors**:
- `404 Not Found`: VM does not exist
- `500 Internal Server Error`: virsh command failed

**Example**:
```bash
curl http://localhost:8080/api/v1/vms/web-01
```

---

#### Start VM

**POST** `/api/v1/vms/{name}/start`

Start a stopped or paused VM.

**Parameters**:
- `name` (string, path, required): VM name

**Request Body**: None

**Response** (200 OK):
```json
{
  "status": "started",
  "vm": "web-01"
}
```

**Errors**:
- `404 Not Found`: VM does not exist
- `500 Internal Server Error`: Failed to start VM (already running, etc.)

**Example**:
```bash
curl -X POST http://localhost:8080/api/v1/vms/web-01/start
```

---

#### Stop VM

**POST** `/api/v1/vms/{name}/stop`

Gracefully shutdown a running VM.

**Parameters**:
- `name` (string, path, required): VM name

**Request Body**: None

**Response** (200 OK):
```json
{
  "status": "stopping",
  "vm": "web-01"
}
```

**Fields**:
- `status`: "stopping" (shutdown initiated, not immediate)
- `vm`: VM name

**Errors**:
- `404 Not Found`: VM does not exist
- `500 Internal Server Error`: Failed to stop VM

**Example**:
```bash
curl -X POST http://localhost:8080/api/v1/vms/web-01/stop
```

**Note**: This performs a graceful shutdown. The VM may take several seconds to stop.

---

### Cluster

#### Get Cluster Status

**GET** `/api/v1/cluster`

Returns status of all cluster nodes.

**Request**: None

**Response** (200 OK):
```json
{
  "nodes": [
    {
      "hostname": "virtos-1.local",
      "ip": "192.168.1.10",
      "status": "online"
    },
    {
      "hostname": "virtos-2.local",
      "ip": "192.168.1.11",
      "status": "online"
    }
  ]
}
```

**Fields**:
- `hostname` (string): Node hostname
- `ip` (string): Node IP address
- `status` (string): Node status (online, offline)

**Errors**:
- `500 Internal Server Error`: Failed to query cluster

**Example**:
```bash
curl http://localhost:8080/api/v1/cluster
```

---

### System

#### Health Check

**GET** `/api/v1/health`

Health check endpoint for monitoring.

**Request**: None

**Response** (200 OK):
```json
{
  "status": "healthy",
  "api_version": "v1",
  "uptime": 3600
}
```

**Fields**:
- `status` (string): "healthy" or "degraded"
- `api_version` (string): API version
- `uptime` (integer): API server uptime in seconds

**Example**:
```bash
curl http://localhost:8080/api/v1/health
```

**Use Case**: Add to monitoring systems (Nagios, Prometheus, etc.)

---

#### Get API Version

**GET** `/api/v1/version`

Returns API version information.

**Request**: None

**Response** (200 OK):
```json
{
  "api_version": "v1",
  "virtos_version": "0.87",
  "server": "virtos-api"
}
```

**Fields**:
- `api_version` (string): API version
- `virtos_version` (string): VirtOS version
- `server` (string): Server identifier

**Example**:
```bash
curl http://localhost:8080/api/v1/version
```

---

## HTTP Status Codes

| Code | Meaning | When Returned |
|------|---------|---------------|
| 200 | OK | Request successful |
| 404 | Not Found | VM or resource doesn't exist |
| 500 | Internal Server Error | virsh command failed, system error |

## Error Response Format

All errors return JSON with an `error` field:

```json
{
  "error": "Failed to start VM"
}
```

Or:

```json
{
  "error": "VM not found",
  "vm": "nonexistent-vm"
}
```

## Complete Example Workflow

### Managing a VM Lifecycle

```bash
# 1. List all VMs
curl http://localhost:8080/api/v1/vms

# 2. Get details for specific VM
curl http://localhost:8080/api/v1/vms/web-01

# 3. Start the VM
curl -X POST http://localhost:8080/api/v1/vms/web-01/start

# 4. Verify it's running
curl http://localhost:8080/api/v1/vms/web-01

# 5. Stop the VM
curl -X POST http://localhost:8080/api/v1/vms/web-01/stop
```

### Monitoring Script

```bash
#!/bin/bash
# Monitor VirtOS API health

API_URL="http://localhost:8080/api/v1"

# Check health
if ! curl -sf "$API_URL/health" > /dev/null; then
    echo "API is DOWN"
    exit 1
fi

# List VMs
VMS=$(curl -s "$API_URL/vms" | jq -r '.vms[].name')

for vm in $VMS; do
    STATE=$(curl -s "$API_URL/vms/$vm" | jq -r '.state')
    echo "$vm: $STATE"
done
```

### Integration with Prometheus

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'virtos-api'
    metrics_path: '/api/v1/health'
    static_configs:
      - targets: ['localhost:8080']
```

## Client Libraries

### Python

```python
import requests

class VirtOSClient:
    def __init__(self, base_url="http://localhost:8080/api/v1"):
        self.base_url = base_url
    
    def list_vms(self):
        r = requests.get(f"{self.base_url}/vms")
        return r.json()["vms"]
    
    def start_vm(self, name):
        r = requests.post(f"{self.base_url}/vms/{name}/start")
        return r.json()

# Usage
client = VirtOSClient()
vms = client.list_vms()
print(f"Found {len(vms)} VMs")

client.start_vm("web-01")
```

### Shell (curl wrapper)

```bash
#!/bin/bash
# virtos-api-client.sh

API_URL="${VIRTOS_API_URL:-http://localhost:8080/api/v1}"

virtos_api_list() {
    curl -s "$API_URL/vms" | jq '.vms'
}

virtos_api_start() {
    local vm="$1"
    curl -X POST -s "$API_URL/vms/$vm/start"
}

virtos_api_stop() {
    local vm="$1"
    curl -X POST -s "$API_URL/vms/$vm/stop"
}

# Usage:
# virtos_api_list
# virtos_api_start web-01
```

## Security Considerations

### Current State

- ⚠️ **No authentication by default** (optional via virtos-auth)
- ⚠️ **HTTP only** (no HTTPS/TLS)
- ⚠️ **No rate limiting**
- ⚠️ **No CORS headers**

### Production Recommendations

1. **Enable Authentication**:
   ```bash
   virtos-auth setup
   virtos-api --require-auth
   ```

2. **Use Reverse Proxy** (NGINX/Apache):
   ```nginx
   # NGINX config
   server {
       listen 443 ssl;
       ssl_certificate /path/to/cert.pem;
       ssl_certificate_key /path/to/key.pem;
       
       location /api/ {
           proxy_pass http://localhost:8080/api/;
       }
   }
   ```

3. **Firewall Rules**:
   ```bash
   # Only allow from specific network
   iptables -A INPUT -p tcp --dport 8080 -s 192.168.1.0/24 -j ACCEPT
   iptables -A INPUT -p tcp --dport 8080 -j DROP
   ```

4. **API Gateway**: Consider using Kong, Traefik, or similar for:
   - Rate limiting
   - Authentication
   - TLS termination
   - Request logging

## Troubleshooting

### API Server Won't Start

```bash
# Check if port is in use
netstat -tulpn | grep 8080

# Check virtos-api logs
journalctl -u virtos-api

# Test manually
virtos-api --port 9090
```

### 500 Errors

```bash
# Verify libvirt is running
systemctl status libvirtd

# Test virsh directly
virsh list --all

# Check API server logs
```

### Connection Refused

```bash
# Verify server is running
ps aux | grep virtos-api

# Check firewall
iptables -L -n | grep 8080

# Test locally first
curl http://localhost:8080/api/v1/health
```

## Limitations

- **Read-only for most operations**: Cannot create/delete VMs via API (use virtos-create-vm)
- **No streaming**: No WebSocket support for live updates
- **Limited filtering**: Cannot filter VMs by state, tags, etc.
- **No pagination**: All VMs returned at once
- **Basic error messages**: Limited error context

## Future Enhancements

Planned features (see roadmap):
- [ ] VM creation/deletion via API
- [ ] WebSocket support for real-time updates
- [ ] Filtering and pagination
- [ ] Snapshot management endpoints
- [ ] Network management endpoints
- [ ] Storage pool endpoints
- [ ] JWT authentication
- [ ] OpenAPI/Swagger specification

## Related Documentation

- [virtos-api Script](../config/custom-scripts/virtos-api) - API server implementation
- [Web UI Documentation](WEB-UI.md) - Web interface using this API
- [Authentication Guide](../README.md#security) - Setting up virtos-auth
- [Architecture](ARCHITECTURE.md) - System design

## See Also

- [Monitoring Guide](MONITORING-SETUP.md) - Integrating with monitoring systems
- [Security Guide](../README.md#security-recommendations) - API security best practices

---

**Quick Reference**:
- `GET /api/v1/vms` - List VMs
- `GET /api/v1/vms/{name}` - VM details
- `POST /api/v1/vms/{name}/start` - Start VM
- `POST /api/v1/vms/{name}/stop` - Stop VM
- `GET /api/v1/cluster` - Cluster status
- `GET /api/v1/health` - Health check
- `GET /api/v1/version` - API version
