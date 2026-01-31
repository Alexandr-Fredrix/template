#!/bin/bash
#
# Deployment Template Script
# Template for application deployment with rollback
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Application settings
APP_NAME="${APP_NAME:-myapp}"
APP_DIR="${APP_DIR:-/var/www/$APP_NAME}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/$APP_NAME}"
LOG_FILE="${LOG_FILE:-/var/log/${APP_NAME}-deploy.log}"

# Git settings
REPO_URL="${REPO_URL:-}"
BRANCH="${BRANCH:-main}"

# Flags
DRY_RUN=0
VERBOSE=0
SKIP_BACKUP=0
FORCE=0

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

Deploy application with automatic backup and rollback.

Options:
    -h, --help          Show help
    -a, --app NAME      Application name
    -b, --branch NAME   Git branch
    -n, --dry-run       Dry run mode
    -v, --verbose       Verbose output
    --skip-backup       Skip backup
    --force             Force deployment

EOF
    exit 0
}

# Backup current version
create_backup() {
    if [ $SKIP_BACKUP -eq 1 ]; then
        log "Skipping backup"
        return 0
    fi

    log "Creating backup..."

    if [ ! -d "$APP_DIR" ]; then
        log "No existing installation to backup"
        return 0
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/backup_${timestamp}.tar.gz"

    mkdir -p "$BACKUP_DIR"

    if tar -czf "$backup_path" -C "$(dirname "$APP_DIR")" "$(basename "$APP_DIR")"; then
        log "✓ Backup created: $backup_path"
        echo "$backup_path" > /tmp/last_backup
    else
        log_error "Backup failed"
        exit 1
    fi
}

# Stop application
stop_app() {
    log "Stopping application..."

    # TODO: Add your stop logic
    # Examples:
    # - systemctl stop $APP_NAME
    # - docker-compose down
    # - kill $(cat /var/run/$APP_NAME.pid)

    log "✓ Application stopped"
}

# Deploy new version
deploy() {
    log "Deploying application..."

    # TODO: Add your deployment logic
    # Examples:
    # - git clone/pull
    # - copy files
    # - build application

    log "✓ Deployment completed"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."

    # TODO: Add dependency installation
    # Examples:
    # - npm install
    # - pip install -r requirements.txt
    # - composer install

    log "✓ Dependencies installed"
}

# Run migrations
run_migrations() {
    log "Running migrations..."

    # TODO: Add migration logic
    # Examples:
    # - npm run migrate
    # - php artisan migrate
    # - python manage.py migrate

    log "✓ Migrations completed"
}

# Start application
start_app() {
    log "Starting application..."

    # TODO: Add your start logic
    # Examples:
    # - systemctl start $APP_NAME
    # - docker-compose up -d
    # - pm2 start app.js

    log "✓ Application started"
}

# Health check
health_check() {
    log "Running health check..."

    local retries=0
    local max_retries=10

    while [ $retries -lt $max_retries ]; do
        # TODO: Add your health check
        # Example:
        # if curl -f http://localhost:8080/health; then
        #     log "✓ Health check passed"
        #     return 0
        # fi

        ((retries++))
        sleep 2
    done

    log_error "Health check failed"
    return 1
}

# Rollback to previous version
rollback() {
    log_error "Deployment failed, rolling back..."

    if [ ! -f /tmp/last_backup ]; then
        log_error "No backup found for rollback"
        exit 1
    fi

    local backup_path=$(cat /tmp/last_backup)

    stop_app

    # Restore backup
    rm -rf "$APP_DIR"
    tar -xzf "$backup_path" -C "$(dirname "$APP_DIR")"

    start_app

    log "✓ Rollback completed"
    exit 1
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) usage ;;
            -a|--app) APP_NAME="$2"; shift 2 ;;
            -b|--branch) BRANCH="$2"; shift 2 ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            --skip-backup) SKIP_BACKUP=1; shift ;;
            --force) FORCE=1; shift ;;
            *) log_error "Unknown option: $1"; usage ;;
        esac
    done

    log "=========================================="
    log "Deployment Started"
    log "=========================================="
    log "Application: $APP_NAME"
    log "Branch: $BRANCH"

    # Execute deployment
    create_backup || rollback

    stop_app || rollback
    deploy || rollback
    install_dependencies || rollback
    run_migrations || rollback
    start_app || rollback
    health_check || rollback

    log "=========================================="
    log "✓ Deployment Successful"
    log "=========================================="
}

# Set error trap
trap rollback ERR

main "$@"
