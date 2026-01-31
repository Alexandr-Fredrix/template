#!/bin/bash
#
# MySQL Backup Script
#

set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_USER="${DB_USER:-root}"
DB_PASSWORD="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/mysql}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${DB_NAME}_${timestamp}.sql.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    log "Creating backup: $backup_path"
    
    mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" \
              "$DB_NAME" \
              --single-transaction \
              --routines \
              --triggers | gzip > "$backup_path"
    
    log "✓ Backup created: $backup_path"
}

rotate_backups() {
    log "Rotating backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "${DB_NAME}_*.sql.gz" -mtime +$RETENTION_DAYS -delete
}

main() {
    if [ -z "$DB_PASSWORD" ] || [ -z "$DB_NAME" ]; then
        echo "Usage: DB_PASSWORD=secret DB_NAME=myapp $0"
        exit 1
    fi
    
    create_backup
    rotate_backups
}

main "$@"
