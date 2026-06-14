import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

class MarketplaceTab extends StatelessWidget {
  const MarketplaceTab({super.key});

  static const List<_CourseItem> _featured = [
    _CourseItem(
      title: 'Advanced PyTorch',
      instructor: 'Dr. Sarah Lin',
      price: 49,
      rating: 4.9,
      students: 3240,
      icon: Icons.science_outlined,
      colorIndex: 0,
    ),
    _CourseItem(
      title: 'LLM Fine-Tuning',
      instructor: 'Alex Mercer',
      price: 79,
      rating: 4.8,
      students: 1870,
      icon: Icons.auto_awesome_outlined,
      colorIndex: 1,
    ),
    _CourseItem(
      title: 'MLOps Bootcamp',
      instructor: 'Priya Nair',
      price: 59,
      rating: 4.7,
      students: 2100,
      icon: Icons.rocket_launch_outlined,
      colorIndex: 2,
    ),
    _CourseItem(
      title: 'Computer Vision Pro',
      instructor: 'James Osei',
      price: 69,
      rating: 4.9,
      students: 2860,
      icon: Icons.visibility_outlined,
      colorIndex: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                    'Marketplace',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Premium courses from top instructors',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
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
                      style: TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search courses...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 22),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Banner
                  _PromoBanner(),
                  const SizedBox(height: 24),
                  Text(
                    'Featured Courses',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MarketplaceCard(item: _featured[index]),
                ),
                childCount: _featured.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, const Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Limited Offer',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get 40% off\nany premium course',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Claim Now',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.school_rounded,
            size: 72,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({required this.item});
  final _CourseItem item;

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[item.colorIndex % _colors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.instructor,
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star_rounded,
                        size: 14, color: const Color(0xFFFBBF24)),
                    const SizedBox(width: 3),
                    Text(
                      item.rating.toString(),
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.students.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} students',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.price}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Enroll',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseItem {
  const _CourseItem({
    required this.title,
    required this.instructor,
    required this.price,
    required this.rating,
    required this.students,
    required this.icon,
    required this.colorIndex,
  });

  final String title;
  final String instructor;
  final int price;
  final double rating;
  final int students;
  final IconData icon;
  final int colorIndex;
}
