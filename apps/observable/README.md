# Observable Framework Dashboard

Observable Framework dashboard for the observability-k8s stack with conda environment support, Python data loaders, and GitOps workflow.

## Overview

This setup provides:
- **Observable Framework** for interactive data visualizations
- **Conda environment** with polars, pandas, and data science libraries
- **Python data loaders** for Loki, Quickwit, and Prometheus
- **GitOps workflow** for adding dashboards via ConfigMaps

## Quick Start

### Option 1: Simple HTML Deployment (Ready to Use)

The simplest option that works out-of-the-box:

```bash
# Use the simple HTML deployment
kubectl apply -k apps/observable/
```

Access at: `http://observable.k3s.local/`

### Option 2: Full Conda-based Observable Framework

For the complete solution with Python data processing:

1. **Deploy in-cluster registry and build the conda Docker image:**
   ```bash
   cd apps/observable/
   
   # Deploy registry to your k8s cluster
   kubectl apply -f registry-deployment.yaml
   
   # Wait for registry to be ready
   kubectl wait --for=condition=available --timeout=60s deployment/registry -n registry
   
   # Build and push to in-cluster registry
   docker build -t 192.168.122.27:30500/observable-conda:latest .
   docker push 192.168.122.27:30500/observable-conda:latest
   ```

2. **Switch to conda deployment:**
   ```bash
   # Edit kustomization.yaml to uncomment conda resources and comment out simple deployment
   vim kustomization.yaml
   ```

3. **Deploy:**
   ```bash
   kubectl apply -k apps/observable/
   ```

4. **Wait for deployment (conda environment setup takes 1-2 minutes):**
   ```bash
   kubectl get pods -n observable -w
   ```

## Dependencies Management

### Adding Python Packages

Edit `conda-environment.yml` to add conda packages:

```yaml
dependencies:
  # Add new conda packages here
  - scikit-learn>=1.3.0
  - statsmodels>=0.14.0
  
  # For pip-only packages:
  - pip:
    - streamlit
    - dash
```

Then rebuild and push the updated Docker image:

```bash
cd apps/observable/
docker build -t 192.168.122.27:30500/observable-conda:latest .
docker push 192.168.122.27:30500/observable-conda:latest
kubectl rollout restart deployment/observable -n observable
```

### Quick Package Addition

For testing, you can also add packages directly in the ConfigMap start script, but this is not recommended for production.

## GitOps Workflow for Dashboards

### Adding New Dashboards

1. **Create your markdown dashboard:**
   ```markdown
   # My Dashboard
   
   ```js
   // Load data
   const data = FileAttachment("data/loki-logs.json").json();
   ```
   
   ```js
   // Create visualization
   Plot.plot({
     data: data,
     marks: [Plot.dot(data, {x: "timestamp", y: "level"})]
   })
   ```
   ```

2. **Add to dashboards ConfigMap:**
   Edit `dashboards-configmap.yaml` and add your dashboard:
   ```yaml
   data:
     my-dashboard.md: |
       # My Dashboard
       Your dashboard content here...
   ```

3. **Commit and push:**
   ```bash
   git add dashboards-configmap.yaml
   git commit -m "Add my-dashboard"
   git push
   ```

4. **ArgoCD will automatically deploy** your dashboard to `http://observable.k3s.local/my-dashboard`

## Data Sources

The dashboards can access these data sources:

| Service | Endpoint | Purpose |
|---------|----------|---------|
| **Loki** | `http://192.168.122.27:3100` | Operational logs |
| **Quickwit** | `http://192.168.122.27:7280` | Security logs |
| **Prometheus** | `http://192.168.122.27:9090` | Metrics |

## Python Data Loaders

Data loaders are Python scripts that fetch data and output JSON for Observable Framework:

### Loki Loader (`loki-loader.py`)
- Fetches operational logs from Loki
- Processes with polars for performance
- Extracts log levels and service information
- Outputs: `data/loki-logs.json`

### Quickwit Loader (`quickwit-loader.py`)
- Fetches security logs from Quickwit
- Calculates risk scores
- Identifies security-relevant events
- Outputs: `data/quickwit-logs.json`

