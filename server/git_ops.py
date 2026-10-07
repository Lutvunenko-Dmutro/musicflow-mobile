import subprocess


def git_commit_and_tag(project_dir, version_tag, new_build, skip_git=False):
    if skip_git:
        return
    print(f"\n[5/6] 🏷️  Синхронізація з Git та GitHub (тег v{version_tag})...")
    try:
        subprocess.run(["git", "add", "-A"], cwd=project_dir, shell=True)
        commit_msg = f"release: v{version_tag} (build {new_build})"
        subprocess.run(["git", "commit", "-m", commit_msg], cwd=project_dir, shell=True)
        subprocess.run(["git", "tag", f"v{version_tag}"], cwd=project_dir, shell=True)
        subprocess.run(["git", "push", "origin", "main"], cwd=project_dir, shell=True)
        subprocess.run(["git", "push", "origin", f"v{version_tag}"], cwd=project_dir, shell=True)
        print(f"       ✅ Тег v{version_tag} та оновлені маніфести успішно надіслано в GitHub!")
    except Exception as e:
        print(f"       ⚠️ Не вдалося завершити git push: {e}")
