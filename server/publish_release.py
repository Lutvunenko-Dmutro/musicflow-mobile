#!/usr/bin/env python3
"""
MusicFlow Release Automation Script
Повністю автоматизує створення та публікацію нового релізу:
0. Pre-flight: перевіряє код (`flutter analyze`) та проганяє всі тести (`flutter test`).
1. Збільшує версію в pubspec.yaml (наприклад: 1.0.28+29 -> 1.0.29+30).
2. Компілює свіжий APK: `flutter build apk --release` (та/або `--debug`).
3. Копіює створений файл у папку сервера `server/data/updates/`.
4. Оновлює `server/data/version.json` з історією релізів та розміром файлів.
5. Автоматично фіксує комміт у Git, створює релізний тег та пушить в GitHub.
6. Будь-який телефон одразу бачить оновлення через Wi-Fi та GitHub Releases.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import hashlib
import sys
from datetime import datetime

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)
PUBSPEC_PATH = os.path.join(PROJECT_DIR, "pubspec.yaml")
UPDATES_DIR = os.path.join(BASE_DIR, "data", "updates")
VERSION_JSON_PATH = os.path.join(BASE_DIR, "data", "version.json")
BUILT_APK_DEBUG = os.path.join(PROJECT_DIR, "build", "app", "outputs", "flutter-apk", "app-debug.apk")
BUILT_APK_RELEASE = os.path.join(PROJECT_DIR, "build", "app", "outputs", "flutter-apk", "app-release.apk")


def calculate_sha256(filepath):
    if not filepath or not os.path.exists(filepath):
        return ""
    sha = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(64 * 1024):
            sha.update(chunk)
    return sha.hexdigest()


def get_current_pubspec_version():
    with open(PUBSPEC_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)", content, re.MULTILINE)
    if not match:
        raise ValueError("Не вдалося знайти поле version у pubspec.yaml")
    return map(int, match.groups())


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


def run_preflight_checks(skip=False):
    if skip:
        print("\n[0/6] ⏭️  Pre-flight перевірки пропущено (--skip-verify)")
        return True
    print("\n[0/6] 🔍 Перевірка якості коду (Pre-flight)...")
    print("       -> 1. Аналізатор коду (`flutter analyze`)...")
    res = subprocess.run(["flutter", "analyze"], cwd=PROJECT_DIR, shell=True)
    if res.returncode != 0:
        print("\n❌ ПОМИЛКА: flutter analyze виявив проблеми! Збірку зупинено.")
        sys.exit(1)
    print("       -> 2. Автоматичні тести (`flutter test`)...")
    res = subprocess.run(["flutter", "test"], cwd=PROJECT_DIR, shell=True)
    if res.returncode != 0:
        print("\n❌ ПОМИЛКА: Не всі тести пройшли! Збірку зупинено.")
        sys.exit(1)
    print("       ✅ Pre-flight пройдено: 0 помилок, всі тести зелені!\n")
    return True


def git_commit_and_tag(version_tag, new_build, skip_git=False):
    if skip_git:
        return
    print(f"\n[5/6] 🏷️  Синхронізація з Git та GitHub (тег v{version_tag})...")
    try:
        subprocess.run(["git", "add", "-A"], cwd=PROJECT_DIR, shell=True)
        commit_msg = f"release: v{version_tag} (build {new_build})"
        subprocess.run(["git", "commit", "-m", commit_msg], cwd=PROJECT_DIR, shell=True)
        subprocess.run(["git", "tag", f"v{version_tag}"], cwd=PROJECT_DIR, shell=True)
        subprocess.run(["git", "push", "origin", "main"], cwd=PROJECT_DIR, shell=True)
        subprocess.run(["git", "push", "origin", f"v{version_tag}"], cwd=PROJECT_DIR, shell=True)
        print(f"       ✅ Тег v{version_tag} та оновлені маніфести успішно надіслано в GitHub!")
    except Exception as e:
        print(f"       ⚠️ Не вдалося завершити git push: {e}")


def publish_release(changelog=None, bump_type="patch", mode="release", skip_verify=False, skip_git=False):
    print("=" * 65)
    print("🚀 MusicFlow • Автоматична публікація нового оновлення")
    print(f"📦 Режим збірки: {mode.upper()}")
    print("=" * 65)

    # 0. Pre-flight checks (analyze & test)
    run_preflight_checks(skip=skip_verify)

    major, minor, patch, build = get_current_pubspec_version()
    old_version_str = f"{major}.{minor}.{patch}+{build}"
    print(f"📌 Поточна версія проєкту: v{major}.{minor}.{patch} (build {build})")

    new_build = build + 1
    if bump_type == "minor":
        new_major, new_minor, new_patch = major, minor + 1, 0
    elif bump_type == "major":
        new_major, new_minor, new_patch = major + 1, 0, 0
    elif bump_type == "build_only":
        new_major, new_minor, new_patch = major, minor, patch
    else:
        new_major, new_minor, new_patch = major, minor, patch + 1

    new_version_display = f"{new_major}.{new_minor}.{new_patch}"
    new_full_version = f"{new_version_display}+{new_build}"

    if not changelog:
        print(f"\n📝 Нова версія буде: v{new_version_display} (build {new_build})")
        user_input = input("Введіть опис змін: ").strip()
        changelog = user_input.replace('\\n', '\n') if user_input else f"• Оновлення v{new_version_display}"
    else:
        changelog = changelog.replace('\\n', '\n')

    # 1. Update pubspec.yaml
    print(f"\n[1/6] ✏️  Оновлюю pubspec.yaml: {old_version_str} -> {new_full_version}...")
    update_pubspec_version(new_major, new_minor, new_patch, new_build)

    # 2. Compile APK
    print(f"\n[2/6] 🔨 Компілюю APK через Flutter...")
    os.makedirs(UPDATES_DIR, exist_ok=True)
    build_release = (mode in ("release", "both"))
    build_debug = (mode in ("debug", "both"))

    if build_release:
        print(f"       -> Збірка RELEASE (`flutter build apk --release`)...")
        res = subprocess.run(["flutter", "build", "apk", "--release"], cwd=PROJECT_DIR, shell=True)
        if res.returncode != 0:
            print("\n❌ Помилка під час збірки Release APK! Відновлюю pubspec.yaml...")
            update_pubspec_version(major, minor, patch, build)
            sys.exit(1)
        shutil.copy2(BUILT_APK_RELEASE, os.path.join(UPDATES_DIR, "app-release.apk"))
        rel_size = os.path.getsize(BUILT_APK_RELEASE)
        print(f"       ✅ Release APK готово: {rel_size / (1024 * 1024):.1f} MB")

    if build_debug:
        print(f"       -> Збірка DEBUG (`flutter build apk --debug`)...")
        res = subprocess.run(["flutter", "build", "apk", "--debug"], cwd=PROJECT_DIR, shell=True)
        if res.returncode != 0:
            print("\n❌ Помилка під час збірки Debug APK! Відновлюю pubspec.yaml...")
            update_pubspec_version(major, minor, patch, build)
            sys.exit(1)
        shutil.copy2(BUILT_APK_DEBUG, os.path.join(UPDATES_DIR, "app-debug.apk"))
        dbg_size = os.path.getsize(BUILT_APK_DEBUG)
        print(f"       ✅ Debug APK готово: {dbg_size / (1024 * 1024):.1f} MB")

    primary_apk = BUILT_APK_RELEASE if build_release else BUILT_APK_DEBUG
    file_size = os.path.getsize(primary_apk)
    apk_file_name = "app-release.apk" if build_release else "app-debug.apk"

    # 3. Synchronize storage
    print(f"[3/6] 📦 APK файли успішно синхронізовано у сховищі сервера ({UPDATES_DIR})")

    # 4. Update version.json
    print(f"[4/6] 📄 Оновлюю інформацію про реліз у version.json...")
    existing_history = []
    if os.path.exists(VERSION_JSON_PATH):
        try:
            with open(VERSION_JSON_PATH, "r", encoding="utf-8") as f:
                old_data = json.load(f)
                existing_history = old_data.get("history", [])
        except Exception:
            pass

    apk_sha256 = calculate_sha256(primary_apk)
    print(f"       🔒 SHA-256: {apk_sha256}")

    new_release_entry = {
        "version": new_version_display,
        "buildNumber": new_build,
        "releaseDate": datetime.now().strftime("%Y-%m-%d"),
        "changelog": changelog,
        "sha256": apk_sha256
    }
    updated_history = [new_release_entry] + [h for h in existing_history if h.get("buildNumber") != new_build]

    version_data = {
        "version": new_version_display,
        "buildNumber": new_build,
        "releaseDate": datetime.now().strftime("%Y-%m-%d"),
        "changelog": changelog,
        "apkFileName": apk_file_name,
        "fileSizeBytes": file_size,
        "sha256": apk_sha256,
        "history": updated_history
    }
    with open(VERSION_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(version_data, f, ensure_ascii=False, indent=2)

    # 5. Git Commit & Tag & Push
    git_commit_and_tag(new_version_display, new_build, skip_git=skip_git)

    # 6. Summary
    print(f"[6/6] 🎉 ГОТОВО!")
    print("=" * 65)
    print(f"✨ Реліз v{new_version_display} (build {new_build}) успішно створено та опубліковано!")
    print(f"📝 Зміни:\n{changelog}")
    print(f"💾 Розмір: {file_size / (1024 * 1024):.1f} MB (режим: {mode})")
    print(f"📡 Сервер оновлень готовий роздавати нову версію смартфонам.")
    print("=" * 65)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Автоматична публікація релізів MusicFlow")
    parser.add_argument("--changelog", "-c", type=str, default=None, help="Опис змін релізу")
    parser.add_argument(
        "--bump", "-b",
        choices=["patch", "minor", "major", "build_only"],
        default="patch",
        help="Тип підвищення версії"
    )
    parser.add_argument(
        "--mode", "-m",
        choices=["both", "release", "debug"],
        default="release",
        help="Режим збірки (за замовчуванням: release)"
    )
    parser.add_argument("--skip-verify", action="store_true", help="Пропустити pre-flight перевірку тестів")
    parser.add_argument("--skip-git", action="store_true", help="Пропустити автоматичний git push та тегування")
    args = parser.parse_args()
    publish_release(
        changelog=args.changelog,
        bump_type=args.bump,
        mode=args.mode,
        skip_verify=args.skip_verify,
        skip_git=args.skip_git
    )
