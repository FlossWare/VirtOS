# VirtOS Cockpit Module Design

**Last Updated**: 2026-05-29  
**Version: 0.89  
**Status**: Design Document (Not Yet Implemented)

## Overview

This document describes the design for a **VirtOS-specific Cockpit module** that provides branded dashboard, cluster view, and VirtOS-specific workflows beyond standard Cockpit features.

## Background

### Current State

VirtOS already integrates with Cockpit via `virtos-web`:
- Users access Cockpit at `https://virtos-host:9090`
- Standard "Virtual Machines" tab shows libvirt VMs
- Generic Linux web console (no VirtOS branding)

### Why a Custom Module?

**Benefits**:
- ✅ VirtOS branding and professional appearance
- ✅ Cluster view (multi-host management)
- ✅ VirtOS-specific shortcuts and workflows
- ✅ Integration with platform-java
- ✅ One-click actions beyond standard libvirt

**Similar Projects**:
- **oVirt** - Custom Cockpit plugin for datacenter management
- **Foreman** - Host provisioning plugin
- **FreeIPA** - Identity management plugin

All provide branded experiences within Cockpit.

## Architecture

### Directory Structure

```
/usr/share/cockpit/virtos/
├── manifest.json          # Cockpit module definition
├── index.html             # Main dashboard
├── cluster.html           # Cluster management view
├── virtos.js              # JavaScript logic
├── virtos.css             # VirtOS styling
├── api.js                 # virtos-api client library
└── assets/
    ├── logo.png           # VirtOS logo (SVG)
    ├── favicon.ico        # Browser icon
    └── icons/
        ├── vm.svg         # VM icons
        ├── cluster.svg    # Cluster icon
        └── storage.svg    # Storage icon
```

### Technology Stack

