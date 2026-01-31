#!/bin/bash
#
# Функции в Bash
#

set -euo pipefail

echo "=== Простая функция ==="
greet() {
    echo "Hello, World!"
}

greet

echo -e "\n=== Функция с аргументами ==="
greet_person() {
    local name="$1"
    echo "Hello, $name!"
}

greet_person "Alice"
greet_person "Bob"

echo -e "\n=== Функция с возвратом значения ==="
add() {
    local a=$1
    local b=$2
    echo $((a + b))
}

result=$(add 10 20)
echo "10 + 20 = $result"

echo -e "\n=== Функция с return кодом ==="
is_even() {
    local num=$1
    if [ $((num % 2)) -eq 0 ]; then
        return 0  # успех
    else
        return 1  # неудача
    fi
}

if is_even 4; then
    echo "4 - чётное"
fi

if ! is_even 5; then
    echo "5 - нечётное"
fi

echo -e "\n=== Функция с локальными переменными ==="
test_scope() {
    local local_var="Я локальная"
    global_var="Я глобальная"

    echo "Внутри функции:"
    echo "  Local: $local_var"
    echo "  Global: $global_var"
}

test_scope
echo "Вне функции:"
# echo "  Local: $local_var"  # Ошибка!
echo "  Global: $global_var"

echo -e "\n=== Рекурсивная функция ==="
factorial() {
    local n=$1
    if [ $n -le 1 ]; then
        echo 1
    else
        local prev=$(factorial $((n - 1)))
        echo $((n * prev))
    fi
}

echo "5! = $(factorial 5)"

echo -e "\n=== Функция с множественными аргументами ==="
print_info() {
    echo "Количество аргументов: $#"
    echo "Все аргументы: $@"
    echo "Обработка аргументов:"
    local i=1
    for arg in "$@"; do
        echo "  Аргумент $i: $arg"
        ((i++))
    done
}

print_info one two three four

echo -e "\n=== Функция с опциями ==="
process_options() {
    local verbose=0
    local output=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                verbose=1
                shift
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            *)
                echo "Неизвестная опция: $1"
                return 1
                ;;
        esac
    done

    echo "Verbose: $verbose"
    echo "Output: ${output:-stdout}"
}

process_options -v --output file.txt
