import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/providers/audio/preferences_manager_mixin.dart';
import 'package:audio_session/audio_session.dart';

class TestPreferencesProvider with ChangeNotifier, PreferencesManagerMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('smoothMediaPause preference defaults to true and can be toggled', () async {
    final provider = TestPreferencesProvider();
    await provider.initPrefs();
    expect(provider.smoothMediaPause, isTrue);

    await provider.toggleSmoothMediaPause(false);
    expect(provider.smoothMediaPause, isFalse);

    await provider.toggleSmoothMediaPause(true);
    expect(provider.smoothMediaPause, isTrue);
  });

  test('Check AudioSession configuration and streams', () async {
    final session = await AudioSession.instance;
    const config = AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    );
    await session.configure(config);
    expect(config.androidWillPauseWhenDucked, isTrue);
    expect(session.interruptionEventStream, isNotNull);
    expect(session.becomingNoisyEventStream, isNotNull);
  });
}
