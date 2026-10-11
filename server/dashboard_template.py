import html
import os
from datetime import datetime

HTML_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dashboard.html")


def _load_template():
    if os.path.exists(HTML_FILE):
        with open(HTML_FILE, "r", encoding="utf-8") as f:
            return f.read()
    return "<html><body><h1>MusicFlow Dashboard</h1></body></html>"


def _build_device_rows(devices, now):
    device_rows = []
    online_count = 0
    for ip, dev in sorted(devices.items(), key=lambda x: x[1].get("last_seen_dt", now), reverse=True):
        last_dt = dev.get("last_seen_dt", now)
        diff_sec = int((now - last_dt).total_seconds())
        state = dev.get("state", "in_app")

        if diff_sec <= 15 and state == "in_app":
            status_html = '<span class="badge-online"><span class="pulse-dot"></span>У додатку (Активний)</span>'
            online_count += 1
            seen_text = "тільки що" if diff_sec < 5 else f"{diff_sec} сек тому"
        elif diff_sec <= 60 and state != "closed":
            status_html = '<span class="badge-recent">У фоні</span>'
            seen_text = f"{diff_sec} сек тому"
        else:
            status_html = '<span class="badge-offline">Офлайн (Закрито)</span>'
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
    return device_rows, online_count


def _build_devices_table(device_rows):
    if not device_rows:
        return '<div class="empty-state">📲 Немає підключених додатків. Відкрийте додаток MusicFlow на телефоні — він з&#39;явиться тут у реальному часі!</div>'
    return f"""
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


def _build_crashes_html(crashes):
    if not crashes:
        return '<div class="empty-state">🎉 Звітів про помилки поки немає. Все працює стабільно!</div>'
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
    return crashes_html


def _build_history_html(history):
    return "".join([f"""
    <div style="border-left: 3px solid var(--accent); padding-left: 10px; margin-bottom: 12px;">
      <div style="font-size: 13px; font-weight: bold; color: var(--accent);">v{html.escape(str(h.get('version', '')))} (build {h.get('buildNumber', '')}) <span style="font-size: 11px; color: var(--text-muted); font-weight: normal;">• {h.get('releaseDate', '')}</span></div>
      <div style="font-size: 12px; color: #ddd; margin-top: 4px;">{html.escape(str(h.get('changelog', ''))).replace(chr(10), '<br>')}</div>
    </div>""" for h in history]) or '<div style="color: var(--text-muted); font-size: 12px;">Історія релізів порожня.</div>'


def render_dashboard(info, local_ip, port, crashes, updates_dir, devices=None):
    apk_path = os.path.join(updates_dir, info.get("apkFileName", "app-release.apk"))
    has_apk = os.path.exists(apk_path)
    apk_status = "✅ Готовий до роздачі" if has_apk else "⚠️ Відсутній"
    apk_size = f"{os.path.getsize(apk_path) / (1024 * 1024):.1f} MB" if has_apk else "0 MB"

    now = datetime.now()
    devices = devices or {}
    device_rows, online_count = _build_device_rows(devices, now)
    devices_table_html = _build_devices_table(device_rows)
    crashes_html = _build_crashes_html(crashes)
    history = info.get("history", [])
    history_html = _build_history_html(history)

    html_page = _load_template()
    replacements = [
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
    ]
    for k, v in replacements:
        html_page = html_page.replace(k, v)
    return html_page
