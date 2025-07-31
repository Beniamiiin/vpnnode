#!/bin/bash

# Скрипт для запуска xray-checker

# Проверяем, что передан SUBSCRIPTION_URL
if [ -z "$1" ]; then
    echo "Ошибка: необходимо указать SUBSCRIPTION_URL"
    echo "Использование: $0 <SUBSCRIPTION_URL>"
    exit 1
fi

SUBSCRIPTION_URL="$1"

echo "Запуск xray-checker с SUBSCRIPTION_URL: $SUBSCRIPTION_URL"

# Останавливаем и удаляем старый контейнер, если он существует
if [ "$(docker ps -aq -f name=xray-checker)" ]; then
    echo "Удаляем старый контейнер xray-checker..."
    docker stop xray-checker
    docker rm xray-checker
fi

# Скачиваем образ
echo "Скачиваем образ kutovoys/xray-checker..."
docker pull kutovoys/xray-checker

# Запускаем контейнер
echo "Запускаем xray-checker..."
docker run -d \
  --name xray-checker \
  -e SUBSCRIPTION_URL="$SUBSCRIPTION_URL" \
  -e XRAY_LOG_LEVEL="debug" \
  -p 2112:2112 \
  --restart unless-stopped \
  kutovoys/xray-checker

# Определяем IP-адрес сервера
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "xray-checker запущен на порту 2112"
echo "Веб-интерфейс доступен по адресу: http://$SERVER_IP:2112"
