#!/bin/bash
set -e

echo "Deploying OpenTelemetry Collector..."
kubectl apply -f namespaces/otel-namespace.yaml
kubectl apply -k otel/
kubectl wait --for=condition=available --timeout=300s deployment/otel-collector -n otel-system
echo "OpenTelemetry Collector deployment complete!"