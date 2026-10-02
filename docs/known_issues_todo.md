# Відомі проблеми та TODO

## 🔴 Критичні баги

_Наразі немає підтверджених критичних_

## 🟡 Активні задачі

### Візуалізатор
- [ ] FFT ваги потребують подальшого тюнінгу — різні жанри музики дають різний баланс
- [ ] Hardware ядро: `hwTemporalBlend` і `hwBoost` підібрані приблизно, потребують тестування на різних треках
- [ ] Розглянути: зберігати `FftTuning` значення в SharedPreferences щоб можна було тюнити in-app

### Відтворення
- [ ] Crossfade: після затишшя (sleep → next) музика інколи не стартує автоматично
  - **Причина:** `startCrossfade` перевіряє `remaining <= 3000ms`, але при ручному перемиканні цей шлях може не спрацювати
  - **Де дивитись:** `crossfade_manager_mixin.dart` → `startCrossfade()` та `playback_controls_mixin.dart` → `_checkCrossfade()`

### YouTube
- [ ] YouTube URL іноді закінчуються (~6 год) — треба механізм refresh без re-search
- [ ] Обробка 429 (rate limit) від YouTube

## 🟢 Ідеї для майбутнього

- [ ] Ядро візуалізатора: **ML-based** (Class C beats detection для punch на бочку)
- [ ] Еквалайзер: підключити Android native EQ замість кастомного (більш точний)
- [ ] Плейлисти: CRUD + import M3U
- [ ] Last.fm scrobbling
- [ ] Режим Gapless playback (без пауз між треками одного альбому)
- [ ] CarPlay / Android Auto підтримка (через `audio_service`)

## 📝 Технічний борг

| Файл | Проблема |
|---|---|
| `MainActivity.kt` | Весь native код в одному файлі — варто розбити на класи |
| `youtube_service.dart` | Немає retry на network помилки |
| `fft_tuning.dart` | Константи хардкодовані — зробити їх редагованими in-app |
| `audio_visualizer.dart` | `Permission.microphone.request()` при кожному старті — кешувати |

## 🔧 Де що шукати при дебагу

| Симптом | Де дивитись |
|---|---|
| Музика не грає | `playback_controls_mixin.dart` → `_playCurrentSong()` |
| Візуалізатор не рухається | `audio_visualizer.dart` → `_startListening()`, перевір `sessionId` |
| YouTube не знаходить | `youtube_service.dart` → перевір fork, можливо оновився YouTube |
| Crossfade не спрацьовує | `crossfade_manager_mixin.dart` → `startCrossfade()` |
| EQ не застосовується | `equalizer_provider.dart` → `_applyBand()`, перевір sessionId |
| Тексти не завантажуються | `lyrics_service.dart` → порядок пошуку |
| База даних | `database_service.dart` → перевір migration версій |
