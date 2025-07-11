#!/bin/bash

#
# Teleport Observable Framework Container Access Script
# 
# This script connects you directly to the Observable Framework container
# for live editing of markdown dashboard files using Teleport.
#
# Usage:
#   ./teleport-observable-connect.sh [command]
#   ./teleport-observable-connect.sh bash              # Interactive shell
#   ./teleport-observable-connect.sh edit-dashboard    # Edit dashboard files
#   ./teleport-observable-connect.sh sync-from-git     # Sync files from git
#   ./teleport-observable-connect.sh show-logs         # Show container logs
#

set -e

# Configuration
NAMESPACE="observable"
APP_LABEL="app=observable"
CONTAINER_NAME="observable"
WORKSPACE_PATH="/app/src"
TELEPORT_CLUSTER="${TELEPORT_CLUSTER:-k3s-observability}"

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

# Check if teleport is available
check_teleport() {
    if ! command -v tsh &> /dev/null; then
        log_error "Teleport (tsh) not found. Please install Teleport client first."
        log_info "Download from: https://goteleport.com/download/"
        exit 1
    fi
    
    if ! tsh status &> /dev/null; then
        log_error "Not logged into Teleport. Please run 'tsh login' first."
        exit 1
    fi
    
    log_success "Teleport client ready"
}

