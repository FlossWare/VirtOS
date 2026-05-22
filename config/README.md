# Configuration Directory

System configuration files for FlossWare VirtOS.

## Files

- `bootlocal.sh` - Boot-time initialization script
- `network.conf` - Network configuration (bridges, routing)
- `onboot.lst` - Extensions to load at boot
- `sysctl.conf` - Kernel parameters for virtualization
- `firewall.rules` - iptables rules
- `libvirt/` - libvirt configuration (if using)
- `lxc/` - LXC default configuration
- `containers/` - Container runtime configuration

## Integration

These files will be integrated into the custom ISO during build process.
