# Hardware Guide - RTX 3090 24/7 AI Workstation

## Chosen Build: RTX 3090 + Ubuntu Server Headless

This guide documents the hardware selection for a 24/7 local AI workstation focused on LLM inference, ComfyUI image generation, and Home Assistant voice integration.

### Key Decisions
- **GPU**: NVIDIA RTX 3090 24GB (proven CUDA support)
- **Deployment**: Ubuntu Server 24.04 LTS (headless, SSH access)
- **Use Case**: Remote access from main desktop, 24/7 operation

---

## Complete Parts List (~$1,715)

| Component | Model | Price | Rationale |
|-----------|-------|-------|-----------|
| **GPU** | RTX 3090 24GB (used) | $800-1000 | 24GB VRAM for 13B LLMs + SDXL, mature CUDA ecosystem |
| **CPU** | Ryzen 7 5700X | $150 | 8C/16T sufficient for AI serving, efficient 24/7 |
| **Motherboard** | MSI B550-A PRO | $140 | Solid VRM, PCIe 4.0 support |
| **RAM** | 64GB DDR4-3200 (2x32GB) | $130 | Headroom for multiple model loading |
| **OS Drive** | Samsung 980 Pro 1TB NVMe | $80 | Fast Docker I/O, system responsiveness |
| **Model Storage** | Crucial MX500 2TB SATA SSD | $100 | Model storage (200GB+ needed) |
| **PSU** | Corsair RM850x 80+ Gold | $130 | 850W for 350W GPU + headroom |
| **Case** | Fractal Meshify 2 Compact | $120 | Excellent airflow for 24/7 operation |
| **CPU Cooler** | Thermalright PA120 | $35 | Quiet, sufficient cooling |
| **Case Fans** | Arctic P12 PWM (5-pack) | $30 | Quiet, good airflow |
| **Total** | | **$1,715** | Excludes OS (Ubuntu Server free) |

---

## Why RTX 3090 Over Intel Arc Pro 24GB?

### RTX 3090 Advantages (CHOSEN)
✅ **Proven compatibility**: All services (Ollama, ComfyUI, Whisper) are CUDA-first
✅ **NVIDIA Container Toolkit**: Docker GPU passthrough already configured
✅ **24GB VRAM**: Run 13B LLMs (Q4) + SDXL simultaneously
✅ **Mature drivers**: Rock-solid Linux support for 24/7 operation
✅ **Community support**: Massive AI/ML knowledge base
✅ **Model compatibility**: ComfyUI workflows assume CUDA

### Intel Arc Pro Issues (REJECTED)
❌ **No Ollama support**: Requires CUDA or ROCm backend
❌ **Immature drivers**: Linux Arc drivers have reliability issues
❌ **Docker unclear**: Intel GPU plugin not widely adopted
❌ **ComfyUI workflows**: Community workflows assume CUDA, custom nodes won't work
❌ **Unknown reliability**: No track record for 24/7 AI inference

**Verdict**: RTX 3090 is the only viable choice for this stack.

---

## GPU Specifications & Performance

### RTX 3090 24GB
- **Architecture**: Ampere (GA102)
- **CUDA Cores**: 10496
- **VRAM**: 24GB GDDR6X
- **TDP**: 350W (can be limited to 300W for quieter operation)
- **Performance**: ~40-60 tokens/sec (Llama 13B Q4), ~8-10 sec/image (SDXL)

### VRAM Allocation Examples

**Typical concurrent usage:**
```
Total VRAM: 24GB
├─ Ollama (llama3.1:8b Q4): 6GB
├─ ComfyUI (SDXL generation): 8GB
├─ Whisper (base model): 2GB
└─ Available headroom: 8GB
```

**Heavy workload:**
```
Total VRAM: 24GB
├─ Ollama (mistral:13b Q4): 10GB
├─ ComfyUI (Flux.1 schnell): 12GB
└─ Buffer: 2GB (can cause OOM if both running)
```

