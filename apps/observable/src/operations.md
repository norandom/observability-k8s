# Operational Insights Dashboard

Advanced operational analytics using Loki logs and Prometheus metrics with Polars processing.

```js
// Load operational data
const operationalLogs = FileAttachment("data/loki-logs.json").json();
const systemMetrics = FileAttachment("data/metrics.json").json();
```

## System Health Overview

```js
// Extract system metrics
const metrics = systemMetrics?.system_metrics || {};
const summary = systemMetrics?.summary || {};
```

<div class="health-overview">
  <div class="metric-card">
    <h3>
      <span class="health-indicator health-${summary.overall_health || 'unknown'}"></span>
      Overall Health
    </h3>
    <div class="metric-value">${(summary.overall_health || 'unknown').toUpperCase()}</div>
  </div>
  <div class="metric-card">
    <h3>Performance Score</h3>
    <div class="metric-value">${(summary.performance_score || 0).toFixed(1)}%</div>
  </div>
  <div class="metric-card">
    <h3>Availability Score</h3>
    <div class="metric-value">${(summary.availability_score || 0).toFixed(1)}%</div>
  </div>
  <div class="metric-card">
    <h3>Critical Alerts</h3>
    <div class="metric-value">${summary.critical_alerts || 0}</div>
  </div>
</div>

## Resource Utilization

```js
// Process resource metrics
const resourceData = [
  { metric: "CPU Usage", value: metrics.cpu_usage || 0, unit: "%" },
  { metric: "Memory Usage", value: metrics.memory_usage || 0, unit: "%" },
  { metric: "Disk Usage", value: metrics.disk_usage || 0, unit: "%" },
  { metric: "Load Average", value: metrics.load_average || 0, unit: "" }
].filter(d => d.value > 0);
```

```js
Plot.plot({
  title: "Resource Utilization",
  width: 600,
  height: 300,
  x: {
    label: "Utilization %",
    domain: [0, 100]
  },
  y: {
    label: "Resource",
    domain: resourceData.map(d => d.metric)
  },
  marginLeft: 100,
  marks: [
    Plot.barX(resourceData, {
      x: "value",
      y: "metric",
      fill: d => {
        if (d.value >= 90) return "#dc3545";  // Critical - red
        if (d.value >= 75) return "#ffc107";  // Warning - yellow
        return "#28a745";  // Good - green
      }
    }),
    Plot.text(resourceData, {
      x: "value",
      y: "metric",
      text: d => `${d.value.toFixed(1)}${d.unit}`,
      dx: 5,
      fontSize: 12
    })
  ]
})
```

## Log Analysis

```js
// Analyze operational logs
const logLevelData = d3.rollup(
  operationalLogs,
  v => v.length,
  d => d.severity || d.level || "unknown"
);

const logLevels = Array.from(logLevelData, ([level, count]) => ({
  level,
  count,
  percentage: ((count / operationalLogs.length) * 100).toFixed(1)
})).sort((a, b) => b.count - a.count);
```

### Log Level Distribution

```js
Plot.plot({
  title: "Log Entries by Severity Level",
  width: 500,
  height: 300,
  marks: [
    Plot.arc(logLevels, {
      theta: "count",
      fill: d => {
        switch(d.level.toLowerCase()) {
          case "error": return "#dc3545";
          case "warning": return "#ffc107";
          case "info": return "#17a2b8";
          case "debug": return "#6c757d";
          default: return "#28a745";
        }
      },
      padAngle: 0.02,
      sort: {channel: "theta", order: "descending"}
    }),
    Plot.text(logLevels, {
      theta: "count",
      text: d => `${d.level}\n${d.percentage}%`,
      fontSize: 11,
      fill: "white",
      fontWeight: "bold"
    })
  ]
})
```

## Service Activity Analysis

```js
// Analyze service activity from logs
const serviceData = d3.rollup(
  operationalLogs.filter(d => d.service_name && d.service_name !== "unknown"),
  v => ({
    count: v.length,
    error_count: v.filter(log => (log.severity || log.level || "").toLowerCase() === "error").length,
    avg_message_length: d3.mean(v, log => log.message_length || log.message?.length || 0),
    keywords: d3.rollup(v.flatMap(log => log.keywords || []), w => w.length, w => w)
  }),
  d => d.service_name
);

const topServices = Array.from(serviceData, ([service, stats]) => ({
  service,
  ...stats,
  error_rate: ((stats.error_count / stats.count) * 100).toFixed(1),
  avg_message_length: stats.avg_message_length.toFixed(0),
  top_keywords: Array.from(stats.keywords).sort((a, b) => b[1] - a[1]).slice(0, 3).map(d => d[0])
}))
.sort((a, b) => b.count - a.count)
.slice(0, 10);
```

### Top Active Services

```js
Inputs.table(topServices, {
  columns: [
    "service",
    "count", 
    "error_count",
    "error_rate",
    "avg_message_length",
    "top_keywords"
  ],
  header: {
    service: "Service",
    count: "Log Count",
    error_count: "Errors",
    error_rate: "Error Rate %",
    avg_message_length: "Avg Msg Length",
    top_keywords: "Top Keywords"
  },
  format: {
    top_keywords: d => d.join(", ")
  },
  width: {
    service: 150,
    count: 90,
    error_count: 80,
    error_rate: 100,
    avg_message_length: 120,
    top_keywords: 200
  }
})
```

