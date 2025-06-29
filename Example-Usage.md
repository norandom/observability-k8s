# 📋 Example Usage Guide

Complete guide for using the observability stack with live dashboard development and demo data.

## 🚀 Quick Start Demo

### 1. **Find Observable Container for Development**

```bash
# Get the current Observable pod name (use this for all kubectl cp operations)
POD_NAME=$(kubectl get pods -n observable -l app=observable,component=dashboard -o jsonpath='{.items[0].metadata.name}')
echo "Observable Pod: $POD_NAME"

# Verify pod is running
kubectl get pod -n observable $POD_NAME

# Check pod status and ready state
kubectl describe pod -n observable $POD_NAME
```

### 2. **Send Demo Logs to Both Systems**

Distinguish demo logs from live system logs using `[DEMO]` prefix:

```bash
# Send operational demo logs to Loki (via OTEL Collector)
./scripts/test-operational-logs.sh

# Send security demo logs to Quickwit (via OTEL Collector)  
./scripts/test-security-logs.sh

# Send additional demo logs with distinct markers
curl -X POST "http://192.168.122.27:4318/v1/logs" \
-H "Content-Type: application/json" \
-d '{
  "resourceLogs": [{
    "resource": {
      "attributes": [
        {"key": "service.name", "value": {"stringValue": "demo-web-application"}},
        {"key": "service.version", "value": {"stringValue": "1.2.3"}},
        {"key": "demo_data", "value": {"stringValue": "true"}}
      ]
    },
    "scopeLogs": [{
      "logRecords": [{
        "timeUnixNano": "'$(date +%s%N)'",
        "severityText": "INFO",
        "body": {"stringValue": "[DEMO] User login successful - Username: alice, Session: sess_12345"},
        "attributes": [
          {"key": "log_type", "value": {"stringValue": "operational"}},
          {"key": "category", "value": {"stringValue": "auth"}},
          {"key": "username", "value": {"stringValue": "alice"}},
          {"key": "demo_data", "value": {"stringValue": "true"}}
        ]
      }]
    }]
  }]
}'

# Wait for logs to be processed
sleep 10
```

### 3. **Verify Demo Data in Systems**

```bash
# Check demo logs in Loki
curl -G 'http://192.168.122.27:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job=~".+"} |= "[DEMO]"' \
  --data-urlencode 'limit=10'

# Check demo logs in Quickwit
curl -X POST 'http://192.168.122.27:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "demo_data:true", "max_hits": 10}'
```

## 🛠️ Dashboard Development Workflow

### 1. **Container Access and Environment Setup**

```bash
# Access the Observable container with bash shell
kubectl exec -it -n observable $POD_NAME -- bash

# Inside container - verify conda environment
conda info --envs
conda activate observable

# Check available packages
conda list | grep -E "(pandas|polars|requests)"

# Python environment check
python --version
which python
```

### 2. **Copy Dashboard Files**

```bash
# Copy dashboard files to running container
kubectl cp security.md observable/$POD_NAME:/app/src/security.md
kubectl cp operations.md observable/$POD_NAME:/app/src/operations.md

# Copy Python data loaders
kubectl cp your-data-loader.py observable/$POD_NAME:/app/src/data/your-loader.py

# Copy conda environment file for package management
kubectl cp apps/observable/environment.yml observable/$POD_NAME:/workspace/environment.yml

# Verify files were copied
kubectl exec -n observable $POD_NAME -- ls -la /app/src/
```

### 3. **Live Development Inside Container**

```bash
# Access container for live development
kubectl exec -it -n observable $POD_NAME -- bash

# Inside container: activate conda environment
conda activate observable

# Navigate to dashboard directory
cd /app/src

# Edit files directly (vi is available)
vi security.md
vi operations.md

# Test Python data loaders
cd data
python loki-loader.py
python quickwit-loader.py

# Install additional packages as needed
conda install -n observable scikit-learn statsmodels
# or
conda env update -f /workspace/environment.yml
```

### 4. **Data Loader Development**

Create Python data loaders that fetch from Loki and Quickwit APIs:

