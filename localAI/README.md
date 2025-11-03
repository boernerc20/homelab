# Local AI Workstation - 24/7 Headless Server

A complete Docker-based AI infrastructure for running local LLMs, image/video generation, and Home Assistant voice integration on dedicated hardware.

## What This Is

A production-ready setup for running AI services 24/7 on a **headless Ubuntu Server** with remote access from your main desktop. Think of it as your own private OpenAI/Midjourney server running in your home.

### Hardware Target
- **GPU**: RTX 3090 24GB (or similar 24GB NVIDIA GPU)
- **Deployment**: Ubuntu Server 24.04 LTS (headless, SSH access)
- **Use Case**: Remote AI inference serving for LLMs, ComfyUI, voice assistant

---

## Features

🤖 **LLM Inference** - Run Llama, Mistral, Codestral models locally via Ollama
🎨 **Image Generation** - Stable Diffusion, SDXL, Flux via ComfyUI
🎥 **Video Generation** - AnimateDiff and Stable Video Diffusion support
🗣️ **Voice Assistant** - Whisper (STT) + Piper (TTS) for Home Assistant
🔍 **Private Search** - SearXNG for web-augmented LLM responses
🏠 **Home Automation** - Full Home Assistant integration
🐳 **Docker Everything** - All services in containers, easy management

---

## Repository Structure

```
localAI/
├── README.md                 # This file - project overview
├── QUICK_START.md            # Fast 30-minute setup guide
├── docker-compose.yml        # All services configuration
├── .env.example              # Environment variables template
├── CLAUDE.md                 # AI assistant context (project instructions)
│
├── docs/                     # Detailed documentation
│   ├── HARDWARE.md           # RTX 3090 build guide (~$1,700)
│   ├── DEPLOYMENT.md         # Ubuntu Server headless setup
│   ├── MODELS.md             # Model recommendations by use case
│   ├── COMFYUI.md            # ComfyUI workflows and setup
│   └── HOME_ASSISTANT.md     # Voice assistant integration
│
└── scripts/                  # Automation scripts
    ├── setup.sh              # Automated system setup
    ├── download-models.sh    # Download common models
    ├── backup.sh             # Backup configurations
    └── monitor.sh            # System/GPU monitoring
```

---

## Quick Start

### 1. Hardware
Build or buy a system with:
- RTX 3090 24GB (~$800-1000 used)
- Ryzen 7 5700X or similar 8-core CPU
- 64GB RAM
- 1TB NVMe + 2TB SSD storage
- 850W PSU

See **[docs/HARDWARE.md](docs/HARDWARE.md)** for complete parts list and rationale.

### 2. Install Ubuntu Server
1. Install Ubuntu Server 24.04 LTS (headless, no GUI)
2. Configure static IP during install
3. Enable SSH server
4. **Disconnect monitor - you won't need it again**

See **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** for step-by-step installation.

### 3. Initial Setup (via SSH)

```bash
# SSH from your main desktop
ssh chris@192.168.1.100

# Clone repository
git clone <your-repo-url> ~/projects/homelab/localAI
cd ~/projects/homelab/localAI

# Run automated setup (installs NVIDIA drivers, Docker, etc.)
./scripts/setup.sh

# Create model storage
sudo mkdir -p /mnt/models/llm/ollama
sudo mkdir -p /mnt/models/stable-diffusion/{checkpoints,vae,loras,controlnet}
sudo mkdir -p /mnt/models/video/{svd,animatediff}
sudo chown -R $USER:$USER /mnt/models

# Configure environment
cp .env.example .env
nano .env  # Change WEBUI_SECRET_KEY
```

### 4. Start Services

```bash
# Start all Docker services
docker compose up -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### 5. Access from Main Desktop

**In your browser:**
- ComfyUI: http://192.168.1.100:8188
- Open-WebUI: http://192.168.1.100:3000
- SearXNG: http://192.168.1.100:8080

**In your terminal:**
```bash
# Point Ollama CLI to remote server
export OLLAMA_HOST=http://192.168.1.100:11434

# Pull and run models
ollama pull llama3.1:8b
ollama run llama3.1:8b "Write a Python function to sort a list"
```

### 6. Download Models

```bash
# SSH to AI workstation
ssh 192.168.1.100

# Download LLMs via Ollama
docker exec ollama ollama pull llama3.1:8b
docker exec ollama ollama pull mistral:7b

