# Observable Framework Development Scripts

This directory contains scripts for local development with the Observable Framework using Telepresence and direct container access.

## Scripts Overview

### 1. `telepresence-observable-connect.sh`
Advanced Telepresence-based local development script with traffic interception and seamless local-to-remote workflows.

### 2. `observable-dashboard-manager.sh`
Simplified dashboard management script for quick file operations and container access.

## Prerequisites

- **Telepresence** (for telepresence-observable-connect.sh):
  ```bash
  # Install Telepresence
  # macOS
  brew install datawire/blackbird/telepresence
  
  # Linux
  sudo curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o /usr/local/bin/telepresence
  sudo chmod a+x /usr/local/bin/telepresence
  
  # Windows - see https://www.telepresence.io/docs/latest/install/
  ```

- **kubectl** (required for both scripts):
  ```bash
  # Standard kubectl access to the cluster
  kubectl get pods -n observable
  ```

- **Observable Framework** (for local development):
  ```bash
  # Install Observable Framework locally
  npm install -g @observablehq/framework
  ```

## Quick Start

### Using Telepresence (Advanced Local Development)

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Start intercepted development (traffic routed to local machine)
./scripts/telepresence-observable-connect.sh intercept

# Setup local workspace with manual sync
./scripts/telepresence-observable-connect.sh local-dev

# Check connection status
./scripts/telepresence-observable-connect.sh status

# Disconnect when done
./scripts/telepresence-observable-connect.sh disconnect
```

### Using Direct Container Access

```bash
# Quick file editing in remote container
./scripts/observable-dashboard-manager.sh quick-edit index.md

# List all dashboard files
./scripts/observable-dashboard-manager.sh list-files

# Create new dashboard from template
./scripts/observable-dashboard-manager.sh create-dashboard security-metrics
```

## Common Use Cases

### 1. Local Development with Telepresence
```bash
# Start full local development with traffic interception
./scripts/telepresence-observable-connect.sh intercept

# Edit files locally in: ./observable-workspace/
# Changes automatically sync to cluster
# Access at: http://localhost:3000
```

### 2. Quick File Operations
```bash
# Upload a dashboard file to remote container
./scripts/observable-dashboard-manager.sh upload-file ./my-dashboard.md

# Edit files directly in remote container
./scripts/observable-dashboard-manager.sh quick-edit index.md
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
# Download specific file from remote container
./scripts/observable-dashboard-manager.sh download-file index.md

# Telepresence: Files are automatically local in ./observable-workspace/
ls ./observable-workspace/
```

### 5. Sync Workflows
```bash
# Telepresence: Setup local workspace and sync
./scripts/telepresence-observable-connect.sh local-dev
./scripts/telepresence-observable-connect.sh sync

# Direct: Download files from cluster
./scripts/observable-dashboard-manager.sh download-file index.md
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