import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/quiz_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

class QuizView extends StatelessWidget {
  const QuizView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuizController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Obx(() {
        switch (controller.phase.value) {
          case QuizPhase.intro:
            return _IntroScreen(controller: controller);
          case QuizPhase.question:
            return _QuestionScreen(controller: controller);
          case QuizPhase.analyzing:
            return const _AnalyzingScreen();
          case QuizPhase.result:
            return _ResultScreen(controller: controller);
        }
      }),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INTRO SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _IntroScreen extends StatelessWidget {
  const _IntroScreen({required this.controller});
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _BackBtn(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, const Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.psychology_outlined,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Find Your\nPersonalized\nPathway',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.0,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Answer 10 short questions about your background, goals, and interests. Our engine will map your skills against our knowledge graph and recommend the ideal starting point.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Info chips — Wrap prevents overflow on small screens
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _InfoChip(
                          icon: Icons.timer_outlined,
                          label: '3–4 min'),
                      _InfoChip(
                          icon: Icons.quiz_outlined,
                          label: '10 questions'),
                      _InfoChip(
                          icon: Icons.auto_awesome_outlined,
                          label: 'AI-powered'),
                    ],
                  ),
                  const SizedBox(height: 44),
                  // How it works
                  _HowItWorksCard(),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
          // Start CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.startQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Start the Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _HowItWorksStep(
            number: '1',
            title: 'Answer honestly',
            description: 'We ask about your experience, goals, and interests.',
          ),
          const SizedBox(height: 12),
          _HowItWorksStep(
            number: '2',
            title: 'Skills are mapped',
            description:
                'Each answer scores your affinity across 6 AI skill domains.',
          ),
          const SizedBox(height: 12),
          _HowItWorksStep(
            number: '3',
            title: 'Get your match',
            description:
                'The pathway with your highest alignment score is recommended.',
          ),
        ],
      ),
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
  });
  final String number;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text(description,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// QUESTION SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _QuestionScreen extends StatelessWidget {
  const _QuestionScreen({required this.controller});
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Top bar: back + progress ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 20, 0),
            child: Row(
              children: [
                _BackBtn(onTap: controller.reset),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${controller.currentIndex.value + 1} of ${controller.totalQuestions}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: controller.progress,
                              minHeight: 4,
                              backgroundColor: AppColors.border,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          ),
                        ],
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // ── Question + options ────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              final q = controller.currentQuestion;
              final selected = controller.selectedOption.value;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Question ${controller.currentIndex.value + 1}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      q.question,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.hint,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Answer options
                    ...List.generate(q.options.length, (i) {
                      final isSelected = selected == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionTile(
                          label: q.options[i],
                          index: i,
                          isSelected: isSelected,
                          onTap: () => controller.selectOption(i),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
          // ── Next / Finish button ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Obx(() {
              final enabled = controller.selectedOption.value >= 0;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: enabled ? controller.nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                    disabledForegroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    controller.isLastQuestion ? 'See My Pathway' : 'Next Question',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  static const _letters = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Letter badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _letters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.4,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ANALYZING SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _AnalyzingScreen extends StatefulWidget {
  const _AnalyzingScreen();

  @override
  State<_AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<_AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      'Mapping your skill profile...',
      'Scoring across 6 AI domains...',
      'Traversing the knowledge graph...',
      'Computing your best match...',
    ];

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spinning brain icon
              RotationTransition(
                turns: _spin,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, const Color(0xFF1D4ED8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.psychology_outlined,
                      color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 36),
              Text(
                'Analyzing your\nanswers...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Our engine is mapping your responses\nagainst 6 AI skill domains.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              // Animated processing steps
              ...steps.map((s) => _AnalyzingStep(label: s, steps: steps)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyzingStep extends StatefulWidget {
  const _AnalyzingStep({required this.label, required this.steps});
  final String label;
  final List<String> steps;

  @override
  State<_AnalyzingStep> createState() => _AnalyzingStepState();
}

class _AnalyzingStepState extends State<_AnalyzingStep> {
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final delay = Duration(
      milliseconds: widget.steps.indexOf(widget.label) * 600 + 400,
    );
    Future.delayed(delay, () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _done
                ? Icon(Icons.check_circle_rounded,
                    key: const ValueKey(true),
                    color: const Color(0xFF22C55E),
                    size: 18)
                : SizedBox(
                    key: const ValueKey(false),
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Text(
            widget.label,
            style: TextStyle(
              color: _done ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 13,
              fontWeight: _done ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// RESULT SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _ResultScreen extends StatelessWidget {
  const _ResultScreen({required this.controller});
  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final pathway = controller.recommendation.value!;
    final accentColor = AppColors.pathwayGradients[
        pathway.colorIndex % AppColors.pathwayGradients.length];

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Hero image ───────────────────────────────────────────
                  Stack(
                    children: [
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              pathway.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: accentColor.withValues(alpha: 0.1),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.6),
                                  ],
                                  stops: const [0.4, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Match badge overlaid
                      Positioned(
                        bottom: 16,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Your Best Match',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Content ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We recommend',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pathway.title,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.6,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          controller.recommendationReason,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            height: 1.65,
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Meta pills
                        Row(
                          children: [
                            _ResultPill(
                              icon: Icons.menu_book_rounded,
                              label: '${pathway.courseCount} courses',
                              color: accentColor,
                            ),
                            const SizedBox(width: 10),
                            _ResultPill(
                              icon: Icons.schedule_rounded,
                              label: '${pathway.totalHours}h total',
                              color: accentColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        // Skill score breakdown
                        _ScoreBreakdown(controller: controller),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom actions ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      Get.toNamed(AppRoutes.pathwayDetail(pathway.id));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Start Learning',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: controller.reset,
                    child: Text(
                      'Retake the quiz',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill(
      {required this.icon, required this.label, required this.color});
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
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.controller});
  final QuizController controller;

  static const _labels = {
    'ml-fundamentals': 'ML Fundamentals',
    'deep-learning': 'Deep Learning',
    'nlp': 'Natural Language Processing',
    'computer-vision': 'Computer Vision',
    'generative-ai': 'Generative AI',
    'mlops': 'MLOps & Deployment',
  };

  @override
  Widget build(BuildContext context) {
    final scores = controller.scores;
    final maxScore =
        scores.values.isEmpty ? 1 : scores.values.reduce((a, b) => a > b ? a : b);
    final recommendedId = controller.recommendation.value?.id ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your skill profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ..._labels.entries.map((entry) {
            final score = scores[entry.key] ?? 0;
            final ratio = maxScore > 0 ? score / maxScore : 0.0;
            final isTop = entry.key == recommendedId;
            final barColor =
                isTop ? AppColors.primary : AppColors.textSecondary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isTop
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Best fit',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.toDouble(),
                      minHeight: 5,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        barColor.withValues(alpha: isTop ? 1.0 : 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared back button
// ─────────────────────────────────────────────────────────────────────────────
class _BackBtn extends StatelessWidget {
  const _BackBtn({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.back(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(Icons.arrow_back_rounded,
            size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
