#!/bin/bash
set -e

REGISTRY_URL="192.168.122.27:30500"
IMAGE_NAME="observable-conda"
NAMESPACE="observable"

echo "🔨 Building Observable Framework conda container..."

# Check if registry is running
if ! curl -f http://${REGISTRY_URL}/v2/ > /dev/null 2>&1; then
    echo "📦 Registry not found, deploying in-cluster registry..."
    kubectl apply -f registry-deployment.yaml
    echo "⏳ Waiting for registry to be ready..."
    kubectl wait --for=condition=available --timeout=120s deployment/registry -n registry
    sleep 10  # Give registry time to start
fi

# Build the Docker image
echo "🔨 Building Docker image..."
docker build -t ${REGISTRY_URL}/${IMAGE_NAME}:latest .

# Configure Docker for insecure registry if needed
echo "📤 Pushing to internal registry ${REGISTRY_URL}..."
if ! docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest 2>/dev/null; then
    echo "⚠️  Push failed, configuring insecure registry..."
    
    # Create docker daemon config for insecure registry
    sudo mkdir -p /etc/docker
    if [ ! -f /etc/docker/daemon.json ]; then
        echo '{"insecure-registries": []}' | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    
    # Add insecure registry if not already present
    if ! grep -q "${REGISTRY_URL}" /etc/docker/daemon.json; then
        sudo jq ".\"insecure-registries\" += [\"${REGISTRY_URL}\"]" /etc/docker/daemon.json > /tmp/daemon.json
        sudo mv /tmp/daemon.json /etc/docker/daemon.json
        echo "🔄 Restarting Docker daemon..."
        sudo systemctl restart docker
        sleep 5
    fi
    
    # Try push again
    docker push ${REGISTRY_URL}/${IMAGE_NAME}:latest
fi

echo "🚀 Deploying to cluster..."

# Make sure namespace exists
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Deploy using kustomize (conda version)
kubectl apply -k .

echo "⏳ Waiting for deployment to be ready..."

# Wait for deployment to be ready
kubectl wait --for=condition=available --timeout=300s deployment/observable -n ${NAMESPACE}

# Restart deployment to ensure latest image is pulled
echo "🔄 Restarting deployment to use latest image..."
kubectl rollout restart deployment/observable -n ${NAMESPACE}
kubectl rollout status deployment/observable -n ${NAMESPACE} --timeout=300s

echo "✅ Observable Framework deployed successfully!"
echo ""
echo "📊 Access your dashboard at: http://observable.k3s.local/"
echo ""
echo "🔍 Pod status:"
kubectl get pods -n ${NAMESPACE} -l app=observable
echo ""
echo "📋 Recent logs:"
kubectl logs -n ${NAMESPACE} deployment/observable --tail=20
echo ""
echo "📋 Follow logs with:"
echo "kubectl logs -n ${NAMESPACE} deployment/observable -f"