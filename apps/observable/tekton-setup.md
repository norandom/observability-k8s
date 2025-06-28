# Tekton Pipeline Setup for Observable Framework

This document explains how to set up the fully automated GitOps workflow using Tekton Pipelines running inside your cluster.

## Overview

The Tekton pipeline provides **complete automation** since it runs inside the cluster:

1. **Detects changes** to conda dependencies, Dockerfiles, or markdown dashboards
2. **Builds containers** using Kaniko (inside cluster, can reach internal registry)
3. **Pushes to internal registry** directly
4. **Updates deployments** automatically
5. **Handles both dashboards and dependencies** seamlessly

## Setup Steps

### 1. Install Tekton Pipelines

```bash
# Install Tekton Pipelines
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

# Install Tekton Triggers
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml

# Wait for installation
kubectl wait --for=condition=ready pod --all -n tekton-pipelines --timeout=120s
```

### 2. Deploy Registry and Pipeline

```bash
cd apps/observable/

# Deploy in-cluster registry
kubectl apply -f registry-deployment.yaml

# Deploy Tekton pipeline and triggers
kubectl apply -f tekton-pipeline.yaml

# Wait for registry to be ready
kubectl wait --for=condition=available --timeout=120s deployment/registry -n registry
```

### 3. Configure Git Repository URL

```bash
# Update the git repository URL in the CronJob
kubectl edit cronjob observable-git-poller -n tekton-pipelines

# Change the GIT_REPO_URL environment variable to your repository
# Default: https://github.com/norandom/observability-k8s.git
```

**No webhook required!** The CronJob polls your repository every 2 minutes for changes.

### 4. Test the Pipeline

```bash
# Make a test change
echo "- test-package" >> apps/observable/conda-environment.yml
git add apps/observable/conda-environment.yml
git commit -m "Test Tekton pipeline trigger"
git push

# Wait up to 2 minutes for git poller to detect changes
kubectl logs -f cronjob/observable-git-poller -n tekton-pipelines

# Watch pipeline execution
kubectl get pipelineruns -n tekton-pipelines -w

# View logs
kubectl logs -f -n tekton-pipelines -l tekton.dev/pipelineRun=<pipeline-run-name>
```

## Workflow Triggers

The CronJob polls the repository every 2 minutes and triggers the pipeline when these files change:

- `apps/observable/conda-environment.yml` → **Full container rebuild**
- `apps/observable/Dockerfile` → **Full container rebuild**
- `apps/observable/dashboards-configmap.yaml` → **Dashboard update + rebuild**
- `apps/observable/*.md` → **Dashboard update + rebuild**

## Pipeline Stages

### 1. git-clone
- Clones the repository at specified revision
- Checks out the correct branch/commit

### 2. check-changes
- Analyzes git diff to determine what changed
- Sets flags for dependency vs dashboard changes
- Decides whether container rebuild is needed

### 3. build-and-push
- Uses Kaniko to build Docker image inside cluster
- Pushes to both internal and external registry endpoints
- Handles insecure registry configuration automatically

### 4. update-deployment
- Updates Kubernetes deployment with new image
- Waits for rollout to complete
- Shows updated pod status

## Usage Examples

### Adding New Python Dependencies

1. **Edit conda environment:**
   ```yaml
   # apps/observable/conda-environment.yml
   dependencies:
     - python=3.11
     - nodejs=20
     - polars>=0.20.0
     - pandas>=2.0.0
     - scikit-learn>=1.3.0  # Add new package
   ```

2. **Commit and push:**
   ```bash
   git add apps/observable/conda-environment.yml
   git commit -m "Add scikit-learn for ML analysis"
   git push
   ```

3. **Automatic result (within 2 minutes):**
   - Git poller detects conda-environment.yml change
   - Triggers Tekton pipeline automatically
   - Pipeline builds new container with scikit-learn
   - Pushes to internal registry
   - Updates Observable Framework deployment
   - All ML packages available in data loaders

### Adding New Dashboards

1. **Add dashboard to ConfigMap:**
   ```yaml
   # apps/observable/dashboards-configmap.yaml
   data:
     ml-analysis.md: |
       # Machine Learning Analysis
       
       ```js
       const data = FileAttachment("data/loki-logs.json").json();
       ```
   ```

2. **Commit and push:**
   ```bash
   git add apps/observable/dashboards-configmap.yaml
   git commit -m "Add ML analysis dashboard"
   git push
   ```

3. **Automatic result (within 2 minutes):**
   - Git poller detects dashboard changes
   - Triggers Tekton pipeline automatically
   - Pipeline rebuilds container with new dashboards
   - Updates deployment
   - Dashboard available at `http://observable.k3s.local/ml-analysis`

## Monitoring

### View Pipeline Runs
```bash
# List all pipeline runs
kubectl get pipelineruns -n tekton-pipelines

# Watch for new runs
kubectl get pipelineruns -n tekton-pipelines -w

# Get detailed status
kubectl describe pipelinerun <run-name> -n tekton-pipelines
```

### View Logs
```bash
# Follow logs for specific pipeline run
kubectl logs -f -n tekton-pipelines -l tekton.dev/pipelineRun=<run-name>

# View logs for specific task
kubectl logs -f -n tekton-pipelines -l tekton.dev/task=build-observable-image

# View EventListener logs
kubectl logs -f -n tekton-pipelines -l eventlistener=observable-listener
```

### Check Observable Framework
```bash
# Check deployment status
kubectl get pods -n observable -l app=observable

# View application logs
kubectl logs -f -n observable deployment/observable

# Check which image is running
kubectl describe deployment/observable -n observable | grep Image
```

## Troubleshooting

### Pipeline Not Triggering
1. **Check git poller:**
   ```bash
   kubectl logs -f cronjob/observable-git-poller -n tekton-pipelines
   ```

2. **Check git repository access:**
   ```bash
   kubectl run test-git --rm -it --image=alpine/git -- \
     git clone https://github.com/norandom/observability-k8s.git /tmp/test
   ```

3. **Check commit tracking:**
   ```bash
   kubectl get configmap observable-last-commit -n tekton-pipelines -o yaml
   ```

### Build Failures
1. **Check Kaniko logs:**
   ```bash
   kubectl logs -f -n tekton-pipelines -l tekton.dev/task=build-observable-image
   ```

2. **Registry connectivity:**
   ```bash
   # Test internal registry
   kubectl run test-registry --rm -it --image=curlimages/curl -- \
     curl -f http://registry.registry.svc.cluster.local:5000/v2/
   ```

### Deployment Issues
1. **Check image pull:**
   ```bash
   kubectl describe pod -n observable -l app=observable
   ```

2. **Verify registry URL:**
   ```bash
   kubectl get deployment/observable -n observable -o yaml | grep image:
   ```

## Security Considerations

- **Service Account**: Pipeline runs with limited permissions
- **Registry**: Using insecure registry for simplicity
- **Git polling**: Repository must be publicly accessible or configure credentials

## Complete Automation Flow

```
📝 Edit conda-environment.yml or dashboards
     ↓
🔄 git commit + push
     ↓
⏱️  Git poller (every 2 minutes) detects changes
     ↓
🏗️  Tekton pipeline runs inside cluster:
     ├── 📥 Clone repository
     ├── 🔍 Detect changes
     ├── 🔨 Build container (Kaniko)
     ├── 📦 Push to internal registry
     └── 🚀 Update deployment
     ↓
✅ Observable Framework available with changes!
```

This creates a **fully automated GitOps workflow** where any change to dependencies or dashboards automatically rebuilds and redeploys your Observable Framework with zero manual intervention!