class WordSpan {
  final double timeSec;
  final String text;
  WordSpan(this.timeSec, this.text);
}

class LyricsLine {
  final double timeSec;
  final String text;
  final List<WordSpan> spans;

  LyricsLine(this.timeSec, this.text, [this.spans = const []]);
}
