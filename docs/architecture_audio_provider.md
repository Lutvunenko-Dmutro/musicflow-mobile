# Архітектура AudioProvider

`AudioProvider` — це **головний провайдер** стану плеєра. Він сам по собі майже порожній і делегує всю логіку через **mixin-систему**.

## Схема наслідування

```
AudioProvider
  ├── QueueManagerMixin         — черга, shuffle, repeat
  ├── PlaybackControlsMixin     — play/pause/seek/next/prev/stop/sleep timer
  ├── CrossfadeManagerMixin     — crossfade між треками
  ├── LyricsManagerMixin        — завантаження і синхронізація текстів
  └── PreferencesManagerMixin   — зберігання налаштувань (crossfade on/off тощо)
```

## Як додати новий функціонал

1. Створи файл `lib/providers/my_feature_mixin.dart`
2. `mixin MyFeatureMixin on ChangeNotifier { ... }`
3. Додай `with MyFeatureMixin` до `AudioProvider`
4. Не перевищуй 200 рядків у файлі — якщо більше, роздробити

## Потік відтворення

```
Користувач → AudioProvider.playSong(song)
  → QueueManagerMixin.setCurrentSong()
  → PlaybackControlsMixin._playCurrentSong()
    → PlaybackManager.play(url/path)
      → just_audio AudioPlayer
        → AudioServiceHandler (background)
```

## Crossfade

Запускається в `PlaybackControlsMixin` коли `remaining <= 3000ms`:

```
_checkCrossfade() → CrossfadeManagerMixin.startCrossfade()
  → Паралельно:
    - fadeOut() на поточному треку (плавне зниження гучності)
    - playSong(nextSong) → fadeIn() на новому треку
```

Вмикається/вимикається через `PreferencesManagerMixin.crossfadeEnabled`.

## Важливо

- `visualizerStream` — це `NativeVisualizerService.visualizerStream` (EventChannel від Android)
- `sessionId` для Android Visualizer береться з `just_audio` після старту відтворення
- Всі налаштування зберігаються через `SharedPreferences`
