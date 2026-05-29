# VirtOS Web UI Guide

**Last Updated**: 2026-05-28  
**Status**: Functional (Cockpit integration)

---

## Overview

VirtOS provides web-based management through **two complementary tools**:

1. **virtos-web** - Web UI integration (Cockpit, Portainer)
2. **virtos-api** - REST API server for automation and custom clients

Both are **functional with working backends** and ready to use.

---

## Quick Start

### Install and Start Web UI

```bash
# Install Cockpit web console
virtos-web install cockpit

# Start web UI server
virtos-web start

# Access in browser
# https://your-virtos-host:9090
# (default credentials: your VirtOS user account)
```

### Start REST API

```bash
# Start API server (default port 8080)
virtos-api start

# Test API
curl http://localhost:8080/api/v1/health
```

---

## Web UI (Cockpit)

### What is Cockpit?

[Cockpit](https://cockpit-project.org/) is a **Red Hat-developed** web console for Linux servers:
- Lightweight (~5MB installed)
- Secure (HTTPS, PAM authentication)
- Extensible (plugin architecture)
- Actively maintained
- Used by Red Hat, Fedora, Ubuntu

### Features Available in VirtOS

#### System Monitoring
- **Dashboard**: CPU, RAM, disk, network graphs
- **Real-time metrics**: Live updates every second
- **Historical data**: Charts show trends over time
- **Disk usage**: Visual breakdown by filesystem

#### Virtual Machine Management
- **VM List**: All VMs with status (running/stopped)
- **VM Control**: Start, stop, restart, force stop
- **VM Creation**: Wizard-based VM builder
- **VM Details**: CPU, RAM, disk, network configuration
- **Console Access**: VNC/SPICE console in browser

#### System Administration
- **Services**: Start/stop systemd services
- **Logs**: System logs with filtering, search, and live tail
- **Terminal**: Web-based SSH console
- **Networking**: Network interfaces, firewall, bonds
- **Storage**: Disks, partitions, RAID, LVM
- **User Accounts**: Manage users and groups

### Cockpit Modules for VirtOS

**Automatically available**:
- `cockpit-system` - Base system management
- `cockpit-machines` - Virtual machine management (libvirt)
- `cockpit-storaged` - Storage management
- `cockpit-networkmanager` - Network configuration
- `cockpit-podman` - Container management (if installed)

**VirtOS-specific module** (future):
- Custom VirtOS dashboard
- Cluster view (multi-host management)
- VirtOS-specific workflows
- Integration with virtos-* scripts

---

## REST API (virtos-api)

### Starting the API Server

```bash
# Default (port 8080)
virtos-api start

# Custom port
virtos-api start --port 9090

# Custom bind address
virtos-api start --host 0.0.0.0 --port 8080
```

### API Endpoints

#### Virtual Machines

**List all VMs**:
```bash
curl http://localhost:8080/api/v1/vms
```

Response:
```json
[
  {
    "name": "web-01",
    "state": "running",
    "cpu": 4,
    "ram": 8192,
    "disk": "50G"
  },
  {
    "name": "db-01",
    "state": "stopped",
    "cpu": 8,
    "ram": 16384,
    "disk": "100G"
  }
]
```

**Get VM details**:
```bash
curl http://localhost:8080/api/v1/vms/web-01
```

**Start VM**:
```bash
curl -X POST http://localhost:8080/api/v1/vms/web-01/start
```

**Stop VM**:
```bash
curl -X POST http://localhost:8080/api/v1/vms/web-01/stop
```

#### Cluster Management

**Cluster status**:
```bash
curl http://localhost:8080/api/v1/cluster
```

Response:
```json
{
  "nodes": [
    {
      "hostname": "virtos-1",
      "ip": "192.168.1.101",
      "status": "up",
      "vms": 4
    },
    {
      "hostname": "virtos-2",
      "ip": "192.168.1.102",
      "status": "up",
      "vms": 2
    }
  ]
}
```

#### Health Check

**API health**:
```bash
curl http://localhost:8080/api/v1/health
```

Response:
```json
{
  "status": "healthy",
  "version": "0.89",
  "uptime": "2d 14h 32m"
}
```

**API version**:
```bash
curl http://localhost:8080/api/v1/version
```

---

## Security

### Cockpit Security

**HTTPS by default**:
- Cockpit uses self-signed certificate on first run
- Can be replaced with proper TLS certificate

**Authentication**:
- PAM-based (uses system users)
- Session timeout: 15 minutes (configurable)
- Two-factor authentication supported

**Firewall**:
```bash
# Allow Cockpit (port 9090)
firewall-cmd --add-service=cockpit --permanent
firewall-cmd --reload
```

**Custom certificate** (optional):
```bash
# Place your certificate
cat > /etc/cockpit/ws-certs.d/virtos.cert <<EOF
-----BEGIN CERTIFICATE-----
[your certificate]
-----END CERTIFICATE-----
-----BEGIN PRIVATE KEY-----
[your private key]
-----END PRIVATE KEY-----
EOF

# Restart Cockpit
systemctl restart cockpit
```

### API Security

**Access control**:
```bash
# Bind to localhost only (default, secure)
virtos-api start --host 127.0.0.1

# Bind to all interfaces (use with firewall!)
virtos-api start --host 0.0.0.0
```

**Firewall** (if exposing API externally):
```bash
# Allow API port
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
```

**Future enhancements**:
- API authentication (tokens, basic auth)
- HTTPS support (TLS)
- Rate limiting
- RBAC (role-based access control)

---

## Configuration

### Cockpit Configuration

**Main config** (`/etc/cockpit/cockpit.conf`):
```ini
[WebService]
Origins = https://virtos-host:9090 wss://virtos-host:9090
ProtocolHeader = X-Forwarded-Proto
LoginTitle = VirtOS Management Console
MaxStartups = 20
AllowUnencrypted = false

[Session]
IdleTimeout = 15
Banner = /etc/virtos/banner.txt
```

**VirtOS customization**:
```bash
# Set custom login banner
cat > /etc/virtos/banner.txt <<EOF
 __      ___      _    ___  ____  
 \ \    / (_)_ __| |_ / _ \/ ___| 
  \ \  / /| | '__| __| | | \___ \ 
   \ \/ / | | |  | |_| |_| |___) |
    \__/  |_|_|   \__|\___/|____/ 
                                  
 Welcome to VirtOS Management Console
EOF
```

### API Configuration

**Environment variables**:
```bash
# Set API port
export API_PORT=9090

# Set bind address
export API_HOST=0.0.0.0

# Start API
virtos-api start
```

**Systemd service** (auto-start on boot):
```bash
# Create systemd service
cat > /etc/systemd/system/virtos-api.service <<EOF
[Unit]
Description=VirtOS REST API Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/virtos-api start
Restart=always
Environment="API_PORT=8080"
Environment="API_HOST=127.0.0.1"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
systemctl enable virtos-api
systemctl start virtos-api
```

---

## Advanced Usage

### Multi-User Access

**Add users** (Cockpit uses PAM authentication):
```bash
# Create user
useradd -m webadmin

# Set password
passwd webadmin

# Add to libvirt group (VM management)
usermod -a -G libvirt webadmin

# User can now log into Cockpit
```

### Custom Cockpit Module

**Future: VirtOS-specific dashboard**

Directory structure:
```
/usr/share/cockpit/virtos/
├── manifest.json       # Module definition
├── index.html          # VirtOS dashboard
├── virtos.js           # API calls to virtos-api
├── virtos.css          # VirtOS styling
└── assets/
    └── logo.png
```

Example `manifest.json`:
```json
{
  "version": 0,
  "name": "virtos",
  "menu": {
    "index": {
      "label": "VirtOS",
      "order": 10
    }
  }
}
```

### API Client Examples

**Python**:
```python
import requests

# List VMs
response = requests.get('http://localhost:8080/api/v1/vms')
vms = response.json()
print(f"VMs: {len(vms)}")

# Start VM
requests.post('http://localhost:8080/api/v1/vms/web-01/start')
```

**Bash**:
```bash
#!/bin/bash
# List all VMs
vms=$(curl -s http://localhost:8080/api/v1/vms | jq -r '.[].name')

# Start each VM
for vm in $vms; do
    echo "Starting $vm..."
    curl -X POST http://localhost:8080/api/v1/vms/$vm/start
done
```

**JavaScript/Node.js**:
```javascript
const axios = require('axios');

async function listVMs() {
  const response = await axios.get('http://localhost:8080/api/v1/vms');
  console.log('VMs:', response.data);
}

async function startVM(name) {
  await axios.post(`http://localhost:8080/api/v1/vms/${name}/start`);
  console.log(`Started ${name}`);
}

