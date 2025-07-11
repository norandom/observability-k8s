#!/bin/bash

#
# Observable Dashboard Manager
#
# A simplified script for common Observable Framework dashboard operations
# Works with both direct kubectl and Teleport (auto-detects)
#
# Usage:
#   ./observable-dashboard-manager.sh quick-edit <filename>
#   ./observable-dashboard-manager.sh upload-file <local-file>
#   ./observable-dashboard-manager.sh download-file <remote-file>
#   ./observable-dashboard-manager.sh list-files
#   ./observable-dashboard-manager.sh restart-service
#

set -e

# Configuration
NAMESPACE="observable"
APP_LABEL="app=observable"
CONTAINER_NAME="observable"
WORKSPACE_PATH="/app/src"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Detect kubectl command (telepresence or direct)
detect_kubectl() {
    if command -v kubectl &> /dev/null; then
        echo "kubectl"
    else
        log_error "kubectl is not available"
        log_info "Please install kubectl or ensure it's in your PATH"
        exit 1
    fi
}

# Get pod name
get_pod() {
    local kubectl_cmd="$1"
    local pod_name
    pod_name=$($kubectl_cmd get pods -n "$NAMESPACE" -l "$APP_LABEL" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "No Observable pod found"
        exit 1
    fi
    
    echo "$pod_name"
}

# Quick edit a specific file
quick_edit() {
    local kubectl_cmd="$1"
    local pod_name="$2"
    local filename="$3"
    
    if [ -z "$filename" ]; then
        log_error "Please specify a filename to edit"
        log_info "Usage: $0 quick-edit <filename>"
        log_info "Example: $0 quick-edit index.md"
        exit 1
    fi
    
    local full_path="$WORKSPACE_PATH/$filename"
    
    log_info "Opening '$filename' for editing..."
    log_info "Use Ctrl+X to save and exit nano"
    
    $kubectl_cmd exec -it "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- nano "$full_path"
    
    log_success "File editing completed"
}

# Upload a file from local machine
upload_file() {
    local kubectl_cmd="$1"
    local pod_name="$2"
    local local_file="$3"
    
    if [ -z "$local_file" ]; then
        log_error "Please specify a local file to upload"
        log_info "Usage: $0 upload-file <local-file>"
        exit 1
    fi
    
    if [ ! -f "$local_file" ]; then
        log_error "Local file '$local_file' not found"
        exit 1
    fi
    
    local filename=$(basename "$local_file")
    local remote_path="$WORKSPACE_PATH/$filename"
    
    log_info "Uploading '$local_file' to container as '$filename'..."
    
    $kubectl_cmd cp "$local_file" "$NAMESPACE/$pod_name:$remote_path" -c "$CONTAINER_NAME"
    
    log_success "File uploaded successfully to $remote_path"
}

# Download a file from container
download_file() {
    local kubectl_cmd="$1"
    local pod_name="$2"
    local remote_file="$3"
    
    if [ -z "$remote_file" ]; then
        log_error "Please specify a remote file to download"
        log_info "Usage: $0 download-file <remote-file>"
        log_info "Example: $0 download-file index.md"
        exit 1
    fi
    
    local remote_path="$WORKSPACE_PATH/$remote_file"
    local local_path="./downloaded-$remote_file"
    
    log_info "Downloading '$remote_file' from container..."
    
    $kubectl_cmd cp "$NAMESPACE/$pod_name:$remote_path" "$local_path" -c "$CONTAINER_NAME"
    
    log_success "File downloaded as '$local_path'"
}

# List files in the workspace
list_files() {
    local kubectl_cmd="$1"
    local pod_name="$2"
    
    log_info "Files in Observable workspace ($WORKSPACE_PATH):"
    echo
    
    $kubectl_cmd exec "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- find "$WORKSPACE_PATH" -type f -name "*.md" -o -name "*.js" -o -name "*.json" | sort
}

# Restart the Observable service
restart_service() {
    local kubectl_cmd="$1"
    local pod_name="$2"
    
    log_info "Restarting Observable Framework service..."
    
    $kubectl_cmd exec "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- pkill -f "npm run dev" || true
    
    log_info "Service process stopped. Container will restart automatically."
    log_success "Observable Framework will be available shortly at http://localhost:3000"
}

# Show workspace structure
show_structure() {
    local kubectl_cmd="$1"
    local pod_name="$2"
    
    log_info "Observable workspace structure:"
    echo
    
    $kubectl_cmd exec "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- tree "$WORKSPACE_PATH" 2>/dev/null || \
    $kubectl_cmd exec "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- find "$WORKSPACE_PATH" -type d | sed 's/[^/]*\//  /g'
}

# Create a new dashboard file from template
create_dashboard() {
    local kubectl_cmd="$1"
    local pod_name="$2"
    local dashboard_name="$3"
    
    if [ -z "$dashboard_name" ]; then
        log_error "Please specify a dashboard name"
        log_info "Usage: $0 create-dashboard <dashboard-name>"
        log_info "Example: $0 create-dashboard metrics"
        exit 1
    fi
    
    local filename="${dashboard_name}.md"
    local file_path="$WORKSPACE_PATH/$filename"
    
    log_info "Creating new dashboard '$filename'..."
    
    $kubectl_cmd exec "$pod_name" -n "$NAMESPACE" -c "$CONTAINER_NAME" -- /bin/bash -c "cat > '$file_path' << 'EOF'
# $dashboard_name Dashboard

\`\`\`js
// Sample data loader
data = FileAttachment(\"data/sample.json\").json()
\`\`\`

## Overview

This is a new dashboard for **$dashboard_name**.

\`\`\`js
// Sample visualization
Plot.plot({
  marks: [
    Plot.barY(data, {x: \"name\", y: \"value\"})
  ]
})
\`\`\`

## Data Sources

- Prometheus: \${PROMETHEUS_ENDPOINT}
- Loki: \${LOKI_ENDPOINT}
- Quickwit: \${QUICKWIT_ENDPOINT}

EOF"
    
    log_success "Dashboard created: $file_path"
    log_info "You can now edit it with: $0 quick-edit $filename"
}

# Show help
show_help() {
    echo "Observable Dashboard Manager"
    echo
    echo "Usage: $0 <command> [args...]"
    echo
    echo "Commands:"
    echo "  quick-edit <filename>       Edit a specific file with nano"
    echo "  upload-file <local-file>    Upload a file to the workspace"
    echo "  download-file <remote-file> Download a file from the workspace"
    echo "  list-files                  List all dashboard files"
    echo "  show-structure              Show workspace directory structure"
    echo "  create-dashboard <name>     Create a new dashboard from template"
    echo "  restart-service             Restart the Observable service"
    echo "  help                        Show this help"
    echo
    echo "Examples:"
    echo "  $0 quick-edit index.md"
    echo "  $0 upload-file ./new-dashboard.md"
    echo "  $0 download-file data/metrics.json"
    echo "  $0 create-dashboard security-metrics"
    echo
    echo "Note: Works with kubectl and integrates with Telepresence workflows"
}

# Main function
main() {
    local command="$1"
    
    if [ -z "$command" ]; then
        show_help
        exit 0
    fi
    
    local kubectl_cmd
    kubectl_cmd=$(detect_kubectl)
    log_info "Using: $kubectl_cmd"
    
    # Check if we're in a Telepresence environment
    if command -v telepresence &> /dev/null && telepresence status &> /dev/null 2>&1; then
        log_info "Telepresence connection detected - enhanced workflows available"
    fi
    
    local pod_name
    pod_name=$(get_pod "$kubectl_cmd")
    log_info "Found pod: $pod_name"
    
    case "$command" in
        "quick-edit"|"edit")
            quick_edit "$kubectl_cmd" "$pod_name" "$2"
            ;;
        "upload-file"|"upload")
            upload_file "$kubectl_cmd" "$pod_name" "$2"
            ;;
        "download-file"|"download")
            download_file "$kubectl_cmd" "$pod_name" "$2"
            ;;
        "list-files"|"list")
            list_files "$kubectl_cmd" "$pod_name"
            ;;
        "show-structure"|"structure")
            show_structure "$kubectl_cmd" "$pod_name"
            ;;
        "create-dashboard"|"create")
            create_dashboard "$kubectl_cmd" "$pod_name" "$2"
            ;;
        "restart-service"|"restart")
            restart_service "$kubectl_cmd" "$pod_name"
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

main "$@"