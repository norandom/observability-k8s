#!/bin/bash

#
# Telepresence Observable Framework Development Script
# 
# This script uses Telepresence to create a seamless local development
# environment for the Observable Framework, allowing you to edit files
# locally while they sync to the remote Kubernetes cluster.
#
# Usage:
#   ./telepresence-observable-connect.sh [command]
#   ./telepresence-observable-connect.sh connect       # Connect to cluster
#   ./telepresence-observable-connect.sh intercept     # Start development intercept
#   ./telepresence-observable-connect.sh local-dev     # Setup local development
#   ./telepresence-observable-connect.sh status        # Check connection status
#   ./telepresence-observable-connect.sh disconnect    # Disconnect from cluster
#

set -e

# Configuration
NAMESPACE="observable"
SERVICE_NAME="observable"
DEPLOYMENT_NAME="observable"
LOCAL_PORT="3000"
REMOTE_PORT="3000"
LOCAL_WORKSPACE="./observable-workspace"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if telepresence is available
check_telepresence() {
    if ! command -v telepresence &> /dev/null; then
        log_error "Telepresence not found. Please install Telepresence first."
        log_info "Install instructions:"
        log_info "  macOS: brew install datawire/blackbird/telepresence"
        log_info "  Linux: https://www.telepresence.io/docs/latest/install/"
        log_info "  Windows: https://www.telepresence.io/docs/latest/install/"
        exit 1
    fi
    
    log_success "Telepresence client available"
}

# Connect to the cluster
connect_to_cluster() {
    log_info "Connecting Telepresence to Kubernetes cluster..."
    
    if telepresence status &> /dev/null; then
        log_success "Already connected to cluster"
        telepresence status
        return 0
    fi
    
    log_info "Establishing Telepresence connection..."
    telepresence connect
    
    if [ $? -eq 0 ]; then
        log_success "Connected to cluster successfully"
        telepresence status
    else
        log_error "Failed to connect to cluster"
        exit 1
    fi
}

# Create local workspace
setup_local_workspace() {
    log_info "Setting up local workspace at: $LOCAL_WORKSPACE"
    
    if [ ! -d "$LOCAL_WORKSPACE" ]; then
        mkdir -p "$LOCAL_WORKSPACE"
        log_info "Created workspace directory"
    fi
    
    # Download current files from cluster
    log_info "Downloading current dashboard files from cluster..."
    
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=observable -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$pod_name" ]; then
        kubectl cp "$NAMESPACE/$pod_name:/app/src/" "$LOCAL_WORKSPACE/" -c observable || log_warn "Could not download files from cluster"
    fi
    
    # Create sample files if workspace is empty
    if [ ! -f "$LOCAL_WORKSPACE/index.md" ]; then
        log_info "Creating sample dashboard files..."
        cat > "$LOCAL_WORKSPACE/index.md" << 'EOF'
# Observable Framework Dashboard

Welcome to your local development environment!

## System Overview

This dashboard is being developed locally with Telepresence.

```js
// Sample data visualization
Plot.plot({
  title: "Development Environment",
  marks: [
    Plot.text([{x: 0, y: 0, text: "Local Development Active"}], {x: "x", y: "y"})
  ]
})
```

## Quick Links

- Edit this file locally to see changes instantly
- All changes sync to the remote cluster
- Access at http://localhost:3000

EOF
        
        # Create data directory
        mkdir -p "$LOCAL_WORKSPACE/data"
        
        cat > "$LOCAL_WORKSPACE/data/sample.json" << 'EOF'
[
  {"name": "Local Dev", "value": 100},
  {"name": "Remote Sync", "value": 95},
  {"name": "Hot Reload", "value": 98}
]
EOF
    fi
    
    log_success "Local workspace ready at: $LOCAL_WORKSPACE"
}

# Start Telepresence intercept
start_intercept() {
    check_telepresence
    connect_to_cluster
    setup_local_workspace
    
    log_info "Starting Telepresence intercept for Observable Framework..."
    log_info "This will redirect traffic from the cluster to your local environment"
    
    # Check if intercept already exists
    if telepresence list | grep -q "$DEPLOYMENT_NAME"; then
        log_warn "Intercept already active. Stopping existing intercept..."
        telepresence leave "$DEPLOYMENT_NAME-$NAMESPACE" || true
    fi
    
    log_info "Creating intercept for deployment: $DEPLOYMENT_NAME"
    log_info "Local port: $LOCAL_PORT, Remote port: $REMOTE_PORT"
    
    # Start the intercept
    telepresence intercept "$DEPLOYMENT_NAME" \
        --namespace "$NAMESPACE" \
        --port "$LOCAL_PORT:$REMOTE_PORT" \
        --mount "/tmp/observable-mount" || {
        log_error "Failed to create intercept"
        exit 1
    }
    
    log_success "Intercept created successfully!"
    log_info "Observable Framework traffic is now routed to your local environment"
    log_info "Access your local development at: http://localhost:$LOCAL_PORT"
    log_info "Edit files in: $LOCAL_WORKSPACE"
    
    # Start a simple file server for development
    start_local_server
}

