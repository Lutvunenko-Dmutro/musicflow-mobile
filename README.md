# MusicFlow Mobile 🎵

> Flutter music player з локальними файлами, YouTube стрімінгом, текстами пісень та FFT-візуалізатором.

> 📖 **[Технічна документація →](docs/README.md)**

## Зміст
- [Що вміє додаток](#що-вміє-додаток)
- [Стек технологій](#стек-технологій)
- [Архітектура](#архітектура)
- [Запуск](#запуск)
- [Структура проекту](#структура-проекту)

---

## Що вміє додаток

| Функція | Статус |
|---|---|
| Відтворення локальних MP3/FLAC/M4A | ✅ |
| YouTube пошук та стрімінг | ✅ |
| Завантаження треків з YouTube | ✅ |
| Синхронізовані тексти пісень (LRC) | ✅ |
| FFT-візуалізатор (Software + Hardware ядра) | ✅ |
| 10-смуговий еквалайзер з пресетами | ✅ |
| Плавний перехід між треками (Crossfade) | ✅ |
| Черга відтворення з drag-and-drop | ✅ |
| Background playback + media notification | ✅ |
| Локальна база даних (SQLite) | ✅ |
| Теми: темна/кастомна | ✅ |

---

## Стек технологій

| Компонент | Технологія |
|---|---|
| UI | Flutter 3.x + Material 3 |
| State management | `provider` (ChangeNotifier) |
| DI / Service locator | `get_it` |
| Аудіо плеєр | `just_audio` + `audio_service` |
| YouTube | `youtube_explode_dart` (кастомний fork) |
| База даних | `sqflite` (SQLite) |
| FFT | `fftea` (Dart) + Android Visualizer (native) |
| Теги аудіофайлів | `audiotags` |
| Зображення | `cached_network_image` + `image` |
| Локалізація | `easy_localization` |
| Налаштування | `shared_preferences` |

---

## Архітектура

```
lib/
├── main.dart                    # Точка входу, реєстрація провайдерів
├── locator.dart                 # GetIt service locator
│
├── core/                        # Глобальні константи, кольори, теми
│
├── models/                      # Дата-класи
│   ├── song_model.dart          # SongModel (id, title, artist, path, duration, ...)
│   ├── history_model.dart       # Модель для збереження історії
│   └── lyrics_line.dart        # Одна строфа тексту пісні (time, text)
│
├── providers/                   # State management
│   ├── audio_provider.dart      # ГОЛОВНИЙ провайдер — агрегує всі mixins
│   ├── queue_manager_mixin.dart         # Черга, shuffle, repeat
│   ├── playback_controls_mixin.dart     # play/pause/seek/stop/sleep timer
│   ├── crossfade_manager_mixin.dart     # Плавний crossfade між треками
│   ├── lyrics_manager_mixin.dart        # Синхронізовані тексти
│   ├── preferences_manager_mixin.dart   # Crossfade toggle та інші префи
│   ├── equalizer_provider.dart  # 10-смуговий EQ + пресети
│   ├── local_library_provider.dart  # Сканування локальної бібліотеки
│   └── visualizer_settings_provider.dart  # Налаштування візуалізатора (по ядру)
│
├── services/                    # Бізнес-логіка, зовнішні API
│   ├── audio_handler.dart       # AudioServiceHandler для background playback
│   ├── playback_manager.dart    # Керує just_audio плеєром
│   ├── database_service.dart    # SQLite: збереження треків, пресетів EQ
│   ├── download_service.dart    # Завантаження YouTube треків
│   ├── lyrics_service.dart      # Пошук текстів (LRC, embedded)
│   ├── native_visualizer_service.dart  # MethodChannel/EventChannel з Android
│   └── youtube_service.dart    # Пошук та резолв URL через youtube_explode_dart
│
├── features/                    # UI по фічах (screens + widgets)
│   ├── main/                   # Головний екран + bottom navigation
│   ├── player/                 # Плеєр + обкладинка + візуалізатор
│   │   └── widgets/
│   │       ├── audio_visualizer.dart     # Stateful widget, слухає stream
│   │       ├── visualizer_painter.dart   # CustomPainter — диспетчер стилів
│   │       ├── visualizer_bars_painter.dart   # Стиль: вертикальні смуги
│   │       ├── visualizer_circle_painter.dart # Стиль: радіальне коло
│   │       ├── visualizer_wave_painter.dart   # Стиль: хвиля
│   │       └── visualizer_settings_sheet.dart # Bottom sheet: всі налаштування
│   ├── library/                # Бібліотека локальних треків
│   ├── search/                 # YouTube пошук
│   ├── lyrics/                 # Екран текстів пісень
│   └── settings/               # Екран налаштувань + еквалайзер
│
└── utils/                       # Утиліти
    ├── app_logger.dart          # Логер з рівнями (verbose/info/error)
    ├── audio_error_handler.dart # Обробка помилок аудіо
    ├── fft_processor.dart       # FFT обробка: Software (fftea) + Hardware (raw bytes)
    ├── fft_tuning.dart          # Константи налаштування FFT (ваги, динамічний діапазон)
    ├── visualizer_physics.dart  # Фізика смужок (attack/release/gravity/bounce)
    ├── library_sorter.dart      # Сортування бібліотеки
    ├── lyrics_parser.dart       # Парсинг LRC файлів
    └── media_metadata_helper.dart  # Читання тегів з аудіофайлів
```

---

## Запуск

```bash
# Встановити залежності
flutter pub get

# Запустити в debug режимі
flutter run

# Зібрати APK
flutter build apk --release
```

> **Мінімальна версія Android:** API 23 (Android 6.0) — потрібна для `android.media.audiofx.Visualizer`

---

## Налаштування проекту

Основні константи в [`lib/core/app_colors.dart`](lib/core/app_colors.dart) — кольорова палітра.

FFT-тюнінг в [`lib/utils/fft_tuning.dart`](lib/utils/fft_tuning.dart).
