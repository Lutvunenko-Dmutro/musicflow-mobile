# Система візуалізатора

## Загальна схема

```
Android AudioPlayer (just_audio)
  → sessionId
    → MainActivity.kt: startVisualizer(sessionId)
      → android.media.audiofx.Visualizer
        → EventChannel (com.example.music_flow_mobile/visualizer_event)
          → NativeVisualizerService.visualizerStream (Dart)
            → AudioVisualizer (widget) слухає stream
              → FftProcessor.process() або processHardwareFft()
                → _targetHeights[]
                  → VisualizerPhysics.updateHeights() (tick)
                    → _currentHeights[]
                      → VisualizerPainter (CustomPainter)
                        → Малює на Canvas
```

## Ядра візуалізатора (VisualizerCore)

### Software (за замовчуванням)
- Android надсилає **сирову звукову хвилю** (waveform bytes)
- Flutter (`FftProcessor.process()`) сам рахує FFT через бібліотеку `fftea`
- Розмір FFT: 4096 samples (rolling buffer)
- Плавніший результат, не залежить від апаратного DSP

### Hardware
- Android надсилає **готові FFT байти** від апаратного DSP
- Flutter (`FftProcessor.processHardwareFft()`) лише декодує packed real/imag байти
- Формат: `[DC_re, Nyquist_re, re1, im1, re2, im2, ...]` (signed bytes через unsigned EventChannel)
- Різкіший, більш "hardware" характер — залежить від конкретного телефону

### Перемикання ядра
```dart
// Flutter
VisualizerSettingsProvider.setCore(VisualizerCore.hardware)
  → NativeVisualizerService.setVisualizerCore('hardware')
    → MethodChannel → MainActivity.kt
      → visualizer.enabled = false
      → setDataCaptureListener(captureWaveform: false, captureFft: true)
      → visualizer.enabled = true
```

## Налаштування (VisualizerSettingsProvider)

Кожне ядро має **окремі** налаштування:

| Параметр | Software default | Hardware default | Що робить |
|---|---|---|---|
| `attack` | 0.60 | 0.30 | Швидкість підйому смужки |
| `release` | 0.40 | 0.20 | Швидкість падіння смужки |
| `gravity` | -0.008 | -0.005 | Швидкість падіння плаваючої лінії |
| `bounce` | 0.060 | 0.030 | Відскок плаваючої лінії |
| `amplitudeBoost` | 1.0 | 1.0 | Загальний множник висоти |

Зберігаються в SharedPreferences з префіксом `sw_` або `hw_`.

## FFT Тюнінг (FftTuning)

Файл: `lib/utils/fft_tuning.dart`

```dart
noiseFloor  = -55.0  // Нижня межа dB (сигнали нижче = 0%)
maxDbOffset =   0.0  // Стеля для басів (для вищих частот: maxDb + 20*log10(weight))
```

### Кольорові зони та ваги

| Колір | Частоти | Бари | Weight | Призначення |
|---|---|---|---|---|
| 🟥 Червоні | 30–760 Hz | 24 | 0.60 | Бочка, бас-гітара |
| 🟧 Помаранчеві | 860–3920 Hz | 18 | 2.5 | Вокал, гітари, синтезатори |
| 🟨 Жовті | 4200–7300 Hz | 12 | 5.0 | Верхній вокал, скрипки |
| 🟦 Сині | 7600–10000 Hz | 6 | 8.0 | Тарілки, хай-хети |

**Чому різні ваги?** Людське вухо і мікшери зводять високі частоти значно тихіше за баси. Без компенсації сині смужки взагалі не рухались би.

## Фізика смужок (VisualizerPhysics)

Кожна смужка анімована незалежно:
1. `_currentHeights[i]` наближається до `_targetHeights[i]` зі швидкістю `attack/release`
2. Плаваюча лінія (`_dotHeights[i]`) підіймається разом зі смужкою, потім падає під дією `gravity`
3. При зіткненні з смужкою — відскок з коефіцієнтом `bounce`

## Стилі відображення (VisualizerStyle)

| Стиль | Файл | Опис |
|---|---|---|
| `bars` | visualizer_bars_painter.dart | Стандартні вертикальні смуги |
| `mirrored` | visualizer_bars_painter.dart | Смуги від центру (вверх + вниз) |
| `circle` | visualizer_circle_painter.dart | Радіальне коло |
| `wave` | visualizer_wave_painter.dart | Плавна хвиля |

## Дозволи

Потрібен `RECORD_AUDIO` (для Android Visualizer). Запитується при першому старті через `permission_handler`.
