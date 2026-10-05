import 'package:flutter/foundation.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/lyrics_service.dart';

mixin LyricsManagerMixin on ChangeNotifier {
  final LyricsService _lyricsService = LyricsService();
  
  Map<String, String>? _availableLyrics;
  String? _selectedLyricsKey;
  bool _isLyricsLoading = false;
  String? _lyricsErrorMsg;

  Map<String, String>? get availableLyrics => _availableLyrics;
  String? get selectedLyricsKey => _selectedLyricsKey;
  String? get currentLyrics => _selectedLyricsKey != null && _availableLyrics != null ? _availableLyrics![_selectedLyricsKey!] : null;
  bool get isLyricsLoading => _isLyricsLoading;
  String? get lyricsErrorMsg => _lyricsErrorMsg;
  bool get hasKaraokeLyrics {
    final lyrics = currentLyrics;
    if (lyrics == null || lyrics.isEmpty) return false;
    return RegExp(r'\[\d+:\d+').hasMatch(lyrics);
  }

  void resetLyricsState() {
    _availableLyrics = null;
    _selectedLyricsKey = null;
    _lyricsErrorMsg = null;
    _isLyricsLoading = true;
  }

  void loadLyricsForSong(SongModel song, SongModel? Function() getCurrentSong) {
    _lyricsService.getLyrics(
      song,
      onUpdate: (freshLyrics) async {
        if (getCurrentSong()?.id == song.id) {
          _availableLyrics = freshLyrics;
          await _selectBestTrack(song.id, freshLyrics);
          notifyListeners();
        }
      },
    ).then((lyricsMap) async {
      if (getCurrentSong()?.id == song.id) {
        _isLyricsLoading = false;
        if (lyricsMap != null && lyricsMap.isNotEmpty) {
          _availableLyrics = lyricsMap;
          await _selectBestTrack(song.id, lyricsMap);
        }
        notifyListeners();
      }
    }).catchError((e) {
      if (getCurrentSong()?.id == song.id) {
        _isLyricsLoading = false;
        if (e.toString().contains('SocketException')) {
          _lyricsErrorMsg = 'Немає підключення до інтернету.';
        } else {
          _lyricsErrorMsg = 'Помилка завантаження тексту.';
        }
        notifyListeners();
      }
    });
  }

  Future<void> _selectBestTrack(String songId, Map<String, String> map) async {
    final savedKey = await _lyricsService.getPreferredLyricsKey(songId);
    if (savedKey != null && map.containsKey(savedKey)) {
      _selectedLyricsKey = savedKey;
      return;
    }
    // Prefer synchronized karaoke track if available
    final karaokeKey = map.keys.firstWhere(
      (k) => k.contains('Караоке'),
      orElse: () => map.keys.first,
    );
    _selectedLyricsKey = karaokeKey;
  }

  void changeLyricsTrack(String key, {String? songId}) {
    if (_availableLyrics != null && _availableLyrics!.containsKey(key)) {
      _selectedLyricsKey = key;
      if (songId != null) {
        _lyricsService.savePreferredLyricsKey(songId, key);
      }
      notifyListeners();
    }
  }

  Future<void> setCustomLyrics(SongModel song, String label, String text) async {
    final updated = Map<String, String>.from(_availableLyrics ?? {});
    updated[label] = text;
    _availableLyrics = updated;
    _selectedLyricsKey = label;
    await _lyricsService.saveCustomLyrics(song, label, text);
    notifyListeners();
  }
}
