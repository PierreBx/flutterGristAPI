# Ansible Docker Container for Deployment
# This Dockerfile creates a containerized Ansible environment for deploying
# the Flutter Grist Widgets application to production servers.

FROM python:3.11-slim

LABEL maintainer="Flutter Grist Widgets"
LABEL description="Ansible deployment container for Raspberry Pi configuration"

# Set working directory
WORKDIR /ansible

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openssh-client \
    sshpass \
    git \
    rsync \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy Ansible configuration and playbooks
COPY ansible.cfg ./
COPY playbooks/ ./playbooks/
COPY roles/ ./roles/
COPY inventory/ ./inventory/

# Create directory for SSH keys
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# Create reports directory
RUN mkdir -p /ansible/reports

# Set environment variables
ENV ANSIBLE_CONFIG=/ansible/ansible.cfg
ENV ANSIBLE_FORCE_COLOR=true
ENV ANSIBLE_HOST_KEY_CHECKING=false

# Default command shows help
CMD ["ansible-playbook", "--version"]
