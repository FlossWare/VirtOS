# VirtOS AI Architecture

**Last Updated**: 2026-05-29  
**Version: 0.89  
**Status**: Architectural Decision Document

## Overview

This document defines the **architectural separation** of AI capabilities between VirtOS (infrastructure layer) and platform-java (application layer).

## Architecture Layers

### VirtOS (Infrastructure Layer)

**Purpose**: Hypervisor OS, VM/container management, resource allocation  
**Technology**: Shell scripts, Tiny Core Linux, libvirt, QEMU  
**Scope**: Infrastructure, physical hosts, hardware resources, VMs  
**AI Focus**: Infrastructure optimization and automation

### platform-java (Application Layer)

**Purpose**: Workload orchestration, application deployment, service management  
**Technology**: Java, pluggable modules, REST APIs  
**Scope**: Applications, workloads, services, business logic  
**AI Focus**: ML/AI workload deployment and operations

## AI Capabilities Distribution

### VirtOS Infrastructure AI ✅

AI capabilities that operate at the **infrastructure/hypervisor level**:

#### 1. VM Placement Optimization 🎯

**What**: Intelligent placement decisions for new VMs  
**Why VirtOS**: Hypervisor-level decision about physical host selection

```bash
# VirtOS decides optimal physical host
virtos-create-vm --name web-server --ai-placement

# Analyzes:
# - CPU availability per host
# - RAM availability per host  
# - Disk I/O patterns
# - Network topology
# - Hardware capabilities

# Decision: "Place on virtos-host-3 (lowest load, best network path)"
```

**Implementation**:
- ML model trained on historical placement success/failure
- Real-time resource monitoring across cluster
- Considers affinity/anti-affinity rules
- Optimizes for performance, cost, or availability

#### 2. VM Auto-Scaling 📈

**What**: Automatically create/destroy VMs based on load  
**Why VirtOS**: Infrastructure resource management at VM level

```bash
# Enable auto-scaling for a VM tier
virtos-ai autoscale enable web-tier \
    --min-vms 2 \
    --max-vms 10 \
    --target-cpu 70%

# VirtOS monitors and scales:
# - CPU usage across VM tier
# - Memory pressure
# - Network traffic
# - Request queue depth

# Actions:
# - Create new VMs when load > threshold
# - Destroy VMs when load < threshold
# - Rebalance workload across VMs
```

**Implementation**:
- Predictive scaling using time-series ML models
- Considers historical load patterns
- Accounts for VM startup time
- Coordinates with platform-java for graceful scaling

#### 3. GPU Management 🎮

**What**: Intelligent GPU allocation and management  
**Why VirtOS**: Hardware-level resource management

```bash
# Assign GPU to VM with AI optimization
virtos-gpu assign nvidia-a100 --vm llm-server --ai-optimize

# VirtOS manages:
# - GPU passthrough vs vGPU
# - Multi-VM GPU sharing
# - GPU memory allocation
# - CUDA version compatibility

# AI decisions:
# - Which GPU for which workload (compute vs graphics)
# - Multi-tenancy optimization
# - Power/thermal management
```

**Implementation**:
- GPU workload profiling
- Automatic mode selection (passthrough vs vGPU)
- Multi-tenancy optimization
- Power/thermal aware scheduling

#### 4. Infrastructure Security 🔒

**What**: Anomaly detection at VM/host level  
**Why VirtOS**: Infrastructure security monitoring

```bash
# Enable AI security monitoring
virtos-ai security-monitor enable

# Monitors:
# - Unusual CPU patterns (crypto mining)
# - Network anomalies (data exfiltration)
# - Process behavior (unexpected executables)
# - Resource usage spikes
# - Lateral movement attempts

# Actions:
# - Alert operator
# - Quarantine VM (network isolation)
# - Create forensic snapshot
# - Auto-remediate (configurable)
```

