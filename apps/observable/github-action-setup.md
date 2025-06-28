# GitHub Actions Setup for Observable Framework

This document explains how to set up the automated GitOps workflow using GitHub Actions.

## Overview

The GitHub Action automatically:
1. **Detects changes** to conda dependencies, Dockerfiles, or markdown dashboards
2. **Rebuilds container** when dependencies change
3. **Updates deployments** when new container is built
4. **Applies dashboard changes** when markdown files are modified
5. **Deploys everything** through ArgoCD or directly to cluster

## Setup Steps

### 1. Add Kubernetes Configuration to GitHub Secrets

You need to add your Kubernetes config as a GitHub secret:

```bash
# Get your kubeconfig (base64 encoded)
cat ~/.kube/config | base64 -w 0
```

Then in your GitHub repository:
1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `KUBE_CONFIG`
4. Value: The base64 encoded kubeconfig from above

### 2. Update Registry URL

Edit `.github/workflows/observable-deploy.yml` and update the `REGISTRY_URL`:

```yaml
env:
  REGISTRY_URL: "YOUR_CLUSTER_IP:30500"  # Replace with your actual cluster IP
```

### 3. Deploy the In-Cluster Registry

First, make sure the registry is deployed:

```bash
kubectl apply -f apps/observable/registry-deployment.yaml
```

### 4. Configure Docker for Insecure Registry

Since we're using an insecure registry, you may need to configure Docker:

**On your local machine:**
```bash
# Add to /etc/docker/daemon.json
{
  "insecure-registries": ["192.168.122.27:30500"]
}

# Restart Docker
sudo systemctl restart docker
```

**For GitHub Actions runner:**
The workflow handles this automatically with buildx configuration.

## Workflow Triggers

The GitHub Action triggers on pushes to `main` branch when these files change:

- `apps/observable/conda-environment.yml` → **Rebuilds container**
- `apps/observable/Dockerfile` → **Rebuilds container**
- `apps/observable/dashboards-configmap.yaml` → **Updates dashboards**
- `apps/observable/*.md` → **Updates dashboards**
- `apps/observable/src/**/*.md` → **Updates dashboards**

## Usage Examples

### Adding New Python Dependencies

1. Edit `apps/observable/conda-environment.yml`:
   ```yaml
   dependencies:
     - python=3.11
     - nodejs=20
     - polars>=0.20.0
     - pandas>=2.0.0
     - scikit-learn>=1.3.0  # Add new package
   ```

2. Commit and push:
   ```bash
   git add apps/observable/conda-environment.yml
   git commit -m "Add scikit-learn for ML analysis"
   git push
   ```

3. **GitHub Action automatically:**
   - Detects conda-environment.yml change
   - Builds new container with scikit-learn
   - Pushes to registry
   - Updates deployment
   - Restarts Observable Framework

### Adding New Dashboards

1. Edit `apps/observable/dashboards-configmap.yaml`:
   ```yaml
   data:
     ml-analysis.md: |
       # Machine Learning Analysis
       
       ```js
       // Load data
       const data = FileAttachment("data/loki-logs.json").json();
       ```
       
       ```js
       // ML analysis with scikit-learn via Python data loader
       const predictions = FileAttachment("data/ml-predictions.json").json();
       ```
   ```

2. Commit and push:
   ```bash
   git add apps/observable/dashboards-configmap.yaml
   git commit -m "Add ML analysis dashboard"
   git push
   ```

3. **GitHub Action automatically:**
   - Detects dashboard change
   - Applies ConfigMap update
   - Dashboard available at `http://observable.k3s.local/ml-analysis`

## Workflow Jobs

### 1. detect-changes
- Analyzes git diff to determine what changed
- Sets output variables for other jobs
- Decides whether container rebuild is needed

### 2. build-and-push
- Only runs if conda dependencies or Dockerfile changed
- Builds new Docker image with updated dependencies
- Pushes to in-cluster registry
- Tags with both commit SHA and `latest`

### 3. deploy
- Runs if either container or dashboards changed
- Updates deployment with new image (if built)
- Applies dashboard ConfigMap changes
- Waits for rollout completion

### 4. notify
- Shows deployment status and access information
- Provides links to updated dashboards

## Monitoring

### View Workflow Status
- GitHub → Actions tab → "Observable Framework Auto-Deploy"
- See real-time logs for each step

### Check Deployment Status
```bash
# Watch deployment progress
kubectl get pods -n observable -w

# View logs
kubectl logs -n observable deployment/observable -f

# Check image version
kubectl describe deployment/observable -n observable | grep Image
```

### Troubleshooting

**Build fails:**
- Check registry is accessible: `curl -f http://192.168.122.27:30500/v2/`
- Verify Docker daemon configuration for insecure registry

**Deployment fails:**
- Check KUBE_CONFIG secret is correctly base64 encoded
- Verify kubectl context in workflow logs
- Check cluster connectivity from GitHub Actions

**Dashboards not updating:**
- Verify ConfigMap was applied: `kubectl get configmap observable-dashboards -n observable -o yaml`
- Check pod restart: `kubectl get pods -n observable`

## Security Considerations

- **KUBE_CONFIG secret**: Contains cluster admin access - protect carefully
- **Registry access**: Using insecure registry for simplicity - consider TLS for production
- **GitHub Actions**: Review workflow permissions in repository settings

## Complete Automation Flow

```
📝 Edit conda-environment.yml
     ↓
🔄 git commit + push
     ↓
🤖 GitHub Action detects changes
     ↓
🔨 Builds new container with updated dependencies
     ↓
📦 Pushes to in-cluster registry
     ↓
🚀 Updates Kubernetes deployment
     ↓
♻️  ArgoCD syncs remaining resources
     ↓
✅ Observable Framework available with new dependencies!
```

This creates a fully automated GitOps workflow where any change to dependencies or dashboards automatically rebuilds and redeploys your Observable Framework with zero manual intervention!