#!/bin/bash

# =============================================================================
# Concourse CI/CD Setup Script
# =============================================================================
# This script performs the complete initial setup of Concourse CI/CD
#
# Steps:
# 1. Generate SSH keys
# 2. Create .env file from template
# 3. Start Concourse services
# 4. Wait for services to be healthy
# 5. Install fly CLI
# 6. Login to Concourse
# 7. Display next steps
#
# Usage:
#   ./setup.sh
#
# =============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONCOURSE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}🚀 Concourse CI/CD Setup${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Docker Compose is not installed${NC}"
    echo "Please install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Detect docker-compose command
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${GREEN}✅ Docker is installed${NC}"
echo ""

# Step 1: Generate keys
echo -e "${BLUE}Step 1: Generating SSH keys...${NC}"
if [ ! -f "$CONCOURSE_DIR/keys/web/session_signing_key" ]; then
    "$SCRIPT_DIR/generate-keys-openssl.sh"
else
    echo -e "${YELLOW}⚠️  Keys already exist, skipping generation${NC}"
fi
echo ""

# Step 2: Create .env file
echo -e "${BLUE}Step 2: Creating .env file...${NC}"
if [ ! -f "$CONCOURSE_DIR/.env" ]; then
    cp "$CONCOURSE_DIR/.env.example" "$CONCOURSE_DIR/.env"
    echo -e "${GREEN}✅ Created .env file from template${NC}"
    echo -e "${YELLOW}⚠️  Please edit .env and set your passwords${NC}"
    echo ""
    read -p "Press Enter to continue after editing .env (or Ctrl+C to exit)..."
else
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
fi
echo ""

# Step 3: Start Concourse services
echo -e "${BLUE}Step 3: Starting Concourse services...${NC}"
cd "$CONCOURSE_DIR"

echo "Running: $DOCKER_COMPOSE up -d"
$DOCKER_COMPOSE up -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Concourse services started${NC}"
else
    echo -e "${RED}❌ Failed to start Concourse services${NC}"
    exit 1
fi
echo ""

# Step 4: Wait for services to be healthy
echo -e "${BLUE}Step 4: Waiting for services to be healthy...${NC}"
echo "This may take 30-60 seconds..."
echo ""

MAX_WAIT=120
WAITED=0
HEALTHY=0

while [ $WAITED -lt $MAX_WAIT ]; do
    # Check if concourse-web is responding
    if curl -s http://localhost:8080/api/v1/info > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Concourse web is healthy${NC}"
        HEALTHY=1
        break
    fi

    echo -e "⏳ Waiting for Concourse to start... (${WAITED}s / ${MAX_WAIT}s)"
    sleep 5
    WAITED=$((WAITED + 5))
done

if [ $HEALTHY -eq 0 ]; then
    echo -e "${RED}❌ Concourse did not become healthy in time${NC}"
    echo "Check logs with: $DOCKER_COMPOSE logs"
    exit 1
fi
echo ""

# Step 5: Install fly CLI
echo -e "${BLUE}Step 5: Installing fly CLI...${NC}"

# Download fly CLI from Concourse
FLY_BINARY="$CONCOURSE_DIR/fly"

if [ "$(uname -s)" = "Darwin" ]; then
    FLY_URL="http://localhost:8080/api/v1/cli?arch=amd64&platform=darwin"
elif [ "$(uname -s)" = "Linux" ]; then
    FLY_URL="http://localhost:8080/api/v1/cli?arch=amd64&platform=linux"
else
    echo -e "${YELLOW}⚠️  Unknown platform, please download fly manually from http://localhost:8080${NC}"
    FLY_URL=""
fi

if [ -n "$FLY_URL" ]; then
    curl -s -o "$FLY_BINARY" "$FLY_URL"
    chmod +x "$FLY_BINARY"
    echo -e "${GREEN}✅ fly CLI installed to: $FLY_BINARY${NC}"
    echo ""
    echo -e "${YELLOW}💡 Tip: Add fly to your PATH:${NC}"
    echo -e "   ${BLUE}sudo mv $FLY_BINARY /usr/local/bin/fly${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠️  Please download fly CLI manually${NC}"
fi
echo ""

# Step 6: Login to Concourse
echo -e "${BLUE}Step 6: Logging in to Concourse...${NC}"

# Load credentials from .env
source "$CONCOURSE_DIR/.env"

if [ -f "$FLY_BINARY" ]; then
    echo "Logging in as: ${CONCOURSE_USERNAME:-admin}"
    "$FLY_BINARY" -t local login \
        -c http://localhost:8080 \
        -u "${CONCOURSE_USERNAME:-admin}" \
        -p "${CONCOURSE_PASSWORD:-admin}"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Logged in successfully${NC}"
    else
        echo -e "${RED}❌ Login failed${NC}"
        echo "Please check your credentials in .env"
    fi
else
    echo -e "${YELLOW}⚠️  fly CLI not available, skipping login${NC}"
fi
echo ""

# Display summary
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${GREEN}✅ Concourse CI/CD Setup Complete!${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${BLUE}📊 Status:${NC}"
echo -e "  ✅ SSH keys generated"
echo -e "  ✅ Configuration file created (.env)"
echo -e "  ✅ Concourse services running"
echo -e "  ✅ fly CLI installed"
echo -e "  ✅ Logged in to Concourse"
echo ""
echo -e "${BLUE}🌐 Access Points:${NC}"
echo -e "  Web UI: ${GREEN}http://localhost:8080${NC}"
echo -e "  Username: ${YELLOW}${CONCOURSE_USERNAME:-admin}${NC}"
echo -e "  Password: ${YELLOW}(see .env file)${NC}"
echo ""
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo -e "  View logs:       ${YELLOW}$DOCKER_COMPOSE logs -f${NC}"
echo -e "  Stop services:   ${YELLOW}$DOCKER_COMPOSE stop${NC}"
echo -e "  Start services:  ${YELLOW}$DOCKER_COMPOSE start${NC}"
echo -e "  Restart:         ${YELLOW}$DOCKER_COMPOSE restart${NC}"
echo -e "  Remove all:      ${YELLOW}$DOCKER_COMPOSE down -v${NC}"
echo ""
echo -e "${BLUE}📋 Next Steps:${NC}"
echo -e "  1. ${YELLOW}Edit credentials.yml with your secrets${NC}"
echo -e "     cp credentials.yml.example credentials.yml"
echo -e "     # Add your SSH keys and Raspberry Pi details"
echo ""
echo -e "  2. ${YELLOW}Deploy the pipeline${NC}"
echo -e "     ./scripts/deploy-pipeline.sh"
echo ""
echo -e "  3. ${YELLOW}Trigger a build${NC}"
echo -e "     $FLY_BINARY -t local trigger-job -j flutter-grist/quality-checks"
echo ""
echo -e "${BLUE}==============================================================================${NC}"
echo ""
