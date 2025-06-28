# GitOps Observability Stack

Complete observability stack managed by ArgoCD for learning GitOps principles.

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

## Access ArgoCD UI

```bash
# Get ArgoCD admin credentials
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""  # Line break for easier copy-paste

# Access ArgoCD UI
# Open http://argocd.k3s.local in browser
# Or via curl: curl -H "Host: argocd.k3s.local" http://192.168.122.27/
```

## GitOps Workflow

1. Make changes to any YAML in `apps/`
2. Commit and push to your Git repository
3. ArgoCD automatically syncs changes to cluster
4. Monitor in ArgoCD UI - see deployment status, health, sync status

## Applications Managed by ArgoCD

- **Grafana** (`apps/grafana/`)
- **Loki** (`apps/loki/`)
- **OpenTelemetry Collector** (`apps/otel/`)
- **Quickwit** (`apps/quickwit/`)

## Learning GitOps

- **App of Apps pattern** - ArgoCD manages multiple applications
- **Automated sync** - Changes in Git trigger deployments
- **Self-healing** - ArgoCD fixes configuration drift
- **Rollback capability** - Easy rollback to previous Git commits
- **Health monitoring** - Visual health status of all components

## Making Changes

```bash
# Example: Update Grafana image
vi apps/grafana/grafana-deployment.yaml
# Change image: grafana/grafana:latest to grafana/grafana:10.2.0

git add .
git commit -m "Update Grafana to 10.2.0"
git push

# Watch ArgoCD sync the change automatically
```

## Access Points

### **Web Interfaces**
- **ArgoCD UI**: http://argocd.k3s.local
  - Username: admin  
  - Password: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
- **Grafana**: http://grafana.k3s.local  
  - Username: admin
  - Password: admin
- **Quickwit UI**: http://quickwit.k3s.local  
- **Loki**: http://loki.k3s.local

### **API Endpoints**
- **OTel HTTP**: http://[CLUSTER_IP]:4318/v1/logs
- **OTel gRPC**: http://[CLUSTER_IP]:4317
- **Loki API**: http://[CLUSTER_IP]:3100/loki/api/v1/
  - Query Range: `/query_range?query={job=~".+"}&start=[timestamp]&end=[timestamp]&limit=10`
  - Recent Logs: `/query_range?query={job=~".+"}&start=$(date -d '1 hour ago' +%s)000000000&end=$(date +%s)000000000&limit=10`
- **Quickwit API**: http://[CLUSTER_IP]:7280/api/v1/
  - Search: `/otel-logs-v0_7/search` (POST with JSON query)
  - Recent Logs: `{"query": "*", "max_hits": 10}` for latest entries

## Data Sources in Grafana

- **Loki**: http://loki.loki-system.svc.cluster.local:3100
- **Quickwit**: http://[CLUSTER_IP]:7280/api/v1 (indexes: otel-logs-v0_7, otel-traces-v0_7)

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

### **OpenTelemetry Log Routing Logic**

The OTEL Collector automatically classifies and routes logs based on content analysis:

**Security Logs Route to Quickwit when:**
- `attributes["log_type"] == "security"`
- `attributes["category"] == "auth"` or `"audit"`
- Log body contains keywords: `login|logout|auth|failed|denied|unauthorized|privilege|sudo|ssh|firewall|intrusion|malware|virus|attack`

**Operational Logs Route to Loki for:**
- All other logs (default route)
- Application performance logs
- Infrastructure monitoring
- System health metrics

### **OTEL Endpoints**

- **HTTP Ingestion**: `http://[CLUSTER_IP]:4318/v1/logs`
- **gRPC Ingestion**: `http://[CLUSTER_IP]:4317` 
- **Internal Routing**: Automatic based on log content classification

**Note**: Replace `[CLUSTER_IP]` with your actual cluster IP configured in `config/cluster-config.env`

## Data Retention

- **Loki**: No retention policy configured (manual cleanup required)
- **Quickwit**: Persistent storage (5Gi PVC) - data survives pod restarts
- **Grafana**: Persistent storage (1Gi PVC) - data survives pod restarts
- **OTEL Collector**: No persistent storage (ephemeral)

## Architecture

```
Vector/Clients → OpenTelemetry Collector → {Loki (operational), Quickwit (security)}
                           ↓                    ↓
                   Grafana (dashboards)  Grafana (search)
```

### **Vector Client Configuration**

Vector clients collect logs from multiple sources and forward to OTEL:

- **journald**: System service logs  
- **docker**: Container logs
- **auditd**: Security audit logs (`/var/log/audit/audit.log`)

**Log Classification**: Vector automatically tags logs with `log_type` and `category` based on:
- Source file paths (auditd → security)
- Log content analysis (auth keywords → security)  
- Default routing (everything else → operational)

**Installation**: 
1. Configure cluster IP: `vi config/cluster-config.env`
2. Generate config: `./scripts/configure-vector.sh`  
3. Install: `./vector-install.sh`

## Testing the Log Pipeline

### **Sending Test Logs**

Send test logs to validate the entire pipeline:

