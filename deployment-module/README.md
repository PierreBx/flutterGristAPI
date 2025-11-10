# Deployment Module

This module provides Ansible automation for deploying and configuring the Flutter Grist Widgets application on a Raspberry Pi production server.

## Overview

The deployment module uses Ansible to automate server configuration, ensuring your Raspberry Pi production environment is properly set up with:

- **Base system configuration** (packages, timezone, locale, swap)
- **Security hardening** (SSH, firewall, fail2ban, automatic updates)
- **Docker environment** (Docker CE, Docker Compose)
- **Monitoring tools** (system health checks, log rotation)
- **Automated backups** ✨ NEW - Daily/weekly/monthly with retention policies
- **SSL/TLS automation** ✨ NEW - Let's Encrypt with auto-renewal
- **Application environment** (user, directories, nginx reverse proxy)

> 🎉 **New in Phase 1:** Enhanced with test coverage, automated backups, SSL/TLS, and secrets scanning!
> See [DEVOPS_ENHANCEMENTS.md](DEVOPS_ENHANCEMENTS.md) for details.

## Two Ways to Run Ansible

### Option 1: Docker-based (Recommended) ✨

**Pros:**
- ✅ No Ansible installation required on your laptop
- ✅ Consistent environment for all developers
- ✅ Isolated dependencies
- ✅ Works on any OS with Docker

**Requirements:**
- Docker installed and running
- SSH access to the Raspberry Pi
- SSH key-based authentication configured (~/.ssh/)

**Quick Start:**
```bash
cd deployment-module

# Configure your inventory (one-time setup)
cp inventory/hosts.example inventory/hosts.yml
vim inventory/hosts.yml  # Update with your Raspberry Pi IP

# Build the Docker image (one-time setup)
./docker-ansible.sh build

# Test connection
./docker-ansible.sh ping

# Run the full configuration
./docker-ansible.sh playbooks/configure_server.yml

# Dry run to see what would change
./docker-ansible.sh playbooks/configure_server.yml --check

# Run specific roles only
./docker-ansible.sh playbooks/configure_server.yml --tags "docker,app"
```

### Option 2: Local Ansible Installation

**Pros:**
- Direct control over Ansible version
- Slightly faster execution (no container overhead)

**Requirements:**
- Ansible 2.9 or higher installed on your machine
- Python 3.x
- SSH access to the Raspberry Pi

**Install Ansible:**
```bash
# On Ubuntu/Debian
sudo apt install ansible

# On macOS
brew install ansible

# On other systems, use pip
pip install ansible
```

**Quick Start:**
```bash
cd deployment-module

# Configure your inventory
cp inventory/hosts.example inventory/hosts.yml
vim inventory/hosts.yml

# Test connection
ansible all -m ping

# Run the configuration
ansible-playbook playbooks/configure_server.yml
```

## Prerequisites

### Raspberry Pi Requirements
- Raspberry Pi 3/4/5 with Raspberry Pi OS (Debian-based)
- SSH enabled and accessible
- User with sudo privileges
- Network connectivity

## Helper Script Commands

The `docker-ansible.sh` script provides convenient commands:

```bash
# Build the Docker image
./docker-ansible.sh build

# Test server connectivity
./docker-ansible.sh ping

# Run a playbook
./docker-ansible.sh playbooks/configure_server.yml [OPTIONS]

# Start an interactive shell
./docker-ansible.sh shell

# Show help
./docker-ansible.sh help
```

## Common Usage Examples

```bash
# Full configuration (Docker)
./docker-ansible.sh playbooks/configure_server.yml

# Dry run to see what would change (Docker)
./docker-ansible.sh playbooks/configure_server.yml --check --diff

# Verbose output (Docker)
./docker-ansible.sh playbooks/configure_server.yml -vv

# Run specific roles only (Docker)
./docker-ansible.sh playbooks/configure_server.yml --tags "common,security"

# Using local Ansible installation
ansible-playbook playbooks/configure_server.yml
ansible-playbook playbooks/configure_server.yml --check
ansible-playbook playbooks/configure_server.yml --tags "docker,app"
```

## Directory Structure

```
deployment-module/
├── Dockerfile                   # Docker image for Ansible
├── docker-ansible.sh           # Helper script to run Ansible in Docker
├── .dockerignore              # Docker build exclusions
├── ansible.cfg                # Ansible configuration
├── requirements.txt           # Python/Ansible dependencies
├── inventory/
│   ├── hosts.yml             # Server inventory (customize this)
│   └── hosts.example         # Example inventory file
├── playbooks/
│   └── configure_server.yml  # Main configuration playbook
├── roles/
│   ├── common/               # Base system configuration
│   ├── security/             # Security hardening
│   ├── docker/               # Docker installation
│   ├── monitoring/           # Monitoring tools
│   └── app_environment/      # Application setup
├── scripts/                  # Deployment helper scripts
├── reports/                  # Generated configuration reports
└── README.md                # This file
```

## Roles

### Common Role
**Tags:** `common`, `base`

Configures base system settings:
- Updates and upgrades packages
- Installs essential tools
- Sets timezone and locale
- Creates swap file
- Optimizes system parameters

### Security Role
**Tags:** `security`

Hardens server security:
- Configures SSH (disables root login, password auth)
- Sets up UFW firewall
- Installs and configures fail2ban
- Enables automatic security updates

### Docker Role
**Tags:** `docker`, `containers`

Installs Docker environment:
- Removes old Docker versions
- Installs Docker CE and Docker Compose
- Configures Docker daemon
- Adds application user to docker group

### Monitoring Role
**Tags:** `monitoring`

