# GitOps Observability Stack

Complete observability stack managed by ArgoCD for learning GitOps principles with dual log routing: operational logs to Loki and security logs to Quickwit.

## Table of Contents

1. [Overview & Architecture](#overview--architecture)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [GitOps Workflow](#gitops-workflow)
5. [Access Points](#access-points)
6. [Log Routing & Data Processing](#log-routing--data-processing)
7. [Testing the Log Pipeline](#testing-the-log-pipeline)
8. [Search API Endpoints](#search-api-endpoints)
9. [Cluster Configuration](#cluster-configuration)

## Overview & Architecture

This observability stack implements a **dual-pipeline log routing architecture** with 8 main components:

### **Core Services**
- **Vector** - Log collection (DaemonSet + client installations)
- **OpenTelemetry Collector** - Central log routing hub
- **Loki** - Time-series log storage for operational monitoring
- **Quickwit** - Full-text search engine for security analysis
- **Grafana** - Dashboards and operational log analysis
- **Prometheus** - Metrics collection and monitoring
- **Observable Framework** - Python-powered data analysis and markdown reports
- **ArgoCD** - GitOps automation and deployment management

### **Architecture Flow**
```
Vector/Clients → OpenTelemetry Collector → {Loki (operational), Quickwit (security)}
                           ↓                    ↓                    ↓
                   Grafana (dashboards)  Quickwit UI (search)  Observable (reports)
                           ↓                                        ↓
                  Prometheus (metrics)                    Python data analysis
```

### **Data Retention**
- **Loki**: No retention policy configured (manual cleanup required)
- **Quickwit**: Persistent storage (5Gi PVC) - data survives pod restarts
- **Grafana**: Persistent storage (1Gi PVC) - data survives pod restarts
- **Prometheus**: Persistent storage for metrics collection
- **OTEL Collector**: No persistent storage (ephemeral)

## Prerequisites

- **Kubernetes cluster** (tested with k3s)
- **kubectl** configured for your cluster
- **Git** for GitOps workflow
- **curl** for testing API endpoints
- **Ingress controller** for web interface access (*.k3s.local domains)

## Quick Start

1. **Configure cluster IP for your environment:**
   ```bash
   # Edit config/cluster-config.env and set your cluster IP
   vi config/cluster-config.env
   
   # Configure Vector client
   ./scripts/configure-vector.sh
   ```

2. **Bootstrap ArgoCD and the stack:**
   ```bash
   chmod +x scripts/bootstrap-gitops.sh
   ./scripts/bootstrap-gitops.sh
   ```

3. **Get ArgoCD admin credentials:**
   ```bash
   echo "Username: admin"
   echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
   echo ""  # Line break for easier copy-paste
   ```

## Access Points

### **Web Interfaces**
- **ArgoCD UI**: http://argocd.k3s.local
  - Username: admin  
  - Password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- **Grafana**: http://grafana.k3s.local  
  - Username: admin / Password: admin
  - **Purpose**: Operational log analysis and dashboards (Loki datasource)
- **Observable Framework**: http://observable.k3s.local
  - **Purpose**: Python-powered data analysis, markdown reports, and interactive visualizations
- **Quickwit UI**: http://quickwit.k3s.local/ui/search
  - **Purpose**: Security log analysis and full-text search
- **Loki**: http://loki.k3s.local

### **Applications Managed by ArgoCD**
- **Grafana** (`apps/grafana/`) - Dashboards and visualization
- **Loki** (`apps/loki/`) - Operational log storage
- **Observable Framework** (`apps/observable/`) - Python data analysis and markdown reports
- **OpenTelemetry Collector** (`apps/otel/`) - Log routing hub
- **Quickwit** (`apps/quickwit/`) - Security log search
- **Prometheus** (`apps/prometheus/`) - Metrics collection
- **Vector** (`apps/vector/`) - Log collection DaemonSet

## Log Routing & Data Processing

### **Loki (Operational Logs)**
- **Purpose**: Time-series log aggregation for operational monitoring
- **Use Cases**: Application logs, infrastructure logs, system metrics, performance monitoring
- **Strengths**: Label-based indexing, fast time-range queries, efficient storage compression
- **Log Types**: HTTP requests, database queries, application errors, system health, container logs

### **Quickwit (Security Logs)**  
- **Purpose**: Full-text search engine for security analysis and forensics
- **Use Cases**: Security events, compliance auditing, threat detection, forensic analysis
- **Strengths**: Full-text search, complex queries, structured data analysis, long-term retention
- **Log Types**: Authentication events, authorization failures, audit trails, firewall logs, intrusion detection

### **Observable Framework (Data Analysis & Reports)**
- **Purpose**: Python-powered data analysis, interactive reports, and visualizations
- **Use Cases**: Custom analytics, trend analysis, executive reporting, data exploration
- **Strengths**: Markdown-based reports, Python data loaders, JavaScript visualizations, automated builds
- **Data Sources**: Loki API, Quickwit API, Prometheus metrics, custom Python analysis

### **OpenTelemetry Log Routing Logic**

The OTEL Collector automatically routes all logs to both destinations:

**Dual Routing**: All logs go to both Loki and Quickwit for comprehensive coverage
- **Loki**: Fast operational queries and dashboards
- **Quickwit**: Deep security analysis and investigations

**OTEL Endpoints**:
- **HTTP Ingestion**: `http://[CLUSTER_IP]:4318/v1/logs`
- **gRPC Ingestion**: `http://[CLUSTER_IP]:4317` 

### **Vector Client Configuration**

Vector clients collect logs from multiple sources and forward to OTEL:
- **journald**: System service logs  
- **docker**: Container logs
- **auditd**: Security audit logs (`/var/log/audit/audit.log`)

**Installation**: 
1. Configure cluster IP: `vi config/cluster-config.env`
2. Generate config: `./scripts/configure-vector.sh`  
3. Install: `./scripts/vector-install.sh`

## Search API Endpoints

### **Loki API**
**Base URL**: `http://[CLUSTER_IP]:3100/loki/api/v1/`

#### **Query Recent Logs**
```bash
# Get last 10 logs from past hour
curl -G 'http://[CLUSTER_IP]:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job=~".+"}' \
  --data-urlencode 'start='$(date -d '1 hour ago' +%s)000000000 \
  --data-urlencode 'end='$(date +%s)000000000 \
  --data-urlencode 'limit=10'

# Query operational logs only
curl -G 'http://[CLUSTER_IP]:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={log_type="operational"}' \
  --data-urlencode 'limit=10'

# Query with JSON parsing
curl -G 'http://[CLUSTER_IP]:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job=~".+"} | json | level="ERROR"' \
  --data-urlencode 'limit=10'
```

#### **Real-time Log Streaming**
```bash
# Tail logs in real-time
curl -G 'http://[CLUSTER_IP]:3100/loki/api/v1/tail' \
  --data-urlencode 'query={job=~".+"}'
```

### **Quickwit API**
**Base URL**: `http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/`

#### **Search Recent Logs**
```bash
# Get last 10 logs
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "*", "max_hits": 10}'

# Search security logs only
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "log_type:security", "max_hits": 10}'

# Search authentication events
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "category:auth", "max_hits": 10}'

# Search by service name
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "service_name:ssh-server", "max_hits": 10}'

# Search with time range (last hour)
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "*", 
    "max_hits": 50,
    "start_timestamp": '$(date -d '1 hour ago' +%s)',
    "end_timestamp": '$(date +%s)'
  }'
```

#### **Advanced Quickwit Queries**
```bash
# Complex search with multiple conditions
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "log_type:security AND severity_text:ERROR", "max_hits": 20}'

# Search by IP address
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "source_ip:203.0.113.42", "max_hits": 10}'

# Text search in message body
curl -X POST 'http://[CLUSTER_IP]:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "message:firewall", "max_hits": 10}'
```

## Testing the Log Pipeline

### **Send Test Logs**

```bash
# Send operational logs to both Loki and Quickwit
./scripts/test-operational-logs.sh

# Send security logs to both Loki and Quickwit  
./scripts/test-security-logs.sh
```

### **Retrieve and Verify Logs**

```bash
# Get latest logs from Loki (operational focus)
./scripts/get-loki-logs.sh

# Get latest logs from Quickwit (security focus)
./scripts/get-quickwit-logs.sh

# Wait for logs to be processed (10-30 seconds)
sleep 30
```

### **Access Log Analysis Interfaces**

#### **Grafana (Operational Monitoring)**
- **URL**: http://grafana.k3s.local 
- **Credentials**: admin/admin
- **Purpose**: Operational monitoring, dashboards, and alerts
- **Datasource**: Loki (pre-configured)
- **Features**: Time-series log aggregation, LogQL queries, label-based filtering

**Sample LogQL Queries in Grafana**:
```logql
# All recent logs with JSON parsing
{job=~".+"} | json

# Error logs only
{job=~".+"} | json | level="ERROR"

# Operational logs from specific service
{service_name="web-server"}

# Recent logs with text filtering
{job=~".+"} |= "database"
```

#### **Quickwit UI (Security Analysis)**
- **URL**: http://quickwit.k3s.local/ui/search
- **Index**: Select `otel-logs-v0_7`
- **Purpose**: Security log analysis and forensic investigations
- **Features**: Full-text search, complex queries, structured data analysis

**Sample Queries in Quickwit UI**:
- All logs: `*`
- Security logs: `log_type:security`
- Authentication events: `category:auth`
- SSH events: `SSH`
- Firewall events: `firewall`
- Error level logs: `severity_text:ERROR`
- IP-based search: `source_ip:203.0.113.42`
- Combined search: `log_type:security AND severity_text:ERROR`

#### **Observable Framework (Data Analysis & Reports)**
- **URL**: http://observable.k3s.local
- **Purpose**: Python-powered data analysis and interactive markdown reports
- **Features**: Real-time data fetching, JavaScript visualizations, automated report generation

**Capabilities**:
- **Python Data Loaders**: Automatically fetch data from Loki and Quickwit APIs at build time
- **Interactive Visualizations**: Charts, tables, and plots using Observable Plot
- **Markdown Reports**: Combine analysis with narrative using markdown
- **Real-time Updates**: Data refreshes automatically during development
- **Custom Analytics**: Run complex Python analysis on log data

**Sample Analysis**:
- Log volume trends over time
- Security event severity distribution
- Service activity monitoring
- Custom threat detection queries
- Executive summary reports

### **Complete Testing Workflow**

```bash
# 1. Configure cluster IP
vi config/cluster-config.env

# 2. Generate Vector client config
./scripts/configure-vector.sh

# 3. Send test logs to validate routing
./scripts/test-operational-logs.sh
./scripts/test-security-logs.sh

# 4. Wait for logs to be processed
sleep 30

# 5. Retrieve and verify logs
./scripts/get-loki-logs.sh
./scripts/get-quickwit-logs.sh

# 6. View in web interfaces
# Grafana: http://grafana.k3s.local (admin/admin)
# Quickwit: http://quickwit.k3s.local/ui/search
# Observable Framework: http://observable.k3s.local
```

## GitOps Workflow

This project demonstrates **GitOps principles** with ArgoCD managing all deployments declaratively.

### **Making Changes**
1. **Edit** any YAML in `apps/` directories
2. **Commit** and push to your Git repository  
3. **ArgoCD automatically syncs** changes to cluster
4. **Monitor** in ArgoCD UI - see deployment status, health, sync status

### **Available Deployment Scripts**
```bash
# GitOps approach (recommended)
./scripts/bootstrap-gitops.sh     # Setup ArgoCD and all apps

# Direct deployment approach  
./scripts/deploy-all.sh           # Deploy all services via kubectl
./scripts/deploy-grafana.sh       # Deploy individual services
./scripts/deploy-loki.sh
./scripts/deploy-otel.sh
./scripts/deploy-quickwit.sh
./scripts/deploy-prometheus.sh
./scripts/deploy-vector.sh
```

### **Making Changes Example**
```bash
# Update Grafana image
vi apps/grafana/grafana-deployment.yaml
# Change image: grafana/grafana:latest to grafana/grafana:10.2.0

git add .
git commit -m "Update Grafana to 10.2.0"
git push

# Watch ArgoCD sync the change automatically
```

### **Key GitOps Learning Benefits**
- **Declarative** - Everything defined in Git
- **Automated** - Changes deploy automatically
- **Auditable** - Git history = deployment history
- **Rollback** - Easy to revert via Git
- **Drift detection** - ArgoCD shows configuration drift
- **Health monitoring** - Visual status of all applications

## Cluster Configuration

The observability stack is designed to work with different Kubernetes clusters by using a centralized configuration system:

### **Configuration Files**
- **`config/cluster-config.env`**: Main configuration file - edit this to set your cluster IP
- **`vector-client-config.toml.template`**: Template for Vector client configuration  
- **`scripts/load-config.sh`**: Loads configuration for use in scripts
- **`scripts/configure-vector.sh`**: Generates Vector config from template

### **Setting Up for a New Cluster**
```bash
# 1. Update cluster IP
vi config/cluster-config.env
# Change: CLUSTER_IP=192.168.122.27 to your cluster IP

# 2. Generate Vector configuration
./scripts/configure-vector.sh

# 3. Test the configuration
./scripts/test-operational-logs.sh
./scripts/test-security-logs.sh
```

### **Configuration Variables**
- **`CLUSTER_IP`**: Main cluster IP address (edit this in config/cluster-config.env)
- **`OTEL_HTTP_ENDPOINT`**: Auto-generated from CLUSTER_IP
- **`OTEL_GRPC_ENDPOINT`**: Auto-generated from CLUSTER_IP  
- **`QUICKWIT_ENDPOINT`**: Auto-generated from CLUSTER_IP

**Note**: Replace `[CLUSTER_IP]` with your actual cluster IP configured in `config/cluster-config.env`

This setup gives you hands-on experience with production GitOps patterns and comprehensive log management!

## Appendix: Client Configuration

### **Hosts File Configuration**

To access the web interfaces from client machines, add the following entries to your hosts file:

**Linux/Mac**: `/etc/hosts`  
**Windows**: `C:\Windows\System32\drivers\etc\hosts`

```
192.168.122.27 grafana.k3s.local
192.168.122.27 argocd.k3s.local
192.168.122.27 loki.k3s.local
192.168.122.27 quickwit.k3s.local
192.168.122.27 otel.k3s.local
192.168.122.27 observable.k3s.local
```

**Note**: Replace `192.168.122.27` with your actual k3s cluster IP address from `config/cluster-config.env`

### **Editing Hosts File**

```bash
# Linux/Mac
sudo nano /etc/hosts

# Windows (as Administrator)
notepad C:\Windows\System32\drivers\etc\hosts
```

After updating the hosts file, you can access all web interfaces using the `.k3s.local` domains listed in the [Access Points](#access-points) section.

### **Observable Framework Dashboard Files**

The Observable Framework dashboard is located in the following directory structure:

```
apps/observable/
├── minimal.yaml                    # Current active ConfigMap with dashboard HTML
├── observable-deployment.yaml     # Kubernetes deployment configuration  
├── observable-service.yaml        # LoadBalancer service (port 3000)
├── observable-ingress.yaml        # Ingress for observable.k3s.local
├── observable-pvc.yaml            # Persistent storage (2Gi)
├── kustomization.yaml             # Kustomize configuration
├── example-dashboard.md           # Example Observable Framework markdown dashboard
├── observablehq.config.js         # Observable Framework configuration
├── src/
│   ├── index.md                   # Main dashboard page (markdown format)
│   └── data/
│       ├── loki-loader.py         # Python data loader for Loki API
│       └── quickwit-loader.py     # Python data loader for Quickwit API
└── Dockerfile                     # Custom container definition (if building custom image)
```

**Dashboard Configuration:**
- **Framework**: Observable Framework with conda environment
- **Dashboard URL**: http://observable.k3s.local or http://192.168.122.27:31451
- **Main Dashboard**: `apps/observable/src/index.md` (markdown with JavaScript)
- **Configuration**: `apps/observable/conda-configmap.yaml`

**Available Dashboards:**
1. **Main Dashboard** (`src/index.md`) - Overview with real-time data
2. **Security Analysis** (`src/security-analysis.md`) - Advanced security analytics
3. **Operational Insights** (`src/operational-insights.md`) - System performance and logs

**Python Data Loaders:**
- **Loki Logs** (`src/data/loki-logs.py`) - Operational log analysis with Polars
- **Quickwit Logs** (`src/data/quickwit-logs.py`) - Security log analysis with Pandas  
- **Metrics** (`src/data/metrics.py`) - Prometheus metrics collection

**Python Environment:**
- **Dependencies**: `apps/observable/requirements.txt` and `environment.yml`
- **Packages**: polars, pandas, requests, matplotlib, seaborn, numpy, scipy
- **Conda Environment**: `observable-env`

**To Add New Dashboards (GitOps Workflow):**
1. **Add Dashboard**: Create new `.md` files in `apps/observable/dashboards-configmap.yaml`
2. **Add Data Loaders**: Create new Python loaders in `apps/observable/src/data/`
3. **Update Dependencies**: Modify `requirements.txt` or `environment.yml` if needed
4. **Commit & Push**: 
   ```bash
   git add apps/observable/
   git commit -m "Add new dashboard: your-dashboard-name"
   git push
   ```
5. **Auto-Deploy**: ArgoCD automatically syncs changes within ~3 minutes
6. **Verify**: Access new dashboard at `http://observable.k3s.local/your-dashboard-name`

**Dashboard File Structure in ConfigMap:**
```yaml
# In apps/observable/dashboards-configmap.yaml
data:
  your-dashboard.md: |
    # Your Dashboard Title
    
    ```js
    const data = FileAttachment("data/your-data-loader.json").json();
    ```
    
    Your dashboard content here...
```

## Complete Workflow: Adding New Dashboards

### **Step-by-Step Guide:**

#### **1. Create Your Dashboard**
Edit the dashboards ConfigMap file:
```bash
vim apps/observable/dashboards-configmap.yaml
```

#### **2. Add Dashboard Content**
Add your dashboard under the `data:` section:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: observable-dashboards
  namespace: observable
data:
  # Existing dashboards...
  
  # Your new dashboard
  my-analytics.md: |
    # My Analytics Dashboard
    
    Custom analysis of application metrics and logs.
    
    ```js
    // Load data from Python loaders
    const appLogs = FileAttachment("data/loki-logs.json").json();
    const securityData = FileAttachment("data/quickwit-logs.json").json();
    const metrics = FileAttachment("data/metrics.json").json();
    ```
    
    ## Application Performance
    
    ```js
    // Filter for application logs
    const appData = appLogs.filter(d => d.service_name.includes("my-app"));
    const errorRate = (appData.filter(d => d.level === "error").length / appData.length * 100).toFixed(2);
    ```
    
    <div class="metric-card">
      <h3>Error Rate</h3>
      <div class="metric-value">${errorRate}%</div>
    </div>
    
    ## Response Time Analysis
    
    ```js
    // Group logs by hour for trend analysis
    const hourlyData = d3.rollup(
      appData,
      v => v.length,
      d => d3.timeHour(new Date(d.timestamp))
    );
    
    const trendData = Array.from(hourlyData, ([hour, count]) => ({
      time: new Date(hour),
      requests: count
    }));
    ```
    
    ```js
    Plot.plot({
      title: "Request Volume Over Time",
      width: 800,
      height: 300,
      x: {type: "time", label: "Time"},
      y: {label: "Requests per Hour"},
      marks: [
        Plot.lineY(trendData, {x: "time", y: "requests", stroke: "#007bff"}),
        Plot.dotY(trendData, {x: "time", y: "requests", fill: "#007bff"})
      ]
    })
    ```
    
    ## Top Error Messages
    
    ```js
    const errorMessages = d3.rollup(
      appData.filter(d => d.level === "error"),
      v => v.length,
      d => d.message.substring(0, 100) + "..."
    );
    
    const topErrors = Array.from(errorMessages, ([message, count]) => ({message, count}))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);
    ```
    
    ```js
    Inputs.table(topErrors, {
      columns: ["message", "count"],
      header: {message: "Error Message", count: "Occurrences"},
      width: {message: 500, count: 100}
    })
    ```
```

#### **3. Optional: Add Custom Data Loader**
If you need custom data processing, add a Python loader in the main ConfigMap:
```yaml
# In apps/observable/simple-gitops-configmap.yaml, add under data:
  my-custom-loader.py: |
    #!/usr/bin/env python3
    import os
    import json
    import requests
    from datetime import datetime, timedelta
    
    def fetch_custom_data():
        # Your custom data fetching logic here
        # Example: fetch from custom API, process logs, etc.
        
        custom_endpoint = os.getenv('CUSTOM_API_ENDPOINT', 'http://my-api:8080')
        
        try:
            response = requests.get(f"{custom_endpoint}/api/metrics", timeout=10)
            if response.status_code == 200:
                data = response.json()
                
                # Process and enhance data
                processed_data = []
                for item in data:
                    processed_data.append({
                        'timestamp': item.get('timestamp', int(datetime.now().timestamp() * 1000)),
                        'value': item.get('value', 0),
                        'category': item.get('type', 'unknown'),
                        # Add your custom fields
                    })
                
                print(json.dumps(processed_data, indent=2))
            else:
                print(json.dumps([]))
                
        except Exception as e:
            print(f"Error: {e}", file=sys.stderr)
            print(json.dumps([]))
    
    if __name__ == "__main__":
        fetch_custom_data()
```

#### **4. Update Dependencies (if needed)**
If your data loader needs additional Python packages:
```yaml
# In apps/observable/simple-gitops-configmap.yaml, update the pip install line:
pip3 install --break-system-packages polars pandas requests matplotlib seaborn numpy scipy your-new-package
```

#### **5. Commit and Deploy**
```bash
# Add your changes
git add apps/observable/

# Commit with descriptive message
git commit -m "feat: add custom analytics dashboard with error tracking"

# Push to trigger GitOps deployment
git push origin main
```

#### **6. Verify Deployment**
```bash
# Monitor ArgoCD sync (should complete within 3 minutes)
kubectl get applications -n argocd observable

# Check if pods restarted
kubectl get pods -n observable

# View your dashboard
open http://observable.k3s.local/my-analytics
```

### **Dashboard Features You Can Use:**

#### **Data Sources:**
- `data/loki-logs.json` - Operational logs from Loki
- `data/quickwit-logs.json` - Security logs from Quickwit  
- `data/metrics.json` - System metrics from Prometheus

#### **Visualization Libraries:**
- **Observable Plot** - Built-in charting library
- **D3.js** - Advanced data manipulation and custom charts
- **Inputs** - Interactive tables, dropdowns, sliders

#### **JavaScript Features:**
```js
// Data processing with D3
const grouped = d3.rollup(data, v => v.length, d => d.category);

// Date/time handling
const lastHour = data.filter(d => d.timestamp > Date.now() - 3600000);

// Statistical calculations
const average = d3.mean(data, d => d.value);
const percentile95 = d3.quantile(data.map(d => d.value).sort(), 0.95);

// Real-time status indicators
const status = data.length > 0 ? "🟢 Online" : "🔴 Offline";
```

#### **CSS Styling:**
Use the built-in CSS classes:
- `.metric-grid` - Grid layout for metrics
- `.metric-card` - Individual metric display
- `.service-grid` - Service link grid
- Custom CSS can be added inline in your markdown

### **Best Practices:**

1. **Performance**: Limit data to recent time ranges (last 1-2 hours)
2. **Error Handling**: Always provide fallbacks for missing data
3. **Responsive Design**: Use CSS Grid for mobile-friendly layouts
4. **Descriptive Names**: Use clear, descriptive dashboard file names
5. **Documentation**: Add comments explaining complex data transformations

### **Troubleshooting:**

- **404 Error**: Check file name matches URL (e.g., `my-dashboard.md` → `/my-dashboard`)
- **No Data**: Verify data loaders are working: `kubectl logs -n observable -l app=observable`
- **Deployment Issues**: Check ArgoCD UI at http://argocd.k3s.local
- **Syntax Errors**: Validate YAML syntax before committing

**To Update Python Dependencies:**
1. Edit `apps/observable/requirements.txt` or `environment.yml`
2. Rebuild the Docker image or restart pods to install new packages
3. Update deployment with new image if needed

**Docker Image Build:**
```bash
cd apps/observable/
docker build -t observability-observable:latest .
# Push to your registry and update conda-deployment.yaml image reference
```