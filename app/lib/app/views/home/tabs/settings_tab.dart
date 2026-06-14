import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/theme_service.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final themeService = Get.find<ThemeService>();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Profile Card ──────────────────────────────────
                  Obx(() {
                    final user = authController.user.value;
                    final initials = (user?.name ?? 'LN')
                        .split(' ')
                        .take(2)
                        .map((w) => w.isNotEmpty ? w[0] : '')
                        .join()
                        .toUpperCase();
                    return Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.12),
                            AppColors.surface,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryLight,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Learner',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: AppColors.textSecondary),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 28),

                  // ── Appearance ───────────────────────────────────
                  _SectionLabel(label: 'Appearance'),
                  const SizedBox(height: 10),
                  Obx(() {
                    final isDark = themeService.isDarkMode;
                    return _SettingsTile(
                      icon: isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Theme',
                      subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => themeService.toggleTheme(),
                        activeColor: AppColors.primary,
                        inactiveThumbColor: AppColors.textSecondary,
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFFFF6B35),
                    title: 'Notifications',
                    subtitle: 'Push & email alerts',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Account ───────────────────────────────────────
                  _SectionLabel(label: 'Account'),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: AppColors.primary,
                    title: 'Edit Profile',
                    subtitle: 'Update your name and photo',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF22C55E),
                    title: 'Change Password',
                    subtitle: 'Secure your account',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Privacy',
                    subtitle: 'Manage your data',
                    onTap: () {},
                  ),

                  const SizedBox(height: 28),

                  // ── Support ───────────────────────────────────────
                  _SectionLabel(label: 'Support'),
                  const SizedBox(height: 10),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF06B6D4),
                    title: 'Help & FAQ',
                    subtitle: 'Get answers to your questions',
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  _SettingsTile(
                    icon: Icons.star_outline_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    title: 'Rate the App',
                    subtitle: 'Share your feedback',
                    onTap: () {},
                  ),

                  const SizedBox(height: 32),

                  // ── Sign Out ──────────────────────────────────────
                  GestureDetector(
                    onTap: () async {
                      await authController.logout();
                      Get.offAllNamed(AppRoutes.login);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded,
                              color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Sign Out',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
