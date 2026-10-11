import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_flow_mobile/l10n/app_language.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';
import 'package:music_flow_mobile/providers/language_provider.dart';

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const LanguageSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final strings = context.l10n;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final current = languageProvider.currentLanguage;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.translate, color: primary, size: 22),
              const SizedBox(width: 10),
              Text(
                strings.selectLanguage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...AppLanguage.values.map((lang) {
            final isSelected = lang == current;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? primary : Colors.white10,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Text(
                  lang.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(
                  lang.title,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                subtitle: Text(
                  lang.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? primary.withValues(alpha: 0.8) : Colors.white38,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: primary, size: 22)
                    : const Icon(Icons.circle_outlined, color: Colors.white24, size: 22),
                onTap: () {
                  languageProvider.setLanguage(lang);
                  Navigator.of(context).pop();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
