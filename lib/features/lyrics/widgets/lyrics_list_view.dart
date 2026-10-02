import 'package:flutter/material.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';

class LyricsListView extends StatefulWidget {
  final List<LyricsLine> lines;
  final bool isKaraoke;
  final double currentSec;

  const LyricsListView({
    super.key,
    required this.lines,
    required this.isKaraoke,
    required this.currentSec,
  });

  @override
  State<LyricsListView> createState() => _LyricsListViewState();
}

class _LyricsListViewState extends State<LyricsListView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _keys = {};
  int _activeIndex = -1;

  @override
  void didUpdateWidget(covariant LyricsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isKaraoke) {
      _updateActiveIndex();
    }
  }

  void _updateActiveIndex() {
    int newActiveIndex = -1;
    for (int i = 0; i < widget.lines.length; i++) {
      if (widget.lines[i].timeSec >= 0 && widget.currentSec >= widget.lines[i].timeSec) {
        newActiveIndex = i;
      } else if (widget.lines[i].timeSec > widget.currentSec) {
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

  void _scrollToActiveIndex(int index) {
    if (!_scrollController.hasClients || index < 0 || index >= widget.lines.length) return;
    
    final key = _keys[index];
    final keyContext = key?.currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: 24, 
        vertical: MediaQuery.of(context).size.height / 2.5
      ),
      cacheExtent: 3000,
      itemCount: widget.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lines[index];
        final isActive = widget.isKaraoke && index == _activeIndex;
        
        _keys[index] ??= GlobalKey();
        
        Widget lineContent;
        if (line.spans.isNotEmpty && isActive) {
          lineContent = RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: line.spans.map((span) {
                final isWordSung = widget.currentSec >= span.timeSec;
                return TextSpan(
                  text: span.text,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isWordSung 
                      ? Theme.of(context).primaryColor 
                      : Colors.white.withValues(alpha: 0.6),
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
              fontSize: isActive ? 26 : 18,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive 
                ? Theme.of(context).primaryColor 
                : Colors.white.withValues(alpha: 0.3),
            ),
          );
        }

        bool hasLongPause = false;
        if (widget.isKaraoke && index < widget.lines.length - 1) {
          final nextLine = widget.lines[index + 1];
          double currentLineEndTime = line.timeSec;
          
          if (line.spans.isNotEmpty) {
            currentLineEndTime = line.spans.last.timeSec;
          }
          
          if (nextLine.timeSec - currentLineEndTime > 8.0) {
            hasLongPause = true;
          }
        }

        return Container(
          key: _keys[index],
          child: Column(
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
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
