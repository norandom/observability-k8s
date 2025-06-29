# 🔍 Observability Dashboard

Welcome to the comprehensive observability stack with real-time monitoring, security analysis, and operational insights.

```js
// Load data from both systems for overview
const operationalData = FileAttachment("data/loki-logs.json").json();
const securityData = FileAttachment("data/quickwit-logs.json").json();
```

## 📊 System Overview

<div class="grid grid-cols-4">
  <div class="card">
    <h3>📝 Total Logs</h3>
    <span class="big-number">${operationalData.summary.total_logs + securityData.summary.total_events}</span>
    <p>Combined events</p>
  </div>
  <div class="card">
    <h3>⚙️ Operations</h3>
    <span class="big-number operational">${operationalData.summary.total_logs}</span>
    <p>Operational logs</p>
  </div>
  <div class="card">
    <h3>🛡️ Security</h3>
    <span class="big-number security">${securityData.summary.total_events}</span>
    <p>Security events</p>
  </div>
  <div class="card">
    <h3>🎯 Demo Data</h3>
    <span class="big-number demo">${operationalData.summary.demo_logs + securityData.summary.demo_events}</span>
    <p>Sample events</p>
  </div>
</div>

## 🚀 Dashboard Navigation

<div class="grid grid-cols-2">
  <a href="/operations" class="dashboard-card operations">
    <h3>⚙️ Operations Dashboard</h3>
    <div class="stats">
      <span class="stat-number">${operationalData.summary.total_logs}</span>
      <span class="stat-label">Total Logs</span>
    </div>
    <p>System monitoring, service health, log analysis, and operational metrics</p>
    <div class="features">
      <span class="feature">📈 Log Volume Analysis</span>
      <span class="feature">🏢 Service Activity</span>
      <span class="feature">🔍 Health Monitoring</span>
    </div>
  </a>

  <a href="/security" class="dashboard-card security">
    <h3>🛡️ Security Dashboard</h3>
    <div class="stats">
      <span class="stat-number">${securityData.critical_events.length}</span>
      <span class="stat-label">Critical Events</span>
    </div>
    <p>Threat detection, attack analysis, authentication monitoring, and forensic investigation</p>
    <div class="features">
      <span class="feature">🚨 Threat Analysis</span>
      <span class="feature">🔐 Auth Monitoring</span>
      <span class="feature">🎯 Attack Detection</span>
    </div>
  </a>
</div>

## 🔗 Observability Services

<div class="grid grid-cols-3">
  <a href="http://grafana.k3s.local" class="service-card grafana" target="_blank">
    <div class="service-icon">📊</div>
    <h3>Grafana</h3>
    <p>Interactive dashboards and operational monitoring with LogQL queries</p>
    <div class="service-details">
      <span>• Time-series visualization</span>
      <span>• Alert management</span>
      <span>• Loki integration</span>
    </div>
  </a>

  <a href="http://quickwit.k3s.local/ui/search" class="service-card quickwit" target="_blank">
    <div class="service-icon">🔍</div>
    <h3>Quickwit Search</h3>
    <p>Advanced full-text search engine for security log analysis and forensics</p>
    <div class="service-details">
      <span>• Full-text search</span>
      <span>• Complex queries</span>
      <span>• Security analysis</span>
    </div>
  </a>

  <a href="http://argocd.k3s.local" class="service-card argocd" target="_blank">
    <div class="service-icon">🚀</div>
    <h3>ArgoCD</h3>
    <p>GitOps continuous deployment and application lifecycle management</p>
    <div class="service-details">
      <span>• GitOps automation</span>
      <span>• Deployment tracking</span>
      <span>• Sync monitoring</span>
    </div>
  </a>
</div>

## 📋 Quick Actions

<div class="grid grid-cols-2">
  <div class="action-card">
    <h3>🔧 Development Resources</h3>
    <div class="action-links">
      <a href="https://github.com/your-org/observability-k8s" target="_blank" class="action-link">
        📖 Project README
      </a>
      <a href="https://github.com/your-org/observability-k8s/blob/main/Example-Usage.md" target="_blank" class="action-link">
        📋 Usage Guide
      </a>
    </div>
  </div>

  <div class="action-card">
    <h3>⚡ Live Data Sources</h3>
    <div class="action-links">
      <a href="http://loki.k3s.local" target="_blank" class="action-link">
        📝 Loki API
      </a>
      <a href="http://192.168.122.27:7280/api/v1/otel-logs-v0_7" target="_blank" class="action-link">
        🔍 Quickwit API
      </a>
    </div>
  </div>
</div>

## 📈 Real-time Analytics

```js
// Calculate system health metrics
const operationsCritical = operationalData.summary.by_level.CRITICAL || 0;
const operationsErrors = operationalData.summary.by_level.ERROR || 0;
const securityCritical = securityData.summary.by_severity.CRITICAL || 0;
const securityErrors = securityData.summary.by_severity.ERROR || 0;

const totalCritical = operationsCritical + securityCritical;
const totalErrors = operationsErrors + securityErrors;

const systemHealth = Math.max(0, 100 - (totalCritical * 10 + totalErrors * 5));
const healthStatus = systemHealth >= 90 ? "🟢 Excellent" : 
                    systemHealth >= 70 ? "🟡 Good" : 
                    systemHealth >= 50 ? "🟠 Warning" : "🔴 Critical";
```

