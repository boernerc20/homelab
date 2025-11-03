# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a local AI workstation infrastructure project designed for 24/7 headless operation. It provides a complete Docker-based stack for running:
- Local LLMs (via Ollama)
- Image/video generation (via ComfyUI)
- Voice assistant capabilities (Whisper/Piper)
- Home Assistant integration
- Privacy-focused web search (SearXNG)

The project is primarily **documentation and configuration-based** rather than application code. The actual AI services run in Docker containers.

### Confirmed Hardware & Deployment Decisions
- **GPU**: NVIDIA RTX 3090 24GB (~$1,700 total build)
- **OS**: Ubuntu Server 24.04 LTS (headless, no GUI)
- **Deployment**: Remote access via SSH from main desktop
- **Use Case**: 24/7 AI inference server accessible over local network

## Architecture

### Service Stack
All services run via Docker Compose in an isolated network (`ai-network`):

1. **Ollama** (port 11434) - LLM inference engine, GPU-accelerated
2. **Open-WebUI** (port 3000) - Chat interface, depends on Ollama
3. **ComfyUI** (port 8188) - Image/video generation, GPU-accelerated
4. **SearXNG** (port 8080) - Privacy-focused search
5. **Whisper** (port 9000) - Speech-to-text, GPU-accelerated
6. **Piper** (port 10200) - Text-to-speech
7. **Text-Generation-WebUI** (port 7860/5000) - Alternative LLM interface
8. **Watchtower** - Automatic container updates (Sundays 3 AM)

### GPU Access
All GPU-accelerated services (Ollama, ComfyUI, Whisper, Text-Gen-WebUI) use NVIDIA Container Toolkit with the deployment configuration:
```yaml
deploy:
  resources:
    reservations:
      devices:
        - driver: nvidia
          count: all
          capabilities: [gpu]
```

