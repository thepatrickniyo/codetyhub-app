import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/pathway_controller.dart';
import '../../theme/app_colors.dart';
import '../../widgets/course_card.dart';

class PathwayDetailView extends StatelessWidget {
  const PathwayDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PathwayController>();
    final pathway = controller.pathway;
    final accentColor = AppColors.pathwayGradients[
        pathway.colorIndex % AppColors.pathwayGradients.length];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Hero image + back button (not a SliverAppBar — no fixed height) ──
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Cover image — fixed 240 px height
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        pathway.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: accentColor.withValues(alpha: 0.1),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: accentColor,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: accentColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: accentColor.withValues(alpha: 0.4),
                            size: 40,
                          ),
                        ),
                      ),
                      // Bottom-to-top gradient so text below reads cleanly
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.55),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Back button — positioned in top-left over the image
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Title + description banner — height adapts to content ────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pathway.title,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.4,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    pathway.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Stats row
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.menu_book_rounded,
                        label: '${pathway.courseCount} courses',
                        color: accentColor,
                      ),
                      const SizedBox(width: 10),
                      _StatPill(
                        icon: Icons.schedule_rounded,
                        label: '${pathway.totalHours}h total',
                        color: accentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Divider spacer ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              height: 8,
              color: AppColors.background,
            ),
          ),

          // ── Section header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
              child: Text(
                'Courses in this pathway',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),

          // ── Courses list ────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final course = pathway.courses[index];
                  return CourseCard(
                    course: course,
                    index: index,
                    accentColor: accentColor,
                    pathwayId: pathway.id,
                  );
                },
                childCount: pathway.courses.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat pill chip (replaces the old _StatCard boxes)
// ─────────────────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
