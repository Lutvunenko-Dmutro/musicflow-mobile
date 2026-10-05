#!/usr/bin/env python3
"""
MusicFlow Local Update & Telemetry Server
Забезпечує:
1. Перевірку та завантаження оновлень APK по мережі (/api/update/check, /api/update/download)
2. Прийом та збереження звітів про збої за згодою користувача (/api/telemetry/crash-report)
3. Веб-дашборд для моніторингу помилок та керування релізами (/)
"""

import http.server
import json
import os
import socket
import socketserver
import sys
from datetime import datetime
from urllib.parse import parse_qs, urlparse

PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
CRASHES_DIR = os.path.join(DATA_DIR, "crashes")
UPDATES_DIR = os.path.join(DATA_DIR, "updates")
CRASH_LOG_FILE = os.path.join(DATA_DIR, "crash_reports.log")
VERSION_FILE = os.path.join(DATA_DIR, "version.json")

os.makedirs(CRASHES_DIR, exist_ok=True)
os.makedirs(UPDATES_DIR, exist_ok=True)

# Ініціалізація версії за замовчуванням, якщо відсутня
if not os.path.exists(VERSION_FILE):
    default_version = {
        "version": "1.0.1",
        "buildNumber": 2,
        "releaseDate": datetime.now().strftime("%Y-%m-%d"),
        "changelog": "• Живий попередній перегляд караоке під час гри музики\n• Можливість видалення та скидання збережених текстів\n• Оновлення по мережі та збір діагностики за згодою",
        "apkFileName": "app-release.apk",
        "fileSizeBytes": 0
    }
    with open(VERSION_FILE, "w", encoding="utf-8") as f:
        json.dump(default_version, f, ensure_ascii=False, indent=2)


def get_local_ip():
    """Отримати IP адресу в локальній мережі Wi-Fi/LAN"""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def find_best_apk_path(filename="app-release.apk"):
    paths = [
        os.path.join(UPDATES_DIR, filename),
        os.path.join(BASE_DIR, "..", "build", "app", "outputs", "flutter-apk", filename),
        os.path.join(BASE_DIR, "..", "build", "app", "outputs", "flutter-apk", "app-debug.apk"),
    ]
    for p in paths:
        if os.path.exists(p) and os.path.getsize(p) > 0:
            return p
    return None


