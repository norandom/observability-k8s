# Observability Dashboard

This dashboard provides real-time monitoring and analysis of your observability stack, combining data from Loki (operational logs) and Quickwit (security logs).

## Recent Logs Overview

```js
// Load recent logs from both Loki and Quickwit
const lokiLogs = FileAttachment("data/loki-loader.py.json").json();
const quickwitLogs = FileAttachment("data/quickwit-loader.py.json").json();

// Combine and sort by timestamp
const allLogs = [...lokiLogs, ...quickwitLogs].sort((a, b) => b.timestamp - a.timestamp);
```

### Log Volume Over Time

```js
// Group logs by hour for volume analysis
const logVolume = d3.rollup(
  allLogs,
  v => v.length,
  d => d3.timeHour(new Date(d.timestamp))
);

const volumeData = Array.from(logVolume, ([hour, count]) => ({
  hour,
  count,
  source: "combined"
}));
```

```js
Plot.plot({
  title: "Log Volume Over Time",
  x: {type: "time", label: "Time"},
  y: {label: "Number of logs"},
  marks: [
    Plot.lineY(volumeData, {x: "hour", y: "count", stroke: "#1f77b4"}),
    Plot.dotY(volumeData, {x: "hour", y: "count", fill: "#1f77b4"})
  ]
})
```

### Log Sources Distribution

```js
const sourceData = d3.rollup(allLogs, v => v.length, d => d.source);
const sourceArray = Array.from(sourceData, ([source, count]) => ({source, count}));
```

```js
Plot.plot({
  title: "Log Distribution by Source",
  marks: [
    Plot.barY(sourceArray, {x: "source", y: "count", fill: "source"}),
    Plot.text(sourceArray, {x: "source", y: "count", text: "count", dy: -10})
  ]
})
```

### Security Events Analysis (Quickwit)

```js
const securityLogs = allLogs.filter(log => log.source === "quickwit");
const severityData = d3.rollup(securityLogs, v => v.length, d => d.severity || "unknown");
const severityArray = Array.from(severityData, ([severity, count]) => ({severity, count}));
```

```js
Plot.plot({
  title: "Security Log Severity Distribution",
  marks: [
    Plot.barY(severityArray, {
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
    Plot.text(severityArray, {x: "severity", y: "count", text: "count", dy: -10})
  ]
})
```

### Recent Log Messages

```js
const recentLogs = allLogs.slice(0, 20);
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
  }
})
```

### Service Activity (Operational Logs)

```js
const operationalLogs = allLogs.filter(log => log.source === "loki");
const serviceData = d3.rollup(
  operationalLogs.filter(log => log.labels && log.labels.service_name),
  v => v.length,
  d => d.labels.service_name
);
const serviceArray = Array.from(serviceData, ([service, count]) => ({service, count}))
  .sort((a, b) => b.count - a.count)
  .slice(0, 10);
```

```js
Plot.plot({
  title: "Top 10 Most Active Services",
  marginLeft: 100,
  marks: [
    Plot.barX(serviceArray, {y: "service", x: "count", fill: "#28a745"}),
    Plot.text(serviceArray, {y: "service", x: "count", text: "count", dx: 5})
  ]
})
```

## API Endpoints

### Quick Access Links

- **Loki API**: [Query Interface](http://192.168.122.27:3100/loki/api/v1/query_range)
- **Quickwit API**: [Search Interface](http://192.168.122.27:7280/api/v1/otel-logs-v0_7/search)
- **Grafana**: [Dashboard](http://grafana.k3s.local)
- **Quickwit UI**: [Search Interface](http://quickwit.k3s.local/ui/search)

### Data Refresh

The data on this dashboard is refreshed every time the page is built. In development mode, data loaders run automatically when files change.

---

*Last updated: ${new Date().toLocaleString()}*