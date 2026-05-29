# VirtOS Monitoring and Alerting Setup

**Last Updated**: 2026-05-26  
**Applies to**: VirtOS 0.80+

## Overview

This guide describes how to set up comprehensive monitoring and alerting for VirtOS production environments using Prometheus, Grafana, and Alert Manager.

## Architecture

```
┌──────────────────────────────────────────────────┐
│   Grafana Dashboards (Visualization)             │
│   http://grafana:3000                            │
└────────────────┬─────────────────────────────────┘
                 │
┌────────────────┴─────────────────────────────────┐
│   Prometheus (Metrics Storage)                   │
│   http://prometheus:9090                         │
└─────┬────────┬────────┬────────┬─────────────────┘
      │        │        │        │
┌─────┴───┐ ┌──┴────┐ ┌┴─────┐ ┌┴────────┐
│ libvirt│ │  Node  │ │ QEMU │ │ Custom  │
│Exporter│ │Exporter│ │Metrics│ │ Scripts │
└────────┘ └────────┘ └───────┘ └─────────┘
      ↓         ↓         ↓         ↓
┌──────────────────────────────────────────────────┐
│   VirtOS Hosts & VMs                             │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│   AlertManager (Alerting)                        │
│   http://alertmanager:9093                       │
└────┬──────┬──────┬──────┬────────────────────────┘
     │      │      │      │
     ↓      ↓      ↓      ↓
  Email  Slack  PagerDuty SMS
```

## Quick Start (5 Minutes)

### Minimal Monitoring Setup

```bash
# 1. Install Prometheus (metrics storage)
tce-load -wi prometheus

# 2. Configure Prometheus for libvirt
sudo vi /etc/prometheus/prometheus.yml

global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'virtos-host'
    static_configs:
      - targets: ['localhost:9100']  # Node exporter

  - job_name: 'libvirt'
    static_configs:
      - targets: ['localhost:9177']  # libvirt exporter

# 3. Start Prometheus
sudo prometheus --config.file=/etc/prometheus/prometheus.yml &

# 4. Verify (should show metrics)
curl http://localhost:9090/metrics

# 5. Access Prometheus web UI
# http://<virtos-host-ip>:9090
```

## Full Production Setup

### 1. Install Monitoring Components

```bash
# Create monitoring directory
sudo mkdir -p /opt/monitoring
cd /opt/monitoring

# Install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xzf prometheus-2.45.0.linux-amd64.tar.gz
sudo mv prometheus-2.45.0.linux-amd64 /opt/prometheus

# Install Node Exporter (host metrics)
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
tar xzf node_exporter-1.6.0.linux-amd64.tar.gz
sudo mv node_exporter-1.6.0.linux-amd64 /opt/node_exporter

# Install libvirt Exporter (VM metrics)
wget https://github.com/kumina/libvirt_exporter/releases/download/v1.0.0/libvirt_exporter-1.0.0.linux-amd64
chmod +x libvirt_exporter-1.0.0.linux-amd64
sudo mv libvirt_exporter-1.0.0.linux-amd64 /opt/libvirt_exporter/libvirt_exporter

# Install Grafana (visualization)
wget https://dl.grafana.com/oss/release/grafana-10.0.0.linux-amd64.tar.gz
tar xzf grafana-10.0.0.linux-amd64.tar.gz
sudo mv grafana-10.0.0 /opt/grafana

# Install AlertManager (alerting)
wget https://github.com/prometheus/alertmanager/releases/download/v0.26.0/alertmanager-0.26.0.linux-amd64.tar.gz
tar xzf alertmanager-0.26.0.linux-amd64.tar.gz
sudo mv alertmanager-0.26.0.linux-amd64 /opt/alertmanager
```

### 2. Configure Prometheus

```bash
# Create configuration
sudo vi /opt/prometheus/prometheus.yml

global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'virtos-production'
    datacenter: 'primary'

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

# Load alert rules
rule_files:
  - '/opt/prometheus/alerts/*.yml'

scrape_configs:
  # VirtOS Hosts
  - job_name: 'virtos-hosts'
    static_configs:
      - targets:
          - 'virtos-host-01:9100'
          - 'virtos-host-02:9100'
          - 'virtos-host-03:9100'
    relabel_configs:
      - source_labels: [__address__]
        regex: '([^:]+):.*'
        target_label: instance

  # libvirt/VMs
  - job_name: 'libvirt'
    static_configs:
      - targets:
          - 'virtos-host-01:9177'
          - 'virtos-host-02:9177'
          - 'virtos-host-03:9177'

  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

### 3. Create Alert Rules

```bash
# Create alerts directory
sudo mkdir -p /opt/prometheus/alerts