**Implementation**:
- Baseline behavioral models per VM
- Anomaly detection using statistical ML
- Integration with virtos-security
- Real-time alerting and response

#### 5. Cost Optimization 💰

**What**: Infrastructure waste detection and recommendations  
**Why VirtOS**: Resource allocation and efficiency

```bash
# Generate AI-powered cost report
virtos-ai waste-report

# Detects:
# - Zombie VMs (not used in 30+ days)
# - Oversized VMs (90% idle resources)
# - Unused storage volumes
# - Redundant snapshots
# - Inefficient placement

# Recommendations:
# - Delete unused resources
# - Resize VMs to actual usage
# - Consolidate VMs to fewer hosts
# - Archive old snapshots
```

**Implementation**:
- Usage pattern analysis
- Cost modeling per resource
- Optimization recommendations
- Integration with virtos-billing

#### 6. Self-Healing Infrastructure 🔧

**What**: Automatic VM recovery and remediation  
**Why VirtOS**: VM-level health and recovery

```bash
# Enable self-healing for critical VMs
virtos-ai self-heal enable --vm database-01

# Monitors:
# - VM responsiveness (ping, SSH)
# - Application health checks
# - Resource exhaustion
# - Hardware failures

# Actions:
# - Restart unresponsive VM
# - Migrate from failing host
# - Increase resources if exhausted
# - Restore from snapshot if corrupted
```

**Implementation**:
- Health check framework
- Automated recovery procedures
- Integration with virtos-ha
- Incident logging and analysis

#### 7. Infrastructure Monitoring 📊

**What**: AI-enhanced metrics and insights  
**Why VirtOS**: Host/VM level observability

**Capabilities**:
- Predictive capacity planning
- Performance bottleneck detection
- Resource trend analysis
- Automated baseline adjustment

### platform-java Application AI ✅

AI capabilities that operate at the **application/workload level**:

#### 1. MLOps Platform 🛠️

**What**: Complete ML lifecycle management  
**Why platform-java**: Application deployment and orchestration

```bash
# Create ML project
platform-java ml project create fraud-detection

# Deploys and orchestrates:
# - JupyterLab for development
# - MLflow for experiment tracking
# - Training jobs (distributed)
# - Model serving endpoints
# - Feature stores
# - Data pipelines

# VirtOS provides: VMs/containers to run these workloads
# platform-java provides: Orchestration, lifecycle, APIs
```

**Components**:
- Development environments (Jupyter, VSCode)
- Experiment tracking (MLflow, W&B)
- Training orchestration (distributed jobs)
- Model registry and versioning
- Inference serving (REST, gRPC)
- Feature engineering pipelines

#### 2. Model Marketplace 🏪

**What**: Catalog and deployment of pre-trained models  
**Why platform-java**: Application-level model management

```bash
# Browse and deploy models
platform-java ml marketplace search llm
platform-java ml marketplace deploy llama-3-70b \
    --name chatbot \
    --gpu-count 2

# Manages:
# - Model catalog and metadata
# - Version management
# - Deployment configurations
# - Scaling policies
# - API endpoints
```

**Features**:
- Curated model catalog (open source + custom)
- One-click deployment
- Version management
- Performance benchmarking
- Cost estimation

#### 3. LLM Inference Serving 🤖

**What**: Large language model deployment and serving  
**Why platform-java**: Complex application orchestration

```bash
# Deploy LLM with optimizations
platform-java ml llm deploy gpt-j-6b \
    --quantization int8 \
    --batch-size 32 \
    --replicas 3

# Handles:
# - Model loading and initialization
# - Request batching and queueing
# - Load balancing across replicas
# - Response streaming
# - API rate limiting
```

**Optimizations**:
- Quantization (int8, int4)
- Request batching
- KV cache management
- Multi-replica load balancing

#### 4. RAG Infrastructure 📚

**What**: Retrieval-Augmented Generation systems  
**Why platform-java**: Application-level data and model integration

