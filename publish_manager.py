import os
import sys
import re
import hashlib
import subprocess
import shutil

LOG_FILE = "build_log.txt"

# Автоматичне налаштування Java 17 LTS для Gradle
JAVA_17_PATH = r"C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot"
if os.path.exists(JAVA_17_PATH):
    os.environ["JAVA_HOME"] = JAVA_17_PATH
    os.environ["PATH"] = os.path.join(JAVA_17_PATH, "bin") + os.pathsep + os.environ.get("PATH", "")

def print_header():
    print("=" * 70)
    print("  MusicFlow Mobile - Менеджер релізів (Release Publisher)")
    print("=" * 70)
    print()

def log(msg, also_print=True):
    with open(LOG_FILE, "a", encoding="utf-8") as f:
        f.write(msg + "\n")
    if also_print:
        print(msg)

def run_command_with_log(cmd, step_name):
    print(f"\n>> {step_name}...")
    log(f"\n{'='*50}\n[COMMAND]: {' '.join(cmd)}\n{'='*50}\n", also_print=False)

    try:
        process = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
            shell=True
        )

        with open(LOG_FILE, "a", encoding="utf-8") as f:
            for line in process.stdout:
                f.write(line)
                f.flush()
                print(line, end="", flush=True)

        process.wait()
        if process.returncode != 0:
            print(f"\n[ПОМИЛКА] {step_name} завершився з кодом {process.returncode}!")
            print(f"Деталі помилки записано у файл: {os.path.abspath(LOG_FILE)}")
            return False
        
        print(f"[УСПІШНО] {step_name} завершено!")
        return True

    except Exception as e:
        print(f"\n[ВИНЯТОК] Не вдалося виконати команду: {e}")
        log(f"EXCEPTION: {str(e)}\n", also_print=False)
        return False