### Storage Architecture
- **./data/** - Persistent data for all services (created at runtime)
- **/mnt/models/** - Large model storage (must be created before first run)
  - `/mnt/models/llm/ollama` - LLM models
  - `/mnt/models/stable-diffusion/` - Image models (checkpoints, vae, loras, controlnet, embeddings, upscale_models)
  - `/mnt/models/video/` - Video models (svd, animatediff)

## Common Commands

### Service Management
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f ollama

# Restart a service
docker compose restart [service-name]

# Rebuild and restart
docker compose up -d --force-recreate

# Check service status
docker compose ps
```

### Model Management
```bash
# Download models interactively
./scripts/download-models.sh

# Pull LLM via Ollama (inside container)
docker exec ollama ollama pull llama3.1:8b

# List available Ollama models
docker exec ollama ollama list

# Remove an Ollama model
docker exec ollama ollama rm [model-name]

# Run interactive chat with model
docker exec -it ollama ollama run llama3.1:8b
```

### Setup and Maintenance
```bash
# Initial system setup (NVIDIA drivers, Docker, directories)
./scripts/setup.sh

# System monitoring (one-time view)
./scripts/monitor.sh

# System monitoring (auto-refresh every 10 seconds)
./scripts/monitor.sh --watch

# Backup configurations and workflows
./scripts/backup.sh

# Backup with custom destination
BACKUP_DIR=/path/to/backup ./scripts/backup.sh
```

### GPU Monitoring
```bash
# Real-time GPU stats
watch -n 1 nvidia-smi

# Check GPU is accessible to Docker
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

# GPU optimization (persistence mode)
sudo nvidia-smi -pm 1

# Set GPU power limit (for quieter/cooler 24/7 operation)
sudo nvidia-smi -pl 250  # Adjust wattage for your GPU
```

### Troubleshooting
```bash
# Test Ollama API
curl http://localhost:11434/api/tags

# Test Ollama generation
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Hello",
  "stream": false
}'

# Check ComfyUI
curl http://localhost:8188

# Verify NVIDIA driver
nvidia-smi

# Restart Docker daemon
sudo systemctl restart docker
```

## Important Configuration Notes

### Environment Variables
Copy `.env.example` to `.env` and configure:
- `WEBUI_SECRET_KEY` - Must be changed from default
- `TZ` - Timezone for services
- Model paths and resource limits

### Model Storage
The `/mnt/models` directory MUST exist before starting services. ComfyUI mounts this as `/opt/ComfyUI/models` inside the container. If models aren't appearing:
1. Verify `/mnt/models` exists and has correct permissions
2. Check that models are in the correct subdirectories
3. Restart ComfyUI service: `docker compose restart comfyui`

### Service Dependencies
- Open-WebUI requires Ollama to be running
- Web search in Open-WebUI requires SearXNG
- Home Assistant voice requires both Whisper and Piper

## Home Assistant Integration

Integration is done via REST API and Wyoming protocol. Key configuration patterns documented in `HOME_ASSISTANT_INTEGRATION.md`:

1. **Wyoming Protocol** - Add Whisper (port 9000) and Piper (port 10200) as integrations in HA
2. **LLM Conversation** - Use Extended OpenAI Conversation integration pointing to Ollama's OpenAI-compatible endpoint (`http://ai-workstation-ip:11434/v1`)
3. **Voice Pipeline** - Configure in HA Settings → Voice Assistants
4. **ComfyUI Automation** - Use REST commands to trigger image generation from HA automations

## Development Workflow

### Adding New Services
1. Add service definition to `docker-compose.yml`
2. Ensure it's on the `ai-network`
3. Add GPU resources if needed
4. Document port in README.md service ports table
5. Add health check to `scripts/monitor.sh`

### Modifying Scripts
All scripts in `scripts/` are bash scripts with:
- Color-coded output (GREEN, YELLOW, RED, BLUE, NC)
- Error handling (`set -e`)
- User confirmations for destructive operations

### Documentation Structure
```
localAI/
├── README.md                 # Main entry, project overview
├── QUICK_START.md            # 30-minute speedrun setup
├── CLAUDE.md                 # This file - AI assistant context
├── docker-compose.yml        # Service definitions
├── .env.example              # Environment template
├── .gitignore                # Git exclusions
│
├── docs/                     # All detailed documentation
│   ├── HARDWARE.md           # RTX 3090 build guide
│   ├── DEPLOYMENT.md         # Ubuntu Server headless setup
│   ├── MODELS.md             # Model recommendations
│   ├── COMFYUI.md            # ComfyUI workflows
│   └── HOME_ASSISTANT.md     # Home Assistant integration
│
└── scripts/                  # Automation scripts
    ├── setup.sh              # System setup
    ├── download-models.sh    # Model downloads
    ├── backup.sh             # Backup configs
    └── monitor.sh            # System monitoring
```

## Target Hardware (Confirmed Build)

**Chosen Configuration:**
- **GPU**: RTX 3090 24GB (used, $800-1000)
- **CPU**: Ryzen 7 5700X (8C/16T)
- **RAM**: 64GB DDR4-3200
- **Storage**: 1TB NVMe (OS) + 2TB SSD (models)
- **PSU**: 850W 80+ Gold
- **OS**: Ubuntu Server 24.04 LTS (headless)
- **Total Cost**: ~$1,715

**Deployment Model:**
- Headless server (no monitor after initial setup)
- SSH access from main desktop
- All services accessed via network (HTTP/REST APIs)
- Server can be placed in basement/closet for noise isolation

## Key Design Decisions

1. **Docker-first**: All services containerized for easy management and isolation
2. **GPU sharing**: All services can access GPU simultaneously via NVIDIA runtime
3. **Model separation**: Large models stored outside containers at `/mnt/models` to survive container rebuilds
4. **24/7 operation**: Auto-restart policies, Watchtower for updates, monitoring scripts
5. **Privacy-focused**: All processing local, optional SearXNG for web search instead of external APIs
6. **Home Assistant ready**: Wyoming protocol support for voice, OpenAI-compatible API for LLM

## Common Issues

### "Out of memory" errors
- Models are too large for available VRAM
- Use smaller models or higher quantization (Q4 instead of Q8)
- For ComfyUI, add `--lowvram` to CLI_ARGS environment variable
- Check multiple services aren't loaded simultaneously

### Services not starting
- Check Docker GPU access: `docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi`
- Verify `/mnt/models` directory exists and is owned by correct user
- Check logs: `docker compose logs [service-name]`
- Ensure NVIDIA Container Toolkit is installed

### Models not appearing in ComfyUI
- Verify model files are in `/mnt/models/stable-diffusion/checkpoints/`
- Check file permissions: `ls -la /mnt/models/stable-diffusion/checkpoints/`
- Restart ComfyUI: `docker compose restart comfyui`
- Look for mount errors in logs: `docker compose logs comfyui`

### Slow inference
- Check GPU utilization should be near 100%: `nvidia-smi`
- Verify model is loaded on GPU not CPU (check service logs)
- Try smaller models or faster samplers
- Check CPU isn't bottlenecking (6-8 cores recommended)
