# VirtOS Build Configurator (Interactive TUI)

**Last Updated**: 2026-05-29  
**Version: 0.89  
**Status**: Design Document (Not Yet Implemented)

## Overview

An interactive Text User Interface (TUI) for configuring VirtOS ISO builds, making it easy to select exactly what to include without manually editing configuration files.

## Problem Statement

**Current build process** requires users to:

- Manually edit `build/build.conf`
- Remember all 50+ configuration options
- Know dependencies between options
- Validate configuration by trial and error
- Understand technical implications of choices

**This creates barriers for new users and increases configuration errors.**

## Solution: virtos-configure

An interactive TUI that:

- Shows all available options with descriptions
- Calculates ISO size and build time estimates
- Validates dependencies automatically
- Provides preset profiles (minimal, standard, AI-native, etc.)
- Generates valid build.conf
- Optionally launches build immediately

## User Experience

### Launch

```bash
# Run from VirtOS repository root
./virtos-configure

# Or from build directory
cd build
./scripts/virtos-configure
```

### Main Screen

```
┌────────────────────────────────────────────────────────────────────────┐
│                  VirtOS ISO Build Configurator v0.87                   │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Build Profile: [Custom ▼]  (minimal, standard, ai-native, custom)    │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │ Core Virtualization                                              │ │
│  │  [✓] KVM/QEMU Support                          Required          │ │
│  │  [✓] libvirt Integration                       Required          │ │
│  │  [ ] LXC Containers                            ~15MB             │ │
│  │                                                                  │ │
│  │ Container Runtimes                                               │ │
│  │  [✓] Docker                                    ~50MB             │ │
│  │  [ ] Podman                                    ~60MB             │ │
│  │  [✓] containerd                                ~40MB             │ │
│  │                                                                  │ │
│  │ AI Capabilities                                                  │ │
│  │  [ ] AI Workload Support (GPU, templates)     ~30MB             │ │
│  │      └─ Enables: virtos-gpu, AI VM templates                    │ │
│  │  [ ] AI-Assisted Operations                   ~20MB + LLM       │ │
│  │      └─ Requires: AI Workload Support, Python 3.x               │ │
│  │      └─ LLM: [ ] Local (Ollama, +500MB)  [✓] Cloud API          │ │
│  │  [ ] AI Model Templates                       ~50MB             │ │
│  │      └─ Requires: AI Workload Support                           │ │
│  │                                                                  │ │
│  │ Advanced Features                                                │ │
│  │  [✓] Clustering (Avahi mDNS)                  ~10MB             │ │
│  │  [ ] Kubernetes (K3s)                         ~100MB            │ │
│  │  [✓] Web UI (Cockpit)                         ~80MB             │ │
│  │  [ ] Desktop Environment (FLWM)               ~30MB             │ │
│  │                                                                  │ │
│  │ Storage Backends                                                 │ │
│  │  [✓] LVM                                      ~15MB             │ │
│  │  [ ] Btrfs                                    ~25MB             │ │
│  │  [ ] ZFS (requires 4GB+ RAM)                  ~60MB             │ │
│  │  [ ] NFS Client                               ~10MB             │ │
│  │  [ ] Ceph Client                              ~40MB             │ │
│  │  [ ] GlusterFS Client                         ~35MB             │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  Estimated ISO Size: 250 MB  (min: 100MB, max: 800MB)                 │
│  Estimated Build Time: ~15 minutes                                    │
│  RAM Required: 4 GB  (8 GB+ recommended)                              │
│                                                                        │
│  [Save Config]  [Build Now]  [Load Profile]  [Help]  [Exit]          │
└────────────────────────────────────────────────────────────────────────┘

↑↓: Navigate  Space: Select  Enter: Confirm  Tab: Next Section  ?: Help
```

### Profile Selection