```bash
# Create RAG pipeline
platform-java ml rag create docs-assistant \
    --vectordb chromadb \
    --embeddings sentence-transformers \
    --llm llama-3-70b

# Orchestrates:
# - Document ingestion and chunking
# - Vector embedding generation
# - Vector database indexing
# - Query processing
# - LLM context augmentation
# - Response generation
```

**Components**:
- Document processors
- Embedding models
- Vector databases
- Query engines
- Context builders

#### 5. Experiment Tracking 📈

**What**: ML experiment management and comparison  
**Why platform-java**: Application workflow management

```bash
# Track experiments
platform-java ml experiment start \
    --name hyperparameter-tuning \
    --framework pytorch

# Tracks:
# - Hyperparameters
# - Metrics (accuracy, loss, etc.)
# - Artifacts (models, plots)
# - Environment (dependencies, hardware)
# - Comparison across runs
```

#### 6. AI Governance 📋

**What**: ML model governance and compliance  
**Why platform-java**: Business logic and policy enforcement

```bash
# Enable governance
platform-java ml governance enable

# Enforces:
# - Model approval workflows
# - Bias detection and mitigation
# - Explainability requirements
# - Audit trails
# - Compliance reporting
```

**Features**:
- Model approval workflows
- Bias/fairness testing
- Explainability (SHAP, LIME)
- Audit logging
- Compliance reports

#### 7. Multi-Modal Support 🎨

**What**: Vision, audio, video ML workloads  
**Why platform-java**: Complex application pipelines

```bash
# Deploy vision model
platform-java ml vision deploy yolov8 \
    --task object-detection \
    --input-stream rtsp://camera1

# Handles:
# - Video/image ingestion
# - Pre-processing pipelines
# - Model inference
# - Post-processing
# - Result storage/streaming
```

## Integration Architecture

### Communication Flow

```
┌─────────────────────────────────────────────┐
│          platform-java (Application)        │
│                                             │
│  MLOps │ Models │ RAG │ Governance        │
│                                             │
└────────────────┬────────────────────────────┘
                 │ REST API
                 ▼
┌─────────────────────────────────────────────┐
│          VirtOS (Infrastructure)            │
│                                             │
│  VM Placement │ Auto-Scale │ GPU │ Healing │
│                                             │
└─────────────────────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
    [Host 1]       [Host 2]       [Host 3]
```

### API Integration

**platform-java → VirtOS**:

```bash
# platform-java requests infrastructure via VirtOS API
POST /api/v1/vms
{
  "name": "ml-training-job-001",
  "cpu": 16,
  "memory": 65536,
  "gpu": "nvidia-a100",
  "ai_placement": true,
  "ai_scaling": {
    "enabled": true,
    "min_cpu": 8,
    "max_cpu": 32
  }
}

# VirtOS makes AI-powered decisions:
# - Best host for placement
# - GPU allocation strategy
# - Monitoring and scaling policies
```

**VirtOS → platform-java**:

```bash
# VirtOS notifies platform-java of infrastructure events
POST http://platform-java:8080/api/infrastructure/events
{
  "event": "vm_scaled",
  "vm": "ml-training-job-001",
  "old_cpu": 16,
  "new_cpu": 32,
  "reason": "high_load"
}

# platform-java adjusts workload accordingly
```

### Metrics Sharing

**Shared telemetry**:

```bash
# VirtOS exports infrastructure metrics
virtos-ai metrics export --format prometheus

# Metrics:
# - vm_cpu_usage{vm="ml-job-001",host="virtos-1"}
# - vm_memory_usage{vm="ml-job-001",host="virtos-1"}
# - vm_gpu_utilization{vm="ml-job-001",gpu="0"}

# platform-java exports application metrics
platform-java ml metrics export --format prometheus

# Metrics:
# - ml_training_loss{job="fraud-detection",epoch="42"}
# - ml_inference_latency{model="llama-3",percentile="p95"}
# - ml_batch_size{job="training-001"}

# Both feed into unified monitoring (Prometheus/Grafana)
```