listVMs();
startVM('web-01');
```

---

## Troubleshooting

### Cockpit Issues

**Cockpit won't start**:
```bash
# Check status
systemctl status cockpit

# View logs
journalctl -u cockpit -f

# Restart
systemctl restart cockpit
```

**Can't connect**:
```bash
# Check firewall
firewall-cmd --list-services | grep cockpit

# Allow if missing
firewall-cmd --add-service=cockpit --permanent
firewall-cmd --reload

# Check port
ss -tulpn | grep 9090
```

**Certificate errors**:
```bash
# Regenerate self-signed certificate
rm /etc/cockpit/ws-certs.d/*
systemctl restart cockpit
```

### API Issues

**API won't start**:
```bash
# Check if port in use
ss -tulpn | grep 8080

# Try different port
virtos-api start --port 9090

# Check logs
tail -f /var/log/virtos-api.log
```

**Can't reach API**:
```bash
# Test locally
curl http://localhost:8080/api/v1/health

# Check bind address
virtos-api status

# Firewall (if accessing remotely)
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload
```

---

## Comparison: Management Interfaces

| Feature | CLI | TUI | Web UI | API |
|---------|-----|-----|--------|-----|
| **Access Method** | SSH | SSH | Browser | HTTP |
| **Learning Curve** | High | Medium | Low | Medium |
| **Scripting** | ✅ Perfect | ❌ No | ❌ No | ✅ Perfect |
| **Visual Feedback** | ❌ Text | 🟡 Menus | ✅ Charts | ❌ JSON |
| **Multi-User** | 🟡 Via SSH | 🟡 Via SSH | ✅ Yes | ✅ Yes |
| **Real-time Updates** | ❌ No | 🟡 Manual | ✅ Live | 🟡 Polling |
| **Mobile-Friendly** | ❌ No | ❌ No | 🟡 Partial | ✅ Yes |
| **Resource Usage** | ✅ Minimal | ✅ Minimal | 🟡 Moderate | ✅ Minimal |
| **Best For** | Automation | SSH admin | Teams | Integration |

**Recommendation**: Use all three!
- **CLI**: Scripts and automation
- **TUI**: Quick SSH management
- **Web UI**: Team dashboards, visual feedback
- **API**: Custom integrations, external tools

---

## Future Enhancements

### Short-term (Phase 2)
- [ ] VirtOS-branded Cockpit module
- [ ] Cluster dashboard (multi-host view)
- [ ] API authentication (JWT tokens)
- [ ] API HTTPS support
- [ ] Enhanced metrics (historical graphs)

### Long-term (Phase 5)
- [ ] Custom React/Vue dashboard (optional)
- [ ] Mobile app (iOS/Android)
- [ ] RBAC (role-based access control)
- [ ] Audit logging
- [ ] Multi-language support
- [ ] Dark mode

---

## Related Documentation

- [TUI Guide](TUI.md) - Text user interface
- [Remote Access](REMOTE-ACCESS.md) - SSH and virt-manager setup
- [Clustering](CLUSTERING.md) - Multi-host management
- [API Reference](API.md) - Complete API documentation (coming soon)

---

## External Resources

- [Cockpit Project](https://cockpit-project.org/) - Official Cockpit documentation
- [Cockpit Guide](https://cockpit-project.org/guide/latest/) - User guide
- [Cockpit Development](https://github.com/cockpit-project/cockpit/blob/main/HACKING.md) - Plugin development

---

**Have questions?** File an issue: https://github.com/FlossWare/VirtOS/issues
