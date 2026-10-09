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
      if (line.isEmpty) continue;

      // Ігноруємо заголовки markdown (#, ##, ###)
      if (line.startsWith('#')) continue;

      // Ігноруємо SHA-256 та контрольні суми
      final lower = line.toLowerCase();
      if (lower.contains('sha-256') || lower.contains('sha256') || lower.contains('md5:')) {
        continue;
      }

      // Ігноруємо службові підзаголовки
      final headerCheck = line
          .replaceAll('*', '')
          .replaceAll('_', '')
          .replaceAll('`', '')
          .replaceAll('#', '')
          .trim()
          .toLowerCase();
      if (headerCheck.startsWith('зміни у цій версії') ||
          headerCheck.startsWith('оновлення musicflow') ||
          headerCheck.startsWith('changelog') ||
          headerCheck.startsWith('що нового') ||
          headerCheck == 'зміни:' ||
          headerCheck == 'changes:') {
        continue;
      }

      // Знімаємо маркер списку на початку (*, -, •, +, 1.)
      var cleaned = line.replaceFirst(RegExp(r'^([•\-\*\+]|\d+[\.\)])\s*'), '').trim();

      // Знімаємо всі залишки markdown: **, __, `, залишки зірочок на краях
      cleaned = cleaned
          .replaceAll('**', '')
          .replaceAll('__', '')
          .replaceAll('`', '')
          .replaceAll(RegExp(r'^\*+|\*+$'), '')
          .trim();

      if (cleaned.isNotEmpty) {
        result.add(cleaned);
      }
    }

    if (result.isEmpty) {
      return const ['Покращення стабільності та оптимізація додатку'];
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final missed = info.missedReleases;

    if (missed.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Що нового ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('пропущено ${missed.length} оновлень', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: missed.map((rel) => _buildReleaseBlock(rel, primary)).toList(),
              ),
            ),
          ),
        ],
      );
    }

    final items = _parseChangelog(info.changelog);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Що нового в цій версії:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70)),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 180),
          child: SingleChildScrollView(
            child: Column(
              children: items.map((item) => _buildBulletItem(item, primary)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReleaseBlock(ReleaseHistoryItem release, Color primary) {
    final items = _parseChangelog(release.changelog);
    final isLatest = release.buildNumber == info.buildNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLatest ? primary.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLatest ? primary.withValues(alpha: 0.25) : Colors.white12,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('v${release.version}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isLatest ? primary : Colors.white)),
              ),
              if (isLatest) ...[
                const SizedBox(width: 6),
                const Text('🔥 найновіша', style: TextStyle(fontSize: 10, color: Colors.amberAccent, fontWeight: FontWeight.w500)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) => _buildBulletItem(item, primary)),
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
