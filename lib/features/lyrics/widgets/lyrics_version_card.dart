import 'package:flutter/material.dart';
import 'package:music_flow_mobile/core/app_colors.dart';

class LyricsVersionCard extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const LyricsVersionCard({
    super.key,
    required this.isSelected,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.06),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                child: Text(badge!, style: const TextStyle(fontSize: 10, color: Colors.white70)),
              ),
            ],
            const SizedBox(width: 8),
            Icon(isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked, size: 20, color: isSelected ? AppColors.primary : Colors.white24),
          ],
        ),
      ),
    );
  }
}
