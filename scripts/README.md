# Observable Framework Container Access Scripts

This directory contains scripts for connecting to and managing the Observable Framework container for live dashboard editing.

## Scripts Overview

### 1. `teleport-observable-connect.sh`
Full-featured Teleport-based container access script with comprehensive functionality.

### 2. `observable-dashboard-manager.sh`
Simplified dashboard management script that auto-detects kubectl vs Teleport.

## Prerequisites

- **Teleport Client** (for teleport-observable-connect.sh):
  ```bash
  # Install Teleport client
  curl -O https://get.gravitational.com/teleport-v12.4.8-linux-amd64-bin.tar.gz
  tar -xzf teleport-v12.4.8-linux-amd64-bin.tar.gz
  sudo mv teleport/tsh /usr/local/bin/
  
  # Login to your Teleport cluster
  tsh login --proxy=your-teleport-proxy.com --user=your-username
  ```

- **kubectl** (alternative to Teleport):
  ```bash
  # Standard kubectl access to the cluster
  kubectl get pods -n observable
  ```

## Quick Start

### Using Teleport (Recommended)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Interactive shell access
./scripts/teleport-observable-connect.sh bash

# Start editing session with helpful prompts
./scripts/teleport-observable-connect.sh edit-dashboard

# Sync files from git repository
./scripts/teleport-observable-connect.sh sync-from-git
```

### Using Standard kubectl

```bash
# Quick file editing
./scripts/observable-dashboard-manager.sh quick-edit index.md

# List all dashboard files
./scripts/observable-dashboard-manager.sh list-files

# Create new dashboard
./scripts/observable-dashboard-manager.sh create-dashboard security-metrics
```

## Common Use Cases

### 1. Edit Main Dashboard
```bash
# Method 1: Full Teleport session
./scripts/teleport-observable-connect.sh edit-dashboard

# Method 2: Quick edit
./scripts/observable-dashboard-manager.sh quick-edit index.md
```

### 2. Upload Local Files
```bash
# Upload a dashboard file
./scripts/observable-dashboard-manager.sh upload-file ./my-dashboard.md

# Copy with Teleport (more control)
./scripts/teleport-observable-connect.sh copy-to ./my-dashboard.md /app/src/dashboard.md
```

### 3. Create New Dashboards
```bash
# Create from template
./scripts/observable-dashboard-manager.sh create-dashboard metrics-overview

# Then edit it
./scripts/observable-dashboard-manager.sh quick-edit metrics-overview.md
```

### 4. Backup Dashboard Files
```bash
# Download specific file
./scripts/observable-dashboard-manager.sh download-file index.md

# Download with Teleport
./scripts/teleport-observable-connect.sh copy-from /app/src/index.md ./backup-index.md
```

### 5. Sync with Git Repository
```bash
# Pull latest dashboard files from git
./scripts/teleport-observable-connect.sh sync-from-git
```

## File Structure in Container

```
/app/src/                           # Observable workspace
├── index.md                        # Main dashboard
├── data/                          # Data files
│   ├── metrics.json
│   └── logs.csv
├── components/                    # Reusable components
└── observablehq.config.js        # Configuration
```

## Environment Variables

The Observable container has these endpoints pre-configured:

- `LOKI_ENDPOINT`: http://192.168.122.27:3100
- `QUICKWIT_ENDPOINT`: http://192.168.122.27:7280  
- `PROMETHEUS_ENDPOINT`: http://192.168.122.27:9090
- `OTEL_ENDPOINT`: http://192.168.122.27:4318

Use these in your dashboards for data fetching.

## Live Development Workflow

1. **Connect to container**:
   ```bash
   ./scripts/teleport-observable-connect.sh bash
   ```

2. **Edit files** (in container):
   ```bash
   cd /app/src
   nano index.md                    # Edit main dashboard
   nano data/new-data.json         # Add data files
   ```

3. **Observable auto-reloads** - changes are immediately visible at http://localhost:3000

4. **No rebuild needed** - markdown changes use live development, no Docker rebuild required

## Script Features

### teleport-observable-connect.sh
- ✅ Interactive shell access
- ✅ Guided dashboard editing
- ✅ Git repository sync
- ✅ File copy operations  
- ✅ Container logs viewing
- ✅ Status checking
- ✅ Full Teleport integration

### observable-dashboard-manager.sh  
- ✅ Auto-detects kubectl vs Teleport
- ✅ Quick file editing with nano
- ✅ File upload/download
- ✅ Dashboard templates
- ✅ Directory listing
- ✅ Service restart

## Troubleshooting

### "Pod not found"
```bash
# Check if Observable is running
kubectl get pods -n observable

# Check namespace
kubectl get namespaces | grep observable
```

### "Teleport not logged in"
```bash
# Login to Teleport
tsh login

# Check status
tsh status
```

### "Permission denied"
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Check cluster access
kubectl auth can-i create pods -n observable
```

### "Container not responding"
```bash
# Check container logs
./scripts/teleport-observable-connect.sh show-logs

# Restart service
./scripts/observable-dashboard-manager.sh restart-service
```

## Security Notes

- Scripts use read-only operations by default
- File modifications are contained within the Observable workspace
- Teleport provides audit logging of all container access
- No persistent changes to container images (volumes only)

## Integration with GitOps

- Markdown file changes **don't trigger rebuilds** (by design)
- Use `kubectl cp` or these scripts for live development
- Infrastructure changes (Dockerfile, conda-environment.yml) trigger automatic GitOps rebuilds
- Best practice: develop with live editing, then commit final changes to git