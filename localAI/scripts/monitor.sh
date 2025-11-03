#!/bin/bash

# AI Workstation Monitoring Script
# Displays status of all services and system resources

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo "=================================="
echo "AI Workstation Monitor"
echo "=================================="
echo "Last updated: $(date)"
echo ""

# GPU Status
echo -e "${CYAN}GPU Status:${NC}"
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=index,name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,memory.total,power.draw --format=csv,noheader,nounits | while IFS=, read -r idx name temp gpu_util mem_util mem_used mem_total power; do
        echo -e "  GPU $idx: ${GREEN}$name${NC}"
        echo "    Temperature: ${temp}°C"
        echo "    GPU Usage: ${gpu_util}%"
        echo "    Memory: ${mem_used}MB / ${mem_total}MB (${mem_util}%)"
        echo "    Power: ${power}W"
    done
else
    echo -e "  ${RED}nvidia-smi not available${NC}"
fi

echo ""

# Docker Services Status
echo -e "${CYAN}Service Status:${NC}"
if command -v docker &> /dev/null && docker compose ps > /dev/null 2>&1; then
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
        if [[ $line == *"Up"* ]]; then
            echo -e "  ${GREEN}$line${NC}"
        elif [[ $line == *"Exit"* ]] || [[ $line == *"Down"* ]]; then
            echo -e "  ${RED}$line${NC}"
        else
            echo "  $line"
        fi
    done
else
    echo -e "  ${RED}Docker Compose not available${NC}"
fi

echo ""

# Ollama Models
echo -e "${CYAN}Ollama Models:${NC}"
if docker ps | grep -q ollama; then
    docker exec ollama ollama list 2>/dev/null | tail -n +2 | while IFS= read -r line; do
        echo "  $line"
    done
else
    echo -e "  ${YELLOW}Ollama service not running${NC}"
fi

echo ""

# System Resources
echo -e "${CYAN}System Resources:${NC}"
echo "  CPU Usage: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
echo "  Memory: $(free -h | awk '/^Mem:/ {printf "%s / %s (%.1f%%)", $3, $2, ($3/$2)*100}')"
echo "  Disk Usage:"
df -h | grep -E "^/dev/" | while read -r line; do
    echo "    $line" | awk '{printf "    %s: %s / %s (%s)\n", $1, $3, $2, $5}'
done

echo ""

# Model Storage
echo -e "${CYAN}Model Storage:${NC}"
if [ -d "/mnt/models" ]; then
    MODEL_SIZE=$(du -sh /mnt/models 2>/dev/null | cut -f1)
    echo "  Total: $MODEL_SIZE"
    echo "  Breakdown:"
    du -h --max-depth=2 /mnt/models 2>/dev/null | tail -n +2 | sort -h -r | head -10 | while read -r line; do
        echo "    $line"
    done
else
    echo -e "  ${YELLOW}/mnt/models not found${NC}"
fi

echo ""

# Service URLs
echo -e "${CYAN}Service URLs:${NC}"
echo "  Open-WebUI (Chat):     http://$(hostname -I | awk '{print $1}'):3000"
echo "  ComfyUI (Images):      http://$(hostname -I | awk '{print $1}'):8188"
echo "  SearXNG (Search):      http://$(hostname -I | awk '{print $1}'):8080"
echo "  Ollama API:            http://$(hostname -I | awk '{print $1}'):11434"
echo "  Text-Gen-WebUI:        http://$(hostname -I | awk '{print $1}'):7860"

echo ""

# Recent Activity
echo -e "${CYAN}Recent Activity (Docker logs):${NC}"
docker compose logs --tail=5 2>/dev/null | tail -20 | while IFS= read -r line; do
    if [[ $line == *"error"* ]] || [[ $line == *"Error"* ]] || [[ $line == *"ERROR"* ]]; then
        echo -e "  ${RED}$line${NC}"
    elif [[ $line == *"warn"* ]] || [[ $line == *"Warning"* ]] || [[ $line == *"WARN"* ]]; then
        echo -e "  ${YELLOW}$line${NC}"
    else
        echo "  $line"
    fi
done

echo ""

# Quick Actions
echo -e "${CYAN}Quick Actions:${NC}"
echo "  View service logs:     docker compose logs -f [service-name]"
echo "  Restart service:       docker compose restart [service-name]"
echo "  Check GPU usage:       watch -n 1 nvidia-smi"
echo "  Monitor resources:     htop"
echo ""

# Health Checks
echo -e "${CYAN}Health Checks:${NC}"

# Check Ollama
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo -e "  Ollama API:         ${GREEN}✓ Online${NC}"
else
    echo -e "  Ollama API:         ${RED}✗ Offline${NC}"
fi

# Check Open-WebUI
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo -e "  Open-WebUI:         ${GREEN}✓ Online${NC}"
else
    echo -e "  Open-WebUI:         ${RED}✗ Offline${NC}"
fi

# Check ComfyUI
if curl -s http://localhost:8188 > /dev/null 2>&1; then
    echo -e "  ComfyUI:            ${GREEN}✓ Online${NC}"
else
    echo -e "  ComfyUI:            ${RED}✗ Offline${NC}"
fi

# Check SearXNG
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo -e "  SearXNG:            ${GREEN}✓ Online${NC}"
else
    echo -e "  SearXNG:            ${RED}✗ Offline${NC}"
fi

echo ""
echo "=================================="
echo "Press Ctrl+C to exit"
echo "Refreshing in 10 seconds..."
echo "=================================="

# Auto-refresh option
if [ "$1" = "-w" ] || [ "$1" = "--watch" ]; then
    sleep 10
    exec "$0" "$@"
fi
