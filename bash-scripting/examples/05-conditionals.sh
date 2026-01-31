#!/bin/bash
#
# Условные операторы в Bash
#

set -euo pipefail

echo "=== Базовый if ==="
AGE=25

if [ $AGE -ge 18 ]; then
    echo "Совершеннолетний"
fi

echo -e "\n=== If-else ==="
SCORE=75

if [ $SCORE -ge 60 ]; then
    echo "Тест пройден"
else
    echo "Тест не пройден"
fi

echo -e "\n=== If-elif-else ==="
GRADE=85

if [ $GRADE -ge 90 ]; then
    echo "Отлично!"
elif [ $GRADE -ge 80 ]; then
    echo "Хорошо!"
elif [ $GRADE -ge 70 ]; then
    echo "Удовлетворительно"
else
    echo "Плохо"
fi

echo -e "\n=== Числовые сравнения ==="
A=10
B=20

[ $A -eq $B ] && echo "$A == $B" || echo "$A != $B"
[ $A -ne $B ] && echo "$A != $B"
[ $A -lt $B ] && echo "$A < $B"
[ $A -le $B ] && echo "$A <= $B"
[ $A -gt $B ] && echo "$A > $B" || echo "$A not > $B"
[ $A -ge $B ] && echo "$A >= $B" || echo "$A not >= $B"

echo -e "\n=== Строковые сравнения ==="
STR1="hello"
STR2="world"

if [ "$STR1" = "$STR2" ]; then
    echo "Строки равны"
else
    echo "Строки не равны"
fi

if [ -z "$STR1" ]; then
    echo "Строка пуста"
else
    echo "Строка не пуста: $STR1"
fi

if [ -n "$STR1" ]; then
    echo "Строка не пуста: $STR1"
fi

echo -e "\n=== Современный синтаксис [[]] ==="
NAME="Alice"

if [[ "$NAME" == "Alice" ]]; then
    echo "Привет, Alice!"
fi

# Паттерны
if [[ "$NAME" == A* ]]; then
    echo "Имя начинается с A"
fi

# Regex
if [[ "$NAME" =~ ^[A-Z][a-z]+$ ]]; then
    echo "Имя в правильном формате"
fi

echo -e "\n=== Проверка файлов ==="
# Создадим тестовый файл
TEST_FILE="/tmp/test_file.txt"
touch "$TEST_FILE"

if [ -e "$TEST_FILE" ]; then
    echo "Файл существует"
fi

if [ -f "$TEST_FILE" ]; then
    echo "Это обычный файл"
fi

if [ -r "$TEST_FILE" ]; then
    echo "Файл читаемый"
fi

if [ -w "$TEST_FILE" ]; then
    echo "Файл записываемый"
fi

if [ ! -s "$TEST_FILE" ]; then
    echo "Файл пуст"
fi

# Cleanup
rm "$TEST_FILE"

echo -e "\n=== Логические операторы ==="
X=5
Y=10

# AND
if [ $X -gt 0 ] && [ $Y -gt 0 ]; then
    echo "Оба числа положительные"
fi

# OR
if [ $X -eq 5 ] || [ $Y -eq 5 ]; then
    echo "Хотя бы одно число равно 5"
fi

# NOT
if [ ! $X -eq $Y ]; then
    echo "Числа не равны"
fi

# Комбинация
if [[ ($X -gt 0 && $Y -gt 0) || $X -eq 100 ]]; then
    echo "Сложное условие истинно"
fi

echo -e "\n=== Case statement ==="
COMMAND="start"

case $COMMAND in
    start)
        echo "Запуск сервиса..."
        ;;
    stop)
        echo "Остановка сервиса..."
        ;;
    restart)
        echo "Перезапуск сервиса..."
        ;;
    status)
        echo "Проверка статуса..."
        ;;
    *)
        echo "Неизвестная команда: $COMMAND"
        echo "Используйте: start|stop|restart|status"
        ;;
esac

echo -e "\n=== Case с паттернами ==="
FILENAME="document.pdf"

case $FILENAME in
    *.txt)
        echo "Текстовый файл"
        ;;
    *.pdf|*.doc)
        echo "Документ"
        ;;
    *.jpg|*.png|*.gif)
        echo "Изображение"
        ;;
    [A-Z]*)
        echo "Начинается с заглавной буквы"
        ;;
    *)
        echo "Неизвестный тип файла"
        ;;
esac

echo -e "\n=== Тернарный оператор (эмуляция) ==="
NUMBER=15
RESULT=$( [ $NUMBER -gt 10 ] && echo "big" || echo "small" )
echo "Number is: $RESULT"

echo -e "\n=== Короткие условия ==="
# Выполнить команду если успешна предыдущая
mkdir -p /tmp/test_dir && echo "Директория создана"

# Выполнить если неудача
ls /nonexistent 2>/dev/null || echo "Файл не найден"

# Cleanup
rmdir /tmp/test_dir