**Frontend**:
- HTML5 + JavaScript (no framework for simplicity)
- PatternFly CSS (Cockpit's UI framework)
- Cockpit JavaScript API (`cockpit.js`)

**Backend**:
- virtos-api (REST API server, already exists)
- Cockpit D-Bus API (for system integration)
- virtos-* scripts (called via shell commands)

**Communication**:
- REST API → virtos-api endpoints
- D-Bus → Cockpit services (authentication, shell, etc.)
- WebSockets → Live updates (future enhancement)

## Module Definition

### manifest.json

```json
{
  "version": 0,
  "name": "virtos",
  "menu": {
    "index": {
      "label": "VirtOS Dashboard",
      "order": 10
    },
    "cluster": {
      "label": "VirtOS Cluster",
      "order": 11
    }
  },
  "description": "VirtOS virtualization management",
  "requires": {
    "cockpit": "276"
  }
}
```

**Fields**:
- `name`: Module identifier (must be "virtos")
- `menu`: Sidebar entries (Dashboard and Cluster tabs)
- `order`: Menu position (10 = near top)
- `requires`: Minimum Cockpit version

## Dashboard Tab (index.html)

### Layout

```
┌────────────────────────────────────────────────────────┐
│ [VirtOS Logo]    VirtOS Dashboard         [Settings]  │
├────────────────────────────────────────────────────────┤
│                                                        │
│ Quick Stats                                           │
│ ┌──────────┬──────────┬──────────┬─────────────────┐ │
│ │ VMs: 12  │ CPU: 45% │ RAM: 67% │ Storage: 23 GB  │ │
│ │ 8 running│          │          │ used            │ │
│ └──────────┴──────────┴──────────┴─────────────────┘ │
│                                                        │
│ Recent Activity                                        │
│ ┌────────────────────────────────────────────────────┐│
│ │ ● web-01 started (2 minutes ago)                   ││
│ │ ● Snapshot created for db-01 (15 minutes ago)      ││
│ │ ● Backup completed for app-tier (1 hour ago)       ││
│ └────────────────────────────────────────────────────┘│
│                                                        │
│ Quick Actions                                          │
│ [+ Create VM] [Start All] [Stop All] [Backup Now]    │
│                                                        │
│ Virtual Machines (12)                                  │
│ ┌────────────────────────────────────────────────────┐│
│ │ Name      State     CPU    RAM     Actions         ││
│ │─────────────────────────────────────────────────── ││
│ │ web-01    running   45%    2 GB    [Stop][Console] ││
│ │ db-01     running   23%    4 GB    [Stop][Console] ││
│ │ app-01    stopped   0%     0 GB    [Start][Delete] ││
│ └────────────────────────────────────────────────────┘│
└────────────────────────────────────────────────────────┘
```

### Features

**Quick Stats**:
- Total VMs (running / stopped)
- Cluster CPU usage (aggregate)
- Cluster RAM usage
- Storage used/available

**Recent Activity**:
- Last 10 VM operations
- Auto-refresh every 5 seconds
- Links to relevant VMs

**Quick Actions**:
- Create VM → Opens virtos-create-vm wizard
- Start All → Starts all stopped VMs
- Stop All → Gracefully stops all running VMs
- Backup Now → Triggers virtos-backup

**VM Table**:
- Sortable columns (name, state, CPU, RAM)
- Filter by state (running/stopped/all)
- Per-VM actions (start, stop, console, delete)
- Click row → VM details page

### Implementation (index.html)

```html
<!DOCTYPE html>
<html>
<head>
    <title>VirtOS Dashboard</title>
    <meta charset="utf-8">
    <link href="../base1/patternfly.css" rel="stylesheet">
    <link href="virtos.css" rel="stylesheet">
    <script src="../base1/cockpit.js"></script>
    <script src="api.js"></script>
    <script src="virtos.js"></script>
</head>
<body>
    <div class="container-fluid">
        <!-- Header -->
        <div class="row">
            <div class="col-md-12">
                <h1>
                    <img src="assets/logo.png" alt="VirtOS" height="40">
                    VirtOS Dashboard
                </h1>
            </div>
        </div>

        <!-- Quick Stats -->
        <div class="row">
            <div class="col-md-3">
                <div class="card-pf">
                    <h2 id="vm-count">0</h2>
                    <p>Virtual Machines</p>
                    <small id="vm-running">0 running</small>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card-pf">
                    <h2 id="cpu-usage">0%</h2>
                    <p>CPU Usage</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card-pf">
                    <h2 id="ram-usage">0%</h2>
                    <p>RAM Usage</p>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card-pf">
                    <h2 id="storage-used">0 GB</h2>
                    <p>Storage Used</p>
                </div>
            </div>
        </div>

        <!-- Recent Activity -->
        <div class="row">
            <div class="col-md-12">
                <h3>Recent Activity</h3>
                <ul id="activity-feed" class="list-group">
                    <!-- Populated by JavaScript -->
                </ul>
            </div>
        </div>

        <!-- Quick Actions -->
        <div class="row">
            <div class="col-md-12">
                <button class="btn btn-primary" onclick="VirtOS.createVM()">
                    + Create VM
                </button>
                <button class="btn btn-default" onclick="VirtOS.startAll()">
                    Start All
                </button>
                <button class="btn btn-default" onclick="VirtOS.stopAll()">
                    Stop All
                </button>
                <button class="btn btn-default" onclick="VirtOS.backupNow()">
                    Backup Now
                </button>
            </div>
        </div>

        <!-- VM Table -->
        <div class="row">
            <div class="col-md-12">
                <h3>Virtual Machines</h3>
                <table id="vm-table" class="table table-hover">
                    <thead>
                        <tr>
                            <th>Name</th>
                            <th>State</th>
                            <th>CPU</th>
                            <th>RAM</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Populated by JavaScript -->
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</body>
</html>
```

### JavaScript (virtos.js)

```javascript
var VirtOS = {
    api: null,
    refreshInterval: null,

    init: function() {
        // Initialize virtos-api client
        this.api = new VirtOSAPI('http://localhost:8080/api/v1');
        
        // Load initial data
        this.refresh();
        
        // Auto-refresh every 5 seconds
        this.refreshInterval = setInterval(() => this.refresh(), 5000);
    },

    refresh: function() {
        // Fetch VM list
        this.api.listVMs().then(vms => {
            this.updateQuickStats(vms);
            this.updateVMTable(vms);
        });
        
        // Fetch cluster status
        this.api.getCluster().then(cluster => {
            this.updateClusterStats(cluster);
        });
        
        // Fetch activity feed
        this.loadActivity();
    },

    updateQuickStats: function(vms) {
        const running = vms.filter(vm => vm.state === 'running').length;
        document.getElementById('vm-count').textContent = vms.length;
        document.getElementById('vm-running').textContent = `${running} running`;
        
        // Calculate aggregate CPU/RAM
        let totalCPU = 0, totalRAM = 0;
        vms.forEach(vm => {
            if (vm.state === 'running') {
                totalCPU += vm.cpu_percent || 0;
                totalRAM += vm.ram_percent || 0;
            }
        });
        
        document.getElementById('cpu-usage').textContent = 
            Math.round(totalCPU / vms.length) + '%';
        document.getElementById('ram-usage').textContent = 
            Math.round(totalRAM / vms.length) + '%';
    },

    updateVMTable: function(vms) {
        const tbody = document.querySelector('#vm-table tbody');
        tbody.innerHTML = '';
        
        vms.forEach(vm => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td><a href="#/vm/${vm.name}">${vm.name}</a></td>
                <td><span class="label label-${vm.state === 'running' ? 'success' : 'default'}">
                    ${vm.state}
                </span></td>
                <td>${vm.cpu || 0}%</td>
                <td>${Math.round(vm.memory / 1024)} MB</td>
                <td>
                    ${vm.state === 'running' ?
                        `<button onclick="VirtOS.stopVM('${vm.name}')">Stop</button>
                         <button onclick="VirtOS.console('${vm.name}')">Console</button>` :
                        `<button onclick="VirtOS.startVM('${vm.name}')">Start</button>
                         <button onclick="VirtOS.deleteVM('${vm.name}')">Delete</button>`
                    }
                </td>
            `;
            tbody.appendChild(row);
        });
    },

    loadActivity: function() {
        // Read /var/log/virtos-activity.log and display recent events
        cockpit.file('/var/log/virtos-activity.log').read()
            .then(data => {
                const lines = data.split('\n').slice(-10).reverse();
                const feed = document.getElementById('activity-feed');
                feed.innerHTML = '';
                
                lines.forEach(line => {
                    if (line.trim()) {
                        const li = document.createElement('li');
                        li.className = 'list-group-item';
                        li.textContent = '● ' + line;
                        feed.appendChild(li);
                    }
                });
            });
    },

    // VM Actions
    startVM: function(name) {
        this.api.startVM(name).then(() => {
            this.refresh();
            this.logActivity(`Started VM: ${name}`);
        });
    },

    stopVM: function(name) {
        this.api.stopVM(name).then(() => {
            this.refresh();
            this.logActivity(`Stopped VM: ${name}`);
        });
    },

    deleteVM: function(name) {
        if (confirm(`Delete VM ${name}? This cannot be undone.`)) {
            cockpit.spawn(['virsh', 'undefine', name, '--remove-all-storage'])
                .then(() => {
                    this.refresh();
                    this.logActivity(`Deleted VM: ${name}`);
                });
        }
    },

    console: function(name) {
        // Open console in new window
        cockpit.jump(`/machines#/vm?name=${name}&connection=system`, 
                     undefined, 'blank');
    },

    // Quick Actions
    createVM: function() {
        // TODO: Integrate virtos-create-vm wizard
        alert('VM creation wizard coming soon!');
    },

    startAll: function() {
        this.api.listVMs().then(vms => {
            vms.filter(vm => vm.state !== 'running').forEach(vm => {
                this.api.startVM(vm.name);
            });
            this.refresh();
        });
    },

    stopAll: function() {
        if (confirm('Stop all running VMs?')) {
            this.api.listVMs().then(vms => {
                vms.filter(vm => vm.state === 'running').forEach(vm => {
                    this.api.stopVM(vm.name);
                });
                this.refresh();
            });
        }
    },

    backupNow: function() {
        cockpit.spawn(['virtos-backup', 'backup-all'])
            .then(() => {
                alert('Backup started!');
                this.logActivity('Backup initiated for all VMs');
            });
    },

    logActivity: function(message) {
        const timestamp = new Date().toISOString();
        cockpit.file('/var/log/virtos-activity.log')
            .modify(old_content => {
                return old_content + `${timestamp} ${message}\n`;
            });
    }
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => VirtOS.init());
```

## Cluster Tab (cluster.html)

### Layout

```
┌────────────────────────────────────────────────────────┐
│ [VirtOS Logo]    VirtOS Cluster                       │
├────────────────────────────────────────────────────────┤
│                                                        │
│ Cluster Overview                                       │
│ ┌──────────────────────────────────────────────────┐  │
│ │ Nodes: 3     Total VMs: 45     Total CPU: 144   │  │
│ │ Online: 3    Running: 32       Total RAM: 384 GB│  │
│ └──────────────────────────────────────────────────┘  │
│                                                        │
│ Nodes                                                  │
│ ┌────────────────────────────────────────────────────┐│
│ │ Node           Status  VMs  CPU    RAM    Disk    ││
│ │────────────────────────────────────────────────────││
│ │ virtos-1.local ● online 15  45%    67%    120 GB  ││
│ │ virtos-2.local ● online 18  52%    71%    200 GB  ││
│ │ virtos-3.local ● online 12  38%    54%    85 GB   ││
│ └────────────────────────────────────────────────────┘│
│                                                        │
│ Actions                                                │
│ [Add Node] [Migrate VMs] [Rebalance] [View Topology] │
└────────────────────────────────────────────────────────┘
```

### Features

**Cluster Overview**:
- Total nodes (online/offline)
- Total VMs across cluster
- Aggregate resources

**Node Table**:
- Per-node status (online/offline)
- VM count per node
- Resource usage per node
- Click node → Node detail page

**Cluster Actions**:
- Add Node → Join new host to cluster
- Migrate VMs → Move VMs between nodes
- Rebalance → Automatically distribute VMs
- View Topology → Network diagram

## API Client Library (api.js)

```javascript
class VirtOSAPI {
    constructor(baseURL) {
        this.baseURL = baseURL;
    }

