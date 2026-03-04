#!/bin/bash

# Развертывание VPN ноды
# Использование: curl ... | bash -s {SECRET_KEY} {FLEET_URL} {FLEET_USERNAME} {FLEET_PASSWORD} {METRICS_USER} {METRICS_PASS} {EMAIL} {DOMAIN}

set -e

# Параметры
SECRET_KEY="$1"
FLEET_URL="$2"
FLEET_USERNAME="$3"
FLEET_PASSWORD="$4"
METRICS_USER="${5:-}"
METRICS_PASS="${6:-}"
EMAIL="${7:-}"
DOMAIN="${8:-}"

# Проверка обязательных параметров
if [ -z "$SECRET_KEY" ] || [ -z "$FLEET_URL" ] || [ -z "$FLEET_USERNAME" ] || [ -z "$FLEET_PASSWORD" ]; then
    echo "❌ Ошибка: Не все обязательные параметры указаны"
    echo ""
    echo "Использование:"
    echo "curl -fsSL ... | bash -s SECRET_KEY FLEET_URL FLEET_USERNAME FLEET_PASSWORD [METRICS_USER] [METRICS_PASS] [EMAIL] [DOMAIN]"
    echo ""
    echo "Обязательные параметры:"
    echo "  SECRET_KEY         - SECRET_KEY из панели Remnawave"
    echo "  FLEET_URL          - URL Fleet Management для Grafana Alloy"
    echo "  FLEET_USERNAME     - Имя пользователя Fleet Management"
    echo "  FLEET_PASSWORD     - Пароль Fleet Management"
    echo ""
    echo "Необязательные параметры:"
    echo "  METRICS_USER       - Пользователь для basic_auth метрик (необязательно)"
    echo "  METRICS_PASS       - Пароль для basic_auth метрик (необязательно)"
    echo "  EMAIL              - Email для Let's Encrypt (необязательно)"
    echo "  DOMAIN             - Домен для SSL сертификата (необязательно)"
    exit 1
fi

echo "🚀 Начинаем развертывание VPN ноды"
echo "=================================="
echo ""

# 1. Установка Docker и Docker Compose
echo "1️⃣ Установка Docker и Docker Compose..."
echo "======================================="

curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/master/docker-install/run.sh?nocache=$(uuidgen)" | bash

echo "✅ Docker и Docker Compose установлены"
echo ""

# 2. Настройка shell окружения
echo "2️⃣ Настройка shell окружения (zsh + oh-my-zsh)..."
echo "================================================="

# Устанавливаем zsh и oh-my-zsh
echo "Установка zsh, curl, git и oh-my-zsh..."
apt-get update && apt-get install -y zsh curl git

# Удаляем существующую папку oh-my-zsh если она есть
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "Найдена существующая установка Oh My Zsh, удаляем..."
    rm -rf "$HOME/.oh-my-zsh"
fi

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Настраиваем плагины и базовые алиасы
echo "Настройка плагинов и алиасов..."
sed -i 's/^plugins=(.*)/plugins=(sudo common-aliases z history)/' ~/.zshrc
grep -qxF "alias zshrc='nano ~/.zshrc'" ~/.zshrc || echo "alias zshrc='nano ~/.zshrc'" >> ~/.zshrc
grep -qxF "alias reload='source ~/.zshrc'" ~/.zshrc || echo "alias reload='source ~/.zshrc'" >> ~/.zshrc

# Добавляем алиас для clear
echo "alias cl='clear'" >> ~/.zshrc

# Добавляем специальные алиасы для работы с нодой
cat <<'EOF' >> ~/.zshrc

# --- Aliases: Node VPS ---
alias cdnode='cd /opt/remnanode'
alias envnode='nano /opt/remnanode/.env'
alias ymlnode='nano /opt/remnanode/docker-compose.yml'
alias dcnode='cd /opt/remnanode && docker compose down && docker compose up -d && docker compose logs -f'

EOF

# Устанавливаем zsh как shell по умолчанию
chsh -s $(which zsh) root

