import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';
import 'package:music_flow_mobile/utils/lyrics_parser.dart';

class InlineLyrics extends StatefulWidget {
  const InlineLyrics({super.key});

  @override
  State<InlineLyrics> createState() => _InlineLyricsState();
}

class _InlineLyricsState extends State<InlineLyrics> {
  List<LyricsLine> _lines = [];
  bool _isKaraoke = false;
  String? _lastParsedLyrics;
  
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  int _lastActiveIndex = -1;

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
      final result = LyricsParser.parse(_lastParsedLyrics);
      _lines = result.lines;
      _isKaraoke = result.isKaraoke;
      _lastActiveIndex = -1;
      _keys.clear();
    }

    if (!_isKaraoke || _lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      builder: (context, snapshot) {
        final currentSec = (snapshot.data?.inMilliseconds ?? 0) / 1000.0;

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
          return const SizedBox.shrink();
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
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
                stops: [0.0, 0.2, 0.8, 1.0],
              ).createShader(bounds);
            },
            blendMode: BlendMode.dstIn,
            child: ListView.builder(
              controller: _scrollController,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 45),
              itemCount: _lines.length,
              cacheExtent: 3000,
              itemBuilder: (context, index) {
                final line = _lines[index];
                final isCurrent = index == activeIndex;
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
                      color: isCurrent ? Theme.of(context).primaryColor : Colors.white.withValues(alpha: 0.3),
                    ),
                  );
                }

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