### Metrics Loader (`metrics-loader.py`)
- Fetches system metrics from Prometheus
- Calculates health indicators
- Provides performance summaries
- Outputs: `data/metrics.json`

## Automated GitOps Workflow

### 🤖 Fully Automated GitOps Workflow

This setup includes a **complete GitOps workflow** using Tekton Pipelines running inside your cluster:

**Fully Automatic (Tekton Pipeline):**
- `conda-environment.yml` → **Automatic container rebuild with new dependencies**
- `Dockerfile` → **Automatic container rebuild**  
- `dashboards-configmap.yaml` or `*.md` files → **Automatic dashboard deployment**

**Benefits:**
- ✅ Runs inside cluster (can reach internal registry)
- ✅ Complete automation for all changes
- ✅ Git polling (no webhook required for internal clusters)
- ✅ Zero manual intervention required

**Setup:** Follow instructions in `tekton-setup.md`

### 📊 Usage Examples

#### Adding Python Dependencies

1. **Edit conda environment:**
   ```yaml
   # apps/observable/conda-environment.yml
   dependencies:
     - python=3.11
     - nodejs=20
     - polars>=0.20.0
     - pandas>=2.0.0
     - scikit-learn>=1.3.0  # Add new package
     - tensorflow>=2.13.0    # Add ML framework
   ```

2. **Commit and push:**
   ```bash
   git add apps/observable/conda-environment.yml
   git commit -m "Add scikit-learn and tensorflow for ML analysis"
   git push
   ```

3. **Automatic result (within 2 minutes):**
   - Git poller detects conda-environment.yml change
   - Triggers Tekton pipeline automatically
   - Pipeline builds new container with packages
   - Pushes to in-cluster registry
   - Updates Observable Framework deployment
   - All ML packages available in data loaders

#### Adding New Dashboards

1. **Add dashboard to ConfigMap:**
   ```yaml
   # apps/observable/dashboards-configmap.yaml
   data:
     ml-analysis.md: |
       # Machine Learning Analysis
       
       ## Security Anomaly Detection
       
       ```js
       // Load security data
       const securityData = FileAttachment("data/quickwit-logs.json").json();
       ```
       
       ```js
       // Risk score distribution
       Plot.plot({
         data: securityData,
         marks: [
           Plot.rectY(securityData, Plot.binX({y: "count"}, {x: "risk_score", fill: "red"}))
         ]
       })
       ```
   ```

2. **Commit and push:**
   ```bash
   git add apps/observable/dashboards-configmap.yaml
   git commit -m "Add ML security analysis dashboard"
   git push
   ```

3. **Automatic result (within 2 minutes):**
   - Git poller detects dashboard changes
   - Triggers Tekton pipeline automatically
   - Pipeline rebuilds container with new dashboards
   - Updates deployment
   - Dashboard available at `http://observable.k3s.local/ml-analysis`

#### Creating Custom Data Loaders

1. **Add Python data loader to ConfigMap:**
   ```yaml
   # In conda-configmap.yaml, add new loader:
   ml-predictions.py: |
     #!/usr/bin/env python3
     import json
     import polars as pl
     from sklearn.ensemble import IsolationForest
     
     # ML-powered anomaly detection
     def detect_anomalies():
         # Your ML code here
         return predictions
   ```

2. **Use in dashboard:**
   ```js
   // Load ML predictions
   const predictions = FileAttachment("data/ml-predictions.json").json();
   ```

### 💻 Loading Data in Dashboards

```js
// Load operational logs
const lokiData = FileAttachment("data/loki-logs.json").json();

// Load security data with risk scores
const securityData = FileAttachment("data/quickwit-logs.json").json();

// Load system metrics
const metrics = FileAttachment("data/metrics.json").json();

// Load custom ML predictions (if added)
const predictions = FileAttachment("data/ml-predictions.json").json();
```

### 📈 Creating Visualizations

```js
// Log level distribution
Plot.plot({
  data: lokiData,
  marks: [
    Plot.barY(lokiData, Plot.groupX({y: "count"}, {x: "level"}))
  ]
})
```

