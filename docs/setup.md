# Complete Setup Guide

## Prerequisites

- **Kubernetes cluster** (tested with k3s, kind)
- **kubectl** configured for your cluster
- **Telepresence** installed locally
- **Git** for GitOps workflow
- **AI tools**: Claude Code, Gemini CLI (optional but recommended)

## Quick Setup

### 1. Configure Cluster
```bash
# Edit cluster configuration
vi config/cluster-config.env
# Set CLUSTER_IP to your cluster's IP address

# Generate configuration files
./scripts/configure-vector.sh
```

### 2. Bootstrap Stack
```bash
# Deploy everything via GitOps
chmod +x scripts/bootstrap-gitops.sh
./scripts/bootstrap-gitops.sh

# Wait for all pods to be ready (3-5 minutes)
kubectl get pods -A -w
```

### 3. Get Access Credentials
```bash
# ArgoCD admin password
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Grafana (admin/admin)
```

### 4. Verify Access
```bash
# Check all services are accessible
curl http://argocd.k3s.local
curl http://grafana.k3s.local
curl http://observable.k3s.local
curl http://quickwit.k3s.local
```

## Host Configuration

Add to `/etc/hosts` (Linux/Mac) or `C:\Windows\System32\drivers\etc\hosts` (Windows):

```
192.168.122.27 grafana.k3s.local
192.168.122.27 argocd.k3s.local
192.168.122.27 loki.k3s.local
192.168.122.27 quickwit.k3s.local
192.168.122.27 otel.k3s.local
192.168.122.27 observable.k3s.local
```

Replace `192.168.122.27` with your cluster IP.

## Telepresence Setup

### Install Telepresence
```bash
# macOS
brew install datawire/blackbird/telepresence

# Linux
sudo curl -fL https://app.getambassador.io/download/tel2/linux/amd64/latest/telepresence -o /usr/local/bin/telepresence
sudo chmod a+x /usr/local/bin/telepresence

# Windows
# Download from https://www.telepresence.io/docs/latest/install/
```

### Connect to Cluster
```bash
# Connect Telepresence to cluster
telepresence connect

# Verify connection
telepresence status
```

## Development Environment Setup

### Option 1: Telepresence Intercept (Recommended)
```bash
# Start intercepted development
./scripts/telepresence-observable-connect.sh intercept

# Your local machine now handles Observable Framework traffic
# Edit files locally, see changes immediately in cluster
```

### Option 2: Direct Container Development
```bash
# Access running container
POD_NAME=$(kubectl get pods -n observable -l app=observable -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n observable $POD_NAME -- /bin/bash

# Container has Python, Node.js, Git available
```

## Next Steps

1. **[Start developing dashboards →](../README.md#live-development-setup)**
2. **[Learn the architecture →](architecture.md)**
3. **[Explore examples →](examples.md)**
4. **[Test APIs →](api-endpoints.md)**