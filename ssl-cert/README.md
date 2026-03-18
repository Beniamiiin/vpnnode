# SSL сертификат Let's Encrypt

Получение SSL сертификата через acme.sh для Remnawave Node.

## Вызов

```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/ssl-cert/run.sh?nocache=$(uuidgen)" | sudo bash -s EMAIL DOMAIN
```

## Параметры

- **EMAIL** — email для Let's Encrypt (уведомления, восстановление)
- **DOMAIN** — домен для сертификата

## Пример

```bash
curl -fsSL -H 'Cache-Control: no-cache' -H 'Pragma: no-cache' "https://raw.githubusercontent.com/Beniamiiin/vpnnode/refs/heads/master/ssl-cert/run.sh?nocache=$(uuidgen)" | sudo bash -s admin@example.com vpn.example.com
```

## Требования

- Порт 80 свободен (standalone режим acme.sh)
- root или sudo
- Ubuntu

## Результат

Сертификаты устанавливаются в:
- `/var/lib/remnawave/configs/xray/ssl/cert.key`
- `/var/lib/remnawave/configs/xray/ssl/cert.crt`

acme.sh настраивает автообновление через cron.
