#!/bin/bash

#
# Quick YAML Lint Fixer
# Fixes common YAML lint issues based on GitHub Actions failures
#

set -e

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

# Function to fix a single YAML file
fix_yaml_file() {
    local file="$1"
    local backup="${file}.backup"
    
    if [ ! -f "$file" ]; then
        log_error "File not found: $file"
        return 1
    fi
    
    log_info "Fixing: $file"
    
    # Create backup
    cp "$file" "$backup"
    
    # Fix trailing spaces
    sed -i '' 's/[[:space:]]*$//' "$file"
    
    # Ensure file ends with newline
    if [ -n "$(tail -c1 "$file")" ]; then
        echo >> "$file"
    fi
    
    # Check if changes were made
    if ! cmp -s "$file" "$backup"; then
        log_success "  Fixed trailing spaces and newlines"
    else
        log_info "  No changes needed"
    fi
    
    # Remove backup
    rm "$backup"
}

# Fix indentation issues in specific problematic files
fix_indentation() {
    log_info "Fixing known indentation issues..."
    
    # These files have specific indentation problems identified in the logs
    local files_to_fix=(
        "apps/loki/loki-deployment.yaml"
        "apps/otel/otel-ingress.yaml"
        "apps/otel/otel-service.yaml"
        "apps/otel/otel-deployment.yaml"
        "apps/grafana/grafana-ingress.yaml"
        "apps/quickwit/quickwit-deployment.yaml"
        "apps/quickwit/quickwit-ingress.yaml"
        "apps/quickwit/quickwit-data-cleanup-job.yaml"
        "apps/quickwit/quickwit-service.yaml"
        "apps/quickwit/storage-cleanup-cronjob.yaml"
    )
    
    for file in "${files_to_fix[@]}"; do
        if [ -f "$file" ]; then
            log_warn "Manual review needed for indentation: $file"
        fi
    done
}

# Main execution
main() {
    echo "YAML Lint Fixer"
    echo "==============="
    echo
    
    log_info "Finding YAML files in apps/ directory..."
    
    # Find all YAML files
    find apps/ -name "*.yaml" -o -name "*.yml" | while read -r file; do
        fix_yaml_file "$file"
    done
    
    echo
    fix_indentation
    
    echo
    log_success "Basic YAML fixes completed!"
    log_warn "Note: Some indentation issues may require manual review"
    echo
    echo "To test the fixes:"
    echo "  yamllint -c .yamllint.yml apps/"
}

main "$@"