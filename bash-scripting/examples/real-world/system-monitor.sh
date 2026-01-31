#!/bin/bash
#
# System Monitoring Script
# Мониторинг ресурсов системы с алертами
#
# Использование: ./system-monitor.sh [options]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Thresholds
CPU_THRESHOLD="${CPU_THRESHOLD:-80}"
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-85}"
DISK_THRESHOLD="${DISK_THRESHOLD:-90}"
LOAD_THRESHOLD="${LOAD_THRESHOLD:-4.0}"

# Monitoring
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"  # seconds
LOG_FILE="${LOG_FILE:-/var/log/system-monitor.log}"

# Flags
VERBOSE=0
CONTINUOUS=0
SEND_ALERTS=1

# ============================================================================
# Functions
# ============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S')${NC} $*" | tee -a "$LOG_FILE" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $(date '+%Y-%m-%d %H:%M:%S')${NC} $*" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[OK] $(date '+%Y-%m-%d %H:%M:%S')${NC} $*" | tee -a "$LOG_FILE"
}

log_info() {
    if [ $VERBOSE -eq 1 ]; then
        echo "[INFO] $*" | tee -a "$LOG_FILE"
    fi
}

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Monitor system resources and send alerts.

Options:
    -h, --help                  Show this help
    -c, --continuous            Run continuously
    -i, --interval SECONDS      Check interval (default: $CHECK_INTERVAL)
    -v, --verbose               Verbose output
    --no-alerts                 Don't send alerts

Thresholds:
    --cpu PERCENT               CPU threshold (default: $CPU_THRESHOLD%)
    --memory PERCENT            Memory threshold (default: $MEMORY_THRESHOLD%)
    --disk PERCENT              Disk threshold (default: $DISK_THRESHOLD%)
    --load NUMBER               Load average threshold (default: $LOAD_THRESHOLD)

Examples:
    $SCRIPT_NAME                            # Single check
    $SCRIPT_NAME -c -i 30                   # Continuous, every 30s
    $SCRIPT_NAME --cpu 90 --memory 95       # Custom thresholds

EOF
    exit 0
}

# Check CPU usage
check_cpu() {
    log_info "Checking CPU usage..."

    # Get CPU usage (excluding idle)
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_usage=$(printf "%.0f" "$cpu_usage")

    echo "cpu_usage=$cpu_usage"

    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        log_warning "High CPU usage: ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"

        # Get top CPU processes
        log_info "Top CPU processes:"
        ps aux --sort=-%cpu | head -6 | tee -a "$LOG_FILE"

        return 1
    else
        log_success "CPU usage: ${cpu_usage}%"
        return 0
    fi
}

# Check memory usage
check_memory() {
    log_info "Checking memory usage..."

    local memory_info=$(free | grep Mem)
    local total=$(echo "$memory_info" | awk '{print $2}')
    local used=$(echo "$memory_info" | awk '{print $3}')
    local memory_usage=$((used * 100 / total))

    echo "memory_usage=$memory_usage"
    echo "memory_total=$total"
    echo "memory_used=$used"

    if [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
        log_warning "High memory usage: ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"

        # Get top memory processes
        log_info "Top memory processes:"
        ps aux --sort=-%mem | head -6 | tee -a "$LOG_FILE"

        return 1
    else
        log_success "Memory usage: ${memory_usage}%"
        return 0
    fi
}

# Check disk usage
check_disk() {
    log_info "Checking disk usage..."

    local alert=0

    while read filesystem size used avail percent mountpoint; do
        # Skip header and special filesystems
        [[ "$filesystem" == "Filesystem" ]] && continue
        [[ "$filesystem" == tmpfs* ]] && continue
        [[ "$filesystem" == devtmpfs* ]] && continue

        local usage=${percent%\%}

        if [ "$usage" -gt "$DISK_THRESHOLD" ]; then
            log_warning "High disk usage on $mountpoint: ${usage}% (threshold: ${DISK_THRESHOLD}%)"
            alert=1
        else
            log_success "Disk usage on $mountpoint: ${usage}%"
        fi
    done < <(df -h | grep -vE '^(tmpfs|devtmpfs)')

    return $alert
}

# Check system load
check_load() {
    log_info "Checking system load..."

    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)
    local cpu_count=$(nproc)
    local load_per_cpu=$(echo "scale=2; $load_avg / $cpu_count" | bc)

    echo "load_avg=$load_avg"
    echo "cpu_count=$cpu_count"
    echo "load_per_cpu=$load_per_cpu"

    # Compare using bc for float comparison
    if (( $(echo "$load_avg > $LOAD_THRESHOLD" | bc -l) )); then
        log_warning "High load average: $load_avg (threshold: $LOAD_THRESHOLD, CPUs: $cpu_count)"
        return 1
    else
        log_success "Load average: $load_avg (CPUs: $cpu_count)"
        return 0
    fi
}

