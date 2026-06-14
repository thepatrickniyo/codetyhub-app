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
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.15),
              AppColors.surface,
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        pathway.iconData,
                        size: 24,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                pathway.title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pathway.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.menu_book_outlined,
                    label: '${pathway.courseCount} courses',
                    color: color,
                  ),
                  const SizedBox(width: 12),
                  _MetaChip(
                    icon: Icons.schedule_outlined,
                    label: '${pathway.totalHours}h',
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
