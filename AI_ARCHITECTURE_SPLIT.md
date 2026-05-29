# AI Architecture Split - VirtOS vs platform-java

**Date**: 2026-05-28  
**Status**: Complete  
**Related**: Issue #128

---

## TL;DR

AI capabilities have been **architecturally separated** between VirtOS (infrastructure AI) and platform-java (application AI).

**VirtOS**: Hypervisor-level AI (VM placement, scaling, security, self-healing)  
**platform-java**: Application-level AI (MLOps, models, RAG, governance)

---

## Architectural Principles

### VirtOS (Infrastructure Layer)

**What it is**: Hypervisor OS, VM/container management, resource allocation  
**Technology**: Shell scripts, Python for ML, Tiny Core Linux, libvirt  
**Scope**: Infrastructure, hosts, hardware, VMs  
**AI Focus**: Resource optimization, infrastructure security, self-healing

### platform-java (Application Layer)

**What it is**: Workload orchestration, application deployment, service management  
**Technology**: Java, pluggable modules, REST APIs  
**Scope**: Applications, workloads, services, business logic  
**AI Focus**: MLOps, model serving, RAG, AI governance

---

## What Goes Where

### ✅ VirtOS (Infrastructure AI)

| Capability | Description | Why VirtOS |
|------------|-------------|------------|
| **AI VM Placement** | ML-based host selection | Hypervisor-level decision |
| **Predictive Auto-Scaling** | Scale VMs before load arrives | Infrastructure resource management |
| **GPU Management** | GPU passthrough, vGPU, topology | Hardware-level resource |
| **Infrastructure Security** | VM anomaly detection, quarantine | Infrastructure security |
| **Cost Optimization** | Find zombie VMs, oversized VMs | Resource allocation decisions |
| **Self-Healing** | Auto-recover failed VMs | VM-level recovery |

**VirtOS Issues**:

- #127 - Advanced AI Capabilities (infrastructure portions)
- #121 - AI Strategy
- #122 - AI Modularity

---

### ✅ platform-java (Application AI)

| Capability | Description | Why platform-java | Issue |
|------------|-------------|-------------------|-------|
| **MLOps Platform** | ML workflow orchestration | Application deployment | #303 |
| **Model Marketplace** | Curated model catalog | Application catalog | #304 |
| **LLM Serving** | Inference service management | Application service | #303 |
| **RAG Infrastructure** | Document Q&A platform | Application workload | #305 |
| **Experiment Tracking** | MLflow integration | Application workflow | #303 |
| **Prompt Management** | Prompt versioning, A/B testing | Application config | #303 |
| **AI Governance** | Model compliance, bias testing | Application policy | #303 |
| **AI Safety** | Content filtering, rate limiting | Application security | #303 |
| **Multi-Modal AI** | Vision, speech models | Application deployment | #304 |

**platform-java Issues**:

- #303 - MLOps Platform
- #304 - Model Marketplace
- #305 - RAG Infrastructure

---

## Integration Pattern

### How They Work Together

```
┌─────────────────────────────────────────────┐
│  User / ChatOps / Web UI                    │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  platform-java (Application AI)             │
│  ┌────────────────────────────────────────┐ │
│  │ • MLOps Platform          (#303)       │ │
│  │ • Model Marketplace       (#304)       │ │
│  │ • RAG Infrastructure      (#305)       │ │
│  │ • LLM Serving                          │ │
│  │ • Experiment Tracking                  │ │
│  │ • AI Governance                        │ │
│  │ • Prompt Management                    │ │
│  │ • Multi-Modal AI                       │ │
│  └────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────┘
                   │ REST API
                   ▼
┌─────────────────────────────────────────────┐
│  VirtOS (Infrastructure AI)                 │
│  ┌────────────────────────────────────────┐ │
│  │ • AI VM Placement         (#127)       │ │
│  │ • Predictive Auto-Scaling (#127)       │ │
│  │ • GPU Management          (existing)   │ │
│  │ • Self-Healing VMs        (#127)       │ │
│  │ • Infrastructure Security (#127)       │ │
│  │ • Cost Optimization       (#127)       │ │
│  └────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│  Hardware (CPUs, GPUs, Storage, Network)    │
└─────────────────────────────────────────────┘
```

