import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_flow_mobile/features/splash/services/permission_flow_service.dart';
import 'package:music_flow_mobile/features/splash/widgets/permission_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PermissionFlowService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('markOnboardingCompleted sets persistent flag in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('permissions_onboarding_completed_v1'), isNull);

      await PermissionFlowService.markOnboardingCompleted();

      final updatedPrefs = await SharedPreferences.getInstance();
      expect(updatedPrefs.getBool('permissions_onboarding_completed_v1'), isTrue);
    });

    test('PermissionItemData models initialize with default parameters', () {
      final item = PermissionItemData(
        type: AppPermissionType.notifications,
        title: 'Тест',
        subtitle: 'Опис тесту',
        icon: Icons.notifications,
      );

      expect(item.title, equals('Тест'));
      expect(item.subtitle, equals('Опис тесту'));
      expect(item.isGranted, isFalse);

      item.isGranted = true;
      expect(item.isGranted, isTrue);
    });
  });

  group('PermissionCard Widget Tests', () {
    testWidgets('renders granted state with checkmark', (tester) async {
      final item = PermissionItemData(
        type: AppPermissionType.notifications,
        title: 'Сповіщення',
        subtitle: 'Керування у шторці',
        icon: Icons.notifications,
        isGranted: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionCard(
              item: item,
              onRequest: () {},
            ),
          ),
        ),
      );

      expect(find.text('Сповіщення'), findsOneWidget);
      expect(find.text('Готово'), findsOneWidget);
      expect(find.text('Надати'), findsNothing);
    });

    testWidgets('renders ungranted state with request button', (tester) async {
      bool requested = false;
      final item = PermissionItemData(
        type: AppPermissionType.visualizer,
        title: 'Візуалізатор',
        subtitle: 'FFT Спектр',
        icon: Icons.equalizer,
        isGranted: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionCard(
              item: item,
              onRequest: () {
                requested = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Візуалізатор'), findsOneWidget);
      expect(find.text('Надати'), findsOneWidget);
      expect(find.text('Готово'), findsNothing);

      await tester.tap(find.text('Надати'));
      expect(requested, isTrue);
    });
  });
}
