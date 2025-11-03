#!/bin/bash
set -e

# Backup Script for AI Workstation
# Backs up configurations and user data (not models)

echo "=================================="
echo "AI Workstation Backup Script"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/mnt/nas/backups/ai-workstation}"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS="${RETENTION_DAYS:-7}"
PROJECT_DIR="/home/chris/projects/homelab/localAI"

echo -e "${BLUE}Backup destination: $BACKUP_DIR${NC}"
echo -e "${BLUE}Retention: $RETENTION_DAYS days${NC}"
echo ""

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo -e "${GREEN}Step 1: Backing up Docker configurations...${NC}"
tar -czf "$BACKUP_DIR/docker-configs_$DATE.tar.gz" \
    -C "$PROJECT_DIR" \
    docker-compose.yml \
    .env \
    2>/dev/null || echo -e "${YELLOW}Some files may not exist${NC}"

echo -e "${GREEN}✓ Docker configs backed up${NC}"

echo ""
echo -e "${GREEN}Step 2: Backing up service configurations...${NC}"
if [ -d "$PROJECT_DIR/config" ]; then
    tar -czf "$BACKUP_DIR/service-configs_$DATE.tar.gz" \
        -C "$PROJECT_DIR" \
        config/ \
        2>/dev/null
    echo -e "${GREEN}✓ Service configs backed up${NC}"
else
    echo -e "${YELLOW}No config directory found, skipping${NC}"
fi

echo ""
echo -e "${GREEN}Step 3: Backing up ComfyUI workflows...${NC}"
if [ -d "$PROJECT_DIR/data/comfyui/user" ]; then
    tar -czf "$BACKUP_DIR/comfyui-workflows_$DATE.tar.gz" \
        -C "$PROJECT_DIR/data/comfyui" \
        user/ \
        2>/dev/null
    echo -e "${GREEN}✓ ComfyUI workflows backed up${NC}"
else
    echo -e "${YELLOW}No ComfyUI user directory found, skipping${NC}"
fi

echo ""
echo -e "${GREEN}Step 4: Backing up Open-WebUI data...${NC}"
if [ -d "$PROJECT_DIR/data/open-webui" ]; then
    tar -czf "$BACKUP_DIR/open-webui-data_$DATE.tar.gz" \
        -C "$PROJECT_DIR/data" \
        open-webui/ \
        2>/dev/null
    echo -e "${GREEN}✓ Open-WebUI data backed up${NC}"
else
    echo -e "${YELLOW}No Open-WebUI data found, skipping${NC}"
fi

echo ""
echo -e "${GREEN}Step 5: Backing up Text-Generation-WebUI data...${NC}"
if [ -d "$PROJECT_DIR/data/text-gen-webui" ]; then
    tar -czf "$BACKUP_DIR/text-gen-webui-data_$DATE.tar.gz" \
        -C "$PROJECT_DIR/data/text-gen-webui" \
        presets/ \
        characters/ \
        2>/dev/null || echo -e "${YELLOW}Some directories may not exist${NC}"
    echo -e "${GREEN}✓ Text-Gen-WebUI data backed up${NC}"
else
    echo -e "${YELLOW}No Text-Gen-WebUI data found, skipping${NC}"
fi

echo ""
echo -e "${GREEN}Step 6: Creating backup manifest...${NC}"
cat > "$BACKUP_DIR/manifest_$DATE.txt" <<EOF
AI Workstation Backup
=====================
Date: $(date)
Hostname: $(hostname)
User: $USER

Backed up files:
- docker-configs_$DATE.tar.gz
- service-configs_$DATE.tar.gz
- comfyui-workflows_$DATE.tar.gz
- open-webui-data_$DATE.tar.gz
- text-gen-webui-data_$DATE.tar.gz

System Info:
- OS: $(lsb_release -d | cut -f2)
- GPU: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo "N/A")
- Docker Version: $(docker --version 2>/dev/null || echo "N/A")

Services Status:
$(docker compose ps 2>/dev/null || echo "Docker Compose not available")

