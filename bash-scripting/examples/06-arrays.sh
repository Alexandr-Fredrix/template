#!/bin/bash
#
# Массивы в Bash
#

set -euo pipefail

echo "=== Создание массива ==="
# Метод 1
FRUITS=("apple" "banana" "cherry")

# Метод 2
NUMBERS[0]=10
NUMBERS[1]=20
NUMBERS[2]=30

echo "Fruits: ${FRUITS[@]}"
echo "Numbers: ${NUMBERS[@]}"

echo -e "\n=== Доступ к элементам ==="
echo "First fruit: ${FRUITS[0]}"
echo "Second fruit: ${FRUITS[1]}"
echo "Third fruit: ${FRUITS[2]}"

echo -e "\n=== Все элементы ==="
echo "All fruits: ${FRUITS[@]}"
echo "All fruits (quoted): ${FRUITS[*]}"

echo -e "\n=== Длина массива ==="
echo "Number of fruits: ${#FRUITS[@]}"
echo "Number of numbers: ${#NUMBERS[@]}"

echo -e "\n=== Индексы массива ==="
echo "Fruit indices: ${!FRUITS[@]}"

echo -e "\n=== Добавление элементов ==="
FRUITS+=("date")
FRUITS+=("elderberry")
echo "Updated fruits: ${FRUITS[@]}"
echo "Count: ${#FRUITS[@]}"

echo -e "\n=== Удаление элементов ==="
unset FRUITS[1]
echo "After removing index 1: ${FRUITS[@]}"
echo "Indices: ${!FRUITS[@]}"  # Индекс 1 пропущен

echo -e "\n=== Срезы массива ==="
LETTERS=("a" "b" "c" "d" "e")
echo "All: ${LETTERS[@]}"
echo "From index 1: ${LETTERS[@]:1}"
echo "From index 1, length 2: ${LETTERS[@]:1:2}"
echo "Last 2: ${LETTERS[@]: -2}"

echo -e "\n=== Цикл по массиву ==="
echo "Итерация по фруктам:"
for fruit in "${FRUITS[@]}"; do
    echo "  - $fruit"
done

echo -e "\n=== Цикл с индексами ==="
echo "Фрукты с индексами:"
for i in "${!FRUITS[@]}"; do
    echo "  Index $i: ${FRUITS[$i]}"
done

echo -e "\n=== Массив из вывода команды ==="
# mapfile или readarray
mapfile -t FILES < <(ls -1 /etc/*.conf 2>/dev/null | head -3)
echo "Найдено ${#FILES[@]} конфиг файлов:"
for file in "${FILES[@]}"; do
    echo "  - $file"
done

echo -e "\n=== Сортировка массива ==="
UNSORTED=(5 2 8 1 9)
echo "Unsorted: ${UNSORTED[@]}"

# Сортировка через IFS
IFS=$'\n' SORTED=($(sort -n <<<"${UNSORTED[*]}"))
unset IFS

echo "Sorted: ${SORTED[@]}"

echo -e "\n=== Поиск в массиве ==="
COLORS=("red" "green" "blue" "yellow")
SEARCH="blue"

found=0
for color in "${COLORS[@]}"; do
    if [ "$color" = "$SEARCH" ]; then
        found=1
        break
    fi
done

if [ $found -eq 1 ]; then
    echo "Found: $SEARCH"
else
    echo "Not found: $SEARCH"
fi

echo -e "\n=== Ассоциативные массивы (словари) ==="
declare -A PERSON

PERSON["name"]="John Doe"
PERSON["age"]="30"
PERSON["city"]="New York"

echo "Name: ${PERSON["name"]}"
echo "Age: ${PERSON["age"]}"
echo "City: ${PERSON["city"]}"

echo -e "\n=== Все ключи и значения ==="
echo "Keys: ${!PERSON[@]}"
echo "Values: ${PERSON[@]}"

echo -e "\n=== Итерация по словарю ==="
for key in "${!PERSON[@]}"; do
    echo "$key: ${PERSON[$key]}"
done

echo -e "\n=== Проверка существования ключа ==="
if [ -n "${PERSON[name]+x}" ]; then
    echo "Ключ 'name' существует"
fi

if [ -z "${PERSON[email]+x}" ]; then
    echo "Ключ 'email' не существует"
fi

echo -e "\n=== Объединение массивов ==="
ARR1=("a" "b" "c")
ARR2=("d" "e" "f")
COMBINED=("${ARR1[@]}" "${ARR2[@]}")
echo "Combined: ${COMBINED[@]}"

echo -e "\n=== Копирование массива ==="
ORIGINAL=("one" "two" "three")
COPY=("${ORIGINAL[@]}")
echo "Copy: ${COPY[@]}"

echo -e "\n=== Многомерный массив (эмуляция) ==="
declare -A MATRIX

MATRIX["0,0"]="a"
MATRIX["0,1"]="b"
MATRIX["0,2"]="c"
MATRIX["1,0"]="d"
MATRIX["1,1"]="e"
MATRIX["1,2"]="f"

echo "Matrix[0,0]: ${MATRIX["0,0"]}"
echo "Matrix[1,1]: ${MATRIX["1,1"]}"

echo -e "\nВывод матрицы:"
for i in 0 1; do
    for j in 0 1 2; do
        echo -n "${MATRIX["$i,$j"]} "
    done
    echo
done
