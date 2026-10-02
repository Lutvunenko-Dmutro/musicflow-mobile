import 'dart:math';
import 'package:flutter/material.dart';

class RotaryKnob extends StatefulWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final ValueChanged<double> onChanged;

  const RotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<RotaryKnob> createState() => _RotaryKnobState();
}

class _RotaryKnobState extends State<RotaryKnob> {
  double _currentValue = 0.0;
  final double _minAngle = -pi * 0.75;
  final double _maxAngle = pi * 0.75;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(covariant RotaryKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
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

    final knobPaint = Paint()
      ..color = const Color(0xFF424242)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 16, knobPaint);

    final knobRingPaint = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 16, knobRingPaint);

    final indicatorPaint = Paint()
      ..color = activeColor
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final ix = center.dx + (radius - 24) * sin(angle);
    final iy = center.dy - (radius - 24) * cos(angle);
    
    final innerIx = center.dx + (radius - 36) * sin(angle);
    final innerIy = center.dy - (radius - 36) * cos(angle);
    
    canvas.drawLine(Offset(innerIx, innerIy), Offset(ix, iy), indicatorPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.angle != angle;
  }
}
