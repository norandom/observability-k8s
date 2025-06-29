# 🛡️ Security Dashboard

Real-time security event monitoring and threat analysis using data from Quickwit.

```js
// Load security logs from Quickwit
const securityLogs = FileAttachment("data/quickwit-logs.json").json();
```

```js
// Process security data
const now = Date.now();
const last24h = now - (24 * 60 * 60 * 1000);
const last1h = now - (60 * 60 * 1000);

// Filter recent security events
const recentLogs = securityLogs.filter(log => {
  const timestamp = new Date(log.timestamp || log.time_unix_nano / 1000000).getTime();
  return timestamp > last24h;
});

const lastHourLogs = recentLogs.filter(log => {
  const timestamp = new Date(log.timestamp || log.time_unix_nano / 1000000).getTime();
  return timestamp > last1h;
});

// Security metrics
const totalEvents = recentLogs.length;
const recentEvents = lastHourLogs.length;
const criticalEvents = recentLogs.filter(log => 
  (log.severity_text === "ERROR" || log.severity_text === "CRITICAL") ||
  (log.level === "error" || log.level === "critical")
).length;

const authEvents = recentLogs.filter(log => 
  log.category === "auth" || 
  log.message?.toLowerCase().includes("auth") ||
  log.message?.toLowerCase().includes("login") ||
  log.message?.toLowerCase().includes("ssh")
).length;
```

## 📊 Security Overview (Last 24 Hours)

<div class="metric-grid">
  <div class="metric-card">
    <h3>🔢 Total Events</h3>
    <div class="metric-value">${totalEvents.toLocaleString()}</div>
    <div class="metric-subtitle">Security events detected</div>
  </div>
  
  <div class="metric-card">
    <h3>⏰ Recent Events</h3>
    <div class="metric-value">${recentEvents}</div>
    <div class="metric-subtitle">Last hour</div>
  </div>
  
  <div class="metric-card critical">
    <h3>🚨 Critical Events</h3>
    <div class="metric-value">${criticalEvents}</div>
    <div class="metric-subtitle">High severity alerts</div>
  </div>
  
  <div class="metric-card">
    <h3>🔐 Auth Events</h3>
    <div class="metric-value">${authEvents}</div>
    <div class="metric-subtitle">Authentication attempts</div>
  </div>
</div>

## 🔗 Security Investigation Links

<div class="service-grid">
  <a href="http://quickwit.k3s.local/ui/search" class="service-card" target="_blank">
    <h3>🔍 Quickwit Search</h3>
    <p>Advanced security log search and investigation</p>
  </a>
  
  <a href="/" class="service-card">
    <h3>🏠 Main Dashboard</h3>
    <p>Overview of all observability data</p>
  </a>
  
  <a href="/operations" class="service-card">
    <h3>⚙️ Operations</h3>
    <p>Operational logs and system monitoring</p>
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