# Get the observable pod name
get_pod_name() {
    local pod_name
    pod_name=$(tsh kubectl get pods -n "$NAMESPACE" -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "No Observable pod found in namespace '$NAMESPACE'"
        log_info "Checking if pod exists with different label..."
        tsh kubectl get pods -n "$NAMESPACE"
        exit 1
    fi
    
    # Check if pod is running
    local pod_status
    pod_status=$(tsh kubectl get pod "$pod_name" -n "$NAMESPACE" -o jsonpath='{.status.phase}')
    
    if [ "$pod_status" != "Running" ]; then
        log_error "Observable pod '$pod_name' is not running (status: $pod_status)"
        exit 1
    fi
    
    echo "$pod_name"
}

# Show container information
show_container_info() {
    local pod_name="$1"
    
    log_info "Container Information:"
    echo "  Pod: $pod_name"
    echo "  Namespace: $NAMESPACE"
    echo "  Container: $CONTAINER_NAME"
    echo "  Workspace: $WORKSPACE_PATH"
    echo
}

# Interactive shell access
interactive_shell() {
    local pod_name="$1"
    
    log_info "Opening interactive shell in Observable container..."
    log_info "You can edit markdown files in: $WORKSPACE_PATH"
    log_info "Use 'exit' to close the connection"
    echo
    
    tsh kubectl exec -it "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- /bin/bash
}

# Edit dashboard files with nano/vim
edit_dashboard() {
    local pod_name="$1"
    
    log_info "Dashboard editing session starting..."
    log_info "Available commands in container:"
    echo "  - ls $WORKSPACE_PATH                     # List dashboard files"
    echo "  - nano $WORKSPACE_PATH/index.md         # Edit main dashboard"
    echo "  - nano $WORKSPACE_PATH/data/*.md        # Edit data files"
    echo "  - cat > $WORKSPACE_PATH/new-file.md     # Create new file"
    echo "  - npm run dev                            # Restart Observable (if needed)"
    echo
    
    tsh kubectl exec -it "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- /bin/bash -c "
        cd $WORKSPACE_PATH
        echo '📊 Observable Framework Dashboard Editor'
        echo '========================================='
        echo 'Current files:'
        ls -la
        echo
        echo 'Starting interactive editing session...'
        /bin/bash
    "
}

# Sync files from git repository
sync_from_git() {
    local pod_name="$1"
    
    log_info "Syncing dashboard files from git repository..."
    
    tsh kubectl exec -it "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- /bin/bash -c "
        echo '🔄 Syncing Observable dashboard files from git...'
        
        # Create temp directory for git clone
        cd /tmp
        rm -rf observable-sync
        
        # Clone repository
        git clone https://github.com/norandom/observability-k8s.git observable-sync
        cd observable-sync/apps/observable/src
        
        # Copy files to workspace
        echo 'Copying files to workspace...'
        cp -r * $WORKSPACE_PATH/
        
        # Show what was copied
        echo 'Files synced:'
        ls -la $WORKSPACE_PATH/
        
        # Cleanup
        cd /tmp
        rm -rf observable-sync
        
        echo '✅ Sync complete!'
    "
}

# Show container logs
show_logs() {
    local pod_name="$1"
    
    log_info "Showing Observable container logs (last 50 lines)..."
    echo
    
    tsh kubectl logs "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" --tail=50
}

# Copy files from local machine to container
copy_to_container() {
    local pod_name="$1"
    local local_path="$2"
    local remote_path="$3"
    
    if [ -z "$local_path" ] || [ -z "$remote_path" ]; then
        log_error "Usage: copy-to <local_path> <remote_path>"
        exit 1
    fi
    
    log_info "Copying '$local_path' to container:'$remote_path'"
    
    tsh kubectl cp "$local_path" "$NAMESPACE/$pod_name:$remote_path" -c "$CONTAINER_NAME"
    
    log_success "File copied successfully"
}

# Copy files from container to local machine
copy_from_container() {
    local pod_name="$1"
    local remote_path="$2"
    local local_path="$3"
    
    if [ -z "$remote_path" ] || [ -z "$local_path" ]; then
        log_error "Usage: copy-from <remote_path> <local_path>"
        exit 1
    fi
    
    log_info "Copying container:'$remote_path' to '$local_path'"
    
    tsh kubectl cp "$NAMESPACE/$pod_name:$remote_path" "$local_path" -c "$CONTAINER_NAME"
    
    log_success "File copied successfully"
}

# Show help
show_help() {
    echo "Teleport Observable Framework Container Access Script"
    echo
    echo "Usage: $0 [command] [args...]"
    echo
    echo "Commands:"
    echo "  bash                              Open interactive bash shell"
    echo "  edit-dashboard                    Start dashboard editing session"
    echo "  sync-from-git                     Sync dashboard files from git repository"
    echo "  show-logs                         Show container logs"
    echo "  copy-to <local_path> <remote_path>   Copy file to container"
    echo "  copy-from <remote_path> <local_path> Copy file from container"
    echo "  status                            Show container status"
    echo "  help                              Show this help"
    echo
    echo "Examples:"
    echo "  $0 bash                           # Interactive shell"
    echo "  $0 edit-dashboard                 # Edit dashboards"
    echo "  $0 copy-to ./dashboard.md /app/src/dashboard.md"
    echo "  $0 copy-from /app/src/data.md ./backup-data.md"
    echo
    echo "Environment Variables:"
    echo "  TELEPORT_CLUSTER                  Teleport cluster name (default: k3s-observability)"
    echo
    echo "Prerequisites:"
    echo "  - Teleport client (tsh) installed and logged in"
    echo "  - Access to Kubernetes cluster via Teleport"
    echo "  - Observable Framework pod running in 'observable' namespace"
}

# Main script logic
main() {
    local command="${1:-bash}"
    
    case "$command" in
        "help"|"-h"|"--help")
            show_help
            exit 0
            ;;
        "bash"|"shell")
            check_teleport
            pod_name=$(get_pod_name)
            show_container_info "$pod_name"
            interactive_shell "$pod_name"
            ;;
        "edit-dashboard"|"edit")
            check_teleport
            pod_name=$(get_pod_name)
            show_container_info "$pod_name"
            edit_dashboard "$pod_name"
            ;;
        "sync-from-git"|"sync")
            check_teleport
            pod_name=$(get_pod_name)
            show_container_info "$pod_name"
            sync_from_git "$pod_name"
            ;;
        "show-logs"|"logs")
            check_teleport
            pod_name=$(get_pod_name)
            show_logs "$pod_name"
            ;;
        "copy-to")
            check_teleport
            pod_name=$(get_pod_name)
            copy_to_container "$pod_name" "$2" "$3"
            ;;
        "copy-from")
            check_teleport
            pod_name=$(get_pod_name)
            copy_from_container "$pod_name" "$2" "$3"
            ;;
        "status")
            check_teleport
            pod_name=$(get_pod_name)
            show_container_info "$pod_name"
            log_info "Pod Status:"
            tsh kubectl get pod "$pod_name" -n "$NAMESPACE" -o wide
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