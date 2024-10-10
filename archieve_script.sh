#!/bin/bash

# проверка существования директорий
check_directories_exist() {
    if [ ! -d "$1" ]; then
            echo "Ошибка: директория $1 не существует."
            exit 1
    fi
}

# путь к папке, путь архивации, порог заполнения и число файлов, подлежащих архивации
LOG_DIR=$1
BACKUP_DIR=$2
THRESHOLD=$3
N=$4

check_directories_exist "$LOG_DIR"

# узнаем размер раздела, на котором находится LOG_DIR, и его использование
USAGE=$(df "$LOG_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')

# проверка заполненности раздела
if [ "$USAGE" -ge "$THRESHOLD" ]; then

  echo "Папка $LOG_DIR заполнена на $USAGE%, порог $THRESHOLD% достигнут. Требуется очистка."

  # получаем список N самых старых файлов
  mapfile -t FILES_TO_ARCHIVE < <(find "$LOG_DIR" -type f -printf "%T@ %p\n" | sort -n | head -n "$N" | awk '{print $2}')

  if [ ${#FILES_TO_ARCHIVE[@]} -eq 0 ]; then
    echo "Нет файлов для архивации."
    exit 0
  fi

  # выведем его на экран
  for file in "${FILES_TO_ARCHIVE[@]}"; do
        echo "Файл $file подлежит архивации."
    done

  if [ ! -d "$BACKUP_DIR" ]; then
    LAST_DIR=$(basename "$BACKUP_DIR")
    echo "Создание директории $HOME/$LAST_DIR..."
    mkdir -p "$HOME/$LAST_DIR"
    BACKUP_DIR="$HOME/$LAST_DIR"
  fi

  # Создаем архив с точной датой и временем
  DATE=$(date +"%Y-%m-%d_%H-%M-%S")
  echo "Архивация..."
  tar -czf "$BACKUP_DIR/archive_$DATE.tar.gz" -C "$LOG_DIR" $FILES_TO_ARCHIVE
  echo "Архивация завершена. Удаление файлов..."

  for FILE in "${FILES_TO_ARCHIVE[@]}"; do
    BASE_FILE=$(basename "$FILE")  # Получаем только имя файла
    rm "$LOG_DIR/$BASE_FILE"        # Удаляем файл из логов
  done

  echo "Удаление файлов завершено."
  
else
  echo "Папка $LOG_DIR еще не достигла порога $THRESHOLD%."
fi