## Error Trend Analysis

```js
// Analyze error trends over time
const errorLogs = operationalLogs.filter(d => 
  (d.severity || d.level || "").toLowerCase() === "error"
);

// Group errors by hour
const errorTrends = d3.rollup(
  errorLogs,
  v => v.length,
  d => {
    const date = new Date(d.timestamp);
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), date.getHours());
  }
);

const errorTrendData = Array.from(errorTrends, ([time, count]) => ({
  time,
  count
})).sort((a, b) => a.time - b.time);
```

```js
Plot.plot({
  title: "Error Trends Over Time",
  width: 800,
  height: 300,
  x: {
    type: "time",
    label: "Time"
  },
  y: {
    label: "Error Count"
  },
  marks: [
    Plot.lineY(errorTrendData, {
      x: "time",
      y: "count",
      stroke: "#dc3545",
      strokeWidth: 2
    }),
    Plot.areaY(errorTrendData, {
      x: "time",
      y: "count",
      fill: "#dc3545",
      fillOpacity: 0.1
    }),
    Plot.dotY(errorTrendData, {
      x: "time",
      y: "count",
      fill: "#dc3545",
      r: 3
    })
  ]
})
```

## Network Activity

```js
// Extract network metrics if available
const networkMetrics = {
  network_in: metrics.network_in || 0,
  network_out: metrics.network_out || 0
};

const networkData = [
  { direction: "Incoming", rate: networkMetrics.network_in, unit: "bps" },
  { direction: "Outgoing", rate: networkMetrics.network_out, unit: "bps" }
];
```

<div class="network-overview">
  ${networkData.map(d => `
    <div class="metric-card">
      <h3>${d.direction} Traffic</h3>
      <div class="metric-value">
        ${d.rate > 0 ? (d.rate / 1000000).toFixed(2) + " Mbps" : "N/A"}
      </div>
    </div>
  `).join("")}
</div>

## System Recommendations

```js
// Generate operational recommendations
const recommendations = summary.recommendations || [];

// Add custom recommendations based on metrics
if (metrics.cpu_usage > 80) {
  recommendations.push("Consider scaling up CPU resources or optimizing high-CPU processes");
}

if (metrics.memory_usage > 85) {
  recommendations.push("Memory usage is high - investigate memory leaks or scale memory resources");
}

if (operationalLogs.filter(d => (d.severity || d.level || "").toLowerCase() === "error").length > 50) {
  recommendations.push("High error rate detected - review application logs and error handling");
}

const avgMessageLength = d3.mean(operationalLogs, d => d.message_length || d.message?.length || 0);
if (avgMessageLength > 200) {
  recommendations.push("Log messages are verbose - consider log level optimization");
}
```

### Operational Recommendations

<div class="recommendations">
  ${recommendations.length > 0 ? recommendations.map(rec => `
    <div class="recommendation">
      <span class="recommendation-icon">💡</span>
      ${rec}
    </div>
  `).join("") : '<div class="recommendation"><span class="recommendation-icon">✅</span>No operational issues detected</div>'}
</div>

## Performance Metrics

```js
// Calculate performance statistics
const performanceStats = {
  uptime_days: metrics.uptime ? (metrics.uptime / 86400).toFixed(1) : "N/A",
  load_average: metrics.load_average ? metrics.load_average.toFixed(2) : "N/A",
  total_logs: operationalLogs.length.toLocaleString(),
  error_percentage: ((errorLogs.length / operationalLogs.length) * 100).toFixed(2),
  unique_services: new Set(operationalLogs.map(d => d.service_name).filter(s => s && s !== "unknown")).size,
  avg_logs_per_service: operationalLogs.length > 0 ? 
    (operationalLogs.length / new Set(operationalLogs.map(d => d.service_name).filter(s => s && s !== "unknown")).size).toFixed(0) : "0"
};
```

<div class="performance-grid">
  <div class="metric-card">
    <h3>System Uptime</h3>
    <div class="metric-value">${performanceStats.uptime_days} days</div>
  </div>
  <div class="metric-card">
    <h3>Load Average</h3>
    <div class="metric-value">${performanceStats.load_average}</div>
  </div>
  <div class="metric-card">
    <h3>Total Log Entries</h3>
    <div class="metric-value">${performanceStats.total_logs}</div>
  </div>
  <div class="metric-card">
    <h3>Error Rate</h3>
    <div class="metric-value">${performanceStats.error_percentage}%</div>
  </div>
  <div class="metric-card">
    <h3>Active Services</h3>
    <div class="metric-value">${performanceStats.unique_services}</div>
  </div>
  <div class="metric-card">
    <h3>Avg Logs/Service</h3>
    <div class="metric-value">${performanceStats.avg_logs_per_service}</div>
  </div>
</div>

---

<style>
.health-overview, .network-overview, .performance-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin: 2rem 0;
}

.recommendations {
  margin: 2rem 0;
}

.recommendation {
  padding: 1rem;
  margin: 0.5rem 0;
  background: #f8f9fa;
  border-radius: 4px;
  border-left: 4px solid #007bff;
}

.recommendation-icon {
  margin-right: 0.5rem;
  font-size: 1.2rem;
}
</style>

*Operational insights updated: ${new Date().toLocaleString()}*