    async request(method, path, body = null) {
        const options = {
            method: method,
            headers: {'Content-Type': 'application/json'}
        };
        
        if (body) {
            options.body = JSON.stringify(body);
        }
        
        const response = await fetch(this.baseURL + path, options);
        if (!response.ok) {
            throw new Error(`API error: ${response.status}`);
        }
        return await response.json();
    }

    // VM Operations
    listVMs() {
        return this.request('GET', '/vms').then(r => r.vms);
    }

    getVM(name) {
        return this.request('GET', `/vms/${name}`);
    }

    startVM(name) {
        return this.request('POST', `/vms/${name}/start`);
    }

    stopVM(name) {
        return this.request('POST', `/vms/${name}/stop`);
    }

    // Cluster Operations
    getCluster() {
        return this.request('GET', '/cluster').then(r => r.nodes);
    }

    // System Operations
    getHealth() {
        return this.request('GET', '/health');
    }

    getVersion() {
        return this.request('GET', '/version');
    }
}
```

## Styling (virtos.css)

```css
/* VirtOS Branding */
body {
    font-family: 'Red Hat Text', sans-serif;
}

.card-pf {
    background: #fff;
    border: 1px solid #d1d1d1;
    border-radius: 3px;
    padding: 20px;
    margin-bottom: 20px;
    text-align: center;
}

