#!/bin/bash
#
# Log Analyzer Script
# Анализ логов с генерацией отчётов и алертами
#
# Использование: ./log-analyzer.sh [options] <log-file>
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Default values
LOG_FILE=""
OUTPUT_DIR="/tmp/log-analysis"
REPORT_FORMAT="text"  # text, html, json
ERROR_THRESHOLD=10
TOP_ENTRIES=20

# Flags
VERBOSE=0
GENERATE_REPORT=1

# ============================================================================
# Functions
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_info() {
    if [ $VERBOSE -eq 1 ]; then
        echo "[INFO] $*"
    fi
}

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS] LOG_FILE

Analyze log files and generate reports.

Options:
    -h, --help              Show this help
    -o, --output DIR        Output directory (default: $OUTPUT_DIR)
    -f, --format FORMAT     Report format: text, html, json (default: $REPORT_FORMAT)
    -t, --threshold NUM     Error threshold for alerts (default: $ERROR_THRESHOLD)
    -n, --top NUM           Number of top entries to show (default: $TOP_ENTRIES)
    -v, --verbose           Verbose output
    --no-report             Don't generate report file

Examples:
    $SCRIPT_NAME /var/log/apache2/error.log
    $SCRIPT_NAME -f html -o ./reports /var/log/app.log
    $SCRIPT_NAME --threshold 50 --top 10 /var/log/syslog

EOF
    exit 0
}

# Validate log file
validate_log_file() {
    if [ -z "$LOG_FILE" ]; then
        log_error "Log file is required"
        usage
    fi

    if [ ! -f "$LOG_FILE" ]; then
        log_error "Log file not found: $LOG_FILE"
        exit 1
    fi

    if [ ! -r "$LOG_FILE" ]; then
        log_error "Log file not readable: $LOG_FILE"
        exit 1
    fi
}

