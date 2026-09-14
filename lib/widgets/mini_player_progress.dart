import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';

class MiniPlayerProgress extends StatelessWidget {
  const MiniPlayerProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    
    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final total = audioProvider.currentSong?.duration ?? Duration.zero;
        
        return SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Theme.of(context).primaryColor,
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: Container(
            height: 12,
            margin: const EdgeInsets.only(top: 0),
            child: Builder(
              builder: (context) {
                double sliderMax = total.inMilliseconds.toDouble();
                if (sliderMax <= 0.0) sliderMax = 1.0;
                
                double sliderValue = position.inMilliseconds.toDouble();
                if (sliderValue < 0.0) sliderValue = 0.0;
                if (sliderValue > sliderMax) sliderValue = sliderMax;

                return Slider(
                  value: sliderValue,
                  max: sliderMax,
                  onChanged: (val) {
                    audioProvider.seek(Duration(milliseconds: val.toInt()));
                  },
                );
              }
            ),
          ),
        );
      },
    );
  }
}
