import re


def get_current_pubspec_version(pubspec_path):
    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()
    match = re.search(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)", content, re.MULTILINE)
    if not match:
        raise ValueError("Не вдалося знайти поле version у pubspec.yaml")
    return [int(x) for x in match.groups()]


def update_pubspec_version(pubspec_path, major, minor, patch, build):
    new_version_str = f"{major}.{minor}.{patch}+{build}"
    with open(pubspec_path, "r", encoding="utf-8") as f:
        content = f.read()
    updated = re.sub(
        r"^version:\s*\d+\.\d+\.\d+\+\d+",
        f"version: {new_version_str}",
        content,
        flags=re.MULTILINE
    )
    with open(pubspec_path, "w", encoding="utf-8") as f:
        f.write(updated)
    return new_version_str


def compute_next_version(major, minor, patch, build, bump_type):
    new_build = build + 1
    if bump_type == "minor":
        return major, minor + 1, 0, new_build
    elif bump_type == "major":
        return major + 1, 0, 0, new_build
    elif bump_type == "build_only":
        return major, minor, patch, new_build
    else:
        return major, minor, patch + 1, new_build
