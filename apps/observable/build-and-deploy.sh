#!/bin/bash
set -e

echo "🔨 Building Observable Framework conda container..."

# Build the Docker image
docker build -t observable-conda:latest .

echo "📦 Importing image to k3s..."

# Import to k3s
docker save observable-conda:latest | sudo k3s ctr images import -

echo "🚀 Deploying to k3s..."

# Deploy using kustomize
kubectl apply -k .

echo "⏳ Waiting for deployment to be ready..."

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s deployment/observable -n observable

echo "✅ Observable Framework deployed successfully!"
echo ""
echo "📊 Access your dashboard at: http://observable.k3s.local/"
echo ""
echo "🔍 Check pod status:"
kubectl get pods -n observable
echo ""
echo "📋 View logs:"
echo "kubectl logs -n observable deployment/observable -f"