```bash
# Inside container, create operational data loader
cat > /app/src/data/loki-logs.py << 'EOF'
#!/usr/bin/env python
import json
import urllib.request
import urllib.parse
from datetime import datetime, timedelta

def fetch_loki_logs():
    """Fetch operational logs from Loki API"""
    loki_endpoint = "http://192.168.122.27:3100"
    
    # Query last hour of logs
    end_time = datetime.now()
    start_time = end_time - timedelta(hours=1)
    
    params = {
        'query': '{job=~".+"}',
        'start': str(int(start_time.timestamp() * 1e9)),
        'end': str(int(end_time.timestamp() * 1e9)),
        'limit': '50'
    }
    
    url = f"{loki_endpoint}/loki/api/v1/query_range?{urllib.parse.urlencode(params)}"
    
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode())
    
    # Process logs for Observable Framework
    logs = []
    if 'data' in data and 'result' in data['data']:
        for stream in data['data']['result']:
            for entry in stream.get('values', []):
                timestamp_ns, log_line = entry
                timestamp = datetime.fromtimestamp(int(timestamp_ns) / 1e9)
                
                try:
                    log_data = json.loads(log_line)
                    if isinstance(log_data, dict):
                        log_entry = log_data.copy()
                    else:
                        log_entry = {'message': str(log_data)}
                except:
                    log_entry = {'message': log_line}
                
                log_entry.update({
                    'timestamp': timestamp.isoformat(),
                    'time': timestamp.isoformat()
                })
                logs.append(log_entry)
    
    return sorted(logs, key=lambda x: x['timestamp'], reverse=True)

if __name__ == "__main__":
    print(json.dumps(fetch_loki_logs(), indent=2))
EOF

# Generate operational data
python loki-logs.py > loki-logs.json
```

### 5. **Test Dashboard Updates**

```bash
# Check Observable Framework is running
curl localhost:3000

# View dashboards in browser
# Main: http://observable.k3s.local
# Security: http://observable.k3s.local/security  
# Operations: http://observable.k3s.local/operations

# Check logs for errors
kubectl logs -n observable $POD_NAME --tail=20
```

## 📊 Dashboard Data Integration

### **Operational Dashboard (Loki Data)**

The operations dashboard uses data from Loki:

```javascript
// In operations.md
const operationalLogs = FileAttachment("data/loki-logs.json").json();

// Filter for demo vs live data
const demoLogs = operationalLogs.filter(log => 
  log.message?.includes("[DEMO]") || log.demo_data === "true"
);

const liveLogs = operationalLogs.filter(log => 
  !log.message?.includes("[DEMO]") && log.demo_data !== "true"
);
```

### **Security Dashboard (Quickwit Data)**

The security dashboard uses data from Quickwit:

```javascript
// In security.md  
const securityLogs = FileAttachment("data/quickwit-logs.json").json();

// Analyze authentication events
const authEvents = securityLogs.filter(log => 
  log.category === "auth" || 
  log.message?.toLowerCase().includes("login") ||
  log.message?.toLowerCase().includes("ssh")
);
```

## 🔄 Development Iteration Cycle

1. **Edit** dashboard markdown files locally
2. **Copy** files to container: `kubectl cp file.md observable/$POD_NAME:/app/src/file.md`
3. **Refresh** browser - Observable Framework auto-reloads
4. **Test** data loaders: `kubectl exec -it -n observable $POD_NAME -- python /app/src/data/loader.py`
5. **Repeat** - instant feedback loop

## 🔍 Troubleshooting

### **Container Issues**
```bash
# Check pod status
kubectl get pods -n observable
kubectl describe pod -n observable $POD_NAME

# Check logs
kubectl logs -n observable $POD_NAME --tail=50

# Restart deployment if needed
kubectl rollout restart deployment observable -n observable
```

### **🚀 Monitoring Container Build Status**

The Observable Framework container goes through several setup phases. Use these commands to monitor progress:

#### **1. Check Overall Pod Status**
```bash
# Get current pod name and status
POD_NAME=$(kubectl get pods -n observable -l app=observable,component=dashboard -o jsonpath='{.items[0].metadata.name}')
echo "Observable Pod: $POD_NAME"

# Check if pod is ready
kubectl get pod -n observable $POD_NAME
```

#### **2. Monitor Setup Progress**
```bash
# Watch setup logs in real-time
kubectl logs -n observable $POD_NAME -f

# Check specific setup phases
kubectl logs -n observable $POD_NAME | grep -E "(Node.js|npm|conda|Observable)"

# Check last 20 lines of logs
kubectl logs -n observable $POD_NAME --tail=20
```

#### **3. Build Status Indicators**

**Phase 1: Node.js Installation**
```bash
# Look for these messages:
# "Setting up nodejs" - Node.js being installed
# "v20.x.x" and "npm 10.x.x" - Version confirmation
```

**Phase 2: Conda Environment Setup**
```bash
# Look for these messages:
# "Collecting package metadata" - Conda resolving packages
# "Downloading and Extracting Packages" - Installing Python packages
# "Preparing transaction: done" - Conda environment ready
```

**Phase 3: Observable Framework Startup**
```bash
# Look for these messages:
# "Observable Framework starting on port 3000"
# "Observable Framework listening" - Server ready
```

#### **4. Test Container Readiness**
```bash
# Test if Observable Framework is running
kubectl exec -n observable $POD_NAME -- bash -c "curl -s localhost:3000 > /dev/null && echo 'Observable Framework ready' || echo 'Still starting...'"

# Check if conda environment exists
kubectl exec -n observable $POD_NAME -- bash -c "conda info --envs | grep observable || echo 'Conda env not ready'"

# Test npm availability
kubectl exec -n observable $POD_NAME -- bash -c "npm --version 2>/dev/null || echo 'npm not ready'"
```

