#!/bin/bash
set -e

echo "Deploying Quickwit..."
kubectl apply -f namespaces/quickwit-namespace.yaml
kubectl apply -k quickwit/
kubectl wait --for=condition=available --timeout=300s deployment/quickwit -n quickwit-system
echo "Quickwit deployment complete!"