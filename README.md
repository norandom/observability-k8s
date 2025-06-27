# GitOps Observability Stack

Complete observability stack managed by ArgoCD for learning GitOps principles.

## Quick Start

1. **Bootstrap ArgoCD and the stack:**
   ```bash
   chmod +x scripts/bootstrap-gitops.sh
   ./scripts/bootstrap-gitops.sh
   ```

## Access ArgoCD UI

```bash
# Get credentials
echo "Username: admin"
echo "Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"

# Access UI (use Host header)
curl -H "Host: argocd.k3s.local" http://192.168.122.27/
```

## GitOps Workflow

1. Make changes to any YAML in `apps/`
2. Commit and push to your Git repository
3. ArgoCD automatically syncs changes to cluster
4. Monitor in ArgoCD UI - see deployment status, health, sync status

## Applications Managed by ArgoCD

- **Grafana** (`apps/grafana/`)
- **Loki** (Helm chart)
- **OpenTelemetry Collector** (`apps/otel/`)
- **Quickwit** (`apps/quickwit/`)

## Learning GitOps

- **App of Apps pattern** - ArgoCD manages multiple applications
- **Automated sync** - Changes in Git trigger deployments
- **Self-healing** - ArgoCD fixes configuration drift
- **Rollback capability** - Easy rollback to previous Git commits
- **Health monitoring** - Visual health status of all components

## Making Changes

```bash
# Example: Update Grafana image
vi apps/grafana/grafana-deployment.yaml
# Change image: grafana/grafana:latest to grafana/grafana:10.2.0

git add .
git commit -m "Update Grafana to 10.2.0"
git push

# Watch ArgoCD sync the change automatically
```

## Access Points

- **ArgoCD UI**: http://argocd.k3s.local
- **Grafana**: http://grafana.k3s.local
- **OTel Endpoint**: http://192.168.122.27:4318/v1/logs
- **Quickwit**: http://quickwit.k3s.local
- **Loki**: http://loki.k3s.local

## Data Sources in Grafana

- **Loki**: http://loki-gateway.loki-system.svc.cluster.local/
- **Quickwit**: http://quickwit.quickwit-system.svc.cluster.local:7280

## Log Routing

- **Security logs** (auth, audit) → Quickwit
- **Operational logs** (syslog, web) → Loki

## Architecture

```
Vector/Clients → OpenTelemetry Collector → {Loki (operational), Quickwit (security)}
                           ↓                    ↓
                   Grafana (dashboards)  Grafana (search)
```

**Key GitOps Learning Benefits:**
- **Declarative** - Everything defined in Git
- **Automated** - Changes deploy automatically
- **Auditable** - Git history = deployment history
- **Rollback** - Easy to revert via Git
- **Drift detection** - ArgoCD shows configuration drift
- **Health monitoring** - Visual status of all applications

This setup gives you hands-on experience with production GitOps patterns!