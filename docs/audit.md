# 🔍 Повний аудит проекту MusicFlow Mobile

> Останнє оновлення: жовтень 2026

---

## ✅ Сильні сторони

### Архітектура
- **Mixin-система** — `AudioProvider` зібраний з незалежних миксинів, кожен ≤200 рядків. Легко розширювати без торкання основного класу.
- **Два плеєри** (`_player1`, `_player2`) — чистий crossfade без артефактів, кожен зі своїм `AndroidEqualizer`.
- **GetIt service locator** — сервіси підключені через DI, що полегшує тестування і заміну.
- **Розподілені відповідальності** — `PlaybackManager`, `YoutubeService`, `DownloadService` — кожен знає лише своє.

### Функціонал
- **Crossfade** — справжній, на двох `AudioPlayer`, з fade-in/fade-out таймерами.
- **FFT-візуалізатор** — два ядра (Software + Hardware), окремі налаштування для кожного, підбір частот через `FftTuning`.
- **Еквалайзер** — Android-native через `AudioPipeline`, синхронізується на обидва плеєри одночасно, зберігає пресети.
- **YouTube субтитри** → LRC — конвертація `ClosedCaptions` → LRC з мержем коротких фраз і очищенням HTML тегів.
- **Завантаження** — прогрес + швидкість, embed тегів через `audiotags`, Media Scanner з обкладинкою.
- **Error handling** — `AudioErrorHandler` обробляє різні типи помилок по-різному (мережа, формат, дозволи).
- **Logging** — `AppLogger` з кольоровими рівнями і тегами (`YOUTUBE`, `DOWNLOAD`, `EQ`, тощо).

---

## ⚠️ Слабкі сторони

### Критичні вразливості

#### 1. YouTube URL не рефрешиться [✅ ВИПРАВЛЕНО]
```
YoutubeService.getAudioStreamUrl() → повертає пряме URL (дійсне 6 годин)
PlaybackManager: перевіряє query-параметр expire перед запуском
Якщо URL прострочено або виникає помилка 403 → автоматично оновлює лінк та повторює спробу.
AudioProvider: при resume() перевіряє expire і безшовно підхоплює відтворення з збереженої позиції.
```
**Статус:** ✅ Виправлено у `PlaybackManager`, `AudioProvider`, `MusicAudioHandler`.

---

#### 2. `_isAutoChangingSong` — race condition [✅ ВИПРАВЛЕНО]
```dart
// audio_provider.dart + crossfade_manager_mixin.dart
playNextAction: () async {
  _isAutoChangingSong = true;
  await playNext(); // Тепер очікується повне завантаження наступного треку
  _isAutoChangingSong = false;
}
```
**Статус:** ✅ Виправлено — `startCrossfade` та `playNextAction` зроблені асинхронними (`await playNext()`).

---

#### 3. `EqualizerProvider` — подвійне завантаження SharedPreferences
```
EqualizerProvider() → _loadSettingsEarly() → SharedPreferences.getInstance()
потім → _initParameters() → _loadSettings() → SharedPreferences.getInstance()
```
**Ризик:** Низька. Два паралельних читання prefs при старті. Можлива десинхронізація якщо між ними хтось запише.  
**Де:** `equalizer_provider.dart` → конструктор.

---

#### 4. `DatabaseService` — версія БД vs назва файлу
```dart
_initDB('music_flow_v3.db')  // назва файлу — v3
version: 2,                  // але version — 2
```
**Ризик:** Низька, але може заплутати. При наступній міграції легко помилитись.  
**Де:** `database_service.dart` → рядки 15, 25.

---

#### 5. `DownloadService` — хардкод шляху [✅ ВИПРАВЛЕНО]
```dart
// download_service.dart + local_library_provider.dart
final dirPath = await DownloadService.getMusicDirectory();
```
* Перевіряє користувацький вибір у `SharedPreferences`.
* Якщо замовчування: перевіряє системний шлях `/storage/emulated/0/Music`.
* Якщо недоступний (планшет, SD-карта, інший профіль): використовує `path_provider` (`getExternalStorageDirectories(type: StorageDirectory.music)`).
* Fallback: автоматично створює та використовує папку в документах додатку.
**Статус:** ✅ Виправлено у `DownloadService` та `LocalLibraryProvider`.

