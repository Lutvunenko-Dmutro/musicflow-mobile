import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';

class _WordSpan {
  final double timeSec;
  final String text;
  _WordSpan(this.timeSec, this.text);
}

class _LyricsLine {
  final double timeSec;
  final String text;
  final List<_WordSpan> spans;

  _LyricsLine(this.timeSec, this.text, [this.spans = const []]);
}

class InlineLyrics extends StatefulWidget {
  const InlineLyrics({super.key});

  @override
  State<InlineLyrics> createState() => _InlineLyricsState();
}

class _InlineLyricsState extends State<InlineLyrics> {
  List<_LyricsLine> _lines = [];
  bool _isKaraoke = false;
  String? _lastParsedLyrics;
  
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  int _lastActiveIndex = -1;

  void _parseLyricsStr(String? lyricsText) {
    if (lyricsText == null || lyricsText.isEmpty) {
      if (_lines.isNotEmpty) {
        setState(() {
          _lines = [];
          _isKaraoke = false;
          _lastActiveIndex = -1;
          _keys.clear();
        });
      }
      return;
    }

    final parsedLines = <_LyricsLine>[];
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
          final spans = <_WordSpan>[];
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
                  if (word.isNotEmpty) spans.add(_WordSpan(currentSpanTime, word));
               } else {
                  spans.add(_WordSpan(currentSpanTime, part));
               }
            }
          }
          parsedLines.add(_LyricsLine(minutes * 60 + seconds, plainText.trim(), spans));
        }
      } else if (line.trim().isNotEmpty) {
        parsedLines.add(_LyricsLine(-1, line.trim()));
      }
    }

    setState(() {
      _lines = parsedLines;
      _isKaraoke = hasTimeTags;
      _lastActiveIndex = -1;
      _keys.clear();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    
    if (_lastParsedLyrics != audioProvider.currentLyrics) {
      _lastParsedLyrics = audioProvider.currentLyrics;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parseLyricsStr(_lastParsedLyrics);
      });
    }

    if (!_isKaraoke || _lines.isEmpty) {
      return const SizedBox(height: 90); // Empty space placeholder
    }

    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      builder: (context, snapshot) {
        double currentSec = 0.0;
        if (snapshot.hasData) {
          currentSec = snapshot.data!.inMilliseconds / 1000.0;
        }

        int activeIndex = -1;
        for (int i = 0; i < _lines.length; i++) {
          if (_lines[i].timeSec >= 0 && currentSec >= _lines[i].timeSec) {
            activeIndex = i;
          } else if (_lines[i].timeSec > currentSec) {
            break;
          }
        }

        if (activeIndex == -1 && _lines.isNotEmpty && _lines[0].timeSec > currentSec) {
           activeIndex = 0;
        } else if (activeIndex == -1) {
           return const SizedBox(height: 90);
        }

        if (activeIndex != _lastActiveIndex && activeIndex != -1) {
          _lastActiveIndex = activeIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final key = _keys[activeIndex];
              final context = key?.currentContext;
              if (context != null) {
                Scrollable.ensureVisible(
                  context,
                  alignment: 0.5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              }
            }
          });
        }

        return SizedBox(
          height: 90,
          width: double.infinity,
          child: ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 45), // Pad so first/last items can be centered in 90px
              itemCount: _lines.length,
              cacheExtent: 3000, // Pre-build items so keys have contexts
              itemBuilder: (context, index) {
                final line = _lines[index];
                final isCurrent = index == activeIndex;
                
                // Ensure key exists
                _keys[index] ??= GlobalKey();
                
                Widget lineContent;
                if (isCurrent && line.spans.isNotEmpty) {
                  lineContent = RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: line.spans.map((span) {
                        final isWordSung = currentSec >= span.timeSec;
                        return TextSpan(
                          text: span.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isWordSung ? Theme.of(context).primaryColor : Colors.white.withValues(alpha: 0.6),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                } else {
                  lineContent = Text(
                    line.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCurrent ? 18 : 14,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent 
                          ? Theme.of(context).primaryColor 
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  );
                }

                // Add AnimatedDefaultTextStyle implicitly for smooth font size transitions
                return Container(
                  key: _keys[index],
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: lineContent,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
