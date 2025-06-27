#!/bin/bash
set -e

echo "Installing ArgoCD..."

# Install ArgoCD
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD pods..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Apply our config, service patch, and ingress
echo "Applying ArgoCD configuration..."
kubectl apply -f argocd/argocd-config.yaml
kubectl apply -f argocd/argocd-service-patch.yaml
kubectl apply -f argocd/argocd-ingress.yaml

# Restart ArgoCD server to pick up insecure config
kubectl rollout restart deployment argocd-server -n argocd
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# Get admin password
echo "ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
echo
echo "ArgoCD installed and configured!"
echo "Access: http://argocd.k3s.local"
echo "Username: admin"
