#!/bin/bash

# Скрипт для запуска бота в фоне с автозапуском при перезагрузке

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="yadreno-vpn-bot"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
PYTHON_PATH=$(which python3)

echo "=== Запуск YadrenoVPN Bot ==="
echo ""

# Проверяем, существует ли config.py
if [ ! -f "$SCRIPT_DIR/config.py" ]; then
    echo "Ошибка: Файл config.py не найден!"
    echo "Запустите install.sh для настройки."
    exit 1
fi

# Проверяем права root для создания systemd сервиса
if [ "$EUID" -ne 0 ]; then 
    echo "Для настройки автозапуска требуются права root (sudo)"
    echo "Запуск без systemd..."
    
    # Запуск через nohup в фоне
    if pgrep -f "python3.*main.py" > /dev/null; then
        echo "Бот уже запущен!"
        exit 0
    fi
    
    cd "$SCRIPT_DIR"
    nohup $PYTHON_PATH main.py > logs/bot.log 2>&1 &
    BOT_PID=$!
    echo $BOT_PID > bot.pid
    
    echo "Бот запущен в фоне (PID: $BOT_PID)"
    echo "Логи: tail -f logs/bot.log"
    echo "Остановить: kill $BOT_PID"
    exit 0
fi

# Создаем systemd сервис-файл
echo "Создаем systemd сервис..."

cat > "$SERVICE_FILE" << SERVICE_EOF
[Unit]
Description=YadrenoVPN Telegram Bot
After=network.target

[Service]
Type=simple
WorkingDirectory=$SCRIPT_DIR
ExecStart=$PYTHON_PATH main.py
Restart=always
RestartSec=5
User=root
Group=root

StandardOutput=journal
StandardError=journal
SyslogIdentifier=yadreno-vpn-bot

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# Перезагружаем systemd
systemctl daemon-reload

# Включаем автозапуск
systemctl enable $SERVICE_NAME

# Проверяем, запущен ли уже сервис
if systemctl is-active --quiet $SERVICE_NAME; then
    echo "Сервис уже запущен. Перезапускаем..."
    systemctl restart $SERVICE_NAME
else
    echo "Запускаем сервис..."
    systemctl start $SERVICE_NAME
fi

# Ждем немного и проверяем статус
sleep 2

if systemctl is-active --quiet $SERVICE_NAME; then
    echo ""
    echo "✅ Бот успешно запущен!"
    echo "Статус: systemctl status $SERVICE_NAME"
    echo "Логи: journalctl -u $SERVICE_NAME -f"
    echo "Остановить: systemctl stop $SERVICE_NAME"
else
    echo ""
    echo "❌ Ошибка запуска! Проверьте логи:"
    echo "journalctl -u $SERVICE_NAME -n 50"
    exit 1
fi