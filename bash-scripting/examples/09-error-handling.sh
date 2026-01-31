#!/bin/bash
#
# Обработка ошибок в Bash
#

echo "=== Exit коды ==="
# Успешная команда
true
echo "Exit code of 'true': $?"

# Неуспешная команда
false
echo "Exit code of 'false': $?"

# Проверка команды
if ls /tmp > /dev/null 2>&1; then
    echo "/tmp exists"
fi

echo -e "\n=== Set опции ==="
cat > /tmp/demo_set.sh <<'EOF'
#!/bin/bash

# -e: exit on error
set -e
echo "Command 1"
false  # Скрипт остановится здесь
echo "Command 2"  # Не выполнится
EOF

echo "Демонстрация set -e:"
bash /tmp/demo_set.sh || echo "Script exited with error"

echo -e "\n=== Set -u (неустановленные переменные) ==="
cat > /tmp/demo_set_u.sh <<'EOF'
#!/bin/bash
set -u
echo "Variable: $UNDEFINED_VAR"  # Ошибка
EOF

echo "Демонстрация set -u:"
bash /tmp/demo_set_u.sh 2>&1 || echo "Script failed on undefined variable"

echo -e "\n=== Игнорирование ошибок ==="
set -e
false || true  # Ошибка игнорируется
echo "Продолжаем после игнорированной ошибки"

# Или
command_that_might_fail || {
    echo "Command failed, but we continue"
}

echo -e "\n=== Trap - cleanup при выходе ==="
cat > /tmp/demo_trap.sh <<'EOF'
#!/bin/bash

cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/tempfile_$$
}

trap cleanup EXIT

echo "Creating temp file..."
touch /tmp/tempfile_$$
echo "Temp file created"

# Trap вызовется автоматически при выходе
EOF

bash /tmp/demo_trap.sh

echo -e "\n=== Trap - обработка ошибок ==="
cat > /tmp/demo_trap_err.sh <<'EOF'
#!/bin/bash
set -e

error_handler() {
    echo "Error occurred at line $1"
    exit 1
}

trap 'error_handler $LINENO' ERR

echo "Command 1"
false  # Вызовет error_handler
echo "Command 2"  # Не выполнится
EOF

bash /tmp/demo_trap_err.sh 2>&1 || echo "Script handled error"

echo -e "\n=== Trap - Ctrl+C ==="
cat > /tmp/demo_trap_int.sh <<'EOF'
#!/bin/bash

interrupted() {
    echo -e "\nInterrupted! Cleaning up..."
    exit 130
}

trap interrupted INT SIGINT

echo "Press Ctrl+C within 3 seconds..."
sleep 3
echo "Not interrupted"
EOF

timeout 1 bash /tmp/demo_trap_int.sh 2>&1 || echo "Demo completed"

echo -e "\n=== Проверка команд ==="
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed"
        return 1
    else
        echo "$1 is available"
        return 0
    fi
}

check_command "bash"
check_command "nonexistent_command" || echo "Command not found (expected)"

echo -e "\n=== Try-Catch эмуляция ==="
try() {
    "$@"
    return $?
}

catch() {
    local exit_code=$?
    echo "Caught error with exit code: $exit_code"
    return $exit_code
}

if ! try false; then
    catch
fi

echo -e "\n=== Безопасное выполнение ==="
safe_exec() {
    local cmd="$1"
    local max_retries="${2:-3}"
    local retry=0

    while [ $retry -lt $max_retries ]; do
        if $cmd; then
            echo "Command succeeded"
            return 0
        else
            ((retry++))
            echo "Attempt $retry failed, retrying..."
            sleep 1
        fi
    done

    echo "Command failed after $max_retries attempts"
    return 1
}

# Демонстрация
attempt=0
flaky_command() {
    ((attempt++))
    if [ $attempt -ge 2 ]; then
        return 0  # Успех на второй попытке
    else
        return 1  # Неудача
    fi
}

safe_exec flaky_command 3

echo -e "\n=== Логирование ошибок ==="
LOG_FILE="/tmp/error.log"

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE" >&2
}

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

log_info "Starting script"
log_error "Something went wrong"
log_info "Script completed"

echo "Log file contents:"
cat "$LOG_FILE"

echo -e "\n=== Валидация входных данных ==="
validate_number() {
    local num="$1"

    if ! [[ "$num" =~ ^[0-9]+$ ]]; then
        echo "Error: '$num' is not a valid number" >&2
        return 1
    fi

    if [ "$num" -lt 0 ] || [ "$num" -gt 100 ]; then
        echo "Error: number must be between 0 and 100" >&2
        return 1
    fi

    return 0
}

if validate_number 50; then
    echo "50 is valid"
fi

if ! validate_number "abc"; then
    echo "Validation failed (expected)"
fi

echo -e "\n=== Pipefail ==="
cat > /tmp/demo_pipefail.sh <<'EOF'
#!/bin/bash

echo "Without pipefail:"
set +o pipefail
false | true
echo "Exit code: $?"  # 0 (последняя команда успешна)

echo -e "\nWith pipefail:"
set -o pipefail
false | true
echo "Exit code: $?"  # 1 (первая команда неуспешна)
EOF

bash /tmp/demo_pipefail.sh

echo -e "\n=== Проверка prerequisite ==="
check_prerequisites() {
    local missing=0

    for cmd in git docker kubectl; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Missing: $cmd"
            ((missing++))
        fi
    done

    if [ $missing -gt 0 ]; then
        echo "Please install missing dependencies"
        return 1
    fi

    return 0
}

# Проверка (может упасть)
check_prerequisites || echo "Some prerequisites missing"

# Cleanup
rm -f /tmp/demo_*.sh /tmp/tempfile_* "$LOG_FILE"
echo -e "\nCleanup completed"
