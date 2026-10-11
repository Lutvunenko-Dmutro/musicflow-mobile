import html
import os
from datetime import datetime

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
    .card { background: var(--card); border: 1px solid var(--card-border); border-radius: 14px; padding: 20px; margin-bottom: 24px; }
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

    /* Таблиця підключених пристроїв */
    .table-container { overflow-x: auto; margin-top: 10px; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; text-align: left; }
    th { background: #252525; color: var(--text-muted); padding: 10px 14px; font-weight: 600; border-bottom: 1px solid var(--card-border); }
    td { padding: 12px 14px; border-bottom: 1px solid #282828; }
    .badge-online { background: rgba(46, 125, 50, 0.2); border: 1px solid #2e7d32; color: #81c784; font-size: 11px; padding: 3px 8px; border-radius: 12px; font-weight: bold; display: inline-flex; align-items: center; gap: 6px; }
    .badge-recent { background: rgba(245, 127, 23, 0.2); border: 1px solid #f57f17; color: #ffb74d; font-size: 11px; padding: 3px 8px; border-radius: 12px; font-weight: bold; }
    .badge-offline { background: rgba(66, 66, 66, 0.2); border: 1px solid #555; color: #aaa; font-size: 11px; padding: 3px 8px; border-radius: 12px; }
    .pulse-dot { width: 8px; height: 8px; background: #69f0ae; border-radius: 50%; box-shadow: 0 0 8px #69f0ae; display: inline-block; animation: pulse 1.5s infinite; }
    @keyframes pulse { 0% { opacity: 0.4; transform: scale(0.9); } 50% { opacity: 1; transform: scale(1.2); } 100% { opacity: 0.4; transform: scale(0.9); } }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <h1>🎵 MusicFlow <span class="badge">SERVER ONLINE</span></h1>
      <div class="badge-ip">IP: {{LOCAL_IP}}:{{PORT}}</div>
    </header>

    <!-- БЛОК ПІДКЛЮЧЕНИХ ПРИСТРОЇВ -->
    <div class="card">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; flex-wrap: wrap; gap: 10px;">
        <h2 style="margin-bottom: 0;">📡 Підключені пристрої в мережі Wi-Fi <span class="badge" style="background: #1976d2;">{{ONLINE_COUNT}} в мережі</span></h2>
        <div style="display: flex; align-items: center; gap: 10px;">
          <span style="font-size: 11px; color: var(--text-muted);" id="scan-status">🟢 Моніторинг у реальному часі</span>
          <button onclick="triggerScan()" class="btn btn-secondary" style="font-size: 12px; padding: 6px 14px; cursor: pointer; display: flex; align-items: center; gap: 6px;" id="scan-btn">
            🔄 Сканувати та оновити зараз
          </button>
        </div>
      </div>
      <div class="table-container">
        {{DEVICES_TABLE_HTML}}
      </div>
    </div>

    <div class="grid">
      <div class="card" style="margin-bottom: 0;">
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

      <div class="card" style="margin-bottom: 0;">
        <h2>📱 Підключення додатку з телефону</h2>
        <p style="font-size: 13px; color: var(--text-muted); margin-bottom: 12px;">
          Введіть цю адресу в мобільному додатку у розділі <b>Налаштування → Оновлення та Телеметрія</b>:
        </p>
        <div style="background: #000; padding: 12px; border-radius: 8px; font-family: monospace; font-size: 14px; color: var(--accent); margin-bottom: 16px; user-select: all;">
          http://{{LOCAL_IP}}:{{PORT}}
        </div>
        <ul style="font-size: 12px; color: #aaa; line-height: 1.6; padding-left: 18px;">
          <li>Телефон і ПК мають бути підключені до одного Wi-Fi роутера.</li>
          <li>Щойно додаток відкриється або перевірить оновлення, він <b>миттєво з'явиться в таблиці вище</b>!</li>
          <li>Звіти про помилки надсилаються <b>тільки якщо користувач дав згоду</b>.</li>
          <li>Для випуску версії запустіть <code style="color: #fff;">publish.bat</code>.</li>
        </ul>
      </div>
    </div>

    <div class="card">
      <h2>🛡️ Звіти про помилки (Телеметрія за згодою) <span style="font-size: 12px; color: var(--text-muted);">({{CRASH_COUNT}} отримано)</span></h2>
      <div id="crashes-list">{{CRASHES_HTML}}</div>
    </div>
  </div>

  <script>
    function triggerScan() {
      const btn = document.getElementById("scan-btn");
      if (btn) btn.innerText = "⏳ Сканування...";
      fetch("/api/telemetry/scan")
        .then(() => { location.reload(); })
        .catch(() => { location.reload(); });
    }

    // Автоматичне фонове оновлення дашборду кожні 4 секунди
    setTimeout(function() {
      location.reload();
    }, 4000);
  </script>
</body>
</html>
"""


def render_dashboard(info, local_ip, port, crashes, updates_dir, devices=None):
    apk_path = os.path.join(updates_dir, info.get("apkFileName", "app-release.apk"))
    has_apk = os.path.exists(apk_path)
    apk_status = "✅ Готовий до роздачі" if has_apk else "⚠️ Відсутній"
    apk_size = f"{os.path.getsize(apk_path) / (1024 * 1024):.1f} MB" if has_apk else "0 MB"

    now = datetime.now()
    devices = devices or {}
    online_count = 0
    device_rows = []

    for ip, dev in sorted(devices.items(), key=lambda x: x[1].get("last_seen_dt", now), reverse=True):
        last_dt = dev.get("last_seen_dt", now)
        diff_sec = int((now - last_dt).total_seconds())

        if diff_sec < 90:
            status_html = '<span class="badge-online"><span class="pulse-dot"></span>Онлайн</span>'
            online_count += 1
            seen_text = "тільки що" if diff_sec < 10 else f"{diff_sec} сек тому"
        elif diff_sec < 600:
            status_html = '<span class="badge-recent">Нещодавно</span>'
            seen_text = f"{diff_sec // 60} хв тому"
        else:
            status_html = '<span class="badge-offline">Офлайн</span>'
            seen_text = dev.get("last_seen_str", "—")

        device_rows.append(f"""
        <tr>
          <td>{status_html}</td>
          <td><b>📱 {html.escape(str(dev.get('device', 'Android Пристрій')))}</b></td>
          <td><code style="color: #80d8ff;">{html.escape(str(ip))}</code></td>
          <td>{html.escape(str(dev.get('version', '—')))}</td>
          <td><span style="background: #333; padding: 2px 6px; border-radius: 4px; font-size: 11px;">{html.escape(str(dev.get('channel', 'RELEASE')))}</span></td>
          <td style="color: var(--text-muted);">{seen_text}</td>
        </tr>""")

    if not device_rows:
        devices_table_html = '<div class="empty-state">📡 Активних пристроїв поки не виявлено. Перевірте, що телефон у тій же мережі Wi-Fi, та відкрийте додаток MusicFlow!</div>'
    else:
        devices_table_html = f"""
        <table>
          <thead>
            <tr>
              <th>Статус</th>
              <th>Модель пристрою</th>
              <th>IP-адреса Wi-Fi</th>
              <th>Встановлена версія</th>
              <th>Канал</th>
              <th>Останній відгук</th>
            </tr>
          </thead>
          <tbody>
            {''.join(device_rows)}
          </tbody>
        </table>"""

    if not crashes:
        crashes_html = '<div class="empty-state">🎉 Звітів про помилки поки немає. Все працює стабільно!</div>'
    else:
        crashes_html = ""
        for c in crashes[:20]:
            stack = html.escape(c.get("stackTrace", "").strip())
            trace_box = f'<pre class="crash-trace">{stack}</pre>' if stack else ""
            logs = c.get("recentLogs", [])
            logs_html = ""
            if logs:
                logs_formatted = html.escape("\n".join(logs))
                logs_html = f'<details style="margin-top:6px; font-size:11px; color:#aaa;"><summary style="cursor:pointer;">Дії ({len(logs)} рядків)</summary><pre class="crash-trace" style="color:#81c784;">{logs_formatted}</pre></details>'
            crashes_html += f"""
            <div class="crash-card">
              <div class="crash-header"><span>#{html.escape(str(c.get('reportId', 'N/A')))}</span><span>{html.escape(str(c.get('receivedAt', '')))}</span></div>
              <div class="crash-title">❌ {html.escape(str(c.get('error', 'Невідома помилка')))}</div>
              <div class="crash-device">📱 {html.escape(str(c.get('device', 'Невідомий')))} • v{html.escape(str(c.get('appVersion', '1.0')))}</div>
              {trace_box}{logs_html}
            </div>"""

    history = info.get("history", [])
    history_html = "".join([f"""
    <div style="border-left: 3px solid var(--accent); padding-left: 10px; margin-bottom: 12px;">
      <div style="font-size: 13px; font-weight: bold; color: var(--accent);">v{html.escape(str(h.get('version', '')))} (build {h.get('buildNumber', '')}) <span style="font-size: 11px; color: var(--text-muted); font-weight: normal;">• {h.get('releaseDate', '')}</span></div>
      <div style="font-size: 12px; color: #ddd; margin-top: 4px;">{html.escape(str(h.get('changelog', ''))).replace(chr(10), '<br>')}</div>
    </div>""" for h in history]) or '<div style="color: var(--text-muted); font-size: 12px;">Історія релізів порожня.</div>'

    html_page = DASHBOARD_HTML
    for k, v in [
        ("{{LOCAL_IP}}", local_ip), ("{{PORT}}", str(port)),
        ("{{ONLINE_COUNT}}", str(online_count)),
        ("{{DEVICES_TABLE_HTML}}", devices_table_html),
        ("{{VERSION}}", str(info.get("version", "1.0.0"))),
        ("{{BUILD}}", str(info.get("buildNumber", 1))),
        ("{{RELEASE_DATE}}", str(info.get("releaseDate", "-"))),
        ("{{APK_STATUS}}", apk_status), ("{{APK_SIZE}}", apk_size),
        ("{{CHANGELOG}}", str(info.get("changelog", "Немає опису"))),
        ("{{HISTORY_COUNT}}", str(len(history))), ("{{HISTORY_HTML}}", history_html),
        ("{{CRASH_COUNT}}", str(len(crashes))), ("{{CRASHES_HTML}}", crashes_html),
    ]:
        html_page = html_page.replace(k, v)
    return html_page
