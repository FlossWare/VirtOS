# VirtOS AI Modularity Design

**Last Updated**: 2026-05-29  
**Version**: 0.87  
**Status**: Architectural Design Document

## Philosophy

VirtOS follows Tiny Core Linux principles:
- **Minimal** - Only include what's necessary
- **Modular** - Extensions loaded on-demand
- **Flexible** - Customize for your exact needs
- **Choosable** - Everything is optional

**AI capabilities must follow the same philosophy.**

## Problem Statement

If AI features are built into core VirtOS, users who don't need AI get:
- ❌ Larger ISO/packages (unnecessary bloat)
- ❌ Unwanted dependencies (Python, ML libraries)
- ❌ Complexity they don't use
- ❌ Forced updates when AI changes

**This violates VirtOS's modular philosophy.**

## Solution: Complete Modularity

Make AI **completely optional** through separate TCZ packages and build profiles.

**Key Principle**: VirtOS works perfectly without any AI. AI is pure enhancement, never required.

## Package Architecture

### Core Packages (Always Included)

```
virtos-tools.tcz              # 336K - Core VM management (NO AI)
├── virtos-setup              # Setup wizard
├── virtos-create-vm          # VM creation (traditional scheduling)
├── virtos-migrate            # VM migration
├── virtos-snapshot           # Snapshot management
├── virtos-network            # Network configuration
├── virtos-storage            # Storage management
├── virtos-backup             # Backup operations
├── virtos-monitor            # Resource monitoring
├── virtos-cluster            # Cluster discovery
├── virtos-tui                # Text UI
└── ... (29 core scripts)     # All work without AI
```

**Dependencies**: bash, libvirt, qemu, dialog  
**No AI dependencies**: No Python, no ML libraries, no models

### Optional AI Packages (User Chooses)

#### virtos-ai-base.tcz (AI Workload Support)

```
virtos-ai-base.tcz            # ~5MB - Basic AI infrastructure
├── virtos-gpu                # Enhanced GPU management
│   ├── GPU passthrough automation
│   ├── vGPU slicing
│   ├── Multi-tenancy optimization
│   └── CUDA version detection
├── virtos-ai-template        # AI VM templates
│   ├── PyTorch template
│   ├── TensorFlow template
│   ├── JAX template
│   └── CUDA template
└── virtos-ai-monitor         # AI workload monitoring
    ├── GPU utilization tracking
    ├── Training job monitoring
    └── Model inference metrics
```

**Dependencies**: nvidia-driver (optional), cuda (optional)  
**Purpose**: Run AI/ML workloads on VMs (training, inference)  
**Does NOT include**: AI operations, local LLMs, ML models

#### virtos-ai-operations.tcz (AI-Assisted Operations)

```
virtos-ai-operations.tcz      # ~20MB - AI-powered automation
├── virtos-ask                # Natural language interface
│   └── "virtos ask 'create web server'"
├── virtos-diagnose           # Intelligent troubleshooting
│   └── Analyzes logs, suggests fixes
├── virtos-optimize           # AI recommendations
│   ├── VM placement optimization
│   ├── Resource right-sizing
│   ├── Cost optimization
│   └── Waste detection
└── virtos-predict            # Predictive operations
    ├── Capacity planning
    ├── Auto-scaling predictions
    └── Failure prediction
```

**Dependencies**: python3.11, ollama (local LLM), scikit-learn  
**Purpose**: AI helps you manage VirtOS  
**Note**: Requires internet OR local Ollama setup

#### virtos-ai-models.tcz (Pre-configured Templates)

```
virtos-ai-models.tcz          # ~50MB - Model deployment templates
├── templates/
│   ├── llama-3-8b/           # Llama 3 8B deployment
│   ├── mistral-7b/           # Mistral 7B deployment
│   ├── stable-diffusion/     # Stable Diffusion deployment
│   ├── whisper/              # Whisper speech-to-text
│   └── yolo/                 # YOLO object detection
├── configs/
│   ├── quantization.conf     # int8, int4 configs
│   ├── multi-gpu.conf        # Multi-GPU setups
│   └── inference.conf        # Inference optimization
└── scripts/
    ├── deploy-llm.sh         # One-command LLM deployment
    ├── deploy-vision.sh      # Vision model deployment
    └── deploy-audio.sh       # Audio model deployment
```

**Dependencies**: virtos-ai-base.tcz  
**Purpose**: Quick deployment of popular AI models  
**Note**: Downloads models on first use (large!)

#### virtos-ai-inference.tcz (Local LLM Runtime)

