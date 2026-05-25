# Kernel Configuration

VirtOS requires a custom Linux kernel with virtualization support enabled.

## Requirements

The VirtOS kernel must include:

### Core Virtualization Support
- **KVM** - Kernel-based Virtual Machine
- **VHOST** - Virtual host drivers for better performance
- **TUN/TAP** - Network virtualization
- **VFIO** - PCI passthrough support

### Container Support
- **Namespaces** - PID, NET, MNT, UTS, IPC, USER
- **Cgroups v1 and v2** - Resource control
- **Overlayfs** - Container filesystem layers
- **Bridge networking** - Container networking

### Storage Support
- **Device Mapper** - LVM support
- **Btrfs** - Copy-on-write filesystem
- **ZFS** - (via external module)
- **Loop devices** - Disk image support

### Hardware Passthrough
- **IOMMU** - Intel VT-d / AMD-Vi
- **VFIO-PCI** - GPU/device passthrough
- **USB passthrough** - USB device assignment

## Kernel Configuration Files

###virtos-base.config
Base kernel configuration with all required options. Use this as a starting point for building a VirtOS kernel.

### virtos-minimal.config
Minimal configuration for size-optimized builds (~100MB target).

### virtos-full.config
Full-featured configuration with all optional drivers and features.

## Building a VirtOS Kernel

### For Tiny Core Linux

```bash
# Download kernel source
cd /tmp
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.6.30.tar.xz
tar xf linux-6.6.30.tar.xz
cd linux-6.6.30

# Copy VirtOS kernel config
cp /path/to/VirtOS/kernel/virtos-base.config .config

# Build kernel
make oldconfig
make -j$(nproc)
make modules_install
make install

# Create Tiny Core kernel package
# (Follow Tiny Core kernel packaging guidelines)
```

### Verification

After building, verify required features are enabled:

```bash
# Check KVM support
grep CONFIG_KVM .config
# Should show: CONFIG_KVM=m or CONFIG_KVM=y

# Check container support
grep CONFIG_NAMESPACES .config
grep CONFIG_CGROUPS .config

# Check virtualization support in running kernel
ls /dev/kvm        # Should exist
lsmod | grep kvm   # Should show kvm modules
```

## Key Kernel Options

### KVM Configuration
```
CONFIG_HAVE_KVM=y
CONFIG_HAVE_KVM_IRQCHIP=y
CONFIG_HAVE_KVM_EVENTFD=y
CONFIG_KVM_MMIO=y
CONFIG_KVM_ASYNC_PF=y
CONFIG_HAVE_KVM_MSI=y
CONFIG_HAVE_KVM_CPU_RELAX_INTERCEPT=y
CONFIG_KVM_VFIO=y
CONFIG_KVM_GENERIC_DIRTYLOG_READ_PROTECT=y
CONFIG_KVM_COMPAT=y
CONFIG_HAVE_KVM_IRQ_BYPASS=y
CONFIG_HAVE_KVM_NO_POLL=y
CONFIG_KVM=m
CONFIG_KVM_INTEL=m
CONFIG_KVM_AMD=m
```

### Namespace Configuration
```
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
```

### Cgroup Configuration
```
CONFIG_CGROUPS=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_PERF=y
CONFIG_CGROUP_BPF=y
CONFIG_CGROUP_SCHED=y
CONFIG_BLK_CGROUP=y
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
```

### Network Configuration
```
CONFIG_NETDEVICES=y
CONFIG_NET_CORE=y
CONFIG_TUN=m
CONFIG_VETH=m
CONFIG_BRIDGE=m
CONFIG_VLAN_8021Q=m
CONFIG_VXLAN=m
CONFIG_MACVLAN=m
CONFIG_MACVTAP=m
CONFIG_OPENVSWITCH=m
```

### Storage Configuration
```
CONFIG_BLK_DEV_LOOP=y
CONFIG_BLK_DEV_NBD=m
CONFIG_DM_SNAPSHOT=m
CONFIG_DM_THIN_PROVISIONING=m
CONFIG_BTRFS_FS=m
CONFIG_OVERLAY_FS=m
CONFIG_EXT4_FS=y
CONFIG_XFS_FS=m
```

