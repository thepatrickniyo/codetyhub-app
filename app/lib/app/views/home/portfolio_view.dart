import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/gamification_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../theme/app_colors.dart';

class StudentPortfolioView extends StatelessWidget {
  const StudentPortfolioView({super.key});

  @override
  Widget build(BuildContext context) {
    final gamCtrl = Get.find<GamificationController>();
    final authCtrl = Get.find<AuthController>();

    final user = authCtrl.user.value;
    final name = user?.name ?? 'Learner';
    final email = user?.email ?? 'learner@codetyhub.com';

    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Student Portfolio',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        shape: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bio Card ──────────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target: AI & ML Systems Engineer',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    'Self-driven computer science student specializing in building and deploying predictive algorithms. Actively working through self-paced learning paths to master model training, tuning, and production pipeline serving.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Stats Summary ──────────────────────────────────────────────────────────
            Obx(() => Row(
                  children: [
                    _PortfolioStat(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFF6B35),
                      value: gamCtrl.streak.value.toString(),
                      label: 'Streak Day',
                    ),
                    const SizedBox(width: 10),
                    _PortfolioStat(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFFBBF24),
                      value: gamCtrl.xp.value.toString(),
                      label: 'Total XP',
                    ),
                    const SizedBox(width: 10),
                    _PortfolioStat(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: AppColors.primary,
                      value: 'Level ${gamCtrl.level}',
                      label: 'Current Level',
                    ),
                  ],
                )),
            const SizedBox(height: 28),

            // ── Skill Matrix ────────────────────────────────────────────────────────────
            Text(
              'Individual Knowledge Profile (IKP)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Obx(() {
                final mlCourses = ['ml-1', 'ml-2', 'ml-3', 'ml-4'];
                final mlDone = mlCourses.where((c) => gamCtrl.completedCourses.contains(c)).length;
                final mlLessons = gamCtrl.completedLessons.where((k) => k.startsWith('ml-')).length;
                final mlProg = mlDone > 0 ? (mlDone / 4.0) : (mlLessons > 0 ? 0.12 : 0.0);

                final dlCourses = ['dl-1', 'dl-2', 'dl-3', 'dl-4'];
                final dlDone = dlCourses.where((c) => gamCtrl.completedCourses.contains(c)).length;
                final dlLessons = gamCtrl.completedLessons.where((k) => k.startsWith('dl-')).length;
                final dlProg = dlDone > 0 ? (dlDone / 4.0) : (dlLessons > 0 ? 0.12 : 0.0);

                final genCourses = ['gen-1', 'gen-2', 'gen-3', 'gen-4'];
                final genDone = genCourses.where((c) => gamCtrl.completedCourses.contains(c)).length;
                final genLessons = gamCtrl.completedLessons.where((k) => k.startsWith('gen-')).length;
                final genProg = genDone > 0 ? (genDone / 4.0) : (genLessons > 0 ? 0.12 : 0.0);

                final opsCourses = ['ops-1', 'ops-2', 'ops-3'];
                final opsDone = opsCourses.where((c) => gamCtrl.completedCourses.contains(c)).length;
                final opsLessons = gamCtrl.completedLessons.where((k) => k.startsWith('ops-')).length;
                final opsProg = opsDone > 0 ? (opsDone / 3.0) : (opsLessons > 0 ? 0.15 : 0.0);

                return Column(
                  children: [
                    _SkillProgress(
                      label: 'Machine Learning Fundamentals',
                      progress: mlProg == 0.0 ? 0.25 : mlProg,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 16),
                    _SkillProgress(
                      label: 'Deep Learning Systems',
                      progress: dlProg,
                      color: const Color(0xFF8B5CF6),
                    ),
                    const SizedBox(height: 16),
                    _SkillProgress(
                      label: 'Generative AI & LLMs',
                      progress: genProg,
                      color: const Color(0xFF06B6D4),
                    ),
                    const SizedBox(height: 16),
                    _SkillProgress(
                      label: 'MLOps & Server Deployment',
                      progress: opsProg,
                      color: const Color(0xFF22C55E),
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 28),

            // ── Achievements (Badges) ────────────────────────────────────────────────────
            Text(
              'Earned Credentials',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Obx(() {
              final badges = gamCtrl.unlockedBadges;
              if (badges.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 32, color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      Text(
                        'Complete lessons to unlock credentials',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    final badge = badges[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(badge.icon, color: badge.color, size: 24),
                          const SizedBox(height: 6),
                          Text(
                            badge.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            badge.description,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 28),

            // ── Recent ML Code Evaluations (CodeBERT Integration) ─────────────────────
            Text(
              'CodeBERT Evaluations Log',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _EvaluationRow(
                    title: 'FastAPI Serving API',
                    date: 'Today',
                    score: '91.8%',
                    rubrics: 'Functional Scopes · API Validation',
                  ),
                  const SizedBox(height: 12),
                  _EvaluationRow(
                    title: 'Gradient Descent NumPy',
                    date: 'Yesterday',
                    score: '88.5%',
                    rubrics: 'Matrix Math · Vector Optimization',
                  ),
                  const SizedBox(height: 12),
                  _EvaluationRow(
                    title: 'MinMaxScaler Scaler',
                    date: '3 days ago',
                    score: '95.2%',
                    rubrics: 'Data Transform · Boundary Norm',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PortfolioStat extends StatelessWidget {
  const _PortfolioStat({
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
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillProgress extends StatelessWidget {
  const _SkillProgress({
    required this.label,
    required this.progress,
    required this.color,
  });

  final String label;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _EvaluationRow extends StatelessWidget {
  const _EvaluationRow({
    required this.title,
    required this.date,
    required this.score,
    required this.rubrics,
  });

  final String title;
  final String date;
  final String score;
  final String rubrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rubrics,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
