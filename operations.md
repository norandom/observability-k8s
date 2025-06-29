# ⚙️ Operations Dashboard

System monitoring and operational log analysis using data from Loki.

```js
// Load operational logs from Loki
const operationalLogs = FileAttachment("data/loki-logs.json").json();
```

```js
// Process operational data
const now = Date.now();
const last24h = now - (24 * 60 * 60 * 1000);
const last1h = now - (60 * 60 * 1000);

// Filter recent operational events
const recentLogs = operationalLogs.filter(log => {
  const timestamp = new Date(log.timestamp || log.time).getTime();
  return timestamp > last24h;
});

const lastHourLogs = recentLogs.filter(log => {
  const timestamp = new Date(log.timestamp || log.time).getTime();
  return timestamp > last1h;
});

// Operational metrics
const totalLogs = recentLogs.length;
const recentLogs = lastHourLogs.length;
const errorLogs = recentLogs.filter(log => 
  log.level === "ERROR" || log.level === "error" || log.level === "WARN"
).length;

const services = [...new Set(recentLogs.map(log => 
  log.service_name || log.service || "unknown"
).filter(s => s !== "unknown"))].length;

const httpRequests = recentLogs.filter(log =>
  log.message?.includes("HTTP") ||
  log.message?.includes("GET") ||
  log.message?.includes("POST") ||
  log.log_type === "operational"
).length;
```

## 📊 Operations Overview (Last 24 Hours)

<div class="metric-grid">
  <div class="metric-card">
    <h3>📝 Total Logs</h3>
    <div class="metric-value">${totalLogs.toLocaleString()}</div>
    <div class="metric-subtitle">Operational events</div>
  </div>
  
  <div class="metric-card">
    <h3>⏰ Recent Logs</h3>
    <div class="metric-value">${recentLogs}</div>
    <div class="metric-subtitle">Last hour</div>
  </div>
  
  <div class="metric-card ${errorLogs > 0 ? 'warning' : ''}">
    <h3>⚠️ Errors/Warnings</h3>
    <div class="metric-value">${errorLogs}</div>
    <div class="metric-subtitle">Issues detected</div>
  </div>
  
  <div class="metric-card">
    <h3>🚀 Active Services</h3>
    <div class="metric-value">${services}</div>
    <div class="metric-subtitle">Services logging</div>
  </div>
</div>

## 📈 Log Volume Timeline

```js
// Group logs by hour for timeline
const hourlyLogs = d3.rollup(
  recentLogs,
  v => ({
    total: v.length,
    errors: v.filter(log => log.level === "ERROR" || log.level === "error").length,
    warnings: v.filter(log => log.level === "WARN" || log.level === "warn").length
  }),
  d => {
    const timestamp = new Date(d.timestamp || d.time);
    return d3.timeHour(timestamp);
  }
);

const timelineData = Array.from(hourlyLogs, ([hour, counts]) => ({
  time: new Date(hour),
  total: counts.total,
  errors: counts.errors,
  warnings: counts.warnings
})).sort((a, b) => a.time - b.time);
```

```js
Plot.plot({
  title: "Operational Logs Over Time (24 Hours)",
  width: 800,
  height: 300,
  x: { type: "time", label: "Time" },
  y: { label: "Logs per Hour" },
  marks: [
    Plot.areaY(timelineData, {
      x: "time",
      y: "total",
      fill: "rgba(0, 123, 255, 0.3)",
      stroke: "#007bff"
    }),
    Plot.lineY(timelineData, {
      x: "time", 
      y: "errors",
      stroke: "#dc3545",
      strokeWidth: 2
    }),
    Plot.lineY(timelineData, {
      x: "time",
      y: "warnings", 
      stroke: "#ffc107",
      strokeWidth: 2
    })
  ]
})
```

## 🏢 Service Activity

```js
// Group logs by service
const serviceActivity = d3.rollup(
  recentLogs,
  v => ({
    logs: v.length,
    errors: v.filter(log => log.level === "ERROR" || log.level === "error").length,
    last_seen: d3.max(v, log => new Date(log.timestamp || log.time))
  }),
  d => d.service_name || d.service || "unknown"
);

const serviceData = Array.from(serviceActivity, ([service, stats]) => ({
  service,
  logs: stats.logs,
  errors: stats.errors,
  error_rate: stats.logs > 0 ? ((stats.errors / stats.logs) * 100).toFixed(1) : "0.0",
  last_seen: stats.last_seen ? stats.last_seen.toLocaleString() : "Unknown"
}))
.filter(d => d.service !== "unknown")
.sort((a, b) => b.logs - a.logs)
.slice(0, 10);
```

```js
Inputs.table(serviceData, {
  columns: ["service", "logs", "errors", "error_rate", "last_seen"],
  header: {
    service: "Service Name",
    logs: "Total Logs",
    errors: "Errors",
    error_rate: "Error Rate (%)",
    last_seen: "Last Activity"
  },
  width: {
    service: 200,
    logs: 100,
    errors: 80,
    error_rate: 120,
    last_seen: 180
  }
})
```

## 🔍 Log Level Distribution

```js
// Analyze log levels
const logLevels = d3.rollup(
  recentLogs,
  v => v.length,
  d => (d.level || "INFO").toUpperCase()
);

const levelData = Array.from(logLevels, ([level, count]) => ({
  level,
  count,
  percentage: ((count / totalLogs) * 100).toFixed(1)
})).sort((a, b) => b.count - a.count);
```

