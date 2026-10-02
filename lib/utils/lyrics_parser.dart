import 'package:music_flow_mobile/models/lyrics_line.dart';

class LyricsParserResult {
  final List<LyricsLine> lines;
  final bool isKaraoke;

  LyricsParserResult(this.lines, this.isKaraoke);
}

class LyricsParser {
  static LyricsParserResult parse(String? lyricsText) {
    if (lyricsText == null || lyricsText.isEmpty) {
      return LyricsParserResult([], false);
    }

    final parsedLines = <LyricsLine>[];
    bool hasTimeTags = false;
    
    final regex = RegExp(r'\[(\d+):(\d+\.?\d*)\]\s*(.*)');
    
    for (var line in lyricsText.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        hasTimeTags = true;
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final text = match.group(3) ?? '';
        
        if (text.trim().isNotEmpty) {
          final spans = <WordSpan>[];
          String plainText = text;
          
          if (text.contains('<') && text.contains('>')) {
            plainText = text.replaceAll(RegExp(r'<[^>]*>'), '');
            
            double currentSpanTime = minutes * 60 + seconds;
            final parts = text.split(RegExp(r'(?=<\d+:\d+\.?\d*>)'));
            
            for (var part in parts) {
               if (part.isEmpty) continue;
               final timeMatch = RegExp(r'^<(\d+):(\d+\.?\d*)>\s*').firstMatch(part);
               if (timeMatch != null) {
                  final m = int.parse(timeMatch.group(1)!);
                  final s = double.parse(timeMatch.group(2)!);
                  currentSpanTime = m * 60 + s;
                  final word = part.substring(timeMatch.end);
                  if (word.isNotEmpty) spans.add(WordSpan(currentSpanTime, word));
               } else {
                  spans.add(WordSpan(currentSpanTime, part));
               }
            }
          }
          
          parsedLines.add(LyricsLine(minutes * 60 + seconds, plainText.trim(), spans));
        }
      } else if (line.trim().isNotEmpty) {
        parsedLines.add(LyricsLine(-1, line.trim()));
      }
    }

    return LyricsParserResult(parsedLines, hasTimeTags);
  }
}
