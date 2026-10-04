import 'package:flutter/material.dart';

class CacheItemRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String sizeText;
  final VoidCallback onClear;
  final String clearTooltip;
  final bool isZero;

  const CacheItemRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.sizeText,
    required this.onClear,
    required this.clearTooltip,
    required this.isZero,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Text(
          sizeText,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 20,
            color: isZero
                ? Colors.grey.withValues(alpha: 0.3)
                : Colors.redAccent.withValues(alpha: 0.8),
          ),
          tooltip: clearTooltip,
          onPressed: isZero ? null : onClear,
        ),
      ],
    );
  }
}
