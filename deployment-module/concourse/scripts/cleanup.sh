#!/bin/bash

# =============================================================================
# Cleanup Script
# =============================================================================
# Stops and optionally removes all Concourse services and data
#
# Usage:
#   ./cleanup.sh [--full]
#
# Options:
#   --full    Remove all data including volumes and keys (cannot be undone)
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONCOURSE_DIR="$(dirname "$SCRIPT_DIR")"

FULL_CLEANUP=0
if [ "$1" = "--full" ]; then
    FULL_CLEANUP=1
fi

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}🧹 Concourse Cleanup${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""

# Detect docker-compose command
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

cd "$CONCOURSE_DIR"

if [ $FULL_CLEANUP -eq 1 ]; then
    echo -e "${RED}⚠️  WARNING: FULL CLEANUP MODE${NC}"
    echo ""
    echo "This will:"
    echo "  - Stop all Concourse containers"
    echo "  - Remove all containers"
    echo "  - Delete all volumes (database data, worker state)"
    echo "  - Delete generated SSH keys"
    echo "  - Delete .env file"
    echo ""
    echo -e "${RED}THIS CANNOT BE UNDONE!${NC}"
    echo ""
    read -p "Are you absolutely sure? Type 'yes' to continue: " -r
    echo ""

    if [ "$REPLY" != "yes" ]; then
        echo -e "${GREEN}Cleanup cancelled${NC}"
        exit 0
    fi

    echo -e "${BLUE}Stopping and removing Concourse services...${NC}"
    $DOCKER_COMPOSE down -v

    echo -e "${BLUE}Removing generated keys...${NC}"
    rm -rf keys/

    echo -e "${BLUE}Removing .env file...${NC}"
    rm -f .env

    echo -e "${BLUE}Removing fly CLI...${NC}"
    rm -f fly

    echo ""
    echo -e "${GREEN}✅ Full cleanup complete${NC}"
    echo ""
    echo "To set up Concourse again, run: ./scripts/setup.sh"

else
    echo -e "${BLUE}Stopping Concourse services...${NC}"
    $DOCKER_COMPOSE stop

    echo ""
    echo -e "${GREEN}✅ Concourse services stopped${NC}"
    echo ""
    echo "Services are stopped but not removed."
    echo ""
    echo -e "${BLUE}Available actions:${NC}"
    echo -e "  ${YELLOW}Start services:${NC}       $DOCKER_COMPOSE start"
    echo -e "  ${YELLOW}View stopped containers:${NC} $DOCKER_COMPOSE ps -a"
    echo -e "  ${YELLOW}Remove containers:${NC}    $DOCKER_COMPOSE down"
    echo -e "  ${YELLOW}Full cleanup:${NC}         ./scripts/cleanup.sh --full"
fi

echo ""
echo -e "${BLUE}==============================================================================${NC}"
echo ""