def get_version_info():
    try:
        with open(VERSION_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        apk_path = find_best_apk_path(data.get("apkFileName", "app-release.apk"))
        if apk_path:
            data["fileSizeBytes"] = os.path.getsize(apk_path)
            data["resolvedApkPath"] = apk_path
        return data
    except Exception:
        return {"version": "1.0.0", "buildNumber": 1, "changelog": "Початковий реліз", "fileSizeBytes": 0}


def get_all_crashes():
    crashes = []
    if not os.path.exists(CRASHES_DIR):
        return crashes
    for fname in sorted(os.listdir(CRASHES_DIR), reverse=True):
        if fname.endswith(".json"):
            fpath = os.path.join(CRASHES_DIR, fname)
            try:
                with open(fpath, "r", encoding="utf-8") as f:
                    crashes.append(json.load(f))
            except Exception:
                pass
    return crashes


DASHBOARD_HTML = """<!DOCTYPE html>
<html lang="uk">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>MusicFlow • Сервер оновлень та телеметрії</title>
  <style>
    :root {
      --bg: #121212; --card: #1e1e1e; --card-border: #2c2c2c;
      --primary: #bb86fc; --accent: #03dac6; --error: #cf6679;
      --text: #ffffff; --text-muted: #a0a0a0;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; }
    body { background: var(--bg); color: var(--text); padding: 24px; }
    .container { max-width: 1100px; margin: 0 auto; }
    header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding-bottom: 16px; border-bottom: 1px solid var(--card-border); }
    h1 { font-size: 22px; display: flex; align-items: center; gap: 10px; }
    .badge { background: #2e7d32; color: #fff; font-size: 11px; padding: 4px 8px; border-radius: 12px; font-weight: bold; }
    .badge-ip { background: #1565c0; font-family: monospace; font-size: 13px; padding: 5px 12px; border-radius: 8px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 24px; }
    @media(max-width: 768px) { .grid { grid-template-columns: 1fr; } }
    .card { background: var(--card); border: 1px solid var(--card-border); border-radius: 14px; padding: 20px; }
    .card h2 { font-size: 16px; margin-bottom: 14px; color: var(--primary); display: flex; align-items: center; gap: 8px; }
    .info-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #282828; font-size: 13px; }
    .info-row span:first-child { color: var(--text-muted); }
    .changelog-box { background: #161616; padding: 12px; border-radius: 8px; font-size: 12px; color: #ddd; white-space: pre-wrap; margin-top: 10px; }
    .btn { background: var(--primary); color: #000; border: none; padding: 8px 16px; border-radius: 8px; font-weight: bold; cursor: pointer; text-decoration: none; display: inline-block; }
    .btn:hover { opacity: 0.9; }
    .btn-secondary { background: #333; color: #fff; }
    .crash-card { background: #1a1517; border-left: 4px solid var(--error); margin-bottom: 12px; border-radius: 8px; padding: 14px; }
    .crash-header { display: flex; justify-content: space-between; font-size: 12px; color: var(--text-muted); margin-bottom: 6px; }
    .crash-title { color: var(--error); font-weight: bold; font-size: 14px; margin-bottom: 6px; }
    .crash-device { font-size: 12px; color: #e0e0e0; margin-bottom: 6px; }
    .crash-trace { background: #000; color: #ffb4a2; font-family: monospace; font-size: 11px; padding: 10px; border-radius: 6px; max-height: 180px; overflow-y: auto; white-space: pre-wrap; margin-top: 8px; }
    .empty-state { text-align: center; padding: 30px; color: var(--text-muted); font-size: 14px; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>🎵 MusicFlow <span class="badge">SERVER ONLINE</span></h1>
      <div class="badge-ip">IP: {{LOCAL_IP}}:{{PORT}}</div>
    </header>

    <div class="grid">
      <!-- Картка оновлень -->
      <div class="card">
        <h2>🚀 Керування оновленнями</h2>
        <div class="info-row"><span>Поточна версія:</span><b>v{{VERSION}} (build {{BUILD}})</b></div>
        <div class="info-row"><span>Дата випуску:</span><b>{{RELEASE_DATE}}</b></div>
        <div class="info-row"><span>Файл APK:</span><b>{{APK_STATUS}}</b></div>
        <div class="info-row"><span>Розмір:</span><b>{{APK_SIZE}}</b></div>
        <div style="margin-top: 12px;"><b>Що нового в релізі:</b></div>
        <div class="changelog-box">{{CHANGELOG}}</div>
        <div style="margin-top: 14px;">
          <details>
            <summary style="cursor: pointer; font-size: 13px; font-weight: bold; color: var(--accent); user-select: none;">📜 Історія всіх релізів ({{HISTORY_COUNT}} версій)</summary>
            <div style="margin-top: 10px; max-height: 250px; overflow-y: auto; background: #151515; padding: 10px; border-radius: 8px;">
              {{HISTORY_HTML}}
            </div>
          </details>
        </div>
        <div style="margin-top: 16px; display: flex; gap: 10px;">
          <a href="/api/update/download" class="btn">Завантажити APK</a>
          <a href="/api/update/check" class="btn btn-secondary" target="_blank">Перевірити API JSON</a>
        </div>
      </div>

      <!-- Картка налаштувань підключення -->
      <div class="card">
        <h2>📱 Підключення додатку з телефону</h2>
        <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 12px;">
          Введіть цю адресу в мобільному додатку у розділі <b>Налаштування → Оновлення та Телеметрія</b>:
        </p>
        <div style="background: #000; padding: 12px; border-radius: 8px; font-family: monospace; font-size: 14px; color: var(--accent); margin-bottom: 16px; user-select: all;">
          http://{{LOCAL_IP}}:{{PORT}}
        </div>
        <ul style="font-size: 12px; color: #aaa; line-height: 1.6; padding-left: 18px;">
          <li>Телефон і ПК мають бути підключені до одного Wi-Fi роутера.</li>
          <li>Додаток автоматично перевірятиме наявність оновлень при натисканні кнопки.</li>
          <li>Звіти про помилки надсилаються <b>тільки якщо користувач дав згоду</b>.</li>
          <li>Для оновлення версії покладіть новий <code style="color: #fff;">app-release.apk</code> у папку <code style="color: #fff;">server/data/updates/</code>.</li>
        </ul>
      </div>
    </div>

    <!-- Список звітів про помилки -->
    <div class="card">
      <h2>🛡️ Звіти про помилки (Телеметрія за згодою) <span style="font-size: 12px; color: var(--text-muted);">({{CRASH_COUNT}} отримано)</span></h2>
      <div id="crashes-list">
        {{CRASHES_HTML}}
      </div>
    </div>
  </div>
</body>
</html>
"""


class MusicFlowRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        # Дозволити CORS для будь-яких запитів
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        # Favicon
        if path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
            return

        # 1. Головна сторінка Dashboard
        if path in ("/", "/dashboard"):
            self.handle_dashboard()
            return

        # 2. Health check
        if path == "/api/health":
            self.send_json({"status": "ok", "time": datetime.now().isoformat()})
            return

        # 3. Перевірка оновлення
        if path == "/api/update/check":
            info = get_version_info()
            local_ip = get_local_ip()
            info["downloadUrl"] = f"http://{local_ip}:{PORT}/api/update/download"

            query = parse_qs(parsed.query)
            current_build_param = query.get("currentBuild", [None])[0]
            if current_build_param:
                try:
                    c_build = int(current_build_param)
                    history = info.get("history", [])
                    missed = [h for h in history if h.get("buildNumber", 0) > c_build]
                    info["missedCount"] = len(missed)
                except Exception:
                    pass

            self.send_json(info)
            return

        # 4. Завантаження APK
        if path == "/api/update/download":
            info = get_version_info()
            apk_path = find_best_apk_path(info.get("apkFileName", "app-release.apk"))

            if apk_path and os.path.exists(apk_path):
                file_size = os.path.getsize(apk_path)
                self.send_response(200)
                self.send_header("Content-Type", "application/vnd.android.package-archive")
                self.send_header("Content-Disposition", 'attachment; filename="music_flow_update.apk"')
                self.send_header("Content-Length", str(file_size))
                self.end_headers()
                with open(apk_path, "rb") as f:
                    while chunk := f.read(64 * 1024):
                        self.wfile.write(chunk)
                print(f"[{datetime.now().strftime('%H:%M:%S')}] 📲 APK завантажено клієнтом ({file_size // 1024} KB)")
                return
            else:
                self.send_json({"error": "APK файл оновлення ще не знайдено."}, status=404)
                return

        # 5. Отримання списку звітів про помилки JSON
        if path == "/api/telemetry/reports":
            crashes = get_all_crashes()
            self.send_json({"count": len(crashes), "reports": crashes})
            return

        self.send_error(404, "Endpoint not found")

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/api/telemetry/crash-report":
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length == 0:
                self.send_json({"error": "Empty body"}, status=400)
                return

            body = self.rfile.read(content_length)
            try:
                data = json.loads(body.decode("utf-8"))
            except Exception:
                self.send_json({"error": "Invalid JSON"}, status=400)
                return

            timestamp = datetime.now()
            report_id = timestamp.strftime("%Y%m%d_%H%M%S_%f")[:19]
            data["reportId"] = report_id
            data["receivedAt"] = timestamp.strftime("%Y-%m-%d %H:%M:%S")

            # Збереження в окремий файл
            fpath = os.path.join(CRASHES_DIR, f"crash_{report_id}.json")
            with open(fpath, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

            # Дописування в загальний лог
            log_line = f"[{data['receivedAt']}] 🚨 [{data.get('device', 'Unknown')}] {data.get('error', 'Unknown Error')}\n"
            with open(CRASH_LOG_FILE, "a", encoding="utf-8") as f:
                f.write(log_line)

            print(f"\033[91m[{data['receivedAt']}] 🚨 НОВИЙ ЗВІТ ПРО ПОМИЛКУ:\033[0m")
            print(f"  Пристрій: {data.get('device')} (Версія додатку: {data.get('appVersion')})")
            print(f"  Помилка:  \033[1m{data.get('error')}\033[0m")
            if data.get("stackTrace"):
                first_lines = "\n".join(data["stackTrace"].splitlines()[:3])
                print(f"  Стек:\n{first_lines}...")

            self.send_json({"status": "received", "reportId": report_id})
            return

        self.send_error(404, "Endpoint not found")

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def handle_dashboard(self):
        info = get_version_info()
        local_ip = get_local_ip()
        apk_path = os.path.join(UPDATES_DIR, info.get("apkFileName", "app-release.apk"))
        has_apk = os.path.exists(apk_path)
        apk_status = "✅ Готовий до роздачі" if has_apk else "⚠️ Відсутній (зберіть flutter build apk)"
        apk_size = f"{os.path.getsize(apk_path) / (1024 * 1024):.1f} MB" if has_apk else "0 MB"

        crashes = get_all_crashes()
        crashes_html = ""
        if not crashes:
            crashes_html = '<div class="empty-state">🎉 Звітів про помилки поки немає. Все працює стабільно!</div>'
        else:
            for c in crashes[:20]:
                stack = c.get("stackTrace", "").strip()
                trace_box = f'<pre class="crash-trace">{stack}</pre>' if stack else ""
                logs = c.get("recentLogs", [])
                logs_html = ""
                if logs:
                    logs_formatted = "\n".join(logs)
                    logs_html = f'<details style="margin-top:6px; font-size:11px; color:#aaa;"><summary style="cursor:pointer;">Останні дії перед збоєм ({len(logs)} рядків)</summary><pre class="crash-trace" style="color:#81c784;">{logs_formatted}</pre></details>'

                crashes_html += f"""
                <div class="crash-card">
                  <div class="crash-header">
                    <span>ID: #{c.get('reportId', 'N/A')}</span>
                    <span>{c.get('receivedAt', '')}</span>
                  </div>
                  <div class="crash-title">❌ {c.get('error', 'Невідома помилка')}</div>
                  <div class="crash-device">📱 {c.get('device', 'Невідомий пристрій')} • Додаток v{c.get('appVersion', '1.0')}</div>
                  {trace_box}
                  {logs_html}
                </div>
                """

        history = info.get("history", [])
        history_html = ""
        if history:
            items_html = []
            for h in history:
                v = h.get("version", "")
                b = h.get("buildNumber", "")
                d = h.get("releaseDate", "")
                cl = h.get("changelog", "").replace("\n", "<br>")
                items_html.append(f"""
                <div style="border-left: 3px solid var(--accent); padding-left: 10px; margin-bottom: 12px;">
                  <div style="font-size: 13px; font-weight: bold; color: var(--accent);">v{v} (build {b}) <span style="font-size: 11px; color: var(--text-muted); font-weight: normal;">• {d}</span></div>
                  <div style="font-size: 12px; color: #ddd; margin-top: 4px;">{cl}</div>
                </div>
                """)
            history_html = "".join(items_html)
        else:
            history_html = '<div style="color: var(--text-muted); font-size: 12px;">Історія релізів порожня.</div>'

        html = DASHBOARD_HTML
        html = html.replace("{{LOCAL_IP}}", local_ip)
        html = html.replace("{{PORT}}", str(PORT))
        html = html.replace("{{VERSION}}", str(info.get("version", "1.0.0")))
        html = html.replace("{{BUILD}}", str(info.get("buildNumber", 1)))
        html = html.replace("{{RELEASE_DATE}}", str(info.get("releaseDate", "-")))
        html = html.replace("{{APK_STATUS}}", apk_status)
        html = html.replace("{{APK_SIZE}}", apk_size)
        html = html.replace("{{CHANGELOG}}", str(info.get("changelog", "Немає опису")))
        html = html.replace("{{HISTORY_COUNT}}", str(len(history)))
        html = html.replace("{{HISTORY_HTML}}", history_html)
        html = html.replace("{{CRASH_COUNT}}", str(len(crashes)))
        html = html.replace("{{CRASHES_HTML}}", crashes_html)

        body = html.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def main():
    local_ip = get_local_ip()
    print("=" * 65)
    print("🎵 MusicFlow Update & Telemetry Server")
    print(f"📡 Локальна мережа:  http://{local_ip}:{PORT}")
    print(f"💻 На цьому ПК:      http://localhost:{PORT}")
    print(f"📊 Дашборд помилок:  http://{local_ip}:{PORT}/dashboard")
    print("=" * 65)
    print("Сервер готовий приймати оновлення та звіти про збої.")
    print("Натисніть Ctrl+C для зупинки.\n")

    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), MusicFlowRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nЗупинка сервера...")
            httpd.shutdown()


if __name__ == "__main__":
    main()
