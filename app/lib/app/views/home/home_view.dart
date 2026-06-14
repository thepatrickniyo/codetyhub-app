import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/nav_controller.dart';
import '../../theme/app_colors.dart';
import '../../theme/theme_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/marketplace_tab.dart';
import 'tabs/pathways_tab.dart';
import 'tabs/settings_tab.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.put(NavController());
    Get.find<HomeController>();
    Get.find<AuthController>();

    final tabs = const [
      HomeTab(),
      PathwaysTab(),
      MarketplaceTab(),
      SettingsTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() => IndexedStack(
            index: navController.currentIndex.value,
            children: tabs,
          )),
      bottomNavigationBar: _BottomNavBar(navController: navController),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.navController});

  final NavController navController;

  @override
  Widget build(BuildContext context) {
    final isDark = Get.find<ThemeService>().isDarkMode;

    return Obx(() {
      final current = navController.currentIndex.value;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  current: current,
                  onTap: navController.changePage,
                ),
                _NavItem(
                  icon: Icons.route_outlined,
                  activeIcon: Icons.route_rounded,
                  label: 'Pathways',
                  index: 1,
                  current: current,
                  onTap: navController.changePage,
                ),
                _NavItem(
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront_rounded,
                  label: 'Marketplace',
                  index: 2,
                  current: current,
                  onTap: navController.changePage,
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 3,
                  current: current,
                  onTap: navController.changePage,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                size: 24,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
