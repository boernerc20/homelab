# Quick Start Guide

Get your AI workstation running in under 30 minutes!

## Prerequisites

- Ubuntu 22.04/24.04 installed
- NVIDIA GPU installed
- Internet connection
- At least 100GB free storage

## Step-by-Step Setup

### 1. Install NVIDIA Drivers (5 minutes)

```bash
sudo ubuntu-drivers autoinstall
sudo reboot
```

After reboot, verify:
```bash
nvidia-smi
```

You should see your GPU listed.

### 2. Install Docker (5 minutes)

```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Configure user
sudo usermod -aG docker $USER
newgrp docker

# Install NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update
sudo apt install -y nvidia-container-toolkit
sudo systemctl restart docker

# Test GPU access
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

### 3. Prepare Environment (2 minutes)

```bash
# Navigate to project directory
cd /home/chris/projects/homelab/localAI

# Create model directories
sudo mkdir -p /mnt/models/{llm/ollama,stable-diffusion/{checkpoints,vae,upscale_models},video}
sudo chown -R $USER:$USER /mnt/models

# Copy environment file
cp .env.example .env

# Edit if needed (optional for now)
nano .env
```

### 4. Start Services (2 minutes)

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs (Ctrl+C to exit)
docker compose logs -f
```

All services are now starting up!

### 5. Download Your First Models (10 minutes)

**Language Model:**
```bash
# Pull Llama 3.1 8B (recommended first model)
docker exec -it ollama ollama pull llama3.1:8b

# Or Mistral 7B (faster)
docker exec -it ollama ollama pull mistral:7b
```

**Image Generation Model:**
```bash
cd /mnt/models/stable-diffusion/checkpoints

# Download SD 1.5 (fastest to get started)
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors

# Or SDXL (better quality, slower)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
```

### 6. Test Everything (5 minutes)

**Test LLM (Ollama):**
```bash
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Why is the sky blue?",
  "stream": false
}'
```

**Open Web Interface:**
```bash
# Open in browser:
# http://localhost:3000 - Chat interface (Open-WebUI)
# http://localhost:8188 - Image generation (ComfyUI)
```

### 7. First Generation Tests

**Chat with AI:**
1. Open http://localhost:3000
2. Create account (local only, no internet needed)
3. Select "llama3.1:8b" from model dropdown
4. Start chatting!

**Generate Image:**
1. Open http://localhost:8188
2. Load default workflow (or create new)
3. Enter prompt: "a beautiful mountain landscape"
4. Click "Queue Prompt"
5. Wait for generation (check output folder)

## You're Done!

Your AI workstation is now running. Here's what you have:

✅ Local LLM chat interface
✅ Image generation with ComfyUI
✅ Privacy-focused web search (optional to enable)
✅ Speech-to-text ready (Whisper)
✅ Text-to-speech ready (Piper)

## What's Next?

### Immediate Next Steps

1. **Download more models** (see MODEL_RECOMMENDATIONS.md)
2. **Configure Home Assistant** (see HOME_ASSISTANT_INTEGRATION.md)
3. **Learn ComfyUI workflows** (see COMFYUI_SETUP.md)
4. **Optimize performance** (see SOFTWARE_STACK.md)

### Try These Tasks

**Language Tasks:**
```bash
# Code generation
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Write a Python function to calculate fibonacci numbers",
  "stream": false
}'

# Creative writing
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.1:8b",
  "prompt": "Write a short sci-fi story about AI",
  "stream": false
}'
```

**Image Generation Tasks:**
- Portrait photography
- Landscape art
- Character design
- Product visualization

### Common First-Time Issues

**"Cannot connect to Docker daemon"**
```bash
sudo systemctl start docker
sudo usermod -aG docker $USER
# Log out and back in
```

**"Out of memory" during image generation**
- Use SD 1.5 instead of SDXL
- Lower resolution (512x512)
- Close other applications

**Slow text generation**
- Use smaller model (mistral:7b)
- Check GPU usage: `nvidia-smi`
- Ensure model running on GPU, not CPU

