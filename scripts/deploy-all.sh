#!/bin/bash
set -e

echo "Deploying observability stack..."

# Deploy namespaces first
kubectl apply -f namespaces/

# Deploy Loki (Helm)
echo "Installing Loki..."
cd loki && ./install.sh && cd ..

# Deploy everything else with kustomize
echo "Deploying Grafana..."
kubectl apply -k grafana/

echo "Deploying OpenTelemetry Collector..."
kubectl apply -k otel/

echo "Deploying Quickwit..."
kubectl apply -k quickwit/

echo "Waiting for deployments..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n my-grafana
kubectl wait --for=condition=available --timeout=300s deployment/otel-collector -n otel-system
kubectl wait --for=condition=available --timeout=300s deployment/quickwit -n quickwit-system

echo "Deployment complete!"
echo "Access points:"
echo "- Grafana: http://grafana.k3s.local (with Host header)"
echo "- OTel Collector: http://otel.k3s.local (with Host header)"
echo "- Quickwit: http://quickwit.k3s.local (with Host header)"
echo "- Loki: http://loki.k3s.local (with Host header)"