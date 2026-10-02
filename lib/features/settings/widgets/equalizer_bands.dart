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
                        onChanged: (val) => onBandChanged(index, val),
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

  String _formatHz(double hz) {
    if (hz >= 1000) {
      return '${(hz / 1000).toStringAsFixed(0)}k';
    }
    return '${hz.toInt()}';
  }
}
