#!/bin/bash

#
# Build script for D2 diagrams
# Generates PNG and SVG versions of all D2 diagrams in this directory
#

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Error log file
ERROR_LOG="error.log"

# Initialize error log
init_error_log() {
    > "$ERROR_LOG"
    echo "D2 Build Error Log - $(date)" >> "$ERROR_LOG"
    echo "================================" >> "$ERROR_LOG"
    echo >> "$ERROR_LOG"
}

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "[ERROR] $1" >> "$ERROR_LOG"
}

# Check if D2 is installed
check_d2() {
    if ! command -v d2 &> /dev/null; then
        log_error "D2 is not installed"
        echo
        echo "Installation instructions:"
        echo "  macOS:  brew install d2"
        echo "  Linux:  curl -fsSL https://d2lang.com/install.sh | sh -s --"
        echo "  Other:  https://d2lang.com/tour/install"
        exit 1
    fi
    
    log_success "D2 is installed: $(d2 --version)"
}

# Create output directory
create_output_dir() {
    if [ ! -d "output" ]; then
        mkdir -p output
        log_info "Created output directory"
    fi
}

# Build a single diagram
build_diagram() {
    local input_file="$1"
    local base_name=$(basename "$input_file" .d2)
    local temp_error_file=$(mktemp)
    
    log_info "Building $input_file..."
    echo >> "$ERROR_LOG"
    echo "Processing: $input_file" >> "$ERROR_LOG"
    echo "------------------------" >> "$ERROR_LOG"
    
    # Generate PNG
    if d2 "$input_file" "output/${base_name}.png" 2>"$temp_error_file"; then
        log_success "Generated output/${base_name}.png"
    else
        log_error "Failed to generate PNG for $input_file"
        echo "PNG Generation Error:" >> "$ERROR_LOG"
        cat "$temp_error_file" >> "$ERROR_LOG"
        echo >> "$ERROR_LOG"
    fi
    
    # Generate SVG
    if d2 "$input_file" "output/${base_name}.svg" 2>"$temp_error_file"; then
        log_success "Generated output/${base_name}.svg"
    else
        log_error "Failed to generate SVG for $input_file"
        echo "SVG Generation Error:" >> "$ERROR_LOG"
        cat "$temp_error_file" >> "$ERROR_LOG"
        echo >> "$ERROR_LOG"
    fi
    
    # Generate GIF for animated diagrams
    if [[ "$base_name" == *"animated"* ]]; then
        if d2 "$input_file" "output/${base_name}.gif" --animate-interval=1000 2>"$temp_error_file"; then
            log_success "Generated output/${base_name}.gif"
        else
            log_error "Failed to generate GIF for $input_file"
            echo "GIF Generation Error:" >> "$ERROR_LOG"
            cat "$temp_error_file" >> "$ERROR_LOG"
            echo >> "$ERROR_LOG"
        fi
    fi
    
    rm -f "$temp_error_file"
    echo
}

# Main script
main() {
    echo "D2 Diagram Build Script"
    echo "======================"
    echo
    
    # Initialize error log
    init_error_log
    
    # Check prerequisites
    check_d2
    create_output_dir
    
    # Find all D2 files
    log_info "Finding D2 files..."
    d2_files=(*.d2)
    
    if [ ${#d2_files[@]} -eq 0 ] || [ ! -f "${d2_files[0]}" ]; then
        log_error "No D2 files found in current directory"
        exit 1
    fi
    
    log_info "Found ${#d2_files[@]} D2 file(s)"
    echo
    
    # Build each diagram
    for d2_file in "${d2_files[@]}"; do
        build_diagram "$d2_file"
    done
    
    # Summary
    echo "Build Summary"
    echo "============="
    
    # Check if there were any errors
    if grep -q "\[ERROR\]" "$ERROR_LOG" 2>/dev/null; then
        log_error "Some diagrams failed to build. Check error.log for details."
        echo
        echo "Error summary from error.log:"
        echo "----------------------------"
        grep "Failed to generate" "$ERROR_LOG" | sort | uniq
        echo
        echo "For detailed error messages, see: $ERROR_LOG"
    else
        log_success "All diagrams built successfully!"
        echo "No errors encountered."
    fi
    
    echo
    echo "Output files:"
    ls -la output/ 2>/dev/null || echo "  (no output files generated)"
    echo
    echo "To view the diagrams:"
    echo "  open output/*.png    # macOS"
    echo "  xdg-open output/*.png # Linux"
}

# Run main function
main "$@"