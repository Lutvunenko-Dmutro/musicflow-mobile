#!/usr/bin/env python3
"""
MusicFlow Local Update & Telemetry Server
Забезпечує перевірку/завантаження оновлень та прийом звітів про збої.
"""

import http.server
import json
import os
import socketserver
import sys
from datetime import datetime
from urllib.parse import parse_qs, urlparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dashboard_template import render_dashboard
from security import is_rate_limited, sanitize_telemetry
from storage import (
    PORT, UPDATES_DIR, CRASHES_DIR, CRASH_LOG_FILE,
    get_local_ip, find_best_apk_path, get_version_info, get_all_crashes
)


class MusicFlowRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if is_rate_limited(self.client_address[0]):
            self.send_json({"error": "Забагато запитів. Зачекайте хвилину."}, status=429)
            return

        parsed = urlparse(self.path)
        path = parsed.path

        if path in ("/", "/dashboard"):
            self.handle_dashboard()
            return

        if path == "/api/health":
            self.send_json({"status": "ok", "time": datetime.now().isoformat()})
            return

        if path == "/api/update/check":
            query = parse_qs(parsed.query)
            channel = query.get("channel", ["release"])[0].lower()
            apk_filename = "app-debug.apk" if channel == "debug" else "app-release.apk"
            info = get_version_info(apk_filename)
            local_ip = get_local_ip()
            info["downloadUrl"] = f"http://{local_ip}:{PORT}/api/update/download?channel={channel}"
            info["channel"] = channel

            c_param = query.get("currentBuild", [None])[0]
            if c_param:
                try:
                    c_build = int(c_param)
                    info["missedCount"] = len([h for h in info.get("history", []) if h.get("buildNumber", 0) > c_build])
                except Exception:
                    pass
            self.send_json(info)
            return

        if path == "/api/update/download":
            query = parse_qs(parsed.query)
            channel = query.get("channel", ["release"])[0].lower()
            apk_filename = "app-debug.apk" if channel == "debug" else "app-release.apk"
            apk_path = find_best_apk_path(apk_filename)
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
                print(f"[{datetime.now().strftime('%H:%M:%S')}] 📲 APK завантажено ({file_size // 1024} KB)")
                return
            self.send_json({"error": "APK файл не знайдено"}, status=404)
            return

        if path == "/api/telemetry/reports":
            crashes = get_all_crashes()
            self.send_json({"count": len(crashes), "reports": crashes})
            return

        self.send_error(404, "Endpoint not found")

    def do_POST(self):
        if is_rate_limited(self.client_address[0]):
            self.send_json({"error": "Забагато запитів. Зачекайте хвилину."}, status=429)
            return

        if urlparse(self.path).path == "/api/telemetry/crash-report":
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length == 0:
                self.send_json({"error": "Empty body"}, status=400)
                return
            try:
                data = json.loads(self.rfile.read(content_length).decode("utf-8"))
            except Exception:
                self.send_json({"error": "Invalid JSON"}, status=400)
                return

            data = sanitize_telemetry(data)
            now = datetime.now()
            report_id = now.strftime("%Y%m%d_%H%M%S_%f")[:19]
            data["reportId"] = report_id
            data["receivedAt"] = now.strftime("%Y-%m-%d %H:%M:%S")

            fpath = os.path.join(CRASHES_DIR, f"crash_{report_id}.json")
            with open(fpath, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)

            with open(CRASH_LOG_FILE, "a", encoding="utf-8") as f:
                f.write(f"[{data['receivedAt']}] 🚨 [{data.get('device', 'Unknown')}] {data.get('error', 'Error')}\n")

            print(f"[{data['receivedAt']}] 🚨 Звіт про помилку від {data.get('device')}: {data.get('error')}")
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
        crashes = get_all_crashes()
        page = render_dashboard(info, local_ip, PORT, crashes, UPDATES_DIR)
        body = page.encode("utf-8")
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
    socketserver.ThreadingTCPServer.allow_reuse_address = True
    with socketserver.ThreadingTCPServer(("0.0.0.0", PORT), MusicFlowRequestHandler) as httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nЗупинка сервера...")
            httpd.shutdown()


if __name__ == "__main__":
    main()
