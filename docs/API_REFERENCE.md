# VirtOS REST API Reference

**Version**: v1  
**Last Updated**: 2026-05-29  
**Status**: Production (with authentication required)

## Overview

The VirtOS REST API provides HTTP-based access to VirtOS management functions. It enables programmatic control of VMs, cluster operations, and system monitoring.

**Base URL**: `http://<virtos-host>:8080/api/v1`  
**Default Port**: 8080  
**Protocol**: HTTP/1.1  
**Authentication**: Basic Auth (planned), currently open

## Quick Start

### Start API Server

```bash
# Start on default port (8080)
virtos-api start

# Start on custom port
virtos-api start --port 9090

# Start on specific interface
virtos-api start --host 192.168.1.10 --port 8080
```

### Basic Request

```bash
# Health check
curl http://localhost:8080/api/v1/health

# List VMs
curl http://localhost:8080/api/v1/vms

# Get VM details
curl http://localhost:8080/api/v1/vms/web-1

# Start VM
curl -X POST http://localhost:8080/api/v1/vms/web-1/start
```

## API Endpoints

### Health & Status

#### GET /api/v1/health

Health check endpoint for monitoring.

**Response**: 200 OK

```json
{
  "status": "ok",
  "version": "0.22"
}
```

**Example**:

```bash
curl http://localhost:8080/api/v1/health
```

---

#### GET /api/v1/version

Get API version information.

**Response**: 200 OK

```json
{
  "version": "0.22",
  "api": "v1"
}
```

**Example**:

```bash
curl http://localhost:8080/api/v1/version
```

---

### Virtual Machines

#### GET /api/v1/vms

List all VMs with their current state.

**Response**: 200 OK

```json
{
  "vms": [
    {
      "name": "web-1",
      "state": "running"
    },
    {
      "name": "db-server",
      "state": "shut off"
    }
  ]
}
```

**Error Responses**:

- `503 Service Unavailable` - libvirt not available

**Example**:

```bash
curl http://localhost:8080/api/v1/vms
```

---

#### GET /api/v1/vms/{name}

Get detailed information about a specific VM.

**URL Parameters**:

- `name` (required) - VM name (alphanumeric, hyphens, underscores only)

**Response**: 200 OK

```json
{
  "name": "web-1",
  "state": "running",
  "cpu": 4,
  "memory": 8192
}
```

**Error Responses**:

- `400 Bad Request` - Invalid VM name format
- `404 Not Found` - VM not found
- `503 Service Unavailable` - libvirt not available

**Example**:

```bash
curl http://localhost:8080/api/v1/vms/web-1
```

**Security Note**: VM names are validated to prevent command injection. Only alphanumeric characters, hyphens, and underscores are allowed.

---

#### POST /api/v1/vms/{name}/start

Start a VM.

**URL Parameters**:

- `name` (required) - VM name (alphanumeric, hyphens, underscores only)

**Response**: 200 OK

```json
{
  "status": "started",
  "vm": "web-1"
}
```

**Error Responses**:

- `400 Bad Request` - Invalid VM name format
- `500 Internal Server Error` - Failed to start VM

**Example**:

```bash
curl -X POST http://localhost:8080/api/v1/vms/web-1/start
```

---

#### POST /api/v1/vms/{name}/stop

Stop (gracefully shutdown) a VM.

**URL Parameters**:

- `name` (required) - VM name (alphanumeric, hyphens, underscores only)

**Response**: 200 OK

```json
{
  "status": "stopping",
  "vm": "web-1"
}
```

**Error Responses**:

- `400 Bad Request` - Invalid VM name format
- `500 Internal Server Error` - Failed to stop VM

**Example**:

```bash
curl -X POST http://localhost:8080/api/v1/vms/web-1/stop
```

---

### Cluster

#### GET /api/v1/cluster

Get cluster status and member list.

**Response**: 200 OK

```json
{
  "nodes": [
    {
      "hostname": "virtos-1",
      "ip": "192.168.1.10"
    },
    {
      "hostname": "virtos-2",
      "ip": "192.168.1.11"
    }
  ]
}
```

**Error Responses**:

- `503 Service Unavailable` - Clustering not available

**Example**:

```bash
curl http://localhost:8080/api/v1/cluster
```

---

## Error Responses

All error responses follow this format:

```json
{
  "error": "Error message describing what went wrong"
}
```

### HTTP Status Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| 200 | OK | Request successful |
| 400 | Bad Request | Invalid input (VM name, parameters) |
| 404 | Not Found | VM or endpoint not found |
| 405 | Method Not Allowed | Wrong HTTP method for endpoint |
| 500 | Internal Server Error | Operation failed (e.g., failed to start VM) |
| 503 | Service Unavailable | Backend service (libvirt, clustering) not available |

## Security

### Input Validation

All API endpoints validate input to prevent security vulnerabilities:

**VM Names**:

- Must match: `^[a-zA-Z0-9_-]+$`
- Invalid names return `400 Bad Request`
- Examples:
  - ✅ Valid: `web-1`, `db_server`, `test-vm`
  - ❌ Invalid: `../etc/passwd`, `test; rm -rf /`, `vm name`

**Port Numbers** (when starting server):

- Must be 1-65535
- Ports < 1024 require root privileges
- Invalid ports rejected at startup

**Host Addresses** (when starting server):

- Must be valid IP address format
- Examples:
  - ✅ Valid: `0.0.0.0`, `192.168.1.10`, `localhost`
  - ❌ Invalid: `999.999.999.999`, `invalid-host`

### Authentication

