# Grist Module

This module contains everything needed to run Grist server in Docker with persistent data storage.

## Contents

- **docker-compose.yml** - Docker Compose configuration for Grist and Flutter services
- **Dockerfile** - Flutter development environment image
- **docker-test.sh** - Helper script for managing Docker services
- **grist-data/** - Persistent Grist data directory (gitignored except README)
- **.env.example** - Environment variable template
- **.dockerignore** - Files to exclude from Docker builds

## Quick Start

### First Time Setup

```bash
# From the grist-module directory
cd grist-module

# Copy environment template
cp .env.example .env

# Edit .env and set GRIST_SESSION_SECRET to a random string
nano .env

# Start Grist server
./docker-test.sh grist-start
```

Access Grist at: **http://localhost:8484**

### Daily Usage

```bash
# Start Grist
./docker-test.sh grist-start

# Stop Grist
./docker-test.sh grist-stop

# View logs
./docker-test.sh grist-logs

# Restart Grist
./docker-test.sh grist-restart
```

## Available Commands

### Grist Commands
- `./docker-test.sh grist-start` - Start Grist server
- `./docker-test.sh grist-stop` - Stop Grist server
- `./docker-test.sh grist-restart` - Restart Grist server
- `./docker-test.sh grist-logs` - View Grist logs (follow mode)

### Flutter Commands
- `./docker-test.sh test` - Run Flutter unit tests
- `./docker-test.sh analyze` - Run Flutter analyzer
- `./docker-test.sh all` - Run both analyze and test
- `./docker-test.sh shell` - Open interactive Flutter shell
- `./docker-test.sh build` - Build Flutter Docker image

### System Commands
- `./docker-test.sh start-all` - Start all services (Grist + Flutter)
- `./docker-test.sh stop-all` - Stop all services
- `./docker-test.sh clean` - Remove Docker containers and volumes ⚠️

## Data Persistence

Grist data is stored in `./grist-data/` and is mounted to `/persist` inside the container.

**Important:**
- This directory contains all your Grist documents
- It is excluded from git (except the README)
- Back it up regularly!

### Backup Grist Data

```bash
# Create timestamped backup
tar -czf ../backups/grist-backup-$(date +%Y%m%d-%H%M%S).tar.gz grist-data/
```

### Restore Grist Data

```bash
# Extract backup
tar -xzf grist-backup-YYYYMMDD-HHMMSS.tar.gz
```

## Environment Variables

Create a `.env` file from `.env.example`:

```bash
# Required: Session secret for Grist
GRIST_SESSION_SECRET=your-random-secret-here

# Optional: Public URL for Grist
GRIST_APP_HOME_URL=http://localhost:8484
```

## Network Configuration

All services are connected via `grist-network` Docker bridge network:
- **Grist container:** `grist:8484`
- **Flutter containers:** Can access Grist via `http://grist:8484`
- **Host machine:** Access Grist via `http://localhost:8484`

## Port Mappings

- **8484** - Grist web interface and API

## Troubleshooting

### Grist won't start

```bash
# Check logs
./docker-test.sh grist-logs

# Ensure .env exists
cp .env.example .env

# Restart
./docker-test.sh grist-restart
```

### Port 8484 already in use

```bash
# Find what's using the port
lsof -i :8484  # macOS/Linux
netstat -ano | findstr :8484  # Windows

# Stop conflicting service or change port in docker-compose.yml
```

### Data lost after cleanup

The `clean` command removes volumes. Use `stop-all` instead to preserve data.

## Documentation

For detailed documentation, see:
- **../documentation-module/QUICKSTART.md** - First-time setup guide
- **../documentation-module/DAILY_USAGE.md** - Daily workflow
- **../documentation-module/README_DOCKER.md** - Detailed Docker docs
