#!/bin/bash
# Docker-based Ansible runner
# This script runs Ansible playbooks inside a Docker container,
# eliminating the need to install Ansible on your local machine.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Docker image name
IMAGE_NAME="flutter-grist-ansible"
IMAGE_TAG="latest"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to build the Docker image
build_image() {
    print_info "Building Ansible Docker image..."
    docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" "$SCRIPT_DIR"
    print_info "Image built successfully!"
}

# Function to check if image exists
image_exists() {
    docker images "${IMAGE_NAME}:${IMAGE_TAG}" | grep -q "${IMAGE_NAME}"
}

# Function to show help
show_help() {
    cat << EOF
Docker Ansible Runner for Flutter Grist Widgets Deployment

Usage: $0 [OPTIONS] [ANSIBLE_ARGS...]

OPTIONS:
  build           Build the Ansible Docker image
  shell           Start an interactive shell in the container
  ping            Test connection to servers
  help            Show this help message

EXAMPLES:
  # Build the Docker image (required first time)
  $0 build

  # Run the main playbook
  $0 playbooks/configure_server.yml

  # Run with check mode (dry-run)
  $0 playbooks/configure_server.yml --check

  # Run with specific tags
  $0 playbooks/configure_server.yml --tags "docker,app"

  # Test connection
  $0 ping

  # Interactive shell
  $0 shell

  # Verbose mode
  $0 playbooks/configure_server.yml -vv

NOTES:
  - Your SSH keys from ~/.ssh will be mounted into the container
  - The current directory and all subdirectories are accessible
  - Reports are saved to ./reports/

REQUIREMENTS:
  - Docker must be installed and running
  - SSH keys must be set up in ~/.ssh/
  - inventory/hosts.yml must be configured

EOF
}

# Main script logic
main() {
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed or not in PATH"
        exit 1
    fi

    # Handle special commands
    case "${1:-}" in
        help|--help|-h)
            show_help
            exit 0
            ;;
        build)
            build_image
            exit 0
            ;;
        shell)
            print_info "Starting interactive shell in Ansible container..."
            if ! image_exists; then
                print_warn "Image not found. Building..."
                build_image
            fi
            docker run --rm -it \
                -v "$SCRIPT_DIR:/ansible" \
                -v "$HOME/.ssh:/root/.ssh:ro" \
                -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
                "${IMAGE_NAME}:${IMAGE_TAG}" \
                /bin/bash
            exit 0
            ;;
        ping)
            print_info "Testing connection to servers..."
            if ! image_exists; then
                print_warn "Image not found. Building..."
                build_image
            fi
            docker run --rm \
                -v "$SCRIPT_DIR:/ansible" \
                -v "$HOME/.ssh:/root/.ssh:ro" \
                -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
                "${IMAGE_NAME}:${IMAGE_TAG}" \
                ansible all -m ping
            exit 0
            ;;
        "")
            print_error "No arguments provided"
            show_help
            exit 1
            ;;
    esac

    # Check if image exists, build if not
    if ! image_exists; then
        print_warn "Ansible Docker image not found. Building..."
        build_image
    fi

    # Run ansible-playbook with all arguments
    print_info "Running Ansible playbook in Docker container..."

    docker run --rm \
        -v "$SCRIPT_DIR:/ansible" \
        -v "$HOME/.ssh:/root/.ssh:ro" \
        -e ANSIBLE_CONFIG=/ansible/ansible.cfg \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        ansible-playbook "$@"
}

# Run main function with all arguments
main "$@"
