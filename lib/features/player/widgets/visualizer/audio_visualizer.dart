import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/utils/fft_processor.dart';
import 'package:music_flow_mobile/utils/visualizer_physics.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_painter.dart';
import 'package:music_flow_mobile/features/player/utils/visualizer_permission_helper.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer/visualizer_mock_generator.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class AudioVisualizer extends StatefulWidget {
  final int barCount;
  final bool isPlaying;
  final double width;
  final double height;
  final bool testMode;

  const AudioVisualizer({
    super.key,
    this.barCount = 60,
    required this.isPlaying,
    this.width = 240,
    this.height = 48,
    this.testMode = false,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late List<double> _currentHeights;
  late List<double> _targetHeights;
  late List<double> _dotHeights;
  late List<double> _dotVelocities;

  Ticker? _ticker;
  Timer? _testTimer;
  final VisualizerMockGenerator _mockGenerator = VisualizerMockGenerator();
  late VisualizerSettingsProvider _settings;
  StreamSubscription? _visualizerSubscription;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  bool _isStartingListening = false;

  @override
  void initState() {
    super.initState();
    _currentHeights = List.filled(widget.barCount, 0.05);
    _targetHeights = List.filled(widget.barCount, 0.05);
    _dotHeights = List.filled(widget.barCount, 0.05);
    _dotVelocities = List.filled(widget.barCount, 0.0);

    _ticker = createTicker(_onTick);
    if (widget.isPlaying) {
      _startListening();
    } else if (widget.testMode) {
      _startTestSimulation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = Provider.of<VisualizerSettingsProvider>(context);
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying || widget.testMode != oldWidget.testMode) {
      if (widget.isPlaying) {
        _stopTestSimulation();
        _startListening();
      } else if (widget.testMode) {
        _stopListening();
        _startTestSimulation();
      } else {
        _stopTestSimulation();
        _stopListening();
      }
    }
  }

  void _startTestSimulation() {
    _testTimer?.cancel();
    if (_ticker != null && !_ticker!.isTicking) _ticker!.start();
    _testTimer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (mounted) _processWaveform(_mockGenerator.generateNextFrame());
    });
  }

  void _stopTestSimulation() {
    _testTimer?.cancel();
    _testTimer = null;
  }

  Future<void> _startListening() async {
    if (_isStartingListening) return;
    _isStartingListening = true;
    try {
      final hasPermission = await VisualizerPermissionHelper.checkOrRequestMicPermission();
      if (hasPermission && mounted && widget.isPlaying) {
        final provider = context.read<AudioProvider>();
        await _visualizerSubscription?.cancel();
        _visualizerSubscription = provider.visualizerStream.listen((dynamic event) {
          if (event is List<dynamic> || event is List<int>) {
            _processWaveform((event as List).cast<int>());
          }
        });
        if (_ticker != null && !_ticker!.isTicking) _ticker!.start();
      } else if (mounted) {
        _targetHeights = List.filled(widget.barCount, 0.05);
      }
    } finally {
      _isStartingListening = false;
    }
  }

  void _stopListening() {
    _isStartingListening = false;
    _visualizerSubscription?.cancel();
    _visualizerSubscription = null;
    if (mounted) {
      _targetHeights = List.filled(widget.barCount, 0.05);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !widget.isPlaying && _ticker != null && _ticker!.isTicking) {
          _ticker!.stop();
        }
      });
    }
  }

  void _onTick(Duration elapsed) {
    VisualizerPhysics.updateHeights(
      barCount: widget.barCount,
      targetHeights: _targetHeights,
      currentHeights: _currentHeights,
      dotHeights: _dotHeights,
      dotVelocities: _dotVelocities,
      attack: _settings.attack,
      release: _settings.release,
      gravity: _settings.gravity,
      bounce: _settings.bounce,
      onRepaintNeeded: () {
        if (mounted) _repaintNotifier.value++;
      },
    );
  }

  void _processWaveform(List<int> raw) {
    if (!mounted) return;
    if (_settings.core == VisualizerCore.hardware) {
      _targetHeights = FftProcessor.processHardwareFft(raw, widget.barCount, amplitudeBoost: _settings.amplitudeBoost);
    } else {
      _targetHeights = FftProcessor.process(raw, widget.barCount, amplitudeBoost: _settings.amplitudeBoost);
    }
  }

  @override
  void dispose() {
    _stopTestSimulation();
    _ticker?.dispose();
    _visualizerSubscription?.cancel();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SizedBox.expand(
            child: CustomPaint(
              painter: VisualizerPainter(
                heights: _currentHeights,
                dotHeights: _dotHeights,
                barCount: widget.barCount,
                style: _settings.style,
                repaint: _repaintNotifier,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
