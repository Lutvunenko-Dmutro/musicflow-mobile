class MusicSearchFilter {
  static const List<String> _blacklist = [
    'інтерв’ю',
    'інтерв\'ю',
    'интервью',
    'interview',
    'подкаст',
    'podcast',
    'вдудь',
    'гордеева',
    'гордон',
    'дьомін',
    'говорить',
    'розмова',
    'бесіда',
    'прямий ефір',
    'ток-шоу',
    'стрим',
    'стрім',
    'stream',
    'новини',
    'новости',
    'news',
    'розслідування',
    'расследование',
    'викриття',
    'разоблачение',
    'скандал',
    'тсн',
    'новини.live',
    'україна сьогодні',
    'zaxid.net',
    '24 канал',
    'рагулівна',
    'propaganda',
    'пропаганда',
    'крінж',
    'cringe',
    'реакция',
    'реакція',
    'reaction',
    'огляд',
    'обзор',
    'review',
    'розпаковка',
    'распаковка',
    'unboxing',
    'геймплей',
    'gameplay',
    'walkthrough',
    'проходження',
    'туториал',
    'tutorial',
    'how to',
    'як зробити',
    'урок',
    'лекція',
    'лекция',
    'влог',
    'vlog',
    'blog',
    'блог',
    'документальний',
    'документальный',
    'documentary',
    'фільм',
    'фильм',
    'movie',
    'film',
    'серія',
    'серия',
    'сезон',
    'season',
    'episode',
    'епізод',
    'випуск',
    'выпуск',
    '#shorts',
    '#short',
    'tiktok',
    'про те як',
    'про те,',
    'про то как',
    'вся правда',
    'шокуюч',
    'зізнання',
    'признание',
  ];

  static Duration parseDuration(String s) {
    final parts = s.split(':').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 1) {
      return Duration(seconds: parts[0]);
    }
    return Duration.zero;
  }

  static bool isMusic({
    required String title,
    required String author,
    required Duration duration,
    bool isLive = false,
  }) {
    if (isLive) return false;
    // Single tracks are usually between 40s and 15min
    if (duration.inMinutes > 15 || duration.inSeconds < 40) {
      return false;
    }

    final lowerTitle = title.toLowerCase();
    final lowerAuthor = author.toLowerCase();

    // YouTube Music auto-generated artist topic channels are always music
    if (lowerAuthor.endsWith('- topic')) {
      return true;
    }

    for (final word in _blacklist) {
      if (lowerTitle.contains(word) || lowerAuthor.contains(word)) {
        return false;
      }
    }

    return true;
  }
}