```
┌────────────────────────────────────────────────────────────────────────┐
│                         Select Build Profile                           │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  > minimal          ~100 MB    KVM only, smallest footprint           │
│                                                                        │
│    standard         ~200 MB    VMs + containers (recommended)         │
│                                Docker, Podman, containerd, LXC        │
│                                                                        │
│    full             ~300 MB    Everything except AI                   │
│                                All containers, K8s, advanced storage   │
│                                                                        │
│    ai-workloads     ~250 MB    Standard + GPU + AI templates          │
│                                For running ML workloads                │
│                                                                        │
│    ai-native        ~700 MB    Full AI platform with local LLM        │
│                                AI operations, Ollama, model templates  │
│                                                                        │
│    kubernetes       ~250 MB    K3s orchestration ready                │
│                                Standard + K3s                          │
│                                                                        │
│    storage          ~350 MB    Advanced storage features              │
│                                Btrfs, LVM, ZFS, Ceph, GlusterFS       │
│                                                                        │
│    custom           varies     Choose your own options                │
│                                Full control over all features          │
│                                                                        │
│  [Select]  [Cancel]  [View Details]                                   │
└────────────────────────────────────────────────────────────────────────┘

Press Enter to select profile, d for details, Esc to cancel
```

### Dependency Resolution

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Dependency Resolution                           │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ⚠️  AI-Assisted Operations requires additional components:            │
│                                                                        │
│  Required (will be enabled automatically):                             │
│    [✓] AI Workload Support              +30 MB                        │
│    [✓] Python 3.11 runtime              +50 MB                        │
│                                                                        │
│  Choose LLM backend (required):                                        │
│    ( ) Local LLM (Ollama + Phi-3)       +500 MB, no internet needed   │
│    (●) Cloud LLM (API)                  +0 MB, requires API key       │
│                                                                        │
│  Optional (recommended):                                               │
│    [ ] AI Model Templates               +50 MB                        │
│    [ ] GPU Support (NVIDIA/AMD)         +100 MB                       │
│                                                                        │
│  Total size change: +80 MB (with cloud LLM)                           │
│                                                                        │
│  [Continue]  [Cancel]  [Details]                                      │
└────────────────────────────────────────────────────────────────────────┘

Cloud LLM requires OpenAI, Anthropic, or compatible API key (configured later)
```

### Validation Warnings

```
┌────────────────────────────────────────────────────────────────────────┐
│                         Configuration Warnings                         │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ⚠️  Warnings (can proceed):                                           │
│                                                                        │
│  1. ZFS selected but RAM < 8 GB                                        │
│     Recommendation: 8 GB+ RAM for ZFS stability                        │
│     Action: Continue anyway or disable ZFS                             │
│                                                                        │
│  2. AI-native profile but no GPU                                       │
│     Recommendation: Add NVIDIA/AMD GPU support for ML workloads        │
│     Action: Continue (CPU-only) or enable GPU support                  │
│                                                                        │
│  3. Large ISO size (780 MB)                                            │
│     Recommendation: Consider reducing features for smaller ISO         │
│     Action: Continue or remove optional components                     │
│                                                                        │
│  ℹ️  Information:                                                      │
│                                                                        │
│  • Clustering enabled: mDNS discovery will work on local network       │
│  • Web UI enabled: Access at https://virtos-host:9090 after boot      │
│  • K3s enabled: 2 GB+ RAM recommended per cluster node                │
│                                                                        │
│  [Continue Anyway]  [Review Config]  [Cancel]                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Build Progress

```
┌────────────────────────────────────────────────────────────────────────┐
│                          Building VirtOS ISO                           │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Profile: custom                                                       │
│  Output: VirtOS-0.87-custom.iso                                       │
│                                                                        │
│  [████████████████████████░░░░░░░░░░] 65% - Building packages...      │
│                                                                        │
│  Steps:                                                                │
│    [✓] Download Tiny Core base                     2m 15s             │
│    [✓] Install core packages                       4m 32s             │
│    [✓] Build virtos-tools.tcz                      1m 08s             │
│    [→] Build virtos-ai-base.tcz                    0m 45s (running)   │
│    [ ] Build virtos-platform-java.tcz                                 │
│    [ ] Create bootable ISO                                            │
│    [ ] Generate checksums                                             │
│                                                                        │
│  Elapsed: 8m 40s  |  Remaining: ~6m 20s  |  Total: ~15m              │
│                                                                        │
│  [View Log]  [Cancel Build]                                           │
└────────────────────────────────────────────────────────────────────────┘

Building virtos-ai-base.tcz (GPU management, templates)...
```

