import 'package:flutter/foundation.dart';
import 'package:music_flow_mobile/models/song_model.dart';
import 'package:music_flow_mobile/services/lyrics_service.dart';
import 'package:music_flow_mobile/utils/app_logger.dart';

mixin LyricsManagerMixin on ChangeNotifier {
  static const String disabledLyricsKey = '__disabled__';

  final LyricsService _lyricsService = LyricsService();
  
  Map<String, String>? _availableLyrics;
  String? _selectedLyricsKey;
  bool _isLyricsLoading = false;
  String? _lyricsErrorMsg;

  Map<String, String>? get availableLyrics => _availableLyrics;
  String? get selectedLyricsKey => _selectedLyricsKey;
  bool get isLyricsDisabledForCurrentSong => _selectedLyricsKey == disabledLyricsKey;

  String? get currentLyrics {
    if (_selectedLyricsKey == null || _selectedLyricsKey == disabledLyricsKey || _availableLyrics == null) {
      return null;
    }
    return _availableLyrics![_selectedLyricsKey!];
  }

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
    AppLogger.info('Пошук караоке для: "${song.title}" (${song.author})', 'LYRICS');
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
          AppLogger.success('Знайдено варіанти: [${lyricsMap.keys.join(", ")}] | Обрано: "$_selectedLyricsKey"', 'LYRICS');
        } else {
          AppLogger.warning('Караоке для "${song.title}" не знайдено', 'LYRICS');
        }
        notifyListeners();
      }
    }).catchError((e) {
      if (getCurrentSong()?.id == song.id) {
        _isLyricsLoading = false;
        AppLogger.error('Помилка караоке для "${song.title}": $e', e, null, 'LYRICS');
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
    if (savedKey == disabledLyricsKey) {
      _selectedLyricsKey = disabledLyricsKey;
      return;
    }
    final karaokeKey = map.keys.firstWhere((k) => k.contains('Караоке'), orElse: () => '');
    if (savedKey != null && map.containsKey(savedKey)) {
      if (karaokeKey.isNotEmpty && !savedKey.contains('Караоке')) {
        _selectedLyricsKey = karaokeKey;
        return;
      }
      _selectedLyricsKey = savedKey;
      return;
    }
    _selectedLyricsKey = karaokeKey.isNotEmpty ? karaokeKey : map.keys.first;
  }

  void changeLyricsTrack(String key, {String? songId}) {
    if (key == disabledLyricsKey || (_availableLyrics != null && _availableLyrics!.containsKey(key))) {
      _selectedLyricsKey = key;
      if (songId != null) {
        _lyricsService.savePreferredLyricsKey(songId, key);
      }
      notifyListeners();
    }
  }

  void disableLyricsForSong(String songId) {
    changeLyricsTrack(disabledLyricsKey, songId: songId);
  }

  void enableLyricsForSong(String songId) {
    if (_availableLyrics != null && _availableLyrics!.isNotEmpty) {
      final karaokeKey = _availableLyrics!.keys.firstWhere(
        (k) => k.contains('Караоке'),
        orElse: () => _availableLyrics!.keys.first,
      );
      changeLyricsTrack(karaokeKey, songId: songId);
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

  Future<void> removeLyricsTrack(SongModel song, String key) async {
    await _lyricsService.removeCustomLyrics(song.id, key);
    if (_availableLyrics != null) {
      final updated = Map<String, String>.from(_availableLyrics!);
      updated.remove(key);
      if (updated.isEmpty) {
        resetLyricsState();
        notifyListeners();
        loadLyricsForSong(song, () => song);
      } else {
        _availableLyrics = updated;
        if (_selectedLyricsKey == key) {
          _selectedLyricsKey = updated.keys.first;
          await _lyricsService.savePreferredLyricsKey(song.id, _selectedLyricsKey!);
        }
        notifyListeners();
      }
    }
  }

  Future<void> resetAllLyricsForSong(SongModel song) async {
    await _lyricsService.resetAllLyrics(song.id);
    resetLyricsState();
    notifyListeners();
    loadLyricsForSong(song, () => song);
  }
}