# Download image models (see docs/MODELS.md for links)
cd /mnt/models/stable-diffusion/checkpoints
wget <model-url>
```

---

## Service Ports

| Service | Port | Access |
|---------|------|--------|
| **Open-WebUI** | 3000 | http://ai-workstation:3000 |
| **ComfyUI** | 8188 | http://ai-workstation:8188 |
| **Ollama API** | 11434 | http://ai-workstation:11434 |
| **SearXNG** | 8080 | http://ai-workstation:8080 |
| **Whisper (Wyoming)** | 9000 | For Home Assistant |
| **Piper (Wyoming)** | 10200 | For Home Assistant |
| **Text-Gen-WebUI** | 7860 | http://ai-workstation:7860 |

---

## Documentation

### Getting Started
- **[QUICK_START.md](QUICK_START.md)** - 30-minute speedrun setup
- **[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Complete Ubuntu Server headless setup

### Hardware & Planning
- **[docs/HARDWARE.md](docs/HARDWARE.md)** - RTX 3090 build guide (~$1,700 total)

### Services & Integration
- **[docs/MODELS.md](docs/MODELS.md)** - Which models to use for your VRAM
- **[docs/COMFYUI.md](docs/COMFYUI.md)** - Image generation workflows
- **[docs/HOME_ASSISTANT.md](docs/HOME_ASSISTANT.md)** - Voice assistant setup

---

## Daily Usage (Headless Workflow)

### From Your Main Desktop:

**SSH Management:**
```bash
ssh ai-workstation "docker compose ps"
ssh ai-workstation "nvidia-smi"
ssh ai-workstation "./scripts/monitor.sh"
```

**ComfyUI:**
- Open http://ai-workstation:8188 in browser
- Load workflow, queue generations
- Download results to main desktop

**Ollama:**
```bash
export OLLAMA_HOST=http://ai-workstation:11434
ollama run llama3.1:8b
```

**VS Code Remote:**
- Install "Remote - SSH" extension
- Connect to ai-workstation
- Edit configs directly on server

**You never need physical access to the server after initial setup.**

---

## Why This Architecture?

### Headless Ubuntu Server
✅ No wasted resources on desktop GUI
✅ Rock-solid 24/7 stability
✅ Lower power consumption
✅ Easier security (smaller attack surface)

### Remote Access
✅ Access from any device (desktop, laptop, phone)
✅ Server can be in basement/closet (noise isolation)
✅ VS Code Remote SSH for seamless editing
✅ Browser-based UIs for ComfyUI/Open-WebUI

### RTX 3090 24GB
✅ Run 13B LLMs + SDXL simultaneously
✅ Proven CUDA ecosystem (Ollama, ComfyUI work perfectly)
✅ 24GB VRAM sweet spot for mixed workloads
✅ Strong used market ($800-1000)

See [docs/HARDWARE.md](docs/HARDWARE.md) for why we chose RTX 3090 over alternatives.

---

## Operating Costs

### Hardware: ~$1,700 one-time
- RTX 3090 24GB: $800-1000
- CPU/MB/RAM/Storage: $900-700

### Power: ~$25-35/month (24/7 operation)
- Average 200W load
- At $0.15/kWh electricity

### Compare to Cloud AI:
- ChatGPT Plus: $20/month
- Midjourney: $30/month
- Cloud GPU: $50+/month
- **Total: $100+/month**

**Payback period: 17-22 months, then pure savings.**

---

## Troubleshooting

### Can't SSH In
```bash
# At the physical machine:
ip a  # Find IP address
sudo systemctl status ssh  # Check SSH running
```

### Services Won't Start
```bash
ssh ai-workstation
docker compose logs [service-name]
docker compose restart [service-name]
```

### GPU Not Working
```bash
# Verify NVIDIA driver
nvidia-smi

# Test Docker GPU access
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

### Out of VRAM
- Use smaller models (7B instead of 13B)
- Higher quantization (Q4 instead of Q8)
- Don't run ComfyUI + large LLM simultaneously
- Add `--lowvram` to ComfyUI if needed

---

## Maintenance

### Daily (Optional)
```bash
ssh ai-workstation "nvidia-smi"  # Check GPU temp/utilization
```

### Weekly
```bash
ssh ai-workstation
docker compose logs --tail 100  # Check for errors
./scripts/monitor.sh  # System overview
```

### Monthly
```bash
# Update system
sudo apt update && sudo apt upgrade

# Update Docker images
docker compose pull
docker compose up -d

# Backup configs
./scripts/backup.sh
```

---

## Security

### Firewall (Configured during setup)
```bash
# Services only accessible from local network
sudo ufw allow from 192.168.1.0/24
```

### Remote Access Outside Home
**Use Tailscale (recommended):**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# Access from anywhere via 100.x.x.x IPs
```

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for VPN setup.

---

## Next Steps

1. **Hardware**: Review [docs/HARDWARE.md](docs/HARDWARE.md), order RTX 3090 build
2. **Install**: Follow [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for Ubuntu Server setup
3. **Models**: See [docs/MODELS.md](docs/MODELS.md) for what to download
4. **ComfyUI**: Check [docs/COMFYUI.md](docs/COMFYUI.md) for workflows
5. **Home Assistant**: Integrate with [docs/HOME_ASSISTANT.md](docs/HOME_ASSISTANT.md)

---

## Resources

- [Ollama Model Library](https://ollama.com/library)
- [ComfyUI Examples](https://comfyanonymous.github.io/ComfyUI_examples/)
- [CivitAI Models](https://civitai.com/)
- [Home Assistant Docs](https://www.home-assistant.io/docs/)

---

## Contributing

Issues and enhancement requests welcome! This is a living project.

## License

Open source for personal and educational use.

---

**Built for hobbyists who want powerful local AI without cloud subscriptions.**

**Questions?** Check the [docs/](docs/) folder or open an issue.
