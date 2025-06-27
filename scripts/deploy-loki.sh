#!/bin/bash
set -e

echo "Deploying Loki..."
kubectl apply -f namespaces/loki-namespace.yaml
cd loki && ./install.sh && cd ..
kubectl apply -k loki/
echo "Loki deployment complete!"