import json
import os
from datetime import datetime

from security import sanitize_telemetry
from storage import CRASHES_DIR, CRASH_LOG_FILE

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


def get_devices_status_list():
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
    return result


def save_crash_report(ip, raw_data):
    data = sanitize_telemetry(raw_data)
    register_client(
        ip,
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
    return report_id