### VFIO Configuration (for GPU passthrough)
```
CONFIG_VFIO=m
CONFIG_VFIO_PCI=m
CONFIG_VFIO_IOMMU_TYPE1=m
CONFIG_VFIO_VIRQFD=m
CONFIG_VFIO_MDEV=m
CONFIG_VFIO_MDEV_DEVICE=m
CONFIG_INTEL_IOMMU=y
CONFIG_INTEL_IOMMU_DEFAULT_ON=y
CONFIG_AMD_IOMMU=y
CONFIG_AMD_IOMMU_V2=m
```

## Kernel Patches

### virtos-patches/
Directory containing VirtOS-specific kernel patches:
- **01-optimize-boot.patch** - Boot time optimizations
- **02-kvm-improvements.patch** - KVM performance tweaks
- **03-container-security.patch** - Enhanced container isolation

Apply patches before building:
```bash
cd linux-6.6.30
for patch in /path/to/VirtOS/kernel/virtos-patches/*.patch; do
    patch -p1 < "$patch"
done
```

## Kernel Modules

VirtOS requires these modules to be loaded:

### Essential
- `kvm`
- `kvm_intel` or `kvm_amd`
- `vhost_net`
- `bridge`
- `tun`

### Optional
- `vfio-pci` (GPU passthrough)
- `openvswitch` (advanced networking)
- `dm-thin-pool` (LVM thin provisioning)
- `btrfs` (Btrfs filesystem)

Load modules in `/etc/rc.d/bootlocal.sh`:
```bash
modprobe kvm
modprobe kvm_intel  # or kvm_amd
modprobe vhost_net
modprobe bridge
modprobe tun
```

## Performance Tuning

### Kernel Boot Parameters

Add to bootloader configuration:

```
# Basic KVM support
kvm-intel.nested=1 kvm-intel.enable_shadow_vmcs=1 kvm-intel.enable_apicv=1

# Or for AMD:
kvm-amd.nested=1 kvm-amd.npt=1

# CPU isolation for VMs (example: isolate cores 2-7)
isolcpus=2-7 nohz_full=2-7 rcu_nocbs=2-7

# Huge pages for better performance
default_hugepagesz=2M hugepagesz=2M hugepages=1024

# IOMMU for passthrough
intel_iommu=on iommu=pt
# Or for AMD:
amd_iommu=on iommu=pt
```

### Sysctl Tuning

See `/etc/sysctl.conf` for runtime kernel tuning.

## Tiny Core Linux Kernel Compatibility

VirtOS is based on Tiny Core Linux. Kernel versions tested:
- **6.1.x** - Stable, tested
- **6.6.x** - Recommended
- **6.8.x** - Latest, experimental

Choose kernel version based on:
- Hardware support needs
- Stability requirements
- Feature requirements

## Troubleshooting

### KVM not available
```bash
# Check CPU virtualization support
grep -E 'vmx|svm' /proc/cpuinfo

# If empty, enable in BIOS:
# - Intel: VT-x
# - AMD: AMD-V

# Check kernel module
lsmod | grep kvm
modprobe kvm
modprobe kvm_intel  # or kvm_amd
```

### Container creation fails
```bash
# Check namespace support
ls /proc/self/ns/

# Check cgroup mounting
mount | grep cgroup

# Mount cgroups if missing
mount -t cgroup2 none /sys/fs/cgroup
```

### Device passthrough not working
```bash
# Check IOMMU in kernel
dmesg | grep -i iommu

# Check IOMMU groups
ls /sys/kernel/iommu_groups/

# Verify boot parameters
cat /proc/cmdline | grep iommu
```

## Contributing

To contribute kernel configurations:
1. Test on real hardware
2. Document hardware tested
3. Minimize size while keeping features
4. Submit PR with testing results

## References

- [KVM Documentation](https://www.kernel.org/doc/html/latest/virt/kvm/)
- [Cgroups Documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
- [VFIO Documentation](https://www.kernel.org/doc/Documentation/vfio.txt)
- [Tiny Core Linux Wiki](http://wiki.tinycorelinux.net/)
