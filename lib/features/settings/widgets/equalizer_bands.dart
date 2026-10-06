import 'package:flutter/material.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';

class EqualizerBandsWidget extends StatelessWidget {
  final EqualizerProvider provider;
  final void Function(int index, double val) onBandChanged;

  const EqualizerBandsWidget({
    super.key,
    required this.provider,
    required this.onBandChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(provider.bandCount, (index) {
          final gain = provider.bandGains[index];
          final min = provider.minDecibels;
          final max = provider.maxDecibels;
          final isModified = gain.abs() > 0.1;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Column(
              children: [
                Text(
                  '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isModified ? FontWeight.bold : FontWeight.normal,
                    color: isModified ? primary : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primary,
                        inactiveTrackColor: Colors.grey[800],
                        thumbColor: isModified ? Colors.white : Colors.grey[400],
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        trackHeight: 3.5,
                      ),
                      child: Slider(
                        value: gain.clamp(min, max),
                        min: min,
                        max: max,
                        onChanged: (val) => onBandChanged(index, val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatHz(provider.getBandFrequency(index)),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isModified ? Colors.white : Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _formatHz(double hz) {
    if (hz >= 1000) {
      final kVal = hz / 1000;
      return kVal == kVal.roundToDouble()
          ? '${kVal.toInt()}k'
          : '${kVal.toStringAsFixed(1)}k';
    }
    return '${hz.toInt()}';
  }
}
