#!/bin/bash
#
# Backup Script с ротацией
# Создаёт резервные копии директорий с автоматической ротацией старых бекапов
#
# Использование: ./backup-script.sh [options]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Default values
BACKUP_SOURCE="${BACKUP_SOURCE:-/var/www}"
BACKUP_DEST="${BACKUP_DEST:-/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESS="${COMPRESS:-1}"
LOG_FILE="${LOG_FILE:-/var/log/backup.log}"
DRY_RUN=0
VERBOSE=0

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
    if [ $VERBOSE -eq 1 ]; then
        log "[INFO] $*"
    fi
}

# Display usage
usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Create backups with automatic rotation.

Options:
    -h, --help              Show this help message
    -s, --source DIR        Source directory (default: $BACKUP_SOURCE)
    -d, --dest DIR          Destination directory (default: $BACKUP_DEST)
    -r, --retention DAYS    Keep backups for N days (default: $RETENTION_DAYS)
    -n, --dry-run           Dry run mode (don't create backups)
    -v, --verbose           Verbose output
    --no-compress           Don't compress backup

Examples:
    $SCRIPT_NAME --source /var/www --dest /backups
    $SCRIPT_NAME -v -r 30 --source /home
    $SCRIPT_NAME --dry-run

EOF
    exit 0
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check required commands
    for cmd in tar gzip find; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command '$cmd' not found"
            exit 1
        fi
    done

    # Check source exists
    if [ ! -d "$BACKUP_SOURCE" ]; then
        log_error "Source directory does not exist: $BACKUP_SOURCE"
        exit 1
    fi

    # Check destination exists or create it
    if [ ! -d "$BACKUP_DEST" ]; then
        log_info "Creating destination directory: $BACKUP_DEST"
        if [ $DRY_RUN -eq 0 ]; then
            mkdir -p "$BACKUP_DEST"
        fi
    fi

    # Check disk space
    local source_size=$(du -sb "$BACKUP_SOURCE" | awk '{print $1}')
    local dest_available=$(df -B1 "$BACKUP_DEST" | awk 'NR==2 {print $4}')

    log_info "Source size: $((source_size / 1024 / 1024)) MB"
    log_info "Available space: $((dest_available / 1024 / 1024)) MB"

    if [ "$dest_available" -lt "$source_size" ]; then
        log_error "Not enough disk space at destination"
        exit 1
    fi
}

# Create backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="backup_${timestamp}"
    local backup_path=""

    if [ $COMPRESS -eq 1 ]; then
        backup_path="${BACKUP_DEST}/${backup_name}.tar.gz"
    else
        backup_path="${BACKUP_DEST}/${backup_name}.tar"
    fi

    log "Creating backup: $backup_path"

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would create: $backup_path"
        return 0
    fi

    # Create backup
    if [ $COMPRESS -eq 1 ]; then
        tar -czf "$backup_path" -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>&1 | tee -a "$LOG_FILE"
    else
        tar -cf "$backup_path" -C "$(dirname "$BACKUP_SOURCE")" "$(basename "$BACKUP_SOURCE")" 2>&1 | tee -a "$LOG_FILE"
    fi

    if [ $? -eq 0 ]; then
        local backup_size=$(du -h "$backup_path" | awk '{print $1}')
        log "Backup created successfully: $backup_path ($backup_size)"
    else
        log_error "Backup failed"
        exit 1
    fi
}

# Rotate old backups
rotate_backups() {
    log "Rotating backups older than $RETENTION_DAYS days..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would delete backups older than $RETENTION_DAYS days"
        find "$BACKUP_DEST" -name "backup_*.tar*" -type f -mtime +$RETENTION_DAYS | while read file; do
            log "[DRY RUN] Would delete: $file"
        done
        return 0
    fi

    local deleted=0
    find "$BACKUP_DEST" -name "backup_*.tar*" -type f -mtime +$RETENTION_DAYS | while read file; do
        log_info "Deleting old backup: $file"
        rm -f "$file"
        ((deleted++))
    done

    log "Deleted $deleted old backup(s)"
}

# List existing backups
list_backups() {
    log "Existing backups in $BACKUP_DEST:"

    if [ ! -d "$BACKUP_DEST" ]; then
        log "No backups found"
        return
    fi

    local count=0
    find "$BACKUP_DEST" -name "backup_*.tar*" -type f -printf "%T@ %p %s\n" | sort -rn | while read timestamp file size; do
        local date=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
        local human_size=$(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "$size bytes")
        log "  $date - $(basename "$file") - $human_size"
        ((count++))
    done

    log "Total: $count backup(s)"
}

# Verify backup
verify_backup() {
    local backup_file="${1:-}"

    if [ -z "$backup_file" ]; then
        log_error "No backup file specified for verification"
        return 1
    fi

    if [ ! -f "$backup_file" ]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi

    log "Verifying backup: $backup_file"

    if [[ "$backup_file" == *.tar.gz ]]; then
        if tar -tzf "$backup_file" > /dev/null 2>&1; then
            log "Backup verification passed"
            return 0
        else
            log_error "Backup verification failed"
            return 1
        fi
    elif [[ "$backup_file" == *.tar ]]; then
        if tar -tf "$backup_file" > /dev/null 2>&1; then
            log "Backup verification passed"
            return 0
        else
            log_error "Backup verification failed"
            return 1
        fi
    fi
}

# Send notification
send_notification() {
    local status="${1:-success}"
    local message="${2:-Backup completed}"

    # Email notification (if mail is available)
    if command -v mail &> /dev/null && [ -n "${NOTIFICATION_EMAIL:-}" ]; then
        echo "$message" | mail -s "Backup Status: $status" "$NOTIFICATION_EMAIL"
    fi

    # Slack notification (if webhook is configured)
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Backup $status: $message\"}" \
            "$SLACK_WEBHOOK" &> /dev/null || true
    fi
}

# Cleanup on exit
cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Script failed with exit code: $exit_code"
        send_notification "failed" "Backup script failed"
    else
        log "Backup script completed successfully"
        send_notification "success" "Backup completed successfully"
    fi

    exit $exit_code
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                ;;
            -s|--source)
                BACKUP_SOURCE="$2"
                shift 2
                ;;
            -d|--dest)
                BACKUP_DEST="$2"
                shift 2
                ;;
            -r|--retention)
                RETENTION_DAYS="$2"
                shift 2
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            --no-compress)
                COMPRESS=0
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Start
    log "========================================="
    log "Backup Script Started"
    log "========================================="
    log "Source: $BACKUP_SOURCE"
    log "Destination: $BACKUP_DEST"
    log "Retention: $RETENTION_DAYS days"
    log "Compress: $COMPRESS"
    [ $DRY_RUN -eq 1 ] && log "Mode: DRY RUN"

    # Execute
    check_prerequisites
    create_backup
    rotate_backups
    list_backups

    log "========================================="
    log "Backup Script Finished"
    log "========================================="
}

# Set trap for cleanup
trap cleanup EXIT INT TERM

# Run main function
main "$@"
