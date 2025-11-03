# ComfyUI Setup & Configuration Guide

## Overview

ComfyUI is a powerful and modular interface for Stable Diffusion and other AI image/video generation models. It uses a node-based workflow system for maximum flexibility.

## Initial Setup

### Using Docker (Recommended)

The docker-compose.yml includes ComfyUI. Simply run:

```bash
cd /home/chris/projects/homelab/localAI
docker compose up -d comfyui
```

Access at: http://localhost:8188

### Native Installation (Alternative)

```bash
# Clone repository
cd /opt
sudo git clone https://github.com/comfyanonymous/ComfyUI.git
sudo chown -R $USER:$USER ComfyUI
cd ComfyUI

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install PyTorch with CUDA
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install dependencies
pip install -r requirements.txt

# Run
python main.py --listen 0.0.0.0 --port 8188
```

## Directory Structure

```
ComfyUI/
├── models/                    # Model files
│   ├── checkpoints/          # Main SD models (*.safetensors, *.ckpt)
│   ├── vae/                  # VAE models
│   ├── loras/                # LoRA adapters
│   ├── embeddings/           # Textual inversions
│   ├── controlnet/           # ControlNet models
│   ├── clip/                 # CLIP models
│   ├── clip_vision/          # CLIP vision encoders
│   ├── upscale_models/       # Upscaling models
│   └── animatediff_models/   # AnimateDiff checkpoints
├── custom_nodes/              # Extensions and plugins
├── input/                     # Input images
├── output/                    # Generated images/videos
├── user/                      # User workflows and settings
└── temp/                      # Temporary files
```

## Essential Models to Download

### 1. Base Checkpoint Models

#### Stable Diffusion 1.5 (4GB)
```bash
cd /mnt/models/stable-diffusion/checkpoints
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
```

**Use case:** Fast generation, good for experimentation

#### Stable Diffusion XL (6.5GB)
```bash
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors
```

**Use case:** Higher quality images, better prompt understanding

#### SDXL Turbo (6.5GB) - Fast inference
```bash
wget https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors
```

**Use case:** Rapid iteration, 1-4 steps only

#### Flux.1 (23GB) - Latest, best quality
```bash
# Schnell version (faster)
wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors

# Dev version (higher quality)
wget https://huggingface.co/black-forest-labs/FLUX.1-dev/resolve/main/flux1-dev.safetensors
```

**Use case:** Best image quality, prompt adherence

### 2. VAE Models

```bash
cd /mnt/models/stable-diffusion/vae

# SD 1.5 VAE
wget https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors

# SDXL VAE
wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors
```

### 3. ControlNet Models (Optional, ~1.5GB each)

```bash
cd /mnt/models/stable-diffusion/controlnet

# Popular ControlNet models
wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_canny.pth
wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11p_sd15_openpose.pth
wget https://huggingface.co/lllyasviel/ControlNet-v1-1/resolve/main/control_v11f1p_sd15_depth.pth
```

### 4. Upscaler Models

```bash
cd /mnt/models/stable-diffusion/upscale_models

# RealESRGAN (4x upscale)
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x4plus_anime_6B.pth
```

### 5. Video Generation Models

```bash
cd /mnt/models/video

# Stable Video Diffusion (~10GB)
mkdir svd && cd svd
wget https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt.safetensors
```

## Essential Custom Nodes

### ComfyUI Manager (Must-have)

```bash
cd /opt/ComfyUI/custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
```

**Restart ComfyUI**, then use the Manager to install other nodes through the UI.

### Recommended Custom Nodes

Install through ComfyUI Manager UI:

1. **ComfyUI-Impact-Pack** - Advanced processing tools
2. **ComfyUI-AnimateDiff** - Animation support
3. **ComfyUI-VideoHelperSuite** - Video processing
4. **rgthree's ComfyUI Nodes** - Quality of life improvements
5. **Efficiency Nodes** - Faster workflow building
6. **WAS Node Suite** - Image processing utilities
7. **ControlNet Aux** - ControlNet preprocessors
8. **Ultimate SD Upscale** - Tiled upscaling
9. **FizzNodes** - Animation and batch tools
10. **IPAdapter Plus** - Style/character consistency

## Sample Workflows

### Basic Text-to-Image (SD 1.5)

1. Load workflow from ComfyUI interface
2. Or create manually:
   - Load Checkpoint node
   - CLIP Text Encode (Positive prompt)
   - CLIP Text Encode (Negative prompt)
   - KSampler
   - VAE Decode
   - Save Image

### SDXL with Refiner

```
Load SDXL Base → Encode Prompt → KSampler (8 steps) →
Load SDXL Refiner → Encode Prompt → KSampler (2 steps) →
VAE Decode → Save Image
```

### Image-to-Image

```
Load Image → VAE Encode → Load Checkpoint →
Encode Prompt → KSampler (denoise: 0.6) →
VAE Decode → Save Image
```

### ControlNet (Pose/Canny)

```
Load Image → ControlNet Preprocessor →
Load ControlNet Model → Apply ControlNet →
Load Checkpoint → Encode Prompt → KSampler →
VAE Decode → Save Image
```

## Configuration & Optimization

### Command Line Arguments

**For more VRAM (lower performance):**
```bash
python main.py --listen --highvram
```

**For less VRAM (higher performance):**
```bash
python main.py --listen --lowvram
# or
python main.py --listen --normalvram
```

**For CPU offloading (very slow):**
```bash
python main.py --listen --cpu
```

**Disable xformers (if issues):**
```bash
python main.py --listen --disable-xformers
```

### VRAM Management Settings

In ComfyUI interface: Settings → VRAM Management

