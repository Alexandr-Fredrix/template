#!/bin/bash
#
# MongoDB Backup Script
#

set -euo pipefail

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_USER:-}"
MONGO_PASSWORD="${MONGO_PASSWORD:-}"
MONGO_DB="${MONGO_DB:-}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/mongodb}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${MONGO_DB}_${timestamp}.archive.gz"
    
    mkdir -p "$BACKUP_DIR"
    
    log "Creating backup: $backup_path"
    
    local uri="mongodb://"
    [ -n "$MONGO_USER" ] && uri="${uri}${MONGO_USER}:${MONGO_PASSWORD}@"
    uri="${uri}${MONGO_HOST}:${MONGO_PORT}/${MONGO_DB}"
    
    mongodump --uri="$uri" \
              --archive="$backup_path" \
              --gzip
    
    log "✓ Backup created: $backup_path"
}

rotate_backups() {
    log "Rotating backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "${MONGO_DB}_*.archive.gz" -mtime +$RETENTION_DAYS -delete
}

main() {
    if [ -z "$MONGO_DB" ]; then
        echo "Usage: MONGO_DB=myapp $0"
        exit 1
    fi
    
    create_backup
    rotate_backups
}

main "$@"