**Current**: No authentication (development only)  
**Planned**: Basic authentication using VirtOS users (virtos-auth)

**When implemented**:

```bash
# With authentication
curl -u username:password http://localhost:8080/api/v1/vms

# Or using header
curl -H "Authorization: Basic <base64-encoded-credentials>" \
     http://localhost:8080/api/v1/vms
```

### HTTPS/TLS

**Current**: HTTP only  
**Planned**: HTTPS support with certificate configuration

**When implemented**:

```bash
virtos-api start --tls --cert /path/to/cert.pem --key /path/to/key.pem
```

### Security Best Practices

1. **Network Isolation**: Run API server on private network only
2. **Firewall**: Restrict access to trusted IPs
3. **Authentication**: Enable when available
4. **HTTPS**: Use TLS in production
5. **Rate Limiting**: Implement at reverse proxy level

## Client Examples

### Python

```python
import requests
import json

BASE_URL = "http://localhost:8080/api/v1"

# Health check
response = requests.get(f"{BASE_URL}/health")
print(response.json())

# List VMs
response = requests.get(f"{BASE_URL}/vms")
vms = response.json()['vms']
for vm in vms:
    print(f"{vm['name']}: {vm['state']}")

# Get VM details
response = requests.get(f"{BASE_URL}/vms/web-1")
vm = response.json()
print(f"CPU: {vm['cpu']}, Memory: {vm['memory']} MB")

# Start VM
response = requests.post(f"{BASE_URL}/vms/web-1/start")
if response.status_code == 200:
    print(f"VM started: {response.json()['vm']}")
else:
    print(f"Error: {response.json()['error']}")
```

### JavaScript/Node.js

```javascript
const axios = require('axios');

const BASE_URL = 'http://localhost:8080/api/v1';

// List VMs
async function listVMs() {
  try {
    const response = await axios.get(`${BASE_URL}/vms`);
    return response.data.vms;
  } catch (error) {
    console.error('Error:', error.response?.data?.error || error.message);
  }
}

// Start VM
async function startVM(vmName) {
  try {
    const response = await axios.post(`${BASE_URL}/vms/${vmName}/start`);
    console.log(`Started: ${response.data.vm}`);
  } catch (error) {
    console.error('Error:', error.response?.data?.error || error.message);
  }
}

// Usage
(async () => {
  const vms = await listVMs();
  console.log('VMs:', vms);

  await startVM('web-1');
})();
```

### Bash/curl

```bash
#!/bin/bash

BASE_URL="http://localhost:8080/api/v1"

# Health check
curl -s "$BASE_URL/health" | jq

# List VMs
curl -s "$BASE_URL/vms" | jq '.vms[] | "\(.name): \(.state)"'

# Start all stopped VMs
curl -s "$BASE_URL/vms" | jq -r '.vms[] | select(.state == "shut off") | .name' | while read vm; do
  echo "Starting $vm..."
  curl -X POST "$BASE_URL/vms/$vm/start"
  echo
done

# Get cluster status
curl -s "$BASE_URL/cluster" | jq
```

## Rate Limiting

**Current**: No rate limiting  
**Recommended**: Implement at reverse proxy (NGINX, HAProxy)

**NGINX Example**:

```nginx
limit_req_zone $binary_remote_addr zone=virtos_api:10m rate=10r/s;

location /api/ {
    limit_req zone=virtos_api burst=20;
    proxy_pass http://localhost:8080;
}
```

## Monitoring

### Prometheus Metrics (Planned)

Future endpoint: `GET /api/v1/metrics`

**Metrics**:

- `virtos_api_requests_total` - Total API requests
- `virtos_api_request_duration_seconds` - Request latency
- `virtos_vms_total` - Total VMs
- `virtos_vms_running` - Running VMs

### Health Checks

Use `/api/v1/health` for monitoring:

```bash
# Check if API is healthy
if curl -s http://localhost:8080/api/v1/health | grep -q '"status":"ok"'; then
  echo "API is healthy"
else
  echo "API is unhealthy"
  exit 1
fi
```

## Versioning

**Current Version**: v1  
**Path**: `/api/v1/...`

Future API changes will use new versions (`/api/v2/...`) to maintain backward compatibility.

## Changelog

### v1 (Current)

- Initial API release
- VM management endpoints
- Cluster status endpoint
- Health and version endpoints
- Input validation and security hardening

## Troubleshooting

### API Server Won't Start

**Problem**: Port already in use

```bash
# Check what's using the port
sudo netstat -tlnp | grep 8080

# Use different port
virtos-api start --port 9090
```

**Problem**: Permission denied for port < 1024

```bash
# Use port >= 1024 or run as root
virtos-api start --port 8080  # OK
virtos-api start --port 80     # Needs root
```

### Connection Refused

**Problem**: Firewall blocking port

```bash
# Allow port in firewall
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --reload
```

### 503 Service Unavailable

**Problem**: libvirt not running

```bash
# Start libvirt
sudo systemctl start libvirtd

# Check status
sudo systemctl status libvirtd
```

## Related Documentation

- [Security Hardening Guide](SECURITY_HARDENING.md) - API security best practices
- [Architecture](ARCHITECTURE.md) - VirtOS architecture overview
- [Web UI](WEB-UI.md) - Cockpit web interface (alternative to API)

## Support

- **GitHub Issues**: <https://github.com/FlossWare/VirtOS/issues>
- **Community**: [COMMUNITY.md](../COMMUNITY.md)
- **Security**: Report security issues privately

---

**Last Updated**: 2026-05-29  
**API Version**: v1  
**Related Issues**: #133 (Documentation), #116 (Security)
