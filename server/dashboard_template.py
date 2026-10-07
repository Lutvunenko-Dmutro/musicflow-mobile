import html
import os

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
          <li>Для оновлення версії запустіть <code style="color: #fff;">python server/publish_release.py</code>.</li>
        </ul>
      </div>
    </div>

    <div class="card">
      <h2>🛡️ Звіти про помилки (Телеметрія за згодою) <span style="font-size: 12px; color: var(--text-muted);">({{CRASH_COUNT}} отримано)</span></h2>
      <div id="crashes-list">{{CRASHES_HTML}}</div>
    </div>
  </div>
</body>
</html>
"""


def render_dashboard(info, local_ip, port, crashes, updates_dir):
    apk_path = os.path.join(updates_dir, info.get("apkFileName", "app-release.apk"))
    has_apk = os.path.exists(apk_path)
    apk_status = "✅ Готовий до роздачі" if has_apk else "⚠️ Відсутній"
    apk_size = f"{os.path.getsize(apk_path) / (1024 * 1024):.1f} MB" if has_apk else "0 MB"

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