# Define alert rules
sudo vi /opt/prometheus/alerts/virtos.yml

groups:
  - name: virtos_host_alerts
    interval: 30s
    rules:
      # Host Down
      - alert: HostDown
        expr: up{job="virtos-hosts"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "VirtOS host {{ $labels.instance }} is down"
          description: "Host {{ $labels.instance }} has been unreachable for 1 minute"

      # High CPU Usage
      - alert: HostHighCPU
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Host {{ $labels.instance }} high CPU usage"
          description: "CPU usage is {{ $value }}% (threshold: 80%)"

      # High Memory Usage
      - alert: HostHighMemory
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Host {{ $labels.instance }} high memory usage"
          description: "Memory usage is {{ $value }}% (threshold: 85%)"

      # Disk Space Critical
      - alert: DiskSpaceCritical
        expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Host {{ $labels.instance }} disk almost full"
          description: "Disk usage on {{ $labels.mountpoint }} is {{ $value }}% (threshold: 90%)"

  - name: virtos_vm_alerts
    interval: 30s
    rules:
      # VM Down Unexpectedly
      - alert: VMCrashed
        expr: libvirt_domain_info_state{state="crashed"} > 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "VM {{ $labels.domain }} has crashed"
          description: "VM {{ $labels.domain }} is in crashed state"

      # VM High CPU
      - alert: VMHighCPU
        expr: libvirt_domain_cpu_time_seconds_total > 90
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "VM {{ $labels.domain }} high CPU usage"
          description: "VM CPU usage is high"

  - name: virtos_service_alerts
    interval: 30s
    rules:
      # libvirtd Down
      - alert: LibvirtdDown
        expr: node_systemd_unit_state{name="libvirtd.service",state="active"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "libvirtd service down on {{ $labels.instance }}"
          description: "libvirtd has been down for 1 minute"
```

### 4. Configure AlertManager

```bash
# Create AlertManager configuration
sudo vi /opt/alertmanager/alertmanager.yml

global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alertmanager@example.com'
  smtp_auth_username: 'alertmanager@example.com'
  smtp_auth_password: 'password'

# Route tree
route:
  receiver: 'virtos-ops'
  group_by: ['alertname', 'cluster', 'instance']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 3h

  routes:
    # Critical alerts to PagerDuty
    - match:
        severity: critical
      receiver: 'pagerduty'
      continue: true

    # All alerts to email and Slack
    - match_re:
        severity: .*
      receiver: 'virtos-ops'

# Receivers
receivers:
  - name: 'virtos-ops'
    email_configs:
      - to: 'ops@example.com'
        headers:
          Subject: 'VirtOS Alert: {{ .GroupLabels.alertname }}'

    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#virtos-alerts'
        title: 'VirtOS Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

  - name: 'pagerduty'
    pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}: {{ .GroupLabels.instance }}'
```

### 5. Set Up Grafana Dashboards

```bash
# Start Grafana
cd /opt/grafana
./bin/grafana-server &

# Access Grafana web UI
# http://<virtos-host-ip>:3000
# Default login: admin / admin

# Add Prometheus data source (via UI or API)
curl -X POST http://admin:admin@localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://localhost:9090",
    "access":"proxy",
    "isDefault":true
  }'

# Import VirtOS dashboard
curl -X POST http://admin:admin@localhost:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -d @/opt/monitoring/virtos-dashboard.json
```

### 6. Create VirtOS Dashboard (JSON)

```bash
# Create dashboard configuration
sudo vi /opt/monitoring/virtos-dashboard.json

{
  "dashboard": {
    "title": "VirtOS Cluster Overview",
    "panels": [
      {
        "title": "Cluster Status",
        "targets": [
          {
            "expr": "up{job='virtos-hosts'}",
            "legendFormat": "{{ instance }}"
          }
        ],
        "type": "stat"
      },
      {
        "title": "Total VMs",
        "targets": [
          {
            "expr": "count(libvirt_domain_info_state{state='running'})"
          }
        ],
        "type": "stat"
      },
      {
        "title": "CPU Usage by Host",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode='idle'}[5m])) * 100)",
            "legendFormat": "{{ instance }}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Memory Usage by Host",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "{{ instance }}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "VM States",
        "targets": [
          {
            "expr": "libvirt_domain_info_state",
            "legendFormat": "{{ domain }} - {{ state }}"
          }
        ],
        "type": "table"
      }
    ]
  },
  "overwrite": true
}
```

### 7. Start All Services

```bash
# Create startup script
sudo vi /opt/monitoring/start-monitoring.sh

