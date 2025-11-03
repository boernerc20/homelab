#!/bin/bash
set -e

# AI Workstation Setup Script
# This script automates the initial setup of your AI workstation

echo "=================================="
echo "AI Workstation Setup Script"
echo "=================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run as root${NC}"
    exit 1
fi

echo -e "${GREEN}Step 1: Checking system...${NC}"

# Check Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "OS: $NAME $VERSION"
else
    echo -e "${RED}Cannot detect OS version${NC}"
    exit 1
fi

# Check for NVIDIA GPU
if ! command -v nvidia-smi &> /dev/null; then
    echo -e "${YELLOW}Warning: nvidia-smi not found. NVIDIA drivers may not be installed.${NC}"
    read -p "Do you want to install NVIDIA drivers? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Installing NVIDIA drivers..."
        sudo ubuntu-drivers autoinstall
        echo -e "${YELLOW}Please reboot and run this script again.${NC}"
        exit 0
    fi
else
    echo -e "${GREEN}✓ NVIDIA drivers detected${NC}"
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
fi

echo ""
echo -e "${GREEN}Step 2: Installing Docker...${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    rm /tmp/get-docker.sh

    # Add user to docker group
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✓ Docker installed${NC}"
else
    echo -e "${GREEN}✓ Docker already installed${NC}"
fi

# Check if user is in docker group
if ! groups $USER | grep -q docker; then
    echo "Adding user to docker group..."
    sudo usermod -aG docker $USER
    echo -e "${YELLOW}Please log out and log back in for docker group changes to take effect${NC}"
fi

echo ""
echo -e "${GREEN}Step 3: Installing NVIDIA Container Toolkit...${NC}"

# Install NVIDIA Container Toolkit
if ! dpkg -l | grep -q nvidia-container-toolkit; then
    echo "Installing NVIDIA Container Toolkit..."

    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | \
      sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
      sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    sudo apt-get update
    sudo apt-get install -y nvidia-container-toolkit
    sudo systemctl restart docker

    echo -e "${GREEN}✓ NVIDIA Container Toolkit installed${NC}"
else
    echo -e "${GREEN}✓ NVIDIA Container Toolkit already installed${NC}"
fi

echo ""
echo -e "${GREEN}Step 4: Creating directories...${NC}"

# Create model directories
sudo mkdir -p /mnt/models/{llm/{ollama,gguf,transformers},stable-diffusion/{checkpoints,vae,loras,embeddings,controlnet,upscale_models},video/{svd,animatediff}}
sudo chown -R $USER:$USER /mnt/models
echo -e "${GREEN}✓ Model directories created at /mnt/models${NC}"

# Create data directories
mkdir -p data/{ollama,open-webui,comfyui/{input,output,custom_nodes,user},text-gen-webui/{models,presets,characters,loras},piper}
echo -e "${GREEN}✓ Data directories created${NC}"

# Create config directories
mkdir -p config/{searxng,nginx}
echo -e "${GREEN}✓ Config directories created${NC}"

echo ""
echo -e "${GREEN}Step 5: Configuring environment...${NC}"

# Copy .env.example if .env doesn't exist
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✓ Created .env file from template${NC}"
        echo -e "${YELLOW}Please edit .env file with your settings${NC}"
    else
        echo -e "${YELLOW}Warning: .env.example not found${NC}"
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

echo ""
echo -e "${GREEN}Step 6: Testing Docker GPU access...${NC}"

if docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✓ Docker can access GPU${NC}"
else
    echo -e "${RED}✗ Docker cannot access GPU${NC}"
    echo "You may need to:"
    echo "  1. Reboot the system"
    echo "  2. Log out and back in"
    echo "  3. Check NVIDIA driver installation"
    exit 1
fi

echo ""
echo -e "${GREEN}Step 7: Installing additional tools...${NC}"

sudo apt-get update
sudo apt-get install -y htop curl wget git jq

echo -e "${GREEN}✓ Additional tools installed${NC}"

echo ""
echo "=================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=================================="
echo ""
echo "Next steps:"
echo "  1. Review and edit .env file if needed:"
echo "     nano .env"
echo ""
echo "  2. Start services:"
echo "     docker compose up -d"
echo ""
echo "  3. Download models:"
echo "     ./scripts/download-models.sh"
echo ""
echo "  4. Access services:"
echo "     - Open-WebUI: http://localhost:3000"
echo "     - ComfyUI: http://localhost:8188"
echo "     - SearXNG: http://localhost:8080"
echo ""
echo "For detailed instructions, see:"
echo "  - README.md"
echo "  - QUICK_START.md"
echo ""

# Ask if user wants to start services now
read -p "Do you want to start services now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting services..."
    docker compose up -d
    echo ""
    echo -e "${GREEN}Services started!${NC}"
    echo "View logs with: docker compose logs -f"
fi
