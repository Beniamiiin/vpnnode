# VPN Node - Скрипты развертывания

Коллекция скриптов для автоматического развертывания VPN и мониторинг инфраструктуры.

## 🚀 Полное развертывание ноды (One-Click)

Установка всех компонентов одной командой:
```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/deploy.sh?nocache=$(uuidgen)" | sudo bash -s {SSL_CERT} {REMNA_PORT} {SUBSCRIPTION_URL} {SPEEDTEST_INTERVAL} {SPEEDTEST_SERVERS} {FLEET_URL} {FLEET_USERNAME} {FLEET_PASSWORD} {METRICS_USER} {METRICS_PASS}
```

**Автоматически устанавливает (Ubuntu):**
- Docker и Docker Compose
- Remnawave Node 
- XRay Checker
- Speedtest мониторинг
- Grafana Alloy

📖 [Подробное руководство по развертыванию](DEPLOY.md)

## Компоненты

### 🌐 Remnawave Node
Официальный VPN сервер Remnawave (устанавливается только через deploy.sh)

### 🔍 XRay Checker
Проверка VPN/прокси подключений с веб-интерфейсом
```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/xray-checker/run.sh?nocache=$(uuidgen)" | bash -s {SUBSCRIPTION_URL}
```

### 📊 Speedtest
Мониторинг скорости интернета для Prometheus
```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/speedtest/run.sh?nocache=$(uuidgen)" | bash -s {UPDATE_INTERVAL} {SERVER_IDS}
```

### 📈 Grafana Alloy
Агент мониторинга с Fleet Management
```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/grafana-alloy/run.sh?nocache=$(uuidgen)" | sudo bash -s {FLEET_URL} {FLEET_USERNAME} {FLEET_PASSWORD} {METRICS_USER} {METRICS_PASS}
```

### 🏥 Server Check
Комплексная проверка качества серверов перед развертыванием
```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/server-check/run.sh?nocache=$(uuidgen)" | bash -s {LANGUAGE}
```

## Структура

```
vpnnode/
├── deploy.sh             # Полное развертывание ноды
├── xray-checker/         # XRay Checker развертывание
├── speedtest/            # Speedtest мониторинг  
├── grafana-alloy/        # Grafana Alloy агент
│   ├── local/            # Конфиги для серверов
│   └── remote/           # Библиотека для Fleet Management
├── server-check/         # Проверка качества серверов
└── alloy/                # Устаревшие конфиги
```

## Быстрый старт

### 🚀 Полное развертывание (рекомендуется)
Запустите одну команду для установки всего:
1. **Получите SSL_CERT** из панели управления Remnawave
2. **Запустите deploy.sh** - полностью настроит VPN ноду

### 🔧 Поэтапное развертывание
Для тонкой настройки устанавливайте компоненты отдельно:
1. **Проверка сервера** - проверьте качество нового сервера перед развертыванием (скорость ≥ 1 Гбит/с, IP репутация, доступность сервисов)
2. **Мониторинг** - разверните Grafana Alloy первым (требует креды Fleet Management, а также опционально METRICS_USER и METRICS_PASS для basic_auth метрик)
3. **XRay Checker** - добавьте проверку VPN (требует SUBSCRIPTION_URL)
4. **Speedtest** - включите мониторинг скорости (требует интервал обновления)

Все сервисы интегрируются с Grafana Cloud для централизованного мониторинга.

## Безопасность

⚠️ **Все креды передаются как параметры** - никакие чувствительные данные не хранятся в коде. Для метрик с basic_auth используйте параметры METRICS_USER и METRICS_PASS.