---

## Example Workflows

### Example 1: Deploy LLM

**User Request**: "Deploy Llama 3.1 70B model"

**Flow**:

1. **platform-java (#304)**:
   - User calls: `platform-java ai marketplace deploy llama-3.1-70b`
   - Checks model requirements: 40GB VRAM, 8 vCPUs
   - Requests 2x GPU VMs from VirtOS via REST API

2. **VirtOS (#127)**:
   - Receives VM request with GPU requirement
   - AI analyzes available hosts (load, GPU availability, network)
   - Selects optimal host: virtos-node-3 (A100 available, low load)
   - Creates 2x VMs with GPU passthrough
   - Returns: VM IDs, IPs, host assignments

3. **platform-java (#304)**:
   - Receives VM details
   - Deploys Llama model on VMs
   - Configures inference server (vLLM)
   - Sets up monitoring
   - Returns API endpoint to user

**Result**:

- VirtOS: Optimal infrastructure ✓
- platform-java: Model deployed and serving ✓

---

### Example 2: ML Training Job

**User Request**: "Train fraud detection model"

**Flow**:

1. **platform-java (#303)**:
   - User calls: `platform-java ml train fraud-detection`
   - Creates MLflow experiment
   - Prepares training code
   - Requests 4x GPU VMs from VirtOS

2. **VirtOS (#127)**:
   - AI placement: Distributes across 2 hosts (avoid contention)
   - Creates 4 VMs with GPUs
   - Configures low-latency networking between VMs
   - Returns VM cluster details

3. **platform-java (#303)**:
   - Deploys distributed training job
   - Tracks experiments in MLflow
   - Monitors progress
   - Saves trained model to registry

**Result**:

- VirtOS: Optimal distributed infrastructure ✓
- platform-java: Training orchestration ✓

---

### Example 3: RAG Application

**User Request**: "Create internal docs Q&A chatbot"

**Flow**:

1. **platform-java (#305)**:
   - User calls: `platform-java rag project create internal-docs`
   - Requests 3 VMs from VirtOS:
     - Vector DB (Qdrant)
     - Embedding service
     - LLM inference

2. **VirtOS (#127)**:
   - AI placement: Co-locate on same host (low latency)
   - Creates 3 VMs with optimized networking
   - Configures private VLAN
   - Returns VM details

3. **platform-java (#305)**:
   - Deploys Qdrant, embedding service, LLM
   - Ingests documents
   - Creates query pipeline
   - Exposes REST API
   - Returns endpoint to user

**Result**:

- VirtOS: Low-latency infrastructure ✓
- platform-java: RAG application running ✓

---

## API Contract

### platform-java → VirtOS

**Request GPU VM**:

```bash
POST /api/v1/vms
{
  "name": "llm-inference-1",
  "gpu": "nvidia-a100",
  "cpu": 8,
  "ram": 32768,
  "ai_placement": true,
  "optimization": "ml-inference"
}
```

**VirtOS Response**:

```json
{
  "vm_id": "vm-12345",
  "host": "virtos-node-3",
  "ip": "192.168.1.50",
  "gpu_device": "0000:81:00.0",
  "placement_confidence": 0.94,
  "placement_reason": "Low load (20%), fast NVMe, same rack as data source"
}
```

---

## Benefits of This Split

### For VirtOS

- ✅ **Focused scope**: Infrastructure AI only
- ✅ **Lightweight**: No Java runtime needed for core AI
- ✅ **Fast**: ML decisions at hypervisor level
- ✅ **Modular**: AI components optional

### For platform-java

- ✅ **Rich ecosystem**: Java ML libraries (DL4J, DJL, etc.)
- ✅ **Pluggable**: Module-based architecture
- ✅ **Application focus**: Not tied to one hypervisor
- ✅ **Cloud-ready**: Can run on VirtOS, VMware, AWS, etc.

### For Users

- ✅ **Clear separation**: Infrastructure vs. application
- ✅ **Flexible**: Use VirtOS alone or with platform-java
- ✅ **Best of both**: Optimal infrastructure + rich applications
- ✅ **Choice**: Pick the AI features you need

---

## Implementation Timeline

### VirtOS AI (Infrastructure)

**Phase 4** (Month 19-24):

- AI VM placement (ML model)
- Predictive auto-scaling
- Infrastructure security (anomaly detection)
- Cost optimization (waste detection)
- Self-healing VMs

**Effort**: 12-16 weeks

### platform-java AI (Application)

**Phase 4** (Month 19-24):

1. MLOps Platform basics (#303)
2. Model Marketplace (#304)
3. LLM inference serving (#303)

**Phase 5** (Year 3):
4. RAG infrastructure (#305)
5. Experiment tracking (#303)
6. AI governance (#303)
7. Multi-modal support (#304)

**Effort**:

- Phase 4: 20 weeks (MLOps) + 14 weeks (Marketplace) = 34 weeks
- Phase 5: 18 weeks (RAG) + ongoing enhancements

---

## Issues Summary

### VirtOS Issues

- #121 - [STRATEGIC] AI Capabilities Discussion
- #122 - [ARCHITECTURE] AI Modularity
- #127 - [AI] Advanced AI Capabilities (infrastructure portions)
- #128 - [ARCHITECTURE] AI Capabilities Split (this document)

### platform-java Issues

- #303 - [AI] MLOps Platform - ML Workflow Orchestration
- #304 - [AI] Model Marketplace - Curated AI Model Catalog
- #305 - [AI] RAG Infrastructure - Retrieval Augmented Generation

---

## Migration from Original Issue #127

**Original Issue #127** covered all AI capabilities mixed together.

**After Split**:

- **Sections 1-4** (Resource optimization, Security, Cost, Self-healing): Stay in VirtOS
- **Sections 5-11** (MLOps, RAG, Multi-modal, Governance): Move to platform-java

**Updated**:

- VirtOS #127: Updated with split information
- platform-java: 3 new issues created (#303-#305)
- VirtOS #128: Architecture documentation (this file)

---

## Related Documentation

- **AI_STRATEGY.md**: 3-phase AI roadmap (modular, optional)
- **PROJECT_REVIEW.md**: Current state analysis
- **A_PLUS_ROADMAP.md**: 12-month improvement plan

---

## Decision Rationale

### Why Split?

1. **Clear Separation of Concerns**: Infrastructure vs. application
2. **Technology Fit**: Shell/Python for infra, Java for apps
3. **Independent Evolution**: Both can evolve separately
4. **Modularity**: Users pick what they need
5. **Team Focus**: Different expertise for each layer

### Why This Specific Split?

| Decision Point | VirtOS | platform-java |
|----------------|--------|---------------|
| **VM Placement** | ✅ Infrastructure-level decision | |
| **MLOps** | | ✅ Application orchestration |
| **GPU Management** | ✅ Hardware resource | |
| **Model Marketplace** | | ✅ Application catalog |
| **Self-Healing** | ✅ VM-level recovery | |
| **RAG** | | ✅ Application workload |

**Guideline**: If it operates on VMs/hardware → VirtOS. If it deploys applications → platform-java.

---

## Future Considerations

### Coordination Points

As both layers evolve, they'll need to coordinate on:

1. **Metrics**: Shared telemetry for unified dashboards
2. **Cost Attribution**: Track costs across both layers
3. **Security**: Defense in depth policies
4. **Monitoring**: Unified observability
5. **User Experience**: Seamless integration

### Potential Challenges

1. **API Versioning**: Both must maintain compatible APIs
2. **Testing**: Integration testing across both projects
3. **Documentation**: Keep both in sync
4. **Deployment**: Coordinate releases

### Mitigation

- Clear API contracts
- Integration test suite
- Shared documentation
- Coordinated release planning

---

## Conclusion

The architectural split between VirtOS (infrastructure AI) and platform-java (application AI) provides:

✅ **Clear boundaries**: Each project focused on its domain  
✅ **Technology fit**: Right tools for each layer  
✅ **Independent evolution**: Both can advance separately  
✅ **User flexibility**: Pick the AI features you need  
✅ **Scalability**: Each layer can scale independently

**This split sets both projects up for success!** 🚀

---

**Created**: 2026-05-28  
**Status**: Complete  
**Issues Created**: 4 (1 VirtOS, 3 platform-java)