### Cost Attribution

**Cross-layer cost tracking**:

```bash
# VirtOS tracks infrastructure costs
virtos-billing report --group-by workload

# Shows:
# - VM compute costs (CPU hours)
# - Storage costs (GB-months)
# - GPU costs (GPU hours)
# - Network costs (GB transferred)

# platform-java tracks application costs
platform-java ml billing report

# Shows:
# - Training costs (GPU hours × job)
# - Inference costs (requests × model)
# - Storage costs (datasets, models)

# Combined view:
Total Cost: ML Training Job "fraud-detection"
  Infrastructure (VirtOS): $450/day (GPU, compute, storage)
  Application (platform-java): $50/day (data processing, API calls)
  Total: $500/day
```

## Implementation Priorities

### VirtOS Infrastructure AI

**Phase 4** (Months 19-24):
1. ✅ VM placement optimization (ML model)
2. ✅ Predictive auto-scaling
3. ✅ Infrastructure security (anomaly detection)
4. ✅ Cost optimization (waste detection)
5. ✅ Self-healing VMs

**Effort**: 6 months (parallel development)

### platform-java Application AI

**Phase 4** (Months 19-24):
1. ✅ MLOps platform basics (Jupyter, MLflow)
2. ✅ Model marketplace (curated catalog)
3. ✅ LLM inference serving

**Phase 5** (Year 3):
4. RAG infrastructure
5. Experiment tracking enhancements
6. AI governance framework
7. Multi-modal support (vision, audio)

**Effort**: 12 months (iterative)

## Design Principles

### VirtOS AI Principles

1. **Lightweight**: No heavy ML frameworks, use simple models
2. **Fast**: Infrastructure decisions in milliseconds
3. **Optional**: All AI features are opt-in modules
4. **Deterministic**: Fallback to non-AI methods if models fail
5. **Transparent**: Explain AI decisions to operators

### platform-java AI Principles

1. **Rich Ecosystem**: Leverage Java ML libraries (DL4J, TensorFlow Java)
2. **Pluggable**: Module-based architecture, swap implementations
3. **Scalable**: Distributed workload orchestration
4. **Cloud-Native**: Run on any infrastructure (VirtOS, AWS, GCP)
5. **Developer-Friendly**: Simple APIs, good documentation

## Benefits of This Split

### For VirtOS
✅ **Focused scope**: Infrastructure AI only, no application complexity  
✅ **Lightweight**: Small ML models, fast inference  
✅ **Independent**: Works standalone without platform-java  
✅ **Minimal**: Stays true to Tiny Core philosophy

### For platform-java
✅ **Rich ecosystem**: Full Java ML libraries available  
✅ **Pluggable**: Easy to add new ML frameworks  
✅ **Scalable**: Distributed training and inference  
✅ **Flexible**: Deploy on any infrastructure

### For Users
✅ **Clear separation**: Infrastructure vs. application concerns  
✅ **Flexible deployment**: Use VirtOS alone or with platform-java  
✅ **Best of both worlds**: Optimal infrastructure + rich ML workloads  
✅ **Choice**: Pick only the AI features you need

## Examples

### Example 1: LLM Training + Deployment

**User Goal**: Train and deploy a large language model

**VirtOS provides** (Infrastructure AI):
- Optimal GPU host placement for training VM
- Auto-scaling: Add GPUs during training, reduce for inference
- Cost tracking: GPU hours, storage costs
- Self-healing: Restart training if VM fails

**platform-java provides** (Application AI):
- MLOps: Jupyter for development, MLflow for tracking
- Training orchestration: Distributed training across GPUs
- Model registry: Version control for checkpoints
- Inference serving: REST API for model queries
- Monitoring: Training metrics, inference latency

