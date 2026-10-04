import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('File Length Checks', () {
    void verifyDirectoryFileLengths(String dirPath) {
      final dir = Directory(dirPath);
      expect(dir.existsSync(), isTrue, reason: '$dirPath directory should exist');

      final violations = <String>[];
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      for (final file in files) {
        final lines = file.readAsLinesSync();
        final lineCount = lines.length;
        if (lineCount >= 200) {
          violations.add('${file.path}: $lineCount lines (max allowed: < 200)');
        }
      }

      if (violations.isNotEmpty) {
        fail('Found ${violations.length} files in $dirPath exceeding 199 lines:\n${violations.join('\n')}');
      }
    }

    test('all dart files in lib/ should have less than 200 lines', () {
      verifyDirectoryFileLengths('lib');
    });

    test('all dart files in test/ should have less than 200 lines', () {
      verifyDirectoryFileLengths('test');
    });
  });
}
