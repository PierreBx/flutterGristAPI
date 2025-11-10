# Concourse CI/CD Quick Start Guide

Get your Concourse CI/CD pipeline running in **5-10 minutes**.

## Prerequisites

- ✅ Docker installed and running
- ✅ Docker Compose installed
- ✅ 4GB+ free RAM
- ✅ SSH access to your Raspberry Pi (for deployment)

## Quick Setup (5 Steps)

### Step 1: Run Setup Script (2 minutes)

```bash
cd deployment-module/concourse
./scripts/setup.sh
```

This will:
- Generate SSH keys for Concourse
- Create `.env` configuration file
- Start Concourse services (web, worker, database)
- Install `fly` CLI tool
- Login to Concourse

**Action Required:** Edit `.env` if you want to change the default passwords:
```bash
nano .env  # Change CONCOURSE_PASSWORD if desired
```

### Step 2: Configure Deployment Credentials (2 minutes)

```bash
cp credentials.yml.example credentials.yml
nano credentials.yml
```

**Minimum required fields:**
```yaml
raspberry-pi-host: 192.168.1.100  # Your Raspberry Pi IP
raspberry-pi-user: appuser          # SSH user on Pi
ssh-private-key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  # Paste your SSH private key here
  # (The public key must be in ~/.ssh/authorized_keys on the Pi)
  -----END OPENSSH PRIVATE KEY-----
```

**Tip:** Generate a dedicated deployment key:
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/concourse_deploy_key -C "concourse-deploy"
ssh-copy-id -i ~/.ssh/concourse_deploy_key.pub appuser@192.168.1.100
# Then paste the private key (~/.ssh/concourse_deploy_key) into credentials.yml
```

### Step 3: Deploy Pipeline (1 minute)

```bash
./scripts/deploy-pipeline.sh
```

This uploads your CI/CD pipeline configuration to Concourse.

### Step 4: Access Web UI

Open in your browser:
```
http://localhost:8080
```

**Login:**
- Username: `admin` (or value from `.env`)
- Password: `admin` (or value from `.env`)

You should see the `flutter-grist` pipeline!

### Step 5: Trigger Your First Build (30 seconds)

**Option A: Via Web UI**
1. Go to http://localhost:8080
2. Click on `flutter-grist` pipeline
3. Click on `quality-checks` job
4. Click the ➕ button (top right) to trigger

**Option B: Via Command Line**
```bash
./scripts/trigger-build.sh quality-checks --watch
```

This will:
1. Run `flutter analyze` on your code
2. Run all 77 unit tests
3. Report results in real-time

## What Happens Now?

### Automatic Testing on Every Commit

The pipeline automatically runs when you push to the `main` branch:

```bash
git add .
git commit -m "Add new feature"
git push origin main
# → Concourse automatically runs tests
```

### Manual Deployment to Raspberry Pi

When tests pass, you can deploy to production:

```bash
./scripts/trigger-build.sh deploy-production --watch
```

Or click the ➕ button on the `deploy-production` job in the Web UI.

This will:
1. Run Ansible playbook
2. Deploy application to Raspberry Pi
3. Run health checks
4. Report status

## Common Commands

### View Pipeline Status
```bash
fly -t local pipelines
```

### Watch a Running Build
```bash
fly -t local watch -j flutter-grist/quality-checks
```

### View Build History
```bash
fly -t local builds
```

### Pause Pipeline
```bash
fly -t local pause-pipeline -p flutter-grist
```

### Unpause Pipeline
```bash
fly -t local unpause-pipeline -p flutter-grist
```

### View Logs
```bash
docker compose logs -f concourse-web
docker compose logs -f concourse-worker
```

## Troubleshooting

### Services Not Starting

```bash
# Check container status
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose restart
```

### Cannot Login with fly

```bash
# Check Web UI is accessible
curl http://localhost:8080/api/v1/info

# Re-login
fly -t local login -c http://localhost:8080 -u admin -p admin
```

### Pipeline Not Triggering on Git Push

1. Check the pipeline is unpaused:
   ```bash
   fly -t local unpause-pipeline -p flutter-grist
   ```

2. Verify git resource is configured correctly in `pipeline.yml`:
   ```yaml
   resources:
     - name: source-code
       type: git
       source:
         uri: https://github.com/YOUR-USERNAME/flutterGristAPI.git
         branch: main
   ```

3. Check for new commits:
   ```bash
   fly -t local check-resource -r flutter-grist/source-code
   ```

### SSH Connection Failed During Deployment

1. Test SSH manually:
   ```bash
   ssh -i ~/.ssh/concourse_deploy_key appuser@192.168.1.100
   ```

2. Verify SSH key is in `credentials.yml`

3. Check Raspberry Pi is powered on and accessible

## Next Steps

Now that Concourse is running:

1. **Customize the Pipeline**: Edit `pipeline.yml` to add more jobs
2. **Add Notifications**: Configure Slack/email notifications in `credentials.yml`
3. **Explore Tasks**: Check `tasks/` directory for reusable task definitions
4. **Read Full Docs**: See `README.md` for advanced configuration

## Quick Reference

| Action | Command |
|--------|---------|
| Start Concourse | `docker compose up -d` |
| Stop Concourse | `docker compose stop` |
| View Web UI | http://localhost:8080 |
| Trigger tests | `./scripts/trigger-build.sh quality-checks` |
| Trigger deployment | `./scripts/trigger-build.sh deploy-production` |
| View logs | `docker compose logs -f` |
| Cleanup everything | `./scripts/cleanup.sh --full` |

---

**Need help?** See the full [README.md](README.md) or check the [Concourse documentation](https://concourse-ci.org/docs.html).
