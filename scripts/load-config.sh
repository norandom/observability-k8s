#!/bin/bash

# Load cluster configuration
CONFIG_FILE="$(dirname "$0")/../config/cluster-config.env"

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "Loaded cluster config: CLUSTER_IP=$CLUSTER_IP"
else
    echo "Warning: Config file not found at $CONFIG_FILE"
    echo "Using default CLUSTER_IP=192.168.122.27"
    CLUSTER_IP=192.168.122.27
fi

# Export derived variables
export CLUSTER_IP
export OTEL_HTTP_ENDPOINT="http://${CLUSTER_IP}:4318"
export OTEL_GRPC_ENDPOINT="http://${CLUSTER_IP}:4317"
export QUICKWIT_ENDPOINT="http://${CLUSTER_IP}:7280"