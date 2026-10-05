#!/usr/bin/env python3
"""
MusicFlow Release Automation Script
Повністю автоматизує створення та публікацію нового релізу:
1. Збільшує версію в pubspec.yaml (наприклад: 1.0.1+2 -> 1.0.2+3)
2. Компілює свіжий APK: `flutter build apk --debug`
3. Копіює створений файл у папку сервера `server/data/updates/`
4. Рахує точний розмір APK у байтах
5. Оновлює `server/data/version.json` з описом змін
6. Будь-який підключений телефон одразу бачить оновлення через Wi-Fi
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)
PUBSPEC_PATH = os.path.join(PROJECT_DIR, "pubspec.yaml")
UPDATES_DIR = os.path.join(BASE_DIR, "data", "updates")
VERSION_JSON_PATH = os.path.join(BASE_DIR, "data", "version.json")
BUILT_APK_DEBUG = os.path.join(PROJECT_DIR, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
BUILT_APK_RELEASE = os.path.join(PROJECT_DIR, "build", "app", "outputs", "flutter-apk", "app-release.apk")


def get_current_pubspec_version():
    with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)", content, re.MULTILINE)
    if not match:
        raise ValueError("Не вдалося знайти поле version у pubspec.yaml")
    major, minor, patch, build = map(int, match.groups())
    return major, minor, patch, build


def update_pubspec_version(major, minor, patch, build):
    new_version_str = f"{major}.{minor}.{patch}+{build}"
    with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    updated = re.sub(
        r"^version:\s*\d+\.\d+\.\d+\+\d+",
        f"version: {new_version_str}",
        content,
        flags=re.MULTILINE
    )
    with open(PUBSPEC_PATH, "w", encoding="utf-8") as f:
        f.write(updated)
    return new_version_str


def publish_release(changelog=None, bump_type="patch", mode="release"):
    print("=" * 65)
    print("🚀 MusicFlow • Автоматична публікація нового оновлення")
    print(f"📦 Режим збірки: {mode.upper()}")
    print("=" * 65)

    major, minor, patch, build = get_current_pubspec_version()
    old_version_str = f"{major}.{minor}.{patch}+{build}"
    print(f"📌 Поточна версія проєкту: v{major}.{minor}.{patch} (build {build})")

    # Розрахунок нової версії
    new_build = build + 1
    if bump_type == "minor":
        new_major, new_minor, new_patch = major, minor + 1, 0
    elif bump_type == "major":
        new_major, new_minor, new_patch = major + 1, 0, 0
    elif bump_type == "build_only":
        new_major, new_minor, new_patch = major, minor, patch
    else:  # patch за замовчуванням
        new_major, new_minor, new_patch = major, minor, patch + 1

    new_version_display = f"{new_major}.{new_minor}.{new_patch}"
    new_full_version = f"{new_version_display}+{new_build}"

    if not changelog:
        print(f"\n📝 Нова версія буде: v{new_version_display} (build {new_build})")
        user_input = input("Введіть опис змін (Що нового в оновленні): ").strip()
        if user_input:
            changelog = user_input.replace('\\n', '\n')
        else:
            changelog = f"• Оновлення v{new_version_display}: виправлення помилок та оптимізація"
    else:
        changelog = changelog.replace('\\n', '\n')

    # 1. Оновлення pubspec.yaml
    print(f"\n[1/5] ✏️  Оновлюю pubspec.yaml: {old_version_str} -> {new_full_version}...")
    update_pubspec_version(new_major, new_minor, new_patch, new_build)

    # 2. Компіляція APK
    print(f"\n[2/5] 🔨 Компілюю APK через Flutter...")
    os.makedirs(UPDATES_DIR, exist_ok=True)
    build_release = (mode in ("release", "both"))
    build_debug = (mode in ("debug", "both"))

    if build_release:
        print(f"       -> Збірка RELEASE (`flutter build apk --release`)...")
        res = subprocess.run(["flutter", "build", "apk", "--release"], cwd=PROJECT_DIR, shell=True)
        if res.returncode != 0:
            print("\n❌ Помилка під час збірки Release APK! Відновлюю версію у pubspec.yaml...")
            update_pubspec_version(major, minor, patch, build)
            sys.exit(1)
        shutil.copy2(BUILT_APK_RELEASE, os.path.join(UPDATES_DIR, "app-release.apk"))
        rel_size = os.path.getsize(BUILT_APK_RELEASE)
        print(f"       ✅ Release APK готово: {rel_size / (1024 * 1024):.1f} MB")

    if build_debug:
        print(f"       -> Збірка DEBUG (`flutter build apk --debug`)...")
        res = subprocess.run(["flutter", "build", "apk", "--debug"], cwd=PROJECT_DIR, shell=True)
        if res.returncode != 0:
            print("\n❌ Помилка під час збірки Debug APK! Відновлюю версію у pubspec.yaml...")
            update_pubspec_version(major, minor, patch, build)
            sys.exit(1)
        shutil.copy2(BUILT_APK_DEBUG, os.path.join(UPDATES_DIR, "app-debug.apk"))
        dbg_size = os.path.getsize(BUILT_APK_DEBUG)
        print(f"       ✅ Debug APK готово: {dbg_size / (1024 * 1024):.1f} MB")

    primary_apk = BUILT_APK_RELEASE if build_release else BUILT_APK_DEBUG
    file_size = os.path.getsize(primary_apk)
    apk_file_name = "app-release.apk" if build_release else "app-debug.apk"

    # 3. Копіювання у папку сервера
    print(f"[3/5] 📦 APK файли успішно синхронізовано у сховищі сервера ({UPDATES_DIR})")

    # 4. Оновлення version.json з підтримкою повної історії релізів
    print(f"[4/5] 📄 Оновлюю інформацію про реліз у version.json...")
    existing_history = []
    if os.path.exists(VERSION_JSON_PATH):
        try:
            with open(VERSION_JSON_PATH, "r", encoding="utf-8") as f:
                old_data = json.load(f)
                existing_history = old_data.get("history", [])
                if not existing_history and "version" in old_data:
                    existing_history.append({
                        "version": old_data.get("version"),
                        "buildNumber": old_data.get("buildNumber"),
                        "releaseDate": old_data.get("releaseDate", ""),
                        "changelog": old_data.get("changelog", "")
                    })
        except Exception:
            pass

    new_release_entry = {
        "version": new_version_display,
        "buildNumber": new_build,
        "releaseDate": datetime.now().strftime("%Y-%m-%d"),
        "changelog": changelog
    }
    updated_history = [new_release_entry] + [h for h in existing_history if h.get("buildNumber") != new_build]

    version_data = {
        "version": new_version_display,
        "buildNumber": new_build,
        "releaseDate": datetime.now().strftime("%Y-%m-%d"),
        "changelog": changelog,
        "apkFileName": apk_file_name,
        "fileSizeBytes": file_size,
        "history": updated_history
    }
    with open(VERSION_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(version_data, f, ensure_ascii=False, indent=2)

    # 5. Підсумок
    print(f"[5/5] 🎉 ГОТОВО!")
    print("=" * 65)
    print(f"✨ Реліз v{new_version_display} (build {new_build}) успішно опубліковано!")
    print(f"📝 Зміни:\n{changelog}")
    print(f"💾 Розмір: {file_size / (1024 * 1024):.1f} MB (режим: {mode})")
    print(f"📡 Сервер оновлень готовий роздавати нову версію смартфонам по Wi-Fi.")
    print("=" * 65)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Автоматична публікація релізів MusicFlow")
    parser.add_argument("--changelog", "-c", type=str, default=None, help="Опис змін релізу")
    parser.add_argument(
        "--bump", "-b",
        choices=["patch", "minor", "major", "build_only"],
        default="patch",
        help="Тип підвищення версії (за замовчуванням: patch)"
    )
    parser.add_argument(
        "--mode", "-m",
        choices=["both", "release", "debug"],
        default="both",
        help="Режим збірки (за замовчуванням: both — збирає синхронно обидва канали)"
    )
    args = parser.parse_args()
    publish_release(changelog=args.changelog, bump_type=args.bump, mode=args.mode)