# Start local development server
start_local_server() {
    log_info "Starting local Observable Framework server..."
    
    cd "$LOCAL_WORKSPACE"
    
    # Check if Observable Framework is installed locally
    if ! command -v observable &> /dev/null; then
        log_warn "Observable Framework not found locally"
        log_info "Installing Observable Framework..."
        npm install -g @observablehq/framework || {
            log_error "Failed to install Observable Framework"
            log_info "Please install manually: npm install -g @observablehq/framework"
            return 1
        }
    fi
    
    log_success "Starting Observable Framework development server..."
    log_info "Files in $LOCAL_WORKSPACE will be served locally"
    log_info "Changes will be reflected immediately"
    log_info "Press Ctrl+C to stop the server"
    
    # Start Observable Framework
    observable preview --port "$LOCAL_PORT" --host 0.0.0.0
}

# Setup local development without intercept
setup_local_dev() {
    check_telepresence
    connect_to_cluster
    setup_local_workspace
    
    log_info "Setting up local development environment..."
    log_info "This creates a local workspace synced with the cluster"
    
    cd "$LOCAL_WORKSPACE"
    
    log_success "Local development environment ready!"
    log_info "Workspace: $LOCAL_WORKSPACE"
    log_info "Edit files locally and use sync commands to update cluster"
    
    # Show available commands
    echo
    log_info "Available commands:"
    echo "  Edit files:     cd $LOCAL_WORKSPACE && code ."
    echo "  Sync to cluster: kubectl cp . $NAMESPACE/\$(kubectl get pods -n $NAMESPACE -l app=observable -o jsonpath='{.items[0].metadata.name}'):/app/src/"
    echo "  Start local:    cd $LOCAL_WORKSPACE && observable preview"
    echo "  Full intercept: $0 intercept"
}

# Sync files to cluster
sync_files_to_cluster() {
    if [ ! -d "$LOCAL_WORKSPACE" ]; then
        log_error "Local workspace not found. Run 'local-dev' first."
        exit 1
    fi
    
    log_info "Syncing files from $LOCAL_WORKSPACE to cluster..."
    
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=observable -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "No Observable pod found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    # Sync files
    kubectl cp "$LOCAL_WORKSPACE/." "$NAMESPACE/$pod_name:/app/src/" -c observable
    
    log_success "Files synced to cluster pod: $pod_name"
    log_info "Observable Framework will reload automatically"
}

# Show connection status
show_status() {
    check_telepresence
    
    log_info "Telepresence Status:"
    telepresence status
    
    echo
    log_info "Active Intercepts:"
    telepresence list
    
    echo
    if [ -d "$LOCAL_WORKSPACE" ]; then
        log_info "Local workspace: $LOCAL_WORKSPACE"
        log_info "Files in workspace:"
        ls -la "$LOCAL_WORKSPACE"
    else
        log_warn "Local workspace not set up"
    fi
}

# Disconnect from cluster
disconnect_from_cluster() {
    log_info "Disconnecting Telepresence from cluster..."
    
    # Stop any active intercepts
    if telepresence list | grep -q "$DEPLOYMENT_NAME"; then
        log_info "Stopping intercept for $DEPLOYMENT_NAME..."
        telepresence leave "$DEPLOYMENT_NAME-$NAMESPACE" || true
    fi
    
    # Disconnect from cluster
    telepresence quit
    
    log_success "Disconnected from cluster"
}

# Show help
show_help() {
    echo "Telepresence Observable Framework Development Script"
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Commands:"
    echo "  connect         Connect Telepresence to Kubernetes cluster"
    echo "  intercept       Start full development intercept (recommended)"
    echo "  local-dev       Setup local development workspace with manual sync"
    echo "  sync            Sync local files to cluster"
    echo "  status          Show Telepresence connection and intercept status"
    echo "  disconnect      Disconnect from cluster and stop intercepts"
    echo "  help            Show this help"
    echo
    echo "Development Workflow:"
    echo "  1. $0 intercept                 # Start intercepted development"
    echo "  2. Edit files in $LOCAL_WORKSPACE"
    echo "  3. View changes at http://localhost:$LOCAL_PORT"
    echo "  4. $0 disconnect               # Clean up when done"
    echo
    echo "Manual Sync Workflow:"
    echo "  1. $0 local-dev                # Setup local workspace"
    echo "  2. Edit files in $LOCAL_WORKSPACE"
    echo "  3. $0 sync                     # Sync changes to cluster"
    echo
    echo "Prerequisites:"
    echo "  - Telepresence installed (brew install datawire/blackbird/telepresence)"
    echo "  - kubectl configured for your cluster"
    echo "  - Observable Framework pod running in '$NAMESPACE' namespace"
}

# Main script logic
main() {
    local command="${1:-help}"
    
    case "$command" in
        "connect")
            check_telepresence
            connect_to_cluster
            ;;
        "intercept")
            start_intercept
            ;;
        "local-dev")
            setup_local_dev
            ;;
        "sync")
            sync_files_to_cluster
            ;;
        "status")
            show_status
            ;;
        "disconnect")
            disconnect_from_cluster
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"