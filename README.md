# MusicFlow Mobile 🎵

<p align="center">
  <a href="https://github.com/Lutvunenko-Dmutro/musicflow-mobile/releases/latest"><img src="https://img.shields.io/badge/Release-v0.1.2-2ea44f?style=for-the-badge&logo=android" alt="Version"></a>
  <a href="test/"><img src="https://img.shields.io/badge/Tests-66%20Passing-brightgreen?style=for-the-badge&logo=flutter" alt="Tests"></a>
  <a href="docs/architecture/ARCHITECTURE.md"><img src="https://img.shields.io/badge/Architecture-%3C200%20Lines%2FFile-purple?style=for-the-badge" alt="Architecture"></a>
  <a href="https://github.com/Lutvunenko-Dmutro/musicflow-mobile/actions"><img src="https://img.shields.io/badge/CI%2FCD-Active-blue?style=for-the-badge&logo=githubactions" alt="CI/CD Status"></a>
</p>

<p align="center">
  <b>Сучасний Hi-Fi плеєр на Flutter з реактивним FFT-візуалізатором та бездротовими OTA-оновленнями</b><br>
  <a href="https://github.com/Lutvunenko-Dmutro/musicflow-mobile/releases/latest">📦 Завантажити APK</a> •
  <a href="docs/README.md">📚 Каталог документації</a> •
  <a href="CHANGELOG.md">📜 Журнал змін</a> •
  <a href="publish.bat">🚀 Збірка в 1 клік</a>
</p>

---

## 🧭 Навігатор («Куди мені піти?»):

| 🎯 Ваша ціль | 📂 Куди дивитися | 💡 Що всередині |
|---|---|---|
| **Випустити новий реліз / зібрати APK** | 🚀 [**publish.bat**](publish.bat)<br>📋 [Чек-лист релізу](docs/release/RELEASE_CHECKLIST.md) | Автоматична збірка, тести, SHA-256 та реліз на GitHub в 1 команду |
| **Зрозуміти як працюють оновлення та канали** | 🗺️ [**Архітектура оновлень UML**](docs/architecture/UPDATE_SYSTEM_ARCHITECTURE.md)<br>🛡️ [Матриця відкату](docs/release/COMPATIBILITY_AND_ROLLBACK.md) | UML Component/Sequence діаграми, перемикання Release ⇄ Debug |
| **Змінити логіку відтворення чи чергу** | 🎧 [AudioProvider & Міксини](docs/architecture/architecture_audio_provider.md)<br>🏗️ [Системна архітектура](docs/architecture/ARCHITECTURE.md) | Потік аудіо, міксини, фоновий сервіс, відновлення стрімів |
| **Налаштувати візуалізатор чи FFT** | 📊 [Система візуалізатора](docs/architecture/visualizer_system.md) | ШПФ на `fftea`, Android AudioEffect API, оптимізація 60 FPS |
| **Подивитися вимоги та дорожню карту** | 📋 [Вимоги (PRD)](docs/planning/PRD.md)<br>🗺️ [Дорожня карта (PLAN)](docs/planning/PLAN.md)<br>🤖 [ШІ-Оркестрація](docs/planning/ORCHESTRATION.md) | Сценарії користувача, етапи розробки, стек та інтеграції |
| **Перевірити відомі баги чи аудит коду** | ⚠️ [Відомі проблеми (TODO)](docs/quality/known_issues_todo.md)<br>🔍 [Аудит безпеки](docs/quality/audit.md)<br>🎯 [Метрики SLA](docs/quality/QUALITY_METRICS.md) | Список багів, споживання пам'яті, швидкість холодного старту |

---

