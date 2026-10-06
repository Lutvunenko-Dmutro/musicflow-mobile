---
name: release-pipeline
description: Автоматичний запуск повного інженерного пайплайну збірки, тестування, версіонування та публікації релізу MusicFlow Mobile в 1 команду.
---

# Release Pipeline Skill

Використовуй цю інструкцію, коли користувач просить зібрати реліз, випустити оновлення, опублікувати нову версію або протестувати білд.

## Єдина команда запуску

Завжди запускай процес **однією командою**:

```powershell
python server/publish_release.py --bump patch --mode release -c "Опис змін українською"
```

### Параметри:
* `--bump`: `patch` (1.0.32 -> 1.0.33), `minor` (1.0.32 -> 1.1.0), `major` (1.0.32 -> 2.0.0).
* `--mode`: `release` (швидка збірка продуктового APK), `debug`, `both`.
* `-c`: обов'язковий ченджлог для `version.json` та повідомлення коміту.

## Що виконує скрипт автоматично:
1. `flutter analyze` (перевірка на 0 помилок).
2. `flutter test` (перевірка 54 тестів та архітектурного правила < 200 рядків).
3. Збільшення версії в `pubspec.yaml`.
4. Збірка `flutter build apk --release`.
5. Копіювання у `server/data/updates/app-release.apk`.
6. Оновлення історії в `server/data/version.json`.
7. `git add -A`, коміт, тег `vX.Y.Z` та push у GitHub.
