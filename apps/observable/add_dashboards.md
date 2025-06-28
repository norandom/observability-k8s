# 🔄 Observable Framework GitOps Workflow

Complete step-by-step workflow for adding a new dashboard, from creation to deployment.

## 📋 Prerequisites

- **Observable Framework**: Deployed and running
- **Tekton Pipelines**: Auto-building system active
- **ArgoCD**: GitOps deployment configured
- **K3s Registry**: Configured for insecure access

## 🚀 Step-by-Step Workflow

### **Step 1: User Creates New Dashboard**

User adds a new `.md` file to the ConfigMap:

```bash
# Edit the ConfigMap to add new dashboard
vim apps/observable/observable-configmap.yaml
```

Add new dashboard entry:
```yaml
data:
  # Existing dashboards...
  new-dashboard.md: |
    # New Dashboard
    
    ```js
    const data = [
      {name: "metric1", value: 100},
      {name: "metric2", value: 200}
    ];
    ```
    
    ## Metrics Overview
    
    <div class="metrics">
      ${data.map(d => html`
        <div class="metric-card">
          <h3>${d.name}</h3>
          <div class="value">${d.value}</div>
        </div>
      `)}
    </div>
    
    <style>
    .metrics { display: flex; gap: 1rem; }
    .metric-card { background: #f8f9fa; padding: 1rem; border-radius: 8px; }
    .value { font-size: 2rem; font-weight: bold; color: #007bff; }
    </style>
```

### **Step 2: Update Observable Configuration**

Update the deployment to include the new page in navigation:

```bash
# The deployment script automatically includes pages, but to add to navigation:
# Update the observablehq.config.js section in observable-deployment.yaml
```

### **Step 3: Commit Changes to Git**

```bash
# Stage changes
git add apps/observable/observable-configmap.yaml

# Commit with descriptive message
git commit -m "Add new metrics dashboard

- New dashboard at /new-dashboard
- Interactive metrics visualization  
- Responsive card layout

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to main branch
git push origin main
```

### **Step 4: Tekton Auto-Build Process**

**🔍 Detection Phase (Every 2 minutes):**
```yaml
# Git Poller CronJob runs
observable-git-poller: 
  schedule: "*/2 * * * *"
  # Checks for changes in apps/observable/*.md files
```

**⚡ Trigger Conditions:**
- ConfigMap changes (`observable-configmap.yaml`)
- Markdown files (`.md` extensions)
- Dockerfile modifications
- Conda environment updates

**🏗️ Build Process:**
1. **Git Clone**: Downloads latest repository
2. **Change Detection**: Compares with last processed commit
3. **Pipeline Trigger**: Creates new PipelineRun if changes detected
4. **Container Build**: Kaniko builds new Observable Framework image
5. **Registry Push**: Pushes to both internal and external registry
6. **Deployment Update**: Updates running deployment with new image

### **Step 5: Tekton Pipeline Execution**

**Pipeline Tasks:**
```yaml
# 1. Git Clone Task
git-clone:
  image: alpine/git:latest
  # Clones repository to workspace

# 2. Build and Push Task  
build-and-push:
  image: gcr.io/kaniko-project/executor:latest
  # Builds: 192.168.122.27:30500/observable-conda:latest
  # Context: apps/observable/
  # Dockerfile: ./Dockerfile
```

**Build Timeline:**
- **Git operations**: ~30 seconds
- **Node.js installation**: ~60 seconds  
- **Observable Framework install**: ~120 seconds
- **ConfigMap integration**: ~15 seconds
- **Container build & push**: ~30 seconds
- **Total time**: ~4-5 minutes

### **Step 6: ArgoCD Sync Process**

**🔄 ArgoCD Detection:**
```yaml
# ArgoCD Application watches main branch
spec:
  source:
    repoURL: https://github.com/norandom/observability-k8s.git
    path: apps/observable
    targetRevision: HEAD
```

**📦 Sync Behavior:**
- **Auto-sync**: Detects ConfigMap changes
- **Self-heal**: Applies new ConfigMap automatically
- **Health check**: Verifies deployment status

