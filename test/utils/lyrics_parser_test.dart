import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/utils/lyrics_parser.dart';

void main() {
  group('LyricsParser Unit Tests', () {
    test('Returns empty result when input is null or blank', () {
      final nullResult = LyricsParser.parse(null);
      expect(nullResult.lines, isEmpty);
      expect(nullResult.isKaraoke, isFalse);

      final emptyResult = LyricsParser.parse('   \n  \n');
      expect(emptyResult.lines, isEmpty);
      expect(emptyResult.isKaraoke, isFalse);
    });

    test('Parses plain text lyrics without time tags', () {
      const text = '''
First line of the song
Second line of the song
Third line of the song
''';

      final result = LyricsParser.parse(text);
      expect(result.isKaraoke, isFalse);
      expect(result.lines.length, equals(3));
      expect(result.lines[0].text, equals('First line of the song'));
      expect(result.lines[0].timeSec, equals(-1));
      expect(result.lines[1].text, equals('Second line of the song'));
    });

    test('Parses standard synchronized LRC format with timestamps', () {
      const lrc = '''
[00:12.50] Hello darkness, my old friend
[01:05.10] I've come to talk with you again
[02:30.00] Because a vision softly creeping
''';

      final result = LyricsParser.parse(lrc);
      expect(result.isKaraoke, isTrue);
      expect(result.lines.length, equals(3));

      expect(result.lines[0].timeSec, closeTo(12.5, 0.001));
      expect(result.lines[0].text, equals('Hello darkness, my old friend'));

      expect(result.lines[1].timeSec, closeTo(65.1, 0.001));
      expect(result.lines[1].text, equals("I've come to talk with you again"));

      expect(result.lines[2].timeSec, closeTo(150.0, 0.001));
      expect(result.lines[2].text, equals('Because a vision softly creeping'));
    });

    test('Parses enhanced word-by-word karaoke tags within synchronized line', () {
      const karaokeLrc = '''
[00:15.00] <00:15.00>Never <00:15.50>gonna <00:16.00>give <00:16.50>you <00:17.00>up
''';

      final result = LyricsParser.parse(karaokeLrc);
      expect(result.isKaraoke, isTrue);
      expect(result.lines.length, equals(1));

      final line = result.lines.first;
      expect(line.timeSec, closeTo(15.0, 0.001));
      expect(line.text, equals('Never gonna give you up'));
      expect(line.spans.isNotEmpty, isTrue);
      expect(line.spans.first.text.trim(), equals('Never'));
      expect(line.spans.first.timeSec, closeTo(15.0, 0.001));
    });
  });
}
