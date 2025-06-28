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

This observability stack implements a **dual-pipeline log routing architecture** with 7 main components:

### **Core Services**
- **Vector** - Log collection (DaemonSet + client installations)
- **OpenTelemetry Collector** - Central log routing hub
- **Loki** - Time-series log storage for operational monitoring
- **Quickwit** - Full-text search engine for security analysis
- **Grafana** - Dashboards and operational log analysis
- **Prometheus** - Metrics collection and monitoring
- **ArgoCD** - GitOps automation and deployment management

### **Architecture Flow**
```
Vector/Clients → OpenTelemetry Collector → {Loki (operational), Quickwit (security)}
                           ↓                    ↓
                   Grafana (dashboards)  Quickwit UI (search)
                           ↓
                  Prometheus (metrics)
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
- **Quickwit UI**: http://quickwit.k3s.local/ui/search
  - **Purpose**: Security log analysis and full-text search
- **Loki**: http://loki.k3s.local

### **Applications Managed by ArgoCD**
- **Grafana** (`apps/grafana/`) - Dashboards and visualization
- **Loki** (`apps/loki/`) - Operational log storage
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