### Build Complete

```
┌────────────────────────────────────────────────────────────────────────┐
│                          Build Complete! ✓                             │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  ISO File: build/output/VirtOS-0.87-custom.iso                        │
│  Size: 248 MB                                                          │
│  Build Time: 14m 32s                                                   │
│  Checksum: SHA256:a3f2...d8e1                                          │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │ What's Included:                                                 │ │
│  │                                                                  │ │
│  │ Core:                                                            │ │
│  │  ✓ KVM/QEMU virtualization                                      │ │
│  │  ✓ libvirt management                                           │ │
│  │  ✓ virtos-tools (54 management scripts)                         │ │
│  │                                                                  │ │
│  │ Containers:                                                      │ │
│  │  ✓ Docker                                                        │ │
│  │  ✓ containerd                                                    │ │
│  │                                                                  │ │
│  │ AI:                                                              │ │
│  │  ✓ AI workload support (GPU management)                         │ │
│  │  ✓ AI VM templates (PyTorch, TensorFlow)                        │ │
│  │                                                                  │ │
│  │ Advanced:                                                        │ │
│  │  ✓ Clustering (Avahi)                                           │ │
│  │  ✓ Web UI (Cockpit)                                             │ │
│  │  ✓ LVM storage                                                  │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  Next Steps:                                                           │
│   1. Create bootable USB: dd if=VirtOS-0.87-custom.iso of=/dev/sdX   │
│   2. Or test in VM: qemu-system-x86_64 -cdrom VirtOS-0.87-custom.iso │
│   3. Boot and run: virtos-setup                                       │
│                                                                        │
│  [Create USB]  [Test in VM]  [Exit]  [Build Another]                 │
└────────────────────────────────────────────────────────────────────────┘
```

## Configuration Output

Generated `build/build.conf`:

```bash
# VirtOS Build Configuration
# Generated by virtos-configure on 2026-05-29

# Build metadata
BUILD_PROFILE="custom"
BUILD_VERSION="0.87"
BUILD_DATE="2026-05-29"

# Core virtualization (required)
INCLUDE_KVM="yes"
INCLUDE_LIBVIRT="yes"
INCLUDE_LXC="no"

# Container runtimes
INCLUDE_DOCKER="yes"
INCLUDE_PODMAN="no"
INCLUDE_CONTAINERD="yes"

# AI capabilities
INCLUDE_AI_BASE="yes"              # GPU support, templates
INCLUDE_AI_OPERATIONS="no"         # AI-assisted operations
INCLUDE_AI_MODELS="yes"            # Pre-configured models
INCLUDE_AI_INFERENCE="no"          # Local LLM (Ollama)

# Advanced features
INCLUDE_CLUSTERING="yes"           # Avahi mDNS
INCLUDE_KUBERNETES="no"            # K3s
INCLUDE_WEB_UI="yes"               # Cockpit
INCLUDE_DESKTOP="no"               # FLWM

# Storage backends
INCLUDE_LVM="yes"
INCLUDE_BTRFS="no"
INCLUDE_ZFS="no"
INCLUDE_NFS_CLIENT="no"
INCLUDE_CEPH_CLIENT="no"
INCLUDE_GLUSTER_CLIENT="no"

# Network
INCLUDE_OVN="no"                   # Open Virtual Network
INCLUDE_SDN="no"                   # Software-defined networking

# Security
INCLUDE_SELINUX="no"
INCLUDE_APPARMOR="no"

# Development tools
INCLUDE_DEV_TOOLS="no"             # GCC, make, git

# Size estimates (auto-calculated)
ESTIMATED_ISO_SIZE="248MB"
ESTIMATED_BUILD_TIME="15m"
```

