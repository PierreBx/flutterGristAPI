#!/bin/bash

# =============================================================================
# Trigger Build Script
# =============================================================================
# Manually triggers a Concourse pipeline job
#
# Usage:
#   ./trigger-build.sh [job-name] [--watch]
#
# Examples:
#   ./trigger-build.sh                      # Trigger quality-checks
#   ./trigger-build.sh quality-checks       # Trigger quality-checks explicitly
#   ./trigger-build.sh deploy-production    # Trigger deployment
#   ./trigger-build.sh quality-checks -w    # Trigger and watch output
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

# Default values
PIPELINE_NAME="flutter-grist"
JOB_NAME="${1:-quality-checks}"
WATCH_FLAG=""

# Check if second argument is --watch or -w
if [ "$2" = "--watch" ] || [ "$2" = "-w" ]; then
    WATCH_FLAG="-w"
fi

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}🚀 Triggering Concourse Build${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""

# Check if fly exists
FLY_CMD=""
if [ -f "$CONCOURSE_DIR/fly" ]; then
    FLY_CMD="$CONCOURSE_DIR/fly"
elif command -v fly &> /dev/null; then
    FLY_CMD="fly"
else
    echo -e "${RED}❌ Error: fly CLI not found${NC}"
    echo "Please run ./setup.sh first to install fly CLI"
    exit 1
fi

# Check if logged in
if ! $FLY_CMD -t local status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not logged in to Concourse${NC}"
    echo "Logging in..."
    echo ""

    # Load credentials
    if [ -f "$CONCOURSE_DIR/.env" ]; then
        source "$CONCOURSE_DIR/.env"
    fi

    $FLY_CMD -t local login \
        -c http://localhost:8080 \
        -u "${CONCOURSE_USERNAME:-admin}" \
        -p "${CONCOURSE_PASSWORD:-admin}"

    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Login failed${NC}"
        exit 1
    fi
    echo ""
fi

# Trigger job
echo -e "${BLUE}Pipeline: ${YELLOW}$PIPELINE_NAME${NC}"
echo -e "${BLUE}Job: ${YELLOW}$JOB_NAME${NC}"
if [ -n "$WATCH_FLAG" ]; then
    echo -e "${BLUE}Mode: ${YELLOW}Trigger and watch${NC}"
else
    echo -e "${BLUE}Mode: ${YELLOW}Trigger only${NC}"
fi
echo ""

echo -e "${BLUE}Triggering build...${NC}"
$FLY_CMD -t local trigger-job -j "$PIPELINE_NAME/$JOB_NAME" $WATCH_FLAG

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Build triggered successfully${NC}"
    echo ""

    if [ -z "$WATCH_FLAG" ]; then
        echo -e "${BLUE}View build status:${NC}"
        echo -e "  Web UI: ${GREEN}http://localhost:8080/teams/main/pipelines/$PIPELINE_NAME/jobs/$JOB_NAME${NC}"
        echo -e "  CLI: ${YELLOW}$FLY_CMD -t local watch -j $PIPELINE_NAME/$JOB_NAME${NC}"
    fi
else
    echo ""
    echo -e "${RED}❌ Failed to trigger build${NC}"
    exit 1
fi

echo ""
