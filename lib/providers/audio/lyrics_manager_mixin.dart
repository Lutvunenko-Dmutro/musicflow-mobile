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

  void resetLyricsState() {
    _availableLyrics = null;
    _selectedLyricsKey = null;
    _lyricsErrorMsg = null;
    _isLyricsLoading = true;
  }

  void loadLyricsForSong(SongModel song, SongModel? Function() getCurrentSong) {
    _lyricsService.getLyrics(
      song,
      onUpdate: (freshLyrics) {
        if (getCurrentSong()?.id == song.id) {
          _availableLyrics = freshLyrics;
          if (_selectedLyricsKey == null || !freshLyrics.containsKey(_selectedLyricsKey)) {
            _selectedLyricsKey = freshLyrics.keys.first;
          }
          notifyListeners();
        }
      },
    ).then((lyricsMap) {
      if (getCurrentSong()?.id == song.id) {
        _isLyricsLoading = false;
        if (lyricsMap != null && lyricsMap.isNotEmpty) {
          _availableLyrics = lyricsMap;
          if (_selectedLyricsKey == null || !lyricsMap.containsKey(_selectedLyricsKey)) {
            _selectedLyricsKey = lyricsMap.keys.first;
          }
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

  void changeLyricsTrack(String key) {
    if (_availableLyrics != null && _availableLyrics!.containsKey(key)) {
      _selectedLyricsKey = key;
      notifyListeners();
    }
  }
}
