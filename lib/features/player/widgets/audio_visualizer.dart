import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/utils/fft_processor.dart';
import 'package:music_flow_mobile/utils/visualizer_physics.dart';
import 'package:music_flow_mobile/features/player/widgets/visualizer_painter.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class AudioVisualizer extends StatefulWidget {
  final int barCount;
  final bool isPlaying;
  final double width;
  final double height;

  const AudioVisualizer({
    super.key,
    this.barCount = 60,
    required this.isPlaying,
    this.width = 240,
    this.height = 48,
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
  late VisualizerSettingsProvider _settings;
  StreamSubscription? _visualizerSubscription;
  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);

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
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _startListening();
      } else {
        _stopListening();
      }
    }
  }

  Future<void> _startListening() async {
    // Check permissions
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      if (!mounted) return;
      final provider = context.read<AudioProvider>();
      
      await _visualizerSubscription?.cancel();
      _visualizerSubscription = provider.visualizerStream.listen((dynamic event) {
        if (event is List<dynamic> || event is List<int>) {
          List<int> waveformData = (event as List).cast<int>();
          _processWaveform(waveformData);
        }
      });
      
      if (!_ticker!.isTicking) {
        _ticker!.start();
      }
    } else {
      if (mounted) {
        _targetHeights = List.filled(widget.barCount, 0.05);
      }
    }
  }

  void _stopListening() {
    _visualizerSubscription?.cancel();
    _visualizerSubscription = null;
    
    // Плавно опускаємо смужки до нуля
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

  void _processWaveform(List<int> waveform) {
    if (!mounted) return;
    _targetHeights = FftProcessor.process(
      waveform, 
      widget.barCount,
      amplitudeBoost: _settings.amplitudeBoost,
    );
  }

  @override
  void dispose() {
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
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
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
