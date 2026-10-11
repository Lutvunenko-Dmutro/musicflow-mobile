import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/release_history_item.dart';
import 'package:music_flow_mobile/services/update_service.dart';

class UpdateChangelogView extends StatelessWidget {
  final UpdateInfo info;

  const UpdateChangelogView({super.key, required this.info});

  List<String> _parseChangelog(String text) {
    final lines = text.split('\n');
    final result = <String>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;

      final lower = line.toLowerCase();
      if (lower.contains('sha-256') || lower.contains('sha256') || lower.contains('md5:')) continue;

      final header = line.replaceAll(RegExp(r'[\*\_`#]'), '').trim().toLowerCase();
      if (header.startsWith('зміни у цій версії') ||
          header.startsWith('оновлення musicflow') ||
          header.startsWith('changelog') ||
          header.startsWith('що нового') ||
          header == 'зміни:' ||
          header == 'changes:') {
        continue;
      }

      var cleaned = line.replaceFirst(RegExp(r'^([•\-\*\+]|\d+[\.\)])\s*'), '').trim();
      cleaned = cleaned.replaceAll('**', '').replaceAll('__', '').replaceAll('`', '').replaceAll(RegExp(r'^\*+|\*+$'), '').trim();

      if (cleaned.isNotEmpty) result.add(cleaned);
    }

    return result.isEmpty ? const ['Покращення стабільності та оптимізація додатку'] : result;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final missed = info.missedReleases;
    final currentItems = _parseChangelog(info.changelog);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Що нового у v${info.version}:', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
            if (missed.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('пропущено ${missed.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
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
                  const Text('Пропущені зміни:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                  const SizedBox(height: 6),
                  ...missed.map((rel) => _buildReleaseBlock(rel, primary)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseBlock(ReleaseHistoryItem release, Color primary) {
    final items = _parseChangelog(release.changelog);

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
