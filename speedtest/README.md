# Speedtest Exporter - Скрипт развертывания

Автоматическое развертывание [kutovoys/speedtest-exporter](https://hub.docker.com/r/kutovoys/speedtest-exporter) для мониторинга скорости интернета.

## Файлы

### Скрипт развертывания
**`run.sh`** - автоматически:
- Принимает UPDATE_INTERVAL как обязательный параметр
- Принимает SERVER_IDS как опциональный параметр (по умолчанию 0)
- Останавливает и удаляет старый контейнер
- Скачивает образ kutovoys/speedtest-exporter
- Запускает контейнер с настройками
- Настраивает экспорт метрик на порту 9090

## Использование

### Локальный запуск
```bash
./run.sh {UPDATE_INTERVAL} [SERVER_IDS]
```

### Удаленный запуск
```bash
# Прямая загрузка и выполнение (с автовыбором сервера)
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/speedtest/run.sh?nocache=$(uuidgen)" | bash -s 60

# Прямая загрузка и выполнение (с указанием сервера)
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/speedtest/run.sh?nocache=$(uuidgen)" | bash -s 60 12345
```

## Доступ

Метрики доступны по адресу:
- **Удаленно:** http://server-ip:9090

## Конфигурация

- **UPDATE_INTERVAL:** передается как первый параметр скрипта (интервал в минутах)
- **SERVER_IDS:** передается как второй параметр скрипта (по умолчанию 0 = автовыбор)
- **Порт:** 9090
- **Автоперезапуск:** включен
