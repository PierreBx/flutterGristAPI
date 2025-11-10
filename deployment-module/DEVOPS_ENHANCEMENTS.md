# DevOps Enhancements - Phase 1 Implementation

This document describes the newly implemented DevOps enhancements for the Flutter Grist API project.

## Overview

Phase 1 focuses on **Foundation** improvements covering:
1. ✅ Test Coverage Reporting
2. ✅ Automated Backups & Recovery
3. ✅ SSL/TLS Automation
4. ✅ Secrets Scanning

---

## 1. Test Coverage Reporting

### What's New
- Automated test coverage report generation in CI pipeline
- Coverage percentage calculation and threshold enforcement
- HTML coverage reports for detailed analysis
- Integrated into Concourse `quality-checks` job

### How to Use

**View Coverage in CI:**
The coverage report runs automatically on every commit as part of the quality-checks job.

**Generate Coverage Locally:**
```bash
cd flutter-module
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # View in browser
```

**Coverage Threshold:**
- Current minimum: 60%
- Target: 80%+
- Located in: `deployment-module/concourse/pipeline.yml:177`

**What's Measured:**
- Line coverage
- Function coverage
- Branch coverage

### Configuration

To adjust the coverage threshold, edit `pipeline.yml`:
```yaml
MIN_COVERAGE=60.0  # Change this value
```

---

## 2. Automated Backup & Recovery

### What's New
- **Automated Backups:** Daily, weekly, and monthly backup schedules
- **Backup Verification:** Automatic integrity checks with SHA256 checksums
- **Configurable Retention:** Separate retention policies for each backup type
- **Easy Restore:** Simple restore script with verification
- **Multiple Destinations:** Support for local, remote, and cloud backups

### Backup Schedule

| Type | Frequency | Retention | Time |
|------|-----------|-----------|------|
| Daily | Every day | 7 days | 2:00 AM |
| Weekly | Every Sunday | 28 days | 2:00 AM |
| Monthly | 1st of month | 90 days | 2:00 AM |

### What's Backed Up
- Grist database data (`/opt/grist/data`)
- Application configuration (`/opt/flutter_grist_app/config`)
- Nginx configuration (`/etc/nginx`)
- SSL certificates (`/etc/letsencrypt`)

### How to Use

**Enable Backups in Deployment:**

Add the backup role to your playbook:
```yaml
# deployment-module/playbooks/configure_server.yml
- hosts: production
  roles:
    - common
    - security
    - docker
    - monitoring
    - backup  # Add this
    - ssl
    - app_environment
```

**Manual Backup Commands:**
```bash
# Create immediate backup
sudo /opt/scripts/backup.sh daily

# View backup statistics
sudo /opt/scripts/backup.sh stats

# View backup logs
sudo tail -f /var/log/backup.log
```

**Restore from Backup:**
```bash
# List available backups
sudo /opt/scripts/restore.sh --list

# Restore latest backup
sudo /opt/scripts/restore.sh --latest

# Restore specific backup
sudo /opt/scripts/restore.sh /opt/backups/daily/flutter_grist_backup_daily_20250110_020000.tar.gz
```

### Configuration

Customize backup settings in your inventory or playbook:
```yaml
# inventory/group_vars/production.yml
backup_base_dir: /opt/backups
backup_retention_daily: 7      # days
backup_retention_weekly: 28    # days
backup_retention_monthly: 90   # days
backup_cron_hour: "2"          # 2 AM
backup_cron_minute: "0"

# Optional: Remote backup
remote_backup_enabled: true
remote_backup_user: backup
remote_backup_host: backup.example.com
remote_backup_path: /backups/flutter-grist-api
```

### Backup Location
- Default: `/opt/backups/`
- Structure:
  ```
  /opt/backups/
  ├── daily/
  ├── weekly/
  ├── monthly/
  └── temp/
  ```

### Monitoring
- Backup logs: `/var/log/backup.log`
- Cron emails on failures (if configured)
- Automatic cleanup of old backups

---

## 3. SSL/TLS Automation

### What's New
- **Automated Certificate Issuance:** Let's Encrypt via certbot
- **Auto-Renewal:** Certificates renew automatically every 7 days
- **Strong Security:** TLS 1.2/1.3, strong ciphers, HSTS, OCSP stapling
- **Expiry Monitoring:** Daily checks with warnings
- **Zero Downtime:** Nginx reloads gracefully after renewal

