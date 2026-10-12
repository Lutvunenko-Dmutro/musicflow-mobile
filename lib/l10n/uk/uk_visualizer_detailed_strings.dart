import 'package:music_flow_mobile/l10n/interfaces/app_visualizer_detailed_strings.dart';

mixin UkVisualizerDetailedStrings implements AppVisualizerDetailedStrings {
  @override
  String get visStyleBars => 'Стовпчики';

  @override
  String get visStyleBarsDesc => 'Класичний еквалайзер';

  @override
  String get visStyleMirrored => 'Дзеркало';

  @override
  String get visStyleMirroredDesc => 'Симетрично від центру';

  @override
  String get visStyleCircle => 'Коло';

  @override
  String get visStyleCircleDesc => 'Кругова діаграма';

  @override
  String get visStyleWave => 'Хвиля';

  @override
  String get visStyleWaveDesc => 'Плавна звукова лінія';

  @override
  String get visPresetClassic => 'Класичний';

  @override
  String get visPresetDynamicBass => 'Динамічний Бас';

  @override
  String get visPresetSmoothWave => 'Плавна Хвиля';

  @override
  String get visPresetNeonCircle => 'Неонове Коло';

  @override
  String get visPresetStereoMirror => 'Стерео Дзеркало';

  @override
  String get visPresetMinimal => 'Мінімалізм';

  @override
  String get visPresetRecommended => 'Рекомендовані пресети';

  @override
  String get visQuickPresets => 'Швидкі пресети';

  @override
  String get visStyles => 'Стиль візуалізації';

  @override
  String get visCore => 'Рушій спектру (Core)';

  @override
  String get visPhysicsParams => 'Параметри фізики та анімації';

  @override
  String get visCustom => 'Користувацький';

  @override
  String get visResetTooltip => 'Скинути до стандартних';

  @override
  String get visResetSuccess => 'Параметри скинуто до стандартних';

  @override
  String get visCoreSoftwareTitle => 'Програмне (Software FFT)';

  @override
  String get visCoreSoftwareDesc => 'Вбудований точний аналіз';

  @override
  String get visCoreHardwareTitle => 'Апаратне (Hardware)';

  @override
  String get visCoreHardwareDesc => 'Пряме зняття з аудіочипа';

  @override
  String get visSliderSensitivity => 'Чутливість / Висота';

  @override
  String get visSliderSensitivityDesc => 'Множник підйому смуг від звуку';

  @override
  String get visSliderAttack => 'Швидкість підйому (Attack)';

  @override
  String get visSliderAttackDesc => 'Як швидко стовпчики реагують на бас';

  @override
  String get visSliderRelease => 'Плавність затухання (Release)';

  @override
  String get visSliderReleaseDesc => 'Швидкість опускання смуг після піку';

  @override
  String get visSliderGravity => 'Гравітація пікових крапок';

  @override
  String get visSliderGravityDesc => 'Прискорення падіння верхніх точок';

  @override
  String get visSliderBounce => 'Пружність відскоку (Bounce)';

  @override
  String get visSliderBounceDesc => 'Ефект пружини при різких ударах';

  @override
  String get visLiveStatusDisabled => 'Вимкнено';

  @override
  String get visLiveStatusPlaying => 'В ефірі (Трек)';

  @override
  String get visLiveStatusTestBeat => 'Тестовий біт';

  @override
  String get visLiveTestBeatBtn => 'Демо-сигнал';

  @override
  String get visLiveDisabledHint => 'Візуалізатор вимкнено перемикачем угорі';

  @override
  String get visLiveNoMusic => 'Музику не вибрано';

  @override
  String get visLiveStartMusicHint => 'Увімкніть трек для живої реакції';
}
