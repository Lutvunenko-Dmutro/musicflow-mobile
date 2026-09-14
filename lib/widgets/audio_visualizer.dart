import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../utils/fft_processor.dart';
import 'visualizer_painter.dart';
import '../providers/visualizer_settings_provider.dart';
import '../providers/audio_provider.dart';
import '../utils/app_logger.dart';

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
    bool needsRepaint = false;
    double gravity = _settings.gravity;
    double bounce = _settings.bounce;
    double attack = _settings.attack;
    double release = _settings.release;

    for (int i = 0; i < widget.barCount; i++) {
      double target = _targetHeights[i];
      double current = _currentHeights[i];
      
      double oldCurrent = current;
      if (target > current) {
        _currentHeights[i] += (target - current) * attack;
        needsRepaint = true;
      } else if (current > target) {
        _currentHeights[i] += (target - current) * release;
        needsRepaint = true;
      }
      
      if ((_currentHeights[i] - target).abs() < 0.001) {
        _currentHeights[i] = target;
      }

      if (_currentHeights[i] >= _dotHeights[i]) {
        _dotHeights[i] = _currentHeights[i];
        
        // Розраховуємо швидкість, з якою смужка вдарила по крапці
        double barVelocity = _currentHeights[i] - oldCurrent;
        if (barVelocity > 0) {
          // Чим сильніший удар (вища швидкість), тим більше крапка відскакує.
          // Множник 25.0 налаштовує чутливість, а clamp обмежує максимальний відскок.
          double bounceFactor = (barVelocity * 25.0).clamp(0.0, 2.0);
          _dotVelocities[i] = bounce * bounceFactor;
        } else {
          _dotVelocities[i] = 0.0;
        }
      } else {
        _dotVelocities[i] += gravity;
        _dotHeights[i] += _dotVelocities[i];
        
        if (_dotHeights[i] < _currentHeights[i]) {
          _dotHeights[i] = _currentHeights[i];
          _dotVelocities[i] = 0.0;
        }
      }
      if (_dotVelocities[i] != 0.0 || _dotHeights[i] > _currentHeights[i]) {
        needsRepaint = true;
      }
    }
    
    if (needsRepaint && mounted) {
      setState(() {});
    }
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: CustomPaint(
        painter: VisualizerPainter(
          heights: _currentHeights,
          dotHeights: _dotHeights,
          barCount: widget.barCount,
        ),
      ),
    );
  }
}
