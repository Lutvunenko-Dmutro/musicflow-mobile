import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/features/settings/widgets/update_changelog_view.dart';
import 'package:music_flow_mobile/models/update_info.dart';

void main() {
  testWidgets('UpdateChangelogView strips hashtags, asterisks, subheadings and SHA-256 lines', (tester) async {
    const rawChangelog = '''
### 📦 Оновлення MusicFlow Mobile v0.1.1

**Зміни у цій версії:**
* feat: add build logging to build_log.txt for easier debugging
* fix: remove all emojis and special characters from batch script to fix cmd parsing

**SHA-256 (Release):** `5e71d0b9cb3e9b846b79ce5a59509550c91ad9983a0483ba1e5e771e63dd22f2`
**SHA-256 (Debug):** `e29fc4d35cadef1633fb19f4ca2e1b24612fd8183dc89a9888ca6e15f02f1c52`
''';

    final info = UpdateInfo(
      version: '0.1.1',
      buildNumber: 2,
      fileSizeBytes: 2000,
      downloadUrl: 'http://test',
      changelog: rawChangelog,
      userCurrentBuild: 1,
      isChannelSwitch: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateChangelogView(info: info),
        ),
      ),
    );

    // Перевіряємо, що хештеги '###' та зірочки '**' НЕ відображаються у списку
    expect(find.textContaining('###'), findsNothing);
    expect(find.textContaining('**'), findsNothing);
    expect(find.textContaining('*Зміни'), findsNothing);

    // Перевіряємо, що SHA-256 вилучено зі списку чейнджлогу
    expect(find.textContaining('SHA-256'), findsNothing);

    // Перевіряємо, що чисті пункти відображаються коректно
    expect(find.text('feat: add build logging to build_log.txt for easier debugging'), findsOneWidget);
    expect(find.text('fix: remove all emojis and special characters from batch script to fix cmd parsing'), findsOneWidget);
  });
}