.card-pf h2 {
    font-size: 36px;
    margin: 0;
    color: #0066cc; /* VirtOS blue */
}

.card-pf p {
    font-size: 14px;
    color: #6a6e73;
}

/* Activity Feed */
#activity-feed {
    max-height: 200px;
    overflow-y: auto;
}

#activity-feed .list-group-item {
    border-left: 3px solid #0066cc;
}

/* VM Table */
#vm-table th {
    background: #f5f5f5;
}

#vm-table tr:hover {
    background: #f9f9f9;
}

/* Quick Actions */
.btn {
    margin-right: 10px;
}

/* Logo */
h1 img {
    vertical-align: middle;
    margin-right: 10px;
}
```

## Integration Points

### virtos-api Backend

The module relies on virtos-api (already implemented):

```bash
# Start API server (required for Cockpit module)
virtos-api --port 8080 --host 0.0.0.0

# Make persistent
systemctl enable virtos-api
systemctl start virtos-api
```

### Cockpit D-Bus API

For system operations (auth, shell, files):

```javascript
// Execute shell command
cockpit.spawn(['virsh', 'list', '--all'])
    .then(output => {
        console.log('VMs:', output);
    });

// Read file
cockpit.file('/var/log/virtos.log').read()
    .then(content => {
        console.log('Log:', content);
    });