```js
Plot.plot({
  title: "Log Level Distribution",
  width: 600,
  height: 300,
  marginLeft: 60,
  x: { label: "Log Count" },
  y: { label: "Log Level" },
  marks: [
    Plot.barX(levelData, {
      x: "count",
      y: "level",
      fill: d => {
        switch(d.level) {
          case "ERROR": return "#dc3545";
          case "WARN": return "#ffc107";
          case "INFO": return "#17a2b8";
          case "DEBUG": return "#6c757d";
          default: return "#007bff";
        }
      },
      tip: true
    }),
    Plot.text(levelData, {
      x: "count",
      y: "level",
      text: d => `${d.count} (${d.percentage}%)`,
      dx: 10,
      fontSize: 12
    })
  ]
})
```

## 🚨 Recent Errors and Warnings

```js
// Get recent error and warning logs
const problemLogs = recentLogs
  .filter(log => 
    log.level === "ERROR" || 
    log.level === "error" ||
    log.level === "WARN" ||
    log.level === "warn"
  )
  .map(log => ({
    time: new Date(log.timestamp || log.time).toLocaleString(),
    level: log.level?.toUpperCase() || "UNKNOWN",
    service: log.service_name || log.service || "Unknown",
    message: (log.message || "No message").substring(0, 100) + "..."
  }))
  .sort((a, b) => new Date(b.time) - new Date(a.time))
  .slice(0, 15);
```

```js
Inputs.table(problemLogs, {
  columns: ["time", "level", "service", "message"],
  header: {
    time: "Timestamp",
    level: "Level",
    service: "Service", 
    message: "Message"
  },
  width: {
    time: 180,
    level: 80,
    service: 150,
    message: 400
  },
  rows: 15
})
```

## 🌐 HTTP Request Analysis

```js
// Analyze HTTP requests from logs
const httpLogs = recentLogs.filter(log =>
  log.message?.includes("HTTP") ||
  log.message?.includes("GET") ||
  log.message?.includes("POST") ||
  log.message?.includes("PUT") ||
  log.message?.includes("DELETE")
);

const httpStats = {
  total: httpLogs.length,
  get: httpLogs.filter(log => log.message?.includes("GET")).length,
  post: httpLogs.filter(log => log.message?.includes("POST")).length,
  errors: httpLogs.filter(log => 
    log.message?.includes("500") ||
    log.message?.includes("404") ||
    log.message?.includes("error")
  ).length
};
```

<div class="metric-grid">
  <div class="metric-card">
    <h3>🌐 HTTP Requests</h3>
    <div class="metric-value">${httpStats.total}</div>
    <div class="metric-subtitle">Total requests</div>
  </div>
  
  <div class="metric-card">
    <h3>📥 GET Requests</h3>
    <div class="metric-value">${httpStats.get}</div>
    <div class="metric-subtitle">Read operations</div>
  </div>
  
  <div class="metric-card">
    <h3>📤 POST Requests</h3>
    <div class="metric-value">${httpStats.post}</div>
    <div class="metric-subtitle">Write operations</div>
  </div>
  
  <div class="metric-card ${httpStats.errors > 0 ? 'critical' : ''}">
    <h3>❌ HTTP Errors</h3>
    <div class="metric-value">${httpStats.errors}</div>
    <div class="metric-subtitle">Failed requests</div>
  </div>
</div>

## 📋 Recent System Events

```js
// Latest operational events
const latestLogs = recentLogs
  .map(log => ({
    time: new Date(log.timestamp || log.time).toLocaleString(),
    level: log.level?.toUpperCase() || "INFO",
    service: log.service_name || log.service || "System",
    type: log.log_type || "operational",
    message: (log.message || "No message").substring(0, 80) + "..."
  }))
  .sort((a, b) => new Date(b.time) - new Date(a.time))
  .slice(0, 20);
```

```js
Inputs.table(latestLogs, {
  columns: ["time", "level", "service", "type", "message"],
  header: {
    time: "Time",
    level: "Level",
    service: "Service",
    type: "Type",
    message: "Message"
  },
  width: {
    time: 150,
    level: 80,
    service: 120,
    type: 100,
    message: 350
  },
  rows: 20
})
```

## 🔗 Operations Links

<div class="service-grid">
  <a href="http://grafana.k3s.local" class="service-card" target="_blank">
    <h3>📊 Grafana</h3>
    <p>Operational dashboards and monitoring</p>
  </a>
  
  <a href="http://loki.k3s.local" class="service-card" target="_blank">
    <h3>📝 Loki</h3>
    <p>Direct log query interface</p>
  </a>
  
  <a href="/" class="service-card">
    <h3>🏠 Main Dashboard</h3>
    <p>Overview of all observability data</p>
  </a>
  
  <a href="/security" class="service-card">
    <h3>🛡️ Security</h3>
    <p>Security event monitoring and analysis</p>
  </a>
</div>

<style>
.metric-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin: 1rem 0;
}

.metric-card {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border: 1px solid #dee2e6;
  border-radius: 8px;
  padding: 1rem;
  text-align: center;
  transition: transform 0.2s ease;
}

.metric-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.1);
}

.metric-card.critical {
  background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%);
  border-color: #f1aeb5;
}

.metric-card.warning {
  background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%);
  border-color: #ffeaa7;
}

.metric-value {
  font-size: 2rem;
  font-weight: bold;
  color: #495057;
  margin: 0.5rem 0;
}

.metric-subtitle {
  font-size: 0.875rem;
  color: #6c757d;
}

.service-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1rem;
  margin: 2rem 0;
}

.service-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
  border: 1px solid #dee2e6;
  border-radius: 8px;
  padding: 1.5rem;
  text-decoration: none;
  color: inherit;
  transition: all 0.2s ease;
}

.service-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  border-color: #007bff;
}

.service-card h3 {
  margin: 0 0 0.5rem 0;
  color: #495057;
}

.service-card p {
  margin: 0;
  color: #6c757d;
  font-size: 0.875rem;
}
</style>