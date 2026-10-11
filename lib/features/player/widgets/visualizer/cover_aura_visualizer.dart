import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/utils/fft_processor.dart';
import 'package:music_flow_mobile/utils/visualizer_physics.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_mock_generator.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/cover_aura_painter.dart';

class CoverAuraVisualizer extends StatefulWidget {
  final Widget child;
  final double coverSize;
  final Color? dominantColor;

  const CoverAuraVisualizer({
    super.key,
    required this.child,
    required this.coverSize,
    this.dominantColor,
  });

  @override
  State<CoverAuraVisualizer> createState() => _CoverAuraVisualizerState();
}

class _CoverAuraVisualizerState extends State<CoverAuraVisualizer>
    with SingleTickerProviderStateMixin {
  static const int _barCount = 48;
  late List<double> _currentHeights, _targetHeights, _dotHeights, _dotVelocities;
  Ticker? _ticker;
  Timer? _testTimer;
  final VisualizerMockGenerator _mock = VisualizerMockGenerator();
  StreamSubscription? _subscription;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _currentHeights = List.filled(_barCount, 0.05);
    _targetHeights = List.filled(_barCount, 0.05);
    _dotHeights = List.filled(_barCount, 0.05);
    _dotVelocities = List.filled(_barCount, 0.0);
    _ticker = createTicker(_onTick);
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final s = context.read<VisualizerSettingsProvider?>();
    if (s == null) return;

    VisualizerPhysics.updateHeights(
      barCount: _barCount,
      targetHeights: _targetHeights,
      currentHeights: _currentHeights,
      dotHeights: _dotHeights,
      dotVelocities: _dotVelocities,
      attack: s.attack,
      release: s.release,
      gravity: s.gravity,
      bounce: s.bounce,
      onRepaintNeeded: () {
        if (mounted) _repaintNotifier.value++;
      },
    );
  }

  void _processWaveform(List<int> raw) {
    if (!mounted) return;
    final s = context.read<VisualizerSettingsProvider?>();
    if (s == null) return;
    final b = s.amplitudeBoost;
    _targetHeights = s.core == VisualizerCore.hardware
        ? FftProcessor.processHardwareFft(raw, _barCount, amplitudeBoost: b)
        : FftProcessor.process(raw, _barCount, amplitudeBoost: b);
  }

  void _updateActiveState(bool isPlaying, bool isCoverAura) {
    if (isPlaying && isCoverAura) {
      if (_ticker?.isTicking == false) _ticker?.start();
      if (_subscription == null) {
        final provider = context.read<AudioProvider>();
        _subscription = provider.visualizerStream.listen((event) {
          if (event is List<dynamic> || event is List<int>) {
            _processWaveform((event as List).cast<int>());
          }
        });
      }
      _testTimer ??= Timer.periodic(const Duration(milliseconds: 30), (_) {
        if (mounted) _processWaveform(_mock.generateNextFrame());
      });
    } else {
      _ticker?.stop();
      _testTimer?.cancel();
      _testTimer = null;
      _subscription?.cancel();
      _subscription = null;
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _testTimer?.cancel();
    _subscription?.cancel();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<VisualizerSettingsProvider?>();
    final isPlaying = context.select<AudioProvider, bool>((p) => p.isPlaying);
    final isAura = settings?.position == VisualizerPosition.coverAura;

    _updateActiveState(isPlaying, isAura);

    if (!isAura || settings == null) {
      return widget.child;
    }

    final totalSize = widget.coverSize + 80.0;

    return SizedBox(
      width: totalSize,
      height: totalSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _repaintNotifier,
            builder: (_, __, ___) => CustomPaint(
              size: Size(totalSize, totalSize),
              painter: CoverAuraPainter(
                heights: _currentHeights,
                dotHeights: _dotHeights,
                shape: settings.coverShape,
                colorScheme: settings.colorScheme,
                dominantColor: widget.dominantColor,
                coverSize: widget.coverSize,
                maxRayLength: 36.0,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