#### **5. Expected Timing**
- **Node.js Installation**: 30-60 seconds
- **Conda Environment**: 2-5 minutes (downloads 300+ MB of packages)
- **Observable Framework**: 10-30 seconds
- **Total Setup Time**: 3-7 minutes

#### **6. Common Build Issues**

**Pod Restarts Multiple Times:**
```bash
# Check previous container logs for errors
kubectl logs -n observable $POD_NAME --previous

# Look for specific errors:
# "npm: command not found" - Node.js installation failed
# "EnvironmentNameNotFound" - Conda environment creation failed
# "exec: npm: not found" - PATH issues
```

**Conda Taking Too Long:**
```bash
# Check if conda is downloading packages
kubectl logs -n observable $POD_NAME | grep -E "(Downloading|Extracting|MB)"

# If stuck, restart deployment
kubectl rollout restart deployment observable -n observable
```

**Observable Framework Not Starting:**
```bash
# Check port 3000 is listening
kubectl exec -n observable $POD_NAME -- bash -c "netstat -tlnp | grep 3000"

# Test direct access
kubectl port-forward -n observable $POD_NAME 3000:3000 &
curl http://localhost:3000
```

#### **7. Quick Health Check Script**
```bash
#!/bin/bash
POD_NAME=$(kubectl get pods -n observable -l app=observable,component=dashboard -o jsonpath='{.items[0].metadata.name}')

echo "=== Observable Container Health Check ==="
echo "Pod: $POD_NAME"
echo

# Pod status
echo "Pod Status:"
kubectl get pod -n observable $POD_NAME

# Container readiness
echo -e "\nContainer Readiness:"
kubectl exec -n observable $POD_NAME -- bash -c "
  echo 'Node.js:' && node --version 2>/dev/null || echo 'Not ready'
  echo 'npm:' && npm --version 2>/dev/null || echo 'Not ready'
  echo 'Conda envs:' && conda info --envs | grep observable || echo 'Not ready'
  echo 'Port 3000:' && netstat -tlnp | grep 3000 || echo 'Not listening'
"

# Recent logs
echo -e "\nRecent Logs:"
kubectl logs -n observable $POD_NAME --tail=5
```

### **Data Loading Issues**
```bash
# Test APIs directly
curl "http://192.168.122.27:3100/loki/api/v1/query_range?query={job=~\".+\"}&limit=5"
curl -X POST "http://192.168.122.27:7280/api/v1/otel-logs-v0_7/search" \
  -H "Content-Type: application/json" -d '{"query":"*","max_hits":5}'

# Test data loaders manually
kubectl exec -n observable $POD_NAME -- python /app/src/data/loki-loader.py
kubectl exec -n observable $POD_NAME -- python /app/src/data/quickwit-loader.py
```

### **Environment Issues**
```bash
# Inside container: check conda environment
conda info --envs
conda activate observable
conda list

# Install missing packages
conda install package-name
# or update from environment.yml
conda env update -f /workspace/environment.yml
```

## 📝 Package Management

### **Adding New Dependencies**

1. **Edit environment.yml** locally:
```yaml
# Add packages under dependencies:
- scikit-learn>=1.3.0
- statsmodels>=0.14.0
```

2. **Copy and update environment**:
```bash
kubectl cp environment.yml observable/$POD_NAME:/workspace/environment.yml
kubectl exec -it -n observable $POD_NAME -- conda env update -f /workspace/environment.yml
```

3. **Commit changes** for permanent deployment:
```bash
git add environment.yml
git commit -m "Add data science packages"
git push
```

## 🎯 Demo Scenarios

### **Security Incident Investigation**
1. Send security demo logs with attack patterns
2. Open security dashboard: `http://observable.k3s.local/security`
3. Analyze authentication failures, port scans, injection attempts
4. Use Quickwit UI for detailed investigation: `http://quickwit.k3s.local/ui/search`

### **Operations Monitoring**
1. Send operational demo logs with various service events
2. Open operations dashboard: `http://observable.k3s.local/operations`
3. Monitor service health, error rates, performance metrics
4. Use Grafana for time-series analysis: `http://grafana.k3s.local`

### **Custom Analytics Development**
1. Access container: `kubectl exec -it -n observable $POD_NAME -- bash`
2. Create custom data analysis in Python with pandas/polars
3. Export results as JSON for Observable Framework
4. Build interactive visualizations with Observable Plot
5. Iterate rapidly with hot reload

This workflow enables rapid development of data-driven dashboards with immediate feedback and access to the full Python data science ecosystem through conda.