## Implementation

### Technology Stack

**Framework**: dialog (ncurses wrapper)  
**Language**: Bash  
**Dependencies**: dialog, coreutils, awk

### File Structure

```
build/scripts/
├── virtos-configure              # Main TUI script
├── lib/
│   ├── config-profiles.sh        # Profile definitions
│   ├── config-options.sh         # All available options
│   ├── config-deps.sh            # Dependency resolver
│   ├── config-validate.sh        # Validation logic
│   └── config-estimate.sh        # Size/time estimation
└── templates/
    ├── build.conf.template       # Base template
    └── profiles/
        ├── minimal.conf
        ├── standard.conf
        ├── ai-native.conf
        └── custom.conf
```

### Core Functions

```bash
#!/bin/bash
# virtos-configure - Interactive build configurator

VERSION="0.87"

# Load libraries
source "$(dirname "$0")/lib/config-profiles.sh"
source "$(dirname "$0")/lib/config-options.sh"
source "$(dirname "$0")/lib/config-deps.sh"
source "$(dirname "$0")/lib/config-validate.sh"
source "$(dirname "$0")/lib/config-estimate.sh"

# Main menu
show_main_menu() {
    local config_file="${1:-build/build.conf}"

    # Load current config or defaults
    load_config "$config_file"

    while true; do
        local choice=$(dialog --clear --backtitle "VirtOS Build Configurator v$VERSION" \
            --title "Main Menu" \
            --menu "Choose action:" 15 60 6 \
            1 "Select Build Profile" \
            2 "Configure Options" \
            3 "Review Configuration" \
            4 "Save Configuration" \
            5 "Build Now" \
            0 "Exit" \
            3>&1 1>&2 2>&3)

        case $choice in
            1) select_profile ;;
            2) configure_options ;;
            3) review_config ;;
            4) save_config "$config_file" ;;
            5) build_iso ;;
            0|"") exit 0 ;;
        esac
    done
}

# Profile selection
select_profile() {
    local profile=$(dialog --clear --backtitle "VirtOS Build Configurator" \
        --title "Select Build Profile" \
        --menu "Choose profile:" 20 70 7 \
        minimal "~100 MB - KVM only, minimal footprint" \
        standard "~200 MB - VMs + containers (recommended)" \
        full "~300 MB - Everything except AI" \
        ai-workloads "~250 MB - Standard + GPU + AI templates" \
        ai-native "~700 MB - Full AI platform with local LLM" \
        kubernetes "~250 MB - K3s orchestration ready" \
        storage "~350 MB - Advanced storage features" \
        custom "varies - Choose your own options" \
        3>&1 1>&2 2>&3)

    if [ -n "$profile" ]; then
        load_profile "$profile"
        dialog --msgbox "Profile '$profile' loaded successfully!" 6 50
    fi
}

# Configure individual options
configure_options() {
    while true; do
        local options=$(build_checklist)

        local selected=$(dialog --clear --backtitle "VirtOS Build Configurator" \
            --title "Configure Build Options" \
            --checklist "Select components (Space to toggle):" \
            25 80 15 \
            $options \
            3>&1 1>&2 2>&3)

        if [ $? -eq 0 ]; then
            update_config "$selected"

            # Check dependencies
            resolve_dependencies

            # Show warnings if any
            show_validation_warnings

            break
        else
            break
        fi
    done
}

# Build checklist from current config
build_checklist() {
    echo "kvm 'KVM/QEMU Support' $([ "$INCLUDE_KVM" = "yes" ] && echo "ON" || echo "OFF")"
    echo "lxc 'LXC Containers (~15MB)' $([ "$INCLUDE_LXC" = "yes" ] && echo "ON" || echo "OFF")"
    echo "docker 'Docker (~50MB)' $([ "$INCLUDE_DOCKER" = "yes" ] && echo "ON" || echo "OFF")"
    echo "podman 'Podman (~60MB)' $([ "$INCLUDE_PODMAN" = "yes" ] && echo "ON" || echo "OFF")"
    echo "containerd 'containerd (~40MB)' $([ "$INCLUDE_CONTAINERD" = "yes" ] && echo "ON" || echo "OFF")"
    echo "ai-base 'AI Workload Support (~30MB)' $([ "$INCLUDE_AI_BASE" = "yes" ] && echo "ON" || echo "OFF")"
    # ... more options
}

# Dependency resolution
resolve_dependencies() {
    # If AI operations selected, require AI base
    if [ "$INCLUDE_AI_OPERATIONS" = "yes" ] && [ "$INCLUDE_AI_BASE" != "yes" ]; then
        dialog --yesno "AI Operations requires AI Workload Support.\n\nEnable AI Workload Support?" 8 50
        if [ $? -eq 0 ]; then
            INCLUDE_AI_BASE="yes"
        else
            INCLUDE_AI_OPERATIONS="no"
        fi
    fi

    # Similar logic for other dependencies
}

# Validation warnings
show_validation_warnings() {
    local warnings=""

    # Check ZFS + RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [ "$INCLUDE_ZFS" = "yes" ] && [ "$ram_gb" -lt 8 ]; then
        warnings="$warnings\n⚠️  ZFS selected but RAM < 8 GB (detected: ${ram_gb}GB)"
    fi

    # Check ISO size
    local size=$(estimate_iso_size)
    if [ "$size" -gt 600 ]; then
        warnings="$warnings\n⚠️  Large ISO size: ${size}MB"
    fi

    if [ -n "$warnings" ]; then
        dialog --msgbox "Configuration Warnings:$warnings\n\nYou can continue anyway or review configuration." 12 60
    fi
}

# Main entry point
main() {
    if ! command -v dialog >/dev/null 2>&1; then
        echo "Error: 'dialog' not installed"
        echo "Install with: sudo apt install dialog"
        exit 1
    fi

    show_main_menu "$@"
}

main "$@"
```