### Model Capacity
- **7B LLMs**: Q4 (5GB), Q8 (8GB) - comfortable
- **13B LLMs**: Q4 (10GB), Q8 (16GB) - comfortable
- **34B LLMs**: Q4 only (20GB) - tight but possible
- **70B LLMs**: Q4 (40GB+) - not viable on 24GB
- **Image Models**: SD1.5 (4GB), SDXL (7GB), Flux.1 (16-23GB)
- **Video Models**: SVD (16GB), AnimateDiff (12-18GB)

---

## CPU & RAM

### CPU: Ryzen 7 5700X (8C/16T)
- **Why 8 cores?** AI inference is GPU-bound; CPU handles API requests, preprocessing
- **TDP**: 65W base (efficient for 24/7)
- **Platform**: AM4 (cost-effective motherboards and RAM)
- **Alternative**: Intel i5-13600 (14C/20T) if preferring Intel

### RAM: 64GB DDR4-3200
- **Why 64GB?**
  - Ollama loading multiple models: 8-20GB per model
  - ComfyUI large batches: 8-16GB
  - OS + Docker overhead: 4-8GB
  - Future-proofing as models grow

- **32GB minimum** but constraining for this workload

---

## Storage Strategy

### Tier 1: OS & Docker (1TB NVMe Gen4)
- **Path**: `/` (root), `/var/lib/docker`
- **Use**: Fast container I/O, system responsiveness
- **Recommendation**: Samsung 980 Pro 1TB (~$80)

### Tier 2: Model Storage (2TB SATA SSD)
- **Path**: `/mnt/models` (mounted for Docker)
- **Use**: Large model files (100GB+ total)
- **Recommendation**: Crucial MX500 2TB (~$100)
- **Structure**:
  ```
  /mnt/models/
  ├── llm/ollama/              (auto-managed by Ollama)
  ├── stable-diffusion/
  │   ├── checkpoints/         (SDXL, SD1.5, Flux models)
  │   ├── vae/
  │   ├── loras/
  │   ├── controlnet/
  │   └── upscale_models/
  └── video/
      ├── svd/
      └── animatediff/
  ```

### Optional Tier 3: Output Storage (4TB HDD via NAS)
- **Use**: Generated images/videos accumulate quickly
- **Alternative**: Mount NFS share from existing NAS

### Model Size Planning
- **Minimal** (~50GB): Llama 8B, SDXL, Whisper Base
- **Recommended** (~200GB): Multiple LLMs, SDXL + LoRAs, ControlNet suite
- **Enthusiast** (500GB+): Large LLM collection, full video model library

---

## Power Supply & Cooling

### PSU: 850W 80+ Gold
**Power calculation:**
- RTX 3090: 350W peak (can limit to 300W)
- Ryzen 7 5700X: 65-105W
- Motherboard/RAM/Storage: 50-75W
- **Total peak**: ~600W → 850W PSU provides 30% headroom

**Recommendations**: Corsair RM850x, EVGA SuperNOVA 850 G6

### Cooling for 24/7 Operation

**GPU Cooling:**
- RTX 3090 runs hot (85-90°C under sustained load)
- **Solution**: Undervolt/limit power to 300W (5-10% perf loss, 20°C cooler, much quieter)
- Case airflow critical: 3x intake (front), 2x exhaust (rear/top)

**CPU Cooling:**
- Thermalright Peerless Assassin 120 (~$35) sufficient
- AIO unnecessary for 65W TDP CPU

**Case Airflow:**
- Positive pressure setup (intake > exhaust)
- Dust filters on all intakes
- Mesh front panel (Fractal Meshify 2 Compact)

**Thermal Targets:**
- GPU: <80°C sustained (85°C acceptable)
- CPU: <70°C sustained

---

## Power Consumption & Operating Costs

### 24/7 Power Usage
- **Idle** (services running, no inference): 100-120W
- **Light load** (Ollama chat): 180-220W
- **Heavy load** (ComfyUI batch generation): 350-400W
- **24/7 average** (mixed usage): ~200W

