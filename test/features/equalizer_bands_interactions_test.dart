import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/equalizer_bands.dart';

class MockEqualizerProviderForBands extends ChangeNotifier implements EqualizerProvider {
  final List<double> _gains = List.filled(10, 0.0);

  @override
  int get bandCount => 10;

  @override
  List<double> get bandGains => _gains;

  @override
  double get minDecibels => -15.0;

  @override
  double get maxDecibels => 15.0;

  @override
  double getBandFrequency(int index) {
    const freqs = [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0];
    if (index >= 0 && index < freqs.length) return freqs[index];
    return 1000.0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('EqualizerBandsWidget Slider Interactions', () {
    testWidgets('Renders 10 frequency sliders and dragging changes band gain', (tester) async {
      final mockProvider = MockEqualizerProviderForBands();
      int changedIndex = -1;
      double changedVal = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 300,
                child: EqualizerBandsWidget(
                  provider: mockProvider,
                  onBandChanged: (index, val) {
                    changedIndex = index;
                    changedVal = val;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify band count
      expect(mockProvider.bandCount, equals(10));
      final sliders = find.byType(Slider);
      expect(sliders, findsNWidgets(10));

      // Drag the first slider (31 Hz band)
      final firstSlider = sliders.first;
      await tester.drag(firstSlider, const Offset(0, -50));
      await tester.pumpAndSettle();

      expect(changedIndex, equals(0));
      expect(changedVal, isNot(equals(0.0)));
    });
  });
}
