import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import 'dart:math' as math;

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

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

class _LyricsScreenState extends State<LyricsScreen> {
  final ScrollController _scrollController = ScrollController();
  List<_LyricsLine> _lines = [];
  bool _isKaraoke = false;
  int _activeIndex = -1;

  String? _lastParsedLyrics;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _parseLyricsStr(String? lyricsText) {
    
    if (lyricsText == null || lyricsText.isEmpty) {
      if (_lines.isNotEmpty) {
        setState(() {
          _lines = [];
          _isKaraoke = false;
        });
      }
      return;
    }

    final parsedLines = <_LyricsLine>[];
    bool hasTimeTags = false;
    
    // Parse LRC format [mm:ss.xx] text
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
    });
  }

  void _scrollToActiveIndex(int index) {
    if (!_scrollController.hasClients || index < 0 || index >= _lines.length) return;
    
    // Try to keep the active line somewhat centered
    final screenHeight = MediaQuery.of(context).size.height;
    final itemHeight = 40.0; // approximate height per line
    
    final targetOffset = math.max(0.0, (index * itemHeight) - (screenHeight / 3));
    
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;
    
    if (_lastParsedLyrics != audioProvider.currentLyrics) {
      _lastParsedLyrics = audioProvider.currentLyrics;
      // Schedule parsing for next frame so we don't setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parseLyricsStr(_lastParsedLyrics);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(song?.title ?? 'Текст пісні', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (audioProvider.availableLyrics != null && audioProvider.availableLyrics!.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.translate),
              tooltip: 'Вибрати версію тексту',
              onSelected: (key) {
                audioProvider.changeLyricsTrack(key);
              },
              itemBuilder: (context) {
                return audioProvider.availableLyrics!.keys.map((key) {
                  final isSelected = key == audioProvider.selectedLyricsKey;
                  return PopupMenuItem<String>(
                    value: key,
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            key,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Theme.of(context).primaryColor : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.3),
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: audioProvider.isLyricsLoading 
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white54),
                )
              : audioProvider.currentLyrics == null
                  ? Center(
                      child: Text(
                        audioProvider.lyricsErrorMsg ?? 'Текст пісні не знайдено...',
                        style: const TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    )
                  : StreamBuilder<Duration>(
                  stream: audioProvider.positionStream,
                  builder: (context, snapshot) {
                    double currentSec = 0.0;
                    if (snapshot.hasData) {
                      currentSec = snapshot.data!.inMilliseconds / 1000.0;
                    }

                    if (_isKaraoke && snapshot.hasData) {
                      // Find active line
                      int newActiveIndex = -1;
                      for (int i = 0; i < _lines.length; i++) {
                        if (_lines[i].timeSec >= 0 && currentSec >= _lines[i].timeSec) {
                          newActiveIndex = i;
                        } else if (_lines[i].timeSec > currentSec) {
                          break;
                        }
                      }
                      
                      if (newActiveIndex != _activeIndex) {
                        _activeIndex = newActiveIndex;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToActiveIndex(_activeIndex);
                        });
                      }
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      itemCount: _lines.length,
                      itemBuilder: (context, index) {
                        final line = _lines[index];
                        final isActive = _isKaraoke && index == _activeIndex;
                        
                        Widget lineContent;
                        if (line.spans.isNotEmpty && isActive) {
                          lineContent = RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: line.spans.map((span) {
                                final isWordSung = currentSec >= span.timeSec;
                                return TextSpan(
                                  text: span.text,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isWordSung ? Colors.white : Colors.white.withValues(alpha: 0.4),
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
                              fontSize: isActive ? 22 : 18,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                            ),
                          );
                        }

                        // Check for instrumental pause (gap > 8 seconds after the last word starts)
                        bool hasLongPause = false;
                        if (_isKaraoke && index < _lines.length - 1) {
                          final nextLine = _lines[index + 1];
                          double currentLineEndTime = line.timeSec;
                          
                          if (line.spans.isNotEmpty) {
                            currentLineEndTime = line.spans.last.timeSec;
                          }
                          
                          if (nextLine.timeSec - currentLineEndTime > 8.0) {
                            hasLongPause = true;
                          }
                        }

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: lineContent,
                            ),
                            if (hasLongPause)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle)),
                                    const SizedBox(width: 12),
                                    Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle)),
                                    const SizedBox(width: 12),
                                    Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), shape: BoxShape.circle)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