<div class="grid grid-cols-3">
  <div class="card health-card">
    <h3>🎯 System Health</h3>
    <span class="big-number health">${systemHealth.toFixed(0)}%</span>
    <p class="health-status">${healthStatus}</p>
  </div>
  <div class="card">
    <h3>⚠️ Issues Detected</h3>
    <span class="big-number error">${totalCritical + totalErrors}</span>
    <p>Critical: ${totalCritical} | Errors: ${totalErrors}</p>
  </div>
  <div class="card">
    <h3>🔄 Data Freshness</h3>
    <span class="small-text">Operations</span>
    <p>${new Date(operationalData.last_updated).toLocaleTimeString()}</p>
    <span class="small-text">Security</span>
    <p>${new Date(securityData.last_updated).toLocaleTimeString()}</p>
  </div>
</div>

## 🏗️ Architecture Overview

This observability stack implements a dual-pipeline architecture:

- **📊 Operations Pipeline**: Vector → OpenTelemetry → Loki → Grafana + Observable
- **🛡️ Security Pipeline**: Vector → OpenTelemetry → Quickwit → Observable
- **🚀 GitOps Management**: ArgoCD manages all deployments and configurations
- **🐍 Data Analytics**: Python loaders fetch API data for Observable Framework dashboards

## 🔄 Live Data Integration

```js
// Show data freshness indicators
const dataAge = (timestamp) => {
  const age = Date.now() - new Date(timestamp).getTime();
  const minutes = Math.floor(age / 60000);
  return minutes < 1 ? "Just now" : minutes < 60 ? `${minutes}m ago` : `${Math.floor(minutes/60)}h ago`;
};
```

<div class="grid grid-cols-2">
  <div class="card data-status">
    <h3>📊 Operational Data</h3>
    <p><strong>Source:</strong> Loki API</p>
    <p><strong>Last Update:</strong> ${dataAge(operationalData.last_updated)}</p>
    <p><strong>Loader:</strong> loki-logs.py</p>
  </div>
  <div class="card data-status">
    <h3>🛡️ Security Data</h3>
    <p><strong>Source:</strong> Quickwit API</p>
    <p><strong>Last Update:</strong> ${dataAge(securityData.last_updated)}</p>
    <p><strong>Loader:</strong> quickwit-logs.py</p>
  </div>
</div>

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

.dashboard-card {
  background: linear-gradient(135deg, #ffffff 0%, #f8f9fa 100%);
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 1.5rem;
  text-decoration: none;
  color: inherit;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.dashboard-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 4px;
  background: linear-gradient(90deg, #3b82f6, #10b981);
}

.dashboard-card.operations::before {
  background: linear-gradient(90deg, #3b82f6, #06b6d4);
}

.dashboard-card.security::before {
  background: linear-gradient(90deg, #dc2626, #ea580c);
}

.dashboard-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.15);
  border-color: #3b82f6;
}

.stats {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 1rem 0;
}

.stat-number {
  font-size: 2rem;
  font-weight: bold;
  color: #1f2937;
}

.stat-label {
  font-size: 0.875rem;
  color: #6b7280;
}

.features {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-top: 1rem;
}

.feature {
  background: #f3f4f6;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  color: #4b5563;
}

.service-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 1.5rem;
  text-decoration: none;
  color: inherit;
  transition: all 0.2s ease;
  text-align: center;
}

.service-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
}

.service-card.grafana:hover { border-color: #f97316; }
.service-card.quickwit:hover { border-color: #8b5cf6; }
.service-card.argocd:hover { border-color: #06b6d4; }

.service-icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.service-details {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  margin-top: 1rem;
  font-size: 0.875rem;
  color: #6b7280;
}

.action-card {
  background: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 1rem;
}

.action-links {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  margin-top: 1rem;
}

.action-link {
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  padding: 0.75rem;
  text-decoration: none;
  color: #374151;
  transition: all 0.2s ease;
}

.action-link:hover {
  background: #f3f4f6;
  border-color: #9ca3af;
}

.big-number {
  font-size: 2rem;
  font-weight: bold;
  color: #1f2937;
}

.big-number.operational { color: #3b82f6; }
.big-number.security { color: #dc2626; }
.big-number.demo { color: #f59e0b; }
.big-number.health { color: #10b981; }
.big-number.error { color: #dc2626; }

.small-text {
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 600;
}

.health-status {
  font-weight: 600;
  margin-top: 0.5rem;
}

.health-card {
  border-left: 4px solid #10b981;
}

.data-status {
  border-left: 3px solid #6b7280;
}

h2, h3 {
  margin: 0 0 0.5rem 0;
  color: #374151;
}

h1 {
  color: #1f2937;
  border-bottom: 2px solid #e5e7eb;
  padding-bottom: 1rem;
}
</style>