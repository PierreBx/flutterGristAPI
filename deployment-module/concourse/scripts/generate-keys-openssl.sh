#!/bin/bash

# =============================================================================
# Concourse Keys Generation Script (OpenSSL-based)
# =============================================================================
# This script generates all SSH keys required for Concourse CI/CD using OpenSSL
# (works when ssh-keygen is not available)
#
# Keys generated:
# 1. session_signing_key   - Web UI session management
# 2. tsa_host_key          - Worker registration (TSA = worker gateway)
# 3. worker_key            - Worker authentication
# 4. authorized_worker_keys - List of authorized worker public keys
#
# Usage:
#   ./generate-keys-openssl.sh
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
echo -e "${BLUE}Concourse CI/CD - SSH Keys Generation (OpenSSL)${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""

# Check if OpenSSL is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}❌ Error: OpenSSL is not installed or not in PATH${NC}"
    exit 1
fi

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

# Function to generate RSA key pair using OpenSSL
generate_key_pair() {
    local private_key_path="$1"
    local key_name="$2"

    echo -e "  Generating ${key_name}..."

    # Generate RSA private key (4096 bits)
    openssl genrsa -out "${private_key_path}" 4096 2>/dev/null

    # Generate public key from private key
    openssl rsa -in "${private_key_path}" -pubout -out "${private_key_path}.pub" 2>/dev/null

    # Set permissions
    chmod 600 "${private_key_path}"
    chmod 644 "${private_key_path}.pub"

    echo -e "${GREEN}  ✅ ${key_name} created${NC}"
}

# Generate web keys
echo -e "${BLUE}🔑 Generating web keys...${NC}"

# 1. Session signing key
generate_key_pair "$WEB_KEYS_DIR/session_signing_key" "session_signing_key"

# 2. TSA host key
generate_key_pair "$WEB_KEYS_DIR/tsa_host_key" "tsa_host_key"

echo -e "${GREEN}✅ Web keys generated${NC}"
echo ""

# Generate worker keys
echo -e "${BLUE}🔑 Generating worker keys...${NC}"

# 3. Worker key
generate_key_pair "$WORKER_KEYS_DIR/worker_key" "worker_key"

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
echo "  $WEB_KEYS_DIR/session_signing_key.pub"
echo "  $WEB_KEYS_DIR/tsa_host_key"
echo "  $WEB_KEYS_DIR/tsa_host_key.pub"
echo "  $WEB_KEYS_DIR/authorized_worker_keys"
echo ""
echo -e "${YELLOW}Worker keys (used by concourse-worker):${NC}"
echo "  $WORKER_KEYS_DIR/worker_key"
echo "  $WORKER_KEYS_DIR/worker_key.pub"
echo "  $WORKER_KEYS_DIR/tsa_host_key.pub"
echo ""
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${YELLOW}⚠️  IMPORTANT SECURITY NOTES:${NC}"
echo -e "${YELLOW}  1. These keys are git-ignored (see .gitignore)${NC}"
echo -e "${YELLOW}  2. Keep these keys secure - they control access to your CI/CD${NC}"
echo -e "${YELLOW}  3. Never commit these keys to version control${NC}"
echo -e "${YELLOW}  4. Regenerate keys if compromised${NC}"
echo -e "${YELLOW}  5. Keys generated with OpenSSL (RSA 4096-bit)${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${GREEN}🚀 Next steps:${NC}"
echo -e "   ${BLUE}1. Copy .env.example to .env and configure it${NC}"
echo -e "   ${BLUE}2. Start Concourse: cd $CONCOURSE_DIR && docker-compose up -d${NC}"
echo -e "   ${BLUE}3. Access Web UI: http://localhost:8080${NC}"
echo ""
