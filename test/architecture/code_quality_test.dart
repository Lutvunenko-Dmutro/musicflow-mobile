import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Code Quality & IDE Diagnostics', () {
    test('no production dart files in lib/ contain raw print calls', () {
      final dir = Directory('lib');
      expect(dir.existsSync(), isTrue, reason: 'lib directory should exist');

      final violations = <String>[];
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final normalizedPath = file.path.replaceAll('\\', '/');
        if (normalizedPath.endsWith('lib/utils/app_logger.dart')) continue;

        final lines = file.readAsLinesSync();
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.startsWith('//')) continue;
          if (RegExp(r'\bprint\s*\(').hasMatch(line)) {
            violations.add('$normalizedPath:${i + 1}: $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Found raw print() calls in production code. Use AppLogger instead:\n${violations.join('\n')}',
      );
    });

    test('dart analyzer reports zero issues or warnings in the project', () {
      final executable = Platform.isWindows ? 'dart' : 'dart';
      final result = Process.runSync(
        executable,
        const ['analyze', '--fatal-infos'],
        runInShell: true,
      );

      final stdout = result.stdout.toString();
      final stderr = result.stderr.toString();

      expect(
        result.exitCode,
        0,
        reason: 'Analyzer detected issues in the codebase:\n$stdout\n$stderr',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
