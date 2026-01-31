#!/bin/bash
#
# Application Deployment Script
# Автоматизация деплоя приложения с rollback возможностью
#
# Использование: ./deployment-script.sh [options]
#

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Default values
APP_NAME="${APP_NAME:-myapp}"
APP_DIR="${APP_DIR:-/var/www/myapp}"
REPO_URL="${REPO_URL:-https://github.com/user/repo.git}"
BRANCH="${BRANCH:-main}"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/deployments}"
HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-http://localhost:8080/health}"
HEALTH_CHECK_TIMEOUT="${HEALTH_CHECK_TIMEOUT:-30}"

# Flags
DRY_RUN=0
VERBOSE=0
SKIP_BACKUP=0
SKIP_TESTS=0
FORCE=0

# ============================================================================
# Functions
# ============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR] $(date '+%Y-%m-%d %H:%M:%S')${NC} $*" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $(date '+%Y-%m-%d %H:%M:%S')${NC} $*"
}

log_info() {
    if [ $VERBOSE -eq 1 ]; then
        echo "[INFO] $*"
    fi
}

usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Deploy application with automatic rollback on failure.

Options:
    -h, --help                  Show this help
    -a, --app NAME              Application name (default: $APP_NAME)
    -d, --directory DIR         Application directory (default: $APP_DIR)
    -r, --repo URL              Git repository URL
    -b, --branch BRANCH         Git branch (default: $BRANCH)
    -n, --dry-run               Dry run mode
    -v, --verbose               Verbose output
    --skip-backup               Skip backup step
    --skip-tests                Skip tests
    --force                     Force deployment

Examples:
    $SCRIPT_NAME --app myapp --branch develop
    $SCRIPT_NAME -v --skip-tests
    $SCRIPT_NAME --dry-run

EOF
    exit 0
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    local missing=0
    for cmd in git npm node; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "Required command not found: $cmd"
            ((missing++))
        fi
    done

    if [ $missing -gt 0 ]; then
        log_error "$missing required command(s) missing"
        exit 1
    fi

    log "✓ Prerequisites check passed"
}

# Create backup
create_backup() {
    if [ $SKIP_BACKUP -eq 1 ]; then
        log_warning "Skipping backup (--skip-backup flag)"
        return 0
    fi

    log "Creating backup..."

    if [ ! -d "$APP_DIR" ]; then
        log_warning "Application directory doesn't exist, skipping backup"
        return 0
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="${BACKUP_DIR}/${APP_NAME}_${timestamp}.tar.gz"

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would create backup: $backup_path"
        return 0
    fi

    mkdir -p "$BACKUP_DIR"

    tar -czf "$backup_path" -C "$(dirname "$APP_DIR")" "$(basename "$APP_DIR")" 2>&1

    if [ $? -eq 0 ]; then
        log "✓ Backup created: $backup_path"
        echo "$backup_path" > /tmp/last_backup_path
    else
        log_error "Backup failed"
        exit 1
    fi
}

# Stop application
stop_app() {
    log "Stopping application..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would stop application"
        return 0
    fi

    # Остановка через systemd
    if systemctl is-active --quiet "$APP_NAME"; then
        systemctl stop "$APP_NAME"
        log "✓ Application stopped"
    else
        log_info "Application is not running"
    fi
}

# Deploy code
deploy_code() {
    log "Deploying code..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would deploy code from $REPO_URL (branch: $BRANCH)"
        return 0
    fi

    if [ -d "$APP_DIR/.git" ]; then
        # Update existing repo
        log_info "Updating existing repository..."
        cd "$APP_DIR"
        git fetch origin
        git checkout "$BRANCH"
        git pull origin "$BRANCH"
    else
        # Clone new repo
        log_info "Cloning repository..."
        mkdir -p "$(dirname "$APP_DIR")"
        git clone -b "$BRANCH" "$REPO_URL" "$APP_DIR"
        cd "$APP_DIR"
    fi

    local commit=$(git rev-parse --short HEAD)
    log "✓ Code deployed (commit: $commit)"
}

# Install dependencies
install_dependencies() {
    log "Installing dependencies..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would install dependencies"
        return 0
    fi

    cd "$APP_DIR"

    if [ -f "package.json" ]; then
        npm ci --production
        log "✓ Dependencies installed"
    else
        log_warning "No package.json found"
    fi
}

# Run tests
run_tests() {
    if [ $SKIP_TESTS -eq 1 ]; then
        log_warning "Skipping tests (--skip-tests flag)"
        return 0
    fi

    log "Running tests..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would run tests"
        return 0
    fi

    cd "$APP_DIR"

    if [ -f "package.json" ] && grep -q "\"test\"" package.json; then
        if npm test; then
            log "✓ Tests passed"
        else
            log_error "Tests failed"
            return 1
        fi
    else
        log_info "No tests configured"
    fi
}

