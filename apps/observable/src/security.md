# Security Analysis Dashboard

Real-time security event analysis using Quickwit logs and advanced Python analytics.

```js
// Load security data
const securityLogs = FileAttachment("data/quickwit-logs.json").json();
```

## Security Overview

```js
// Filter for security-relevant events
const securityEvents = securityLogs.filter(d => d.is_security_relevant);
const totalEvents = securityLogs.length;
const securityEventCount = securityEvents.length;
const securityPercentage = ((securityEventCount / totalEvents) * 100).toFixed(1);
```

<div class="security-overview">
  <div class="metric-card">
    <h3>Total Events</h3>
    <div class="metric-value">${totalEvents.toLocaleString()}</div>
  </div>
  <div class="metric-card">
    <h3>Security Events</h3>
    <div class="metric-value">${securityEventCount.toLocaleString()}</div>
  </div>
  <div class="metric-card">
    <h3>Security %</h3>
    <div class="metric-value">${securityPercentage}%</div>
  </div>
</div>

## Risk Score Distribution

```js
// Analyze risk scores
const riskScoreData = d3.rollup(
  securityLogs,
  v => v.length,
  d => Math.floor(d.risk_score || 0)
);

const riskData = Array.from(riskScoreData, ([score, count]) => ({
  risk_score: score,
  count,
  percentage: ((count / totalEvents) * 100).toFixed(1)
})).sort((a, b) => a.risk_score - b.risk_score);
```

```js
Plot.plot({
  title: "Risk Score Distribution",
  width: 700,
  height: 300,
  x: {
    label: "Risk Score (0-10)",
    domain: [0, 10]
  },
  y: {
    label: "Event Count"
  },
  marks: [
    Plot.barY(riskData, {
      x: "risk_score",
      y: "count",
      fill: d => {
        if (d.risk_score >= 7) return "#dc3545";  // High risk - red
        if (d.risk_score >= 4) return "#ffc107";  // Medium risk - yellow
        return "#28a745";  // Low risk - green
      }
    }),
    Plot.text(riskData.filter(d => d.count > 0), {
      x: "risk_score",
      y: "count",
      text: "count",
      dy: -5,
      fontSize: 10
    })
  ]
})
```

## Security Categories

```js
// Analyze security categories
const categoryData = d3.rollup(
  securityEvents,
  v => v.length,
  d => d.category || "unknown"
);

const categoryArray = Array.from(categoryData, ([category, count]) => ({
  category,
  count,
  percentage: ((count / securityEventCount) * 100).toFixed(1)
})).sort((a, b) => b.count - a.count);
```

```js
Plot.plot({
  title: "Security Events by Category",
  width: 600,
  height: 300,
  x: {
    label: "Event Count"
  },
  y: {
    label: "Category",
    domain: categoryArray.map(d => d.category)
  },
  marginLeft: 80,
  marks: [
    Plot.barX(categoryArray, {
      x: "count",
      y: "category",
      fill: "#007bff"
    }),
    Plot.text(categoryArray, {
      x: "count",
      y: "category",
      text: d => `${d.count} (${d.percentage}%)`,
      dx: 5,
      fontSize: 11
    })
  ]
})
```

## Time-based Analysis

```js
// Analyze security events over time
const hourlyData = d3.rollup(
  securityEvents,
  v => v.length,
  d => d.hour
);

const hourlyArray = Array.from(hourlyData, ([hour, count]) => ({
  hour,
  count
})).sort((a, b) => a.hour - b.hour);

// Fill missing hours with 0
const completeHourlyData = [];
for (let i = 0; i < 24; i++) {
  const existing = hourlyArray.find(d => d.hour === i);
  completeHourlyData.push({
    hour: i,
    count: existing ? existing.count : 0
  });
}
```

```js
Plot.plot({
  title: "Security Events by Hour of Day",
  width: 800,
  height: 300,
  x: {
    label: "Hour of Day",
    domain: [0, 23],
    ticks: 24
  },
  y: {
    label: "Event Count"
  },
  marks: [
    Plot.lineY(completeHourlyData, {
      x: "hour",
      y: "count",
      stroke: "#dc3545",
      strokeWidth: 2
    }),
    Plot.dotY(completeHourlyData, {
      x: "hour",
      y: "count",
      fill: "#dc3545",
      r: 3
    }),
    // Highlight unusual activity (late night/early morning)
    Plot.rectY([{hour: 22}, {hour: 6}], {
      x1: d => d.hour === 22 ? 22 : 0,
      x2: d => d.hour === 22 ? 24 : 6,
      y1: 0,
      y2: Math.max(...completeHourlyData.map(d => d.count)),
      fill: "#ffc107",
      fillOpacity: 0.1
    })
  ]
})
```

## Anomaly Detection

