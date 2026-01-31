#!/bin/bash
#
# Операции с файлами
#

set -euo pipefail

# Рабочая директория для примеров
WORK_DIR="/tmp/bash_file_ops_$$"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "Рабочая директория: $WORK_DIR"

echo -e "\n=== Создание файлов ==="
# Простое создание
touch file1.txt
echo "Создан: file1.txt"

# Создание с содержимым
echo "Hello, World!" > file2.txt
echo "Создан: file2.txt с содержимым"

# Многострочное содержимое
cat > file3.txt <<EOF
Line 1
Line 2
Line 3
EOF
echo "Создан: file3.txt с несколькими строками"

echo -e "\n=== Чтение файлов ==="
# Построчное чтение
echo "Содержимое file3.txt:"
while IFS= read -r line; do
    echo "  $line"
done < file3.txt

# Весь файл в переменную
CONTENT=$(<file2.txt)
echo "file2.txt содержит: $CONTENT"

# В массив
mapfile -t LINES < file3.txt
echo "Строк в file3.txt: ${#LINES[@]}"

echo -e "\n=== Запись в файлы ==="
# Перезапись
echo "New content" > file1.txt

# Добавление
echo "Additional line" >> file1.txt
echo "Another line" >> file1.txt

echo "file1.txt после записи:"
cat file1.txt

echo -e "\n=== Проверка существования ==="
if [ -e "file1.txt" ]; then
    echo "file1.txt существует"
fi

if [ -f "file1.txt" ]; then
    echo "file1.txt - обычный файл"
fi

if [ ! -e "nonexistent.txt" ]; then
    echo "nonexistent.txt не существует"
fi

echo -e "\n=== Проверка прав доступа ==="
chmod 644 file1.txt

if [ -r "file1.txt" ]; then echo "file1.txt - читаемый"; fi
if [ -w "file1.txt" ]; then echo "file1.txt - записываемый"; fi

chmod +x file1.txt
if [ -x "file1.txt" ]; then echo "file1.txt - исполняемый"; fi

echo -e "\n=== Размер файла ==="
if [ -s "file1.txt" ]; then
    SIZE=$(stat -f%z "file1.txt" 2>/dev/null || stat -c%s "file1.txt")
    echo "file1.txt не пуст (размер: $SIZE байт)"
fi

echo -e "\n=== Работа с путями ==="
FULLPATH="/home/user/documents/file.txt"

BASENAME=$(basename "$FULLPATH")
DIRNAME=$(dirname "$FULLPATH")
EXTENSION="${BASENAME##*.}"
FILENAME="${BASENAME%.*}"

echo "Full path: $FULLPATH"
echo "Basename: $BASENAME"
echo "Dirname: $DIRNAME"
echo "Extension: $EXTENSION"
echo "Filename without extension: $FILENAME"

echo -e "\n=== Копирование ==="
cp file1.txt file1_backup.txt
echo "Скопирован file1.txt -> file1_backup.txt"

# Копирование директории
mkdir -p source_dir
echo "test" > source_dir/test.txt
cp -r source_dir dest_dir
echo "Скопирована директория source_dir -> dest_dir"

echo -e "\n=== Перемещение/переименование ==="
mv file2.txt file2_renamed.txt
echo "Переименован file2.txt -> file2_renamed.txt"

echo -e "\n=== Поиск файлов ==="
# Создадим несколько файлов для поиска
touch test1.txt test2.txt test.log

echo "Текстовые файлы:"
find . -name "*.txt" -type f

echo -e "\nФайлы, изменённые за последние 5 минут:"
find . -type f -mmin -5

echo -e "\n=== Обработка всех файлов в директории ==="
for file in *.txt; do
    if [ -f "$file" ]; then
        echo "Обработка: $file"
        # Добавим метку времени
        echo "Processed: $(date)" >> "$file"
    fi
done

echo -e "\n=== Временные файлы ==="
# Безопасное создание temp файла
TMPFILE=$(mktemp)
echo "Temporary file: $TMPFILE"
echo "temp data" > "$TMPFILE"
cat "$TMPFILE"
rm "$TMPFILE"

# Temp директория
TMPDIR=$(mktemp -d)
echo "Temporary directory: $TMPDIR"
rmdir "$TMPDIR"

echo -e "\n=== Архивирование ==="
# Создать архив
tar -czf archive.tar.gz *.txt
echo "Создан архив: archive.tar.gz"

# Просмотр содержимого
echo "Содержимое архива:"
tar -tzf archive.tar.gz | head -5

echo -e "\n=== Удаление ==="
# Удаление файла
rm -f file3.txt
echo "Удалён file3.txt"

# Удаление директории
rm -rf source_dir
echo "Удалена директория source_dir"

echo -e "\n=== Перенаправление ввода/вывода ==="
# Stdout в файл
echo "Standard output" > stdout.txt

# Stderr в файл
ls /nonexistent 2> stderr.txt

# Оба потока
ls /nonexistent &> combined.txt

# Добавление
echo "Line 1" > output.txt
echo "Line 2" >> output.txt
echo "Line 3" >> output.txt

echo "output.txt:"
cat output.txt

echo -e "\n=== Сравнение файлов ==="
echo "Version 1" > version1.txt
echo "Version 2" > version2.txt

if ! diff -q version1.txt version2.txt &>/dev/null; then
    echo "Файлы различаются"
fi

# Cleanup
cd /
rm -rf "$WORK_DIR"
echo -e "\nCleanup: удалена рабочая директория $WORK_DIR"
