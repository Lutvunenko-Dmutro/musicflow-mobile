import os
import re
import shutil
import subprocess
import sys
import time

from publisher_ops import (
    LOG_FILE, run_command_with_log, calculate_sha256,
    generate_automatic_changelog, get_latest_github_release_tag, upload_github_release
)

JAVA_17_PATH = r"C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
if os.path.exists(JAVA_17_PATH):
    os.environ["JAVA_HOME"] = JAVA_17_PATH
    os.environ["PATH"] = os.path.join(JAVA_17_PATH, "bin") + os.pathsep + os.environ.get("PATH", "")


def print_header():
    print("=" * 70)
    print("  MusicFlow Mobile - Менеджер релізів (Release Publisher)")
    print("=" * 70 + "\n")


def get_current_version():
    if not os.path.exists("pubspec.yaml"):
        return "1.0.0", "1"
    with open("pubspec.yaml", "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"^version:\s*([0-9.]+)\+([0-9]+)", content, re.MULTILINE)
    return (match.group(1), match.group(2)) if match else ("1.0.0", "1")


def update_pubspec_version(version_name, build_num):
    with open("pubspec.yaml", "r", encoding="utf-8") as f:
        content = f.read()
    new_content = re.sub(r"^version:.*", f"version: {version_name}+{build_num}", content, flags=re.MULTILINE)
    with open("pubspec.yaml", "w", encoding="utf-8") as f:
        f.write(new_content)


def check_requirements():
    if not shutil.which("gh"):
        print("[УВАГА / ПОМИЛКА] GitHub CLI ('gh') не знайдено в PATH.\nВстановіть gh або додайте його до PATH.")
        return False
    return True


def _calculate_next_version(current_ver, current_build, latest_gh):
    base_ver = current_ver
    if latest_gh and not current_ver.startswith("0."):
        try:
            if [int(x) for x in latest_gh.split(".")] > [int(x) for x in current_ver.split(".")]:
                base_ver = latest_gh
        except Exception:
            pass
    parts = base_ver.split(".")
    try:
        suggested_ver = f"{parts[0]}.{parts[1]}.{int(parts[2]) + 1}"
    except Exception:
        suggested_ver = base_ver
    try:
        suggested_build = str(int(current_build) + 1)
    except Exception:
        suggested_build = str(int(current_build or 0) + 1)
    return suggested_ver, suggested_build


def build_and_publish_local(version_name, build_num, changelog):
    print(f"\n--- Початок локальної збірки MusicFlow v{version_name}+{build_num} ---")
    print("\n[1/5] Оновлення pubspec.yaml...")
    update_pubspec_version(version_name, build_num)
    print(f"Версію оновлено до {version_name}+{build_num}")

    print("\n[2/5] Перевірка коду та тести...")
    if not run_command_with_log(["flutter", "analyze"], "Flutter Analyze"):
        return 1
    if not run_command_with_log(["flutter", "test"], "Flutter Test"):
        return 1

    print("\n[3/5] Збірка APK файлів...")
    build_rel_cmd = ["flutter", "build", "apk", "--release", f"--build-name={version_name}", f"--build-number={build_num}"]
    if not run_command_with_log(build_rel_cmd, "Flutter Build Release APK"):
        return 1

    time.sleep(2.0)
    dbg_apk_ready = False
    build_dbg_cmd = ["flutter", "build", "apk", "--debug", f"--build-name={version_name}", f"--build-number={build_num}"]
    if run_command_with_log(build_dbg_cmd, "Flutter Build Debug APK"):
        dbg_apk_ready = True
    else:
        print("\n[УВАГА] Debug APK пропущено через блокування файлів. Продовжуємо з Release APK...")

    print("\n[4/5] Розрахунок SHA-256 контрольної суми...")
    release_apk = os.path.join("build", "app", "outputs", "flutter-apk", "app-release.apk")
    debug_apk = os.path.join("build", "app", "outputs", "flutter-apk", "app-debug.apk")
    if not os.path.exists(release_apk):
        print(f"[ПОМИЛКА] Файл не знайдено: {release_apk}")
        return 1

    sha256_rel = calculate_sha256(release_apk)
    sha256_dbg = calculate_sha256(debug_apk) if (dbg_apk_ready and os.path.exists(debug_apk)) else ""
    print(f"SHA-256 (Release): {sha256_rel}")

    print("\n[5/5] Збереження у Git та публікація в GitHub Releases...")
    apk_files = [release_apk]
    if dbg_apk_ready and os.path.exists(debug_apk):
        apk_files.append(debug_apk)
    return upload_github_release(version_name, build_num, changelog, sha256_rel, sha256_dbg, apk_files)


def main():
    if sys.platform == "win32":
        try:
            os.system("chcp 65001 > nul")
        except Exception:
            pass
    print_header()
    if not check_requirements():
        input("\nНатисніть Enter для виходу...")
        return 1

    current_ver, current_build = get_current_version()
    print(f"Версія в pubspec.yaml: {current_ver} (білд {current_build})")
    latest_gh = get_latest_github_release_tag()
    if latest_gh:
        print(f"Останній реліз на GitHub: v{latest_gh}")

    print("\nОберіть метод публікації:\n  [1] Локальна збірка (швидко на вашому ПК)\n  [2] GitHub Actions (хмарна збірка через ci.yml)\n  [0] Вихід\n")
    choice = input("Ваш вибір (1, 2 або 0): ").strip()
    if choice == "0":
        return 0
    if choice not in ["1", "2"]:
        print("[ПОМИЛКА] Невірний вибір!")
        input("\nНатисніть Enter для виходу...")
        return 1

    version_name, build_num = _calculate_next_version(current_ver, current_build, latest_gh)
    print(f"\n--> Автоматично визначено реліз: v{version_name} (білд {build_num})")
    changelog = generate_automatic_changelog(version_name)

    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write(f"=== BUILD LOG: v{version_name} ({build_num}) ===\n\n")

    if choice == "2":
        cmd = ["gh", "workflow", "run", "ci.yml", "-f", f"release_version=v{version_name}", "-f", f"build_number={build_num}", "-f", f"release_notes={changelog}"]
        res = subprocess.run(cmd)
        print("\n[УСПІШНО] Завдання відправлено до GitHub Actions!" if res.returncode == 0 else "\n[ПОМИЛКА] Не вдалося запустити.")
        input("\nНатисніть Enter для виходу...")
        return res.returncode

    res = build_and_publish_local(version_name, build_num, changelog)
    print("\n" + "=" * 50 + f"\n УСПІХ! Реліз v{version_name} опубліковано на GitHub!\n" + "=" * 50 if res == 0 else "\n[ПОМИЛКА] Не вдалося створити реліз!")
    input("\nНатисніть Enter для завершення...")
    return res


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nПерервано користувачем.")
        sys.exit(0)
    except Exception as e:
        print(f"\n[КРИТИЧНА ПОМИЛКА]: {e}")
        input("\nНатисніть Enter для закриття...")
        sys.exit(1)