**⏱️ Sync Timeline:**
- **Change detection**: ~30 seconds after git push
- **ConfigMap update**: ~10 seconds
- **Pod restart trigger**: ~15 seconds (if needed)
- **Service ready**: ~60 seconds
- **Total time**: ~2 minutes

### **Step 7: Deployment Update Process**

**🔄 Container Update (if Tekton built new image):**
```bash
# Tekton pipeline updates deployment
kubectl set image deployment/observable \
  observable=192.168.122.27:30500/observable-conda:latest \
  -n observable

# Rolling update process
kubectl rollout status deployment/observable -n observable
```

**📝 ConfigMap Update (always happens):**
```bash
# ArgoCD applies ConfigMap changes
kubectl apply -f observable-configmap.yaml

# ConfigMap mounted as volume, auto-reloads
# Observable Framework picks up new .md files
```

### **Step 8: User Verification**

**🌐 Dashboard Access:**
```bash
# Test new dashboard URL
curl http://observable.k3s.local/new-dashboard

# Verify in browser
open http://observable.k3s.local/new-dashboard
```

**🔍 Verification Steps:**
1. Check main page updates with new navigation
2. Access new dashboard URL
3. Verify JavaScript code blocks execute
4. Confirm styling and interactivity work

## ⏱️ Complete Workflow Timeline

| Phase | Component | Duration | Action |
|-------|-----------|----------|---------|
| **1. User Action** | Developer | ~5 mins | Edit ConfigMap, commit, push |
| **2. Git Detection** | Tekton Poller | 0-2 mins | Wait for next poll cycle |
| **3. Pipeline Build** | Tekton | ~5 mins | Build & push new container |
| **4. ArgoCD Sync** | ArgoCD | ~2 mins | Detect & apply ConfigMap |
| **5. Container Update** | Kubernetes | ~3 mins | Rolling update deployment |
| **6. Service Ready** | Observable | ~1 min | Framework loads new dashboard |

**📊 Total Time: 8-18 minutes** (depending on polling timing)

## 🔧 Optimization Options

### **Faster Deployment (ConfigMap Only):**
If no container changes needed:
```bash
# Skip Tekton, direct ArgoCD sync
# Only ConfigMap changes: ~2-3 minutes total
```

### **Immediate Testing:**
```bash
# Manual ConfigMap update for testing
kubectl apply -f apps/observable/observable-configmap.yaml

# Force pod restart
kubectl rollout restart deployment/observable -n observable
```

## 🚨 Troubleshooting

### **Dashboard Not Appearing:**
```bash
# Check ConfigMap applied
kubectl get configmap observable-dashboards -n observable -o yaml

# Check pod logs
kubectl logs deployment/observable -n observable

# Verify file mounted
kubectl exec deployment/observable -n observable -- ls -la /dashboard-src/
```

### **Build Pipeline Issues:**
```bash
# Check pipeline runs
kubectl get pipelinerun -n tekton-pipelines --sort-by=.metadata.creationTimestamp

# Check git poller
kubectl get cronjob observable-git-poller -n tekton-pipelines

# Manual trigger
kubectl create -f simple-pipeline.yaml
```

### **ArgoCD Sync Problems:**
```bash
# Check application status
kubectl get application observable -n argocd

# Force sync
argocd app sync observable
```

## 📝 Dashboard Development Best Practices

### **JavaScript Code Blocks:**
- Use `const` for data variables
- Include error handling for API calls
- Use template literals for dynamic content
- Test calculations before committing

### **Styling Guidelines:**
- Use consistent color schemes (`#007bff`, `#dc3545`, `#ffc107`)
- Responsive grid layouts (`display: grid`)
- Standard padding and margins (`1rem`, `1.5rem`)
- Accessible font sizes and contrast

### **Data Integration:**
- Reference API endpoints via environment variables
- Include sample data for development
- Use Observable's `FileAttachment` for static data
- Plan for real-time data refresh patterns

### **Git Workflow:**
- Use descriptive commit messages
- Include dashboard name and purpose
- Reference issue numbers if applicable
- Test locally before pushing to main

This workflow ensures **full GitOps compliance** with **automated building**, **container updates**, and **live dashboard deployment**! 🎯