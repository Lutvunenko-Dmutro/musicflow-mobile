import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';
import 'package:music_flow_mobile/utils/lyrics_parser.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_list_view.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  List<LyricsLine> _lines = [];
  bool _isKaraoke = false;
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
    final result = LyricsParser.parse(lyricsText);
    setState(() {
      _lines = result.lines;
      _isKaraoke = result.isKaraoke;
    });
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
          if (song != null)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Знайти інше караоке',
              onPressed: () => LyricsSearchSheet.show(context, song: song),
            ),
          if (audioProvider.availableLyrics != null && audioProvider.availableLyrics!.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.translate),
              tooltip: 'Вибрати версію тексту',
              onSelected: (key) {
                audioProvider.changeLyricsTrack(key, songId: song?.id);
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
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Завантаження караоке та тексту...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                )
              : audioProvider.currentLyrics == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lyrics_outlined, size: 48, color: Colors.white24),
                          const SizedBox(height: 12),
                          Text(
                            audioProvider.lyricsErrorMsg ?? 'Текст пісні не знайдено',
                            style: const TextStyle(color: Colors.white54, fontSize: 15),
                          ),
                          if (song != null) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => LyricsSearchSheet.show(context, song: song),
                              icon: const Icon(Icons.search, size: 16),
                              label: const Text('Знайти караоке в базі'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                foregroundColor: Theme.of(context).primaryColor,
                                elevation: 0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : StreamBuilder<Duration>(
                  stream: audioProvider.positionStream,
                  builder: (context, snapshot) {
                    double currentSec = 0.0;
                    if (snapshot.hasData) {
                      currentSec = snapshot.data!.inMilliseconds / 1000.0;
                    }
                    
                    return LyricsListView(
                      lines: _lines,
                      isKaraoke: _isKaraoke,
                      currentSec: currentSec,
                    );
                  },
                ),
        ),
      ),
    );
  }
}
