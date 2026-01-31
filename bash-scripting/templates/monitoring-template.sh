#!/bin/bash
#
# Monitoring Template Script
# Template for system/application monitoring
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Monitoring settings
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"
LOG_FILE="${LOG_FILE:-/var/log/monitor.log}"

# Thresholds
CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-85}"
DISK_THRESHOLD="${DISK_THRESHOLD:-90}"

# Alert settings
ALERT_EMAIL="${ALERT_EMAIL:-}"
SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"

# Flags
VERBOSE=0
CONTINUOUS=0
SEND_ALERTS=1

# ============================================================================
# Functions
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $*" | tee -a "$LOG_FILE" >&2
}

log_info() {
    [ $VERBOSE -eq 1 ] && echo "[INFO] $*" | tee -a "$LOG_FILE"
}

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Monitor system resources and send alerts.

Options:
    -h, --help              Show help
    -c, --continuous        Run continuously
    -i, --interval SEC      Check interval (default: $CHECK_INTERVAL)
    -v, --verbose           Verbose output
    --no-alerts             Don't send alerts
    --cpu NUM               CPU threshold
    --memory NUM            Memory threshold
    --disk NUM              Disk threshold

EOF
    exit 0
}

# Check CPU usage
check_cpu() {
    log_info "Checking CPU usage..."

    # TODO: Implement CPU check
    # Example:
    # local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
    #
    # if [ ${cpu_usage%.*} -gt $CPU_THRESHOLD ]; then
    #     send_alert "High CPU usage: $cpu_usage%"
    #     return 1
    # fi

    log "✓ CPU OK"
    return 0
}

# Check memory usage
check_memory() {
    log_info "Checking memory usage..."

    # TODO: Implement memory check
    # Example:
    # local mem_info=$(free | grep Mem)
    # local total=$(echo "$mem_info" | awk '{print $2}')
    # local used=$(echo "$mem_info" | awk '{print $3}')
    # local usage=$((used * 100 / total))
    #
    # if [ $usage -gt $MEMORY_THRESHOLD ]; then
    #     send_alert "High memory usage: $usage%"
    #     return 1
    # fi

    log "✓ Memory OK"
    return 0
}

# Check disk usage
check_disk() {
    log_info "Checking disk usage..."

    # TODO: Implement disk check
    # Example:
    # local usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    #
    # if [ $usage -gt $DISK_THRESHOLD ]; then
    #     send_alert "High disk usage: $usage%"
    #     return 1
    # fi

    log "✓ Disk OK"
    return 0
}

# Check application/service
check_service() {
    log_info "Checking service..."

    # TODO: Implement service check
    # Examples:
    # - HTTP endpoint check
    # - Process check
    # - Port check
    # - Database connection

    log "✓ Service OK"
    return 0
}

# Custom checks
custom_checks() {
    log_info "Running custom checks..."

    # TODO: Add your custom monitoring logic
    # Examples:
    # - API response time
    # - Queue size
    # - Error rate
    # - Business metrics

    log "✓ Custom checks OK"
    return 0
}

# Send alert
send_alert() {
    local message="$1"

    if [ $SEND_ALERTS -eq 0 ]; then
        return 0
    fi

    log_error "ALERT: $message"

    # Email alert
    if [ -n "$ALERT_EMAIL" ] && command -v mail &> /dev/null; then
        echo "$message" | mail -s "Monitoring Alert" "$ALERT_EMAIL"
    fi

    # Slack alert
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 Alert: $message\"}" \
            "$SLACK_WEBHOOK" &> /dev/null || true
    fi

    # TODO: Add more alert methods
    # - PagerDuty
    # - Telegram
    # - SMS
    # - Custom webhook
}

# Perform all checks
perform_checks() {
    log "=========================================="
    log "Starting checks"
    log "=========================================="

    local failed=0

    check_cpu || ((failed++))
    check_memory || ((failed++))
    check_disk || ((failed++))
    check_service || ((failed++))
    custom_checks || ((failed++))

    if [ $failed -gt 0 ]; then
        log_error "Failed checks: $failed"
    else
        log "All checks passed"
    fi

    log "=========================================="
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage ;;
            -c|--continuous) CONTINUOUS=1; shift ;;
            -i|--interval) CHECK_INTERVAL="$2"; shift 2 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            --no-alerts) SEND_ALERTS=0; shift ;;
            --cpu) CPU_THRESHOLD="$2"; shift 2 ;;
            --memory) MEMORY_THRESHOLD="$2"; shift 2 ;;
            --disk) DISK_THRESHOLD="$2"; shift 2 ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    if [ $CONTINUOUS -eq 1 ]; then
        log "Starting continuous monitoring (interval: ${CHECK_INTERVAL}s)"

        while true; do
            perform_checks
            sleep "$CHECK_INTERVAL"
        done
    else
        perform_checks
    fi
}

# Trap signals
trap 'log "Monitoring stopped"; exit 0' INT TERM

main "$@"
