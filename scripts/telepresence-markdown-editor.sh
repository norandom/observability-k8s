#!/bin/bash

#
# Telepresence Markdown Editor for Observable Framework
#
# A streamlined script for editing markdown files in the Observable container
# using Telepresence for seamless local-to-remote development.
#
# Usage:
#   ./telepresence-markdown-editor.sh edit <filename>      # Edit specific file
#   ./telepresence-markdown-editor.sh list                # List markdown files
#   ./telepresence-markdown-editor.sh new <filename>      # Create new markdown file
#   ./telepresence-markdown-editor.sh quick-start         # Setup and start editing
#   ./telepresence-markdown-editor.sh sync-local         # Sync to local workspace
#

set -e

# Configuration
NAMESPACE="observable"
DEPLOYMENT_NAME="observable"
LOCAL_WORKSPACE="./observable-workspace"
REMOTE_WORKSPACE="/app/src"

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

# Check prerequisites
check_prerequisites() {
    if ! command -v telepresence &> /dev/null; then
        log_error "Telepresence not found. Please install:"
        log_info "  macOS: brew install datawire/blackbird/telepresence"
        log_info "  Linux: https://www.telepresence.io/docs/latest/install/"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Ensure Telepresence connection
ensure_telepresence_connection() {
    if ! telepresence status &> /dev/null; then
        log_info "Connecting to cluster via Telepresence..."
        telepresence connect
        
        if [ $? -ne 0 ]; then
            log_error "Failed to connect to cluster"
            exit 1
        fi
    fi
    
    log_success "Telepresence connected"
}

# Setup local workspace with current files
setup_workspace() {
    log_info "Setting up local workspace for markdown editing..."
    
    # Create workspace if it doesn't exist
    mkdir -p "$LOCAL_WORKSPACE"
    
    # Get current pod
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=observable -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "No Observable pod found in namespace '$NAMESPACE'"
        exit 1
    fi
    
    log_info "Downloading current markdown files from pod: $pod_name"
    
    # Download all markdown files
    kubectl exec "$pod_name" -n "$NAMESPACE" -c observable -- find "$REMOTE_WORKSPACE" -name "*.md" -exec basename {} \; | while read file; do
        kubectl cp "$NAMESPACE/$pod_name:$REMOTE_WORKSPACE/$file" "$LOCAL_WORKSPACE/$file" -c observable 2>/dev/null || true
    done
    
    log_success "Workspace ready at: $LOCAL_WORKSPACE"
}

# List markdown files
list_markdown_files() {
    ensure_telepresence_connection
    
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=observable -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "No Observable pod found"
        exit 1
    fi
    
    log_info "Markdown files in Observable container:"
    echo
    kubectl exec "$pod_name" -n "$NAMESPACE" -c observable -- find "$REMOTE_WORKSPACE" -name "*.md" -type f | sort
    echo
    
    # Also show local files if workspace exists
    if [ -d "$LOCAL_WORKSPACE" ]; then
        log_info "Local workspace files:"
        find "$LOCAL_WORKSPACE" -name "*.md" -type f 2>/dev/null | sort || echo "  (no markdown files found locally)"
    fi
}

# Edit a specific markdown file
edit_markdown_file() {
    local filename="$1"
    
    if [ -z "$filename" ]; then
        log_error "Please specify a filename to edit"
        log_info "Usage: $0 edit <filename.md>"
        exit 1
    fi
    
    # Add .md extension if not present
    if [[ ! "$filename" =~ \.md$ ]]; then
        filename="${filename}.md"
    fi
    
    ensure_telepresence_connection
    setup_workspace
    
    local local_file="$LOCAL_WORKSPACE/$filename"
    
    # Download file if it doesn't exist locally
    if [ ! -f "$local_file" ]; then
        log_info "File not found locally, downloading from container..."
        
        local pod_name
        pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=observable -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        
        kubectl cp "$NAMESPACE/$pod_name:$REMOTE_WORKSPACE/$filename" "$local_file" -c observable 2>/dev/null || {
            log_warn "File doesn't exist in container, creating new file"
            touch "$local_file"
        }
    fi
    
    log_info "Opening '$filename' for editing..."
    log_info "File location: $local_file"
    
    # Use EDITOR environment variable if set, otherwise auto-detect
    if [ -n "$EDITOR" ]; then
        log_info "Using editor from EDITOR variable: $EDITOR"
        $EDITOR "$local_file"
    elif command -v code &> /dev/null; then
        log_info "Opening in VS Code..."
        code "$local_file"
    elif command -v nano &> /dev/null; then
        log_info "Opening in nano (use Ctrl+X to save and exit)..."
        nano "$local_file"
    elif command -v vim &> /dev/null; then
        log_info "Opening in vim..."
        vim "$local_file"
    else
        log_error "No suitable editor found (tried: \$EDITOR, code, nano, vim)"
        log_info "Set the EDITOR environment variable to specify your preferred editor"
        exit 1
    fi
    
    # After editing, offer to sync back
    echo
    read -p "Sync changes back to container? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sync_file_to_container "$filename"
    else
        log_info "File saved locally. Use '$0 sync-file $filename' to sync later"
    fi
}

# Create new markdown file from template
create_new_markdown() {
    local filename="$1"
    
    if [ -z "$filename" ]; then
        log_error "Please specify a filename for the new markdown file"
        log_info "Usage: $0 new <filename>"
        exit 1
    fi
    
    # Add .md extension if not present
    if [[ ! "$filename" =~ \.md$ ]]; then
        filename="${filename}.md"
    fi
    
    ensure_telepresence_connection
    setup_workspace
    
    local local_file="$LOCAL_WORKSPACE/$filename"
    
    if [ -f "$local_file" ]; then
        log_warn "File '$filename' already exists"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 0
        fi
    fi
    
    # Create template
    local title=$(basename "$filename" .md | sed 's/-/ /g' | sed 's/\b\w/\U&/g')
    
    cat > "$local_file" << EOF
# $title

## Overview

This is a new Observable Framework dashboard.

\`\`\`js
// Sample data loader
data = FileAttachment("data/sample.json").json()
\`\`\`

## Visualizations

\`\`\`js
// Sample chart
Plot.plot({
  title: "$title",
  marks: [
    Plot.barY(data, {x: "name", y: "value"})
  ]
})
\`\`\`

## Data Sources

Available endpoints:
- **Loki**: \${LOKI_ENDPOINT}/loki/api/v1/query_range
- **Quickwit**: \${QUICKWIT_ENDPOINT}/api/v1/default/search
- **Prometheus**: \${PROMETHEUS_ENDPOINT}/api/v1/query

## Next Steps

1. Edit this markdown file to add your content
2. Add data files to the \`data/\` directory
3. Create visualizations with Observable Plot
4. Use the sync command to update the container

EOF
    
    log_success "Created new markdown file: $local_file"
    
    # Open for editing
    edit_markdown_file "$filename"
}

# Sync a specific file to container
sync_file_to_container() {
    local filename="$1"
    
    if [ -z "$filename" ]; then
        log_error "Please specify a filename to sync"
        exit 1
    fi
    
    ensure_telepresence_connection
    
    local local_file="$LOCAL_WORKSPACE/$filename"
    
    if [ ! -f "$local_file" ]; then
        log_error "Local file not found: $local_file"
        exit 1
    fi
    
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=observable -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "No Observable pod found"
        exit 1
    fi
    
    log_info "Syncing '$filename' to container..."
    kubectl cp "$local_file" "$NAMESPACE/$pod_name:$REMOTE_WORKSPACE/$filename" -c observable
    
    log_success "File synced to container: $filename"
    log_info "Observable Framework will reload automatically"
}

# Sync all local files to container
sync_all_to_container() {
    ensure_telepresence_connection
    
    if [ ! -d "$LOCAL_WORKSPACE" ]; then
        log_error "Local workspace not found. Run 'quick-start' first."
        exit 1
    fi
    
    local pod_name
    pod_name=$(kubectl get pods -n "$NAMESPACE" -l app=observable -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -z "$pod_name" ]; then
        log_error "No Observable pod found"
        exit 1
    fi
    
    log_info "Syncing all markdown files to container..."
    
    find "$LOCAL_WORKSPACE" -name "*.md" -type f | while read local_file; do
        local filename=$(basename "$local_file")
        log_info "  Syncing: $filename"
        kubectl cp "$local_file" "$NAMESPACE/$pod_name:$REMOTE_WORKSPACE/$filename" -c observable
    done
    
    log_success "All files synced to container"
}

# Quick start workflow
quick_start() {
    log_info "Starting quick markdown editing workflow..."
    
    check_prerequisites
    ensure_telepresence_connection
    setup_workspace
    
    echo
    log_success "Ready for markdown editing!"
    log_info "Local workspace: $LOCAL_WORKSPACE"
    log_info "Available commands:"
    echo "  $0 list              # List all markdown files"
    echo "  $0 edit <file>       # Edit a specific file"
    echo "  $0 new <name>        # Create new file"
    echo "  $0 sync-all          # Sync all changes to container"
    echo
    log_info "Observable Framework available at: http://observable.observable.svc.cluster.local:3000"
    
    # Show current files
    list_markdown_files
    
    # Offer to edit index.md
    echo
    read -p "Edit index.md now? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        edit_markdown_file "index.md"
    fi
}

# Show help
show_help() {
    echo "Telepresence Markdown Editor for Observable Framework"
    echo
    echo "Usage: $0 <command> [args...]"
    echo
    echo "Commands:"
    echo "  quick-start              Setup workspace and start editing"
    echo "  list                     List all markdown files"
    echo "  edit <filename>          Edit a specific markdown file"
    echo "  new <filename>           Create new markdown file from template"
    echo "  sync-file <filename>     Sync specific file to container"
    echo "  sync-all                 Sync all local files to container"
    echo "  help                     Show this help"
    echo
    echo "Examples:"
    echo "  $0 quick-start           # Complete setup and editing workflow"
    echo "  $0 edit index.md         # Edit the main dashboard"
    echo "  $0 new security          # Create security.md from template"
    echo "  $0 list                  # Show all available markdown files"
    echo
    echo "Workflow:"
    echo "  1. Run 'quick-start' to setup everything"
    echo "  2. Edit files locally in: $LOCAL_WORKSPACE"
    echo "  3. Changes auto-sync or use 'sync-all' command"
    echo "  4. View results in Observable Framework"
    echo
    echo "Prerequisites:"
    echo "  - Telepresence installed"
    echo "  - kubectl configured for cluster access"
    echo "  - Observable pod running in '$NAMESPACE' namespace"
    echo
    echo "Editor Selection:"
    echo "  - Set EDITOR environment variable for custom editor (e.g., export EDITOR=vim)"
    echo "  - Auto-detects: VS Code > nano > vim (if EDITOR not set)"
    echo "  - Examples: export EDITOR=emacs, export EDITOR='code --wait'"
}

# Main function
main() {
    local command="${1:-help}"
    
    case "$command" in
        "quick-start"|"start")
            quick_start
            ;;
        "list"|"ls")
            list_markdown_files
            ;;
        "edit")
            edit_markdown_file "$2"
            ;;
        "new"|"create")
            create_new_markdown "$2"
            ;;
        "sync-file"|"sync")
            sync_file_to_container "$2"
            ;;
        "sync-all")
            sync_all_to_container
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