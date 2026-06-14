import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/home_controller.dart';
import '../../../data/mock_data.dart';
import '../../../models/leaderboard_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pathway_card.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();
    final authController = Get.find<AuthController>();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(authController: authController),
                  const SizedBox(height: 20),
                  _StatsRow(),
                  const SizedBox(height: 24),
                  _SearchBar(homeController: homeController),
                  const SizedBox(height: 28),
                  _LeaderboardSection(),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    title: 'AI Pathways',
                    trailing: Obx(
                      () => Text(
                        '${homeController.filteredPathways.length} available',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Pathways List ────────────────────────────────────────
          Obx(() {
            final pathways = homeController.filteredPathways;
            if (pathways.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'No pathways found',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: PathwayCard(pathway: pathways[index]),
                  ),
                  childCount: pathways.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.authController});
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Obx(() {
            final name = authController.user.value?.name.split(' ').first ?? 'Learner';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            );
          }),
        ),
        // Notification bell
        _IconBtn(icon: Icons.notifications_outlined, onTap: () {}),
        const SizedBox(width: 10),
        // Avatar
        Obx(() {
          final initials = (authController.user.value?.name ?? 'LN')
              .split(' ')
              .take(2)
              .map((w) => w.isNotEmpty ? w[0] : '')
              .join()
              .toUpperCase();
          return Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          icon: Icons.local_fire_department_rounded,
          iconColor: const Color(0xFFFF6B35),
          value: '7',
          label: 'Day Streak',
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFFFBBF24),
          value: '2,340',
          label: 'XP Points',
        ),
        const SizedBox(width: 12),
        _StatCard(
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF22C55E),
          value: '12',
          label: 'Lessons Done',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.homeController});
  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: homeController.updateSearch,
        style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search pathways...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leaderboard Section
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderboardSection extends StatelessWidget {
  const _LeaderboardSection();

  @override
  Widget build(BuildContext context) {
    final entries = MockData.leaderboard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Leaderboard',
          trailing: GestureDetector(
            onTap: () {},
            child: Text(
              'See all',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Top 3 Podium Cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place
            _PodiumCard(entry: entries[1], height: 80),
            const SizedBox(width: 8),
            // 1st place (tallest)
            _PodiumCard(entry: entries[0], height: 100, isFirst: true),
            const SizedBox(width: 8),
            // 3rd place
            _PodiumCard(entry: entries[2], height: 64),
          ],
        ),
        const SizedBox(height: 14),
        // Ranks 4-5 list
        ...entries.skip(3).map((e) => _LeaderboardRow(entry: e)),
      ],
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.entry,
    required this.height,
    this.isFirst = false,
  });

  final LeaderboardEntry entry;
  final double height;
  final bool isFirst;

  Color get _rankColor {
    switch (entry.rank) {
      case 1:
        return const Color(0xFFFBBF24); // gold
      case 2:
        return const Color(0xFF94A3B8); // silver
      default:
        return const Color(0xFFCD7F32); // bronze
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
        decoration: BoxDecoration(
          color: isFirst
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFirst
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _rankColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: _rankColor, width: 2),
              ),
              child: Center(
                child: Text(
                  entry.avatarInitials,
                  style: TextStyle(
                    color: _rankColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.name.split(' ').first,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _rankColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${(entry.points / 1000).toStringAsFixed(1)}k',
                style: TextStyle(
                  color: _rankColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              entry.rank == 1
                  ? Icons.workspace_premium_rounded
                  : Icons.military_tech_rounded,
              color: _rankColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            '#${entry.rank}',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                entry.avatarInitials,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.name,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 14, color: const Color(0xFFFF6B35)),
              const SizedBox(width: 3),
              Text(
                '${entry.streak}d',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(entry.points / 1000).toStringAsFixed(1)}k XP',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
