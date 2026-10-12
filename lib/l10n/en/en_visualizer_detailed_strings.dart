import 'package:music_flow_mobile/l10n/interfaces/app_visualizer_detailed_strings.dart';

mixin EnVisualizerDetailedStrings implements AppVisualizerDetailedStrings {
  @override
  String get visStyleBars => 'Bars';

  @override
  String get visStyleBarsDesc => 'Classic Equalizer';

  @override
  String get visStyleMirrored => 'Mirror';

  @override
  String get visStyleMirroredDesc => 'Symmetric from Center';

  @override
  String get visStyleCircle => 'Circle';

  @override
  String get visStyleCircleDesc => 'Radial Display';

  @override
  String get visStyleWave => 'Wave';

  @override
  String get visStyleWaveDesc => 'Smooth Audio Wave';

  @override
  String get visPresetClassic => 'Classic';

  @override
  String get visPresetDynamicBass => 'Dynamic Bass';

  @override
  String get visPresetSmoothWave => 'Smooth Wave';

  @override
  String get visPresetNeonCircle => 'Neon Circle';

  @override
  String get visPresetStereoMirror => 'Stereo Mirror';

  @override
  String get visPresetMinimal => 'Minimalism';

  @override
  String get visPresetRecommended => 'Recommended Presets';

  @override
  String get visQuickPresets => 'Quick Presets';

  @override
  String get visStyles => 'Visualizer Style';

  @override
  String get visCore => 'Spectrum Engine (Core)';

  @override
  String get visPhysicsParams => 'Physics & Animation Parameters';

  @override
  String get visCustom => 'Custom';

  @override
  String get visResetTooltip => 'Reset to defaults';

  @override
  String get visResetSuccess => 'Parameters reset to default';

  @override
  String get visCoreSoftwareTitle => 'Software FFT';

  @override
  String get visCoreSoftwareDesc => 'Built-in high precision analysis';

  @override
  String get visCoreHardwareTitle => 'Hardware AudioEffect';

  @override
  String get visCoreHardwareDesc => 'Direct capture from audio chip';

  @override
  String get visSliderSensitivity => 'Sensitivity / Height';

  @override
  String get visSliderSensitivityDesc => 'Bar height response multiplier';

  @override
  String get visSliderAttack => 'Attack Speed';

  @override
  String get visSliderAttackDesc => 'How quickly bars respond to peaks';

  @override
  String get visSliderRelease => 'Release Smoothness';

  @override
  String get visSliderReleaseDesc => 'How smoothly bars decay';

  @override
  String get visSliderGravity => 'Peak Dot Gravity';

  @override
  String get visSliderGravityDesc => 'Falling acceleration of peak dots';

  @override
  String get visSliderBounce => 'Bounce Elasticity';

  @override
  String get visSliderBounceDesc => 'Spring response on sharp transients';

  @override
  String get visLiveStatusDisabled => 'Disabled';

  @override
  String get visLiveStatusPlaying => 'Live Track';

  @override
  String get visLiveStatusTestBeat => 'Test Beat';

  @override
  String get visLiveTestBeatBtn => 'Demo Signal';

  @override
  String get visLiveDisabledHint => 'Visualizer is disabled by top switch';

  @override
  String get visLiveNoMusic => 'No music selected';

  @override
  String get visLiveStartMusicHint => 'Play a track for live reaction';
}
