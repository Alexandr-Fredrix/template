#!/bin/bash
#
# Циклы в Bash
#

set -euo pipefail

echo "=== For loop - список ==="
for item in apple banana cherry; do
    echo "Fruit: $item"
done

echo -e "\n=== For loop - диапазон ==="
for i in {1..5}; do
    echo "Number: $i"
done

echo -e "\n=== For loop - с шагом ==="
for i in {0..20..5}; do
    echo "Step 5: $i"
done

echo -e "\n=== C-style for ==="
for ((i=0; i<5; i++)); do
    echo "i = $i"
done

echo -e "\n=== For loop - файлы ==="
echo "Текстовые файлы в текущей директории:"
for file in *.txt 2>/dev/null; do
    if [ -f "$file" ]; then
        echo "  - $file"
    fi
done

echo -e "\n=== For loop - массив ==="
COLORS=("red" "green" "blue")
for color in "${COLORS[@]}"; do
    echo "Color: $color"
done

echo -e "\n=== While loop ==="
counter=1
while [ $counter -le 5 ]; do
    echo "Counter: $counter"
    ((counter++))
done

echo -e "\n=== While loop - чтение файла ==="
# Создаём временный файл для примера
cat > /tmp/example.txt <<EOF
Line 1
Line 2
Line 3
EOF

while IFS= read -r line; do
    echo "Read: $line"
done < /tmp/example.txt

rm /tmp/example.txt

echo -e "\n=== Until loop ==="
count=1
until [ $count -gt 5 ]; do
    echo "Count: $count"
    ((count++))
done

echo -e "\n=== Break ==="
echo "Цикл с break:"
for i in {1..10}; do
    if [ $i -eq 5 ]; then
        echo "Stopping at $i"
        break
    fi
    echo "i = $i"
done

echo -e "\n=== Continue ==="
echo "Пропуск чётных чисел:"
for i in {1..10}; do
    if [ $((i % 2)) -eq 0 ]; then
        continue
    fi
    echo "Odd: $i"
done

echo -e "\n=== Nested loops ==="
for i in {1..3}; do
    for j in {1..3}; do
        echo -n "$i,$j "
    done
    echo
done

echo -e "\n=== Loop с командами ==="
# Обработка вывода команды
ps aux | head -5 | while read line; do
    echo "Process: $line"
done

echo -e "\n=== Бесконечный цикл (прерывается по условию) ==="
count=0
while true; do
    ((count++))
    echo "Iteration: $count"

    if [ $count -ge 3 ]; then
        echo "Stopping infinite loop"
        break
    fi
done