echo "✅ Shell окружение настроено"
echo ""

# 2.5. Cron: ежедневный перезагруз в 4:30
echo "Настройка cron (ежедневный перезагруз в 4:30)..."
apt-get install -y cron
(crontab -l 2>/dev/null | grep -Fx '30 4 * * * /sbin/reboot') || (crontab -l 2>/dev/null; echo '30 4 * * * /sbin/reboot') | crontab -
echo "✅ Cron настроен"
echo ""

# 3. Установка Remnawave Node
echo "3️⃣ Установка Remnawave Node..."
echo "=============================="

# Создаем директорию проекта
mkdir -p /opt/remnanode
cd /opt/remnanode

# Создаем .env файл
cat > .env << EOF
NODE_PORT=2222
SECRET_KEY="$SECRET_KEY"
EOF

# Создаем папку для логов
mkdir -p /var/log/remnanode
mkdir -p /var/lib/remnawave/configs/xray/ssl

# Настройка SSL сертификатов через Let's Encrypt (если указаны EMAIL и DOMAIN)
if [ -n "$EMAIL" ] && [ -n "$DOMAIN" ]; then
    echo "🔐 Настройка SSL сертификатов..."
    echo "==============================="
    
    # Устанавливаем необходимые пакеты
    apt install -y cron socat
    
    # Устанавливаем и настраиваем acme.sh
    curl https://get.acme.sh | sh -s email="$EMAIL"
    
    # Устанавливаем Let's Encrypt как CA по умолчанию
    ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    
    # Выпускаем сертификат
    ~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --force
    
    # Устанавливаем сертификат в нужную папку
    ~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
        --key-file /var/lib/remnawave/configs/xray/ssl/cert.key \
        --fullchain-file /var/lib/remnawave/configs/xray/ssl/cert.crt
    
    echo "✅ SSL сертификаты настроены для домена $DOMAIN"
    echo ""
fi

# Создаем docker-compose.yml файл с настройкой логирования
cat > docker-compose.yml << 'EOF'
services:
    remnanode:
        container_name: remnanode
        hostname: remnanode
        image: remnawave/node:2.2.3
        restart: always
        network_mode: host
        env_file:
            - .env
        volumes:
            - '/var/log/remnanode:/var/log/remnanode'
            - '/var/lib/remnawave:/var/lib/remnawave'
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
echo "• Zsh + Oh My Zsh (удобное shell окружение)"
echo "• Cron: ежедневный перезагруз в 4:30"
echo "• Remnawave Node (порт 2222)"
if [ -n "$EMAIL" ] && [ -n "$DOMAIN" ]; then
    echo "• SSL сертификаты Let's Encrypt для домена $DOMAIN"
fi
echo "• Grafana Alloy (агент мониторинга)"
echo ""
echo "🔍 Проверка статуса сервисов:"
echo "• docker ps - статус контейнеров"
echo "• systemctl status alloy - статус Grafana Alloy"
echo ""
echo "📊 Логи:"
echo "• docker logs remnanode - логи контейнера Remnawave Node"
echo "• tail -f /var/log/remnanode/*.log - файловые логи Remnawave Node"
echo "• journalctl -u alloy -f - логи Grafana Alloy"
if [ -n "$EMAIL" ] && [ -n "$DOMAIN" ]; then
    echo "• ~/.acme.sh/acme.sh --list - список SSL сертификатов"
fi
echo ""
echo "🔧 Полезные алиасы (доступны в zsh после новой SSH сессии):"
echo "• cdnode - перейти в папку ноды"
echo "• envnode - редактировать .env файл"
echo "• ymlnode - редактировать docker-compose.yml"
echo "• dcnode - перезапустить ноду с логами"
echo "• cl - очистить экран"
echo "• zshrc - редактировать ~/.zshrc"
echo "• reload - перезагрузить ~/.zshrc"
echo ""
echo "🔄 Ротация логов настроена автоматически (50MB, 5 файлов)" 