**Can't access web interface**
```bash
# Check services running
docker compose ps

# Restart services
docker compose restart

# Check firewall
sudo ufw status
```

## Quick Command Reference

### Docker Commands
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a service
docker compose restart [service-name]

# View logs
docker compose logs -f [service-name]

# Check status
docker compose ps

# Update images
docker compose pull
docker compose up -d
```

### Ollama Commands
```bash
# List installed models
docker exec ollama ollama list

# Pull new model
docker exec ollama ollama pull [model-name]

# Remove model
docker exec ollama ollama rm [model-name]

# Run model interactively
docker exec -it ollama ollama run llama3.1:8b
```

### System Monitoring
```bash
# GPU usage
watch -n 1 nvidia-smi

# Disk usage
df -h

# Docker stats
docker stats

# System resources
htop
```

## Service URLs Reference

| Service        | URL                      | Purpose                |
|----------------|--------------------------|------------------------|
| Open-WebUI     | http://localhost:3000    | Chat with AI           |
| ComfyUI        | http://localhost:8188    | Generate images        |
| SearXNG        | http://localhost:8080    | Web search             |
| Ollama API     | http://localhost:11434   | LLM API access         |

## Getting Help

1. **Check logs first:**
   ```bash
   docker compose logs [service-name]
   ```

2. **Verify GPU access:**
   ```bash
   nvidia-smi
   docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
   ```

3. **Restart problematic service:**
   ```bash
   docker compose restart [service-name]
   ```

4. **Full restart:**
   ```bash
   docker compose down
   docker compose up -d
   ```

5. **Check documentation:**
   - README.md
   - SOFTWARE_STACK.md
   - Specific service documentation

## 30-Minute Challenge

Can you do all of this in 30 minutes?

- [ ] Install drivers (5 min)
- [ ] Install Docker (5 min)
- [ ] Start services (2 min)
- [ ] Download Llama 3.1 8B (5 min)
- [ ] Download SD 1.5 (3 min)
- [ ] Generate first chat response (2 min)
- [ ] Generate first image (5 min)
- [ ] Celebrate! (3 min)

**Total: 30 minutes to fully operational AI workstation!**

## Pro Tips

1. **Start small:** Use 7B LLMs and SD 1.5 first
2. **Monitor resources:** Keep an eye on GPU memory
3. **Download while configuring:** Models download in background
4. **Save workflows:** In ComfyUI, save your workflows as you build
5. **Use quantized models:** Q4/Q5 for best performance/quality balance
6. **Check community:** CivitAI, Ollama library for more models
7. **Automate backups:** Set up backup script early
8. **Document settings:** Note what works well for your hardware

## Benchmarking Your System

Test your system performance:

**LLM Speed Test:**
```bash
time docker exec ollama ollama run llama3.1:8b "Write a short paragraph about AI"
```

**Image Generation Speed Test:**
1. Open ComfyUI (http://localhost:8188)
2. Load default SD 1.5 workflow
3. Generate 512x512 image with 20 steps
4. Note time taken

**Expected Performance:**
- **RTX 3060 12GB:** 25-40 tokens/sec, 2-3 sec/image
- **RTX 4070 12GB:** 40-60 tokens/sec, 1-2 sec/image
- **RTX 4090 24GB:** 80-120 tokens/sec, 0.5-1 sec/image

## Next Learning Paths

**Path 1: LLM Mastery**
1. Try different models (Mistral, CodeLlama)
2. Learn about quantization
3. Set up RAG (Retrieval Augmented Generation)
4. Create custom prompts and personas

**Path 2: Image Generation**
1. Learn ComfyUI workflows
2. Download LoRAs and fine-tunes
3. Experiment with ControlNet
4. Try video generation

**Path 3: Home Automation**
1. Install Home Assistant
2. Set up voice assistant
3. Create custom intents
4. Automate your home with AI

**Path 4: Development**
1. Use API integrations
2. Build custom applications
3. Fine-tune models for your use case
4. Create workflows and automations

## Congratulations!

You now have a powerful local AI workstation. No cloud dependencies, complete privacy, unlimited usage!

**Happy generating! 🚀**
