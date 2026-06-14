import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/home_controller.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pathway_card.dart';

class PathwaysTab extends StatelessWidget {
  const PathwaysTab({super.key});

  @override
  Widget build(BuildContext context) {
    final homeController = Get.find<HomeController>();

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Learning Pathways',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose your AI learning journey',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: homeController.updateSearch,
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search pathways...',
                        hintStyle:
                            TextStyle(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'All', isActive: true),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Beginner'),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Intermediate'),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Advanced'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
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
                      Text('No pathways found',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 15)),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.isActive = false});
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary
            : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
