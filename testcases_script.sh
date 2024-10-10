#!/bin/bash

# путь к директории для виртуальных дисков и к самому виртуальному диску
VIRTUAL_DISK="$HOME/virtual_disk.img"
MOUNT_POINT="$HOME/mount_point"

# создание файла виртуального диска 1 гб
dd if=/dev/zero of="$VIRTUAL_DISK" bs=1M count=1024

# создаем файловую систему ext4 на виртуальном диске
mkfs.ext4 "$VIRTUAL_DISK"

# создаем папку для монтирования, если она не существует
mkdir -p "$MOUNT_POINT"

# монтируем виртуальный диск
sudo mount -o loop "$VIRTUAL_DISK" "$MOUNT_POINT"

# даем права 777 на точку монтирования. 
# права 777 на файл или директорию позволяет 
# любому пользователю на системе читать, записывать и выполнять файл.
sudo chmod -R 777 "$MOUNT_POINT"

# создаем папку log на новом разделе
mkdir -p "$MOUNT_POINT/log"
# создаём папку backup
mkdir -p "$HOME/backup"

# Выводим сообщение о завершении
echo "Виртуальный диск смонтирован в $MOUNT_POINT. Папка 'log' создана."

function generate_files() {
    local files_counter=$1
    local target_dir=$2

    # Проверка, существует ли директория
    if [ -d "$target_dir" ]; then
        echo "Генерация файлов по 25 Мб для теста: $files_counter шт."

        for i in $(seq 1 "$files_counter"); do
            # Генерация файлов
            dd if=/dev/zero of="$target_dir/file_$i" bs=1M count=25 status=none
            # Задержка для изменения времени модификации
            sleep 0.1
        done
    fi
} 


function testcase()
{
    local LOG_DIR=$1
    local BACKUP_DIR=$2
    local THRESHOLD=$3
    local N=$4
    local FILES_COUNTER=$5
    echo "Начало теста. Порог: $THRESHOLD%, удалению подлежат файлы: $N шт."
    generate_files "$FILES_COUNTER" "$LOG_DIR"
    ./archieve_script.sh "$LOG_DIR" "$BACKUP_DIR" "$THRESHOLD" "$N"

    rm -rf "$LOG_DIR"/*

    if [ -d "$BACKUP_DIR" ]; then
        rm -rf "$BACKUP_DIR"/*
    else 
        LAST_DIR=$(basename "$$BACKUP_DIR")
        BACKUP_DIR="$HOME/$LAST_DIR"
        rm -rf "$BACKUP_DIR"/*
    fi
    echo "Тест завершён."
}

#тест 1. порог - 50%, удаляем 10 файлов, создаём 30 файлов по 25 мб (750 мб)
testcase "$MOUNT_POINT/log" "$HOME/backup" 50 10 30

#тест 2. порог - 50%, удаляем 10 файлов, создаём 10 файлов по 25 мб (250 мб), 
testcase "$MOUNT_POINT/log" "$HOME/backup" 50 10 10

#тест 3. порог - 50%, удаляем 10 файлов, создаём 30 файлов по 25 мб (250 мб), директория backup_dir не существует
testcase "$MOUNT_POINT/log" "$HOME/backup1" 50 10 30

#тест 4. порог - 50%, удаляем 10 файлов, создаём 30 файлов по 25 мб (250 мб), директория log_dir не существует
testcase "$MOUNT_POINT/log1" "$HOME/backup" 50 10 30

# Размонтируем виртуальный диск
sudo umount "$MOUNT_POINT"

# Удаляем точку монтирования
rmdir "$MOUNT_POINT"

# Удаляем файл виртуального диска
rm -f "$VIRTUAL_DISK"

echo "Виртуальный диск размонтирован, папка удалена, файл диска удалён."