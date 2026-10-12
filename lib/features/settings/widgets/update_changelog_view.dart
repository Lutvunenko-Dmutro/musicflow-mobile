import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/release_history_item.dart';
import 'package:music_flow_mobile/services/update_service.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class UpdateChangelogView extends StatelessWidget {
  final UpdateInfo info;

  const UpdateChangelogView({super.key, required this.info});

  List<String> _parseChangelog(String text, AppStrings l10n) {
    final lines = text.split('\n');
    final result = <String>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final lower = line.toLowerCase();
      if (lower.contains('sha-256') || lower.contains('sha256') || lower.contains('md5:')) continue;

      var cleaned = line.replaceFirst(RegExp(r'^([•\-\*\+]|\d+[\.\)])\s*'), '').trim();
      cleaned = cleaned.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '').replaceAll(RegExp(r'^\*+|\*+$'), '').trim();

      // Skip section headers (e.g. "Features:", "Зміни:", "Changelog")
      if (cleaned.endsWith(':') || cleaned.toLowerCase() == 'changelog') {
        continue;
      }

      if (cleaned.isNotEmpty) result.add(cleaned);
    }

    return result.isEmpty ? [l10n.defaultChangelogFallback] : result;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final l10n = context.l10n;
    final missed = info.missedReleases;
    final currentItems = _parseChangelog(info.changelog, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(l10n.whatsNewInVersion(info.version), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
            if (missed.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(l10n.missedReleasesCount(missed.length), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...currentItems.map((item) => _buildBulletItem(item, primary)),
                if (missed.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(l10n.missedChanges, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  const SizedBox(height: 6),
                  ...missed.map((rel) => _buildReleaseBlock(rel, primary, l10n)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseBlock(ReleaseHistoryItem release, Color primary, AppStrings l10n) {
    final items = _parseChangelog(release.changelog, l10n);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(5)),
                child: Text('v${release.version}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              ),
              if (release.releaseDate.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(release.releaseDate, style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) => _buildBulletItem(item, Colors.amberAccent)),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String item, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: primary),
          const SizedBox(width: 8),
          Expanded(child: Text(item, style: const TextStyle(fontSize: 12, height: 1.3, color: Colors.white))),
        ],
      ),
    );
  }
}
