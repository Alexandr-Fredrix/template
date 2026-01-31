#!/bin/bash
#
# Манипуляции со строками
#

set -euo pipefail

echo "=== Длина строки ==="
STR="Hello, World!"
echo "String: $STR"
echo "Length: ${#STR}"

echo -e "\n=== Извлечение подстроки ==="
TEXT="Bash Scripting Tutorial"
echo "Original: $TEXT"
echo "From position 5: ${TEXT:5}"
echo "From position 5, length 9: ${TEXT:5:9}"
echo "Last 8 chars: ${TEXT: -8}"

echo -e "\n=== Замена подстроки ==="
PHRASE="I love apples and apples are great"
echo "Original: $PHRASE"
echo "Replace first 'apples': ${PHRASE/apples/oranges}"
echo "Replace all 'apples': ${PHRASE//apples/oranges}"
echo "Delete 'apples': ${PHRASE//apples/}"

echo -e "\n=== Замена в начале/конце ==="
MESSAGE="Hello World"
echo "Original: $MESSAGE"
echo "Replace 'Hello' at start: ${MESSAGE/#Hello/Hi}"
echo "Replace 'World' at end: ${MESSAGE/%World/Universe}"

echo -e "\n=== Удаление префикса/суффикса ==="
FILENAME="archive.tar.gz"
echo "Filename: $FILENAME"
echo "Remove shortest from start (*.*): ${FILENAME#*.}"
echo "Remove longest from start (*.*): ${FILENAME##*.}"
echo "Remove shortest from end (.*): ${FILENAME%.*}"
echo "Remove longest from end (.*): ${FILENAME%%.*}"

echo -e "\n=== Практический пример - работа с путями ==="
FILEPATH="/home/user/documents/report.pdf"
echo "Full path: $FILEPATH"
echo "Filename: $(basename "$FILEPATH")"
echo "Directory: $(dirname "$FILEPATH")"
echo "Extension: ${FILEPATH##*.}"
echo "Name without extension: $(basename "${FILEPATH%.*}")"

echo -e "\n=== Изменение регистра ==="
TEXT="Hello World"
echo "Original: $TEXT"
echo "Uppercase: ${TEXT^^}"
echo "Lowercase: ${TEXT,,}"
echo "First char uppercase: ${TEXT^}"
echo "First char lowercase: ${TEXT,}"

# Альтернативные методы
echo "tr uppercase: $(echo "$TEXT" | tr '[:lower:]' '[:upper:]')"
echo "awk uppercase: $(echo "$TEXT" | awk '{print toupper($0)}')"

echo -e "\n=== Разделение строки ==="
CSV="apple,banana,cherry,date"
echo "CSV: $CSV"

# Разделение в массив
IFS=',' read -ra FRUITS <<< "$CSV"
echo "Fruits array:"
for fruit in "${FRUITS[@]}"; do
    echo "  - $fruit"
done

echo -e "\n=== Объединение строк ==="
ARR=("one" "two" "three")
IFS=','
JOINED="${ARR[*]}"
echo "Joined with comma: $JOINED"

IFS=' '
JOINED="${ARR[*]}"
echo "Joined with space: $JOINED"

IFS=$'\n\t'  # Restore IFS

echo -e "\n=== Конкатенация ==="
FIRST="Hello"
LAST="World"
FULL="$FIRST, $LAST!"
echo "$FULL"

# С разделителем
SEP=" - "
RESULT="$FIRST$SEP$LAST"
echo "$RESULT"

echo -e "\n=== Проверка паттернов ==="
EMAIL="user@example.com"

# С использованием [[]]
if [[ "$EMAIL" == *@* ]]; then
    echo "$EMAIL содержит @"
fi

if [[ "$EMAIL" == user* ]]; then
    echo "$EMAIL начинается с 'user'"
fi

if [[ "$EMAIL" == *.com ]]; then
    echo "$EMAIL оканчивается на '.com'"
fi

echo -e "\n=== Regex ==="
# Проверка формата email
if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "$EMAIL - валидный email"
fi

# Проверка телефона
PHONE="123-456-7890"
if [[ "$PHONE" =~ ^[0-9]{3}-[0-9]{3}-[0-9]{4}$ ]]; then
    echo "$PHONE - валидный телефон"
fi

# Извлечение частей через regex
VERSION="v1.2.3"
if [[ "$VERSION" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
    echo "Major: $MAJOR, Minor: $MINOR, Patch: $PATCH"
fi

echo -e "\n=== Padding (дополнение) ==="
NUM=42
# Left pad с нулями
printf "Padded: %05d\n" $NUM

# Right pad
printf "%-10s|\n" "text"

echo -e "\n=== Trimming (удаление пробелов) ==="
SPACED="   text with spaces   "
echo "Original: [$SPACED]"

# Удалить leading пробелы
TRIMMED="${SPACED#"${SPACED%%[![:space:]]*}"}"
echo "Left trim: [$TRIMMED]"

# Удалить trailing пробелы
TRIMMED="${SPACED%"${SPACED##*[![:space:]]}"}"
echo "Right trim: [$TRIMMED]"

# Удалить оба
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo "$var"
}
echo "Both trim: [$(trim "$SPACED")]"

echo -e "\n=== Повторение строки ==="
repeat() {
    local str="$1"
    local count="$2"
    local result=""
    for ((i=0; i<count; i++)); do
        result+="$str"
    done
    echo "$result"
}

echo "Repeat '*' 10 times: $(repeat '*' 10)"
echo "Repeat 'abc' 5 times: $(repeat 'abc' 5)"

echo -e "\n=== Reverse строки ==="
reverse() {
    echo "$1" | rev
}

echo "Original: Hello"
echo "Reversed: $(reverse "Hello")"

echo -e "\n=== Содержит подстроку ==="
contains() {
    [[ "$1" == *"$2"* ]]
}

TEXT="The quick brown fox"
if contains "$TEXT" "quick"; then
    echo "'$TEXT' содержит 'quick'"
fi

echo -e "\n=== Начинается/заканчивается ==="
starts_with() {
    [[ "$1" == "$2"* ]]
}

ends_with() {
    [[ "$1" == *"$2" ]]
}

if starts_with "Hello World" "Hello"; then
    echo "Строка начинается с 'Hello'"
fi

if ends_with "Hello World" "World"; then
    echo "Строка заканчивается на 'World'"
fi
