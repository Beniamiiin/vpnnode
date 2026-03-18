#!/bin/bash

# Получение SSL сертификата Let's Encrypt через acme.sh
# Использование: curl ... | bash -s {EMAIL} {DOMAIN}

set -e

EMAIL="$1"
DOMAIN="$2"

if [ -z "$EMAIL" ] || [ -z "$DOMAIN" ]; then
    echo "❌ Ошибка: укажите EMAIL и DOMAIN"
    echo ""
    echo "Использование:"
    echo "curl -fsSL ... | bash -s EMAIL DOMAIN"
    echo ""
    echo "Пример:"
    echo "curl -fsSL ... | bash -s admin@example.com vpn.example.com"
    exit 1
fi

echo "🔐 Получение SSL сертификата Let's Encrypt"
echo "=========================================="
echo "Email:  $EMAIL"
echo "Домен:  $DOMAIN"
echo ""

if command -v ss >/dev/null 2>&1; then
    if ss -tlnp 2>/dev/null | grep -q ':80 '; then
        echo "⚠️  Порт 80 занят. Для standalone режима acme.sh нужен свободный порт 80."
        echo "   Остановите веб-сервер (nginx, apache) и запустите скрипт снова."
        exit 1
    fi
fi

echo "Установка зависимостей..."
apt-get update
apt-get install -y cron socat

echo ""
echo "Установка acme.sh..."
curl https://get.acme.sh | sh -s email="$EMAIL"

~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

echo ""
echo "Выпуск сертификата (standalone)..."
~/.acme.sh/acme.sh --issue -d "$DOMAIN" --standalone --force

echo ""
echo "Установка сертификата в /var/lib/remnawave/configs/xray/ssl/..."
mkdir -p /var/lib/remnawave/configs/xray/ssl
~/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --key-file /var/lib/remnawave/configs/xray/ssl/cert.key \
    --fullchain-file /var/lib/remnawave/configs/xray/ssl/cert.crt

echo ""
echo "✅ Готово. Сертификат установлен:"
echo "   /var/lib/remnawave/configs/xray/ssl/cert.key"
echo "   /var/lib/remnawave/configs/xray/ssl/cert.crt"
echo ""
echo "acme.sh настроит автообновление через cron."
