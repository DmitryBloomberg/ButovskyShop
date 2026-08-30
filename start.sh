#!/bin/bash

# Скрипт для настройки токена бота и ID администратора

CONFIG_FILE="config.py"

# Проверяем, существует ли config.py, если нет — создаем из примера
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Файл $CONFIG_FILE не найден. Создаем из $CONFIG_FILE.example..."
    if [ -f "$CONFIG_FILE.example" ]; then
        cp "$CONFIG_FILE.example" "$CONFIG_FILE"
        echo "Файл $CONFIG_FILE создан."
    else
        echo "Ошибка: Файл $CONFIG_FILE.example не найден!"
        exit 1
    fi
fi

echo "=== Настройка бота ==="
echo ""

# Запрашиваем токен бота
read -p "Введите токен бота (получите у @BotFather): " BOT_TOKEN

if [ -z "$BOT_TOKEN" ]; then
    echo "Ошибка: Токен бота не может быть пустым!"
    exit 1
fi

# Запрашиваем ID администратора
read -p "Введите ваш Telegram ID администратора (число): " ADMIN_ID

if [ -z "$ADMIN_ID" ]; then
    echo "Ошибка: ID администратора не может быть пустым!"
    exit 1
fi

# Проверяем, что ADMIN_ID — число
if ! [[ "$ADMIN_ID" =~ ^[0-9]+$ ]]; then
    echo "Ошибка: ID администратора должен быть числом!"
    exit 1
fi

# Обновляем config.py с новыми значениями
echo "Сохраняем настройки в $CONFIG_FILE..."

# Создаем временный файл для записи
TEMP_FILE=$(mktemp)

# Записываем заголовок и обязательные настройки
cat > "$TEMP_FILE" << EOF
import os

# Telegram Bot API Token
# Получите у @BotFather
BOT_TOKEN = "$BOT_TOKEN"

# Список Telegram ID администраторов бота
ADMIN_IDS = [
    $ADMIN_ID,  # Ваш ID
]



################# Ниже необязательные настройки ################# 

# Адрес Telegram Bot API
# Стандартный: https://api.telegram.org
# Можно указать один кастомный адрес (прокси/зеркало), например: https://my-proxy.example.com
TELEGRAM_API_URL = "https://api.telegram.org"
#
# Если нужно несколько адресов, укажите список. Бот начнет с первого адреса и
# переключится на следующий только после сетевого сбоя текущего Telegram API:
# TELEGRAM_API_URL = [
#     "https://my-proxy-1.example.com",
#     "https://my-proxy-2.example.com",
#     "https://api.telegram.org",
# ]

# Ссылка на GitHub репозиторий для автообновления
# Формат: https://github.com/username/repo.git или git@github.com:username/repo.git
GITHUB_REPO_URL = "https://github.com/plushkinv/YadrenoVPN.git"  # Укажите URL вашего репозитория

# Client Configuration Defaults
DEFAULT_LIMIT_IP = 1  # Ограничение кол-ва одновременных подключений (1 ключ = 1 устройство)
DEFAULT_TOTAL_GB = 1024 * 1024 * 1024 * 1024  # 1 TB в байтах (лимит трафика на ключ)

# Rate Limiting Configuration
RATE_LIMITS = {
    "commands_per_minute": 30,              # Максимум команд для обычных пользователей
    "critical_operations_per_minute": 5,    # Лимит для критичных операций (платежи, создание ключей)
}

# Retry Configuration for API calls
RETRY_CONFIG = {
    "max_attempts": 3,      # Максимальное количество попыток
    "delays": [1, 3, 9],    # Задержки между попытками в секундах (экспоненциальная)
    "timeout_seconds": 15,  # Таймаут одной попытки обращения к VPN-панели
}

# SQLite Configuration
# Эти параметры нужны владельцу проекта для тонкой настройки БД.
# В админ-панели они не редактируются.
SQLITE_JOURNAL_MODE = "WAL"          # WAL повышает устойчивость при одновременном чтении и записи
SQLITE_SYNCHRONOUS = "NORMAL"        # Оптимальный режим для WAL: быстрее FULL, но без опасного OFF
SQLITE_BUSY_TIMEOUT_MS = 10000       # Сколько ждать освобождения БД при временной блокировке
SQLITE_CACHE_SIZE_KB = 32768         # Размер страничного кэша SQLite на подключение, в КБ
SQLITE_TEMP_STORE = "MEMORY"         # Временные таблицы и сортировки хранить в памяти
SQLITE_MMAP_SIZE_BYTES = 134217728   # Лимит memory-mapped I/O, 128 МБ
EOF

# Перемещаем временный файл в config.py
mv "$TEMP_FILE" "$CONFIG_FILE"

echo ""
echo "=== Настройки успешно сохранены! ==="
echo "Токен бота: $BOT_TOKEN"
echo "ID администратора: $ADMIN_ID"
echo ""
echo "Теперь вы можете запустить бота командой: python main.py"