### Security Features
- **TLS Protocols:** TLS 1.2 and 1.3 only (no SSLv3, TLS 1.0, TLS 1.1)
- **Strong Ciphers:** ECDHE, ChaCha20-Poly1305, AES-GCM
- **HSTS:** HTTP Strict Transport Security (1 year max-age)
- **OCSP Stapling:** Enabled for faster certificate validation
- **Security Headers:** X-Frame-Options, X-Content-Type-Options, etc.
- **HTTP → HTTPS Redirect:** All HTTP traffic redirected to HTTPS

### How to Use

**Enable SSL in Deployment:**

1. Add the SSL role to your playbook:
```yaml
# deployment-module/playbooks/configure_server.yml
- hosts: production
  roles:
    - common
    - security
    - docker
    - monitoring
    - backup
    - ssl  # Add this
    - app_environment

  vars:
    domain_name: your-domain.com        # REQUIRED
    admin_email: admin@your-domain.com  # REQUIRED
```

2. Run the playbook:
```bash
ansible-playbook -i inventory/hosts.yml playbooks/configure_server.yml
```

**Prerequisites:**
- Domain name pointing to your server's IP
- Port 80 open (for Let's Encrypt challenge)
- Port 443 open (for HTTPS traffic)
- Nginx installed and running

### Manual Commands

```bash
# Manual certificate renewal
sudo certbot renew

# Force renewal (for testing)
sudo certbot renew --force-renewal

# Check certificate expiry
sudo /opt/scripts/check-cert-expiry.sh your-domain.com

# Test Nginx configuration
sudo nginx -t

# View renewal logs
sudo tail -f /var/log/certbot-renew.log
```

### Configuration

Customize SSL settings in your inventory or playbook:
```yaml
# inventory/group_vars/production.yml
domain_name: your-domain.com
admin_email: admin@your-domain.com

# SSL settings (optional, defaults are secure)
ssl_protocols: "TLSv1.2 TLSv1.3"
ssl_hsts_enabled: true
ssl_hsts_max_age: 31536000  # 1 year
ssl_ocsp_stapling: true
ssl_generate_dhparam: true
ssl_expiry_warning_days: 30

# For testing (uses Let's Encrypt staging)
certbot_staging: false
```

### Certificate Locations
- Certificates: `/etc/letsencrypt/live/YOUR_DOMAIN/`
- Renewal config: `/etc/letsencrypt/renewal/YOUR_DOMAIN.conf`
- Logs: `/var/log/letsencrypt/`

### Monitoring
- Auto-renewal: Every 7 days at 3:00 AM
- Expiry check: Daily at 9:00 AM
- Warning threshold: 30 days before expiry

### Testing Your SSL

**Check SSL Grade:**
https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com

**Expected Grade:** A or A+

---

## 4. Secrets Scanning

### What's New
- **Automated Detection:** Scans for hardcoded secrets, API keys, passwords
- **CI Integration:** Runs on every commit in Concourse pipeline
- **Gitleaks:** Industry-standard tool for secrets detection
- **False Positive Handling:** `.gitleaksignore` file for known safe files

### What's Detected
- API keys and tokens
- Passwords and credentials
- Private keys (SSH, SSL)
- Database connection strings
- AWS credentials
- Generic secrets (high entropy strings)

### How to Use

**Automatic Scanning:**
The secrets scan runs automatically as part of the `quality-checks` job on every commit.

**Local Scanning:**
```bash
# Install gitleaks
wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.4/gitleaks_8.18.4_linux_x64.tar.gz
tar -xzf gitleaks_8.18.4_linux_x64.tar.gz

# Run scan
./gitleaks detect --source . --verbose
```

**Handling False Positives:**

Edit `.gitleaksignore` in the project root:
```
# Example files (not real secrets)
**/.env.example
**/credentials.yml.example

# Documentation
**/README*.md

# Test files
**/test/**
**/*_test.dart
```

### Configuration

Located in: `deployment-module/concourse/pipeline.yml:195-266`

The scan will **fail the build** if secrets are detected, preventing them from being committed.

### Best Practices
1. Never commit real credentials
2. Use environment variables for secrets
3. Use `.env.example` files with dummy values
4. Store production secrets in:
   - Ansible Vault
   - HashiCorp Vault
   - AWS Secrets Manager
   - Environment variables

---

## Implementation Details

### Files Created/Modified

**Concourse Pipeline:**
- `deployment-module/concourse/pipeline.yml` (updated)
  - Added test coverage task
  - Added secrets scanning task

**Backup Role:**
- `deployment-module/roles/backup/tasks/main.yml`
- `deployment-module/roles/backup/templates/backup.sh.j2`
- `deployment-module/roles/backup/templates/restore.sh.j2`
- `deployment-module/roles/backup/templates/backup.conf.j2`
- `deployment-module/roles/backup/templates/backup-logrotate.j2`
- `deployment-module/roles/backup/defaults/main.yml`

**SSL Role:**
- `deployment-module/roles/ssl/tasks/main.yml`
- `deployment-module/roles/ssl/templates/nginx-ssl.conf.j2`
- `deployment-module/roles/ssl/templates/nginx-pre-ssl.conf.j2`
- `deployment-module/roles/ssl/templates/check-cert-expiry.sh.j2`
- `deployment-module/roles/ssl/defaults/main.yml`
- `deployment-module/roles/ssl/handlers/main.yml`

**Other:**
- `.gitleaksignore` (new)

---

## Quick Start

### 1. Update Your Concourse Pipeline
```bash
cd deployment-module/concourse
fly -t local set-pipeline -p flutter-grist -c pipeline.yml -l credentials.yml
fly -t local unpause-pipeline -p flutter-grist
```

### 2. Deploy Backup & SSL Roles

Edit your playbook:
```yaml
# playbooks/configure_server.yml
- hosts: production
  become: yes
  vars:
    domain_name: your-domain.com        # Set your domain
    admin_email: admin@your-domain.com  # Set your email
  roles:
    - common
    - security
    - docker
    - monitoring
    - backup     # NEW
    - ssl        # NEW
    - app_environment
```

Run deployment:
```bash
cd deployment-module
ansible-playbook -i inventory/hosts.yml playbooks/configure_server.yml
```

### 3. Verify Setup

```bash
# Check backups
ssh pi@raspberry-pi "sudo /opt/scripts/backup.sh stats"

# Check SSL
curl -I https://your-domain.com
sudo /opt/scripts/check-cert-expiry.sh your-domain.com

# Check coverage (in CI logs)
fly -t local watch -j flutter-grist/quality-checks
```

---

## Troubleshooting

### Test Coverage Issues

**Problem:** Coverage not generated
```bash
# Solution: Install lcov locally
sudo apt-get install lcov

# Verify Flutter can generate coverage
cd flutter-module
flutter test --coverage
ls -la coverage/
```

### Backup Issues

**Problem:** Permission denied
```bash
# Solution: Check directory permissions
sudo chown -R root:root /opt/backups
sudo chmod 750 /opt/backups
```

**Problem:** Backups too large
```yaml
# Solution: Adjust what's backed up
# Edit roles/backup/templates/backup.sh.j2
# Comment out sections you don't need
```

### SSL Issues

**Problem:** Let's Encrypt rate limit
```yaml
# Solution: Use staging during testing
certbot_staging: true
```

**Problem:** Domain not reachable
```bash
# Check DNS
nslookup your-domain.com

# Check firewall
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

**Problem:** Nginx fails to start
```bash
# Test configuration
sudo nginx -t

# View errors
sudo journalctl -u nginx -n 50
```

### Secrets Scanning Issues

**Problem:** False positives
```bash
# Solution: Add to .gitleaksignore
echo "path/to/false/positive.txt" >> .gitleaksignore
```

---

## Next Steps (Future Phases)

### Phase 2: Observability (Weeks 3-4)
- [ ] Centralized logging (Promtail + Loki)
- [ ] Metrics collection (Prometheus)
- [ ] Grafana dashboards
- [ ] Alerting (Slack/Email)
- [ ] Integration tests

### Phase 3: Advanced Deployment (Weeks 5-6)
- [ ] Blue-green deployment
- [ ] Performance testing (k6)
- [ ] Dependency scanning
- [ ] API documentation (OpenAPI)

### Phase 4: Polish (Weeks 7-8)
- [ ] E2E tests
- [ ] Chaos engineering
- [ ] Runbook documentation
- [ ] Team training

---

## Support

For issues or questions:
1. Check this documentation
2. Review logs in `/var/log/`
3. Check Ansible role defaults in `roles/*/defaults/main.yml`
4. Consult the main analysis: `DEVOPS_ENHANCEMENTS_ANALYSIS.md`

---

**Last Updated:** 2025-11-10
**Implementation Version:** 1.0 (Phase 1)