# Check disk I/O
check_disk_io() {
    log_info "Checking disk I/O..."

    if command -v iostat &> /dev/null; then
        iostat -x 1 2 | tail -n +4 | head -10 | tee -a "$LOG_FILE"
    else
        log_info "iostat not available"
    fi
}

# Check network
check_network() {
    log_info "Checking network..."

    # Check network interfaces
    if command -v ifconfig &> /dev/null; then
        ifconfig | grep -E "^[a-z]|inet " | tee -a "$LOG_FILE"
    elif command -v ip &> /dev/null; then
        ip addr show | grep -E "^[0-9]|inet " | tee -a "$LOG_FILE"
    fi

    # Check connectivity
    if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        log_success "Network connectivity: OK"
    else
        log_error "Network connectivity: FAILED"
    fi
}

# Check running services
check_services() {
    log_info "Checking critical services..."

    local services=(
        "sshd"
        "nginx"
        "docker"
        "mysql"
    )

    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log_success "Service $service: running"
        else
            log_info "Service $service: not running (may not be installed)"
        fi
    done
}

# Check failed login attempts
check_security() {
    log_info "Checking security..."

    if [ -f /var/log/auth.log ]; then
        local failed_attempts=$(grep "Failed password" /var/log/auth.log | tail -20 | wc -l)

        if [ "$failed_attempts" -gt 10 ]; then
            log_warning "High number of failed login attempts: $failed_attempts"

            # Show recent failures
            log_info "Recent failed attempts:"
            grep "Failed password" /var/log/auth.log | tail -5 | tee -a "$LOG_FILE"
        fi
    fi
}

# Generate report
generate_report() {
    local report_file="/tmp/system-report-$(date +%Y%m%d_%H%M%S).txt"

    {
        echo "=========================================="
        echo "System Monitor Report"
        echo "=========================================="
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime -p)"
        echo ""

        echo "RESOURCE USAGE"
        echo "--------------"
        check_cpu | grep "cpu_usage=" | cut -d= -f2 | xargs echo "CPU:"
        check_memory | grep "memory_usage=" | cut -d= -f2 | xargs echo "Memory:"
        check_load | grep "load_avg=" | cut -d= -f2 | xargs echo "Load:"
        echo ""

        echo "DISK USAGE"
        echo "----------"
        df -h | grep -vE '^(tmpfs|devtmpfs)'
        echo ""

        echo "TOP PROCESSES BY CPU"
        echo "--------------------"
        ps aux --sort=-%cpu | head -6
        echo ""

        echo "TOP PROCESSES BY MEMORY"
        echo "-----------------------"
        ps aux --sort=-%mem | head -6
        echo ""

        echo "=========================================="
    } > "$report_file"

    echo "$report_file"
}

# Send alert
send_alert() {
    local message="$1"

    if [ $SEND_ALERTS -eq 0 ]; then
        return 0
    fi

    # Email alert
    if command -v mail &> /dev/null && [ -n "${ALERT_EMAIL:-}" ]; then
        echo "$message" | mail -s "System Alert: $(hostname)" "$ALERT_EMAIL"
    fi

    # Slack alert
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 System Alert ($(hostname))\\n$message\"}" \
            "$SLACK_WEBHOOK" &> /dev/null || true
    fi

    # Telegram alert
    if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${TELEGRAM_CHAT_ID:-}" ]; then
        curl -s -X POST \
            "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
            -d chat_id="${TELEGRAM_CHAT_ID}" \
            -d text="🚨 System Alert ($(hostname)): $message" &> /dev/null || true
    fi
}

# Perform full check
perform_check() {
    log "=========================================="
    log "System Check Started"
    log "=========================================="

    local alerts=()

    # Check all metrics
    if ! check_cpu; then
        alerts+=("High CPU usage")
    fi

    if ! check_memory; then
        alerts+=("High memory usage")
    fi

    if ! check_disk; then
        alerts+=("High disk usage")
    fi

    if ! check_load; then
        alerts+=("High system load")
    fi

    check_network
    check_services
    check_security

    # Send alerts if any
    if [ ${#alerts[@]} -gt 0 ]; then
        local alert_message="System alerts detected:\n"
        for alert in "${alerts[@]}"; do
            alert_message+="- $alert\n"
        done
        send_alert "$alert_message"
    fi

    log "=========================================="
    log "System Check Completed"
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
            --load) LOAD_THRESHOLD="$2"; shift 2 ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Create log directory if needed
    mkdir -p "$(dirname "$LOG_FILE")"

    if [ $CONTINUOUS -eq 1 ]; then
        log "Starting continuous monitoring (interval: ${CHECK_INTERVAL}s)"
        log "Press Ctrl+C to stop"

        while true; do
            perform_check
            sleep "$CHECK_INTERVAL"
        done
    else
        perform_check
    fi
}

# Trap Ctrl+C
trap 'log "Monitoring stopped"; exit 0' INT TERM

main "$@"
