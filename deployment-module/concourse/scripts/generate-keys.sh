#!/bin/bash

# =============================================================================
# Concourse Keys Generation Script
# =============================================================================
# This script generates all SSH keys required for Concourse CI/CD
#
# Keys generated:
# 1. session_signing_key   - Web UI session management
# 2. tsa_host_key          - Worker registration (TSA = worker gateway)
# 3. worker_key            - Worker authentication
# 4. authorized_worker_keys - List of authorized worker public keys
#
# Usage:
#   ./generate-keys.sh
#
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONCOURSE_DIR="$(dirname "$SCRIPT_DIR")"
KEYS_DIR="$CONCOURSE_DIR/keys"
WEB_KEYS_DIR="$KEYS_DIR/web"
WORKER_KEYS_DIR="$KEYS_DIR/worker"

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}Concourse CI/CD - SSH Keys Generation${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""

# Check if keys already exist
if [ -f "$WEB_KEYS_DIR/session_signing_key" ]; then
    echo -e "${YELLOW}⚠️  Keys already exist!${NC}"
    echo ""
    read -p "Do you want to regenerate all keys? This will invalidate existing workers. (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}✅ Keeping existing keys${NC}"
        exit 0
    fi
    echo -e "${YELLOW}🔄 Regenerating keys...${NC}"
    echo ""
fi

# Create directories
echo -e "${BLUE}📁 Creating key directories...${NC}"
mkdir -p "$WEB_KEYS_DIR"
mkdir -p "$WORKER_KEYS_DIR"
echo -e "${GREEN}✅ Directories created${NC}"
echo ""

# Generate web keys
echo -e "${BLUE}🔑 Generating web keys...${NC}"

# 1. Session signing key (used by web to sign session tokens)
echo -e "  Generating session_signing_key..."
ssh-keygen -t rsa -b 4096 -f "$WEB_KEYS_DIR/session_signing_key" -N '' -C "concourse-session-signing" >/dev/null 2>&1
chmod 600 "$WEB_KEYS_DIR/session_signing_key"
echo -e "${GREEN}  ✅ session_signing_key created${NC}"

# 2. TSA host key (used by web for worker registration)
echo -e "  Generating tsa_host_key..."
ssh-keygen -t rsa -b 4096 -f "$WEB_KEYS_DIR/tsa_host_key" -N '' -C "concourse-tsa-host" >/dev/null 2>&1
chmod 600 "$WEB_KEYS_DIR/tsa_host_key"
echo -e "${GREEN}  ✅ tsa_host_key created${NC}"

echo -e "${GREEN}✅ Web keys generated${NC}"
echo ""

# Generate worker keys
echo -e "${BLUE}🔑 Generating worker keys...${NC}"

# 3. Worker key (used by worker to authenticate with TSA)
echo -e "  Generating worker_key..."
ssh-keygen -t rsa -b 4096 -f "$WORKER_KEYS_DIR/worker_key" -N '' -C "concourse-worker" >/dev/null 2>&1
chmod 600 "$WORKER_KEYS_DIR/worker_key"
echo -e "${GREEN}  ✅ worker_key created${NC}"

echo -e "${GREEN}✅ Worker keys generated${NC}"
echo ""

# Copy public keys for cross-component authentication
echo -e "${BLUE}🔗 Setting up key relationships...${NC}"

# Web needs to know worker's public key (authorized_worker_keys)
cp "$WORKER_KEYS_DIR/worker_key.pub" "$WEB_KEYS_DIR/authorized_worker_keys"
chmod 644 "$WEB_KEYS_DIR/authorized_worker_keys"
echo -e "${GREEN}  ✅ authorized_worker_keys created${NC}"

# Worker needs to know TSA's public key
cp "$WEB_KEYS_DIR/tsa_host_key.pub" "$WORKER_KEYS_DIR/tsa_host_key.pub"
chmod 644 "$WORKER_KEYS_DIR/tsa_host_key.pub"
echo -e "${GREEN}  ✅ TSA public key copied to worker${NC}"

echo -e "${GREEN}✅ Key relationships established${NC}"
echo ""

# Display summary
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${GREEN}✅ All keys generated successfully!${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${BLUE}Key locations:${NC}"
echo ""
echo -e "${YELLOW}Web keys (used by concourse-web):${NC}"
echo "  $WEB_KEYS_DIR/session_signing_key"
echo "  $WEB_KEYS_DIR/tsa_host_key"
echo "  $WEB_KEYS_DIR/authorized_worker_keys"
echo ""
echo -e "${YELLOW}Worker keys (used by concourse-worker):${NC}"
echo "  $WORKER_KEYS_DIR/worker_key"
echo "  $WORKER_KEYS_DIR/tsa_host_key.pub"
echo ""
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo -e "${YELLOW}  1. These keys are git-ignored (see .gitignore)${NC}"
echo -e "${YELLOW}  2. Keep these keys secure - they control access to your CI/CD${NC}"
echo -e "${YELLOW}  3. Never commit these keys to version control${NC}"
echo -e "${YELLOW}  4. Regenerate keys if compromised${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${GREEN}🚀 You can now start Concourse with:${NC}"
echo -e "   ${BLUE}cd $CONCOURSE_DIR${NC}"
echo -e "   ${BLUE}docker-compose up -d${NC}"
echo ""
