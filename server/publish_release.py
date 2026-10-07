#!/usr/bin/env python3
"""
MusicFlow Release Automation Script
Повністю автоматизує створення та публікацію нового релізу в 1 команду.
"""

import argparse
import json
import os
import sys
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from build_ops import run_preflight_checks, compile_and_copy_apk
from git_ops import git_commit_and_tag
from security import calculate_sha256
from version_ops import (
    get_current_pubspec_version,
    update_pubspec_version,
    compute_next_version
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)
PUBSPEC_PATH = os.path.join(PROJECT_DIR, "pubspec.yaml")
UPDATES_DIR = os.path.join(BASE_DIR, "data", "updates")
VERSION_JSON_PATH = os.path.join(BASE_DIR, "data", "version.json")


def save_version_manifest(new_version, new_build, changelog, apk_name, apk_path):
    os.makedirs(UPDATES_DIR, exist_ok=True)
    existing_history = []
    if os.path.exists(VERSION_JSON_PATH):
        try:
            with open(VERSION_JSON_PATH, "r", encoding="utf-8") as f:
                existing_history = json.load(f).get("history", [])
        except Exception:
            pass

    file_size = os.path.getsize(apk_path)
    apk_sha256 = calculate_sha256(apk_path)
    print(f"       🔒 SHA-256: {apk_sha256}")

    entry = {
        "version": new_version,
        "buildNumber": new_build,
        "releaseDate": datetime.now().strftime("%Y-%m-%d"),
        "changelog": changelog,
        "sha256": apk_sha256
    }
    history = [entry] + [h for h in existing_history if h.get("buildNumber") != new_build]
    manifest = {
        "version": new_version,
        "buildNumber": new_build,
        "releaseDate": datetime.now().strftime("%Y-%m-%d"),
        "changelog": changelog,
        "apkFileName": apk_name,
        "fileSizeBytes": file_size,
        "sha256": apk_sha256,
        "history": history
    }
    with open(VERSION_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)
    return file_size


def publish_release(changelog=None, bump_type="patch", mode="release", skip_verify=False, skip_git=False):
    print("=" * 65)
    print("🚀 MusicFlow • Автоматична публікація нового оновлення")
    print(f"📦 Режим збірки: {mode.upper()}")
    print("=" * 65)

    run_preflight_checks(PROJECT_DIR, skip=skip_verify)

    cur_maj, cur_min, cur_pat, cur_bld = get_current_pubspec_version(PUBSPEC_PATH)
    n_maj, n_min, n_pat, n_bld = compute_next_version(cur_maj, cur_min, cur_pat, cur_bld, bump_type)
    new_version_display = f"{n_maj}.{n_min}.{n_pat}"

    if not changelog:
        print(f"\n📝 Нова версія: v{new_version_display} (build {n_bld})")
        user_input = input("Введіть опис змін: ").strip()
        changelog = user_input.replace('\\n', '\n') if user_input else f"• Оновлення v{new_version_display}"
    else:
        changelog = changelog.replace('\\n', '\n')

    print(f"\n[1/6] ✏️  Оновлюю pubspec.yaml -> {new_version_display}+{n_bld}...")
    update_pubspec_version(PUBSPEC_PATH, n_maj, n_min, n_pat, n_bld)

    print(f"\n[2/6] 🔨 Компілюю APK через Flutter...")
    os.makedirs(UPDATES_DIR, exist_ok=True)
    primary_apk = None
    if mode in ("release", "both"):
        primary_apk = compile_and_copy_apk(PROJECT_DIR, UPDATES_DIR, "release", "app-release.apk", "app-release.apk")
        if not primary_apk:
            update_pubspec_version(PUBSPEC_PATH, cur_maj, cur_min, cur_pat, cur_bld)
            sys.exit(1)
    if mode in ("debug", "both"):
        dbg_apk = compile_and_copy_apk(PROJECT_DIR, UPDATES_DIR, "debug", "app-debug.apk", "app-debug.apk")
        if not primary_apk:
            primary_apk = dbg_apk

    print(f"[3/6] 📦 APK файли синхронізовано у {UPDATES_DIR}")
    print(f"[4/6] 📄 Оновлюю version.json...")
    apk_name = "app-release.apk" if mode != "debug" else "app-debug.apk"
    file_size = save_version_manifest(new_version_display, n_bld, changelog, apk_name, primary_apk)

    git_commit_and_tag(PROJECT_DIR, new_version_display, n_bld, skip_git=skip_git)

    print(f"[6/6] 🎉 ГОТОВО!")
    print(f"✨ Реліз v{new_version_display} (build {n_bld}) успішно створено та опубліковано!")
    print(f"💾 Розмір: {file_size / (1024 * 1024):.1f} MB (режим: {mode})")
    print("=" * 65)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Автоматична публікація релізів MusicFlow")
    parser.add_argument("--changelog", "-c", type=str, default=None, help="Опис змін")
    parser.add_argument("--bump", "-b", choices=["patch", "minor", "major", "build_only"], default="patch")
    parser.add_argument("--mode", "-m", choices=["both", "release", "debug"], default="release")
    parser.add_argument("--skip-verify", action="store_true", help="Пропустити тести")
    parser.add_argument("--skip-git", action="store_true", help="Пропустити git push")
    args = parser.parse_args()
    publish_release(args.changelog, args.bump, args.mode, args.skip_verify, args.skip_git)
