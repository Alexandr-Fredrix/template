#!/bin/bash
#
# Базовый пример Bash скрипта
# Демонстрирует основные концепции
#

# Строгий режим
set -euo pipefail

# Вывод текста
echo "Hello, World!"
echo "Текущая дата: $(date)"
echo "Текущий пользователь: $USER"
echo "Домашняя директория: $HOME"

# Простая переменная
NAME="John"
echo "Привет, $NAME!"

# Арифметика
NUM1=10
NUM2=20
SUM=$((NUM1 + NUM2))
echo "$NUM1 + $NUM2 = $SUM"

# Выполнение команды
CURRENT_DIR=$(pwd)
echo "Текущая директория: $CURRENT_DIR"

# Подсчёт файлов
FILE_COUNT=$(ls -1 | wc -l)
echo "Файлов в текущей директории: $FILE_COUNT"

# Простое условие
if [ $FILE_COUNT -gt 5 ]; then
    echo "Много файлов!"
else
    echo "Мало файлов"
fi
