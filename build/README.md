# Build Directory

This directory contains build scripts and tools for creating FlossWare VirtOS.

## Structure

```
build/
├── scripts/          # Build automation scripts
├── downloads/        # Downloaded base files (Tiny Core, etc.)
├── workspace/        # Temporary build workspace
└── output/           # Final ISO output
```

## Build Scripts (to be created)

- `prepare.sh` - Download and prepare Tiny Core base
- `kernel.sh` - Configure and build custom kernel (if needed)
- `packages.sh` - Build/download required TCZ packages
- `customize.sh` - Customize initrd and boot scripts
- `iso.sh` - Generate final bootable ISO
- `build-all.sh` - Complete build pipeline

## Usage

```bash
# Initial setup
./scripts/prepare.sh

# Build custom ISO
./scripts/build-all.sh

# Output will be in output/VirtOS-*.iso
```

## Build Requirements

See [../docs/GETTING-STARTED.md](../docs/GETTING-STARTED.md) for prerequisites.
