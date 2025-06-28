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
# Get credentials
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Access UI (use Host header)
curl -H "Host: argocd.k3s.local" http://192.168.122.27/
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

- **ArgoCD UI**: http://argocd.k3s.local
- **Grafana**: http://grafana.k3s.local
- **OTel Endpoint**: http://[CLUSTER_IP]:4318/v1/logs
- **Quickwit**: http://quickwit.k3s.local  
- **Loki**: http://loki.k3s.local

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

Test log routing with the provided scripts:

```bash
# Test operational logs → Loki
./scripts/test-operational-logs.sh

# Test security logs → Quickwit  
./scripts/test-security-logs.sh
```

Both scripts send JSON logs with 15+ structured fields for comprehensive testing.

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