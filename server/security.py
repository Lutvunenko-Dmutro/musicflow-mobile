import hashlib
import os
import re
import time

RATE_LIMIT_STORE = {}
MAX_REQUESTS_PER_MINUTE = 120


def is_rate_limited(ip):
    now = time.time()
    timestamps = RATE_LIMIT_STORE.get(ip, [])
    timestamps = [t for t in timestamps if now - t < 60]
    if len(timestamps) >= MAX_REQUESTS_PER_MINUTE:
        RATE_LIMIT_STORE[ip] = timestamps
        return True
    timestamps.append(now)
    RATE_LIMIT_STORE[ip] = timestamps
    return False


def calculate_sha256(filepath):
    if not filepath or not os.path.exists(filepath):
        return None
    sha = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(64 * 1024):
            sha.update(chunk)
    return sha.hexdigest()


def sanitize_telemetry(data):
    if not isinstance(data, dict):
        return data
    cleaned = dict(data)
    for key in ("error", "stackTrace", "message", "deviceInfo", "device"):
        val = cleaned.get(key)
        if isinstance(val, str):
            val = re.sub(r'([A-Za-z]:\\Users\\)[^\\]+(\\)', r'\1***\2', val)
            val = re.sub(r'(/home/)[^/]+(/)', r'\1***\2', val)
            cleaned[key] = val
    return cleaned