def get_current_version():
    if not os.path.exists("pubspec.yaml"):
        return "1.0.0", "1"
    with open("pubspec.yaml", "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"^version:\s*([0-9.]+)\+([0-9]+)", content, re.MULTILINE)
    if match:
        return match.group(1), match.group(2)
    return "1.0.0", "1"

def update_pubspec_version(version_name, build_num):
    with open("pubspec.yaml", "r", encoding="utf-8") as f:
        content = f.read()
    new_content = re.sub(
        r"^version:.*",
        f"version: {version_name}+{build_num}",
        content,
        flags=re.MULTILINE
    )
    with open("pubspec.yaml", "w", encoding="utf-8") as f:
        f.write(new_content)

def calculate_sha256(filepath):
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(65536), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def generate_automatic_changelog(version_name):
    """Автоматично формує опис релізу на основі останніх git-комітів."""
    commits = []
    try:
        # Шукаємо останній тег
        tag_proc = subprocess.run(
            ["git", "describe", "--tags", "--abbrev=0"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8"
        )
        last_tag = tag_proc.stdout.strip() if tag_proc.returncode == 0 else ""

        if last_tag:
            log_cmd = ["git", "log", f"{last_tag}..HEAD", "--pretty=format:%s"]
        else:
            log_cmd = ["git", "log", "-n", "8", "--pretty=format:%s"]

        log_proc = subprocess.run(
            log_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8"
        )
        if log_proc.returncode == 0 and log_proc.stdout:
            raw_commits = log_proc.stdout.strip().split("\n")
            for c in raw_commits:
                c = c.strip()
                if c and not c.startswith("chore: bump") and not c.startswith("Merge"):
                    commits.append(f"* {c}")
    except Exception:
        pass

    if not commits:
        commits = [
            "* Покращення стабільності та оптимізація",
            "* Оновлення компонентів додатку"
        ]

    changelog = f"### 📦 Оновлення MusicFlow Mobile v{version_name}\n\n"
    changelog += "**Зміни у цій версії:**\n" + "\n".join(commits)
    return changelog

def get_latest_github_release_tag():
    """Отримує останній тег релізу з GitHub."""
    try:
        proc = subprocess.run(
            ["gh", "release", "list", "--limit", "5"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            encoding="utf-8"
        )
        if proc.returncode == 0 and proc.stdout:
            for line in proc.stdout.strip().split("\n"):
                parts = line.split("\t")
                if len(parts) >= 3:
                    tag = parts[2].strip().lstrip("v")
                    if re.match(r"^\d+\.\d+\.\d+$", tag):
                        return tag
    except Exception:
        pass
    return None

def check_requirements():
    if not shutil.which("gh"):
        print("[УВАГА / ПОМИЛКА] GitHub CLI ('gh') не знайдено в PATH.")
        print("Встановіть gh або додайте його до PATH.")
        return False
    return True

def main():
    # Set console encoding to UTF-8 on Windows
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

    print("\nОберіть метод публікації:")
    print("  [1] Локальна збірка (швидко на вашому ПК, зберігає логи в build_log.txt)")
    print("  [2] GitHub Actions (збірка на серверах GitHub через ci.yml)")
    print("  [0] Вихід")
    print()

    choice = input("Ваш вибір (1, 2 або 0): ").strip()

    if choice == "0":
        print("Скасовано.")
        return 0

    if choice not in ["1", "2"]:
        print("[ПОМИЛКА] Невірний вибір!")
        input("\nНатисніть Enter для виходу...")
        return 1

    # Визначаємо базову версію для інкременту
    base_ver = current_ver
    if latest_gh and not current_ver.startswith("0."):
        try:
            gh_parts = [int(x) for x in latest_gh.split(".")]
            local_parts = [int(x) for x in current_ver.split(".")]
            if gh_parts > local_parts:
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

    version_name = suggested_ver
    build_num = suggested_build

    print(f"\n--> Автоматично визначено реліз: v{version_name} (білд {build_num})")

    # Автоматична генерація опису з Git
    changelog = generate_automatic_changelog(version_name)
    print("\n[Автоматичний опис релізу з Git]:")
    print("-" * 50)
    print(changelog)
    print("-" * 50)

    # Clear log file
    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write(f"=== BUILD LOG: v{version_name} ({build_num}) ===\n\n")

    # Mode 2: GitHub Actions
    if choice == "2":
        print("\n>> Відправка команди в GitHub Actions...")
        cmd = [
            "gh", "workflow", "run", "ci.yml",
            "-f", f"release_version=v{version_name}",
            "-f", f"build_number={build_num}",
            "-f", f"release_notes={changelog}"
        ]
        res = subprocess.run(cmd)
        if res.returncode == 0:
            print("\n[УСПІШНО] Завдання відправлено до GitHub Actions!")
            print("Ви можете перевірити статус: https://github.com/dmutr43603/music_flow_mobile/actions")
        else:
            print("\n[ПОМИЛКА] Не вдалося запустити GitHub Actions.")
        input("\nНатисніть Enter для виходу...")
        return res.returncode

    # Mode 1: Local Build
    print(f"\n--- Початок локальної збірки MusicFlow v{version_name}+{build_num} ---")

    # Step 1: pubspec.yaml
    print("\n[1/5] Оновлення pubspec.yaml...")
    update_pubspec_version(version_name, build_num)
    print(f"Версію оновлено до {version_name}+{build_num}")

    # Step 2: Tests & Analysis
    print("\n[2/5] Перевірка коду та тести...")
    if not run_command_with_log(["flutter", "analyze"], "Flutter Analyze"):
        input("\nНатисніть Enter для виходу...")
        return 1

    if not run_command_with_log(["flutter", "test"], "Flutter Test"):
        input("\nНатисніть Enter для виходу...")
        return 1

    # Step 3: Build APKs
    print("\n[3/5] Збірка APK файлів...")
    build_rel_cmd = [
        "flutter", "build", "apk", "--release",
        f"--build-name={version_name}",
        f"--build-number={build_num}"
    ]
    if not run_command_with_log(build_rel_cmd, "Flutter Build Release APK"):
        input("\nНатисніть Enter для виходу...")
        return 1

    build_dbg_cmd = [
        "flutter", "build", "apk", "--debug",
        f"--build-name={version_name}",
        f"--build-number={build_num}"
    ]
    if not run_command_with_log(build_dbg_cmd, "Flutter Build Debug APK"):
        input("\nНатисніть Enter для виходу...")
        return 1

    # Step 4: SHA-256
    print("\n[4/5] Розрахунок SHA-256 контрольної суми...")
    release_apk = os.path.join("build", "app", "outputs", "flutter-apk", "app-release.apk")
    debug_apk = os.path.join("build", "app", "outputs", "flutter-apk", "app-debug.apk")

    if not os.path.exists(release_apk):
        print(f"[ПОМИЛКА] Файл не знайдено: {release_apk}")
        input("\nНатисніть Enter для виходу...")
        return 1

    sha256_rel = calculate_sha256(release_apk)
    sha256_dbg = calculate_sha256(debug_apk) if os.path.exists(debug_apk) else ""
    print(f"SHA-256 (Release): {sha256_rel}")
    if sha256_dbg:
        print(f"SHA-256 (Debug):   {sha256_dbg}")

    # Step 5: Git commit & GitHub Release
    print("\n[5/5] Збереження у Git та публікація в GitHub Releases...")
    
    subprocess.run(["git", "add", "pubspec.yaml"])
    subprocess.run(["git", "commit", "-m", f"chore: bump version to v{version_name}"])
    print("Пуш змін до гілки main...")
    subprocess.run(["git", "push", "origin", "main"])

    notes_file = "release_notes_temp.txt"
    with open(notes_file, "w", encoding="utf-8") as f:
        f.write(f"{changelog}\n\n")
        f.write(f"**SHA-256 (Release):** `{sha256_rel}`\n")
        if sha256_dbg:
            f.write(f"**SHA-256 (Debug):** `{sha256_dbg}`\n")

    # Перевіряємо, чи існує вже такий реліз на GitHub
    check_rel = subprocess.run(
        ["gh", "release", "view", f"v{version_name}"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    if check_rel.returncode == 0:
        print(f"Реліз v{version_name} вже існує. Оновлюємо APK-файли (--clobber) та опис...")
        res = subprocess.run([
            "gh", "release", "upload", f"v{version_name}",
            release_apk,
            debug_apk,
            "--clobber"
        ])
        subprocess.run([
            "gh", "release", "edit", f"v{version_name}",
            "--title", f"MusicFlow v{version_name} (build {build_num})",
            "--notes-file", notes_file
        ])
    else:
        release_cmd = [
            "gh", "release", "create", f"v{version_name}",
            release_apk,
            debug_apk,
            "--title", f"MusicFlow v{version_name} (build {build_num})",
            "--notes-file", notes_file
        ]
        res = subprocess.run(release_cmd)
    
    if os.path.exists(notes_file):
        os.remove(notes_file)

    if res.returncode == 0:
        print("\n" + "="*50)
        print(f" УСПІХ! Реліз v{version_name} опубліковано на GitHub!")
        print("="*50)
    else:
        print("\n[ПОМИЛКА] Не вдалося створити реліз у GitHub!")

    input("\nНатисніть Enter для завершення...")
    return res.returncode

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