```
virtos-ai-inference.tcz       # ~100MB - Local inference server
├── ollama                    # Local LLM runtime
├── models/
│   ├── phi-3-mini (3.8GB)    # Small, fast LLM
│   └── llama-3-8b (4.7GB)    # Default LLM
└── virtos-llm                # LLM management CLI
    ├── virtos-llm list       # List available models
    ├── virtos-llm download   # Download new models
    ├── virtos-llm start      # Start inference server
    └── virtos-llm query      # Query LLM
```

**Dependencies**: virtos-ai-operations.tcz  
**Purpose**: Run LLMs locally (no internet needed)  
**Note**: Large package, optional even for AI users

## Build Profiles

### Profile 1: Minimal (No AI)

```bash
# build/profiles/minimal.conf
INCLUDE_AI_BASE="no"
INCLUDE_AI_OPERATIONS="no"
INCLUDE_AI_MODELS="no"
INCLUDE_AI_INFERENCE="no"

# Build
./build-all.sh --profile minimal

# Result:
# - ISO Size: ~100MB
# - Includes: Core VM management only
# - No AI dependencies
# - Works perfectly for traditional virtualization
```

**Use Case**: Homelab, simple virtualization, resource-constrained environments

### Profile 2: Standard (Default - No AI)

```bash
# build/profiles/standard.conf
INCLUDE_AI_BASE="no"
INCLUDE_AI_OPERATIONS="no"
INCLUDE_AI_MODELS="no"
INCLUDE_AI_INFERENCE="no"

# Build
./build-all.sh  # Default profile

# Result:
# - ISO Size: ~200MB
# - Includes: Core + containers + networking
# - No AI dependencies
# - Standard virtualization + containers
```

**Use Case**: Most users, production workloads, containers + VMs

### Profile 3: AI Workloads (GPU + Templates)

```bash
# build/profiles/ai-workloads.conf
INCLUDE_AI_BASE="yes"         # GPU management, templates
INCLUDE_AI_OPERATIONS="no"    # No AI operations
INCLUDE_AI_MODELS="yes"       # Model templates
INCLUDE_AI_INFERENCE="no"     # No local LLM

# Build
./build-all.sh --profile ai-workloads

# Result:
# - ISO Size: ~250MB
# - Includes: Core + GPU + AI templates
# - Can run ML workloads (training, inference)
# - No AI-assisted operations
```

**Use Case**: ML engineers, AI researchers, GPU workloads

### Profile 4: AI Native (Full AI Stack)

```bash
# build/profiles/ai-native.conf
INCLUDE_AI_BASE="yes"
INCLUDE_AI_OPERATIONS="yes"
INCLUDE_AI_MODELS="yes"
INCLUDE_AI_INFERENCE="yes"    # Includes Ollama + local LLM

# Build
./build-all.sh --profile ai-native

# Result:
# - ISO Size: ~400MB (+ ~5GB models downloaded on first boot)
# - Includes: Everything + AI operations
# - AI-assisted management (virtos-ask, virtos-optimize)
# - Local LLM (Ollama + Phi-3)
```

**Use Case**: AI-first infrastructure, autonomous operations, research

### Profile 5: Custom (User Chooses)

```bash
# build/profiles/custom.conf
INCLUDE_AI_BASE="yes"         # YES - I want GPU support
INCLUDE_AI_OPERATIONS="yes"   # YES - I want AI help
INCLUDE_AI_MODELS="no"        # NO - I don't need templates
INCLUDE_AI_INFERENCE="no"     # NO - I'll use cloud LLMs

# Build
./build-all.sh --profile custom

# Result:
# - ISO Size: ~220MB
# - Exactly what user wants, nothing more
```

## User Experience Examples

### Example 1: Minimal User (No AI)

```bash
# Install VirtOS minimal
# Boot from ISO
# Run setup
virtos-setup

# Create VMs (traditional)
virtos-create-vm --name web-01 --cpu 2 --ram 4096 --disk 20G

# Everything works, no AI involved
# ISO was small (~100MB)
# No unnecessary dependencies
```

### Example 2: Adding AI Later

```bash
# User started with minimal
# Now wants GPU support for ML workload

# Install AI base package
tce-load -wi virtos-ai-base.tcz

# Now GPU features available
virtos-gpu list
virtos-gpu assign nvidia-a100 --vm ml-training-01

# Install AI templates
tce-load -wi virtos-ai-models.tcz

# Deploy LLM quickly
virtos-ai-template deploy llama-3-8b --name chatbot
```

### Example 3: AI-Assisted Operations

