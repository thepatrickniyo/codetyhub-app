import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/course_controller.dart';
import '../../controllers/gamification_controller.dart';
import '../../models/badge_model.dart';
import '../../theme/app_colors.dart';

class CoursePlayerView extends StatelessWidget {
  const CoursePlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    final courseCtrl = Get.find<CourseController>();
    final gamCtrl = Get.find<GamificationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _TopBar(courseCtrl: courseCtrl),
                _LessonTabRow(courseCtrl: courseCtrl),
                Expanded(
                  child: _LessonContent(
                    courseCtrl: courseCtrl,
                    gamCtrl: gamCtrl,
                  ),
                ),
              ],
            ),
          ),
          // XP toast
          Obx(() {
            if (!gamCtrl.showXpToast.value) return const SizedBox.shrink();
            return _XpToast(amount: gamCtrl.lastXpAward.value);
          }),
          // Badge celebration
          Obx(() {
            final badge = gamCtrl.newlyUnlocked.value;
            if (badge == null) return const SizedBox.shrink();
            return _BadgeCelebration(
              badge: badge,
              onDismiss: gamCtrl.clearBadgeOverlay,
            );
          }),
        ],
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.courseCtrl});
  final CourseController courseCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      size: 18, color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  courseCtrl.course.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Obx(() {
                final pct = (courseCtrl.courseProgress * 100).round();
                return Text(
                  '$pct%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Obx(() => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: courseCtrl.courseProgress,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Lesson Tab Row ────────────────────────────────────────────────────────────
class _LessonTabRow extends StatelessWidget {
  const _LessonTabRow({required this.courseCtrl});
  final CourseController courseCtrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Divider(height: 1, color: AppColors.border),
          SizedBox(
            height: 48,
            child: Obx(() {
              final current = courseCtrl.currentLesson.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: courseCtrl.lessons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isActive = current == index;
                  final isDone = courseCtrl.isLessonCompleted(index);
                  final isUnlocked = courseCtrl.isLessonUnlocked(index);
                  return GestureDetector(
                    onTap: () => courseCtrl.selectLesson(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : isDone
                                ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                                : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary
                              : isDone
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.4)
                                  : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDone)
                            Icon(Icons.check_circle_rounded,
                                size: 13,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF22C55E))
                          else if (!isUnlocked)
                            Icon(Icons.lock_outline_rounded,
                                size: 13,
                                color: AppColors.textSecondary)
                          else
                            Icon(Icons.play_circle_outline_rounded,
                                size: 13,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            'Lesson ${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : isUnlocked
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Lesson Content ────────────────────────────────────────────────────────────
class _LessonContent extends StatelessWidget {
  const _LessonContent({
    required this.courseCtrl,
    required this.gamCtrl,
  });
  final CourseController courseCtrl;
  final GamificationController gamCtrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = courseCtrl.currentLesson.value;
      if (index >= courseCtrl.lessons.length) return const SizedBox.shrink();
      final lesson = courseCtrl.lessons[index];
      final isDone = courseCtrl.isLessonCompleted(index);

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lesson number + XP badge
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Lesson ${index + 1} of ${courseCtrl.lessons.length}',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 4),
                      Text(
                        '+50 XP',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lesson title
            Text(
              lesson.title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.4,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  lesson.duration,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Body
            Text(
              lesson.body,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.75,
              ),
            ),

            // Code snippet
            if (lesson.codeSnippet != null) ...[
              const SizedBox(height: 24),
              _CodeBlock(
                code: lesson.codeSnippet!,
                language: lesson.codeLanguage,
              ),
            ],

            const SizedBox(height: 32),

            // Mark complete button
            SizedBox(
              width: double.infinity,
              child: isDone
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF22C55E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF22C55E), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Lesson Completed',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: courseCtrl.completeCurrentLesson,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Mark as Complete',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
}

// ── Code Block ────────────────────────────────────────────────────────────────
class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code, required this.language});
  final String code;
  final String language;

  @override
  Widget build(BuildContext context) {
    final isDark = Get.isDarkMode;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                // Traffic-light dots
                _Dot(color: const Color(0xFFFF5F56)),
                const SizedBox(width: 6),
                _Dot(color: const Color(0xFFFFBD2E)),
                const SizedBox(width: 6),
                _Dot(color: const Color(0xFF27C93F)),
                const Spacer(),
                Text(
                  language,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Code
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Color(0xFFE6EDF3),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

// ── XP Toast ──────────────────────────────────────────────────────────────────
class _XpToast extends StatefulWidget {
  const _XpToast({required this.amount});
  final int amount;

  @override
  State<_XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<_XpToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slide = Tween<Offset>(
            begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFBBF24).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  '+${widget.amount} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Badge Celebration Overlay ─────────────────────────────────────────────────
class _BadgeCelebration extends StatefulWidget {
  const _BadgeCelebration({
    required this.badge,
    required this.onDismiss,
  });
  final BadgeModel badge;
  final VoidCallback onDismiss;

  @override
  State<_BadgeCelebration> createState() => _BadgeCelebrationState();
}

class _BadgeCelebrationState extends State<_BadgeCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = Tween<double>(begin: 0.5, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Container(
        color: Colors.black.withValues(alpha: 0.65),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge icon
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: widget.badge.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: widget.badge.color.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: Icon(widget.badge.icon,
                        color: widget.badge.color, size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Badge Unlocked!',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.badge.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.badge.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onDismiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.badge.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Awesome!',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
