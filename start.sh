#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # Без цвета

echo -e "${GREEN}=== Скрипт настройки и запуска бота ===${NC}"

# Проверка наличия config.py
if [ ! -f "config.py" ]; then
    echo -e "${YELLOW}Файл config.py не найден. Создаем из config.py.example...${NC}"
    if [ -f "config.py.example" ]; then
        cp config.py.example config.py
        echo -e "${GREEN}Файл config.py создан.${NC}"
    else
        echo -e "${RED}Ошибка: Файл config.py.example не найден!${NC}"
        exit 1
    fi
fi

# Функция для запроса токена
get_bot_token() {
    while true; do
        read -p "Введите токен бота (получите у @BotFather): " token
        if [[ -n "$token" ]]; then
            echo "$token"
            return
        else
            echo -e "${RED}Токен не может быть пустым. Попробуйте снова.${NC}"
        fi
    done
}

# Функция для запроса ID админа
get_admin_id() {
    while true; do
        read -p "Введите ваш Telegram ID администратора (число): " admin_id
        if [[ "$admin_id" =~ ^[0-9]+$ ]]; then
            echo "$admin_id"
            return
        else
            echo -e "${RED}ID должен быть числом. Попробуйте снова.${NC}"
        fi
    done
}

echo -e "${GREEN}=== Настройка бота ===${NC}"

BOT_TOKEN=$(get_bot_token)
ADMIN_ID=$(get_admin_id)

echo -e "${GREEN}Сохраняем настройки в config.py...${NC}"

# Обновляем config.py, заменяя значения заглушек
# Используем временный файл для безопасности
TEMP_FILE=$(mktemp)

# Заменяем BOT_TOKEN и ADMIN_ID, сохраняя остальное содержимое
python3 -c "
import re
with open('config.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Замена токена
content = re.sub(r\"BOT_TOKEN\s*=\s*['\\\"].*?['\\\"]\", f\"BOT_TOKEN = '$BOT_TOKEN'\", content)
# Замена ADMIN_ID
content = re.sub(r\"ADMIN_ID\s*=\s*['\\\"]?\d+['\\\"]?\", f\"ADMIN_ID = $ADMIN_ID\", content)

print(content)
" > "$TEMP_FILE"

mv "$TEMP_FILE" config.py

echo -e "\n${GREEN}=== Настройки успешно сохранены! ===${NC}"
echo -e "Токен бота: ${YELLOW}$BOT_TOKEN${NC}"
echo -e "ID администратора: ${YELLOW}$ADMIN_ID${NC}"

# Установка прав на файл конфигурации (чтобы другие пользователи не читали токен)
chmod 600 config.py

echo -e "\n${GREEN}=== Установка и запуск службы systemd ===${NC}"

SERVICE_NAME="yadreno-vpn"
SERVICE_FILE="${SERVICE_NAME}.service"

# Проверяем наличие файла службы
if [ ! -f "$SERVICE_FILE" ]; then
    echo -e "${RED}Ошибка: Файл службы $SERVICE_FILE не найден в текущей директории!${NC}"
    echo "Убедитесь, что вы находитесь в папке проекта и файл службы существует."
    exit 1
fi

# Копируем файл службы в систему
echo "Копирование файла службы в /etc/systemd/system/..."
sudo cp "$SERVICE_FILE" /etc/systemd/system/

# Перезагружаем демон systemd, чтобы он увидел новую службу
echo "Обновление списка служб systemd..."
sudo systemctl daemon-reload

# Включаем службу для автозапуска при загрузке
echo "Включение автозапуска службы..."
sudo systemctl enable "$SERVICE_NAME"

# Останавливаем службу, если она уже запущена (чтобы применить новый конфиг)
echo "Остановка существующего процесса бота (если есть)..."
sudo systemctl stop "$SERVICE_NAME" || true
# Также убиваем возможные ручные процессы python main.py
sudo pkill -f "python.*main.py" || true

# Запускаем службу
echo "Запуск службы бота..."
sudo systemctl start "$SERVICE_NAME"

# Проверка статуса
sleep 2
if sudo systemctl is-active --quiet "$SERVICE_NAME"; then
    echo -e "\n${GREEN}✅ Бот успешно запущен как служба ($SERVICE_NAME)!${NC}"
    echo -e "Бот будет работать в фоне даже после закрытия терминала и перезагрузки сервера."
    echo -e "\nПолезные команды:"
    echo -e "  Просмотр логов: ${YELLOW}sudo journalctl -u $SERVICE_NAME -f${NC}"
    echo -e "  Остановка бота: ${YELLOW}sudo systemctl stop $SERVICE_NAME${NC}"
    echo -e "  Перезапуск бота: ${YELLOW}sudo systemctl restart $SERVICE_NAME${NC}"
    echo -e "  Статус службы: ${YELLOW}sudo systemctl status $SERVICE_NAME${NC}"
else
    echo -e "\n${RED}❌ Ошибка при запуске службы!${NC}"
    echo "Проверьте логи для диагностики:"
    sudo systemctl status "$SERVICE_NAME" --no-pager
    exit 1
fi
