import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/providers/audio_provider.dart';
import 'package:music_flow_mobile/models/lyrics_line.dart';
import 'package:music_flow_mobile/utils/lyrics_parser.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_list_view.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_search_sheet.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_version_menu.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_empty_views.dart';
import 'package:music_flow_mobile/features/lyrics/widgets/lyrics_source_banner.dart';

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
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final song = audioProvider.currentSong;

    if (_lastParsedLyrics != audioProvider.currentLyrics) {
      _lastParsedLyrics = audioProvider.currentLyrics;
      final result = LyricsParser.parse(_lastParsedLyrics);
      _lines = result.lines;
      _isKaraoke = result.isKaraoke;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              song?.title ?? 'Текст пісні',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (song != null)
              Text(
                song.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
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
          LyricsVersionMenu(audioProvider: audioProvider, song: song),
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
          child: Column(
            children: [
              if (audioProvider.currentLyrics != null && !audioProvider.isLyricsDisabledForCurrentSong)
                LyricsSourceBanner(provider: audioProvider, song: song, isKaraoke: _isKaraoke),
              Expanded(
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
                            const Text(
                              'Завантаження караоке та тексту...',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : audioProvider.isLyricsDisabledForCurrentSong
                        ? LyricsDisabledView(song: song, onEnable: () => audioProvider.enableLyricsForSong(song!.id))
                        : audioProvider.currentLyrics == null
                            ? LyricsEmptyView(song: song, errorMsg: audioProvider.lyricsErrorMsg)
                            : StreamBuilder<Duration>(
                                stream: audioProvider.positionStream,
                                builder: (context, snapshot) {
                                  final currentSec = (snapshot.data?.inMilliseconds ?? 0) / 1000.0;
                                  return LyricsListView(
                                    lines: _lines,
                                    isKaraoke: _isKaraoke,
                                    currentSec: currentSec,
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
