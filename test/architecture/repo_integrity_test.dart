import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Repository & CI/CD Integrity Checks', () {
    test('all GitHub Actions workflow YAML files have valid syntax and structure', () {
      final workflowsDir = Directory('.github/workflows');
      expect(workflowsDir.existsSync(), isTrue, reason: '.github/workflows directory should exist');

      final yamlFiles = workflowsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'));

      expect(yamlFiles, isNotEmpty, reason: 'At least one workflow file should exist');

      for (final file in yamlFiles) {
        final content = file.readAsStringSync();
        dynamic parsed;
        try {
          parsed = loadYaml(content);
        } catch (e) {
          fail('Syntax error in workflow file ${file.path}:\n$e');
        }

        expect(parsed, isA<YamlMap>(), reason: '${file.path} should contain a YAML map');
        final map = parsed as YamlMap;

        expect(map.containsKey('name'), isTrue, reason: '${file.path} must have a name');
        expect(map.containsKey('jobs'), isTrue, reason: '${file.path} must have a jobs block');
        expect(map.containsKey('on') || map.containsKey(true), isTrue,
            reason: '${file.path} must have an on: trigger block');
      }
    });

    test('all local markdown links in README.md and docs/README.md are valid and exist', () {
      final readmes = [
        File('README.md'),
        File('docs/README.md'),
      ];

      final brokenLinks = <String>[];
      final linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

      for (final readme in readmes) {
        if (!readme.existsSync()) continue;
        final baseDir = readme.parent;
        final content = readme.readAsStringSync();

        for (final match in linkRegex.allMatches(content)) {
          final url = match.group(2) ?? '';
          if (url.startsWith('http://') ||
              url.startsWith('https://') ||
              url.startsWith('#') ||
              url.startsWith('mailto:')) {
            continue;
          }

          final cleanUrl = url.split('#').first.trim();
          if (cleanUrl.isEmpty) continue;

          final targetFile = File('${baseDir.path}/$cleanUrl');
          final targetDir = Directory('${baseDir.path}/$cleanUrl');

          if (!targetFile.existsSync() && !targetDir.existsSync()) {
            brokenLinks.add('${readme.path}: [${match.group(1)}]($url) -> file does not exist');
          }
        }
      }

      expect(
        brokenLinks,
        isEmpty,
        reason: 'Found broken markdown links:\n${brokenLinks.join('\n')}',
      );
    });

    test('root pubspec.yaml and analysis_options.yaml have valid YAML syntax', () {
      final configFiles = [
        File('pubspec.yaml'),
        File('analysis_options.yaml'),
      ];

      for (final file in configFiles) {
        expect(file.existsSync(), isTrue, reason: '${file.path} must exist');
        try {
          final parsed = loadYaml(file.readAsStringSync());
          expect(parsed, isA<YamlMap>(), reason: '${file.path} must be a valid YAML map');
        } catch (e) {
          fail('Syntax error in ${file.path}:\n$e');
        }
      }
    });
  });
}
