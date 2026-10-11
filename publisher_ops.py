import hashlib
import os
import re
import subprocess
import time

LOG_FILE = "build_log.txt"


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


def calculate_sha256(filepath):
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(65536), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()


def generate_automatic_changelog(version_name):
    commits = []
    try:
        tag_proc = subprocess.run(["git", "describe", "--tags", "--abbrev=0"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8")
        last_tag = tag_proc.stdout.strip() if tag_proc.returncode == 0 else ""
        log_cmd = ["git", "log", f"{last_tag}..HEAD", "--pretty=format:%s"] if last_tag else ["git", "log", "-n", "8", "--pretty=format:%s"]
        log_proc = subprocess.run(log_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8")
        if log_proc.returncode == 0 and log_proc.stdout:
            for c in log_proc.stdout.strip().split("\n"):
                c = c.strip()
                if c and not c.startswith("chore: bump") and not c.startswith("Merge"):
                    commits.append(c)
    except Exception:
        pass
    return "\n".join(commits) if commits else "Покращення стабільності та оптимізація\nОновлення компонентів додатку"


def get_latest_github_release_tag():
    try:
        proc = subprocess.run(["gh", "release", "list", "--limit", "5"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding="utf-8")
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


def upload_github_release(version_name, build_num, changelog, sha256_rel, sha256_dbg, apk_files):
    subprocess.run(["git", "add", "pubspec.yaml"])
    subprocess.run(["git", "commit", "-m", f"chore: bump version to v{version_name}"])
    print("Пуш змін до гілки main...")
    subprocess.run(["git", "push", "origin", "main"])

    notes_file = "release_notes_temp.txt"
    with open(notes_file, "w", encoding="utf-8") as f:
        f.write(f"{changelog}\n\nSHA-256 (Release): {sha256_rel}\n")
        if sha256_dbg:
            f.write(f"SHA-256 (Debug): {sha256_dbg}\n")

    check_rel = subprocess.run(["gh", "release", "view", f"v{version_name}"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if check_rel.returncode == 0:
        print(f"Реліз v{version_name} вже існує. Оновлюємо APK-файли (--clobber) та опис...")
        res = subprocess.run(["gh", "release", "upload", f"v{version_name}", *apk_files, "--clobber"])
        subprocess.run(["gh", "release", "edit", f"v{version_name}", "--title", f"MusicFlow v{version_name} (build {build_num})", "--notes-file", notes_file])
    else:
        release_cmd = ["gh", "release", "create", f"v{version_name}", *apk_files, "--title", f"MusicFlow v{version_name} (build {build_num})", "--notes-file", notes_file]
        res = subprocess.run(release_cmd)

    if os.path.exists(notes_file):
        os.remove(notes_file)
    return res.returncode
