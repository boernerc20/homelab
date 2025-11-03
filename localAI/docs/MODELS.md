# AI Model Recommendations & Requirements

## Overview

This guide helps you choose the right AI models for your hardware and use cases, with specific VRAM requirements and performance expectations.

## Language Models (LLMs)

### Small Models (7B-8B parameters) - Budget Friendly

#### Llama 3.1 8B (Recommended)
- **VRAM Required:** 6-8GB (Q4), 12GB (Q5/Q8), 16GB (FP16)
- **Use Cases:** General conversation, coding, Home Assistant
- **Speed:** ~20-40 tokens/sec (RTX 3060)
- **Quality:** Excellent for size, good reasoning

```bash
ollama pull llama3.1:8b        # Default Q4 (~4.7GB)
ollama pull llama3.1:8b-q8     # Higher quality (~8.5GB)
```

#### Mistral 7B v0.3
- **VRAM Required:** 6GB (Q4), 10GB (Q8)
- **Use Cases:** Fast inference, concise responses
- **Speed:** ~25-50 tokens/sec
- **Quality:** Fast and efficient

```bash
ollama pull mistral:7b
ollama pull mistral:7b-instruct-q8
```

#### Phi-3 Mini 3.8B
- **VRAM Required:** 4GB (Q4), 6GB (Q8)
- **Use Cases:** Fastest responses, low VRAM
- **Speed:** ~50-80 tokens/sec
- **Quality:** Surprising good for size

```bash
ollama pull phi3:mini
```

#### CodeLlama 7B
- **VRAM Required:** 6GB (Q4), 10GB (Q8)
- **Use Cases:** Code generation, programming help
- **Speed:** ~20-35 tokens/sec
- **Quality:** Best for code at this size

```bash
ollama pull codellama:7b
ollama pull codellama:7b-instruct
```

### Medium Models (13B-14B parameters) - Balanced

#### Llama 3.1 13B
- **VRAM Required:** 10GB (Q4), 16GB (Q8), 24GB (FP16)
- **Use Cases:** Better reasoning, complex tasks
- **Speed:** ~10-20 tokens/sec (RTX 3060)
- **Quality:** Significantly better than 7B

```bash
ollama pull llama3.1:13b
```

#### Mistral-Nemo 12B
- **VRAM Required:** 8GB (Q4), 14GB (Q8)
- **Use Cases:** Good middle ground
- **Speed:** ~15-25 tokens/sec
- **Quality:** Excellent efficiency

```bash
ollama pull mistral-nemo:12b
```

### Large Models (30B-34B parameters) - 24GB VRAM

#### Llama 3.1 34B
- **VRAM Required:** 20GB (Q4), 24GB+ (Q5)
- **Use Cases:** Complex reasoning, professional use
- **Speed:** ~5-10 tokens/sec (RTX 3090)
- **Quality:** Near GPT-3.5 quality

```bash
ollama pull llama3.1:34b-q4
```

#### Yi 34B
- **VRAM Required:** 20GB (Q4), 24GB+ (Q8)
- **Use Cases:** Long context, detailed responses
- **Speed:** ~5-12 tokens/sec
- **Quality:** Excellent reasoning

```bash
ollama pull yi:34b-q4
```

### Very Large Models (70B+ parameters) - Expert Use

#### Llama 3.1 70B
- **VRAM Required:** 40GB (Q4) - Needs multiple GPUs or heavy quantization
- **Use Cases:** Best local model quality
- **Speed:** ~2-5 tokens/sec (RTX 4090)
- **Quality:** GPT-4 level on some tasks

```bash
ollama pull llama3.1:70b-q4  # 24GB with heavy quant, slow
```

**Note:** 70B models are challenging on single consumer GPUs. Consider 34B for better experience.

## Specialized LLMs

### Medical & Scientific

#### Meditron 7B/70B
- Medical knowledge
- Drug interactions
- Clinical documentation

```bash
ollama pull meditron:7b
```

### Legal

#### Lex-GPT 13B
- Legal document analysis
- Contract review

### Coding Specialists

#### DeepSeek-Coder 33B
- **VRAM:** 20GB (Q4)
- Best coding model at this size
- Multiple programming languages

```bash
ollama pull deepseek-coder:33b
```

#### StarCoder2 15B
- **VRAM:** 12GB (Q4)
- Code completion
- Supports 600+ languages

```bash
ollama pull starcoder2:15b
```

## Vision-Language Models

### LLaVA (Llama + Vision)
- **VRAM:** 8GB (7B version)
- Image understanding
- Visual question answering

```bash
ollama pull llava:7b
ollama pull llava:13b
ollama pull llava:34b
```

### Bakllava
- **VRAM:** 6GB
- Efficient vision model
- Good for resource-constrained setups

```bash
ollama pull bakllava:7b
```

## Image Generation Models

### Stable Diffusion 1.5
- **VRAM:** 4GB minimum, 6GB comfortable
- **Size:** ~4GB
- **Resolution:** 512x512 native
- **Speed:** ~2-3 sec/image (RTX 3060, 20 steps)
- **Use Cases:** Fast iteration, learning, LoRA training

