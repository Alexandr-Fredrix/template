#!/bin/bash
#
# PostgreSQL Backup Script
# Автоматическое резервное копирование PostgreSQL баз данных
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

# Database connection
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-postgres}"
DB_NAME="${DB_NAME:-postgres}"
PGPASSWORD="${PGPASSWORD:-}"

# Backup settings
BACKUP_DIR="${BACKUP_DIR:-/var/backups/postgresql}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
COMPRESS="${COMPRESS:-1}"

# Logging
LOG_FILE="${LOG_FILE:-/var/log/postgres-backup.log}"

# Flags
DRY_RUN=0
VERBOSE=0

# ============================================================================
# Functions
# ============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE" >&2
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Backup PostgreSQL database with rotation.

Options:
    -h, --help              Show help
    -H, --host HOST         Database host (default: $DB_HOST)
    -p, --port PORT         Database port (default: $DB_PORT)
    -U, --user USER         Database user (default: $DB_USER)
    -d, --database DB       Database name (default: $DB_NAME)
    -b, --backup-dir DIR    Backup directory (default: $BACKUP_DIR)
    -r, --retention DAYS    Retention days (default: $RETENTION_DAYS)
    -n, --dry-run           Dry run mode
    -v, --verbose           Verbose output
    --no-compress           Don't compress backup

Environment variables:
    PGPASSWORD              PostgreSQL password

Examples:
    $0 --database myapp
    $0 -H db.example.com -d myapp -r 30
    PGPASSWORD=secret $0 --database myapp

EOF
    exit 0
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    if ! command -v pg_dump &> /dev/null; then
        log_error "pg_dump not found. Install PostgreSQL client tools."
        exit 1
    fi

    if [ -z "$PGPASSWORD" ]; then
        log_error "PGPASSWORD environment variable is not set"
        exit 1
    fi

    export PGPASSWORD

    log "✓ Prerequisites OK"
}

# Test database connection
test_connection() {
    log "Testing database connection..."

    if ! psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" &>/dev/null; then
        log_error "Failed to connect to database"
        exit 1
    fi

    log "✓ Connection OK"
}

# Create backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${DB_NAME}_${timestamp}"
    local backup_path=""

    mkdir -p "$BACKUP_DIR"

    log "Creating backup: $backup_name"

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would create backup: ${BACKUP_DIR}/${backup_name}.sql.gz"
        return 0
    fi

    # Backup database
    if [ $COMPRESS -eq 1 ]; then
        backup_path="${BACKUP_DIR}/${backup_name}.sql.gz"

        pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
                -d "$DB_NAME" \
                --format=plain \
                --no-owner \
                --no-acl \
                --verbose 2>&1 | tee -a "$LOG_FILE" | gzip > "$backup_path"
    else
        backup_path="${BACKUP_DIR}/${backup_name}.sql"

        pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
                -d "$DB_NAME" \
                --format=plain \
                --no-owner \
                --no-acl \
                --verbose \
                --file="$backup_path" 2>&1 | tee -a "$LOG_FILE"
    fi

    if [ $? -eq 0 ]; then
        local size=$(du -h "$backup_path" | awk '{print $1}')
        log "✓ Backup created: $backup_path ($size)"

        # Verify backup
        if [ $COMPRESS -eq 1 ]; then
            if gzip -t "$backup_path" &>/dev/null; then
                log "✓ Backup verified"
            else
                log_error "Backup verification failed"
                exit 1
            fi
        fi
    else
        log_error "Backup failed"
        exit 1
    fi
}

# Backup specific schemas
backup_schema() {
    local schema="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${DB_NAME}_${schema}_${timestamp}.sql.gz"
    local backup_path="${BACKUP_DIR}/${backup_name}"

    log "Backing up schema: $schema"

    pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
            -d "$DB_NAME" \
            --schema="$schema" \
            --format=plain \
            --no-owner \
            --no-acl | gzip > "$backup_path"

    log "✓ Schema backup: $backup_path"
}

# Backup all databases
backup_all_databases() {
    log "Backing up all databases..."

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/all_databases_${timestamp}.sql.gz"

    pg_dumpall -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
               --no-role-passwords | gzip > "$backup_path"

    log "✓ All databases backed up: $backup_path"
}

# Rotate old backups
rotate_backups() {
    log "Rotating old backups..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would delete backups older than $RETENTION_DAYS days"
        find "$BACKUP_DIR" -name "${DB_NAME}_*.sql*" -type f -mtime +$RETENTION_DAYS | while read file; do
            log "[DRY RUN] Would delete: $file"
        done
        return 0
    fi

    local deleted=0
    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql*" -type f -mtime +$RETENTION_DAYS | while read file; do
        log "Deleting old backup: $file"
        rm -f "$file"
        ((deleted++))
    done

    log "Deleted $deleted old backup(s)"
}

# List backups
list_backups() {
    log "Available backups in $BACKUP_DIR:"

    if [ ! -d "$BACKUP_DIR" ]; then
        log "No backups found"
        return
    fi

    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql*" -type f -printf "%T@ %p %s\n" | \
        sort -rn | \
        while read timestamp file size; do
            local date=$(date -d "@$timestamp" '+%Y-%m-%d %H:%M:%S')
            local human_size=$(numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "$size bytes")
            log "  $date - $(basename "$file") - $human_size"
        done
}

# Send notification
send_notification() {
    local status="${1:-success}"
    local message="${2:-Backup completed}"

    # Slack notification
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        local color="good"
        [ "$status" = "failed" ] && color="danger"

        curl -X POST -H 'Content-type: application/json' \
            --data "{
                \"attachments\": [{
                    \"color\": \"$color\",
                    \"title\": \"PostgreSQL Backup $status\",
                    \"text\": \"$message\",
                    \"fields\": [
                        {\"title\": \"Database\", \"value\": \"$DB_NAME\", \"short\": true},
                        {\"title\": \"Host\", \"value\": \"$DB_HOST\", \"short\": true}
                    ]
                }]
            }" \
            "$SLACK_WEBHOOK" &> /dev/null || true
    fi
}

# Cleanup on exit
cleanup() {
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_error "Backup script failed"
        send_notification "failed" "Backup failed with exit code $exit_code"
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
            -h|--help) usage ;;
            -H|--host) DB_HOST="$2"; shift 2 ;;
            -p|--port) DB_PORT="$2"; shift 2 ;;
            -U|--user) DB_USER="$2"; shift 2 ;;
            -d|--database) DB_NAME="$2"; shift 2 ;;
            -b|--backup-dir) BACKUP_DIR="$2"; shift 2 ;;
            -r|--retention) RETENTION_DAYS="$2"; shift 2 ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            --no-compress) COMPRESS=0; shift ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    log "=========================================="
    log "PostgreSQL Backup Started"
    log "=========================================="
    log "Database: $DB_NAME"
    log "Host: $DB_HOST:$DB_PORT"
    log "Backup directory: $BACKUP_DIR"
    log "Retention: $RETENTION_DAYS days"

    check_prerequisites
    test_connection
    create_backup
    rotate_backups
    list_backups

    log "=========================================="
    log "Backup Completed"
    log "=========================================="
}

trap cleanup EXIT INT TERM

main "$@"