```bash
# User wants AI help managing VirtOS
tce-load -wi virtos-ai-operations.tcz

# Natural language interface
virtos ask "create a web server VM with nginx"
# Output: Creating VM 'web-server-01' with:
#   CPU: 2 cores
#   RAM: 4 GB
#   Disk: 20 GB
#   OS: Ubuntu 24.04
#   Post-install: nginx, certbot
# Proceed? [y/n]: y

# AI optimization
virtos optimize --suggest
# Output: Found 3 optimization opportunities:
#   1. VM 'old-test' unused for 45 days → Delete (save $50/month)
#   2. VM 'db-01' 90% idle CPU → Resize 8→4 cores (save $100/month)
#   3. 5 VMs on failing host → Migrate to host-2 (prevent downtime)

# AI troubleshooting
virtos diagnose --vm web-01
# Output: VM 'web-01' is slow
# Analysis:
#   - Disk I/O bottleneck detected
#   - Storage backend: HDD (slow)
#   - Recommendation: Migrate to SSD storage pool
# Fix: virtos-migrate web-01 --storage ssd-pool
```

### Example 4: Local LLM (No Internet)

```bash
# User wants AI operations WITHOUT cloud LLMs
tce-load -wi virtos-ai-inference.tcz

# Ollama + local LLM installed
virtos-llm start

# Now virtos-ask uses local LLM
virtos ask "optimize my cluster"
# (Uses local Phi-3, no internet needed)
```

## TCZ Package Dependencies

```
virtos-tools.tcz
  ├── bash.tcz
  ├── libvirt.tcz
  ├── qemu.tcz
  └── dialog.tcz

virtos-ai-base.tcz
  ├── virtos-tools.tcz
  ├── nvidia-driver.tcz (optional)
  └── cuda.tcz (optional)

virtos-ai-operations.tcz
  ├── virtos-ai-base.tcz
  ├── python3.11.tcz
  ├── scikit-learn.tcz
  └── (optional) virtos-ai-inference.tcz

virtos-ai-models.tcz
  ├── virtos-ai-base.tcz
  └── (downloads models on demand)

virtos-ai-inference.tcz
  ├── virtos-ai-operations.tcz
  ├── ollama.tcz
  └── (downloads LLM on first boot)
```

## Graceful Degradation

All AI features have **fallback behavior** when AI packages aren't installed:

### virtos-create-vm (without AI)
```bash
# Without AI packages
virtos-create-vm --name web-01 --cpu 2 --ram 4096

# Uses traditional scheduling:
# - Round-robin placement
# - No ML-based optimization
# - Works perfectly, just not AI-optimized
```

### virtos-create-vm (with AI)
```bash
# With virtos-ai-operations.tcz installed
virtos-create-vm --name web-01 --cpu 2 --ram 4096

# Uses AI-enhanced scheduling:
# - ML model predicts best host
# - Considers historical performance
# - Optimizes for workload type
```

### virtos-ask (without AI inference)
```bash
# Without virtos-ai-inference.tcz
virtos ask "create web server"

# Uses cloud LLM (OpenAI, Anthropic, etc.)
# Requires: API key + internet
```

### virtos-ask (with AI inference)
```bash
# With virtos-ai-inference.tcz
virtos ask "create web server"

# Uses local Ollama + Phi-3
# No internet needed
# Slower but private
```

## Implementation Plan

### Phase 1: Package Split (Month 1-2)

- [ ] Split virtos-tools.tcz (remove any AI dependencies)
- [ ] Create virtos-ai-base.tcz package
- [ ] Create virtos-ai-operations.tcz package
- [ ] Create virtos-ai-models.tcz package
- [ ] Create virtos-ai-inference.tcz package
- [ ] Update .tcz.dep files

### Phase 2: Build System (Month 2-3)

- [ ] Create build profiles (minimal, standard, ai-workloads, ai-native, custom)
- [ ] Add profile selection to build.conf
- [ ] Update build scripts to respect INCLUDE_AI_* flags
- [ ] Test each profile builds successfully

### Phase 3: Graceful Degradation (Month 3-4)

- [ ] Add AI capability detection to all scripts
- [ ] Implement fallback behavior (no AI → traditional methods)
- [ ] Test all features work without AI packages
- [ ] Document AI vs non-AI behavior differences

### Phase 4: Documentation (Month 4)

- [ ] Update README.md (explain AI modularity)
- [ ] Create AI_MODULARITY.md (this document)
- [ ] Update INSTALLATION.md (profile selection guide)
- [ ] Create AI_QUICKSTART.md (how to add AI later)

### Phase 5: Testing (Month 5)

- [ ] Test minimal profile (no AI)
- [ ] Test standard profile (no AI)
- [ ] Test ai-workloads profile
- [ ] Test ai-native profile
- [ ] Test runtime AI installation (tce-load)
- [ ] Verify graceful degradation

