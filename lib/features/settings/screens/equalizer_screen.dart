import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';
import 'package:music_flow_mobile/features/player/widgets/audio_visualizer.dart';

class EqualizerScreen extends StatelessWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    
    return ChangeNotifierProvider.value(
      value: audioProvider.equalizerProvider,
      child: const _EqualizerScreenBody(),
    );
  }
}

class _EqualizerScreenBody extends StatefulWidget {
  const _EqualizerScreenBody();

  @override
  State<_EqualizerScreenBody> createState() => _EqualizerScreenBodyState();
}

class _EqualizerScreenBodyState extends State<_EqualizerScreenBody> {
  String _activePreset = 'Налаштувати';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EqualizerProvider>(context);
    final audioProvider = context.watch<AudioProvider>();
    final isEnabled = provider.isEnabled;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.parameters == null) {
        provider.initIfNeeded();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Еквалайзер'),
        backgroundColor: Colors.transparent,
        actions: [
          Switch(
            value: isEnabled,
            onChanged: (val) => provider.toggleEqualizer(),
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
      body: !isEnabled
          ? const Center(
              child: Text(
                'Еквалайзер вимкнено',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              children: [
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: AudioVisualizer(
                    isPlaying: audioProvider.isPlaying,
                    width: MediaQuery.of(context).size.width,
                    height: 120,
                  ),
                ),
                const SizedBox(height: 24),
                _buildBands(context, provider),
                const SizedBox(height: 32),
                _buildKnobs(context, provider),
                const SizedBox(height: 32),
                _buildPresets(context, provider),
                const SizedBox(height: 32),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        final audioProvider = context.read<AudioProvider>();
                        final sessionId = audioProvider.player.androidAudioSessionId;
                        const channel = MethodChannel('com.example.music_flow_mobile/visualizer_method');
                        await channel.invokeMethod('openSystemEqualizer', {'sessionId': sessionId});
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Не вдалося відкрити налаштування звуку')),
                        );
                      }
                    },
                    icon: const Icon(Icons.settings_suggest),
                    label: const Text('Системний еквалайзер / Звукові ефекти'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
    );
  }

  Widget _buildBands(BuildContext context, EqualizerProvider provider) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(provider.bandCount, (index) {
          final gain = provider.bandGains[index];
          final min = provider.minDecibels;
          final max = provider.maxDecibels;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Column(
              children: [
                Text(
                  '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(1)} dB',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Theme.of(context).primaryColor,
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: Colors.white,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: gain.clamp(min, max),
                        min: min,
                        max: max,
                        onChanged: (val) {
                          setState(() => _activePreset = 'Налаштувати');
                          provider.setBandGain(index, val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatHz(provider.getBandFrequency(index)),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKnobs(BuildContext context, EqualizerProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Посилення звуку',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.headphones, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Одягніть навушники перед регулюванням звукових ефектів',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RotaryKnob(
                label: 'Бас',
                value: provider.bassBoost,
                onChanged: (val) => provider.setBassBoost(val),
              ),
              _RotaryKnob(
                label: 'Звук із зануренням',
                value: provider.virtualizer,
                onChanged: (val) => provider.setVirtualizer(val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresets(BuildContext context, EqualizerProvider provider) {
    final presets = [
      'Налаштувати', 'Звичайний', 'Класика',
      'Танцювальна', 'Стандарт', 'Фолк',
      'Метал', 'Хіп-хоп', 'Джаз',
      'Поп', 'Рок'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Рекомендовані пресети',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final preset = presets[index];
              final isActive = preset == _activePreset;
              return GestureDetector(
                onTap: () {
                  setState(() => _activePreset = preset);
                  provider.applyPreset(preset);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive ? Theme.of(context).primaryColor : const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    preset,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey[300],
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatHz(double hz) {
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(0)}k';
    }
    return '${hz.toInt()}';
  }
}

class _RotaryKnob extends StatefulWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;

  const _RotaryKnob({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_RotaryKnob> createState() => _RotaryKnobState();
}

class _RotaryKnobState extends State<_RotaryKnob> {
  double _currentValue = 0.0;
  final double _minAngle = -pi * 0.75;
  final double _maxAngle = pi * 0.75;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant _RotaryKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // Simple vertical drag to change value
    setState(() {
      _currentValue -= details.delta.dy * 0.01;
      _currentValue += details.delta.dx * 0.01;
      _currentValue = _currentValue.clamp(0.0, 1.0);
    });
    widget.onChanged(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    final angle = _minAngle + (_maxAngle - _minAngle) * _currentValue;
    
    return Column(
      children: [
        GestureDetector(
          onPanUpdate: _onPanUpdate,
          child: SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _KnobPainter(
                value: _currentValue,
                angle: angle,
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.label,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final double angle;
  final Color activeColor;

  _KnobPainter({
    required this.value,
    required this.angle,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw dots track
    const int totalDots = 20;
    const double minA = -pi * 0.75;
    const double maxA = pi * 0.75;
    final int activeDots = (value * totalDots).round();

    for (int i = 0; i <= totalDots; i++) {
      final a = minA + (maxA - minA) * (i / totalDots);
      final r = radius - 4;
      final x = center.dx + r * sin(a);
      final y = center.dy - r * cos(a);
      
      canvas.drawCircle(
        Offset(x, y),
        2,
        i <= activeDots ? (Paint()..color = activeColor) : (Paint()..color = Colors.grey[800]!),
      );
    }

    // Draw knob base
    final knobPaint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 16, knobPaint);

    // Draw knob outer ring
    final knobRingPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 16, knobRingPaint);

    // Draw indicator line
    final indicatorPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final ix = center.dx + (radius - 24) * sin(angle);
    final iy = center.dy - (radius - 24) * cos(angle);
    
    // Draw line from slightly off center to the edge
    final innerIx = center.dx + (radius - 36) * sin(angle);
    final innerIy = center.dy - (radius - 36) * cos(angle);
    
    canvas.drawLine(Offset(innerIx, innerIy), Offset(ix, iy), indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.angle != angle;
  }
}
