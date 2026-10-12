import 'package:flutter/material.dart';
import 'package:music_flow_mobile/features/splash/services/permission_flow_service.dart';
import 'package:music_flow_mobile/l10n/app_strings.dart';

class PermissionCard extends StatelessWidget {
  final PermissionItemData item;
  final VoidCallback onRequest;

  const PermissionCard({
    super.key,
    required this.item,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final l10n = context.l10n;
    final isGranted = item.isGranted;

    String title = item.title;
    String subtitle = item.subtitle;
    if (title.isEmpty) {
      switch (item.type) {
        case AppPermissionType.notifications:
          title = l10n.notificationPermTitle;
          subtitle = l10n.notificationPermDesc;
          break;
        case AppPermissionType.visualizer:
          title = l10n.visualizerPermTitle;
          subtitle = l10n.visualizerPermDesc;
          break;
        case AppPermissionType.mediaLibrary:
          title = l10n.storagePermTitle;
          subtitle = l10n.storagePermDesc;
          break;
        case AppPermissionType.installUpdates:
          title = l10n.updatePermTitle;
          subtitle = l10n.updatePermDesc;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? Colors.greenAccent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted
                  ? Colors.greenAccent.withValues(alpha: 0.15)
                  : primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              item.icon,
              size: 24,
              color: isGranted ? Colors.greenAccent : primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text(
                    l10n.permissionGranted,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: onRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.permissionGrant,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