**Workflow**:
```bash
# 1. platform-java requests training VM from VirtOS
platform-java ml train start llm-custom \
    --framework pytorch \
    --gpus 8

# VirtOS (AI placement):
# → Selects host with 8× A100 GPUs available
# → Creates VM on optimal host
# → Enables auto-scaling and self-healing

# 2. platform-java orchestrates training
# → Launches Jupyter for development
# → Runs distributed training job
# → Tracks experiments in MLflow

# 3. VirtOS monitors infrastructure
# → Detects high GPU usage
# → Monitors for VM failures
# → Tracks costs

# 4. platform-java deploys trained model
platform-java ml deploy llm-custom \
    --version latest \
    --replicas 3

# VirtOS (AI placement):
# → Places inference VMs on different hosts (HA)
# → Enables auto-scaling based on request load
```

### Example 2: Infrastructure Optimization

**User Goal**: Reduce infrastructure costs

**VirtOS provides** (Infrastructure AI):
```bash
# Run cost optimization analysis
virtos-ai waste-report

# Output:
# Zombie VMs: 5 (not used in 30+ days) → Save $200/month
# Oversized VMs: 12 (90% idle CPU) → Save $500/month
# Unused storage: 2 TB → Save $100/month
# Inefficient placement: 8 VMs → Save $150/month (power)
#
# Total potential savings: $950/month
#
# Recommendations:
# 1. Delete zombie VMs: vm-test-01, vm-old-backup, ...
# 2. Resize oversized VMs: web-01 (16→8 CPU), db-02 (32→16 CPU)
# 3. Archive unused volumes: vol-2023-backup, vol-old-snapshots
# 4. Consolidate VMs: Move 8 VMs from virtos-host-5 to host-2
```

**platform-java provides** (Application AI):
```bash
# Optimize ML workload costs
platform-java ml optimize costs

# Output:
# Model inference optimizations:
# - Use int8 quantization for llama-3 → Save 60% GPU memory
# - Batch requests (size 32) → Reduce inference cost by 40%
# - Use spot instances for training → Save 70% on compute
#
# Total potential savings: $1,200/month
```

## Security Considerations

### VirtOS Infrastructure Security

- **Threat Model**: VM-level attacks, resource abuse, lateral movement
- **Detection**: Behavioral anomaly detection (CPU, network, processes)
- **Response**: Quarantine, snapshot, alert, auto-remediate
- **Privacy**: No application data inspection, only infrastructure metrics

### platform-java Application Security

- **Threat Model**: Model poisoning, data leakage, adversarial inputs
- **Detection**: Input validation, output sanitization, model monitoring
- **Response**: Block requests, retrain models, audit logs
- **Privacy**: PII detection, data anonymization, encryption

## Open Questions

1. **API Design**: Should VirtOS expose AI features via REST API or CLI only?
   - **Proposal**: Both (CLI for humans, API for platform-java)

2. **Model Storage**: Where to store ML models for VirtOS AI features?
   - **Proposal**: `/var/lib/virtos/ai/models/` with auto-download

3. **Telemetry**: Should VirtOS send anonymized telemetry to improve AI models?
   - **Proposal**: Opt-in telemetry, fully anonymized, user-controlled

4. **Backward Compatibility**: How to ensure existing VirtOS works without AI?
   - **Proposal**: All AI features are optional modules, graceful degradation

## Related Documentation

- [AI Strategy](../README.md#ai-capabilities) - Overall AI vision
- [platform-java Architecture](https://github.com/FlossWare/platform-java/docs/ARCHITECTURE.md)
- [VirtOS Roadmap](ROADMAP.md) - Implementation timeline

## References

- Issue #127 - Advanced AI Capabilities
- Issue #128 - AI Capabilities Split (this document)
- Issue #121 - AI Strategy
- Issue #122 - AI Modularity

---

**Decision**: Clear architectural separation with defined integration points  
**Status**: Approved  
**Next Steps**: Implement Phase 4 features in parallel (VirtOS + platform-java)