**Download:**
```bash
cd /mnt/models/stable-diffusion/checkpoints
wget https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
```

### Stable Diffusion XL (SDXL)
- **VRAM:** 8GB minimum, 12GB comfortable
- **Size:** ~6.5GB (base + refiner)
- **Resolution:** 1024x1024 native
- **Speed:** ~8-12 sec/image (RTX 3060, 25 steps)
- **Use Cases:** High-quality images, better prompt understanding

**Download:**
```bash
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors
wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors
```

### SDXL Turbo
- **VRAM:** 8GB
- **Size:** ~6.5GB
- **Resolution:** 512x512
- **Speed:** ~1-2 sec/image (1-4 steps only!)
- **Use Cases:** Real-time generation, rapid prototyping

**Download:**
```bash
wget https://huggingface.co/stabilityai/sdxl-turbo/resolve/main/sd_xl_turbo_1.0_fp16.safetensors
```

### Flux.1
- **VRAM:** 16GB minimum, 24GB comfortable
- **Size:** ~23GB
- **Resolution:** 1024x1024+
- **Speed:** ~15-25 sec/image (RTX 4090)
- **Use Cases:** Best quality, photorealism, complex prompts

**Versions:**
- **Schnell:** Faster (4-8 steps)
- **Dev:** Higher quality (20-30 steps)

**Download:**
```bash
wget https://huggingface.co/black-forest-labs/FLUX.1-schnell/resolve/main/flux1-schnell.safetensors
```

### Community Fine-tunes (Recommended)

#### Realistic Vision (SD1.5 based)
- Photorealistic images
- ~2GB

```bash
wget https://civitai.com/api/download/models/130072 -O realistic_vision_v5.1.safetensors
```

#### DreamShaper XL
- Versatile, artistic
- ~6.5GB

```bash
wget https://civitai.com/api/download/models/351306 -O dreamshaper_xl.safetensors
```

#### Juggernaut XL
- Photorealism, portraits
- ~6.5GB

## Video Generation Models

### Stable Video Diffusion (SVD)
- **VRAM:** 16GB minimum, 24GB comfortable
- **Size:** ~9.5GB
- **Output:** 14-25 frames, 576x1024
- **Speed:** ~60-90 sec/video (RTX 3090)
- **Use Cases:** Image-to-video, motion generation

**Download:**
```bash
mkdir -p /mnt/models/video/svd
cd /mnt/models/video/svd
wget https://huggingface.co/stabilityai/stable-video-diffusion-img2vid-xt/resolve/main/svd_xt.safetensors
```

### AnimateDiff
- **VRAM:** 12GB minimum
- **Size:** ~1.6GB (motion module)
- **Output:** Variable length, SD resolution
- **Speed:** Depends on frame count
- **Use Cases:** Animation from SD models

**Download:**
```bash
mkdir -p /mnt/models/animatediff
cd /mnt/models/animatediff
wget https://huggingface.co/guoyww/animatediff/resolve/main/mm_sd_v15_v2.ckpt
```

## Upscaling Models

### RealESRGAN
- **VRAM:** 4-8GB depending on tile size
- **Size:** ~17MB-64MB
- **Upscale:** 4x
- **Use Cases:** Photo upscaling, detail enhancement

**Download:**
```bash
cd /mnt/models/stable-diffusion/upscale_models
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth
wget https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.1/RealESRGAN_x4plus_anime_6B.pth
```

### ESRGAN
- Similar to RealESRGAN
- Multiple versions for different styles

### Latent Upscale
- Built into SD
- Fast, uses same model
- Good for quick upscaling

## Speech Models

### Whisper (Speech-to-Text)

#### Tiny
- **VRAM:** 1GB
- **Size:** 74MB
- **Speed:** Real-time on CPU
- **Quality:** Basic, English-only

#### Base
- **VRAM:** 1GB
- **Size:** 142MB
- **Speed:** 2x real-time
- **Quality:** Good for most uses

#### Small
- **VRAM:** 2GB
- **Size:** 466MB
- **Speed:** 1.5x real-time
- **Quality:** Very good

#### Medium
- **VRAM:** 5GB
- **Size:** 1.5GB
- **Speed:** 0.8x real-time
- **Quality:** Excellent

#### Large-v3
- **VRAM:** 10GB
- **Size:** 2.9GB
- **Speed:** 0.5x real-time
- **Quality:** Best available

**Recommendation:** Base or Small for Home Assistant

### Piper (Text-to-Speech)

Multiple voice options:
- **en_US-lessac-medium** - Natural male voice
- **en_US-amy-medium** - Female voice
- **en_GB-** - British accents
- **Various languages** - 50+ languages supported

**VRAM:** Minimal (<1GB)
**Speed:** Real-time

## Model Selection by GPU

### RTX 3060 12GB

**LLMs:**
- Llama 3.1 8B (Q4/Q8) ✓
- Mistral 7B ✓
- Llama 3.1 13B (Q4) ✓

**Image:**
- SD 1.5 ✓
- SDXL (batch=1) ✓
- SDXL Turbo ✓

