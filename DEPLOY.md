# Полное развертывание VPN ноды

Скрипт `deploy.sh` автоматически устанавливает и настраивает полную VPN ноду с мониторингом.

## ⚠️ Требования

- **Операционная система**: Ubuntu (любая версия)
- **Права доступа**: root или sudo
- **Интернет**: доступ к репозиториям Docker и GitHub

## 🚀 Быстрый запуск

```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/deploy.sh?nocache=$(uuidgen)" | sudo bash -s "{SSL_CERT}" 2222 "{SUBSCRIPTION_URL}" 3600 "" "{FLEET_URL}" "{FLEET_USERNAME}" "{FLEET_PASSWORD}"
```

## 📋 Параметры

### Обязательные параметры:

1. **SSL_CERT** - SSL сертификат из панели Remnawave
   ```
   SSL_CERT_KEY=your_private_key_here
   SSL_CERT_CERT=your_certificate_here
   ```

2. **SUBSCRIPTION_URL** - URL подписки для XRay Checker
   ```
   https://your-subscription-url.com/subscription
   ```

3. **FLEET_URL** - URL Fleet Management для Grafana Alloy
   ```
   https://your-fleet-management.com
   ```

4. **FLEET_USERNAME** - Имя пользователя Fleet Management

5. **FLEET_PASSWORD** - Пароль Fleet Management

### Необязательные параметры:

6. **REMNA_PORT** (по умолчанию: 2222) - Порт для Remnawave Node

7. **SPEEDTEST_INTERVAL** (по умолчанию: 3600) - Интервал speedtest в секундах

8. **SPEEDTEST_SERVERS** (необязательно) - ID серверов для speedtest через запятую

9. **METRICS_USER** (необязательно) - Пользователь для basic_auth метрик

10. **METRICS_PASS** (необязательно) - Пароль для basic_auth метрик

## 📝 Примеры использования

### Минимальная установка:
```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/deploy.sh?nocache=$(uuidgen)" | sudo bash -s \
  "SSL_CERT_KEY=your_key_here
SSL_CERT_CERT=your_cert_here" \
  2222 \
  "https://your-subscription-url.com/subscription" \
  3600 \
  "" \
  "https://your-fleet-management.com" \
  "fleet_username" \
  "fleet_password"
```

### Полная установка с аутентификацией метрик:
```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/deploy.sh?nocache=$(uuidgen)" | sudo bash -s \
  "SSL_CERT_KEY=your_key_here
SSL_CERT_CERT=your_cert_here" \
  2222 \
  "https://your-subscription-url.com/subscription" \
  1800 \
  "12345,67890" \
  "https://your-fleet-management.com" \
  "fleet_username" \
  "fleet_password" \
  "metrics_user" \
  "metrics_password"
```

## 🔧 Что устанавливается

### 1. Docker и Docker Compose
- Проверка совместимости с Ubuntu
- Установка официальных пакетов Docker для Ubuntu
- Настройка автозапуска сервиса

### 2. Remnawave Node
- Создание директории `/opt/remnanode`
- Настройка SSL сертификатов
- Запуск контейнера с `network_mode: host`

### 3. XRay Checker  
- Веб-интерфейс на порту 8080
- Автоматическая проверка VPN подключений
- Интеграция с подпиской

### 4. Speedtest мониторинг
- Регулярные проверки скорости интернета
- Экспорт метрик в Prometheus формате
- Настраиваемый интервал и серверы

### 5. Grafana Alloy
- Агент мониторинга с Fleet Management
- Сбор системных метрик
- Опциональная аутентификация

## 🔍 Проверка установки

После завершения установки проверьте статус сервисов:

```bash
# Контейнеры Docker
docker ps

# Grafana Alloy
systemctl status alloy

# XRay Checker веб-интерфейс
curl http://localhost:8080

# Remnawave Node
docker logs remnanode
```

## 📊 Логи и диагностика

```bash
# Логи Remnawave Node
docker logs remnanode -f

# Логи XRay Checker
docker logs xray-checker -f

# Логи Speedtest
docker logs speedtest-exporter -f

# Логи Grafana Alloy
journalctl -u alloy -f
```

## 🚨 Устранение неполадок

### Проблемы с Docker
```bash
# Перезапуск Docker
sudo systemctl restart docker

# Проверка статуса
sudo systemctl status docker
```

### Проблемы с портами
```bash
# Проверка занятых портов
netstat -tulpn | grep :2222
netstat -tulpn | grep :8080
```

### Проблемы с SSL сертификатами
- Убедитесь, что SSL_CERT содержит корректные ключ и сертификат
- Проверьте формат: каждая переменная на новой строке

## 🔐 Безопасность

- Все чувствительные данные передаются как параметры
- SSL сертификаты хранятся в `/opt/remnanode/.env`
- Контейнеры запускаются с минимальными привилегиями
- Логи не содержат чувствительной информации

## 📞 Поддержка

При возникновении проблем:
1. Проверьте логи всех сервисов
2. Убедитесь в корректности параметров
3. Проверьте доступность сетевых ресурсов
4. Проверьте права доступа к файлам 