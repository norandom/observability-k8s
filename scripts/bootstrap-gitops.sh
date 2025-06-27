#!/bin/bash
set -e

echo "Setting up GitOps with ArgoCD..."

# Install ArgoCD with proper config
chmod +x argocd/install-argocd.sh
./argocd/install-argocd.sh

# Deploy the app of apps
echo "Deploying observability stack via ArgoCD..."
kubectl apply -f argocd/applications/observability-app.yaml

echo "GitOps setup complete!"
echo ""
echo "Access ArgoCD:"
echo "- URL: http://argocd.k3s.local"
echo "- Username: admin"
echo "- Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo ""
echo "Your observability stack will be automatically deployed and managed by ArgoCD!"