**Video:**
- AnimateDiff (limited) ⚠️

### RTX 4070 12GB / RTX 3090 24GB

**LLMs:**
- All 7B-13B models ✓
- Llama 3.1 34B (Q4) ✓
- DeepSeek-Coder 33B ✓

**Image:**
- SD 1.5 (batch=4) ✓
- SDXL (batch=2) ✓
- Flux.1 Schnell ✓

**Video:**
- SVD ✓
- AnimateDiff ✓

### RTX 4090 24GB

**LLMs:**
- All models up to 34B ✓
- Llama 3.1 70B (Q4, slow) ⚠️

**Image:**
- All models ✓
- Flux.1 Dev ✓
- Multiple simultaneous ✓

**Video:**
- SVD ✓
- Long AnimateDiff ✓

## Quantization Explained

### GGUF Quantization Levels

- **Q2** - 2-bit: Heavily degraded, not recommended
- **Q3** - 3-bit: Noticeable quality loss
- **Q4** - 4-bit: Good balance, recommended for most (4-5GB for 7B)
- **Q5** - 5-bit: Better quality, minimal loss (5-6GB for 7B)
- **Q6** - 6-bit: Very close to FP16 (6-7GB for 7B)
- **Q8** - 8-bit: Nearly identical to FP16 (8-9GB for 7B)
- **FP16** - 16-bit: Full quality (14-16GB for 7B)

**Recommendation:** Q4 for most users, Q5/Q8 if VRAM allows

### When to Use Different Quantizations

- **Q4:** Limited VRAM, multiple models loaded
- **Q5:** Good VRAM, want better quality
- **Q8:** Plenty of VRAM, want best local quality
- **FP16:** Fine-tuning, maximum quality needed

## Storage Requirements

### Minimal Setup (~50GB)
- Llama 3.1 8B (Q4): 5GB
- SD 1.5: 4GB
- SDXL: 7GB
- Whisper Base: 0.2GB
- Essential LoRAs: 2GB
- Working space: 30GB

### Recommended Setup (~200GB)
- Multiple LLMs (7B-13B): 40GB
- SDXL + fine-tunes: 30GB
- LoRAs, embeddings: 20GB
- ControlNet models: 25GB
- Upscalers: 5GB
- Video models: 15GB
- Working space: 65GB

### Enthusiast Setup (~500GB+)
- Large LLM collection: 150GB
- Full image model library: 100GB
- Video generation: 50GB
- ControlNet full suite: 40GB
- Experimental/community models: 100GB
- Working space: 60GB

## Download Script

Create a download script for essential models:

```bash
#!/bin/bash
# Essential model download script

MODEL_DIR="/mnt/models"

# Create directories
mkdir -p $MODEL_DIR/{llm/ollama,stable-diffusion/{checkpoints,vae,loras,controlnet,upscale_models},video/svd}

# LLMs via Ollama
ollama pull llama3.1:8b
ollama pull mistral:7b
ollama pull codellama:7b

# Image models
cd $MODEL_DIR/stable-diffusion/checkpoints
wget -c https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors
wget -c https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# VAEs
cd $MODEL_DIR/stable-diffusion/vae
wget -c https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.safetensors

# Upscalers
cd $MODEL_DIR/stable-diffusion/upscale_models
wget -c https://github.com/xinntao/Real-ESRGAN/releases/download/v0.1.0/RealESRGAN_x4plus.pth

echo "Essential models downloaded!"
```

## Model Management Tips

1. **Start small** - Download only what you need
2. **Test first** - Verify models work before downloading more
3. **Organize** - Keep consistent directory structure
4. **Clean up** - Remove unused models regularly
5. **Backup configs** - Not the models, just your settings
6. **Use symlinks** - If sharing models between systems
7. **Monitor space** - AI models add up quickly

## Performance Expectations

### Text Generation Speed (Tokens/sec)

| Model Size | RTX 3060 12GB | RTX 4070 12GB | RTX 4090 24GB |
|------------|---------------|---------------|---------------|
| 7B Q4      | 25-40         | 40-60         | 80-120        |
| 13B Q4     | 12-20         | 20-35         | 40-60         |
| 34B Q4     | N/A           | 8-12          | 15-25         |
| 70B Q4     | N/A           | N/A           | 5-10          |

### Image Generation Speed (seconds/image)

| Model      | RTX 3060 12GB | RTX 4070 12GB | RTX 4090 24GB |
|------------|---------------|---------------|---------------|
| SD 1.5     | 2-3           | 1-2           | 0.5-1         |
| SDXL       | 10-15         | 6-10          | 3-5           |
| SDXL Turbo | 1-2           | 0.5-1         | 0.3-0.5       |
| Flux.1     | N/A           | 20-30         | 12-18         |

*Based on typical settings (20-25 steps, 512x512 for SD1.5, 1024x1024 for SDXL)*

## Next Steps

1. Determine your primary use cases
2. Check your available VRAM
3. Start with recommended models for your GPU
4. Test and benchmark
5. Expand collection based on needs
6. Join communities for model recommendations
