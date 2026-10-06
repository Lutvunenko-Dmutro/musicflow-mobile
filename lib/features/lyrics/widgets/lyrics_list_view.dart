import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_line_tile.dart';

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
  void initState() {
    super.initState();
    if (widget.isKaraoke) {
      _updateActiveIndex(scroll: false);
    }
  }

  @override
  void didUpdateWidget(covariant LyricsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isKaraoke) {
      _updateActiveIndex(scroll: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateActiveIndex({bool scroll = true}) {
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
      if (scroll) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveIndex(_activeIndex);
        });
      }
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
        duration: const Duration(milliseconds: 450),
        curve: kLyricMotionCurve,
      );
    }
  }

  void _seekToLine(LyricsLine line) {
    if (line.timeSec >= 0) {
      HapticFeedback.lightImpact();
      context.read<AudioProvider>().seek(
        Duration(milliseconds: (line.timeSec * 1000).toInt()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: MediaQuery.of(context).size.height / 2.6,
      ),
      cacheExtent: 3000,
      itemCount: widget.lines.length,
      itemBuilder: (context, index) {
        final line = widget.lines[index];
        final isActive = widget.isKaraoke && index == _activeIndex;
        final distance = _activeIndex >= 0 ? (index - _activeIndex).abs() : 99;

        _keys[index] ??= GlobalKey();

        return Container(
          key: _keys[index],
          child: Column(
            children: [
              LyricsLineTile(
                line: line,
                isActive: isActive,
                distanceToActive: distance,
                currentSec: widget.currentSec,
                onTap: () => _seekToLine(line),
              ),
              if (_hasLongPause(index)) _buildPauseDots(),
            ],
          ),
        );
      },
    );
  }

  bool _hasLongPause(int index) {
    if (!widget.isKaraoke || index >= widget.lines.length - 1) return false;
    final currentLine = widget.lines[index];
    final nextLine = widget.lines[index + 1];

    double currentEndTime = currentLine.timeSec;
    if (currentLine.spans.isNotEmpty) {
      currentEndTime = currentLine.spans.last.timeSec;
    }
    return (nextLine.timeSec - currentEndTime) > 8.0;
  }

  Widget _buildPauseDots() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _dot(4),
          const SizedBox(width: 10),
          _dot(6),
          const SizedBox(width: 10),
          _dot(4),
        ],
      ),
    );
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}
