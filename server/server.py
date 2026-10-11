#!/usr/bin/env python3
"""
MusicFlow Local Observability & Telemetry Server
Забезпечує живий моніторинг клієнтів, статус пристроїв та прийом звітів про збої.
"""

import http.server
import json
import os
import socketserver
import subprocess
import sys
from datetime import datetime
from urllib.parse import parse_qs, urlparse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", line_buffering=True)
        sys.stderr.reconfigure(encoding="utf-8", line_buffering=True)
    except Exception:
        pass

from dashboard_template import render_dashboard
from security import is_rate_limited
from storage import PORT, UPDATES_DIR, get_local_ip, get_version_info, get_all_crashes
from telemetry_handler import (
    ACTIVE_DEVICES, register_client, get_devices_status_list, save_crash_report
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

    def send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def handle_dashboard(self):
        page = render_dashboard(get_version_info(), get_local_ip(), PORT, get_all_crashes(), UPDATES_DIR, devices=ACTIVE_DEVICES).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(page)))
        self.end_headers()
        self.wfile.write(page)

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
        if path == "/api/telemetry/ping":
            q = parse_qs(parsed.query)
            register_client(self.client_address[0], q.get("device", [None])[0], q.get("version", [None])[0], q.get("channel", [None])[0])
            self.send_json({"status": "pong", "time": datetime.now().isoformat()})
            return
        if path == "/api/telemetry/heartbeat":
            q = parse_qs(parsed.query)
            register_client(self.client_address[0], q.get("device", [None])[0], q.get("version", [None])[0], q.get("channel", [None])[0], state=q.get("state", ["in_app"])[0], screen=q.get("screen", [None])[0])
            self.send_json({"status": "heartbeat_ack", "time": datetime.now().isoformat()})
            return
        if path in ("/api/telemetry/scan", "/api/telemetry/devices"):
            devices = get_devices_status_list()
            self.send_json({"count": len(devices), "devices": devices})
            return
        if path == "/api/update/check":
            self.send_json({"info": "MusicFlow оновлюється через GitHub Releases 24/7.", "githubUrl": "https://github.com/Lutvunenko-Dmutro/musicflow-mobile/releases", "buildNumber": 0})
            return
        if path == "/api/update/download":
            self.send_json({"info": "Завантаження APK на GitHub Releases: https://github.com/Lutvunenko-Dmutro/musicflow-mobile/releases"}, status=200)
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

        path = urlparse(self.path).path
        content_length = int(self.headers.get("Content-Length", 0))
        data = {}
        if content_length > 0:
            try:
                data = json.loads(self.rfile.read(content_length).decode("utf-8"))
            except Exception:
                self.send_json({"error": "Invalid JSON"}, status=400)
                return

        if path == "/api/telemetry/heartbeat":
            register_client(self.client_address[0], device_name=data.get("device"), version=data.get("appVersion") or data.get("version"), channel=data.get("channel"), state=data.get("state", "in_app"), screen=data.get("screen"), extra=data)
            self.send_json({"status": "heartbeat_ack", "time": datetime.now().isoformat()})
            return
        if path == "/api/telemetry/ping":
            register_client(self.client_address[0], device_name=data.get("device"), version=data.get("version"), channel=data.get("channel"), extra=data)
            self.send_json({"status": "pong", "time": datetime.now().isoformat()})
            return
        if path == "/api/telemetry/events":
            register_client(self.client_address[0], device_name=data.get("device"), version=data.get("appVersion"), channel=data.get("channel"))
            event_name = data.get("event", "unknown_event")
            print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 📈 Подія від {data.get('device')}: {event_name}")
            self.send_json({"status": "received", "event": event_name})
            return
        if path == "/api/telemetry/crash-report":
            report_id = save_crash_report(self.client_address[0], data)
            self.send_json({"status": "received", "reportId": report_id})
            return
        self.send_error(404, "Endpoint not found")


def kill_port_owner(port):
    if sys.platform == "win32":
        try:
            out = subprocess.check_output(f'netstat -aon | findstr :{port} | findstr LISTENING', shell=True).decode()
            for line in out.strip().splitlines():
                parts = line.split()
                if len(parts) >= 5 and parts[-1] != str(os.getpid()):
                    subprocess.run(f"taskkill /f /pid {parts[-1]}", shell=True, capture_output=True)
        except Exception:
            pass


def main():
    import time
    kill_port_owner(PORT)
    time.sleep(0.3)
    local_ip = get_local_ip()
    print("=" * 65)
    print("🎵 MusicFlow Observability & Telemetry Server")
    print(f"📡 Локальна мережа:  http://{local_ip}:{PORT}")
    print(f"💻 На цьому ПК:      http://localhost:{PORT}")
    print(f"📊 Дашборд моніторингу: http://{local_ip}:{PORT}/dashboard")
    print("=" * 65)

    if sys.platform != "win32":
        socketserver.ThreadingTCPServer.allow_reuse_address = True
    else:
        socketserver.ThreadingTCPServer.allow_reuse_address = False

    httpd = None
    for _ in range(3):
        try:
            httpd = socketserver.ThreadingTCPServer(("0.0.0.0", PORT), MusicFlowRequestHandler)
            break
        except OSError:
            kill_port_owner(PORT)
            time.sleep(1.0)

    if not httpd:
        print(f"❌ Не вдалося відкрити порт {PORT}.")
        return

    print("🟢 Сервер успішно запущено та очікує підключень...")
    with httpd:
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nЗупинка сервера...")
            httpd.shutdown()


if __name__ == "__main__":
    main()
