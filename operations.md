# ⚙️ Operations Dashboard

Real-time operational monitoring and log analysis with live data from Loki.

```js
// Load operational data from Loki API via Python data loader
const operationalData = FileAttachment("data/loki-logs.json").json();
```

<div class="grid grid-cols-4">
  <div class="card">
    <h2>Total Logs</h2>
    <span class="big-number">${operationalData.summary.total_logs}</span>
  </div>
  <div class="card">
    <h2>Demo Logs</h2>
    <span class="big-number demo">${operationalData.summary.demo_logs}</span>
  </div>
  <div class="card">
    <h2>Live Logs</h2>
    <span class="big-number live">${operationalData.summary.live_logs}</span>
  </div>
  <div class="card">
    <h2>Services</h2>
    <span class="big-number">${Object.keys(operationalData.summary.by_service).length}</span>
  </div>
</div>

## 📊 Log Volume Analysis

```js
// Prepare hourly log volume data
const hourlyData = Object.entries(operationalData.summary.by_hour)
  .map(([hour, count]) => ({hour, count}))
  .sort((a, b) => a.hour.localeCompare(b.hour));
```

<div class="grid grid-cols-1">
  <div class="card">
    ${Plot.plot({
      title: "Log Volume by Hour",
      width: 800,
      height: 300,
      x: {label: "Hour"},
      y: {label: "Log Count"},
      marks: [
        Plot.barY(hourlyData, {x: "hour", y: "count", fill: "#4f46e5"}),
        Plot.ruleY([0])
      ]
    })}
  </div>
</div>

## 🚨 Service Activity Monitoring

```js
// Prepare service activity data
const serviceData = Object.entries(operationalData.summary.by_service)
  .map(([service, count]) => ({service, count}))
  .sort((a, b) => b.count - a.count);
```

<div class="grid grid-cols-2">
  <div class="card">
    ${Plot.plot({
      title: "Log Count by Service",
      width: 400,
      height: 300,
      marginBottom: 80,
      x: {label: "Service", tickRotate: -45},
      y: {label: "Log Count"},
      marks: [
        Plot.barY(serviceData, {x: "service", y: "count", fill: "#059669"}),
        Plot.ruleY([0])
      ]
    })}
  </div>
  <div class="card">
    ${Plot.plot({
      title: "Service Distribution",
      width: 400,
      height: 300,
      marks: [
        Plot.cell(serviceData, {
          x: (d, i) => i % 3,
          y: (d, i) => Math.floor(i / 3),
          fill: "service",
          stroke: "white",
          strokeWidth: 2,
          width: (d) => Math.sqrt(d.count / Math.max(...serviceData.map(x => x.count))) * 80,
          height: (d) => Math.sqrt(d.count / Math.max(...serviceData.map(x => x.count))) * 80
        }),
        Plot.text(serviceData, {
          x: (d, i) => i % 3,
          y: (d, i) => Math.floor(i / 3),
          text: (d) => `${d.service}\n${d.count}`,
          fill: "white",
          fontSize: 10,
          fontWeight: "bold"
        })
      ]
    })}
  </div>
</div>

## 📈 Log Level Distribution

```js
// Prepare log level data
const levelData = Object.entries(operationalData.summary.by_level)
  .map(([level, count]) => ({level, count}))
  .sort((a, b) => b.count - a.count);

// Color mapping for log levels
const levelColors = {
  "CRITICAL": "#dc2626",
  "ERROR": "#ea580c", 
  "WARN": "#ca8a04",
  "INFO": "#2563eb",
  "DEBUG": "#6b7280"
};
```

<div class="grid grid-cols-1">
  <div class="card">
    ${Plot.plot({
      title: "Log Levels Distribution",
      width: 800,
      height: 300,
      x: {label: "Log Level"},
      y: {label: "Count"},
      color: {range: Object.values(levelColors)},
      marks: [
        Plot.barY(levelData, {
          x: "level", 
          y: "count", 
          fill: (d) => levelColors[d.level] || "#6b7280"
        }),
        Plot.ruleY([0])
      ]
    })}
  </div>
</div>

## 📋 Recent Log Activity

