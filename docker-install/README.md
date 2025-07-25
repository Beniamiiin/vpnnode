# Установка Docker

Автоматическая установка Docker и Docker Compose на Ubuntu серверах.

## Быстрая установка

```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/master/docker-install/run.sh" | sudo bash
```

## Что устанавливается

- **Docker CE** - Container Engine
- **Docker CLI** - интерфейс командной строки  
- **containerd.io** - среда выполнения контейнеров
- **Docker Buildx** - расширенные возможности сборки
- **Docker Compose** - управление многоконтейнерными приложениями

## Системные требования

- **ОС**: Ubuntu (любая поддерживаемая версия)
- **Права**: root или sudo
- **Интернет**: для загрузки пакетов

## Особенности

✅ **Проверка совместимости** - скрипт работает только на Ubuntu  
✅ **Защита от повторной установки** - проверяет наличие Docker  
✅ **Автозапуск** - настраивает запуск Docker при загрузке системы  
✅ **Официальные пакеты** - устанавливает из официального репозитория Docker  

## После установки

Проверить работу:
```bash
docker --version
docker compose version
docker ps
```

Тестовый запуск:
```bash
docker run hello-world
```

## Управление сервисом

```bash
# Статус
sudo systemctl status docker

# Запуск/остановка/перезапуск
sudo systemctl start docker
sudo systemctl stop docker  
sudo systemctl restart docker
``` 