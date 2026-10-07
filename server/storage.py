import json
import os
import socket
import sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from security import calculate_sha256

PORT = 8080
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
CRASHES_DIR = os.path.join(DATA_DIR, "crashes")
UPDATES_DIR = os.path.join(DATA_DIR, "updates")
CRASH_LOG_FILE = os.path.join(DATA_DIR, "crash_reports.log")
VERSION_FILE = os.path.join(DATA_DIR, "version.json")

os.makedirs(CRASHES_DIR, exist_ok=True)
os.makedirs(UPDATES_DIR, exist_ok=True)


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


def get_version_info(apk_filename=None):
    try:
        with open(VERSION_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        filename = apk_filename or data.get("apkFileName", "app-release.apk")
        data["apkFileName"] = filename
        apk_path = find_best_apk_path(filename)
        if apk_path:
            data["fileSizeBytes"] = os.path.getsize(apk_path)
            data["resolvedApkPath"] = apk_path
            if not data.get("sha256"):
                data["sha256"] = calculate_sha256(apk_path)
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
