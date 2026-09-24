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
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            thumbColor: Theme.of(context).primaryColor,
            trackShape: const RectangularSliderTrackShape(),
          ),
          child: Container(
            height: 20,
            margin: const EdgeInsets.only(top: 0),
            child: Builder(
              builder: (context) {
                double sliderMax = total.inMilliseconds.toDouble();
                if (sliderMax <= 0.0) sliderMax = 1.0;
                
                double sliderValue = position.inMilliseconds.toDouble();
                if (sliderValue < 0.0) sliderValue = 0.0;
                if (sliderValue > sliderMax) sliderValue = sliderMax;

                return SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackShape: _CustomTrackShape(),
                  ),
                  child: Slider(
                    value: sliderValue,
                    max: sliderMax,
                    onChanged: (val) {
                      audioProvider.seek(Duration(milliseconds: val.toInt()));
                    },
                  ),
                );
              }
            ),
          ),
        );
      },
    );
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 2.0;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
