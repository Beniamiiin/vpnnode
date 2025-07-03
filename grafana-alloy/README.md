# Grafana Alloy - Скрипты развертывания

Автоматическое развертывание [Grafana Alloy](https://grafana.com/docs/alloy/) для мониторинга серверов.

## Файлы

### Конфигурации

#### Локальное развертывание (папка `local/`)
- **`local.alloy`** - конфигурация для развертывания на серверах через Fleet Management

#### Библиотека конфигураций (папка `remote/`)
Готовые конфигурации для добавления через Grafana Fleet Management → Remote Configuration:
- **`linux.alloy`** - системные метрики Linux (CPU, память, диск, сеть)
- **`xray-checker.alloy`** - мониторинг xray-checker сервиса (порт 2112)
- **`speedtest.alloy`** - мониторинг speedtest-exporter (порт 9090, интервал 60м)

### Скрипт развертывания
**`run.sh`** - автоматически:
- Принимает креды Fleet Management как параметры
- Использует конфигурацию из `local/local.alloy`
- Проверяет Docker и права root
- Скачивает конфигурацию (локально или с GitHub)
- Останавливает старый контейнер и запускает новый
- Настраивает Alloy на порту 12345

### Примеры переменных
**`env-vars.example`** - примеры всех переменных окружения для конфигураций

## Использование

### Локальный запуск
```bash
sudo ./run.sh <FLEET_URL> <FLEET_USERNAME> <FLEET_PASSWORD>
```

### Удаленный запуск
```bash
# Прямая загрузка и выполнение
curl -fsSL https://raw.githubusercontent.com/Beniamiiin/vpn/refs/heads/master/grafana-alloy/run.sh | sudo bash -s <FLEET_URL> <FLEET_USERNAME> <FLEET_PASSWORD>
```

### Параметры
- **FLEET_URL** - URL Fleet Management (например: `https://fleet-management-prod-011.grafana.net`)
- **FLEET_USERNAME** - Username для Fleet Management
- **FLEET_PASSWORD** - Password для Fleet Management

### Переменные окружения
Вместо параметров можно использовать переменные окружения:
```bash
export GRAFANA_FLEET_URL="https://fleet-management-prod-011.grafana.net"
export GRAFANA_FLEET_USERNAME="1234567"
export GRAFANA_FLEET_PASSWORD="glc_xxx"
sudo ./run.sh
```

См. `env-vars.example` для полного списка переменных.

## Рабочий процесс

1. **На сервере**: Запускаем `run.sh` с кредами - устанавливает Alloy с `local.alloy`
2. **В Grafana**: Добавляем нужные конфигурации из папки `remote/` через Fleet Management
3. **Результат**: Centralized управление мониторингом через Grafana Cloud
