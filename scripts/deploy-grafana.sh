#!/bin/bash
set -e

echo "Deploying Grafana..."
kubectl apply -f namespaces/grafana-namespace.yaml
kubectl apply -k apps/grafana/
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n my-grafana
echo "Grafana deployment complete!"