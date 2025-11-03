#!/bin/bash
set -e

# Model Download Script
# Downloads essential AI models for your workstation

echo "=================================="
echo "AI Model Download Script"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

MODEL_DIR="/mnt/models"

# Check if model directory exists
if [ ! -d "$MODEL_DIR" ]; then
    echo -e "${YELLOW}Model directory not found. Creating...${NC}"
    sudo mkdir -p $MODEL_DIR/{llm/ollama,stable-diffusion/{checkpoints,vae,loras,controlnet,upscale_models},video/svd}
    sudo chown -R $USER:$USER $MODEL_DIR
fi

echo "Select models to download:"
echo ""
echo "Language Models (via Ollama):"
echo "  1) Llama 3.1 8B (recommended, ~4.7GB)"
echo "  2) Mistral 7B (fast, ~4.1GB)"
echo "  3) CodeLlama 7B (coding, ~3.8GB)"
echo "  4) Llama 3.1 13B (better quality, ~7.3GB)"
echo "  5) Phi-3 Mini (fastest, ~2.3GB)"
echo "  6) All of the above"
echo ""
echo "Image Generation Models:"
echo "  7) Stable Diffusion 1.5 (fast, ~4GB)"
echo "  8) Stable Diffusion XL Base (quality, ~6.5GB)"
echo "  9) SDXL Turbo (speed, ~6.5GB)"
echo "  10) All image models"
echo ""
echo "Support Models:"
echo "  11) VAE models (~300MB)"
echo "  12) Upscaler models (~64MB)"
echo "  13) All support models"
echo ""
echo "  14) Download everything (recommended for first setup)"
echo "  0) Exit"
echo ""

read -p "Enter your choice (0-14): " choice

download_llm() {
    echo -e "${BLUE}Downloading LLM: $1${NC}"
    docker exec ollama ollama pull $1
    echo -e "${GREEN}✓ Downloaded $1${NC}"
}

download_image_model() {
    local url=$1
    local filename=$2
    local dest=$3

    echo -e "${BLUE}Downloading: $filename${NC}"
    if [ -f "$dest/$filename" ]; then
        echo -e "${YELLOW}File already exists, skipping${NC}"
        return
    fi

    wget -c -q --show-progress "$url" -O "$dest/$filename"
    echo -e "${GREEN}✓ Downloaded $filename${NC}"
}

case $choice in
    1)
        download_llm "llama3.1:8b"
        ;;
    2)
        download_llm "mistral:7b"
        ;;
    3)
        download_llm "codellama:7b"
        ;;
    4)
        download_llm "llama3.1:13b"
        ;;
    5)
        download_llm "phi3:mini"
        ;;
    6)
        echo "Downloading all LLMs..."
        download_llm "llama3.1:8b"
        download_llm "mistral:7b"
        download_llm "codellama:7b"
        download_llm "llama3.1:13b"
        download_llm "phi3:mini"
        ;;
    7)
        cd $MODEL_DIR/stable-diffusion/checkpoints
        download_image_model \
            "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" \
            "v1-5-pruned-emaonly.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"
        ;;
    8)
        cd $MODEL_DIR/stable-diffusion/checkpoints
        download_image_model \
            "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" \
            "sd_xl_base_1.0.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"
        ;;
    9)
        cd $MODEL_DIR/stable-diffusion/checkpoints
        download_image_model \
            "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors" \
            "sd_xl_turbo_1.0_fp16.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"
        ;;
    10)
        echo "Downloading all image models..."
        cd $MODEL_DIR/stable-diffusion/checkpoints
        download_image_model \
            "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" \
            "v1-5-pruned-emaonly.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"
        download_image_model \
            "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" \
            "sd_xl_base_1.0.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"
        download_image_model \
            "https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors" \
            "sd_xl_turbo_1.0_fp16.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"
        ;;
    11)
        echo "Downloading VAE models..."
        cd $MODEL_DIR/stable-diffusion/vae
        download_image_model \
            "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors" \
            "vae-ft-mse-840000-ema-pruned.safetensors" \
            "$MODEL_DIR/stable-diffusion/vae"
        download_image_model \
            "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors" \
            "sdxl_vae.safetensors" \
            "$MODEL_DIR/stable-diffusion/vae"
        ;;
    12)
        echo "Downloading upscaler models..."
        cd $MODEL_DIR/stable-diffusion/upscale_models
        download_image_model \
            "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" \
            "RealESRGAN_x4plus.pth" \
            "$MODEL_DIR/stable-diffusion/upscale_models"
        download_image_model \
            "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x4plus_anime_6B.pth" \
            "RealESRGAN_x4plus_anime_6B.pth" \
            "$MODEL_DIR/stable-diffusion/upscale_models"
        ;;
    13)
        echo "Downloading all support models..."
        cd $MODEL_DIR/stable-diffusion/vae
        download_image_model \
            "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors" \
            "vae-ft-mse-840000-ema-pruned.safetensors" \
            "$MODEL_DIR/stable-diffusion/vae"
        download_image_model \
            "https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors" \
            "sdxl_vae.safetensors" \
            "$MODEL_DIR/stable-diffusion/vae"
        cd $MODEL_DIR/stable-diffusion/upscale_models
        download_image_model \
            "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" \
            "RealESRGAN_x4plus.pth" \
            "$MODEL_DIR/stable-diffusion/upscale_models"
        ;;
    14)
        echo "Downloading everything..."
        echo ""
        echo "This will download approximately 30GB of models."
        read -p "Continue? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi

        echo "Downloading LLMs..."
        download_llm "llama3.1:8b"
        download_llm "mistral:7b"
        download_llm "codellama:7b"

        echo ""
        echo "Downloading image models..."
        cd $MODEL_DIR/stable-diffusion/checkpoints
        download_image_model \
            "https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors" \
            "v1-5-pruned-emaonly.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"
        download_image_model \
            "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors" \
            "sd_xl_base_1.0.safetensors" \
            "$MODEL_DIR/stable-diffusion/checkpoints"

        echo ""
        echo "Downloading support models..."
        cd $MODEL_DIR/stable-diffusion/vae
        download_image_model \
            "https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors" \
            "vae-ft-mse-840000-ema-pruned.safetensors" \
            "$MODEL_DIR/stable-diffusion/vae"
        cd $MODEL_DIR/stable-diffusion/upscale_models
        download_image_model \
            "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth" \
            "RealESRGAN_x4plus.pth" \
            "$MODEL_DIR/stable-diffusion/upscale_models"
        ;;
    0)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "=================================="
echo -e "${GREEN}Download Complete!${NC}"
echo "=================================="
echo ""
echo "Downloaded models are stored in: $MODEL_DIR"
echo ""
echo "To view available Ollama models:"
echo "  docker exec ollama ollama list"
echo ""
echo "To view image models:"
echo "  ls -lh $MODEL_DIR/stable-diffusion/checkpoints/"
echo ""
echo "For more models, visit:"
echo "  - Ollama Library: https://ollama.com/library"
echo "  - CivitAI: https://civitai.com/"
echo "  - HuggingFace: https://huggingface.co/models"
echo ""