# Build application
build_app() {
    log "Building application..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would build application"
        return 0
    fi

    cd "$APP_DIR"

    if [ -f "package.json" ] && grep -q "\"build\"" package.json; then
        npm run build
        log "✓ Application built"
    else
        log_info "No build script found"
    fi
}

# Start application
start_app() {
    log "Starting application..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would start application"
        return 0
    fi

    systemctl start "$APP_NAME"

    # Wait for startup
    sleep 2

    if systemctl is-active --quiet "$APP_NAME"; then
        log "✓ Application started"
    else
        log_error "Application failed to start"
        return 1
    fi
}

# Health check
health_check() {
    log "Running health check..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would run health check on $HEALTH_CHECK_URL"
        return 0
    fi

    local retries=0
    local max_retries=$((HEALTH_CHECK_TIMEOUT / 2))

    while [ $retries -lt $max_retries ]; do
        if curl -f -s -o /dev/null "$HEALTH_CHECK_URL"; then
            log "✓ Health check passed"
            return 0
        fi

        ((retries++))
        log_info "Health check attempt $retries/$max_retries failed, retrying..."
        sleep 2
    done

    log_error "Health check failed after $max_retries attempts"
    return 1
}

# Rollback
rollback() {
    log_error "Deployment failed, rolling back..."

    if [ $DRY_RUN -eq 1 ]; then
        log "[DRY RUN] Would rollback"
        return 0
    fi

    # Stop current version
    systemctl stop "$APP_NAME" 2>/dev/null || true

    # Restore from backup
    if [ -f /tmp/last_backup_path ]; then
        local backup_path=$(cat /tmp/last_backup_path)

        if [ -f "$backup_path" ]; then
            log "Restoring from backup: $backup_path"

            rm -rf "$APP_DIR"
            mkdir -p "$(dirname "$APP_DIR")"
            tar -xzf "$backup_path" -C "$(dirname "$APP_DIR")"

            systemctl start "$APP_NAME"

            log "✓ Rollback completed"
        else
            log_error "Backup file not found: $backup_path"
        fi
    else
        log_error "No backup path found"
    fi

    exit 1
}

# Send notification
send_notification() {
    local status="${1:-success}"
    local message="${2:-Deployment completed}"

    # Slack webhook
    if [ -n "${SLACK_WEBHOOK:-}" ]; then
        local color="good"
        [ "$status" = "failed" ] && color="danger"

        curl -X POST -H 'Content-type: application/json' \
            --data "{
                \"attachments\": [{
                    \"color\": \"$color\",
                    \"title\": \"Deployment $status\",
                    \"text\": \"$message\",
                    \"fields\": [
                        {\"title\": \"Application\", \"value\": \"$APP_NAME\", \"short\": true},
                        {\"title\": \"Branch\", \"value\": \"$BRANCH\", \"short\": true}
                    ]
                }]
            }" \
            "$SLACK_WEBHOOK" &> /dev/null || true
    fi
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
            -d|--directory) APP_DIR="$2"; shift 2 ;;
            -r|--repo) REPO_URL="$2"; shift 2 ;;
            -b|--branch) BRANCH="$2"; shift 2 ;;
            -n|--dry-run) DRY_RUN=1; shift ;;
            -v|--verbose) VERBOSE=1; shift ;;
            --skip-backup) SKIP_BACKUP=1; shift ;;
            --skip-tests) SKIP_TESTS=1; shift ;;
            --force) FORCE=1; shift ;;
            *)
                log_error "Unknown option: $1"
                usage
                ;;
        esac
    done

    # Confirm if not forced
    if [ $FORCE -eq 0 ] && [ $DRY_RUN -eq 0 ]; then
        read -p "Deploy $APP_NAME from branch $BRANCH? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Deployment cancelled"
            exit 0
        fi
    fi

    log "========================================="
    log "Deployment Started"
    log "========================================="
    log "Application: $APP_NAME"
    log "Directory: $APP_DIR"
    log "Repository: $REPO_URL"
    log "Branch: $BRANCH"
    [ $DRY_RUN -eq 1 ] && log "Mode: DRY RUN"

    # Execute deployment
    check_prerequisites
    create_backup
    stop_app

    if ! deploy_code; then rollback; fi
    if ! install_dependencies; then rollback; fi
    if ! run_tests; then rollback; fi
    if ! build_app; then rollback; fi
    if ! start_app; then rollback; fi
    if ! health_check; then rollback; fi

    log "========================================="
    log "✓ Deployment Completed Successfully"
    log "========================================="

    send_notification "success" "Deployment of $APP_NAME completed"
}

# Error handler
set -E
trap 'rollback' ERR

# Run
main "$@"
