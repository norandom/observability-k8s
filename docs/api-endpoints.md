# API Endpoints Documentation

## Overview

All APIs are accessible both from within the cluster and locally via Telepresence. Use these endpoints for data integration, testing, and development.

## Loki API (Operational Logs)

**Base URL**: `http://loki.k3s.local:3100`

### Query Recent Logs
```bash
# Get last 10 logs from past hour
curl -G 'http://loki.k3s.local:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job=~".+"}' \
  --data-urlencode 'start='$(date -d '1 hour ago' +%s)000000000 \
  --data-urlencode 'end='$(date +%s)000000000 \
  --data-urlencode 'limit=10'
```

### Filter by Log Level
```bash
# Query ERROR level logs only
curl -G 'http://loki.k3s.local:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job=~".+"} | json | level="ERROR"' \
  --data-urlencode 'limit=10'
```

### Real-time Log Streaming
```bash
# Tail logs in real-time
curl -G 'http://loki.k3s.local:3100/loki/api/v1/tail' \
  --data-urlencode 'query={job=~".+"}'
```

### LogQL Examples
```bash
# Service-specific logs
curl -G 'http://loki.k3s.local:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={service_name="web-server"}'

# Operational logs only
curl -G 'http://loki.k3s.local:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={log_type="operational"}'

# Text search in log messages
curl -G 'http://loki.k3s.local:3100/loki/api/v1/query_range' \
  --data-urlencode 'query={job=~".+"} |= "database"'
```

## Quickwit API (Security Logs)

**Base URL**: `http://quickwit.k3s.local:7280`

### Basic Search
```bash
# Get last 10 logs
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "*", "max_hits": 10}'
```

### Security-focused Searches
```bash
# Security logs only
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "log_type:security", "max_hits": 10}'

# Authentication events
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "category:auth", "max_hits": 10}'

# Failed login attempts
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "category:auth AND severity_text:ERROR", "max_hits": 20}'
```

### Advanced Queries
```bash
# Search by IP address
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "source_ip:203.0.113.42", "max_hits": 10}'

# Time range search (last hour)
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{
    "query": "*", 
    "max_hits": 50,
    "start_timestamp": '$(date -d '1 hour ago' +%s)',
    "end_timestamp": '$(date +%s)'
  }'

# Complex multi-condition search
curl -X POST 'http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search' \
  -H 'Content-Type: application/json' \
  -d '{"query": "log_type:security AND severity_text:ERROR AND message:firewall", "max_hits": 20}'
```

## Prometheus API (Metrics)

**Base URL**: `http://prometheus.k3s.local:9090`

### Instant Queries
```bash
# Current CPU usage
curl 'http://prometheus.k3s.local:9090/api/v1/query?query=cpu_usage_seconds_total'

# Memory usage
curl 'http://prometheus.k3s.local:9090/api/v1/query?query=memory_usage_bytes'

# Pod status
curl 'http://prometheus.k3s.local:9090/api/v1/query?query=kube_pod_status_phase'
```

### Range Queries
```bash
# CPU usage over last hour
curl -G 'http://prometheus.k3s.local:9090/api/v1/query_range' \
  --data-urlencode 'query=cpu_usage_seconds_total' \
  --data-urlencode 'start='$(date -d '1 hour ago' +%s) \
  --data-urlencode 'end='$(date +%s) \
  --data-urlencode 'step=60s'
```

## Observable Framework API

**Base URL**: `http://observable.k3s.local`

### Dashboard Access
```bash
# Main dashboard
curl http://observable.k3s.local/

# Security dashboard
curl http://observable.k3s.local/security

# Operations dashboard
curl http://observable.k3s.local/operations
```

### Data Files
```bash
# Operational data (generated by Python loaders)
curl http://observable.k3s.local/_file/data/loki-logs.json

# Security data (generated by Python loaders)
curl http://observable.k3s.local/_file/data/quickwit-logs.json
```

## Python Data Loader Integration

