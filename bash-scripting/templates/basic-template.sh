#!/bin/bash
#
# Script Name: [NAME]
# Description: [DESCRIPTION]
# Author: [AUTHOR]
# Date: [DATE]
# Version: 1.0
#
# Usage: ./script.sh [options] [arguments]
#

# Enable strict mode
set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Get script directory and name
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Default configuration
CONFIG_FILE="${CONFIG_FILE:-$HOME/.config/script.conf}"
LOG_FILE="${LOG_FILE:-/var/log/script.log}"
VERBOSE="${VERBOSE:-0}"
DRY_RUN="${DRY_RUN:-0}"

# ============================================================================
# Functions
# ============================================================================

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE" >&2
}

log_info() {
    if [ "$VERBOSE" -eq 1 ]; then
        echo "[INFO] $*" | tee -a "$LOG_FILE"
    fi
}

# Display usage information
usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] [ARGUMENTS]

[DESCRIPTION]

Options:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -n, --dry-run           Run in dry-run mode
    -c, --config FILE       Configuration file

Examples:
    $SCRIPT_NAME --verbose
    $SCRIPT_NAME --config custom.conf

EOF
    exit 0
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check for required commands
    local required_commands=("grep" "awk" "sed")
    local missing=0

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command not found: $cmd"
            ((missing++))
        fi
    done

    if [ $missing -gt 0 ]; then
        log_error "$missing required command(s) missing"
        exit 1
    fi

    log_info "✓ Prerequisites check passed"
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_info "Loading configuration from: $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        log_info "Configuration file not found, using defaults"
    fi
}

# Main processing function
process() {
    log "Starting processing..."

    if [ "$DRY_RUN" -eq 1 ]; then
        log "[DRY RUN] Would perform actions here"
        return 0
    fi

    # TODO: Add your main logic here

    log "Processing completed"
}

# Cleanup function (called on exit)
cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Script failed with exit code: $exit_code"
    else
        log "Script completed successfully"
    fi

    # TODO: Add cleanup tasks here
    # - Remove temporary files
    # - Close connections
    # - etc.

    exit $exit_code
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                # Positional argument
                POSITIONAL_ARGS+=("$1")
                shift
                ;;
        esac
    done

    # Start logging
    log "=========================================="
    log "Script started"
    log "=========================================="

    # Execute
    load_config
    check_prerequisites
    process

    log "=========================================="
    log "Script finished"
    log "=========================================="
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Run main function
main "$@"
