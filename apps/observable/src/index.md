# 🔍 Observability Dashboard

Welcome to the Observable Framework dashboard with conda Python environment support.

## 📊 Dashboards

### **Available Dashboards:**
- **[🏠 Home](/)** - This main dashboard
- **[🛡️ Security](/security)** - Security analysis and threat monitoring  
- **[⚙️ Operations](/operations)** - System performance and operational metrics

## 🌐 External Services

### **Monitoring & Analytics:**
- **[📊 Grafana](http://grafana.k3s.local)** - Operational monitoring dashboards
- **[🔍 Quickwit](http://quickwit.k3s.local/ui/search)** - Security log search and analysis
- **[🚀 ArgoCD](http://argocd.k3s.local)** - GitOps deployment management
- **[📝 Loki](http://loki.k3s.local)** - Log aggregation API

## 🐍 Python Environment

This Observable Framework includes:
- **Python 3.11** with conda environment
- **polars & pandas** for high-performance data processing
- **requests** for API integration
- **matplotlib, seaborn, plotly** for visualization

## 📡 Data Sources

- **Loki API**: `http://192.168.122.27:3100` - Operational logs
- **Quickwit API**: `http://192.168.122.27:7280` - Security logs
- **Prometheus**: `http://192.168.122.27:9090` - System metrics

---

*Built with Observable Framework + Conda • GitOps Enabled*