```bash
# Send operational logs to Loki via OTEL
./scripts/test-operational-logs.sh
```
- Sends 2 operational log entries with 15+ structured fields
- Includes web server request log and database error log
- Routes through OTEL → Loki for operational monitoring

```bash  
# Send security logs to Quickwit via OTEL
./scripts/test-security-logs.sh
```
- Sends 3 security log entries with 15+ structured fields  
- Includes SSH auth failure, sudo privilege escalation, and firewall block
- Routes through OTEL → Quickwit for security analysis

### **Retrieving Logs**

Query the centralized log collection services:

```bash
# Get latest 10 logs from Quickwit (security logs)
./scripts/get-quickwit-logs.sh
```
- Queries Quickwit REST API at `http://CLUSTER_IP:7280`
- Shows security events, auth logs, and audit trails sorted by timestamp (newest first)
- Provides query examples for specific security log types
- **Note**: May take 10-30 seconds for new logs to appear in search index

```bash
# Get latest 10 logs from Loki (operational logs)  
./scripts/get-loki-logs.sh
```
- Queries Loki REST API at `http://CLUSTER_IP:3100`
- Shows operational logs, application events, and infrastructure logs from last 24 hours
- Includes examples for time-range and label-based queries
- **Note**: Logs appear almost immediately after ingestion

### **Complete Testing Workflow**

```bash
# 1. Configure cluster IP
vi config/cluster-config.env

# 2. Generate Vector client config
./scripts/configure-vector.sh

# 3. Send test logs to validate routing
./scripts/test-operational-logs.sh
./scripts/test-security-logs.sh

# 4. Wait for logs to be processed (10-30 seconds)
sleep 30

# 5. Retrieve and verify logs
./scripts/get-loki-logs.sh
./scripts/get-quickwit-logs.sh

# 6. View in Grafana dashboard
# Open http://grafana.k3s.local (admin/admin)
```

### **Grafana Integration**

Grafana comes pre-configured with datasources and dashboards:

**Access:**
- **URL**: http://grafana.k3s.local 
- **Username**: admin
- **Password**: admin

**Pre-configured Datasources:**

1. **Loki Datasource**
   - **Name**: Loki
   - **Type**: loki  
   - **URL**: `http://loki.loki-system.svc.cluster.local:3100`
   - **Purpose**: Query operational logs, application logs, infrastructure events
   - **Features**: Time-series log aggregation, label-based filtering, fast time-range queries
   - **Max Lines**: 1000 (configurable)

2. **Quickwit Datasource**
   - **Name**: Quickwit
   - **Type**: yesoreyeram-infinity-datasource
   - **URL**: `http://quickwit.quickwit-system.svc.cluster.local:7280`
   - **Purpose**: Full-text search on security logs, audit trails, compliance data
   - **Pre-configured Queries**:
     - Security Logs: `log_type:security` (100 results)
     - Auth Logs: `category:auth` (100 results)
     - All Logs: `*` (50 results)
   - **API Endpoint**: `/api/v1/otel-logs-v0_7/search`

**Pre-installed Plugins:**
- `yesoreyeram-infinity-datasource` - Enables REST API datasources for Quickwit integration

**Default Dashboard:**
- **"Observability Overview"** - Shows recent operational logs from Loki and security events from Quickwit

### **Finding Most Recent Logs**

**In Loki Datasource:**
1. **Explore Tab**: Go to Grafana → Explore → Select "Loki" datasource
2. **Query Recent Logs**: Use LogQL queries:
   ```logql
   # All recent logs (last 1 hour)
   {job=~".+"}
   
   # Recent operational logs only
   {log_type="operational"}
   
   # Recent logs from specific service
   {service_name="web-server"}
   
   # Recent error logs
   {level="ERROR"} or {severity="error"}
   ```
3. **Time Range**: Set to "Last 15 minutes" or "Last 1 hour" for most recent
4. **Live Tail**: Click "Live" button for real-time log streaming

**In Quickwit Datasource:**
1. **Explore Tab**: Go to Grafana → Explore → Select "Quickwit" datasource
2. **Use Pre-configured Queries**:
   - Select "Security Logs" global query for recent security events
   - Select "Auth Logs" for recent authentication events
   - Select "All Logs" for recent logs of any type
3. **Custom Queries**: Create new query with:
   ```json
   {
     "query": "*",
     "max_hits": 50,
     "start_timestamp": "now-1h",
     "end_timestamp": "now"
   }
   ```
4. **Sort Results**: Results automatically ordered by timestamp (newest first)

**Via Command Line Scripts:**
```bash
# Get 10 most recent operational logs
./scripts/get-loki-logs.sh

# Get 10 most recent security logs  
./scripts/get-quickwit-logs.sh
```

**Note**: Both Loki and Quickwit are now configured as LoadBalancer services for external access.

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

**Key GitOps Learning Benefits:**
- **Declarative** - Everything defined in Git
- **Automated** - Changes deploy automatically
- **Auditable** - Git history = deployment history
- **Rollback** - Easy to revert via Git
- **Drift detection** - ArgoCD shows configuration drift
- **Health monitoring** - Visual status of all applications

This setup gives you hands-on experience with production GitOps patterns!