#!/bin/bash
# Start VirtOS monitoring stack

# Start Node Exporter
/opt/node_exporter/node_exporter \
    --web.listen-address=:9100 &
echo $! > /var/run/node_exporter.pid

# Start libvirt Exporter
/opt/libvirt_exporter/libvirt_exporter \
    --web.listen-address=:9177 &
echo $! > /var/run/libvirt_exporter.pid

# Start Prometheus
/opt/prometheus/prometheus \
    --config.file=/opt/prometheus/prometheus.yml \
    --storage.tsdb.path=/opt/prometheus/data \
    --web.listen-address=:9090 &
echo $! > /var/run/prometheus.pid

# Start AlertManager
/opt/alertmanager/alertmanager \
    --config.file=/opt/alertmanager/alertmanager.yml \
    --storage.path=/opt/alertmanager/data \
    --web.listen-address=:9093 &
echo $! > /var/run/alertmanager.pid

# Start Grafana
cd /opt/grafana
./bin/grafana-server \
    --homepath=/opt/grafana \
    --config=/opt/grafana/conf/defaults.ini &
echo $! > /var/run/grafana.pid

echo "Monitoring stack started"
echo "Prometheus: http://localhost:9090"
echo "AlertManager: http://localhost:9093"
echo "Grafana: http://localhost:3000"

# Make executable
chmod +x /opt/monitoring/start-monitoring.sh

# Start monitoring
sudo /opt/monitoring/start-monitoring.sh

# Make persistent (start on boot)
echo "/opt/monitoring/start-monitoring.sh" >> /opt/bootlocal.sh
```

## Metrics Collection

### Host Metrics (Node Exporter)

Collected automatically by node_exporter:

- **CPU**: Usage per core, load average, steal time
- **Memory**: Total, used, free, cached, buffers
- **Disk**: Usage, I/O operations, latency
- **Network**: Traffic, errors, packets
- **System**: Uptime, context switches, processes

### VM Metrics (libvirt Exporter)

Collected automatically by libvirt_exporter:

- **VM State**: Running, stopped, paused, crashed
- **vCPU**: CPU time, usage percentage
- **Memory**: Allocated, actual, balloon
- **Disk**: Read/write bytes, IOPS
- **Network**: RX/TX bytes, packets, errors

### Custom Metrics (virtos-monitor)

```bash
# Create custom metrics exporter
sudo vi /opt/monitoring/virtos-metrics-exporter.sh

#!/bin/bash
# Export custom VirtOS metrics for Prometheus

while true; do
    # VM count by state
    RUNNING=$(virsh list --state-running --name | wc -l)
    STOPPED=$(virsh list --state-shutoff --name | wc -l)
    PAUSED=$(virsh list --state-paused --name | wc -l)

    # Storage pool usage
    POOL_SIZE=$(virsh pool-info default | awk '/Capacity:/ {print $2}')
    POOL_USED=$(virsh pool-info default | awk '/Allocation:/ {print $2}')

    # Output in Prometheus format
    echo "# HELP virtos_vms_running Number of running VMs"
    echo "# TYPE virtos_vms_running gauge"
    echo "virtos_vms_running $RUNNING"

    echo "# HELP virtos_vms_stopped Number of stopped VMs"
    echo "# TYPE virtos_vms_stopped gauge"
    echo "virtos_vms_stopped $STOPPED"

    echo "# HELP virtos_storage_pool_size_bytes Storage pool size"
    echo "# TYPE virtos_storage_pool_size_bytes gauge"
    echo "virtos_storage_pool_size_bytes $POOL_SIZE"

    sleep 15
done

# Run exporter
chmod +x /opt/monitoring/virtos-metrics-exporter.sh
/opt/monitoring/virtos-metrics-exporter.sh > /var/lib/node_exporter/textfile_collector/virtos.prom &
```

## Alerting Channels

### Email Alerts

Already configured in alertmanager.yml (see above).

### Slack Integration

```bash
# Create Slack webhook
# 1. Go to Slack API: https://api.slack.com/apps
# 2. Create New App
# 3. Add Incoming Webhook
# 4. Copy webhook URL

# Update alertmanager.yml
slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR_SLACK_WEBHOOK_URL'
    channel: '#virtos-alerts'
    username: 'VirtOS AlertManager'
    title: '{{ .GroupLabels.alertname }}'
    text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

