import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'app/data/auth_service.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/theme/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();

  final storage = GetStorage();
  final authService = AuthService(storage);
  Get.put<AuthService>(authService, permanent: true);

  final themeService = ThemeService(storage);
  Get.put<ThemeService>(themeService, permanent: true);

  runApp(const CodetyHubApp());
}

class CodetyHubApp extends StatelessWidget {
  const CodetyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return GetMaterialApp(
      title: 'CodetyHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.theme,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.routes,
    );
  }
}

