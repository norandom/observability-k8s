# Observability Dashboard

Welcome to the comprehensive observability dashboard powered by Observable Framework with Python data analytics.

## System Overview

```js
// Load real-time data from our APIs
const lokiData = FileAttachment("data/loki-logs.json").json();
const quickwitData = FileAttachment("data/quickwit-logs.json").json();
const metricsData = FileAttachment("data/metrics.json").json();
```

## Quick Access

<div class="service-grid">

### [📊 Grafana](http://grafana.k3s.local)
Operational monitoring and dashboards
- Time-series visualization
- Alert management
- Custom dashboards

### [🔍 Quickwit](http://quickwit.k3s.local/ui/search)
Security log analysis and search
- Full-text search capabilities
- Complex query support
- Forensic analysis

### [🚀 ArgoCD](http://argocd.k3s.local)
GitOps deployment management
- Application deployment status
- Sync and health monitoring
- Git-based configuration

### [📝 Loki](http://loki.k3s.local)
Log aggregation API
- Direct API access
- LogQL queries
- Real-time log streaming

</div>

## Real-time Metrics

```js
// Process and display log volume over time
const logVolume = d3.rollup(
  [...lokiData, ...quickwitData],
  v => v.length,
  d => d3.timeHour(new Date(d.timestamp))
);

const volumeData = Array.from(logVolume, ([time, count]) => ({
  time: new Date(time),
  count,
  source: "combined"
}));
```

```js
Plot.plot({
  title: "Log Volume Over Time",
  width: 800,
  height: 300,
  x: {
    type: "time",
    label: "Time"
  },
  y: {
    label: "Log Count"
  },
  marks: [
    Plot.lineY(volumeData, {
      x: "time",
      y: "count",
      stroke: "#1f77b4",
      strokeWidth: 2
    }),
    Plot.dotY(volumeData, {
      x: "time",
      y: "count",
      fill: "#1f77b4",
      r: 3
    })
  ]
})
```

## Security Events Analysis

```js
// Analyze security events from Quickwit
const securityEvents = quickwitData.filter(d => d.source === "quickwit");
const severityBreakdown = d3.rollup(
  securityEvents,
  v => v.length,
  d => d.severity || "unknown"
);

const severityData = Array.from(severityBreakdown, ([severity, count]) => ({
  severity,
  count
})).sort((a, b) => b.count - a.count);
```

```js
Plot.plot({
  title: "Security Events by Severity",
  width: 600,
  height: 300,
  x: {
    label: "Severity"
  },
  y: {
    label: "Event Count"
  },
  marks: [
    Plot.barY(severityData, {
      x: "severity",
      y: "count",
      fill: d => {
        switch(d.severity.toLowerCase()) {
          case "error": return "#dc3545";
          case "warning": return "#ffc107";
          case "info": return "#17a2b8";
          default: return "#6c757d";
        }
      }
    }),
    Plot.text(severityData, {
      x: "severity",
      y: "count",
      text: "count",
      dy: -10
    })
  ]
})
```

## Data Sources Status

<div class="status-grid">

**Loki API**
- Endpoint: `http://192.168.122.27:3100`
- Status: ${lokiData.length > 0 ? "🟢 Online" : "🔴 Offline"}
- Last Update: ${lokiData.length > 0 ? new Date(Math.max(...lokiData.map(d => d.timestamp))).toLocaleString() : "N/A"}

**Quickwit API**
- Endpoint: `http://192.168.122.27:7280`
- Status: ${quickwitData.length > 0 ? "🟢 Online" : "🔴 Offline"}
- Last Update: ${quickwitData.length > 0 ? new Date(Math.max(...quickwitData.map(d => d.timestamp))).toLocaleString() : "N/A"}

**Prometheus**
- Endpoint: `http://192.168.122.27:9090`
- Status: ${metricsData ? "🟢 Online" : "🔴 Offline"}

</div>

## Recent Log Activity

```js
// Show recent logs from both sources
const recentLogs = [...lokiData, ...quickwitData]
  .sort((a, b) => b.timestamp - a.timestamp)
  .slice(0, 20);
```

```js
Inputs.table(recentLogs, {
  columns: [
    "timestamp",
    "source",
    "message",
    "severity",
    "service"
  ],
  header: {
    timestamp: "Time",
    source: "Source",
    message: "Message",
    severity: "Severity",
    service: "Service"
  },
  format: {
    timestamp: d => new Date(d).toLocaleString()
  },
  width: {
    timestamp: 150,
    source: 80,
    message: 400,
    severity: 80,
    service: 120
  }
})
```

---

<style>
.service-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin: 2rem 0;
}

.service-grid > div {
  padding: 1.5rem;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
}

.service-grid h3 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
}

.service-grid a {
  text-decoration: none;
  color: inherit;
}

.service-grid a:hover {
  color: #007bff;
}

.status-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin: 1rem 0;
  font-family: monospace;
  font-size: 0.9rem;
}

.status-grid > div {
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 4px;
  border-left: 4px solid #007bff;
}
</style>

*Dashboard last updated: ${new Date().toLocaleString()}*