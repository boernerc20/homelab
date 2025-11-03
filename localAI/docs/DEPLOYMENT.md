# Deployment Guide - Ubuntu Server 24.04 Headless

## Overview

This guide covers deploying the AI workstation as a **headless Ubuntu Server** accessible via SSH and network services. After initial setup, you'll never need a monitor/keyboard again - everything is managed remotely.

### Deployment Architecture

```
┌──────────────────────────────────────────────────┐
│ Main Desktop (192.168.1.50)                      │
│ - SSH to AI workstation for management          │
│ - Browser to ComfyUI/Open-WebUI                 │
│ - OLLAMA_HOST points to remote server           │
│ - VS Code Remote SSH for editing                │
└─────────────┬────────────────────────────────────┘
              │ SSH (22)
              │ HTTP (3000, 8188, 11434)
              │
┌─────────────▼────────────────────────────────────┐
│ AI Workstation (192.168.1.100)                   │
│ Ubuntu Server 24.04 LTS - HEADLESS              │
│                                                   │
│ Docker Services:                                  │
│ ├─ Ollama (11434)                                │
│ ├─ Open-WebUI (3000)                             │
│ ├─ ComfyUI (8188)                                │
│ ├─ Whisper (9000)                                │
│ ├─ Piper (10200)                                 │
│ └─ SearXNG (8080)                                │
│                                                   │
│ Storage:                                          │
│ ├─ / (1TB NVMe) - OS & Docker                   │
│ └─ /mnt/models (2TB SSD) - AI models            │
└───────────────────────────────────────────────────┘
              │ Wyoming Protocol (9000, 10200)
              │ REST API (11434)
              │
┌─────────────▼────────────────────────────────────┐
│ Home Assistant (192.168.1.75)                    │
│ - Voice assistant (Whisper + Piper)             │
│ - LLM conversation (Ollama)                      │
└──────────────────────────────────────────────────┘
```

---

## Phase 1: Ubuntu Server Installation

### Download Ubuntu Server
- **Download**: [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/server)
- **Create bootable USB**: Use Rufus (Windows), balenaEtcher (Mac/Linux), or `dd`

### BIOS Setup
1. Boot into BIOS/UEFI (usually DEL, F2, or F12 during startup)
2. Set boot order: USB first
3. Enable UEFI mode (not legacy BIOS)
4. **Disable Secure Boot** (NVIDIA drivers may require this)
5. Save and exit

### Installation Process

**1. Boot from USB**
- Select "Install Ubuntu Server"

**2. Language & Keyboard**
- English (or your preference)

**3. Network Configuration**
- **Static IP recommended** for stable SSH access
- Example configuration:
  ```
  IP address: 192.168.1.100/24
  Gateway: 192.168.1.1
  DNS: 192.168.1.1 (or 1.1.1.1, 8.8.8.8)
  ```
- Alternatively: Use DHCP now, configure static later

**4. Proxy & Mirror**
- Skip proxy (unless you need it)
- Use default Ubuntu mirror

**5. Storage Configuration**
- **Guided - use entire disk** (simplest)
- Select 1TB NVMe drive for OS
- Confirm partition scheme:
  - `/boot/efi` (512MB)
  - `/` (remaining space, ext4)
  - Swap file: 8GB (or same as RAM if you plan hibernation)

