import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/providers/visualizer_settings_provider.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_live_preview_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_presets_row.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_styles_grid.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_core_selector.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_sliders_card.dart';
import 'package:music_flow_mobile/features/settings/widgets/visualizer/visualizer_appearance_card.dart';

class VisualizerSettingsScreen extends StatefulWidget {
  const VisualizerSettingsScreen({super.key});

  @override
  State<VisualizerSettingsScreen> createState() => _VisualizerSettingsScreenState();
}

class _VisualizerSettingsScreenState extends State<VisualizerSettingsScreen> {
  bool _forceTestMode = false;
  String _activePreset = 'classic';

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settings = context.watch<VisualizerSettingsProvider>();
    final isVisEnabled = audioProvider.showVisualizer;
    final primary = Theme.of(context).primaryColor;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(l10n.visualizer, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.visResetTooltip,
            onPressed: () {
              HapticFeedback.mediumImpact();
              settings.reset();
              setState(() => _activePreset = 'classic');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.visResetSuccess), duration: const Duration(seconds: 2)),
              );
            },
          ),
          Switch(
            value: isVisEnabled,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              audioProvider.toggleVisualizer();
            },
            activeColor: primary,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 6.0),
            child: VisualizerLivePreviewCard(
              audioProvider: audioProvider,
              settings: settings,
              forceTestMode: _forceTestMode,
              onToggleTestMode: (val) => setState(() => _forceTestMode = val),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              children: [
                _buildSectionHeader(context, l10n.visQuickPresets, Icons.auto_awesome),
                const SizedBox(height: 10),
                VisualizerPresetsRow(
                  settings: settings,
                  activePreset: _activePreset,
                  onSelectPreset: (preset) => setState(() => _activePreset = preset),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.visStyles, Icons.palette_outlined),
                const SizedBox(height: 12),
                VisualizerStylesGrid(
                  settings: settings,
                  onStyleChanged: () => setState(() => _activePreset = 'custom'),
                ),
                const SizedBox(height: 24),
                VisualizerAppearanceCard(settings: settings),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.visCore, Icons.memory),
                const SizedBox(height: 12),
                VisualizerCoreSelector(settings: settings),
                const SizedBox(height: 24),
                _buildSectionHeader(context, l10n.visPhysicsParams, Icons.tune),
                const SizedBox(height: 12),
                VisualizerSlidersCard(
                  settings: settings,
                  onValuesChanged: () => setState(() => _activePreset = 'custom'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ],
    );
  }
}
