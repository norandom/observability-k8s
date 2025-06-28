# Observable Framework Dashboard

Observable Framework dashboard with interactive data visualization for observability monitoring.

## ✅ Current Status

**WORKING**: Observable Framework is deployed and accessible at:
- **Main Dashboard**: http://observable.k3s.local/
- **Security Dashboard**: http://observable.k3s.local/security
- **Operations Dashboard**: http://observable.k3s.local/operations

## 📊 Features

- **Observable Framework v1.13.3** for interactive dashboards
- **JavaScript data processing** with reactive components
- **Live metrics and visualizations** with sample data
- **GitOps workflow** for dashboard updates via ConfigMap
- **Auto-building container system** (Tekton pipelines)

## 📁 Dashboard Files

The dashboards are defined in `observable-configmap.yaml`:

### Main Dashboards:
- **`index.md`** - Main observability dashboard with service links
- **`security.md`** - Security analysis dashboard with threat monitoring
- **`operations.md`** - Operations monitoring with system metrics

### JavaScript Components:
Each dashboard includes:
- **Data loading** with JavaScript code blocks
- **Interactive visualizations** with metric cards and tables  
- **Responsive styling** with CSS
- **API endpoint references** for Loki, Quickwit, and Prometheus

## 🚀 Deployment

### Standard Deployment:
```bash
kubectl apply -k .
```

### Individual Components:
```bash
# Deploy just the Observable Framework
kubectl apply -f observable-deployment.yaml -f observable-configmap.yaml

# Deploy with auto-building (requires Tekton)
kubectl apply -f tekton-pipeline.yaml
```

## 🔧 Configuration

### Environment Variables:
- `LOKI_ENDPOINT`: http://192.168.122.27:3100
- `QUICKWIT_ENDPOINT`: http://192.168.122.27:7280  
- `PROMETHEUS_ENDPOINT`: http://192.168.122.27:9090
- `OBSERVABLE_TELEMETRY_DISABLE`: true

### Adding New Dashboards:
1. Add new `.md` file to `observable-configmap.yaml`
2. Include JavaScript code blocks for data processing
3. Add page entry to `observablehq.config.js` in deployment
4. Commit changes (triggers auto-rebuild if enabled)

## 🏗️ Auto-Building System

### Container Build Process:
1. **Tekton Pipeline**: Detects changes to `.md`, `.yml`, or `Dockerfile`
2. **Kaniko Build**: Creates container with Observable Framework + dashboards
3. **Registry Push**: Stores image in internal registry  
4. **Deployment Update**: Automatically updates running containers

### Build Triggers:
- Changes to dashboard files (`.md`)
- Updates to `conda-environment.yml`
- Dockerfile modifications
- Manual trigger via pipeline runs

## 🎯 Usage Examples

### Security Dashboard:
- View security event metrics with JavaScript calculations
- Interactive tables with filtering and styling
- Real-time threat analysis visualization

### Operations Dashboard:  
- System health overview with metric cards
- Service performance monitoring
- Log analysis with responsive tables

## 📡 Data Integration

### Current Status:
- **Sample Data**: Embedded in dashboards for demonstration
- **API Endpoints**: Configured for Loki, Quickwit, Prometheus integration
- **Future Enhancement**: Add Python data loaders for live API queries

### Data Sources:
- **Loki API**: Operational log aggregation
- **Quickwit API**: Security log search and analysis  
- **Prometheus**: System metrics and monitoring

## 🔍 Troubleshooting

### Common Issues:
1. **"No available server"**: Check pod status with `kubectl get pods -n observable`
2. **Container crashes**: Review logs with `kubectl logs deployment/observable -n observable`
3. **404 on dashboards**: Verify ConfigMap with `kubectl get configmap observable-dashboards -n observable`

### Debug Commands:
```bash
# Check deployment status
kubectl get pods -n observable

# View logs
kubectl logs deployment/observable -n observable

# Test URLs
curl http://observable.k3s.local/
curl http://observable.k3s.local/security
curl http://observable.k3s.local/operations
```

## 🏆 Achievements

### ✅ Completed:
- Observable Framework deployment with proper `.md` file processing
- JavaScript code blocks working in dashboards
- Interactive visualizations with metric cards and tables
- Auto-building container system with Tekton pipelines
- K3s registry configuration for insecure registry access
- GitOps workflow for dashboard updates

### 🎯 Next Steps:
- Add live data loaders connecting to Loki, Quickwit, and Prometheus APIs
- Enhance Python data processing with polars/pandas integration
- Implement real-time data refresh in dashboards