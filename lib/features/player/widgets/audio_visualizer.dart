import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static bool? _cachedMicPermission;
  static bool _hasRequestedPermission = false;

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
    // Перевіряємо дозвіл лише якщо статус ще не відомий або не наданий
    if (_cachedMicPermission != true) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('mic_permission_granted') == true) {
        _cachedMicPermission = true;
      } else {
        var status = await Permission.microphone.status;
        if (status.isGranted) {
          _cachedMicPermission = true;
          await prefs.setBool('mic_permission_granted', true);
        } else if (!_hasRequestedPermission && !status.isPermanentlyDenied) {
          _hasRequestedPermission = true;
          status = await Permission.microphone.request();
          _cachedMicPermission = status.isGranted;
          if (status.isGranted) {
            await prefs.setBool('mic_permission_granted', true);
          }
        }
      }
    }

    if (_cachedMicPermission == true) {
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

  void _processWaveform(List<int> raw) {
    if (!mounted) return;
    if (_settings.core == VisualizerCore.hardware) {
      // Hardware mode: Android sends raw FFT bytes (packed real/imag pairs).
      // We skip our own FFT and map magnitudes directly to bars.
      _targetHeights = FftProcessor.processHardwareFft(
        raw,
        widget.barCount,
        amplitudeBoost: _settings.amplitudeBoost,
      );
    } else {
      // Software mode: time-domain waveform → our own FFT (fftea)
      _targetHeights = FftProcessor.process(
        raw,
        widget.barCount,
        amplitudeBoost: _settings.amplitudeBoost,
      );
    }
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
