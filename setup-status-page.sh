#!/usr/bin/env bash
set -e
DIR="${STATUS_PAGE_DIR:-/tmp/status-page}"
mkdir -p "$DIR"
cat > "$DIR/index.html" << 'PAGE'
<!doctype html>
<html lang="ru">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>Статус сервера</title>
    <style>
      html, body {
        height: 100%;
        margin: 0;
      }
      body {
        display: grid;
        place-items: center;
        text-align: center;
        background: #fff;
        color: #111;
      }
      .msg {
        font-size: clamp(100px, 2.2vw, 28px);
      }
    </style>
  </head>
  <body>
    <div class="msg">
      🥳
    </div>
  </body>
</html>
PAGE
cd "$DIR"
if [ -n "$STATUS_PAGE_FOREGROUND" ]; then
  exec python3 -m http.server 8080
fi
nohup python3 -m http.server 8080 </dev/null >"$DIR/server.log" 2>&1 &
echo "Страница: http://$(hostname -f 2>/dev/null || hostname):8080/"
echo "Каталог: $DIR"
