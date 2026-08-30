#!/bin/bash

# Переходим в директорию ButovskyShop
cd "$(dirname "$0")" || exit 1

MAIN_PY="./main.py"
LOG_FILE="./logs/main_py.log"
PID_FILE="./logs/main_py.pid"

# Создаем папку для логов
mkdir -p ./logs

# Проверяем существование main.py
if [ ! -f "$MAIN_PY" ]; then
    echo "Ошибка: Файл $MAIN_PY не найден!"
    exit 1
fi

# Проверяем, запущен ли уже процесс
if pgrep -f "python.*main.py" > /dev/null; then
    echo "main.py уже запущен!"
    exit 0
fi

# Запускаем main.py в фоне
echo "Запуск main.py..."
nohup python3 "$MAIN_PY" > "$LOG_FILE" 2>&1 &

# Сохраняем PID
PID=$!
echo $PID > "$PID_FILE"

echo "main.py запущен с PID: $PID"
echo "Логи: $LOG_FILE"

# Добавляем в автозагрузку при перезапуске сервера
(crontab -l 2>/dev/null; echo "@reboot cd $(pwd) && nohup python3 $MAIN_PY > $LOG_FILE 2>&1 &") | crontab -

echo "Добавлено в автозагрузку"