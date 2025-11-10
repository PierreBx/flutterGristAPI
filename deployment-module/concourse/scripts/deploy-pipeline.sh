#!/bin/bash

# =============================================================================
# Deploy Pipeline Script
# =============================================================================
# Uploads the Concourse pipeline configuration to the Concourse server
#
# Usage:
#   ./deploy-pipeline.sh [pipeline-name]
#
# Examples:
#   ./deploy-pipeline.sh                    # Deploy main pipeline as 'flutter-grist'
#   ./deploy-pipeline.sh my-custom-pipeline # Deploy with custom name
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

# Pipeline name (default or from argument)
PIPELINE_NAME="${1:-flutter-grist}"

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}📤 Deploying Concourse Pipeline${NC}"
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

# Check if pipeline file exists
PIPELINE_FILE="$CONCOURSE_DIR/pipeline.yml"
if [ ! -f "$PIPELINE_FILE" ]; then
    echo -e "${RED}❌ Error: Pipeline file not found: $PIPELINE_FILE${NC}"
    exit 1
fi

# Check if credentials file exists
CREDENTIALS_FILE="$CONCOURSE_DIR/credentials.yml"
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo -e "${YELLOW}⚠️  Warning: credentials.yml not found${NC}"
    echo "Creating from template..."
    cp "$CONCOURSE_DIR/credentials.yml.example" "$CREDENTIALS_FILE"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT: Edit credentials.yml with your actual secrets before deploying!${NC}"
    echo ""
    read -p "Press Enter to continue after editing credentials.yml (or Ctrl+C to exit)..."
    echo ""
fi

# Deploy pipeline
echo -e "${BLUE}Deploying pipeline: ${YELLOW}$PIPELINE_NAME${NC}"
echo -e "${BLUE}Pipeline file: ${YELLOW}$PIPELINE_FILE${NC}"
echo -e "${BLUE}Credentials file: ${YELLOW}$CREDENTIALS_FILE${NC}"
echo ""

$FLY_CMD -t local set-pipeline \
    -p "$PIPELINE_NAME" \
    -c "$PIPELINE_FILE" \
    -l "$CREDENTIALS_FILE" \
    --non-interactive

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Pipeline deployed successfully${NC}"
else
    echo ""
    echo -e "${RED}❌ Failed to deploy pipeline${NC}"
    exit 1
fi

# Unpause pipeline (pipelines are paused by default)
echo ""
echo -e "${BLUE}Unpausing pipeline...${NC}"
$FLY_CMD -t local unpause-pipeline -p "$PIPELINE_NAME"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Pipeline unpaused${NC}"
else
    echo -e "${YELLOW}⚠️  Could not unpause pipeline${NC}"
fi

# Display summary
echo ""
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${GREEN}✅ Pipeline Deployment Complete!${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${BLUE}📊 Pipeline Info:${NC}"
echo -e "  Name: ${YELLOW}$PIPELINE_NAME${NC}"
echo -e "  Status: ${GREEN}Active${NC}"
echo -e "  Web UI: ${GREEN}http://localhost:8080/teams/main/pipelines/$PIPELINE_NAME${NC}"
echo ""
echo -e "${BLUE}🔧 Useful Commands:${NC}"
echo ""
echo -e "  ${YELLOW}View pipeline:${NC}"
echo -e "    $FLY_CMD -t local pipelines"
echo ""
echo -e "  ${YELLOW}Get pipeline config:${NC}"
echo -e "    $FLY_CMD -t local get-pipeline -p $PIPELINE_NAME"
echo ""
echo -e "  ${YELLOW}Trigger quality checks:${NC}"
echo -e "    $FLY_CMD -t local trigger-job -j $PIPELINE_NAME/quality-checks -w"
echo ""
echo -e "  ${YELLOW}Trigger deployment:${NC}"
echo -e "    $FLY_CMD -t local trigger-job -j $PIPELINE_NAME/deploy-production -w"
echo ""
echo -e "  ${YELLOW}Watch build:${NC}"
echo -e "    $FLY_CMD -t local watch -j $PIPELINE_NAME/quality-checks"
echo ""
echo -e "  ${YELLOW}Pause pipeline:${NC}"
echo -e "    $FLY_CMD -t local pause-pipeline -p $PIPELINE_NAME"
echo ""
echo -e "  ${YELLOW}Destroy pipeline:${NC}"
echo -e "    $FLY_CMD -t local destroy-pipeline -p $PIPELINE_NAME"
echo ""
echo -e "${BLUE}==============================================================================${NC}"
echo ""
echo -e "${GREEN}🚀 Next Steps:${NC}"
echo -e "  1. View the pipeline in the web UI: ${BLUE}http://localhost:8080${NC}"
echo -e "  2. Make a git commit to trigger automatic testing"
echo -e "  3. Or manually trigger: ${YELLOW}./scripts/trigger-build.sh${NC}"
echo ""
