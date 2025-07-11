#!/bin/bash

# Скрипт для запуска speedtest

# Проверяем параметры
if [ -z "$1" ]; then
    echo "Ошибка: необходимо указать UPDATE_INTERVAL"
    echo "Использование: $0 <UPDATE_INTERVAL> [SERVER_IDS]"
    exit 1
fi

UPDATE_INTERVAL="$1"
SERVER_IDS="${2:-0}"

echo "Запуск speedtest с SERVER_IDS: $SERVER_IDS, UPDATE_INTERVAL: $UPDATE_INTERVAL"

# Останавливаем и удаляем старый контейнер, если он существует
if [ "$(docker ps -aq -f name=speedtest)" ]; then
    echo "Удаляем старый контейнер speedtest..."
    docker stop speedtest
    docker rm speedtest
fi

# Скачиваем образ
echo "Скачиваем образ kutovoys/speedtest-exporter..."
docker pull kutovoys/speedtest-exporter

# Запускаем контейнер
echo "Запускаем speedtest..."
docker run -d \
  --name speedtest \
  -e SERVER_IDS="$SERVER_IDS" \
  -e UPDATE_INTERVAL="$UPDATE_INTERVAL" \
  -p 9090:9090 \
  --restart unless-stopped \
  kutovoys/speedtest-exporter

# Определяем IP-адрес сервера
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "speedtest запущен на порту 9090"
echo "Метрики доступны по адресу: http://$SERVER_IP:9090"
