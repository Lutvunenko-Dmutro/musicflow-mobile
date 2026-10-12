import 'package:flutter/material.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/providers/equalizer_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/rotary_knob.dart';

class EqualizerKnobsWidget extends StatelessWidget {
  final EqualizerProvider provider;

  const EqualizerKnobsWidget({
    super.key,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.soundBoostTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.headphones, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                l10n.soundBoostHint,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              RotaryKnob(
                label: l10n.bassKnob,
                value: provider.bassBoost,
                onChanged: (val) => provider.setBassBoost(val),
              ),
              RotaryKnob(
                label: l10n.immersionKnob,
                value: provider.virtualizer,
                onChanged: (val) => provider.setVirtualizer(val),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