Models NOT backed up (too large):
- /mnt/models/ directory
- Ollama models in data/ollama/

To restore models, re-download using:
  ./scripts/download-models.sh
EOF

echo -e "${GREEN}✓ Manifest created${NC}"

echo ""
echo -e "${GREEN}Step 7: Cleaning old backups (older than $RETENTION_DAYS days)...${NC}"
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "manifest_*.txt" -mtime +$RETENTION_DAYS -delete 2>/dev/null || true
echo -e "${GREEN}✓ Old backups cleaned${NC}"

echo ""
echo -e "${GREEN}Step 8: Calculating backup sizes...${NC}"
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
echo "Total backup size: $TOTAL_SIZE"

echo ""
echo "Backup files created:"
ls -lh "$BACKUP_DIR"/*_$DATE.* 2>/dev/null || echo "No files created"

echo ""
echo "=================================="
echo -e "${GREEN}Backup Complete!${NC}"
echo "=================================="
echo ""
echo "Backup location: $BACKUP_DIR"
echo "Backup date: $DATE"
echo ""
echo "To restore from backup:"
echo "  1. Extract configuration files:"
echo "     tar -xzf docker-configs_$DATE.tar.gz -C /path/to/restore/"
echo ""
echo "  2. Extract service configs:"
echo "     tar -xzf service-configs_$DATE.tar.gz -C /path/to/restore/"
echo ""
echo "  3. Extract ComfyUI workflows:"
echo "     tar -xzf comfyui-workflows_$DATE.tar.gz -C /path/to/restore/data/comfyui/"
echo ""
echo "  4. Re-download models:"
echo "     ./scripts/download-models.sh"
echo ""
echo "  5. Restart services:"
echo "     docker compose up -d"
echo ""

# Create a restore script
cat > "$BACKUP_DIR/restore_$DATE.sh" <<'RESTORE_SCRIPT'
#!/bin/bash
set -e

BACKUP_DATE="DATE_PLACEHOLDER"
BACKUP_DIR="$(dirname "$0")"
RESTORE_DIR="${1:-/home/chris/projects/homelab/localAI}"

echo "Restoring AI Workstation backup from $BACKUP_DATE"
echo "Restore location: $RESTORE_DIR"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

# Stop services if running
if [ -f "$RESTORE_DIR/docker-compose.yml" ]; then
    cd "$RESTORE_DIR"
    docker compose down 2>/dev/null || true
fi

# Extract files
echo "Extracting docker configs..."
tar -xzf "$BACKUP_DIR/docker-configs_$BACKUP_DATE.tar.gz" -C "$RESTORE_DIR"

echo "Extracting service configs..."
tar -xzf "$BACKUP_DIR/service-configs_$BACKUP_DATE.tar.gz" -C "$RESTORE_DIR" 2>/dev/null || true

echo "Extracting ComfyUI workflows..."
mkdir -p "$RESTORE_DIR/data/comfyui"
tar -xzf "$BACKUP_DIR/comfyui-workflows_$BACKUP_DATE.tar.gz" -C "$RESTORE_DIR/data/comfyui" 2>/dev/null || true

echo "Extracting Open-WebUI data..."
mkdir -p "$RESTORE_DIR/data"
tar -xzf "$BACKUP_DIR/open-webui-data_$BACKUP_DATE.tar.gz" -C "$RESTORE_DIR/data" 2>/dev/null || true

echo ""
echo "Restore complete!"
echo ""
echo "Next steps:"
echo "  1. Review .env file and adjust if needed"
echo "  2. Download models: ./scripts/download-models.sh"
echo "  3. Start services: docker compose up -d"
RESTORE_SCRIPT

# Replace placeholder with actual date
sed -i "s/DATE_PLACEHOLDER/$DATE/g" "$BACKUP_DIR/restore_$DATE.sh"
chmod +x "$BACKUP_DIR/restore_$DATE.sh"

echo "Restore script created: $BACKUP_DIR/restore_$DATE.sh"
echo ""