### Annual Operating Costs
At $0.15/kWh electricity rate:
- **Idle/light** (150W avg): ~$197/year (~$16/month)
- **Mixed usage** (200W avg): ~$263/year (~$22/month)
- **Heavy usage** (300W avg): ~$394/year (~$33/month)

**Compare to cloud AI services:**
- ChatGPT Plus: $240/year
- Midjourney: $360/year
- Cloud GPU (RunPod/Vast): $600+/year
- **Total cloud**: $1200+/year
- **Payback period**: 17-22 months

---

## GPU Optimization for 24/7

### Power Limit (Reduces heat/noise)
```bash
# Reduce 3090 from 350W to 300W
sudo nvidia-smi -pl 300

# Make persistent across reboots
sudo nano /etc/systemd/system/nvidia-power-limit.service
```

```ini
[Unit]
Description=Set NVIDIA GPU Power Limit
After=nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi -pl 300
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

### Enable Persistence Mode
```bash
sudo nvidia-smi -pm 1
```

**Benefits**: Lower temps (70-75°C instead of 85°C), quieter fans, minimal performance loss

---

## Noise Management

### Noise Sources (Ranked)
1. **RTX 3090 fans**: 40-50 dB under load (loudest)
2. **Case fans**: 25-35 dB (tunable)
3. **CPU cooler**: 20-30 dB (minimal)
4. **PSU fan**: 15-25 dB (minimal)

### Mitigation Strategies
1. **Physical isolation**: Place server in basement/closet, access via network
2. **Power limiting**: 300W limit significantly reduces fan speed
3. **Case fan curves**: Configure in BIOS for 800-1200 RPM (quiet)
4. **Quality fans**: Arctic P12 PWM (quiet, good airflow)

**Realistic expectation**: Audible when generating images/video. Headless deployment in separate room is key for comfortable home use.

---

## Purchasing Guide

### RTX 3090 24GB (Used Market)
**Where to buy:**
- eBay (buyer protection)
- r/hardwareswap (lower prices, buyer beware)
- Local classifieds (Facebook Marketplace, Craigslist)

**What to check:**
- ✅ EVGA, MSI, ASUS brands (better cooling)
- ✅ Test before buying if local
- ✅ Ask about mining history (honest sellers exist)
- ✅ Check warranty transferability (EVGA transfers, ASUS doesn't)
- ❌ Avoid blower-style coolers (too loud)
- ❌ Avoid heavily modified cards (custom BIOS, removed pads)

**Price targets:**
- Good deal: $750-850
- Fair: $850-950
- High: $950-1100

### New vs. Used Comparison
| Component | New | Used | Recommendation |
|-----------|-----|------|----------------|
| GPU | N/A (discontinued) | $800-1000 | Used only option |
| CPU | $150 | $100-120 | Buy new (warranty) |
| RAM | $130 | $90-110 | Buy new (reliability) |
| Storage | $180 | $120-150 | Buy new (SSD lifespan) |
| PSU | $130 | $70-90 | Buy new (safety) |

---

## Alternative Builds

### Budget Option (~$1,200)
- GPU: RTX 3060 12GB ($400 used)
- CPU: Ryzen 5 5600 ($120)
- RAM: 32GB ($85)
- **Limitation**: Can't run 13B models comfortably, SDXL tight

### Performance Option (~$3,000)
- GPU: RTX 4090 24GB ($1,600 new)
- CPU: Ryzen 7 7700X ($300)
- RAM: 64GB DDR5 ($220)
- **Benefit**: Faster inference (~2x speed), newer architecture

**Chosen RTX 3090 build** provides best value for 24/7 operation.

---

## Next Steps

1. **Purchase RTX 3090**: Check r/hardwareswap, eBay, local listings
2. **Order remaining parts**: Use PCPartPicker for price tracking
3. **While waiting**: Review `docker-compose.yml`, plan network setup
4. **Build system**: Follow assembly best practices (antistatic, cable management)
5. **See docs/DEPLOYMENT.md**: Ubuntu Server installation and headless setup
