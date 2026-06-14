import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/pathway_model.dart';
import '../routes/app_routes.dart';
import '../theme/app_colors.dart';

class PathwayCard extends StatelessWidget {
  const PathwayCard({super.key, required this.pathway});

  final PathwayModel pathway;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.pathwayGradients[
        pathway.colorIndex % AppColors.pathwayGradients.length];

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.pathwayDetail(pathway.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cover Image ──────────────────────────────────────
            _CoverImage(imageUrl: pathway.imageUrl, accentColor: color),

            // ── Content ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          pathway.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: color,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    pathway.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Divider
                  Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  // Meta chips
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.menu_book_rounded,
                        label: '${pathway.courseCount} courses',
                        color: color,
                      ),
                      const SizedBox(width: 16),
                      _MetaChip(
                        icon: Icons.schedule_rounded,
                        label: '${pathway.totalHours}h total',
                        color: color,
                      ),
                      const Spacer(),
                      // Enroll CTA pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Start',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover Image with gradient overlay
// ─────────────────────────────────────────────────────────────────────────────
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.imageUrl, required this.accentColor});

  final String imageUrl;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Network image with fade-in and error fallback
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: accentColor.withValues(alpha: 0.08),
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
            errorBuilder: (context, _, __) => Container(
              color: accentColor.withValues(alpha: 0.1),
              child: Center(
                child: Icon(Icons.image_not_supported_outlined,
                    color: accentColor.withValues(alpha: 0.4), size: 36),
              ),
            ),
          ),
          // Subtle gradient at the bottom so content below reads cleanly
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta chip (icon + label)
// ─────────────────────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
