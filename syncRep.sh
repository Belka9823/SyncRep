#!/bin/bash

# Настройка кодировки (на всякий случай для вывода в консоль)
export LANG=en_US.UTF-8

# Папка для временной работы
WORK_DIR="$HOME/git_sync_temp"
mkdir -p "$WORK_DIR"

echo -e "\e[36m--- СКРИПТ СИНХРОНИЗАЦИИ РЕПОЗИТОРИЕВ (BASH) ---\e[0m"

# 1. Запрос ссылок
read -p "Введите URL репозитория преподавателя: " SOURCE_URL
read -p "Введите URL вашего репозитория: " MY_URL

# Вырезаем названия папок из ссылок для локальных путей
SOURCE_NAME=$(basename "$SOURCE_URL" .git)
MY_NAME=$(basename "$MY_URL" .git)

SOURCE_PATH="$WORK_DIR/$SOURCE_NAME"
MY_PATH="$WORK_DIR/$MY_NAME"

# Функция для подготовки репозитория
get_repo() {
    local url=$1
    local path=$2
    if [ -d "$path/.git" ]; then
        echo "-> Обновляю существующую папку: $path"
        cd "$path" && git pull
    else
        echo "-> Клонирую новый репозиторий: $path"
        git clone "$url" "$path"
    fi
}

echo -e "\n\e[33m[ШАГ 1] Подготовка локальных копий...\e[0m"
get_repo "$SOURCE_URL" "$SOURCE_PATH"
get_repo "$MY_URL" "$MY_PATH"

# 2. Синхронизация через rsync
echo -e "\n\e[33m[ШАГ 2] Зеркальное копирование файлов...\e[0m"
# --archive: сохраняет права доступа
# --delete: удаляет в твоем репо то, что удалил препод (настоящее зеркало)
# --exclude: игнорим папку гита
rsync -av --delete --exclude='.git' "$SOURCE_PATH/" "$MY_PATH/"

# 3. Проверка изменений и Push
echo -e "\n\e[33m[ШАГ 3] Проверка изменений и Push...\e[0m"
cd "$MY_PATH" || exit

if [[ -n $(git status --porcelain) ]]; then
    TIMESTAMP=$(date +"%d.%m.%Y %H:%M")
    git add .
    git commit -m "Синхронизация с исходником | $TIMESTAMP"
    git push
    echo -e "\e[32m✅ УСПЕХ: Все изменения отправлены!\e[0m"
else
    echo -e "\e[37mℹ️ Изменений не найдено, пушить нечего.\e[0m"
fi

echo -e "\nСинхронизация завершена. Нажмите Enter, чтобы выйти..."
read -r
