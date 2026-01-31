# Полное руководство по написанию Bash скриптов

## 📚 Содержание

1. [Основы Bash](#основы-bash)
2. [Переменные](#переменные)
3. [Условные операторы](#условные-операторы)
4. [Циклы](#циклы)
5. [Функции](#функции)
6. [Массивы](#массивы)
7. [Работа с файлами](#работа-с-файлами)
8. [Работа со строками](#работа-со-строками)
9. [Обработка ошибок](#обработка-ошибок)
10. [Аргументы командной строки](#аргументы-командной-строки)
11. [Регулярные выражения](#регулярные-выражения)
12. [Отладка](#отладка)
13. [Best Practices](#best-practices)
14. [Безопасность](#безопасность)

---

## Основы Bash

### Первый скрипт

```bash
#!/bin/bash
# Shebang - указывает интерпретатор для выполнения скрипта

# Это комментарий
echo "Hello, World!"  # Вывод текста в консоль
```

**Создание и запуск:**

```bash
# Создать файл
touch script.sh

# Сделать исполняемым
chmod +x script.sh

# Запустить
./script.sh

# Или через bash
bash script.sh
```

### Структура скрипта

```bash
#!/bin/bash
#
# Описание: Что делает скрипт
# Автор: Ваше имя
# Дата: 2024-01-31
# Версия: 1.0
#
# Использование: ./script.sh [options] [arguments]
#

set -euo pipefail  # Строгий режим (рекомендуется)

# Глобальные переменные
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Функции
main() {
    echo "Основная логика скрипта"
}

# Точка входа
main "$@"
```

---

## Переменные

### Объявление и использование

```bash
# Простое присваивание (БЕЗ пробелов вокруг =)
NAME="John"
AGE=30

# Использование переменных
echo "Name: $NAME"
echo "Age: ${AGE}"  # Рекомендуемый формат с {}

# Константы (нельзя изменить)
readonly PI=3.14159
declare -r CONSTANT="value"

# Локальные переменные (только внутри функций)
function example() {
    local local_var="local"
}
```

### Типы переменных

```bash
# Строки
STRING="Hello World"
MULTILINE="Line 1
Line 2
Line 3"

# Числа (Bash работает только с целыми числами)
NUM=42
RESULT=$((NUM + 10))  # Арифметика

# Массивы
ARRAY=("item1" "item2" "item3")

# Ассоциативные массивы (словари)
declare -A DICT
DICT["key1"]="value1"
DICT["key2"]="value2"
```

### Специальные переменные

```bash
$0      # Имя скрипта
$1-$9   # Позиционные аргументы
$#      # Количество аргументов
$@      # Все аргументы как отдельные слова
$*      # Все аргументы как одна строка
$?      # Код возврата последней команды
$$      # PID текущего процесса
$!      # PID последнего фонового процесса
$_      # Последний аргумент предыдущей команды

# Примеры
echo "Script name: $0"
echo "First arg: $1"
echo "All args: $@"
echo "Number of args: $#"
echo "Last exit code: $?"
```

### Подстановка команд

```bash
# Современный синтаксис (рекомендуется)
CURRENT_DATE=$(date +%Y-%m-%d)
FILES_COUNT=$(ls -1 | wc -l)

# Старый синтаксис (не рекомендуется)
OLD_SYNTAX=`date`

# Вложенные подстановки
RESULT=$(echo "Result: $(date)")
```

### Переменные окружения

```bash
# Системные переменные
echo "Home: $HOME"
echo "User: $USER"
echo "Path: $PATH"
echo "PWD: $PWD"

# Экспорт переменной (доступна в дочерних процессах)
export MY_VAR="value"

# Проверка существования
if [ -z "$MY_VAR" ]; then
    echo "MY_VAR не установлена"
fi
```

### Значения по умолчанию

```bash
# Если переменная не установлена, использовать значение по умолчанию
NAME=${NAME:-"default"}

# Если переменная пуста или не установлена
NAME=${NAME:="default"}

# Вызвать ошибку если переменная не установлена
NAME=${NAME:?"Error: NAME is required"}

# Использовать альтернативное значение если установлена
RESULT=${VAR:+"VAR is set"}
```

---

## Условные операторы

### If-Then-Else

```bash
# Базовый синтаксис
if [ условие ]; then
    echo "Истина"
fi

# С else
if [ условие ]; then
    echo "Истина"
else
    echo "Ложь"
fi

# С elif
if [ условие1 ]; then
    echo "Условие 1"
elif [ условие2 ]; then
    echo "Условие 2"
else
    echo "Иначе"
fi

# Многострочный формат (рекомендуется)
if [ условие ]; then
    команда1
    команда2
fi
```

### Операторы сравнения

```bash
# Числовые сравнения
if [ $a -eq $b ]; then echo "равно"; fi           # equal
if [ $a -ne $b ]; then echo "не равно"; fi        # not equal
if [ $a -gt $b ]; then echo "больше"; fi          # greater than
if [ $a -ge $b ]; then echo "больше или равно"; fi # greater or equal
if [ $a -lt $b ]; then echo "меньше"; fi          # less than
if [ $a -le $b ]; then echo "меньше или равно"; fi # less or equal

# Строковые сравнения
if [ "$a" = "$b" ]; then echo "равны"; fi         # equal
if [ "$a" != "$b" ]; then echo "не равны"; fi     # not equal
if [ -z "$a" ]; then echo "строка пуста"; fi      # zero length
if [ -n "$a" ]; then echo "строка не пуста"; fi   # non-zero length

# Современный синтаксис [[ ]] (рекомендуется)
if [[ "$a" == "$b" ]]; then echo "равны"; fi
if [[ "$a" != "$b" ]]; then echo "не равны"; fi
if [[ "$a" < "$b" ]]; then echo "меньше"; fi      # лексикографически
if [[ "$a" > "$b" ]]; then echo "больше"; fi
```

### Проверка файлов

```bash
# Проверка существования
if [ -e "$file" ]; then echo "существует"; fi
if [ -f "$file" ]; then echo "обычный файл"; fi
if [ -d "$dir" ]; then echo "директория"; fi
if [ -L "$link" ]; then echo "символическая ссылка"; fi

# Проверка прав доступа
if [ -r "$file" ]; then echo "читаемый"; fi
if [ -w "$file" ]; then echo "записываемый"; fi
if [ -x "$file" ]; then echo "исполняемый"; fi

# Проверка размера
if [ -s "$file" ]; then echo "не пустой"; fi

# Сравнение файлов
if [ "$file1" -nt "$file2" ]; then echo "file1 новее"; fi  # newer than
if [ "$file1" -ot "$file2" ]; then echo "file1 старше"; fi # older than
```

### Логические операторы

```bash
# AND - &&
if [ условие1 ] && [ условие2 ]; then
    echo "Оба истины"
fi

# OR - ||
if [ условие1 ] || [ условие2 ]; then
    echo "Хотя бы одно истина"
fi

# NOT - !
if [ ! условие ]; then
    echo "Не истина"
fi

# Современный синтаксис
if [[ условие1 && условие2 ]]; then
    echo "Оба истины"
fi

if [[ условие1 || условие2 ]]; then
    echo "Хотя бы одно истина"
fi

# Группировка
if [[ (условие1 || условие2) && условие3 ]]; then
    echo "Сложное условие"
fi
```

### Case (Switch)

```bash
case "$переменная" in
    шаблон1)
        команды
        ;;
    шаблон2|шаблон3)
        команды
        ;;
    *)
        # default
        команды
        ;;
esac

# Пример
case "$1" in
    start)
        echo "Запуск..."
        ;;
    stop)
        echo "Остановка..."
        ;;
    restart)
        echo "Перезапуск..."
        ;;
    *)
        echo "Использование: $0 {start|stop|restart}"
        exit 1
        ;;
esac

# С паттернами
case "$filename" in
    *.txt)
        echo "Текстовый файл"
        ;;
    *.jpg|*.png)
        echo "Изображение"
        ;;
    [a-z]*)
        echo "Начинается с маленькой буквы"
        ;;
esac
```

---

## Циклы

### For Loop

```bash
# Цикл по списку
for item in item1 item2 item3; do
    echo "$item"
done

# Цикл по диапазону чисел
for i in {1..10}; do
    echo "$i"
done

# С шагом
for i in {0..100..10}; do  # 0, 10, 20, ... 100
    echo "$i"
done

# C-style for
for ((i=0; i<10; i++)); do
    echo "$i"
done

# Цикл по файлам
for file in *.txt; do
    echo "Processing: $file"
done

# Цикл по массиву
ARRAY=("one" "two" "three")
for item in "${ARRAY[@]}"; do
    echo "$item"
done

# Цикл по строкам файла
while IFS= read -r line; do
    echo "$line"
done < file.txt
```

### While Loop

```bash
# Базовый while
while [ условие ]; do
    команды
done

# Пример с счётчиком
counter=0
while [ $counter -lt 10 ]; do
    echo "$counter"
    ((counter++))
done

# Бесконечный цикл
while true; do
    echo "Press Ctrl+C to stop"
    sleep 1
done

# Чтение из файла
while IFS= read -r line; do
    echo "Line: $line"
done < input.txt

# Чтение вывода команды
ps aux | while read line; do
    echo "$line"
done
```

### Until Loop

```bash
# Выполняется пока условие ложно
until [ условие ]; do
    команды
done

# Пример
counter=0
until [ $counter -eq 10 ]; do
    echo "$counter"
    ((counter++))
done
```

### Break и Continue

```bash
# Break - выход из цикла
for i in {1..10}; do
    if [ $i -eq 5 ]; then
        break
    fi
    echo "$i"
done

# Continue - переход к следующей итерации
for i in {1..10}; do
    if [ $((i % 2)) -eq 0 ]; then
        continue  # Пропустить чётные числа
    fi
    echo "$i"
done
```

---

## Функции

### Объявление и вызов

```bash
# Простая функция
function hello() {
    echo "Hello, World!"
}

# Альтернативный синтаксис (предпочтительнее)
hello() {
    echo "Hello, World!"
}

# Вызов функции
hello

# С аргументами
greet() {
    echo "Hello, $1!"
}

greet "John"  # Выведет: Hello, John!
```

### Аргументы функций

```bash
# Функция с несколькими аргументами
add() {
    local num1=$1
    local num2=$2
    echo $((num1 + num2))
}

result=$(add 5 3)
echo "Result: $result"  # 8

# Все аргументы
print_args() {
    echo "Количество аргументов: $#"
    echo "Все аргументы: $@"
    for arg in "$@"; do
        echo "- $arg"
    done
}

print_args one two three
```

### Возврат значений

```bash
# Return - возвращает код выхода (0-255)
is_positive() {
    if [ $1 -gt 0 ]; then
        return 0  # успех
    else
        return 1  # ошибка
    fi
}

if is_positive 5; then
    echo "Positive"
fi

# Echo - возвращает значение через stdout
get_user_name() {
    echo "John Doe"
}

name=$(get_user_name)
echo "Name: $name"
```

### Локальные переменные

```bash
# Локальные переменные видны только внутри функции
my_function() {
    local local_var="I'm local"
    global_var="I'm global"

    echo "$local_var"
    echo "$global_var"
}

my_function
# echo "$local_var"  # Ошибка: переменная не существует
echo "$global_var"    # Работает
```

### Рекурсия

```bash
# Факториал
factorial() {
    local n=$1
    if [ $n -le 1 ]; then
        echo 1
    else
        local prev=$(factorial $((n - 1)))
        echo $((n * prev))
    fi
}

result=$(factorial 5)
echo "5! = $result"  # 120
```

---

## Массивы

### Индексированные массивы

```bash
# Создание массива
ARRAY=("apple" "banana" "cherry")

# Альтернативный синтаксис
ARRAY[0]="apple"
ARRAY[1]="banana"
ARRAY[2]="cherry"

# Доступ к элементам
echo "${ARRAY[0]}"  # apple
echo "${ARRAY[1]}"  # banana

# Все элементы
echo "${ARRAY[@]}"  # Все элементы как отдельные слова
echo "${ARRAY[*]}"  # Все элементы как одна строка

# Количество элементов
echo "${#ARRAY[@]}"

# Индексы
echo "${!ARRAY[@]}"

# Срезы (slice)
echo "${ARRAY[@]:1:2}"  # Элементы с индекса 1, длина 2
```

### Операции с массивами

```bash
# Добавление элемента
ARRAY+=("date")

# Удаление элемента
unset ARRAY[1]

# Цикл по массиву
for item in "${ARRAY[@]}"; do
    echo "$item"
done

# Цикл с индексами
for i in "${!ARRAY[@]}"; do
    echo "Index $i: ${ARRAY[$i]}"
done

# Проверка существования элемента
if [ -n "${ARRAY[0]+x}" ]; then
    echo "Element 0 exists"
fi
```

### Ассоциативные массивы (словари)

```bash
# Объявление
declare -A DICT

# Присваивание
DICT["name"]="John"
DICT["age"]="30"
DICT["city"]="New York"

# Доступ
echo "${DICT["name"]}"

# Все ключи
for key in "${!DICT[@]}"; do
    echo "$key"
done

# Все значения
for value in "${DICT[@]}"; do
    echo "$value"
done

# Ключи и значения
for key in "${!DICT[@]}"; do
    echo "$key: ${DICT[$key]}"
done
```

### Многомерные массивы (эмуляция)

```bash
# Bash не поддерживает многомерные массивы напрямую
# Можно эмулировать через строковые ключи

declare -A MATRIX

MATRIX["0,0"]="a"
MATRIX["0,1"]="b"
MATRIX["1,0"]="c"
MATRIX["1,1"]="d"

echo "${MATRIX["0,0"]}"  # a
```

---

## Работа с файлами

### Чтение файлов

```bash
# Построчное чтение
while IFS= read -r line; do
    echo "$line"
done < file.txt

# В массив
mapfile -t LINES < file.txt
# или
readarray -t LINES < file.txt

# Весь файл в переменную
CONTENT=$(<file.txt)

# С сохранением переводов строк
CONTENT=$(cat file.txt)
```

### Запись в файлы

```bash
# Перезапись файла
echo "New content" > file.txt

# Добавление в конец
echo "Appended line" >> file.txt

# Многострочная запись
cat > file.txt <<EOF
Line 1
Line 2
Line 3
EOF

# Запись вывода команды
ls -la > listing.txt

# Перенаправление stderr
command 2> error.log

# Перенаправление stdout и stderr
command > output.log 2>&1
# или современный синтаксис
command &> output.log
```

### Проверка файлов

```bash
# Существование
if [ -e "file.txt" ]; then
    echo "Файл существует"
fi

# Обычный файл
if [ -f "file.txt" ]; then
    echo "Это файл"
fi

# Директория
if [ -d "mydir" ]; then
    echo "Это директория"
fi

# Права доступа
if [ -r "file.txt" ]; then echo "Читаемый"; fi
if [ -w "file.txt" ]; then echo "Записываемый"; fi
if [ -x "script.sh" ]; then echo "Исполняемый"; fi

# Пустой файл
if [ ! -s "file.txt" ]; then
    echo "Файл пуст"
fi
```

### Работа с путями

```bash
# Имя файла
filename=$(basename /path/to/file.txt)  # file.txt

# Директория
dirname=$(dirname /path/to/file.txt)    # /path/to

# Расширение
extension="${filename##*.}"             # txt

# Имя без расширения
name="${filename%.*}"                   # file

# Абсолютный путь
absolute=$(realpath file.txt)

# Директория скрипта
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

### Операции с файлами

```bash
# Создание
touch file.txt
mkdir -p /path/to/dir

# Копирование
cp source.txt dest.txt
cp -r source_dir/ dest_dir/

# Перемещение/переименование
mv old.txt new.txt

# Удаление
rm file.txt
rm -rf directory/

# Поиск файлов
find /path -name "*.txt"
find /path -type f -mtime -7  # Изменённые за последние 7 дней

# Архивирование
tar -czf archive.tar.gz directory/
tar -xzf archive.tar.gz
```

---

## Работа со строками

### Длина строки

```bash
STR="Hello, World!"
echo ${#STR}  # 13
```

### Извлечение подстроки

```bash
STR="Hello, World!"

# С позиции
echo ${STR:7}      # World!

# С позиции и длина
echo ${STR:7:5}    # World

# С конца
echo ${STR: -6}    # World!
```

### Замена подстроки

```bash
STR="Hello, World!"

# Первое вхождение
echo ${STR/o/O}    # HellO, World!

# Все вхождения
echo ${STR//o/O}   # HellO, WOrld!

# Удаление
echo ${STR//o/}    # Hell, Wrld!

# Замена в начале
echo ${STR/#Hello/Hi}  # Hi, World!

# Замена в конце
echo ${STR/%World!/Universe!}  # Hello, Universe!
```

### Удаление подстроки

```bash
FILE="document.txt"

# Удалить самое короткое совпадение с начала
echo ${FILE#*.}     # txt

# Удалить самое длинное совпадение с начала
echo ${FILE##*.}    # txt

# Удалить самое короткое совпадение с конца
echo ${FILE%.*}     # document

# Удалить самое длинное совпадение с конца
echo ${FILE%%.*}    # document
```

### Регистр

```bash
STR="Hello World"

# В верхний регистр
echo ${STR^^}       # HELLO WORLD

# В нижний регистр
echo ${STR,,}       # hello world

# Первая буква в верхний
echo ${STR^}        # Hello World

# Первая буква в нижний
echo ${STR,}        # hello World

# Альтернативные методы
echo "$STR" | tr '[:lower:]' '[:upper:]'  # HELLO WORLD
echo "$STR" | awk '{print toupper($0)}'   # HELLO WORLD
```

### Разделение строк

```bash
# Разделение по разделителю
STR="one,two,three"
IFS=',' read -ra ARRAY <<< "$STR"

for item in "${ARRAY[@]}"; do
    echo "$item"
done

# Разделение по пробелам
STR="one two three"
read -ra ARRAY <<< "$STR"
```

### Объединение строк

```bash
# Конкатенация
STR1="Hello"
STR2="World"
RESULT="$STR1, $STR2!"  # Hello, World!

# Объединение массива
ARRAY=("one" "two" "three")
IFS=','
JOINED="${ARRAY[*]}"  # one,two,three
```

### Сравнение строк

```bash
if [ "$str1" = "$str2" ]; then
    echo "Равны"
fi

if [ "$str1" != "$str2" ]; then
    echo "Не равны"
fi

# Современный синтаксис с поддержкой паттернов
if [[ "$str" == pattern* ]]; then
    echo "Начинается с pattern"
fi

if [[ "$str" =~ ^[0-9]+$ ]]; then
    echo "Только цифры (regex)"
fi
```

---

## Обработка ошибок

### Exit коды

```bash
# Успешное завершение
exit 0

# Ошибка
exit 1

# Код последней команды
ls /nonexistent
echo $?  # 2 (код ошибки ls)

# Проверка успешности
if command; then
    echo "Успешно"
else
    echo "Ошибка"
fi
```

### Set опции

```bash
# Строгий режим (рекомендуется)
set -euo pipefail

# -e: выход при ошибке любой команды
# -u: ошибка при использовании неустановленной переменной
# -o pipefail: ошибка в любой команде pipeline

# Пример
set -e
command1
command2  # Если упадёт, скрипт остановится
command3  # Не выполнится

# Отключение для конкретной команды
command || true  # Игнорировать ошибку
```

### Trap - обработка сигналов

```bash
# Cleanup функция
cleanup() {
    echo "Cleaning up..."
    rm -f /tmp/tempfile
    exit
}

# Вызвать cleanup при выходе
trap cleanup EXIT

# При ошибке
trap 'echo "Error on line $LINENO"' ERR

# При Ctrl+C
trap 'echo "Interrupted"; exit 130' INT SIGINT

# Пример с temporary файлами
TEMPFILE=$(mktemp)
trap "rm -f $TEMPFILE" EXIT

echo "Working with $TEMPFILE"
# ... работа ...
# Файл будет удалён автоматически при выходе
```

### Проверка команд

```bash
# Проверить существование команды
if command -v docker &> /dev/null; then
    echo "Docker установлен"
else
    echo "Docker не найден"
    exit 1
fi

# Альтернатива
if ! command -v git &> /dev/null; then
    echo "Git требуется для работы скрипта"
    exit 1
fi
```

### Try-Catch эмуляция

```bash
# Bash не имеет try-catch, но можно эмулировать

try() {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        return $status
    fi
}

catch() {
    return $?
}

# Использование
if try command_that_might_fail; then
    echo "Success"
else
    echo "Failed with code: $?"
fi
```

### Логирование ошибок

```bash
# Функция для логирования
log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

# Использование
if ! some_command; then
    log_error "Command failed"
    exit 1
fi

log_info "Operation completed successfully"
```

---

## Аргументы командной строки

### Базовая обработка

```bash
#!/bin/bash

# Позиционные аргументы
echo "Script: $0"
echo "First arg: $1"
echo "Second arg: $2"
echo "All args: $@"
echo "Number of args: $#"

# Пример использования
# ./script.sh arg1 arg2
```

### Getopts - короткие опции

```bash
#!/bin/bash

# Парсинг опций -a -b value -c
while getopts "ab:c:" opt; do
    case $opt in
        a)
            echo "Option -a"
            ;;
        b)
            echo "Option -b with value: $OPTARG"
            ;;
        c)
            echo "Option -c with value: $OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            exit 1
            ;;
    esac
done

# Сдвинуть аргументы (убрать обработанные опции)
shift $((OPTIND-1))

# Оставшиеся аргументы
echo "Remaining args: $@"
```

### Длинные опции (manual parsing)

```bash
#!/bin/bash

# Парсинг --option=value и --flag
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        --output=*)
            OUTPUT="${1#*=}"
            shift
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            # Позиционный аргумент
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# Восстановить позиционные аргументы
set -- "${POSITIONAL[@]}"

echo "Verbose: ${VERBOSE:-0}"
echo "File: ${FILE:-none}"
echo "Output: ${OUTPUT:-none}"
echo "Positional: $@"
```

### Полный пример с help

```bash
#!/bin/bash

usage() {
    cat <<EOF
Usage: $0 [OPTIONS] FILE

Options:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -o, --output FILE   Output file (default: stdout)
    -n, --dry-run       Dry run mode
    -c, --config FILE   Configuration file

Examples:
    $0 -v -o output.txt input.txt
    $0 --config=app.conf --dry-run file.txt

EOF
    exit 0
}

# Значения по умолчанию
VERBOSE=0
DRY_RUN=0
OUTPUT="/dev/stdout"
CONFIG=""

# Парсинг
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help) usage ;;
        -v|--verbose) VERBOSE=1; shift ;;
        -n|--dry-run) DRY_RUN=1; shift ;;
        -o|--output) OUTPUT="$2"; shift 2 ;;
        -c|--config) CONFIG="$2"; shift 2 ;;
        --config=*) CONFIG="${1#*=}"; shift ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) FILE="$1"; shift ;;
    esac
done

# Проверка обязательных параметров
if [ -z "$FILE" ]; then
    echo "Error: FILE is required"
    usage
fi

# Логика скрипта
[ $VERBOSE -eq 1 ] && echo "Processing $FILE..."
[ $DRY_RUN -eq 1 ] && echo "[DRY RUN MODE]"
```

---

## Регулярные выражения

### Grep

```bash
# Поиск паттерна в файле
grep "pattern" file.txt

# Игнорировать регистр
grep -i "pattern" file.txt

# Инвертировать (строки БЕЗ паттерна)
grep -v "pattern" file.txt

# Рекурсивный поиск
grep -r "pattern" directory/

# Показать только имена файлов
grep -l "pattern" *.txt

# С номерами строк
grep -n "pattern" file.txt

# Extended regex
grep -E "pattern1|pattern2" file.txt

# Perl regex
grep -P "\d{3}-\d{4}" file.txt
```

### Sed - потоковый редактор

```bash
# Замена (первое вхождение)
sed 's/old/new/' file.txt

# Замена (все вхождения в строке)
sed 's/old/new/g' file.txt

# Замена с записью в файл
sed -i 's/old/new/g' file.txt

# Backup перед изменением
sed -i.bak 's/old/new/g' file.txt

# Удаление строк
sed '/pattern/d' file.txt

# Удаление пустых строк
sed '/^$/d' file.txt

# Вставка текста после паттерна
sed '/pattern/a\New line' file.txt

# Извлечение строк
sed -n '5,10p' file.txt  # Строки 5-10

# Множественные команды
sed -e 's/old1/new1/g' -e 's/old2/new2/g' file.txt
```

### Awk

```bash
# Вывести столбцы
awk '{print $1, $3}' file.txt

# С разделителем
awk -F: '{print $1}' /etc/passwd

# Условие
awk '$3 > 100 {print $1}' file.txt

# Сумма столбца
awk '{sum += $1} END {print sum}' file.txt

# Форматированный вывод
awk '{printf "%-10s %5d\n", $1, $2}' file.txt

# Встроенные переменные
awk '{print NR, NF, $0}' file.txt  # NR=номер строки, NF=число полей
```

### Regex в Bash

```bash
# =~ оператор для regex
if [[ "$string" =~ ^[0-9]+$ ]]; then
    echo "Только цифры"
fi

# Email validation
EMAIL="user@example.com"
if [[ "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "Valid email"
fi

# Извлечение групп
if [[ "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    MAJOR="${BASH_REMATCH[1]}"
    MINOR="${BASH_REMATCH[2]}"
    PATCH="${BASH_REMATCH[3]}"
fi

# IP адрес
if [[ "$IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    echo "Valid IP format"
fi
```

---

## Отладка

### Debug опции

```bash
# -x: печатать команды перед выполнением
bash -x script.sh

# В скрипте
set -x  # Включить
set +x  # Выключить

# Только для части кода
set -x
# ... код для отладки ...
set +x

# -v: печатать строки скрипта
set -v

# -n: проверка синтаксиса без выполнения
bash -n script.sh
```

### Отладочный вывод

```bash
# Debug функция
DEBUG=${DEBUG:-0}

debug() {
    if [ $DEBUG -eq 1 ]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Использование
debug "Variable value: $VAR"

# Запуск с debug
DEBUG=1 ./script.sh
```

### Проверка переменных

```bash
# Вывести все переменные
set

# Только экспортированные
env

# Только функции
declare -F

# Трассировка выполнения
PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
set -x
```

### ShellCheck

```bash
# Установка
# Ubuntu/Debian
sudo apt install shellcheck

# macOS
brew install shellcheck

# Проверка скрипта
shellcheck script.sh

# С подробным выводом
shellcheck -f gcc script.sh

# Игнорирование предупреждения
# shellcheck disable=SC2086
echo $VAR
```

---

## Best Practices

### 1. Строгий режим

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
```

### 2. Использование кавычек

```bash
# ПЛОХО
echo $VAR
rm -rf $DIR/*

# ХОРОШО
echo "$VAR"
rm -rf "${DIR:?}/"*
```

### 3. Проверка аргументов

```bash
if [ $# -lt 1 ]; then
    echo "Usage: $0 <argument>"
    exit 1
fi

# Проверка существования файла
FILE="${1:?Error: File argument required}"
if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found"
    exit 1
fi
```

### 4. Используйте функции

```bash
# Вместо дублирования кода
check_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo "Error: $file not found" >&2
        exit 1
    fi
}

check_file "$CONFIG"
check_file "$INPUT"
```

### 5. Константы в верхнем регистре

```bash
readonly MAX_RETRIES=3
readonly TIMEOUT=30
readonly CONFIG_DIR="/etc/myapp"
```

### 6. Локальные переменные в функциях

```bash
process_file() {
    local file="$1"
    local result

    result=$(do_something "$file")
    echo "$result"
}
```

### 7. Безопасное удаление

```bash
# ОПАСНО
rm -rf $DIR/*

# БЕЗОПАСНО
if [ -n "${DIR:-}" ] && [ -d "$DIR" ]; then
    rm -rf "${DIR:?}"/*
fi
```

### 8. Временные файлы

```bash
# Создание безопасного temp файла
TMPFILE=$(mktemp)
trap "rm -f $TMPFILE" EXIT

echo "data" > "$TMPFILE"
# ... работа ...
# Файл будет удалён автоматически
```

### 9. Читаемость

```bash
# Длинные команды - разбивать на строки
docker run \
    --name myapp \
    --restart always \
    -p 8080:8080 \
    -v /data:/data \
    myapp:latest

# Комментарии
# Проверяем существование пользователя перед созданием
if ! id -u "$USERNAME" &> /dev/null; then
    useradd "$USERNAME"
fi
```

### 10. Обработка сигналов

```bash
cleanup() {
    echo "Cleaning up..."
    # Остановка процессов
    # Удаление temp файлов
    exit
}

trap cleanup EXIT INT TERM
```

---

## Безопасность

### 1. Избегайте eval

```bash
# ОПАСНО
eval "$user_input"

# БЕЗОПАСНО
# Используйте массивы и "$@"
```

### 2. Валидация ввода

```bash
sanitize_input() {
    local input="$1"
    # Разрешить только буквы, цифры, дефис
    if [[ ! "$input" =~ ^[a-zA-Z0-9-]+$ ]]; then
        echo "Invalid input" >&2
        exit 1
    fi
    echo "$input"
}

USERNAME=$(sanitize_input "$1")
```

### 3. Безопасная работа с паролями

```bash
# Не хранить пароли в коде
# Использовать переменные окружения или файлы с правами 600

# Чтение пароля без echo
read -s -p "Password: " PASSWORD
echo

# Или из файла
PASSWORD=$(cat /secure/password.txt)
chmod 600 /secure/password.txt
```

### 4. Проверка команд

```bash
# Использовать абсолютные пути для критичных команд
GREP=/bin/grep
RM=/bin/rm

$GREP "pattern" file
$RM -f tempfile
```

### 5. Защита от injection

```bash
# ОПАСНО
mysql -u root -p$PASSWORD -e "$QUERY"

# ЛУЧШЕ
mysql -u root -p"$PASSWORD" -e "$QUERY"

# ЕЩЁ ЛУЧШЕ - использовать конфигурацию
mysql --defaults-file=/secure/my.cnf -e "$QUERY"
```

### 6. Umask для безопасности файлов

```bash
# Установить umask для ограничения прав по умолчанию
umask 077  # Файлы: 600, Директории: 700

# Создание файла с конкретными правами
install -m 600 /dev/null secure_file
```

### 7. Логирование без секретов

```bash
# ПЛОХО
log "Connecting with password: $PASSWORD"

# ХОРОШО
log "Connecting to database..."

# Маскирование
masked_pass="${PASSWORD:0:2}***"
log "Using password: $masked_pass"
```

---

## Примеры из реальной жизни

См. директорию `examples/real-world/` для полных примеров:

- `backup-script.sh` - Скрипт резервного копирования с ротацией
- `deployment-script.sh` - Автоматизация деплоя приложения
- `log-analyzer.sh` - Анализ логов с отчётами
- `system-monitor.sh` - Мониторинг системы с алертами

---

## Полезные ресурсы

- [Bash Manual](https://www.gnu.org/software/bash/manual/)
- [ShellCheck](https://www.shellcheck.net/) - Линтер для shell скриптов
- [Bash Guide](https://mywiki.wooledge.org/BashGuide)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

---

## Шпаргалка

```bash
# Переменные
VAR="value"
readonly CONST="constant"
local LOCAL_VAR="local"

# Условия
if [ condition ]; then ... fi
if [[ condition ]]; then ... fi  # Предпочтительнее

# Циклы
for i in {1..10}; do ... done
while [ condition ]; do ... done
until [ condition ]; do ... done

# Функции
function_name() { ... }

# Массивы
ARRAY=("a" "b" "c")
echo "${ARRAY[@]}"
echo "${#ARRAY[@]}"

# Строки
${#STR}              # длина
${STR:pos:len}       # подстрока
${STR//old/new}      # замена
${STR^^}             # верхний регистр
${STR,,}             # нижний регистр

# Файлы
[ -f file ]          # файл существует
[ -d dir ]           # директория существует
[ -r file ]          # читаемый
[ -w file ]          # записываемый
[ -x file ]          # исполняемый

# Обработка ошибок
set -euo pipefail
trap cleanup EXIT
command || true

# Отладка
set -x               # trace mode
bash -x script.sh    # run in trace mode
shellcheck script.sh # lint
```