```js
// Process recent logs for table display
const recentLogs = operationalData.logs.slice(0, 15).map(log => {
  // Extract message from various possible fields
  let message = log.message || log.body || log.msg || "";
  if (!message && log.attributes && log.attributes.message) {
    message = log.attributes.message;
  }
  if (!message) {
    message = "Log entry recorded";
  }
  
  return {
    time: new Date(log.timestamp).toLocaleString(),
    level: log.level || log.severity || "INFO",
    service: log.service_name || "unknown",
    category: log.category || "general",
    message: message.length > 80 ? message.substring(0, 80) + "..." : message,
    demo: log.is_demo ? "🎯" : ""
  };
});
```

<div class="card">
  ${Inputs.table(recentLogs, {
    columns: ["time", "level", "service", "category", "demo", "message"],
    header: {
      time: "Timestamp", 
      level: "Level", 
      service: "Service", 
      category: "Category",
      demo: "Demo",
      message: "Message"
    },
    width: {
      time: 140,
      level: 80, 
      service: 120,
      category: 100,
      demo: 50,
      message: 400
    }
  })}
</div>

## 📊 Category Analysis

```js
// Prepare category data
const categoryData = Object.entries(operationalData.summary.by_category)
  .map(([category, count]) => ({category, count}))
  .sort((a, b) => b.count - a.count);
```

<div class="grid grid-cols-1">
  <div class="card">
    ${Plot.plot({
      title: "Log Categories",
      width: 800,
      height: 300,
      x: {label: "Category"},
      y: {label: "Count"},
      marks: [
        Plot.barY(categoryData, {x: "category", y: "count", fill: "#7c3aed"}),
        Plot.ruleY([0])
      ]
    })}
  </div>
</div>

## 🔍 System Health Overview

```js
// Calculate health metrics
const errorCount = operationalData.summary.by_level.ERROR || 0;
const criticalCount = operationalData.summary.by_level.CRITICAL || 0;
const warnCount = operationalData.summary.by_level.WARN || 0;
const totalIssues = errorCount + criticalCount + warnCount;

const healthScore = Math.max(0, 100 - (criticalCount * 10 + errorCount * 5 + warnCount * 2));
const healthStatus = healthScore >= 90 ? "Excellent" : 
                    healthScore >= 70 ? "Good" : 
                    healthScore >= 50 ? "Warning" : "Critical";
```

<div class="grid grid-cols-3">
  <div class="card health-excellent">
    <h3>System Health Score</h3>
    <span class="big-number">${healthScore.toFixed(0)}%</span>
    <p class="status">${healthStatus}</p>
  </div>
  <div class="card">
    <h3>Issues Found</h3>
    <span class="big-number error">${totalIssues}</span>
    <p>Critical: ${criticalCount}, Error: ${errorCount}, Warning: ${warnCount}</p>
  </div>
  <div class="card">
    <h3>Data Freshness</h3>
    <span class="small-text">Last Updated</span>
    <p>${new Date(operationalData.last_updated).toLocaleString()}</p>
  </div>
</div>

## 🔄 Real-time Updates

This dashboard automatically refreshes with live data from the Loki API. The Python data loader (`loki-logs.py`) fetches the latest operational logs and provides comprehensive analytics.

### Key Features:
- **Live Data**: Real-time log ingestion from Loki API
- **Demo vs Live**: Clear distinction between demo and production logs  
- **Multi-dimensional Analysis**: Service, time, level, and category breakdowns
- **Health Monitoring**: Automated system health scoring
- **Interactive Charts**: Powered by Observable Plot for responsive visualizations

<style>
.grid {
  display: grid;
  gap: 1rem;
  margin: 1rem 0;
}

.grid-cols-1 { grid-template-columns: 1fr; }
.grid-cols-2 { grid-template-columns: 1fr 1fr; }
.grid-cols-3 { grid-template-columns: 1fr 1fr 1fr; }
.grid-cols-4 { grid-template-columns: 1fr 1fr 1fr 1fr; }

.card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 1rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.big-number {
  font-size: 2rem;
  font-weight: bold;
  color: #1f2937;
}

.big-number.demo { color: #f59e0b; }
.big-number.live { color: #059669; }
.big-number.error { color: #dc2626; }

.small-text {
  font-size: 0.875rem;
  color: #6b7280;
}

.status {
  font-weight: 600;
  margin-top: 0.5rem;
}

.health-excellent {
  border-left: 4px solid #059669;
}

h2, h3 {
  margin: 0 0 0.5rem 0;
  color: #374151;
}
</style>