- **auto** - Recommended for most
- **GPU** - Keep models in VRAM (fast, high VRAM usage)
- **highvram** - Keep models loaded (medium VRAM)
- **normalvram** - Load/unload as needed (balanced)
- **lowvram** - Minimal VRAM usage (slower)

### Performance Tips

1. **Use FP16 models** - Half file size, same quality
2. **Enable xformers** - Faster attention (usually auto-enabled)
3. **Batch processing** - Generate multiple images in one pass
4. **Tiled VAE** - For high-resolution images
5. **Model offloading** - Move models to RAM when not in use

### Recommended Settings by GPU

**RTX 3060 12GB:**
```
--normalvram
Steps: 20-30
CFG: 7-8
Resolution: 512x512 (SD1.5), 768x768 (SDXL with batch=1)
```

**RTX 4070 12GB / RTX 3090 24GB:**
```
--highvram
Steps: 25-40
CFG: 7-9
Resolution: 1024x1024 (SDXL), 512x512 batch=4
```

**RTX 4090 24GB:**
```
--gpu-only
Steps: 30-50
CFG: 7-10
Resolution: 1536x1536 (SDXL), 2048x2048 with upscaling
```

## API Usage

### Basic API Call

```python
import requests
import json
import time

url = "http://localhost:8188/prompt"

prompt = {
    "3": {
        "inputs": {
            "seed": 42,
            "steps": 20,
            "cfg": 8,
            "sampler_name": "euler",
            "scheduler": "normal",
            "denoise": 1,
            "model": ["4", 0],
            "positive": ["6", 0],
            "negative": ["7", 0],
            "latent_image": ["5", 0]
        },
        "class_type": "KSampler"
    },
    "4": {
        "inputs": {
            "ckpt_name": "v1-5-pruned-emaonly.safetensors"
        },
        "class_type": "CheckpointLoaderSimple"
    },
    "5": {
        "inputs": {
            "width": 512,
            "height": 512,
            "batch_size": 1
        },
        "class_type": "EmptyLatentImage"
    },
    "6": {
        "inputs": {
            "text": "beautiful landscape, mountains, sunset, vibrant colors",
            "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
    },
    "7": {
        "inputs": {
            "text": "blurry, ugly, bad quality",
            "clip": ["4", 1]
        },
        "class_type": "CLIPTextEncode"
    },
    "8": {
        "inputs": {
            "samples": ["3", 0],
            "vae": ["4", 2]
        },
        "class_type": "VAEDecode"
    },
    "9": {
        "inputs": {
            "filename_prefix": "ComfyUI",
            "images": ["8", 0]
        },
        "class_type": "SaveImage"
    }
}

response = requests.post(url, json={"prompt": prompt})
prompt_id = response.json()['prompt_id']
print(f"Prompt ID: {prompt_id}")

# Check status
while True:
    history = requests.get(f"http://localhost:8188/history/{prompt_id}")
    if history.json():
        print("Generation complete!")
        break
    time.sleep(1)
```

### Export Workflow as API

1. In ComfyUI, create your workflow
2. Click "Save (API Format)"
3. Use the JSON output in your scripts

## Integration with Home Assistant

See HOME_ASSISTANT_INTEGRATION.md for full details.

**Quick Example:**

```yaml
rest_command:
  generate_image:
    url: "http://ai-workstation-ip:8188/prompt"
    method: POST
    content_type: "application/json"
    payload: >
      {
        "prompt": {{ prompt_data }}
      }
```

## Troubleshooting

### Out of Memory Errors

1. Lower resolution
2. Use `--lowvram` flag
3. Reduce batch size
4. Close other GPU applications
5. Use smaller model (SD1.5 instead of SDXL)

### Slow Generation

1. Check GPU utilization: `nvidia-smi`
2. Enable xformers
3. Use faster samplers (euler_a, dpm++ 2m)
4. Reduce steps (20 is usually enough)
5. Check CPU bottleneck (upgrade CPU if needed)

### Black Images

1. Update VAE
2. Check prompt (some words cause issues)
3. Lower CFG scale
4. Update ComfyUI

### Model Loading Issues

1. Check file integrity (re-download)
2. Verify file permissions
3. Check model format (prefer .safetensors)
4. Ensure correct model path in settings

## Useful Resources

- **CivitAI** - https://civitai.com/ (models, LoRAs)
- **ComfyUI Examples** - https://comfyanonymous.github.io/ComfyUI_examples/
- **OpenArt** - https://openart.ai/ (workflow sharing)
- **ComfyUI Reddit** - r/comfyui

## Workflow Tips

1. **Save frequently** - Use descriptive names
2. **Version workflows** - Keep iterations
3. **Comment nodes** - Right-click → "Add Note"
4. **Use groups** - Organize complex workflows
5. **Share workflows** - Export as PNG (includes metadata)

## Advanced Features

### AnimateDiff (Video Generation)

Requires AnimateDiff custom node and motion modules:

```bash
cd /mnt/models/animatediff
wget https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt
```

### IP-Adapter (Style Transfer)

Maintain consistent characters/styles across generations.

### ControlNet (Precise Control)

Use pose, depth, canny edge detection for exact control.

### Upscaling Workflows

Generate at lower resolution, then upscale with tiling for massive images.

## Recommended Prompting

### Good Prompt Structure

```
[Subject], [Style], [Quality tags], [Camera angle], [Lighting]

Example:
"portrait of a woman, digital art, highly detailed, 8k, trending on artstation,
soft lighting, centered composition"
```

### Negative Prompt

```
"blurry, ugly, deformed, bad anatomy, watermark, text, low quality,
jpeg artifacts, signature"
```

## Next Steps

1. Download essential models
2. Install ComfyUI Manager
3. Try basic text-to-image workflow
4. Experiment with different samplers/settings
5. Install custom nodes for your use cases
6. Create API integration with Home Assistant
7. Share and download community workflows