**6. Profile Setup**
- Name: Your name
- Server name: `ai-workstation` (or `ai-server`, `homelab-ai`)
- Username: `chris` (or your preference)
- Password: Strong password (you'll use SSH keys later)

**7. SSH Setup**
- **Install OpenSSH server** ✅ (IMPORTANT)
- Do NOT import SSH identity yet (we'll do this properly later)

**8. Featured Server Snaps**
- **Skip all** (we'll install Docker manually)

**9. Installation**
- Wait 10-15 minutes for installation
- **Reboot** when prompted
- Remove USB drive

**10. First Boot**
- Server will boot to command line login prompt
- Login with username/password you created

---

## Phase 2: Initial Configuration (At the Server)

### Update System
```bash
# Update package lists and upgrade
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y curl wget git nano htop net-tools
```

### Configure Static IP (if not done during install)
```bash
# Find your network interface name
ip a

# Edit netplan configuration
sudo nano /etc/netplan/01-netcfg.yaml
```

**Example static IP configuration:**
```yaml
network:
  version: 2
  ethernets:
    eno1:  # Replace with your interface name (e.g., enp3s0, ens160)
      dhcp4: no
      addresses:
        - 192.168.1.100/24
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses:
          - 192.168.1.1
          - 1.1.1.1
```

```bash
# Apply network configuration
sudo netplan apply

# Verify
ip a
ping -c 4 google.com
```

### Enable SSH (should already be running)
```bash
# Check SSH status
sudo systemctl status ssh

# If not running:
sudo systemctl enable ssh
sudo systemctl start ssh
```

### Set Hostname (if needed)
```bash
# Check current hostname
hostnamectl

# Change if needed
sudo hostnamectl set-hostname ai-workstation
```

### Find Your IP Address
```bash
# Note this IP for SSH access from main desktop
ip a | grep inet
```

**At this point, disconnect the monitor and keyboard. You won't need them again.**

---

## Phase 3: SSH Access from Main Desktop

### From Your Main Desktop

**Linux/Mac:**
```bash
# Test connection
ssh chris@192.168.1.100

# You'll be prompted to accept host key (type "yes")
# Enter your password
```

**Windows:**
- Use **Windows Terminal** (built-in SSH client)
- Or **PuTTY** for GUI
- Or **VS Code Remote SSH extension** (best option)

### Set Up SSH Key Authentication (No More Passwords!)

**On your main desktop, generate SSH key:**
```bash
# Generate ED25519 key (modern, secure)
ssh-keygen -t ed25519 -C "your-email@example.com"

# Press Enter to accept default location (~/.ssh/id_ed25519)
# Optionally set a passphrase (or leave empty for convenience)
```

**Copy public key to AI workstation:**
```bash
# Copy your public key to the server
ssh-copy-id chris@192.168.1.100

# Enter your password one last time
```

**Test passwordless login:**
```bash
# This should now work without password
ssh chris@192.168.1.100

# Success! You're in without typing a password
```

### SSH Connection Shortcuts

**Edit SSH config on main desktop:**
```bash
nano ~/.ssh/config
```

**Add this configuration:**
```
Host ai-workstation
  HostName 192.168.1.100
  User chris
  ForwardAgent yes
  ServerAliveInterval 60
```

**Now you can connect with:**
```bash
ssh ai-workstation
# Much easier than typing IP every time!
```

---

## Phase 4: Install NVIDIA Drivers & Docker

### Install NVIDIA Drivers

```bash
# SSH into server
ssh ai-workstation

# Update system
sudo apt update

# Check available NVIDIA drivers
ubuntu-drivers devices

# Install recommended driver (usually 535+ for RTX 3090)
sudo ubuntu-drivers autoinstall

# Reboot
sudo reboot

# Wait 1 minute, then SSH back in
ssh ai-workstation

# Verify NVIDIA driver
nvidia-smi
```

**Expected output:**
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.xx.xx              Driver Version: 535.xx.xx      CUDA Version: 12.2     |
|----------------------------------------------+-------------------------+-----------------|
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|===============================================+=========================+==================|
|   0  NVIDIA GeForce RTX 3090        Off | 00000000:01:00.0 Off |                  N/A |
| 30%   35C    P8              25W / 350W |      1MiB / 24576MiB |      0%      Default |
+-----------------------------------------------------------------------------------------+
```

### Install Docker & Docker Compose

```bash
# Install Docker using official script
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group (no more sudo)
sudo usermod -aG docker $USER

# Apply group change (or logout/login)
newgrp docker

# Install Docker Compose plugin
sudo apt install -y docker-compose-plugin

# Verify installations
docker --version
docker compose version
```

### Install NVIDIA Container Toolkit

```bash
# Add NVIDIA Container Toolkit repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# Install
sudo apt update
sudo apt install -y nvidia-container-toolkit

# Configure Docker to use NVIDIA runtime
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test GPU access in Docker
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

**If you see nvidia-smi output, GPU passthrough is working!**

---

## Phase 5: Clone Repository & Prepare Storage

### Clone This Repository

```bash
# Create projects directory
mkdir -p ~/projects/homelab

# Clone repository
cd ~/projects/homelab
git clone <your-repo-url> localAI
cd localAI
```

### Create Model Storage Directories

```bash
# Create /mnt/models directory structure
sudo mkdir -p /mnt/models/llm/ollama
sudo mkdir -p /mnt/models/stable-diffusion/{checkpoints,vae,loras,controlnet,embeddings,upscale_models}
sudo mkdir -p /mnt/models/video/{svd,animatediff}

# Set ownership to your user
sudo chown -R $USER:$USER /mnt/models

# Verify
ls -la /mnt/models
```

### Create Data Directories (Docker volumes)

```bash
# Docker Compose will auto-create these, but we can create manually
mkdir -p ~/projects/homelab/localAI/data
```

### Configure Environment Variables

```bash
# Copy example environment file
cd ~/projects/homelab/localAI
cp .env.example .env

# Edit configuration
nano .env
```

**Important values to change:**
```bash
# Change this secret!
WEBUI_SECRET_KEY=your-random-secret-key-here

# Set your timezone
TZ=America/New_York

# Set model paths (should already be correct)
OLLAMA_MODELS=/mnt/models/llm/ollama
COMFYUI_MODELS=/mnt/models/stable-diffusion
```

---

## Phase 6: Start Services

### First Run Setup Script (Optional)
```bash
# Review what the script does
cat scripts/setup.sh

# Run setup script (installs everything we did above)
# Skip if you already did Phase 4 manually
./scripts/setup.sh
```

### Start Docker Stack

```bash
cd ~/projects/homelab/localAI

# Pull images (takes 10-20 minutes depending on connection)
docker compose pull

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

**Expected output:**
```
NAME                      IMAGE                              STATUS              PORTS
ollama                    ollama/ollama:latest               Up 2 minutes        0.0.0.0:11434->11434/tcp
open-webui                ghcr.io/open-webui/open-webui      Up 2 minutes        0.0.0.0:3000->8080/tcp
comfyui                   yanwk/comfyui-boot:latest          Up 2 minutes        0.0.0.0:8188->8188/tcp
whisper                   rhasspy/wyoming-whisper:latest     Up 2 minutes        0.0.0.0:9000->10300/tcp
piper                     rhasspy/wyoming-piper:latest       Up 2 minutes        0.0.0.0:10200->10200/tcp
searxng                   searxng/searxng:latest             Up 2 minutes        0.0.0.0:8080->8080/tcp
```

### Verify Services Are Running

**Check Ollama API:**
```bash
curl http://localhost:11434/api/tags
```

**Check ComfyUI:**
```bash
curl http://localhost:8188
```

**Check GPU usage:**
```bash
watch -n 1 nvidia-smi
```

---

## Phase 7: Access from Main Desktop

### Configure Main Desktop

**On your main desktop, edit hosts file (optional but convenient):**

**Linux/Mac:**
```bash
sudo nano /etc/hosts
```

**Windows:**
```
notepad C:\Windows\System32\drivers\etc\hosts (as Administrator)
```

**Add this line:**
```
192.168.1.100    ai-workstation ai-workstation.local
```

### Access Services in Browser

Open on your main desktop:
- **ComfyUI**: http://ai-workstation:8188
- **Open-WebUI**: http://ai-workstation:3000
- **SearXNG**: http://ai-workstation:8080

### Configure Ollama Client

**On your main desktop shell config (Linux/Mac):**
```bash
# Edit ~/.bashrc or ~/.zshrc
nano ~/.bashrc
```

**Add this line:**
```bash
export OLLAMA_HOST=http://ai-workstation:11434
```

```bash
# Reload config
source ~/.bashrc

# Now Ollama commands use remote server
ollama list
ollama pull llama3.1:8b
ollama run llama3.1:8b
```

**Windows PowerShell:**
```powershell
$env:OLLAMA_HOST="http://ai-workstation:11434"
ollama list
```

### VS Code Remote Development

1. Install **Remote - SSH** extension in VS Code
2. Click green icon in bottom-left corner
3. Select "Connect to Host"
4. Choose "ai-workstation" (from your SSH config)
5. Open folder: `/home/chris/projects/homelab/localAI`
6. Edit files directly on remote machine
7. Terminal in VS Code is on AI workstation

---

## Phase 8: GPU Optimization

### Set Power Limit (Quieter Operation)

```bash
ssh ai-workstation

# Reduce power limit from 350W to 300W
sudo nvidia-smi -pl 300

# Enable persistence mode
sudo nvidia-smi -pm 1
```

### Make Power Limit Persistent

**Create systemd service:**
```bash
sudo nano /etc/systemd/system/nvidia-power-limit.service
```

**Paste this:**
```ini
[Unit]
Description=Set NVIDIA GPU Power Limit
After=nvidia-persistenced.service

[Service]
Type=oneshot
ExecStart=/usr/bin/nvidia-smi -pl 300
ExecStart=/usr/bin/nvidia-smi -pm 1
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

```bash
# Enable service
sudo systemctl enable nvidia-power-limit.service
sudo systemctl start nvidia-power-limit.service

# Verify
nvidia-smi
```

---

## Phase 9: Firewall & Security

### Configure UFW Firewall

```bash
# Enable UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH from your local network only
sudo ufw allow from 192.168.1.0/24 to any port 22

# Allow services from local network
sudo ufw allow from 192.168.1.0/24 to any port 11434  # Ollama
sudo ufw allow from 192.168.1.0/24 to any port 3000   # Open-WebUI
sudo ufw allow from 192.168.1.0/24 to any port 8188   # ComfyUI
sudo ufw allow from 192.168.1.0/24 to any port 9000   # Whisper
sudo ufw allow from 192.168.1.0/24 to any port 10200  # Piper
sudo ufw allow from 192.168.1.0/24 to any port 8080   # SearXNG

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status numbered
```

### Disable Root Login (Security Best Practice)

```bash
sudo nano /etc/ssh/sshd_config
```

**Find and change:**
```
PermitRootLogin no
PasswordAuthentication no  # Force SSH key auth only
```

```bash
# Restart SSH
sudo systemctl restart ssh
```

---

## Phase 10: Monitoring & Maintenance

### Daily Monitoring Commands

```bash
# SSH into server
ssh ai-workstation

# Check Docker services
docker compose ps

# View logs
docker compose logs -f ollama

# Monitor GPU
nvidia-smi

# System resources
htop

# Disk usage
df -h
du -sh /mnt/models/*
```

### Use Built-in Monitor Script

```bash
# One-time view
./scripts/monitor.sh

# Auto-refresh every 10 seconds
./scripts/monitor.sh --watch
```

### Set Up Log Monitoring

**Install log viewer:**
```bash
sudo apt install -y lnav

# View Docker logs with lnav
docker compose logs | lnav
```

---

## Phase 11: Optional - Remote Access (Outside Home)

### Option 1: Tailscale (Recommended)

**On AI workstation:**
```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

**On main desktop, laptop, phone:**
- Install Tailscale
- Login with same account
- Access AI workstation via Tailscale IP: http://100.x.x.x:8188

**Benefits:**
- Encrypted VPN mesh
- Works behind CGNAT
- No port forwarding
- Free for personal use

### Option 2: WireGuard VPN

**More control but complex setup:**
- Install WireGuard on server
- Configure peers for each device
- Port forward UDP 51820 on router

### Option 3: Cloudflare Tunnel

**For HTTP services only:**
- No port forwarding needed
- Free tier available
- Adds external dependency

---

## Deployment Checklist

### Initial Setup (One-Time)
- [ ] Install Ubuntu Server 24.04
- [ ] Configure static IP
- [ ] Enable SSH
- [ ] Set up SSH key auth from main desktop
- [ ] Install NVIDIA drivers
- [ ] Install Docker + Docker Compose
- [ ] Install NVIDIA Container Toolkit
- [ ] Clone this repository
- [ ] Create `/mnt/models` directory structure
- [ ] Configure `.env` file
- [ ] Start Docker services

### Optimization (One-Time)
- [ ] Set GPU power limit (300W)
- [ ] Enable NVIDIA persistence mode
- [ ] Configure UFW firewall
- [ ] Disable root SSH login
- [ ] Add ai-workstation to `/etc/hosts` on main desktop
- [ ] Set `OLLAMA_HOST` on main desktop
- [ ] Install VS Code Remote SSH extension

### Optional Enhancements
- [ ] Set up Tailscale for remote access
- [ ] Configure automatic backups
- [ ] Set up monitoring alerts
- [ ] Mount NAS for model storage
- [ ] Configure fan curves in BIOS

---

## Daily Usage Workflow

**From your main desktop:**

1. **Check server status:**
   ```bash
   ssh ai-workstation "docker compose ps"
   ```

2. **Use ComfyUI:**
   - Open browser: http://ai-workstation:8188
   - Load workflow, queue generations
   - Download results

3. **Use Ollama:**
   ```bash
   ollama run llama3.1:8b "Write a Python function to sort a list"
   ```

4. **Check GPU usage:**
   ```bash
   ssh ai-workstation "nvidia-smi"
   ```

5. **View logs:**
   ```bash
   ssh ai-workstation "docker compose logs --tail 50 ollama"
   ```

6. **Restart a service:**
   ```bash
   ssh ai-workstation "docker compose restart comfyui"
   ```

**You never need to physically access the server.**

---

## Troubleshooting

### Service Won't Start
```bash
# Check logs
docker compose logs [service-name]

# Verify GPU access
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi

# Check disk space
df -h
```

### Can't SSH In
- Verify IP: `ip a` (at the physical machine)
- Check SSH service: `sudo systemctl status ssh`
- Firewall: `sudo ufw status`
- Try from server's console: `ssh localhost`

### GPU Not Detected in Docker
```bash
# Restart Docker daemon
sudo systemctl restart docker

# Check NVIDIA Container Toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

### Services Accessible Locally But Not From Main Desktop
- Check firewall: `sudo ufw status`
- Verify services bind to 0.0.0.0: `docker compose ps`
- Test with curl from server: `curl localhost:11434/api/tags`

---

## Next Steps

1. **Download models**: See `scripts/download-models.sh` or docs/MODELS.md
2. **Home Assistant integration**: See docs/HOME_ASSISTANT.md
3. **ComfyUI workflows**: See docs/COMFYUI.md
4. **Backup configuration**: See `scripts/backup.sh`

Your AI workstation is now ready for 24/7 operation!
