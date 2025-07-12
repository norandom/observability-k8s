# Example Usage & Tutorials

## Tutorial 1: Creating Your First Security Dashboard

### Step 1: Start Development Environment
```bash
# Intercept Observable Framework traffic
./scripts/telepresence-observable-connect.sh intercept

# Verify you can edit files locally
ls -la src/  # Should show container files
```

### Step 2: Create Security Dashboard with AI
```bash
# Option A: Use Claude Code
code .  # Open in VS Code with Claude Code extension
# Ask Claude: "Create a security dashboard showing failed login attempts from Quickwit API"

# Option B: Use Gemini CLI
gemini chat "Help me create an Observable Framework dashboard for security analysis"
```

### Step 3: Implement Dashboard
```markdown
# src/security-analysis.md

# Security Analysis Dashboard

```js
// Load security data from Quickwit
const securityData = FileAttachment("data/quickwit-logs.json").json();

// Failed login attempts visualization
Plot.plot({
  title: "Failed Login Attempts",
  x: {type: "time", label: "Time"},
  y: {label: "Failed Attempts"},
  marks: [
    Plot.lineY(securityData.failed_logins, {x: "timestamp", y: "count", stroke: "red"})
  ]
})
```

### Step 4: Test Live
```bash
# Visit your new dashboard
curl http://localhost:3000/security-analysis

# Or open in browser
open http://observable.k3s.local/security-analysis
```

## Tutorial 2: Custom Python Data Loader

### Step 1: Mount Container Filesystem
```bash
./scripts/telepresence-observable-connect.sh local-dev
```

### Step 2: Create Data Loader
```python
# src/data/auth-events.py
import requests
import json
from datetime import datetime, timedelta

def fetch_auth_events():
    """Fetch authentication events from Quickwit"""
    quickwit_url = "http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search"
    
    query = {
        "query": "category:auth AND severity_text:ERROR",
        "max_hits": 100,
        "start_timestamp": int((datetime.now() - timedelta(hours=24)).timestamp()),
        "end_timestamp": int(datetime.now().timestamp())
    }
    
    response = requests.post(quickwit_url, json=query)
    data = response.json()
    
    return {
        "summary": {
            "total_events": len(data.get("hits", [])),
            "timeframe": "24 hours",
            "risk_level": "medium" if len(data.get("hits", [])) > 10 else "low"
        },
        "events": data.get("hits", [])
    }

if __name__ == "__main__":
    result = fetch_auth_events()
    print(json.dumps(result, indent=2))
```

### Step 3: Test Data Loader
```bash
# Test locally (accesses cluster APIs via Telepresence)
python src/data/auth-events.py > src/data/auth-events.json

# Verify data
head -20 src/data/auth-events.json
```

### Step 4: Use in Dashboard
```markdown
# src/auth-dashboard.md

```js
const authData = FileAttachment("data/auth-events.json").json();

// Display summary
html`<div class="metric-card">
  <h3>Authentication Events (24h)</h3>
  <div class="metric-value">${authData.summary.total_events}</div>
  <div class="risk-${authData.summary.risk_level}">Risk: ${authData.summary.risk_level}</div>
</div>`
```

## Tutorial 3: Real-time Debugging

### Step 1: Intercept Traffic for Debugging
```bash
./scripts/telepresence-observable-connect.sh intercept
```

### Step 2: Run Local Development Server with Debugging
```bash
# Start Observable Framework with debugging
npm run dev -- --inspect

# Or debug Python data loaders
python -m pdb src/data/loki-logs.py
```

### Step 3: Monitor Live Data Flow
```bash
# Watch log data in real-time
curl -G 'http://loki.k3s.local:3100/loki/api/v1/tail' \
  --data-urlencode 'query={job=~".+"}'

# Search security events
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "log_type:security", "max_hits": 10}'
```

## Tutorial 4: AI-Assisted Dashboard Development

### Using Claude Code for Observable Plot Visualizations
```bash
# 1. Start Telepresence intercept
./scripts/telepresence-observable-connect.sh intercept

# 2. Open VS Code with Claude Code
code .

# 3. Ask Claude Code to help with specific tasks:
# "Create an Observable Plot chart showing log volume trends over time"
# "Generate a Python script to analyze failed authentication events"
# "Build a dashboard component for system health metrics"
```

### Using Gemini CLI for Data Analysis
```bash
# 1. Mount filesystem locally
./scripts/telepresence-observable-connect.sh local-dev

# 2. Get data analysis help
gemini chat "Analyze this Quickwit security data and suggest visualization approaches"

# 3. Implement suggestions in real-time
# Edit files locally, see changes in cluster immediately
```

## Tutorial 5: Production-like Development

### Scenario: Debug Live Security Alerts
```bash
# 1. Intercept production-like traffic
./scripts/telepresence-observable-connect.sh intercept

# 2. Send test security events
./scripts/test-security-logs.sh

# 3. Debug data flow in real-time
curl http://localhost:3000/security  # Your local development server
```

### Scenario: Performance Optimization
```bash
# 1. Profile Python data loaders
python -m cProfile src/data/loki-logs.py

# 2. Test with large datasets
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -d '{"query": "*", "max_hits": 1000}'

# 3. Optimize and test locally
npm run dev -- --inspect
```

## Common Development Patterns

### Pattern 1: Dashboard + Data Loader + API Integration
```
src/
├── security-advanced.md        # Dashboard markdown
├── data/
│   └── security-analysis.py    # Python data loader
└── components/
    └── security-metrics.js     # Reusable components
```

### Pattern 2: Multi-source Data Integration
```python
# Combine Loki + Quickwit + Prometheus data
def fetch_comprehensive_data():
    loki_data = fetch_from_loki()
    security_data = fetch_from_quickwit()
    metrics_data = fetch_from_prometheus()
    
    return {
        "operational": loki_data,
        "security": security_data,
        "metrics": metrics_data,
        "combined_risk_score": calculate_risk(loki_data, security_data)
    }
```

### Pattern 3: Real-time Updates
```js
// Observable Framework supports real-time data
const liveData = FileAttachment("data/live-metrics.json").json();

// Auto-refresh every 30 seconds
setInterval(() => {
  // Trigger data reload
  location.reload();
}, 30000);
```

## Troubleshooting Examples

### Issue: Telepresence Connection Problems
```bash
# Reset Telepresence connection
telepresence quit
telepresence connect

# Check cluster connectivity
telepresence status
kubectl get pods -A
```

### Issue: Data Loader API Errors
```bash
# Test API endpoints directly
curl http://loki.k3s.local:3100/ready
curl http://quickwit.k3s.local:7280/health

# Debug with verbose output
python -v src/data/loki-logs.py
```

### Issue: Dashboard Not Updating
```bash
# Check Observable Framework status
curl http://localhost:3000/
kubectl logs -n observable -l app=observable

# Verify file sync
ls -la src/  # Should show your local changes
```

## Next Steps

1. **[Learn the architecture →](architecture.md)**
2. **[Explore API endpoints →](api-endpoints.md)**
3. **[Understand GitOps workflow →](gitops.md)**
4. **[Troubleshooting guide →](troubleshooting.md)**