## Зміст
- [Можливості додатку](#можливості-додатку)
- [Стек технологій](#стек-технологій)
- [Архітектура проекту](#архітектура-проекту)
- [Сервер оновлень та телеметрія](#сервер-оновлень-та-телеметрія)
- [Запуск та тестування](#запуск-та-тестування)
- [Структура директорій](#структура-директорій)
- [Безпека та сховище](#безпека-та-сховище)

---

## Можливості додатку

| Функція | Опис | Статус |
|---|---|:---:|
| 📂 **Локальна бібліотека** | Сканування та відтворення MP3/M4A/FLAC, кешування ID3 тегів у SQLite для миттєвого старту | ✅ |
| 🌐 **YouTube стрімінг** | Пошук, фонове відтворення, автоматичний refresh потоків при закінченні терміну дії URL (403 retry) | ✅ |
| 🔄 **Мережева надійність** | Exponential Backoff (3 спроби з наростаючою затримкою) на всі запити до YouTube | ✅ |
| ⬇️ **Завантаження музики** | Викачування аудіо, автоматичне обрізання обкладинки 1:1, запис ID3 тегів та сканування в MediaStore | ✅ |
| 📜 **Синхронізовані тексти** | Підтримка LRC, LRCLIB API, парсинг та калібрування таймінгів авто-субтитрів YouTube | ✅ |
| 📊 **FFT-візуалізатор** | 60-смуговий спектрограф із Software (fftea) та Hardware (AudioEffect) ядрами, згладжуванням та +3dB headroom | ✅ |
| 🎛️ **Екран налаштувань візуалізатора** | Закріплене живе прев'ю вгорі, 5 стилів відображення, швидкі пресети та повзунки фізики | ✅ |
| 🎚️ **10-смуговий Еквалайзер** | 10 стандартних частот (31 Гц – 16 кГц), 12 пресетів (Рок, Поп, Bass Boost тощо), мапування на аудіочип, кнопка скидання | ✅ |
| 🔀 **Справжній Crossfade** | Плавний перехід між треками без пауз завдяки архітектурі на двох `AudioPlayer` | ✅ |
| 🌌 **Flowing Ambient Glow** | Живий шовковий 28px GPU фон плеєра з орбітальними сферами, що дихає в такт музиці | ✅ |
| ✨ **Cover Sheen** | Інтерактивні відблиски на обкладинці треку при горизонтальному свайпі | ✅ |
| 🔤 **Alphabet Index Bar** | Швидкий алфавітний скролер (#, A-Z, А-Я) з плаваючою бульбашкою та тактильним вібровідгуком | ✅ |
| 📡 **Автономні OTA-оновлення** | Пряма перевірка релізів через GitHub Releases API без залежності від локального ПК, підтримка кастомного сервера розробника | ✅ |
| 🛡️ **Телеметрія збоїв** | Збір діагностичних звітів збоїв за згодою користувача та зручний веб-дашборд | ✅ |
| 🧹 **Керування пам'яттю** | Детальна статистика зайнятої пам'яті (обкладинки, LRC, SQLite, історія) та безпечне очищення | ✅ |
| 🧪 **58 автоматичних тестів** | 58 unit-, service-, архітектурних та UI Smoke-тестів (< 200 рядків на файл, 0 analyzer issues) | ✅ |


---

## Стек технологій

| Компонент | Технологія / Бібліотека |
|---|---|
| **Фреймворк** | Flutter 3.x (Material 3, Impeller) |
| **Управління станом** | `provider` (ChangeNotifier + Mixins) |
| **Впровадження залежностей** | `get_it` (Service Locator) |
| **Аудіо ядро** | `just_audio` + `audio_service` + `audio_session` |
| **YouTube інтеграція** | `youtube_explode_dart` (кастомний fork із захистом від 403) |
| **Локальне сховище** | `sqflite` (SQLite v3) + `shared_preferences` |
| **Цифрова обробка сигналу** | `fftea` (ШПФ) + Android Native `Visualizer` |
| **Метадані та теги** | `audiotags` (Rust FFI engine) |
| **Мережа та зображення** | `http`, `cached_network_image`, `image` |
| **Локалізація** | `easy_localization` (Українська / Англійська) |

---

## Архітектура проекту

- **Строге правило `< 200` рядків на файл:** Кожен `.dart` файл у `lib/` та `test/` не перевищує 199 рядків коду, що автоматично контролюється тестом [test/architecture/file_length_test.dart](test/architecture/file_length_test.dart).
- **Модульні міксини AudioProvider:** Розбиття логіки плеєра на спеціалізовані міксини (черга, контролери відтворення, фокус аудіо, тексти, відновлення стрімів).
- **Єдиний сертифікат MusicFlow:** Debug та Release збірки використовують єдиний цифровий ключ розробника для сумісності установки по кабелю та бездротових оновлень.
- **Native Kotlin Handlers:** `VisualizerHandler`, `ApkInstallerHandler` та `NativeCrashHandler` винесені в окремі класи для максимальної стабільності.

---

## Сервер оновлень та телеметрія

У папці `server/` реалізовано автономний HTTP-сервер на Python без зовнішніх залежностей:
- **Роздача APK по Wi-Fi:** автоматичне виявлення локальної IP-адреси та генерація прямих посилань.
- **Перемикання каналів:** підтримка каналів **Release** (оптимізований AOT) та **Debug**.
- **Веб-дашборд (`http://localhost:8080/dashboard`):** перегляд історії релізів, статусу файлів оновлень та звітів про збої з розшифровкою логів (із захистом від XSS).

Скрипт публікації:
```bash
python server/publish_release.py -c "Опис змін" -b patch -m both
```

---

## Запуск та тестування

### 1. Запуск unit-тестів (58 тестів)
```bash
flutter test
```

### 2. Перевірка коду лінтером (0 warnings)
```bash
flutter test test/architecture/code_quality_test.dart
```

### 3. Запуск додатку
```bash
# Debug запуск на смартфоні
flutter run

# Збірка Release APK
flutter build apk --release
```

---

## Структура директорій

```
lib/
├── main.dart                    # Точка входу, ініціалізація провайдерів
├── locator.dart                 # GetIt service locator
│
├── core/                        # Тема, кольори, базові віджети
├── models/                      # Моделі даних (SongModel, HistoryModel, тощо)
│
├── providers/                   # State Management
│   ├── audio_provider.dart      # Головний провайдер відтворення
│   ├── equalizer_provider.dart  # Керування 10-смуговим еквалайзером
│   ├── visualizer_settings_provider.dart # Налаштування ядер та фізики спектру
│   └── audio/                   # Модульні міксини аудіоплеєра
│
├── services/                    # Сервіси бізнес-логіки
│   ├── update_service.dart      # Завантаження та встановлення оновлень APK
│   ├── telemetry_service.dart   # Збір діагностики за згодою
│   ├── youtube_service.dart     # Пошук та стрімінг аудіо
│   ├── download_service.dart    # Завантаження треків та тегування
│   └── database_service.dart    # База даних SQLite
│
├── features/                    # Екрани та UI компоненти
│   ├── player/                  # Плеєр та візуалізатор спектру
│   ├── settings/                # Налаштування, екран візуалізатора, діалоги оновлень
│   ├── library/                 # Локальна медіатека
│   └── lyrics/                  # Синхронізовані тексти пісень
│
└── utils/                       # Утиліти (AppLogger, FFT-процесори, фізика)
```

---

## Безпека та сховище

- **Безпека файлів користувача:** Очищення кешу чи історії ніколи не зачіпає власні треки користувача.
- **Path Traversal Protection:** Назви файлів при завантаженні фільтруються від спецсимволів (`\ / : * ? " < > |`).
- **SQL Injection Safe:** 100% параметризовані SQL-запити в `DatabaseService`.
- **Безпечний FileProvider:** Доступ до APK надається виключно системному інсталятору через `grantUriPermissions`.
