# Concourse CI/CD for Flutter Grist Widgets

Automated testing and deployment pipeline for the Flutter Grist Widgets project.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Configuration](#configuration)
- [Pipeline Design](#pipeline-design)
- [Usage](#usage)
- [Advanced Topics](#advanced-topics)
- [Troubleshooting](#troubleshooting)

## Overview

This Concourse CI/CD setup provides:

✅ **Automated Testing** - Runs 77 unit tests + analysis on every commit
✅ **Deployment Automation** - One-click deploy to Raspberry Pi production
✅ **Visual Monitoring** - Real-time pipeline status in Web UI
✅ **Health Checks** - Automatic verification after deployment
✅ **Self-Hosted** - Runs on your laptop, no cloud dependencies

### Benefits

- **Time Savings**: 25+ minutes/day saved on manual testing/deployment
- **Quality Gates**: Broken code never reaches production
- **Consistent Builds**: Same Docker images in dev, CI, and prod
- **Fast Feedback**: Know within 2 minutes if your code works

### Pipeline Flow

```
Git Push (main branch)
    ↓
[quality-checks] (automatic, ~2 min)
    ├─ flutter analyze
    └─ flutter test (77 tests)
    ↓
[build] (manual, ~3 min)
    └─ flutter build web
    ↓
[deploy-production] (manual, ~5 min)
    ├─ ansible-playbook (deploy to Pi)
    ├─ health-check (verify deployment)
    └─ rollback (if health check fails)
```

## Quick Start

**Want to get started immediately?** See [QUICKSTART.md](QUICKSTART.md) (5-10 minutes).

**Manual setup:**

```bash
# 1. Setup Concourse
./scripts/setup.sh

# 2. Configure credentials
cp credentials.yml.example credentials.yml
# Edit with your SSH keys and Raspberry Pi details

# 3. Deploy pipeline
./scripts/deploy-pipeline.sh

# 4. Access Web UI
open http://localhost:8080
# Username: admin, Password: (see .env)

# 5. Trigger first build
./scripts/trigger-build.sh quality-checks --watch
```

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                    LAPTOP (localhost)                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Concourse Web (:8080)                               │   │
│  │  - Web UI dashboard                                  │   │
│  │  - API server                                        │   │
│  │  - Pipeline scheduler                                │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Concourse Worker (privileged)                       │   │
│  │  - Executes pipeline tasks                           │   │
│  │  - Runs Docker containers                            │   │
│  │  - Manages build resources                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PostgreSQL (:5432)                                  │   │
│  │  - Pipeline state                                    │   │
│  │  - Build history                                     │   │
│  │  - Resource versions                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ SSH (port 22)
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              RASPBERRY PI (Production)                       │
├─────────────────────────────────────────────────────────────┤
│  - Flutter Grist Application                                │
│  - Grist Server                                             │
│  - Nginx reverse proxy                                      │
│  - Monitoring tools                                         │
└─────────────────────────────────────────────────────────────┘
```

### Resource Requirements

| Component | CPU | RAM | Disk |
|-----------|-----|-----|------|
| concourse-web | 0.5 core | 512MB | 100MB |
| concourse-worker | 2-4 cores | 2-4GB | 5GB |
| concourse-db | 0.5 core | 256MB | 1GB |
| **Total** | **3-5 cores** | **2.5-4.5GB** | **~6GB** |

## Directory Structure

```
concourse/
├── README.md                      # This file
├── QUICKSTART.md                  # 5-minute setup guide
├── docker-compose.yml             # Service definitions
├── .env.example                   # Environment template
├── .gitignore                     # Excludes secrets from git
├── pipeline.yml                   # Main CI/CD pipeline
├── credentials.yml.example        # Secrets template
│
├── keys/                          # SSH keys (git-ignored)
│   ├── web/
│   │   ├── session_signing_key
│   │   ├── tsa_host_key
│   │   └── authorized_worker_keys
│   └── worker/
│       ├── worker_key
│       └── tsa_host_key.pub
│
├── tasks/                         # Reusable task definitions
│   ├── flutter-analyze.yml
│   ├── flutter-test.yml
│   ├── deploy-ansible.yml
│   └── health-check.yml
│
├── scripts/                       # Helper scripts
│   ├── setup.sh                   # Complete setup
│   ├── generate-keys-openssl.sh   # Key generation
│   ├── deploy-pipeline.sh         # Upload pipeline
│   ├── trigger-build.sh           # Manual triggers
│   └── cleanup.sh                 # Cleanup/removal
│
└── pipelines/                     # Additional pipelines
    ├── test-only.yml              # Test without deploy
    ├── deploy-staging.yml         # Staging environment
    └── rollback.yml               # Emergency rollback
```

## Configuration

### Environment Variables (.env)

```bash
# Database
CONCOURSE_POSTGRES_PASSWORD=your_secure_password

# Authentication
CONCOURSE_USERNAME=admin
CONCOURSE_PASSWORD=your_secure_password

# Deployment target
RASPBERRY_PI_HOST=192.168.1.100
RASPBERRY_PI_USER=appuser

# Git repository
GIT_REPO_URI=https://github.com/PierreBx/flutterGristAPI.git
GIT_BRANCH=main
```

### Pipeline Credentials (credentials.yml)

**Required fields:**

```yaml
# SSH access to Raspberry Pi
raspberry-pi-host: 192.168.1.100
raspberry-pi-user: appuser
ssh-private-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ... your deployment key ...
  -----END OPENSSH PRIVATE KEY-----

# Git repository access (for private repos)
github-private-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ... your git SSH key ...
  -----END OPENSSH PRIVATE KEY-----
```

**Optional fields:**

```yaml
# Docker Hub (for pushing images)
docker-registry-username: your-username
docker-registry-password: your-password

# Slack notifications
slack-webhook-url: https://hooks.slack.com/services/...

# Email notifications
smtp-host: smtp.gmail.com
smtp-username: your-email@gmail.com
smtp-password: your-app-password
```

## Pipeline Design

### Jobs

#### 1. quality-checks (automatic)

**Triggers:** On every commit to `main` branch
**Duration:** ~2 minutes
**Tasks:**
- `flutter-analyze`: Static code analysis
- `flutter-test`: Run 77 unit tests

**On Success:** Enables build and deployment jobs
**On Failure:** Blocks deployment, notifies team

#### 2. build (manual)

**Triggers:** Manual only
**Duration:** ~3 minutes
**Tasks:**
- `flutter build web --release`

**Outputs:** Build artifacts for deployment

#### 3. deploy-production (manual)

**Triggers:** Manual only (must pass quality-checks first)
**Duration:** ~5 minutes
**Tasks:**
- `ansible-deploy`: Runs Ansible playbook on Raspberry Pi
- `health-check`: Verifies deployment success

**On Success:** Application deployed and healthy
**On Failure:** Alerts team, optionally triggers rollback

### Resources

**source-code** (git)
- Type: `git`
- Checks every: 1 minute
- Branch: `main`

**flutter-image** (docker)
- Type: `registry-image`
- Repository: `instrumentisto/flutter:latest`

### Task Caching

Tasks cache the following for faster builds:
- `.dart_tool/` - Flutter build cache
- `/root/.pub-cache` - Pub dependency cache

**Cache hit:** ~30s faster builds
**Cache miss:** Downloads dependencies (~2-3 minutes)

## Usage

### Daily Workflow

**Development:**
```bash
# 1. Work on feature
git checkout -b feature/new-widget
# ... edit code ...

# 2. Test locally (optional)
cd flutter-module
flutter test

# 3. Commit and push
git add .
git commit -m "Add new widget"
git push origin feature/new-widget
```

**After Merge to Main:**
```bash
# Concourse automatically:
# 1. Detects new commit
# 2. Runs quality-checks job
# 3. Shows results in Web UI (http://localhost:8080)
```

**Deploying to Production:**
```bash
# Option 1: Web UI
# Go to http://localhost:8080
# Click deploy-production job
# Click ➕ button

# Option 2: Command line
./scripts/trigger-build.sh deploy-production --watch
```

### Monitoring Builds

**Web UI (recommended):**
```
http://localhost:8080/teams/main/pipelines/flutter-grist
```

**Command Line:**
```bash
# List all pipelines
fly -t local pipelines

# Watch a specific job
fly -t local watch -j flutter-grist/quality-checks

# View build history
fly -t local builds

# Get build logs
fly -t local watch -j flutter-grist/quality-checks -b 42
```

### Pipeline Management

**Update pipeline:**
```bash
# Edit pipeline.yml
nano pipeline.yml

# Redeploy
./scripts/deploy-pipeline.sh
```

**Pause/unpause:**
```bash
# Pause (stops automatic triggers)
fly -t local pause-pipeline -p flutter-grist

# Unpause
fly -t local unpause-pipeline -p flutter-grist
```

**Remove pipeline:**
```bash
fly -t local destroy-pipeline -p flutter-grist
```

## Advanced Topics

### Custom Task Definitions

Create reusable tasks in `tasks/`:

```yaml
# tasks/my-custom-task.yml
platform: linux

image_resource:
  type: registry-image
  source:
    repository: alpine
    tag: latest

inputs:
  - name: source-code

run:
  path: /bin/sh
  args:
    - -ec
    - |
      echo "Running custom task..."
      cd source-code
      # Your commands here
```

**Use in pipeline:**
```yaml
jobs:
  - name: my-job
    plan:
      - get: source-code
      - task: my-custom-task
        file: source-code/deployment-module/concourse/tasks/my-custom-task.yml
```

### Multiple Environments

**Create staging pipeline:**

```bash
cp pipeline.yml pipelines/staging-pipeline.yml
# Edit to use staging Raspberry Pi

fly -t local set-pipeline -p flutter-grist-staging \
    -c pipelines/staging-pipeline.yml \
    -l credentials.yml
```

### Notifications

**Slack integration:**

1. Create Slack webhook: https://api.slack.com/messaging/webhooks
2. Add to `credentials.yml`:
   ```yaml
   slack-webhook-url: https://hooks.slack.com/services/...
   ```
3. Add notification task to pipeline:
   ```yaml
   on_success:
     task: notify-slack
     config:
       platform: linux
       params:
         SLACK_WEBHOOK: ((slack-webhook-url))
       # ... send message to Slack
   ```

### Secrets Management with Vault

For production, use HashiCorp Vault instead of `credentials.yml`:

```bash
# Install Vault
# Configure Concourse web with Vault connection
export CONCOURSE_VAULT_URL=https://vault.example.com
export CONCOURSE_VAULT_AUTH_BACKEND=cert

# Store secrets in Vault
vault kv put concourse/main/flutter-grist/raspberry-pi-host "192.168.1.100"
vault kv put concourse/main/flutter-grist/ssh-private-key @/path/to/key

# Reference in pipeline (same syntax)
params:
  HOST: ((raspberry-pi-host))  # Fetched from Vault
```

## Troubleshooting

### Services Won't Start

**Symptom:** `docker compose up -d` fails

**Solutions:**
```bash
# Check ports not in use
lsof -i :8080
lsof -i :5432

# Check Docker is running
docker ps

# View error logs
docker compose logs

# Remove old containers
docker compose down -v
./scripts/setup.sh  # Start fresh
```

### Worker Cannot Connect to Web

**Symptom:** Worker shows "failed to register" in logs

**Solutions:**
```bash
# Check keys are correctly generated
ls -la keys/web/
ls -la keys/worker/

# Regenerate keys
./scripts/generate-keys-openssl.sh

# Restart services
docker compose restart
```

### Pipeline Not Triggering

**Symptom:** New commits don't trigger builds

**Solutions:**
```bash
# 1. Check pipeline is unpaused
fly -t local unpause-pipeline -p flutter-grist

# 2. Manually trigger resource check
fly -t local check-resource -r flutter-grist/source-code

# 3. Verify git resource configuration
fly -t local get-pipeline -p flutter-grist | grep -A 10 "source-code"

# 4. Check worker logs
docker compose logs -f concourse-worker
```

### SSH Deployment Fails

**Symptom:** `ansible-deploy` task fails with SSH error

**Solutions:**
```bash
# 1. Test SSH manually
ssh -i ~/.ssh/concourse_deploy_key appuser@192.168.1.100

# 2. Verify SSH key in credentials.yml is correct
cat credentials.yml | grep -A 10 "ssh-private-key"

# 3. Check Raspberry Pi is reachable
ping 192.168.1.100

# 4. Verify firewall allows SSH
# On Raspberry Pi:
sudo ufw status
```

### High Resource Usage

**Symptom:** Laptop fans loud, high CPU/RAM

**Solutions:**
```bash
# 1. Limit worker resources in docker-compose.yml
deploy:
  resources:
    limits:
      cpus: '2'      # Reduce from 4
      memory: 2G     # Reduce from 4G

# 2. Stop when not needed
docker compose stop

# 3. Clean up old builds
fly -t local prune-worker -w local-worker
```

## Common Tasks Cheat Sheet

| Task | Command |
|------|---------|
| **Setup & Maintenance** | |
| Initial setup | `./scripts/setup.sh` |
| Start Concourse | `docker compose up -d` |
| Stop Concourse | `docker compose stop` |
| Restart Concourse | `docker compose restart` |
| View logs | `docker compose logs -f` |
| Full cleanup | `./scripts/cleanup.sh --full` |
| **Pipeline Management** | |
| Deploy pipeline | `./scripts/deploy-pipeline.sh` |
| List pipelines | `fly -t local pipelines` |
| Get pipeline config | `fly -t local get-pipeline -p flutter-grist` |
| Pause pipeline | `fly -t local pause-pipeline -p flutter-grist` |
| Unpause pipeline | `fly -t local unpause-pipeline -p flutter-grist` |
| Destroy pipeline | `fly -t local destroy-pipeline -p flutter-grist` |
| **Build Management** | |
| Trigger quality checks | `./scripts/trigger-build.sh quality-checks` |
| Trigger deployment | `./scripts/trigger-build.sh deploy-production` |
| Watch running build | `fly -t local watch -j flutter-grist/quality-checks` |
| View build history | `fly -t local builds` |
| Abort build | `fly -t local abort-build -j flutter-grist/quality-checks -b 42` |
| **Resources** | |
| Check for new commits | `fly -t local check-resource -r flutter-grist/source-code` |
| List resource versions | `fly -t local resource-versions -r flutter-grist/source-code` |

## Resources & Documentation

- **Concourse Official Docs**: https://concourse-ci.org/docs.html
- **Concourse Tutorial**: https://concoursetutorial.com/
- **Docker Compose Docs**: https://docs.docker.com/compose/
- **Fly CLI Reference**: https://concourse-ci.org/fly.html
- **Pipeline Mechanics**: https://concourse-ci.org/pipelines.html
- **Concourse Examples**: https://github.com/concourse/examples

## Support

**Issues with this setup:**
- Check the [Troubleshooting](#troubleshooting) section
- View Concourse logs: `docker compose logs -f`
- Check analysis document: `CONCOURSE_ANALYSIS.md`

**Concourse platform issues:**
- Concourse GitHub: https://github.com/concourse/concourse/issues
- Concourse Discord: https://discord.gg/MeRxXKW

---

**Version**: 1.0
**Last Updated**: 2025-11-10
**Maintainer**: Development Team
