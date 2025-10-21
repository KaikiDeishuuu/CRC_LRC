#!/usr/bin/env bash
# Improved install-or-update script for CRC_LRC
# - Better error handling: set -euo pipefail
# - Architecture normalization and arm64 support
# - Use docker compose V2 if available, otherwise docker-compose
# - Use docker buildx for multi-arch builds (optional)
# - Safer image cleanup and backup

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Basic utilities
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Determine docker compose command
COMPOSE_CMD=""
if command_exists docker && docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command_exists docker-compose; then
  COMPOSE_CMD="docker-compose"
fi

# Normalize architecture names returned by uname -m
normalize_arch() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    armv7l|armv7) echo "armv7" ;;
    *) echo "$arch" ;;
  esac
}

ARCH=$(normalize_arch)

# Print header
echo -e "${CYAN}CRC_LRC installer - arch=${ARCH}${NC}"

# Check docker
if ! command_exists docker; then
  echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
  exit 1
fi

# Check compose
if [ -z "${COMPOSE_CMD}" ]; then
  echo -e "${YELLOW}Docker Compose V2 not found and docker-compose not installed.${NC}"
  echo "Attempting to install docker-compose (standalone binary)"
  if command_exists curl; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    COMPOSE_CMD="docker-compose"
  else
    echo -e "${RED}Neither docker compose V2 nor curl available to install docker-compose. Install compose manually.${NC}"
    exit 1
  fi
fi

# Build/upgrade with buildx for multi-arch
use_buildx=false
if command_exists docker && docker buildx version >/dev/null 2>&1; then
  use_buildx=true
fi

# Create backup dir
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup config and env
if [ -f config/config.yaml ]; then
  cp config/config.yaml "$BACKUP_DIR/" || true
fi
if [ -f .env ]; then
  cp .env "$BACKUP_DIR/" || true
fi

# Offer to enable private buildx builder for arm64
if [ "$ARCH" = "arm64" ] && [ "$use_buildx" = true ]; then
  echo -e "${CYAN}Detected arm64 architecture and buildx available. Preparing multi-arch build options.${NC}"
  if ! docker buildx inspect crc_lrc_builder >/dev/null 2>&1; then
    echo -e "${YELLOW}Creating buildx builder 'crc_lrc_builder'...${NC}"
    docker buildx create --name crc_lrc_builder --use || true
    docker buildx inspect --bootstrap || true
  fi
fi

# Build images (choose strategy)
echo -e "${CYAN}Building Docker images...${NC}"
if [ "$use_buildx" = true ]; then
  echo -e "${CYAN}Using buildx for multi-arch build (if configured)${NC}"
  # If arch is arm64 and multi-arch is desired, set platforms
  if [ "$ARCH" = "arm64" ]; then
    docker buildx build --platform linux/arm64,linux/amd64 --load -t crc_lrc-checksum-api:latest -f Dockerfile .
  else
    docker buildx build --platform linux/amd64 --load -t crc_lrc-checksum-api:latest -f Dockerfile .
  fi
else
  # Fallback to docker-compose build
  $COMPOSE_CMD build --no-cache || {
    echo -e "${RED}docker compose build failed. Please check Dockerfile and dependencies.${NC}"
    exit 1
  }
fi

# Use compose to bring up services
echo -e "${CYAN}Bringing up containers...${NC}"
$COMPOSE_CMD up -d --remove-orphans

# Health check
echo -e "${CYAN}Waiting for the API to be healthy...${NC}"
RETRIES=10
count=0
until curl -fs http://localhost:8080/api/checksum?input=health >/dev/null 2>&1 || [ $count -ge $RETRIES ]; do
  count=$((count+1))
  echo -e "${YELLOW}Waiting ($count/$RETRIES)...${NC}"
  sleep 3
done

if [ $count -ge $RETRIES ]; then
  echo -e "${RED}API failed to respond. Check 'docker compose logs' for details.${NC}"
  exit 1
fi

# Optional cleanup - only remove old named images matching project and not latest
echo -e "${CYAN}Cleanup old CRC_LRC images (non-latest)...${NC}"
docker images --format "{{.Repository}}:{{.Tag}} {{.ID}}" | grep "crc_lrc-checksum-api" | while read -r line; do
  tag=$(echo "$line" | awk '{print $1}')
  id=$(echo "$line" | awk '{print $2}')
  if [[ "$tag" != "crc_lrc-checksum-api:latest" ]]; then
    docker rmi -f "$id" || true
  fi
done

# Summary
echo -e "${GREEN}Install/Update complete. Backup at: $BACKUP_DIR${NC}"

exit 0