```js
// Find anomalous events (high anomaly score)
const anomalousEvents = securityLogs
  .filter(d => d.anomaly_score > 0.5)
  .sort((a, b) => b.anomaly_score - a.anomaly_score)
  .slice(0, 10);
```

### Top Anomalous Events

```js
Inputs.table(anomalousEvents, {
  columns: [
    "timestamp",
    "severity",
    "category",
    "risk_score",
    "anomaly_score",
    "message",
    "source_ip",
    "user_id"
  ],
  header: {
    timestamp: "Time",
    severity: "Severity",
    category: "Category", 
    risk_score: "Risk",
    anomaly_score: "Anomaly",
    message: "Message",
    source_ip: "Source IP",
    user_id: "User"
  },
  format: {
    timestamp: d => new Date(d).toLocaleString(),
    risk_score: d => d?.toFixed(1) || "N/A",
    anomaly_score: d => d?.toFixed(3) || "N/A"
  },
  width: {
    timestamp: 140,
    severity: 80,
    category: 80,
    risk_score: 60,
    anomaly_score: 80,
    message: 300,
    source_ip: 120,
    user_id: 100
  }
})
```

## Source IP Analysis

```js
// Analyze events by source IP
const ipData = d3.rollup(
  securityEvents.filter(d => d.source_ip && d.source_ip !== ""),
  v => ({
    count: v.length,
    avg_risk: d3.mean(v, d => d.risk_score || 0),
    categories: [...new Set(v.map(d => d.category))],
    latest_event: Math.max(...v.map(d => d.timestamp))
  }),
  d => d.source_ip
);

const topIPs = Array.from(ipData, ([ip, stats]) => ({
  ip,
  ...stats,
  avg_risk: stats.avg_risk.toFixed(2)
}))
.sort((a, b) => b.count - a.count)
.slice(0, 15);
```

### Top Source IPs by Event Count

```js
Inputs.table(topIPs, {
  columns: ["ip", "count", "avg_risk", "categories", "latest_event"],
  header: {
    ip: "Source IP",
    count: "Events",
    avg_risk: "Avg Risk",
    categories: "Categories",
    latest_event: "Latest Event"
  },
  format: {
    categories: d => d.join(", "),
    latest_event: d => new Date(d).toLocaleString()
  },
  width: {
    ip: 140,
    count: 80,
    avg_risk: 80,
    categories: 200,
    latest_event: 140
  }
})
```

## Security Recommendations

```js
// Generate security recommendations based on analysis
const recommendations = [];

const highRiskEvents = securityLogs.filter(d => d.risk_score >= 7).length;
if (highRiskEvents > 10) {
  recommendations.push({
    severity: "high",
    message: `${highRiskEvents} high-risk security events detected. Immediate investigation recommended.`
  });
}

const authFailures = securityLogs.filter(d => 
  d.category === "auth" && 
  (d.message.toLowerCase().includes("failed") || d.message.toLowerCase().includes("denied"))
).length;

if (authFailures > 20) {
  recommendations.push({
    severity: "medium", 
    message: `${authFailures} authentication failures detected. Consider implementing rate limiting.`
  });
}

const nightActivity = securityEvents.filter(d => d.hour < 6 || d.hour > 22).length;
if (nightActivity > securityEventCount * 0.2) {
  recommendations.push({
    severity: "medium",
    message: `${nightActivity} security events during off-hours. Review access patterns.`
  });
}

const uniqueIPs = new Set(securityEvents.map(d => d.source_ip).filter(ip => ip)).size;
if (uniqueIPs > 100) {
  recommendations.push({
    severity: "low",
    message: `${uniqueIPs} unique source IPs detected. Monitor for distributed attacks.`
  });
}
```

<div class="recommendations">
  ${recommendations.map(rec => `
    <div class="recommendation ${rec.severity}">
      <span class="severity-badge ${rec.severity}">${rec.severity.toUpperCase()}</span>
      ${rec.message}
    </div>
  `).join("")}
</div>

---

<style>
.security-overview {
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
  border-radius: 4px;
  border-left: 4px solid;
}

.recommendation.high {
  background: #f8d7da;
  border-color: #dc3545;
}

.recommendation.medium {
  background: #fff3cd;
  border-color: #ffc107;
}

.recommendation.low {
  background: #d1ecf1;
  border-color: #17a2b8;
}

.severity-badge {
  display: inline-block;
  padding: 0.2rem 0.5rem;
  border-radius: 3px;
  font-size: 0.8rem;
  font-weight: bold;
  margin-right: 0.5rem;
}

.severity-badge.high {
  background: #dc3545;
  color: white;
}

.severity-badge.medium {
  background: #ffc107;
  color: black;
}

.severity-badge.low {
  background: #17a2b8;
  color: white;
}
</style>

*Security analysis updated: ${new Date().toLocaleString()}*