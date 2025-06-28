#!/bin/bash

# Script to configure vector client with the correct cluster IP

SCRIPT_DIR="$(dirname "$0")"
source "$SCRIPT_DIR/load-config.sh"

# Template file location
TEMPLATE_FILE="$SCRIPT_DIR/../vector-client-config.toml.template"
OUTPUT_FILE="$SCRIPT_DIR/../vector-client-config.toml"

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    echo "Please create the template file first"
    exit 1
fi

echo "Configuring Vector client config with CLUSTER_IP=$CLUSTER_IP"

# Replace placeholder with actual IP
sed "s/{{CLUSTER_IP}}/$CLUSTER_IP/g" "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Vector configuration updated at $OUTPUT_FILE"
echo "OTEL endpoint: $OTEL_HTTP_ENDPOINT"