Sets up monitoring tools:
- Installs system monitoring utilities
- Creates health check scripts
- Configures log rotation

### Backup Role ✨ NEW
**Tags:** `backup`

Automated backup and recovery:
- Daily, weekly, and monthly backup schedules
- Configurable retention policies (7/28/90 days)
- Backup verification with SHA256 checksums
- Easy restore with verification
- Supports local, remote, and cloud destinations

**What's backed up:**
- Grist database data
- Application configuration
- Nginx configuration
- SSL certificates

**Commands:**
```bash
sudo /opt/scripts/backup.sh daily      # Manual backup
sudo /opt/scripts/restore.sh --latest  # Restore latest
sudo /opt/scripts/backup.sh stats      # View statistics
```

### SSL Role ✨ NEW
**Tags:** `ssl`

SSL/TLS automation with Let's Encrypt:
- Automated certificate issuance
- Auto-renewal every 7 days
- Strong security (TLS 1.2/1.3, HSTS, OCSP)
- Certificate expiry monitoring
- HTTP → HTTPS redirect

**Requirements:**
- `domain_name` variable set
- `admin_email` variable set
- DNS pointing to server
- Ports 80 and 443 open

**Commands:**
```bash
sudo certbot renew                                # Manual renewal
sudo /opt/scripts/check-cert-expiry.sh DOMAIN     # Check expiry
```

### App Environment Role
**Tags:** `app`, `environment`

Prepares application environment:
- Creates application user and directories
- Installs nginx reverse proxy
- Creates environment file template
- Sets up application structure

## Configuration Variables

Key variables you can customize in `inventory/hosts.yml`:

```yaml
# Server settings
server_timezone: "Europe/Paris"
server_locale: "en_US.UTF-8"

# SSH settings
ssh_port: 22
ssh_permit_root_login: "no"
ssh_password_authentication: "no"

# Application settings
app_name: "flutter_grist_app"
app_user: "appuser"
app_home: "/opt/flutter_grist_app"
deployment_env: "production"
```

## Advanced Usage Examples

### Run specific tasks with tags

```bash
# Docker version
./docker-ansible.sh playbooks/configure_server.yml --tags "packages"
./docker-ansible.sh playbooks/configure_server.yml --tags "security"
./docker-ansible.sh playbooks/configure_server.yml --tags "docker,app"

# Local Ansible version
ansible-playbook playbooks/configure_server.yml --tags "packages"
ansible-playbook playbooks/configure_server.yml --tags "security"
ansible-playbook playbooks/configure_server.yml --tags "docker,app"
```

### Check what would change (dry-run)

```bash
# Docker version
./docker-ansible.sh playbooks/configure_server.yml --check --diff

# Local Ansible version
ansible-playbook playbooks/configure_server.yml --check --diff
```

### Run with elevated verbosity

```bash
# Docker version
./docker-ansible.sh playbooks/configure_server.yml -vvv

# Local Ansible version
ansible-playbook playbooks/configure_server.yml -vvv
```

## Post-Configuration Steps

After running the playbook:

1. **Configure application environment:**
   ```bash
   ssh pi@your-raspberry-pi-ip
   sudo su - appuser
   cd /opt/flutter_grist_app/config
   cp .env.example .env
   vim .env  # Update with your Grist API credentials
   ```

2. **Deploy your application:**
   - Upload your Flutter application build to `/opt/flutter_grist_app/`
   - Create a docker-compose.yml for your app
   - Start your application

3. **Verify services:**
   ```bash
   # Check Docker
   docker --version
   docker ps

   # Check nginx
   sudo systemctl status nginx

   # Check firewall
   sudo ufw status

   # Run health check
   sudo /opt/monitoring/health_check.sh
   ```

## Troubleshooting

### Docker Build Issues

```bash
# Rebuild the image from scratch
./docker-ansible.sh build

# Check if Docker is running
docker ps

# Check Docker logs
docker logs <container-id>
```

### Connection Issues

```bash
# Test SSH connection
ssh pi@your-raspberry-pi-ip

# Test Ansible connection (Docker)
./docker-ansible.sh ping

# Test Ansible connection (Local)
ansible all -m ping -vvv

# Check SSH keys are mounted correctly (Docker)
./docker-ansible.sh shell
ls -la /root/.ssh/
```

### Permission Issues

Ensure your user has sudo privileges:
```bash
# On Raspberry Pi
sudo visudo
# Add: pi ALL=(ALL) NOPASSWD:ALL
```

### Docker Issues

```bash
# On Raspberry Pi, check Docker status
sudo systemctl status docker

# Test Docker
docker run --rm hello-world
```

### View Ansible Logs

```bash
cat ansible.log
```

## Security Notes

- SSH password authentication is disabled by default
- Root login is disabled
- UFW firewall is enabled (only SSH, HTTP, HTTPS allowed)
- fail2ban protects against brute force attacks
- Automatic security updates are enabled

## Next Steps

1. ✅ ~~Configure SSL/TLS~~ - Now automated with the `ssl` role!
2. ✅ ~~Configure backup scripts~~ - Now automated with the `backup` role!
3. Set up application deployment automation
4. Set up monitoring alerts (Phase 2)
5. Configure centralized logging (Phase 2)
6. Set up metrics and dashboards (Phase 2)

See [DEVOPS_ENHANCEMENTS_ANALYSIS.md](../DEVOPS_ENHANCEMENTS_ANALYSIS.md) for the complete roadmap.

## Contributing

When adding new roles or playbooks:
1. Follow Ansible best practices
2. Use tags for granular control
3. Document all variables
4. Test thoroughly on a test Raspberry Pi first

## License

This deployment module is part of the Flutter Grist Widgets project and follows the same MIT license.