---

#### 6. Відсутній retry на мережеві помилки YouTube
```dart
// youtube_service.dart
} catch (e) {
  rethrow; // просто кидає помилку вгору без retry
}
```
**Ризик:** Середня. При тимчасовій мережевій помилці (timeout, 429) — трек просто не грає.  
**Рішення:** Додати 3 спроби з затримкою (exponential backoff).

---

#### 7. Visualizer permission запитується при кожному старті [✅ ВИПРАВЛЕНО]
```dart
// audio_visualizer.dart
static bool? _cachedMicPermission;
```
Результат статусу дозволу кешується у статичній змінній та `SharedPreferences`. Запит викликається тільки один раз, при наступних треках чи паузах перевірка миттєва.  
**Статус:** ✅ Виправлено у `AudioVisualizer`.

---

### UX Проблеми

| Проблема | Де | Пріоритет |
|---|---|---|
| FFT кольори б'ють у стелю при гучній музиці | `fft_tuning.dart` — ваги потребують тюнінгу | Середній |
| Hardware FFT більш "дерганий" ніж Software | `fft_processor.dart` → `hwTemporalBlend` | Середній |
| Тексти пісень не синхронізовані з YouTube авто-субтитрів | `youtube_service.dart` → `getYoutubeCaptions()` — offset інколи неточний | Низький |
| Немає індикатора завантаження при старті YouTube треку | `audio_provider.dart` → `_isLoading` не охоплює YouTube resolve | Середній |

---

### Технічний борг

| Файл | Проблема | Складність фіксу |
|---|---|---|
| `MainActivity.kt` | Весь native код в одному файлі (~300+ рядків) | Середня |
| `audio_provider.dart` | `debugPrint()` замість `AppLogger` в деяких місцях | Легка |
| `equalizer_provider.dart` | `debugPrint()` скрізь — не через `AppLogger` | Легка |
| `crossfade_manager_mixin.dart` | `debugPrint()` замість `AppLogger` | Легка |
| `download_service.dart` | Весь код в одній функції `downloadSong()` (170 рядків) | Середня |
| `youtube_service.dart` | `YoutubeExplode` не закривається при помилці — memory leak | Легка |
| Загальне | Немає жодного unit test | Висока |

---

## 📊 Оцінки по категоріях

| Категорія | Оцінка | Коментар |
|---|---|---|
| Архітектура | ⭐⭐⭐⭐⭐ | Mixin-система — правильне рішення |
| Функціонал | ⭐⭐⭐⭐ | Багато фіч, деякі ще сирі |
| Стабільність | ⭐⭐⭐ | YouTube URL і race condition — реальні ризики |
| Performance | ⭐⭐⭐⭐ | FFT в окремому ізоляті, Canvas ефективний |
| Код якість | ⭐⭐⭐ | `debugPrint` замість логера, немає тестів |
| UX | ⭐⭐⭐⭐ | Гарний дизайн, але є дрібні баги |

---

## 🎯 Пріоритетний план фіксів

### Обов'язково (до релізу)
1. ~~**YouTube URL refresh** — при 403 автоматично refetch і retry~~ ✅ Виправлено
2. ~~**Race condition** `_isAutoChangingSong` — `await playNext()`~~ ✅ Виправлено
3. ~~**Download path** — замінити хардкод на `path_provider`~~ ✅ Виправлено

### Бажано
4. Перенести `debugPrint` → `AppLogger` скрізь
5. ~~Кешувати microphone permission~~ ✅ Виправлено
6. Retry при YouTube timeout (3 спроби)

### Коли буде час
7. Розбити `MainActivity.kt` на окремі класи
8. Додати хоч 5–10 unit тестів на критичну логіку
9. Refactor `downloadSong()` — розбити на приватні методи