// Write file
cockpit.file('/etc/virtos.conf').modify(old_content => {
    return old_content + '\nnew_setting=value';
});
```

### platform-java Integration

**Future Enhancement**: Add platform-java workload view

```javascript
// Fetch platform-java workloads
fetch('http://localhost:8081/api/workloads')
    .then(r => r.json())
    .then(workloads => {
        // Display platform-java VMs/containers
        displayWorkloads(workloads);
    });
```

## Packaging

### TCZ Package Structure

```
virtos-cockpit-module.tcz
├── /usr/share/cockpit/virtos/
│   ├── manifest.json
│   ├── index.html
│   ├── cluster.html
│   ├── virtos.js
│   ├── virtos.css
│   ├── api.js
│   └── assets/
│       ├── logo.png
│       └── icons/
└── /usr/local/tce.installed/
    └── virtos-cockpit-module
```

### Build Script

```bash
#!/bin/sh
# packages/virtos-cockpit-module/build.sh

PKGNAME="virtos-cockpit-module"
VERSION=$(cat ../../VERSION)

# Create structure
mkdir -p virtos.build/usr/share/cockpit/virtos
mkdir -p virtos.build/usr/share/cockpit/virtos/assets/icons

# Copy files
cp src/manifest.json virtos.build/usr/share/cockpit/virtos/
cp src/index.html virtos.build/usr/share/cockpit/virtos/
cp src/cluster.html virtos.build/usr/share/cockpit/virtos/
cp src/virtos.js virtos.build/usr/share/cockpit/virtos/
cp src/virtos.css virtos.build/usr/share/cockpit/virtos/
cp src/api.js virtos.build/usr/share/cockpit/virtos/
cp assets/* virtos.build/usr/share/cockpit/virtos/assets/

# Create TCZ package
mksquashfs virtos.build "${PKGNAME}.tcz" -noappend

# Generate metadata
cat > "${PKGNAME}.tcz.dep" <<EOF
cockpit.tcz
virtos-tools.tcz
EOF

cat > "${PKGNAME}.tcz.info" <<EOF
Title:          ${PKGNAME}.tcz
Description:    VirtOS Cockpit module for web-based management
Version:        $VERSION
Author:         FlossWare
Original-site:  https://github.com/FlossWare/VirtOS
Copying-policy: Apache 2.0
Size:           100K
Extension_by:   FlossWare
EOF

echo "Cockpit module package built: ${PKGNAME}.tcz"
```

## Installation

```bash
# Install Cockpit (if not already installed)
tce-load -wi cockpit

# Install VirtOS Cockpit module
tce-load -wi virtos-cockpit-module

# Restart Cockpit
sudo systemctl restart cockpit

# Access at: https://virtos-host:9090
# Navigate to "VirtOS Dashboard" in sidebar
```

## Security Considerations

### Authentication

Cockpit module uses Cockpit's PAM authentication:
- Inherits system users and permissions
- No separate authentication needed
- Respects sudo rules

### Authorization

```javascript
// Check if user has sudo privileges before destructive actions
cockpit.user().then(user => {
    if (!user.admin) {
        alert('This action requires administrator privileges');
        return;
    }
    // Proceed with action
});
```

### HTTPS/TLS

Cockpit handles TLS:
- Self-signed cert by default
- Configure custom cert in `/etc/cockpit/ws-certs.d/`

## Testing

### Manual Testing Checklist

- [ ] Module appears in Cockpit sidebar
- [ ] Dashboard loads without errors
- [ ] VM list displays correctly
- [ ] Quick stats show accurate data
- [ ] Start VM button works
- [ ] Stop VM button works
- [ ] Activity feed updates
- [ ] Cluster tab shows all nodes
- [ ] Auto-refresh works (5s interval)

### Browser Compatibility

- ✅ Chrome/Chromium 90+
- ✅ Firefox 88+
- ✅ Safari 14+ (macOS)
- ✅ Edge 90+

## Future Enhancements

### Phase 1 (MVP - This Design)
- [x] Dashboard with quick stats
- [x] VM table with basic actions
- [x] Cluster view
- [x] Activity feed

### Phase 2 (Planned)
- [ ] VM creation wizard (integrated virtos-create-vm)
- [ ] Real-time metrics (charts)
- [ ] Snapshot management UI
- [ ] Network configuration UI
- [ ] Storage pool management UI

### Phase 3 (Advanced)
- [ ] WebSocket live updates
- [ ] Drag-and-drop VM migration
- [ ] Network topology diagram
- [ ] platform-java integration
- [ ] Mobile-responsive design

## Limitations

**Current**:
- Read-only for some operations (must use CLI)
- No WebSocket support (polling only)
- Basic styling (PatternFly defaults)
- No customizable dashboard

**By Design**:
- Requires Cockpit (100+ MB overhead)
- Web-only (no CLI equivalent)
- JavaScript required (no graceful degradation)

## Comparison with Alternatives

| Feature | VirtOS Cockpit Module | virt-manager | Proxmox Web UI |
|---------|----------------------|--------------|----------------|
| **Installation** | `tce-load -wi` | Heavy (GTK+) | Built-in |
| **Access** | Web browser | Desktop app | Web browser |
| **Branding** | VirtOS | Generic | Proxmox |
| **Cluster View** | ✅ Yes | ❌ No | ✅ Yes |
| **Mobile** | ✅ Responsive | ❌ No | ✅ Yes |
| **Overhead** | ~100 MB | ~200 MB | ~500 MB |

## Related Documentation

- [Web UI Guide](../README.md#web-ui) - virtos-web overview
- [API Reference](API.md) - virtos-api endpoints
- [Cockpit Documentation](https://cockpit-project.org/guide/latest/) - Cockpit developer guide

## References

- [Cockpit Module Development](https://cockpit-project.org/guide/latest/development.html)
- [PatternFly CSS](https://www.patternfly.org/) - UI framework
- [oVirt Cockpit Plugin](https://github.com/oVirt/cockpit-ovirt) - Similar project

---

**Status**: Design document ready for implementation  
**Effort**: ~40 hours (MVP implementation)  
**Priority**: Medium (nice-to-have, not critical)  
**Next**: Implement Phase 1 features
