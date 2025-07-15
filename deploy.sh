#!/bin/bash

# Развертывание VPN ноды
# Использование: curl ... | bash -s {SSL_CERT} {SPEEDTEST_SERVERS} {FLEET_URL} {FLEET_USERNAME} {FLEET_PASSWORD} {METRICS_USER} {METRICS_PASS}

set -e

# Параметры
SSL_CERT="$1"
SPEEDTEST_SERVERS="$2"
FLEET_URL="$3"
FLEET_USERNAME="$4"
FLEET_PASSWORD="$5"
METRICS_USER="${6:-}"
METRICS_PASS="${7:-}"

# Константы
SPEEDTEST_INTERVAL=60

# Проверка обязательных параметров
if [ -z "$SSL_CERT" ] || [ -z "$FLEET_URL" ] || [ -z "$FLEET_USERNAME" ] || [ -z "$FLEET_PASSWORD" ]; then
    echo "❌ Ошибка: Не все обязательные параметры указаны"
    echo ""
    echo "Использование:"
    echo "curl -fsSL ... | bash -s SSL_CERT SPEEDTEST_SERVERS FLEET_URL FLEET_USERNAME FLEET_PASSWORD [METRICS_USER] [METRICS_PASS]"
    echo ""
    echo "Обязательные параметры:"
    echo "  SSL_CERT           - SSL сертификат из панели Remnawave"
    echo "  FLEET_URL          - URL Fleet Management для Grafana Alloy"
    echo "  FLEET_USERNAME     - Имя пользователя Fleet Management"
    echo "  FLEET_PASSWORD     - Пароль Fleet Management"
    echo ""
    echo "Необязательные параметры:"
    echo "  SPEEDTEST_SERVERS  - ID серверов для speedtest (необязательно)"
    echo "  METRICS_USER       - Пользователь для basic_auth метрик (необязательно)"
    echo "  METRICS_PASS       - Пароль для basic_auth метрик (необязательно)"
    echo ""
    echo "Фиксированные настройки:"
    echo "  SPEEDTEST_INTERVAL - Интервал speedtest: 60 секунд"
    exit 1
fi

echo "🚀 Начинаем развертывание VPN ноды"
echo "=================================="
echo "Speedtest интервал: $SPEEDTEST_INTERVAL сек (фиксированный)"
echo ""

# 1. Установка Docker и Docker Compose
echo "1️⃣ Установка Docker и Docker Compose..."
echo "======================================="

# Проверяем что это Ubuntu
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" != "ubuntu" ]; then
        echo "❌ Поддерживается только Ubuntu. Обнаружено: $ID"
        exit 1
    fi
    echo "✅ Обнаружена Ubuntu $VERSION_ID"
else
    echo "❌ Не удалось определить операционную систему"
    exit 1
fi

# Обновляем систему
echo "Обновление пакетов..."
apt-get update

# Устанавливаем зависимости
echo "Установка зависимостей..."
apt-get install -y ca-certificates curl gnupg lsb-release

# Добавляем официальный GPG ключ Docker
echo "Добавление GPG ключа Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Добавляем репозиторий Docker
echo "Добавление репозитория Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Устанавливаем Docker
echo "Установка Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Запускаем и включаем Docker
systemctl start docker
systemctl enable docker

# Проверяем установку
docker --version
docker compose version

echo "✅ Docker и Docker Compose установлены"
echo ""

# 2. Установка Remnawave Node
echo "2️⃣ Установка Remnawave Node..."
echo "=============================="

# Создаем директорию проекта
mkdir -p /opt/remnanode
cd /opt/remnanode

# Создаем .env файл
cat > .env << EOF
APP_PORT=2222
SSL_CERT=$SSL_CERT
EOF

# Создаем папку для логов
mkdir -p /var/log/remnanode

# Создаем docker-compose.yml файл с настройкой логирования
cat > docker-compose.yml << 'EOF'
services:
    remnanode:
        container_name: remnanode
        hostname: remnanode
        image: remnawave/node:latest
        restart: always
        network_mode: host
        env_file:
            - .env
        volumes:
            - '/var/log/remnanode:/var/log/remnanode'
EOF

# Устанавливаем logrotate для ротации логов
echo "Настройка ротации логов..."
apt-get install -y logrotate

# Создаем конфигурацию logrotate для Remnawave Node
cat > /etc/logrotate.d/remnanode << 'EOF'
/var/log/remnanode/*.log {
      size 50M
      rotate 5
      compress
      missingok
      notifempty
      copytruncate
  }
EOF

# Тестируем конфигурацию logrotate
logrotate -vf /etc/logrotate.d/remnanode > /dev/null 2>&1 || true

# Запускаем Remnawave Node
docker compose up -d

echo "✅ Remnawave Node установлен и запущен на порту 2222"
echo "📝 Логи: /var/log/remnanode/ (с автоматической ротацией)"
echo ""

# 3. Установка Speedtest
echo "3️⃣ Установка Speedtest мониторинга..."
echo "====================================="

if [ -n "$SPEEDTEST_SERVERS" ]; then
    curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/speedtest/run.sh?nocache=$(uuidgen)" | bash -s "$SPEEDTEST_INTERVAL" "$SPEEDTEST_SERVERS"
else
    curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/speedtest/run.sh?nocache=$(uuidgen)" | bash -s "$SPEEDTEST_INTERVAL"
fi

echo "✅ Speedtest мониторинг установлен"
echo ""

# 4. Установка и настройка Grafana Alloy
echo "4️⃣ Установка Grafana Alloy..."
echo "============================="

if [ -n "$METRICS_USER" ] && [ -n "$METRICS_PASS" ]; then
    curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/grafana-alloy/run.sh?nocache=$(uuidgen)" | sudo bash -s "$FLEET_URL" "$FLEET_USERNAME" "$FLEET_PASSWORD" "$METRICS_USER" "$METRICS_PASS"
else
    curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/grafana-alloy/run.sh?nocache=$(uuidgen)" | sudo bash -s "$FLEET_URL" "$FLEET_USERNAME" "$FLEET_PASSWORD"
fi

echo "✅ Grafana Alloy установлен и настроен"
echo ""

# Финальная проверка
echo "🎉 Развертывание завершено!"
echo "=========================="
echo ""
echo "📋 Установленные компоненты:"
echo "• Docker и Docker Compose"
echo "• Remnawave Node (порт 2222)"
echo "• Speedtest мониторинг (интервал $SPEEDTEST_INTERVAL сек, фиксированный)"
echo "• Grafana Alloy (агент мониторинга)"
echo ""
echo "🔍 Проверка статуса сервисов:"
echo "• docker ps - статус контейнеров"
echo "• systemctl status alloy - статус Grafana Alloy"
echo ""
echo "📊 Логи:"
echo "• docker logs remnanode - логи контейнера Remnawave Node"
echo "• tail -f /var/log/remnanode/*.log - файловые логи Remnawave Node"
echo "• docker logs speedtest-exporter - логи Speedtest"
echo "• journalctl -u alloy -f - логи Grafana Alloy"
echo ""
echo "🔄 Ротация логов настроена автоматически (50MB, 5 файлов)" 