import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:codetyhub_app/app/theme/app_colors.dart';

void main() {
  group('AppColors Tests', () {
    testWidgets('AppColors returns light and dark mode colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.light,
          home: const Scaffold(),
        ),
      );

      // Light mode check
      Get.changeThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(AppColors.background, isA<Color>());
      expect(AppColors.surface, isA<Color>());
      expect(AppColors.surfaceLight, isA<Color>());
      expect(AppColors.primary, equals(const Color(0xFF3B82F6)));
      expect(AppColors.primaryLight, isA<Color>());
      expect(AppColors.accent, isA<Color>());
      expect(AppColors.accentGreen, equals(const Color(0xFF3B82F6)));
      expect(AppColors.textPrimary, isA<Color>());
      expect(AppColors.textSecondary, isA<Color>());
      expect(AppColors.error, equals(const Color(0xFFEF4444)));
      expect(AppColors.border, isA<Color>());
      expect(AppColors.pathwayGradients.length, equals(6));

      // Dark mode check
      Get.changeThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(AppColors.background, isA<Color>());
      expect(AppColors.surface, isA<Color>());
      expect(AppColors.surfaceLight, isA<Color>());
      expect(AppColors.primaryLight, isA<Color>());
      expect(AppColors.accent, isA<Color>());
      expect(AppColors.textPrimary, isA<Color>());
      expect(AppColors.textSecondary, isA<Color>());
      expect(AppColors.border, isA<Color>());
      expect(AppColors.pathwayGradients.length, equals(6));
    });
  });
}
