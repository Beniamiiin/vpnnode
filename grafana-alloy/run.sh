#!/bin/bash

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Показ справки
show_help() {
    echo "Использование: $0 [FLEET_URL] [FLEET_USERNAME] [FLEET_PASSWORD]"
    echo
    echo "Параметры:"
    echo "  FLEET_URL      - URL Fleet Management (например: https://fleet-management-prod-011.grafana.net)"
    echo "  FLEET_USERNAME - Username для Fleet Management"
    echo "  FLEET_PASSWORD - Password для Fleet Management"
    echo
    echo "Пример:"
    echo "  $0 https://fleet-management-prod-011.grafana.net 1300043 glc_xxx"
    echo
    echo "Если параметры не указаны, используются переменные окружения:"
    echo "  GRAFANA_FLEET_URL, GRAFANA_FLEET_USERNAME, GRAFANA_FLEET_PASSWORD"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
}

# Проверка наличия Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker не установлен. Пожалуйста, установите Docker и попробуйте снова."
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker не запущен или недоступен. Проверьте статус Docker service."
        exit 1
    fi
    
    log_success "Docker найден и работает"
}

# Проверка и установка переменных окружения
setup_env_vars() {
    # Получаем параметры из командной строки или переменных окружения
    FLEET_URL="${1:-$GRAFANA_FLEET_URL}"
    FLEET_USERNAME="${2:-$GRAFANA_FLEET_USERNAME}"
    FLEET_PASSWORD="${3:-$GRAFANA_FLEET_PASSWORD}"
    
    # Проверяем обязательные параметры
    if [ -z "$FLEET_URL" ] || [ -z "$FLEET_USERNAME" ] || [ -z "$FLEET_PASSWORD" ]; then
        log_error "Не все необходимые параметры указаны!"
        echo
        show_help
        exit 1
    fi
    
    log_info "Fleet URL: $FLEET_URL"
    log_info "Fleet Username: $FLEET_USERNAME"
    log_info "Fleet Password: [СКРЫТ]"
}

# Загрузка конфига Alloy
download_config() {
    local config_url=""
    local github_repo="https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/grafana-alloy"
    
    # Если мы в локальной директории с файлом
    if [ -f "local/local.alloy" ]; then
        log_info "Используем локальный конфиг local/local.alloy"
        cp local/local.alloy /tmp/alloy_config.tmp
        log_success "Локальный конфиг загружен"
        return 0
    fi
    
    # Параметр для передачи URL конфига
    if [ ! -z "$4" ]; then
        config_url="$4"
    else
        config_url="${github_repo}/local/local.alloy?$(date +%s)"
    fi
    
    log_info "Загружаем конфиг из: $config_url"
    
    if command -v curl &> /dev/null; then
        curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "$config_url" -o /tmp/alloy_config.tmp
    elif command -v wget &> /dev/null; then
        wget -q "$config_url" -O /tmp/alloy_config.tmp
    else
        log_error "Не найден curl или wget для загрузки конфига"
        exit 1
    fi
    
    if [ ! -s "/tmp/alloy_config.tmp" ]; then
        log_error "Не удалось загрузить конфиг или файл пустой"
        exit 1
    fi
    
    log_success "Конфиг успешно загружен"
}

# Настройка директорий и конфига
setup_config() {
    log_info "Создаем необходимые директории..."
    mkdir -p /etc/alloy
    mkdir -p /var/lib/alloy/data
    
    log_info "Копируем конфиг в /etc/alloy/config.alloy..."
    cp /tmp/alloy_config.tmp /etc/alloy/config.alloy
    chmod 644 /etc/alloy/config.alloy
    
    # Очищаем временный файл
    rm -f /tmp/alloy_config.tmp
    
    log_success "Конфиг установлен"
}

# Остановка старого контейнера
stop_old_container() {
    log_info "Проверяем наличие старого контейнера grafana-alloy..."
    
    if docker ps -a --format "{{.Names}}" | grep -q "^grafana-alloy$"; then
        log_warning "Останавливаем и удаляем старый контейнер..."
        docker rm grafana-alloy -f 2>/dev/null || true
        log_success "Старый контейнер удален"
    else
        log_info "Старый контейнер не найден"
    fi
}

# Запуск нового контейнера
start_container() {
    log_info "Запускаем новый контейнер grafana-alloy..."
    
    # Получаем переменные окружения
    local hostname_var=$(hostname)
    local server_ip=$(hostname -I | awk '{print $1}')
    
    log_info "Hostname: $hostname_var"
    log_info "Server IP: $server_ip"
    
    # Запускаем контейнер с переданными кредами
    docker run \
        -d \
        --network=host \
        --name grafana-alloy \
        -e HOSTNAME="$hostname_var" \
        -e SERVER_IP="$server_ip" \
        -e GRAFANA_FLEET_URL="$FLEET_URL" \
        -e GRAFANA_FLEET_USERNAME="$FLEET_USERNAME" \
        -e GRAFANA_FLEET_PASSWORD="$FLEET_PASSWORD" \
        -v /etc/alloy/config.alloy:/etc/alloy/config.alloy \
        -v /var/lib/alloy/data:/var/lib/alloy/data \
        -p 12345:12345 \
        grafana/alloy:latest \
        run --server.http.listen-addr=0.0.0.0:12345 --storage.path=/var/lib/alloy/data \
        /etc/alloy/config.alloy
    
    log_success "Контейнер grafana-alloy запущен"
}

# Проверка статуса контейнера
check_container_status() {
    log_info "Проверяем статус контейнера..."
    sleep 2
    
    if docker ps --format "{{.Names}}" | grep -q "^grafana-alloy$"; then
        log_success "Контейнер работает успешно"
        local server_ip=$(hostname -I | awk '{print $1}')
        log_info "Alloy доступен по адресу: http://$server_ip:12345"
    else
        log_error "Контейнер не запустился. Проверьте логи:"
        docker logs grafana-alloy
        exit 1
    fi
}

# Показ логов
show_logs() {
    log_info "Показываем логи (Ctrl+C для выхода)..."
    echo "----------------------------------------"
    docker logs grafana-alloy -f
}

# Основная функция
main() {
    # Проверка на помощь
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_help
        exit 0
    fi
    
    echo "========================================="
    echo "    Grafana Alloy Deployment Script     "
    echo "========================================="
    echo
    
    check_root
    check_docker
    setup_env_vars "$1" "$2" "$3"
    download_config "$1" "$2" "$3" "$4"
    setup_config
    stop_old_container
    start_container
    check_container_status
    
    echo
    log_success "🎉 Grafana Alloy успешно развернут!"
    echo
    
    # Спрашиваем, показывать ли логи
    read -p "Показать логи в реальном времени? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        show_logs
    else
        log_info "Для просмотра логов выполните: docker logs grafana-alloy -f"
    fi
}

# Запуск основной функции
main "$@" 