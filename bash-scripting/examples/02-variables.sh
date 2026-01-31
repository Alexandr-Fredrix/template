#!/bin/bash
#
# Работа с переменными
#

set -euo pipefail

echo "=== Базовые переменные ==="
STRING="Hello"
NUMBER=42
FLOAT="3.14"  # Bash не поддерживает float напрямую

echo "String: $STRING"
echo "Number: $NUMBER"
echo "Float: $FLOAT"

echo -e "\n=== Константы ==="
readonly PI=3.14159
readonly MAX_USERS=100
echo "PI: $PI"
echo "Max users: $MAX_USERS"

echo -e "\n=== Специальные переменные ==="
echo "Script name: $0"
echo "Process ID: $$"
echo "User: $USER"
echo "Home: $HOME"
echo "Path: $PATH"

echo -e "\n=== Подстановка команд ==="
CURRENT_DATE=$(date +%Y-%m-%d)
UPTIME_DAYS=$(uptime | awk '{print $3}')
echo "Сегодня: $CURRENT_DATE"
echo "Uptime: $uptime_days"

echo -e "\n=== Значения по умолчанию ==="
# Если переменная не установлена, использовать default
DEFAULT_NAME=${NAME:-"Anonymous"}
echo "Name: $DEFAULT_NAME"

# Установить переменную если не установлена
: ${PORT:=8080}
echo "Port: $PORT"

echo -e "\n=== Арифметика ==="
A=10
B=5
echo "$A + $B = $((A + B))"
echo "$A - $B = $((A - B))"
echo "$A * $B = $((A * B))"
echo "$A / $B = $((A / B))"
echo "$A % $B = $((A % B))"

# Инкремент/декремент
COUNT=0
((COUNT++))
echo "After increment: $COUNT"

echo -e "\n=== Переменные окружения ==="
export MY_VAR="exported value"
echo "MY_VAR: $MY_VAR"

# Вывести все переменные окружения
# env