## Size Comparison

| Profile | ISO Size | AI Packages | Use Case |
|---------|----------|-------------|----------|
| **Minimal** | ~100 MB | None | Homelab, basic VMs |
| **Standard** | ~200 MB | None | Production VMs + containers |
| **AI Workloads** | ~250 MB | Base + Models | ML training, GPU workloads |
| **AI Native** | ~400 MB | All | AI-first infrastructure |
| **Custom** | Varies | User choice | Exactly what you need |

**Model downloads (on-demand)**:
- Phi-3 Mini: 3.8 GB
- Llama 3 8B: 4.7 GB
- Mistral 7B: 4.1 GB
- Stable Diffusion: 5.0 GB

## Benefits

### For Minimal Users
✅ **Small ISO** - No AI bloat (~100 MB)  
✅ **Fast boot** - No unnecessary services  
✅ **Simple** - Only what's needed  
✅ **Stable** - AI changes don't affect core

### For AI Users
✅ **Flexible** - Choose exactly what you need  
✅ **Upgradable** - Add AI anytime with tce-load  
✅ **Complete** - Full AI stack available  
✅ **Optional internet** - Local LLM option

### For VirtOS Project
✅ **Modular** - Clean separation of concerns  
✅ **Maintainable** - AI code in separate packages  
✅ **Testable** - Test with/without AI independently  
✅ **Philosophy-aligned** - Truly modular like Tiny Core

## Comparison: Before vs After

### Before (Monolithic)

```
virtos-tools.tcz (500MB)
  ├── Core VM management
  ├── AI operations (forced on everyone)
  ├── Python runtime (forced)
  ├── ML libraries (forced)
  └── LLM models (forced)

❌ Everyone gets AI whether they want it or not
❌ ISO is huge (500+ MB)
❌ Can't opt out
```

### After (Modular)

```
virtos-tools.tcz (336KB)        # Core only
virtos-ai-base.tcz (5MB)        # Optional
virtos-ai-operations.tcz (20MB) # Optional
virtos-ai-models.tcz (50MB)     # Optional
virtos-ai-inference.tcz (100MB) # Optional

✅ Choose exactly what you need
✅ ISO can be tiny (100 MB) or full-featured (400 MB)
✅ Add/remove AI anytime
```

## Security Considerations

### Minimal Attack Surface

Users who don't install AI packages don't get:
- Python runtime (potential vulnerabilities)
- ML libraries (supply chain risks)
- LLM inference server (network exposure)
- Model files (large, untrusted binaries)

**Principle**: Don't ship what you don't need.

### AI Package Security

For users who DO install AI:
- GPG-signed TCZ packages
- Checksum verification for models
- Sandboxed LLM runtime (Ollama in separate namespace)
- Network isolation options
- Model provenance tracking

## FAQ

### Q: Does VirtOS work without AI packages?

**A**: Yes! Perfectly. AI is pure enhancement, never required. All 29 core management scripts work without any AI packages.

### Q: Can I add AI later?

**A**: Yes! Just run `tce-load -wi virtos-ai-base.tcz` anytime after installation.

### Q: What if I only want GPU support, not AI operations?

**A**: Install only `virtos-ai-base.tcz`. Skip `virtos-ai-operations.tcz`.

### Q: Do I need internet for AI operations?

**A**: Optional. Install `virtos-ai-inference.tcz` for local LLM (Ollama). Otherwise, cloud LLMs require internet + API key.

### Q: Can I use VirtOS in air-gapped environments with AI?

**A**: Yes! Install `virtos-ai-inference.tcz` which includes local Ollama + Phi-3. No internet needed after initial setup.

### Q: What's the smallest possible VirtOS?

**A**: ~100 MB (minimal profile, no AI).

### Q: What's the largest possible VirtOS?

**A**: ~400 MB base + ~15 GB models (ai-native profile with all models).

## Related Documentation

- [AI Architecture](AI-ARCHITECTURE.md) - AI capability split (VirtOS vs platform-java)
- [Profiles](PROFILES.md) - Build profile reference
- [Installation](INSTALLATION.md) - Installation guide
- [TCZ Packages](TCZ_PACKAGES.md) - Package system

## References

- Issue #122 - Make AI Capabilities Completely Modular and Optional
- Issue #128 - AI Capabilities Split
- [Tiny Core Linux Extensions](https://tinycorelinux.net/concepts.html)

---

**Status**: Architectural design approved  
**Implementation**: Phase 1-5 (5 months)  
**Priority**: P1 (High) - Core philosophy alignment  
**Next Steps**: Begin Phase 1 (Package Split)