### Using APIs in Python
```python
import requests
import json
from datetime import datetime, timedelta

# Loki API example
def fetch_loki_logs():
    url = "http://loki.k3s.local:3100/loki/api/v1/query_range"
    params = {
        'query': '{job=~".+"}',
        'start': int((datetime.now() - timedelta(hours=1)).timestamp()) * 1000000000,
        'end': int(datetime.now().timestamp()) * 1000000000,
        'limit': 100
    }
    response = requests.get(url, params=params)
    return response.json()

# Quickwit API example
def fetch_security_logs():
    url = "http://quickwit.k3s.local:7280/api/v1/otel-logs-v0_7/search"
    query = {
        "query": "log_type:security",
        "max_hits": 100,
        "start_timestamp": int((datetime.now() - timedelta(hours=24)).timestamp()),
        "end_timestamp": int(datetime.now().timestamp())
    }
    response = requests.post(url, json=query)
    return response.json()

# Prometheus API example
def fetch_metrics():
    url = "http://prometheus.k3s.local:9090/api/v1/query"
    params = {'query': 'cpu_usage_seconds_total'}
    response = requests.get(url, params=params)
    return response.json()
```

## API Authentication

### Current Setup
- **No authentication required** for development environment
- **Internal cluster access** - APIs accessible within Kubernetes
- **Telepresence access** - Local development via traffic intercept

### Production Considerations
```bash
# Add authentication headers when needed
curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     http://api.example.com/endpoint
```

## API Response Formats

### Loki Response Format
```json
{
  "status": "success",
  "data": {
    "resultType": "streams",
    "result": [
      {
        "stream": {
          "job": "kubernetes-pods",
          "service_name": "web-server"
        },
        "values": [
          ["1641024000000000000", "log message here"]
        ]
      }
    ]
  }
}
```

### Quickwit Response Format
```json
{
  "hits": [
    {
      "_source": {
        "timestamp": "2024-01-01T12:00:00Z",
        "message": "security event message",
        "log_type": "security",
        "severity_text": "ERROR",
        "source_ip": "203.0.113.42"
      }
    }
  ],
  "num_hits": 1,
  "elapsed_time_micros": 1234
}
```

### Prometheus Response Format
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "cpu_usage_seconds_total",
          "instance": "localhost:9090"
        },
        "value": [1641024000, "123.45"]
      }
    ]
  }
}
```

## Testing Scripts

### Send Test Data
```bash
# Send operational test logs
./scripts/test-operational-logs.sh

# Send security test logs  
./scripts/test-security-logs.sh
```

### Verify API Endpoints
```bash
# Test all endpoints
./scripts/test-all-apis.sh

# Health checks
curl http://loki.k3s.local:3100/ready
curl http://quickwit.k3s.local:7280/health
curl http://prometheus.k3s.local:9090/-/healthy
```

## Development Tips

### Local API Access with Telepresence
```bash
# Start intercept for local development
./scripts/telepresence-observable-connect.sh intercept

# Now APIs are accessible from local machine
python src/data/loki-logs.py  # Works locally
curl http://loki.k3s.local:3100/ready  # Accessible locally
```

### Error Handling
```python
def safe_api_call(url, **kwargs):
    try:
        response = requests.get(url, timeout=30, **kwargs)
        response.raise_for_status()
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"API call failed: {e}")
        return {"error": str(e)}
```

### Rate Limiting
```python
import time
from functools import wraps

def rate_limit(calls_per_second=1):
    min_interval = 1.0 / calls_per_second
    last_called = [0.0]
    
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            elapsed = time.time() - last_called[0]
            left_to_wait = min_interval - elapsed
            if left_to_wait > 0:
                time.sleep(left_to_wait)
            ret = func(*args, **kwargs)
            last_called[0] = time.time()
            return ret
        return wrapper
    return decorator

@rate_limit(calls_per_second=2)
def fetch_data_safely():
    # API call here
    pass
```

## Next Steps

- **[Setup Guide →](setup.md)** - Deploy and configure APIs
- **[Examples →](examples.md)** - Hands-on API usage tutorials
- **[Architecture →](architecture.md)** - System design and data flow
- **[Troubleshooting →](troubleshooting.md)** - API connectivity issues