```js
// Security risk timeline
Plot.plot({
  data: securityData,
  marks: [
    Plot.dot(securityData, {
      x: "timestamp", 
      y: "risk_score",
      fill: "severity"
    })
  ]
})
```

```js
// System health overview
Plot.plot({
  data: metrics,
  marks: [
    Plot.lineY(metrics.system_metrics, {
      x: "timestamp",
      y: "cpu_usage",
      stroke: "blue"
    })
  ]
})
```

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Git Repository │ => │   ArgoCD GitOps  │ => │   K8s Cluster   │
│                 │    │                  │    │                 │
│ dashboards/     │    │ Watches repo     │    │ Observable Pod  │
│ ├── security.md │    │ Auto-deploys     │    │ ├── Python env  │
│ ├── ops.md      │    │ ConfigMaps       │    │ ├── Node.js     │
│ └── custom.md   │    │                  │    │ └── Data loaders│
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        v
┌─────────────────────────────────────────────────────────────────┐
│                    Data Sources                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │    Loki     │  │  Quickwit   │  │      Prometheus         │  │
│  │ Operational │  │  Security   │  │       Metrics           │  │
│  │    Logs     │  │    Logs     │  │                         │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Dashboard Not Loading
- Check pod logs: `kubectl logs -n observable deployment/observable`
- Verify ConfigMap: `kubectl get configmap -n observable observable-dashboards -o yaml`

### Python Packages Missing
- Rebuild Docker image with updated `conda-environment.yml`
- Check conda environment in pod: `kubectl exec -it -n observable deployment/observable -- conda list`

### Data Loaders Failing
- Check data source connectivity
- Verify environment variables in deployment
- Test loaders manually: `kubectl exec -it -n observable deployment/observable -- python src/data/loki-loader.py`

### ArgoCD Not Syncing
- Check ArgoCD application status
- Verify git repository connectivity
- Force sync in ArgoCD UI

## Development

### Local Development

1. **Install conda environment locally:**
   ```bash
   conda env create -f conda-environment.yml
   conda activate observable-dashboard
   ```

2. **Install Observable Framework:**
   ```bash
   npm install -g @observablehq/framework
   ```

3. **Run locally:**
   ```bash
   cd src/
   npx @observablehq/framework dev
   ```

### Building and Testing the Docker Image

1. **Build locally:**
   ```bash
   docker build -t observable-conda:latest .
   ```

2. **Test the image:**
   ```bash
   docker run -p 3000:3000 \
     -e LOKI_ENDPOINT=http://192.168.122.27:3100 \
     -e QUICKWIT_ENDPOINT=http://192.168.122.27:7280 \
     -e PROMETHEUS_ENDPOINT=http://192.168.122.27:9090 \
     observable-conda:latest
   ```

3. **Push to in-cluster registry when ready:**
   ```bash
   docker tag observable-conda:latest 192.168.122.27:30500/observable-conda:latest
   docker push 192.168.122.27:30500/observable-conda:latest
   ```

### Testing Data Loaders

```bash
# Set environment variables
export LOKI_ENDPOINT=http://192.168.122.27:3100
export QUICKWIT_ENDPOINT=http://192.168.122.27:7280
export PROMETHEUS_ENDPOINT=http://192.168.122.27:9090

# Test loaders
python src/data/loki-loader.py
python src/data/quickwit-loader.py  
python src/data/metrics-loader.py
```

## Configuration Files

| File | Purpose |
|------|---------|
| `conda-environment.yml` | Python package dependencies |
| `Dockerfile` | Conda-based container image |
| `conda-deployment.yaml` | Kubernetes deployment for conda version |
| `conda-configmap.yaml` | Configuration and data loaders |
| `dashboards-configmap.yaml` | Dashboard markdown files |
| `kustomization.yaml` | Kustomize configuration |

## Links

- **Dashboard:** http://observable.k3s.local/
- **Observable Framework Docs:** https://observablehq.com/framework/
- **Python Data Loaders:** https://observablehq.com/framework/loaders