## Features

### Auto-Calculation

- **ISO Size**: Sum of selected component sizes
- **Build Time**: Based on number of packages
- **RAM Requirements**: Based on selected features (ZFS, K3s, etc.)

### Validation

- **Dependency checks**: Auto-enable required components
- **Conflict detection**: Warn about incompatible selections
- **Resource warnings**: Alert if system resources insufficient
- **Size warnings**: Alert if ISO becomes very large

### Presets

**Minimal** (~100 MB):

- KVM/QEMU only
- libvirt
- virtos-tools

**Standard** (~200 MB):

- Minimal + Docker + containerd + LXC
- Clustering
- Web UI

**AI Native** (~700 MB):

- Standard + all AI packages
- Local LLM (Ollama)
- GPU support

**Custom**:

- User chooses everything

## Benefits

### For Users

✅ **Easier configuration** - No config file editing  
✅ **Visual feedback** - See size/time estimates  
✅ **Fewer errors** - Validation before build  
✅ **Learn options** - Discover features while configuring  
✅ **Faster workflow** - Configure and build in one session

### For VirtOS

✅ **Lower barrier to entry** - New users can build easily  
✅ **Better UX** - Professional, guided experience  
✅ **Reduced support** - Fewer config errors  
✅ **Feature discovery** - Users see all capabilities

## Related Documentation

- [Build Profiles](PROFILES.md) - Profile reference
- [Configuration](CONFIGURATION.md) - All config options
- [AI Modularity](AI-MODULARITY.md) - AI package architecture
- [Getting Started](GETTING-STARTED.md) - Build guide

## References

- Issue #123 - Interactive TUI for ISO Build Configuration
- Issue #125 - Enhance virtos-tui
- [dialog Manual](https://invisible-island.net/dialog/)

---

**Status**: Design approved  
**Implementation**: 4-6 weeks  
**Priority**: P2 (Medium) - Nice to have, not critical  
**Dependencies**: dialog package