### PagerDuty Integration

```bash
# Create PagerDuty service
# 1. Go to PagerDuty
# 2. Services → Add New Service
# 3. Integration type: Prometheus
# 4. Copy Integration Key

# Update alertmanager.yml
pagerduty_configs:
  - service_key: 'YOUR_PAGERDUTY_INTEGRATION_KEY'
    description: '{{ .GroupLabels.alertname }}: {{ .GroupLabels.instance }}'
    details:
      firing: '{{ .Alerts.Firing | len }}'
      resolved: '{{ .Alerts.Resolved | len }}'
```

### SMS Alerts (via Twilio)

```bash
# Install webhook bridge for SMS
sudo vi /opt/monitoring/sms-alerter.sh

#!/bin/bash
# Send SMS via Twilio when critical alert fires

TWILIO_SID="YOUR_ACCOUNT_SID"
TWILIO_TOKEN="YOUR_AUTH_TOKEN"
TWILIO_FROM="+15551234567"
TWILIO_TO="+15559876543"

# Read webhook from AlertManager
MESSAGE="$1"

curl -X POST https://api.twilio.com/2010-04-01/Accounts/$TWILIO_SID/Messages.json \
    --data-urlencode "From=$TWILIO_FROM" \
    --data-urlencode "To=$TWILIO_TO" \
    --data-urlencode "Body=$MESSAGE" \
    -u $TWILIO_SID:$TWILIO_TOKEN
```

## Monitoring Best Practices

### 1. Set Appropriate Thresholds

```yaml
# Don't alert on every blip
# Use `for: 5m` to require sustained condition

# Too sensitive (alerts on brief spikes):
- alert: HighCPU
  expr: cpu_usage > 80

# Better (alerts on sustained high CPU):
- alert: HighCPU
  expr: cpu_usage > 80
  for: 10m
```

### 2. Group Related Alerts

```yaml
# Group by cluster/host to avoid alert storm
route:
  group_by: ['alertname', 'cluster', 'instance']
  group_wait: 30s  # Wait 30s before sending first alert
  group_interval: 5m  # Wait 5m between batched alerts
  repeat_interval: 3h  # Resend unresolved alerts every 3h
```

### 3. Define Severity Levels

```yaml
- alert: DiskSpaceWarning
  expr: disk_usage > 75
  labels:
    severity: warning  # Email/Slack

- alert: DiskSpaceCritical
  expr: disk_usage > 90
  labels:
    severity: critical  # PagerDuty/SMS
```

### 4. Regular Review

- **Weekly**: Review alert history, tune thresholds
- **Monthly**: Review dashboard effectiveness
- **Quarterly**: Update metrics collection as needs change

## Maintenance

### Log Rotation

```bash
# Prometheus data retention (default: 15 days)
/opt/prometheus/prometheus \
    --storage.tsdb.retention.time=30d \
    --storage.tsdb.retention.size=50GB

# Grafana log rotation
sudo vi /etc/logrotate.d/grafana

/var/log/grafana/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

### Backup Monitoring Config

```bash
# Daily backup of monitoring configuration
echo "0 2 * * * tar czf /root/monitoring-backup-\$(date +\%Y\%m\%d).tar.gz /opt/prometheus /opt/grafana /opt/alertmanager" | crontab -
```

## Troubleshooting

### Metrics Not Appearing

```bash
# Check exporter is running
ps aux | grep exporter

# Check exporter is accessible
curl http://localhost:9100/metrics  # Node exporter
curl http://localhost:9177/metrics  # libvirt exporter

# Check Prometheus is scraping
curl http://localhost:9090/targets
# All targets should show "UP"
```

### Alerts Not Firing

```bash
# Check AlertManager is running
curl http://localhost:9093/-/healthy

# Check alert rules loaded
curl http://localhost:9090/api/v1/rules

# Check alerts pending/firing
curl http://localhost:9090/api/v1/alerts

# Test alert manually
curl http://localhost:9093/api/v1/alerts \
    -d '[{"labels":{"alertname":"test"}}]'
```

## Getting Help

- **Prometheus**: <https://prometheus.io/docs/>
- **Grafana**: <https://grafana.com/docs/>
- **VirtOS Monitoring**: [ADMIN-GUIDE.md](ADMIN-GUIDE.md)

---

**Monitoring Setup Guide Version**: 1.0 (2026-05-26)  
**Applies to**: VirtOS 0.80+  
**Related**: [ADMIN-GUIDE.md](ADMIN-GUIDE.md), [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
