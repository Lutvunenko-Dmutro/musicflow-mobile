#!/usr/bin/env python3
"""
MusicFlow Local Update & Telemetry Server
Забезпечує перевірку/завантаження оновлень та прийом звітів про збої.
"""

import http.server
import json
import os
import re
import socketserver
import subprocess
import sys
import threading
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
from security import is_rate_limited, sanitize_telemetry
from storage import (
    PORT, UPDATES_DIR, CRASHES_DIR, CRASH_LOG_FILE,
    get_local_ip, find_best_apk_path, get_version_info, get_all_crashes
)

ACTIVE_DEVICES = {}


def register_client(ip, device_name=None, version=None, channel=None, state=None, screen=None, extra=None):
    now = datetime.now()
    existing = ACTIVE_DEVICES.get(ip, {})
    dev_name = device_name or existing.get("device") or "Android Пристрій"
    ver = version or existing.get("version") or "1.0.0"
    chan = (channel or existing.get("channel") or "release").upper()
    cur_state = state or "in_app"
    cur_screen = screen or existing.get("screen") or "MusicFlow App"

    ACTIVE_DEVICES[ip] = {
        "device": dev_name,
        "version": ver,
        "channel": chan,
        "state": cur_state,
        "screen": cur_screen,
        "last_seen_dt": now,
        "last_seen_str": now.strftime("%H:%M:%S"),
        "extra": extra or existing.get("extra", {}),
    }


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

        if path == "/api/telemetry/ping":
            query = parse_qs(parsed.query)
            dev_name = query.get("device", [None])[0]
            ver = query.get("version", [None])[0]
            chan = query.get("channel", [None])[0]
            register_client(self.client_address[0], dev_name, ver, chan)
            self.send_json({"status": "pong", "time": datetime.now().isoformat()})
            return

        if path == "/api/telemetry/heartbeat":
            query = parse_qs(parsed.query)
            dev_name = query.get("device", [None])[0]
            ver = query.get("version", [None])[0]
            chan = query.get("channel", [None])[0]
            st = query.get("state", ["in_app"])[0]
            scr = query.get("screen", [None])[0]
            register_client(self.client_address[0], dev_name, ver, chan, state=st, screen=scr)
            self.send_json({"status": "heartbeat_ack", "time": datetime.now().isoformat()})
            return

        if path in ("/api/telemetry/scan", "/api/telemetry/devices"):
            result = []
            now = datetime.now()
            for ip, d in ACTIVE_DEVICES.items():
                diff_sec = int((now - d.get("last_seen_dt", now)).total_seconds())
                is_online = (diff_sec <= 15 and d.get("state") == "in_app")
                result.append({
                    "ip": ip,
                    "device": d.get("device"),
                    "version": d.get("version"),
                    "channel": d.get("channel"),
                    "state": d.get("state"),
                    "screen": d.get("screen"),
                    "lastSeenSecondsAgo": diff_sec,
                    "isOnline": is_online,
                })
            self.send_json({"count": len(result), "devices": result})
            return

        if path == "/api/update/check":
            query = parse_qs(parsed.query)
            channel = query.get("channel", ["release"])[0].lower()
            if channel not in ("release", "debug"):
                self.send_json({"error": "Недійсний канал. Дозволено: release, debug"}, status=400)
                return

            dev_name = query.get("device", [None])[0] or self.headers.get("X-Device-Model")
            ver_name = query.get("version", [None])[0]
            register_client(self.client_address[0], dev_name, ver_name, channel)

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
            if channel not in ("release", "debug"):
                self.send_json({"error": "Недійсний канал. Дозволено: release, debug"}, status=400)
                return

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

        if urlparse(self.path).path == "/api/telemetry/heartbeat":
            content_length = int(self.headers.get("Content-Length", 0))
            data = {}
            if content_length > 0:
                try:
                    data = json.loads(self.rfile.read(content_length).decode("utf-8"))
                except Exception:
                    pass
            register_client(
                self.client_address[0],
                device_name=data.get("device"),
                version=data.get("appVersion") or data.get("version"),
                channel=data.get("channel"),
                state=data.get("state", "in_app"),
                screen=data.get("screen"),
                extra=data,
            )
            self.send_json({"status": "heartbeat_ack", "time": datetime.now().isoformat()})
            return

        if urlparse(self.path).path == "/api/telemetry/ping":
            content_length = int(self.headers.get("Content-Length", 0))
            data = {}
            if content_length > 0:
                try:
                    data = json.loads(self.rfile.read(content_length).decode("utf-8"))
                except Exception:
                    pass
            register_client(
                self.client_address[0],
                device_name=data.get("device"),
                version=data.get("version") or (f"build {data.get('buildNumber')}" if data.get('buildNumber') else None),
                channel=data.get("channel"),
                extra=data,
            )
            self.send_json({"status": "pong", "time": datetime.now().isoformat()})
            return

        if urlparse(self.path).path == "/api/telemetry/events":
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length == 0:
                self.send_json({"error": "Empty body"}, status=400)
                return
            try:
                data = json.loads(self.rfile.read(content_length).decode("utf-8"))
            except Exception:
                self.send_json({"error": "Invalid JSON"}, status=400)
                return

            register_client(
                self.client_address[0],
                device_name=data.get("device"),
                version=data.get("appVersion"),
                channel=data.get("channel"),
            )
            now = datetime.now()
            event_name = data.get("event", "unknown_event")
            print(f"[{now.strftime('%Y-%m-%d %H:%M:%S')}] 📈 Подія від {data.get('device')}: {event_name}")
            self.send_json({"status": "received", "event": event_name})
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
            register_client(
                self.client_address[0],
                device_name=data.get("device"),
                version=data.get("appVersion"),
                channel=data.get("channel"),
            )
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
        page = render_dashboard(info, local_ip, PORT, crashes, UPDATES_DIR, devices=ACTIVE_DEVICES)
        body = page.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def kill_port_owner(port):
    if sys.platform == "win32":
        try:
            import subprocess
            out = subprocess.check_output(f'netstat -aon | findstr :{port} | findstr LISTENING', shell=True).decode()
            for line in out.strip().splitlines():
                parts = line.split()
                if len(parts) >= 5:
                    pid = parts[-1]
                    if pid != str(os.getpid()):
                        subprocess.run(f"taskkill /f /pid {pid}", shell=True, capture_output=True)
        except Exception:
            pass


def main():
    import time
    kill_port_owner(PORT)
    time.sleep(0.3)
    local_ip = get_local_ip()
    print("=" * 65)
    print("🎵 MusicFlow Update & Telemetry Server")
    print(f"📡 Локальна мережа:  http://{local_ip}:{PORT}")
    print(f"💻 На цьому ПК:      http://localhost:{PORT}")
    print(f"📊 Дашборд помилок:  http://{local_ip}:{PORT}/dashboard")
    print("=" * 65)

    if sys.platform != "win32":
        socketserver.ThreadingTCPServer.allow_reuse_address = True
    else:
        socketserver.ThreadingTCPServer.allow_reuse_address = False

    httpd = None
    for attempt in range(3):
        try:
            httpd = socketserver.ThreadingTCPServer(("0.0.0.0", PORT), MusicFlowRequestHandler)
            break
        except OSError as e:
            if e.errno in (10048, 98):
                print(f"⚠️ Порт {PORT} зайнято попереднім процесом. Звільняю...")
                kill_port_owner(PORT)
                time.sleep(1.0)
            else:
                raise

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
