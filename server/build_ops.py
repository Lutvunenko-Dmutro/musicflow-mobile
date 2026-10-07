import os
import shutil
import subprocess
import sys


def run_preflight_checks(project_dir, skip=False):
    if skip:
        print("\n[0/6] ⏭️  Pre-flight перевірки пропущено (--skip-verify)")
        return True
    print("\n[0/6] 🔍 Перевірка якості коду (Pre-flight)...")
    print("       -> 1. Аналізатор коду (`flutter analyze`)...")
    res = subprocess.run(["flutter", "analyze"], cwd=project_dir, shell=True)
    if res.returncode != 0:
        print("\n❌ ПОМИЛКА: flutter analyze виявив проблеми! Збірку зупинено.")
        sys.exit(1)
    print("       -> 2. Автоматичні тести (`flutter test`)...")
    res = subprocess.run(["flutter", "test"], cwd=project_dir, shell=True)
    if res.returncode != 0:
        print("\n❌ ПОМИЛКА: Не всі тести пройшли! Збірку зупинено.")
        sys.exit(1)
    print("       ✅ Pre-flight пройдено: 0 помилок, всі тести зелені!\n")
    return True


def compile_and_copy_apk(project_dir, target_dir, mode_flag, artifact_name, dest_name):
    print(f"       -> Збірка {mode_flag.upper()} (`flutter build apk --{mode_flag}`)...")
    res = subprocess.run(["flutter", "build", "apk", f"--{mode_flag}"], cwd=project_dir, shell=True)
    if res.returncode != 0:
        print(f"\n❌ Помилка під час збірки {mode_flag} APK!")
        return None
    built_path = os.path.join(project_dir, "build", "app", "outputs", "flutter-apk", artifact_name)
    dest_path = os.path.join(target_dir, dest_name)
    shutil.copy2(built_path, dest_path)
    size_mb = os.path.getsize(dest_path) / (1024 * 1024)
    print(f"       ✅ {dest_name} готово: {size_mb:.1f} MB")
    return dest_path
