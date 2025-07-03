# XRay Checker - Скрипт развертывания

Автоматическое развертывание [kutovoys/xray-checker](https://hub.docker.com/r/kutovoys/xray-checker) для проверки VPN/прокси подключений.

## Файлы

### Скрипт развертывания
**`run.sh`** - автоматически:
- Принимает SUBSCRIPTION_URL как параметр
- Останавливает и удаляет старый контейнер
- Скачивает образ kutovoys/xray-checker
- Запускает контейнер с настройками
- Настраивает веб-интерфейс на порту 2112

## Использование

### Локальный запуск
```bash
./run.sh {SUBSCRIPTION_URL}
```

### Удаленный запуск
```bash
# Прямая загрузка и выполнение
curl -fsSL https://raw.githubusercontent.com/Beniamiiin/vpn/refs/heads/master/xray-checker/run.sh | bash -s {SUBSCRIPTION_URL}
```

## Доступ

Веб-интерфейс доступен по адресу:
- **Локально:** http://localhost:2112
- **Удаленно:** http://server-ip:2112

## Конфигурация

- **SUBSCRIPTION_URL:** передается как параметр скрипта
- **Порт:** 2112
- **Автоперезапуск:** включен 
