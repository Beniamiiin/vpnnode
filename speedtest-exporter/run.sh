#!/bin/bash

# Скрипт для запуска speedtest-exporter

# Проверяем параметры
if [ -z "$1" ]; then
    echo "Ошибка: необходимо указать UPDATE_INTERVAL"
    echo "Использование: $0 <UPDATE_INTERVAL> [SERVER_IDS]"
    exit 1
fi

UPDATE_INTERVAL="$1"
SERVER_IDS="${2:-0}"

echo "Запуск speedtest-exporter с SERVER_IDS: $SERVER_IDS, UPDATE_INTERVAL: $UPDATE_INTERVAL"

# Останавливаем и удаляем старый контейнер, если он существует
if [ "$(docker ps -aq -f name=speedtest-exporter)" ]; then
    echo "Удаляем старый контейнер speedtest-exporter..."
    docker stop speedtest-exporter
    docker rm speedtest-exporter
fi

# Скачиваем образ
echo "Скачиваем образ kutovoys/speedtest-exporter..."
docker pull kutovoys/speedtest-exporter

# Запускаем контейнер
echo "Запускаем speedtest-exporter..."
docker run -d \
  --name speedtest-exporter \
  -e SERVER_IDS="$SERVER_IDS" \
  -e UPDATE_INTERVAL="$UPDATE_INTERVAL" \
  -p 9090:9090 \
  --restart unless-stopped \
  kutovoys/speedtest-exporter

# Определяем IP-адрес сервера
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "speedtest-exporter запущен на порту 9090"
echo "Метрики доступны по адресу: http://$SERVER_IP:9090"