# Analyze log statistics
analyze_statistics() {
    log "Analyzing log statistics..."

    # Total lines
    local total_lines=$(wc -l < "$LOG_FILE")
    echo "total_lines=$total_lines"

    # Error lines (case insensitive)
    local error_count=$(grep -i "error" "$LOG_FILE" | wc -l)
    echo "error_count=$error_count"

    # Warning lines
    local warning_count=$(grep -i "warning\|warn" "$LOG_FILE" | wc -l)
    echo "warning_count=$warning_count"

    # Critical/Fatal lines
    local critical_count=$(grep -i "critical\|fatal" "$LOG_FILE" | wc -l)
    echo "critical_count=$critical_count"

    # Date range
    local first_date=$(head -1 "$LOG_FILE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || echo "Unknown")
    local last_date=$(tail -1 "$LOG_FILE" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || echo "Unknown")
    echo "first_date=$first_date"
    echo "last_date=$last_date"

    # File size
    local file_size=$(du -h "$LOG_FILE" | awk '{print $1}')
    echo "file_size=$file_size"
}

# Find top errors
find_top_errors() {
    log "Finding top errors..."

    grep -i "error" "$LOG_FILE" | \
        sed 's/^.*error[: ]*/Error: /i' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -n "$TOP_ENTRIES"
}

# Find top IPs (if applicable)
find_top_ips() {
    log "Finding top IP addresses..."

    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "$LOG_FILE" | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -n "$TOP_ENTRIES"
}

# Find HTTP status codes (if applicable)
find_http_status() {
    log "Analyzing HTTP status codes..."

    grep -oE 'HTTP/[0-9.]+ [0-9]{3}' "$LOG_FILE" | \
        awk '{print $2}' | \
        sort | \
        uniq -c | \
        sort -rn
}

# Timeline analysis
analyze_timeline() {
    log "Analyzing timeline..."

    # Errors by hour
    grep -i "error" "$LOG_FILE" | \
        grep -oE '[0-9]{2}:[0-9]{2}:[0-9]{2}' | \
        awk -F: '{print $1":00"}' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -n 24
}

# Find suspicious patterns
find_suspicious_patterns() {
    log "Finding suspicious patterns..."

    local patterns=(
        "failed password"
        "authentication failure"
        "illegal user"
        "failed login"
        "connection refused"
        "timeout"
        "out of memory"
        "segmentation fault"
        "permission denied"
    )

    for pattern in "${patterns[@]}"; do
        local count=$(grep -i "$pattern" "$LOG_FILE" | wc -l)
        if [ $count -gt 0 ]; then
            echo "$count occurrences: $pattern"
        fi
    done
}

# Generate text report
generate_text_report() {
    local report_file="${OUTPUT_DIR}/report_$(date +%Y%m%d_%H%M%S).txt"

    log "Generating text report: $report_file"

    {
        echo "=========================================="
        echo "Log Analysis Report"
        echo "=========================================="
        echo "Generated: $(date)"
        echo "Log file: $LOG_FILE"
        echo ""

        echo "STATISTICS"
        echo "----------"
        analyze_statistics | while IFS='=' read key value; do
            printf "%-20s: %s\n" "$key" "$value"
        done
        echo ""

        echo "TOP $TOP_ENTRIES ERRORS"
        echo "-------------------"
        find_top_errors
        echo ""

        echo "TOP $TOP_ENTRIES IP ADDRESSES"
        echo "-------------------------"
        find_top_ips
        echo ""

        echo "HTTP STATUS CODES"
        echo "-----------------"
        find_http_status
        echo ""

        echo "ERRORS BY HOUR"
        echo "--------------"
        analyze_timeline
        echo ""

        echo "SUSPICIOUS PATTERNS"
        echo "-------------------"
        find_suspicious_patterns
        echo ""

        echo "=========================================="
    } > "$report_file"

    echo "$report_file"
}

# Generate HTML report
generate_html_report() {
    local report_file="${OUTPUT_DIR}/report_$(date +%Y%m%d_%H%M%S).html"

    log "Generating HTML report: $report_file"

    {
        cat <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Log Analysis Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; border-bottom: 2px solid #ccc; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .error { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .stat { font-size: 18px; padding: 10px; margin: 10px 0; background: #f9f9f9; }
        pre { background: #f4f4f4; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
EOF
        echo "<h1>Log Analysis Report</h1>"
        echo "<p><strong>Generated:</strong> $(date)</p>"
        echo "<p><strong>Log file:</strong> $LOG_FILE</p>"

        echo "<h2>Statistics</h2>"
        echo "<div class='stat'>"
        analyze_statistics | while IFS='=' read key value; do
            echo "<strong>$key:</strong> $value<br>"
        done
        echo "</div>"

        echo "<h2>Top $TOP_ENTRIES Errors</h2>"
        echo "<table><tr><th>Count</th><th>Error</th></tr>"
        find_top_errors | while read count error; do
            echo "<tr><td>$count</td><td class='error'>$error</td></tr>"
        done
        echo "</table>"

        echo "<h2>Top $TOP_ENTRIES IP Addresses</h2>"
        echo "<table><tr><th>Count</th><th>IP Address</th></tr>"
        find_top_ips | while read count ip; do
            echo "<tr><td>$count</td><td>$ip</td></tr>"
        done
        echo "</table>"

        echo "<h2>Errors by Hour</h2>"
        echo "<table><tr><th>Count</th><th>Hour</th></tr>"
        analyze_timeline | while read count hour; do
            echo "<tr><td>$count</td><td>$hour</td></tr>"
        done
        echo "</table>"

        cat <<'EOF'
</body>
</html>
EOF
    } > "$report_file"

    echo "$report_file"
}

# Generate JSON report
generate_json_report() {
    local report_file="${OUTPUT_DIR}/report_$(date +%Y%m%d_%H%M%S).json"

    log "Generating JSON report: $report_file"

    {
        echo "{"
        echo "  \"generated\": \"$(date -Iseconds)\","
        echo "  \"log_file\": \"$LOG_FILE\","

        echo "  \"statistics\": {"
        local stats=$(analyze_statistics)
        local first=1
        echo "$stats" | while IFS='=' read key value; do
            [ $first -eq 0 ] && echo "," || first=0
            echo -n "    \"$key\": \"$value\""
        done
        echo ""
        echo "  },"

        echo "  \"top_errors\": ["
        find_top_errors | while read count error; do
            echo "    {\"count\": $count, \"error\": \"${error//\"/\\\"}\"},"
        done | sed '$ s/,$//'
        echo "  ],"

        echo "  \"top_ips\": ["
        find_top_ips | while read count ip; do
            echo "    {\"count\": $count, \"ip\": \"$ip\"},"
        done | sed '$ s/,$//'
        echo "  ]"

        echo "}"
    } > "$report_file"

    echo "$report_file"
}

# Check for alerts
check_alerts() {
    log "Checking for alerts..."

    local stats=$(analyze_statistics)
    local error_count=$(echo "$stats" | grep "error_count=" | cut -d= -f2)

    if [ "$error_count" -gt "$ERROR_THRESHOLD" ]; then
        log_error "ALERT: Error count ($error_count) exceeds threshold ($ERROR_THRESHOLD)"

        # Send alert (example with email)
        if command -v mail &> /dev/null && [ -n "${ALERT_EMAIL:-}" ]; then
            echo "Error count in $LOG_FILE: $error_count (threshold: $ERROR_THRESHOLD)" | \
                mail -s "Log Alert: High Error Count" "$ALERT_EMAIL"
        fi

        return 1
    fi

    log "No alerts triggered"
    return 0
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage ;;
            -o|--output) OUTPUT_DIR="$2"; shift 2 ;;
            -f|--format) REPORT_FORMAT="$2"; shift 2 ;;
            -t|--threshold) ERROR_THRESHOLD="$2"; shift 2 ;;
            -n|--top) TOP_ENTRIES="$2"; shift 2 ;;
            -v|--verbose) VERBOSE=1; shift ;;
            --no-report) GENERATE_REPORT=0; shift ;;
            -*)
                log_error "Unknown option: $1"
                usage
                ;;
            *)
                LOG_FILE="$1"
                shift
                ;;
        esac
    done

    log "=========================================="
    log "Log Analysis Started"
    log "=========================================="

    # Validate
    validate_log_file

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Analyze
    log "Analyzing: $LOG_FILE"

    if [ $GENERATE_REPORT -eq 1 ]; then
        case $REPORT_FORMAT in
            text)
                report=$(generate_text_report)
                log "Report generated: $report"
                ;;
            html)
                report=$(generate_html_report)
                log "Report generated: $report"
                ;;
            json)
                report=$(generate_json_report)
                log "Report generated: $report"
                ;;
            *)
                log_error "Unknown format: $REPORT_FORMAT"
                exit 1
                ;;
        esac
    fi

    # Check alerts
    check_alerts || true

    log "=========================================="
    log "Analysis Completed"
    log "=========================================="
}

main "$@"
