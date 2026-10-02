# Сервіси та зовнішні API

## PlaybackManager

**Файл:** `lib/services/playback_manager.dart`

Обгортка над `just_audio`. Відповідає за:
- Завантаження треку (`setUrl` / `setFilePath`)
- `play()`, `pause()`, `seek()`
- Надає `positionStream`, `durationStream`, `playerStateStream`
- Отримання `sessionId` (для Android Visualizer після початку відтворення)

## AudioHandler

**Файл:** `lib/services/audio_handler.dart`

Реалізує `BaseAudioHandler` з `audio_service`. Відповідає за:
- Медіа-нотифікацію в шторці Android
- Кнопки: play/pause/next/prev на headphones та notification
- Lock screen controls

## DatabaseService

**Файл:** `lib/services/database_service.dart`

SQLite база через `sqflite`. Таблиці:
- `songs` — локальні треки (path, title, artist, album, duration, artPath)
- `eq_presets` — кастомні пресети еквалайзера

Доступ через GetIt: `locator<DatabaseService>()`

## YouTubeService

**Файл:** `lib/services/youtube_service.dart`

Використовує `youtube_explode_dart` (кастомний fork з фіксом 403).

Методи:
- `search(query)` → `List<SongModel>`
- `getStreamUrl(videoId)` → `String` (пряме аудіо URL)

> ⚠️ YouTube API нестабільний — може ламатись при оновленні сайту. Форк: `its-ashutosh-pathak/youtube_explode_dart` (гілка `fix-visionos-403`)

## DownloadService

**Файл:** `lib/services/download_service.dart`

Завантажує аудіо з YouTube на пристрій:
1. Отримує stream URL через `YouTubeService`
2. Завантажує через `http` з прогресом
3. Зберігає в `getApplicationDocumentsDirectory()/downloads/`
4. Додає в локальну бібліотеку через `DatabaseService`

## LyricsService

**Файл:** `lib/services/lyrics_service.dart`

Пошук текстів (у пріоритеті):
1. Embedded LRC теги з аудіофайлу (через `audiotags`)
2. LRC файл поруч з треком (same folder, same name)
3. Зовнішній API (lrclib або подібний)

Повертає `List<LyricsLine>` — пари `(Duration time, String text)`

## NativeVisualizerService

**Файл:** `lib/services/native_visualizer_service.dart`

Міст між Flutter і Android `Visualizer`:

```
MethodChannel: com.example.music_flow_mobile/visualizer_method
  → startVisualizer(sessionId)    — запустити візуалізатор
  → stopVisualizer()              — зупинити
  → setVisualizerCore(core)       — 'software' або 'hardware'
  → openSoundSettings()           — відкрити системні налаштування звуку

EventChannel: com.example.music_flow_mobile/visualizer_event
  → stream ByteArray (waveform або FFT) ~30 FPS
```

Kotlin реалізація: `android/app/src/main/kotlin/.../MainActivity.kt`
