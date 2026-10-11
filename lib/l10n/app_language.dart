enum AppLanguage {
  uk(
    code: 'uk',
    title: 'Українська',
    subtitle: 'Ukrainian',
    flag: '🇺🇦',
  ),
  en(
    code: 'en',
    title: 'English',
    subtitle: 'Англійська',
    flag: '🇬🇧',
  );

  final String code;
  final String title;
  final String subtitle;
  final String flag;

  const AppLanguage({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.flag,
  });

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.uk;
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code.toLowerCase().trim(),
      orElse: () => AppLanguage.uk,
    );
  }
}
