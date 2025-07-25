#!/bin/bash

# Установка Docker и Docker Compose
# Использование: curl -fsSL ... | bash

set -e

echo "🐳 Установка Docker и Docker Compose"
echo "===================================="

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

# Проверяем установлен ли Docker
if command -v docker >/dev/null 2>&1; then
    echo "⚠️  Docker уже установлен:"
    docker --version
    if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
        docker compose version
        echo "✅ Docker и Docker Compose уже установлены и работают"
        exit 0
    fi
fi

# Обновляем систему
echo "📦 Обновление пакетов..."
apt-get update

# Устанавливаем зависимости
echo "📦 Установка зависимостей..."
apt-get install -y ca-certificates curl gnupg lsb-release

# Добавляем официальный GPG ключ Docker
echo "🔑 Добавление GPG ключа Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Добавляем репозиторий Docker
echo "📚 Добавление репозитория Docker..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Устанавливаем Docker
echo "🐳 Установка Docker..."
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Запускаем и включаем Docker
echo "🚀 Запуск и настройка автозапуска Docker..."
systemctl start docker
systemctl enable docker

# Проверяем установку
echo ""
echo "✅ Установка завершена!"
echo "======================"
echo ""
echo "📋 Установленные версии:"
docker --version
docker compose version
echo ""
echo "🔍 Проверка работы:"
echo "• docker ps - список запущенных контейнеров"
echo "• docker run hello-world - тестовый контейнер"
echo ""
echo "🛠️  Управление сервисом:"
echo "• systemctl status docker - статус сервиса"
echo "• systemctl start/stop/restart docker - управление" 