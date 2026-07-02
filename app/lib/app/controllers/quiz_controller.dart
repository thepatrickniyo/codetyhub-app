import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/app_config.dart';
import '../data/mock_data.dart';
import '../data/ml_service.dart';
import '../data/quiz_data.dart';
import '../models/ml_models.dart';
import '../models/pathway_model.dart';
import '../models/quiz_model.dart';

enum QuizPhase { intro, question, analyzing, result }

class QuizController extends GetxController {
  final questions = QuizData.questions;

  // ── Observable state ──────────────────────────────────────────────────────
  final Rx<QuizPhase> phase = QuizPhase.intro.obs;
  final RxInt currentIndex = 0.obs;
  final RxInt selectedOption = (-1).obs;

  /// pathway-id → accumulated score
  final RxMap<String, int> scores = <String, int>{}.obs;

  /// The recommended pathway after scoring completes.
  final Rx<PathwayModel?> recommendation = Rx<PathwayModel?>(null);

  /// Live ML skill recommendations from the pathway engine.
  final Rx<PathwayRecommendResponse?> mlRecommendation = Rx<PathwayRecommendResponse?>(null);

  late final MlService _ml;

  @override
  void onInit() {
    super.onInit();
    final storage = Get.find<GetStorage>();
    final user = storage.read<Map<dynamic, dynamic>>('current_user');
    final userId = user?['id']?.toString() ?? 'anonymous';
    _ml = MlService(
      baseUrl: bridgeUrl,
      bearerToken: devBearerToken(userId),
    );
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  QuizQuestion get currentQuestion => questions[currentIndex.value];

  int get totalQuestions => questions.length;

  double get progress =>
      (currentIndex.value + 1) / totalQuestions;

  bool get isLastQuestion => currentIndex.value == totalQuestions - 1;

  String get recommendationReason {
    final p = recommendation.value;
    if (p == null) return '';
    switch (p.id) {
      case 'ml-fundamentals':
        return 'Your answers show a strong interest in statistics, structured data, and building prediction models. ML Fundamentals gives you the rigorous foundation to start making data-driven decisions.';
      case 'deep-learning':
        return 'You gravitate toward neural architectures and training models from scratch. Deep Learning will teach you the mathematics and implementation skills behind state-of-the-art AI.';
      case 'nlp':
        return 'Your interest in language, text, and communication points directly to NLP. You will learn to build chatbots, sentiment analyzers, and language models used in real products.';
      case 'computer-vision':
        return 'You are drawn to visual data and spatial reasoning. Computer Vision will teach you to build systems that can see — from object detection to medical image analysis.';
      case 'generative-ai':
        return 'You are excited by creativity, APIs, and building on top of cutting-edge models. Generative AI will get you building with LLMs, diffusion models, and prompt engineering fast.';
      case 'mlops':
        return 'You care about getting models into production reliably. MLOps will teach you the engineering discipline — pipelines, monitoring, and deployment — that makes AI work in the real world.';
      default:
        return 'Based on your profile, this pathway matches your current skills and goals.';
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  void startQuiz() {
    scores.clear();
    currentIndex.value = 0;
    selectedOption.value = -1;
    recommendation.value = null;
    mlRecommendation.value = null;
    phase.value = QuizPhase.question;
  }

  void selectOption(int index) {
    selectedOption.value = index;
  }

  Future<void> nextQuestion() async {
    if (selectedOption.value < 0) return;

    // Accumulate scores for the selected option
    final optScores = currentQuestion.optionScores[selectedOption.value];
    optScores.forEach((pathwayId, points) {
      scores[pathwayId] = (scores[pathwayId] ?? 0) + points;
    });

    if (isLastQuestion) {
      await _finalize();
    } else {
      currentIndex.value++;
      selectedOption.value = -1;
    }
  }

  Future<void> _finalize() async {
    phase.value = QuizPhase.analyzing;

    // Find the pathway with the highest accumulated score (local rule-based)
    String bestId = scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    recommendation.value =
        MockData.getPathwayById(bestId) ?? MockData.pathways.first;

    // Build IKP from quiz scores — map pathway IDs to normalized proficiency
    final totalScore = scores.values.fold<int>(0, (sum, v) => sum + v);
    final ikp = <String, double>{};
    scores.forEach((pathwayId, pts) {
      // Map quiz pathway scores to ML skill node IDs (best-effort mapping)
      final normalizedId = _quizPathwayToSkillNode(pathwayId);
      ikp[normalizedId] = totalScore > 0 ? (pts / totalScore) : 0.0;
    });

    // Fetch ML recommendation in parallel with the analyzing animation
    final storage = Get.find<GetStorage>();
    final user = storage.read<Map<dynamic, dynamic>>('current_user');
    final studentId = user?['id']?.toString() ?? 'quiz-student';

    final mlFuture = _ml.recommendPathway(
      studentId: studentId,
      ikpScores: ikp,
      topN: 5,
    );

    // Wait for both the UX delay and the ML call
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 2800)),
      mlFuture,
    ]);

    final mlResult = results[1] as PathwayRecommendResponse?;
    if (mlResult != null) {
      mlRecommendation.value = mlResult;
      print('[QuizController] ML top recommendations: '
          '${mlResult.recommendations.take(3).map((r) => r.skillId).join(', ')}');

      // If ML strongly recommends a different pathway, override the local pick
      final mlTopSkill = mlResult.recommendations.isNotEmpty
          ? mlResult.recommendations.first.skillId
          : null;
      if (mlTopSkill != null) {
        final mlMappedPathway = _skillNodeToPathwayId(mlTopSkill);
        if (mlMappedPathway != null) {
          final mlPathway = MockData.getPathwayById(mlMappedPathway);
          if (mlPathway != null) {
            recommendation.value = mlPathway;
            print('[QuizController] ML overrode local recommendation → $mlMappedPathway');
          }
        }
      }
    } else {
      print('[QuizController] ML unreachable — using local quiz scoring');
    }

    phase.value = QuizPhase.result;
  }

  /// Maps quiz pathway IDs → ML knowledge graph skill node IDs.
  String _quizPathwayToSkillNode(String pathwayId) {
    const map = {
      'ml-fundamentals': 'linear_regression',
      'deep-learning': 'neural_networks',
      'nlp': 'nlp_basics',
      'computer-vision': 'computer_vision',
      'generative-ai': 'generative_models',
      'mlops': 'ml_deployment',
    };
    return map[pathwayId] ?? pathwayId;
  }

  /// Maps ML skill node IDs → app pathway IDs.
  String? _skillNodeToPathwayId(String skillNode) {
    const map = {
      'linear_regression': 'ml-fundamentals',
      'logistic_regression': 'ml-fundamentals',
      'decision_trees': 'ml-fundamentals',
      'random_forests': 'ml-fundamentals',
      'neural_networks': 'deep-learning',
      'convolutional_nets': 'deep-learning',
      'transformers': 'deep-learning',
      'nlp_basics': 'nlp',
      'word_embeddings': 'nlp',
      'computer_vision': 'computer-vision',
      'object_detection': 'computer-vision',
      'generative_models': 'generative-ai',
      'ml_deployment': 'mlops',
    };
    return map[skillNode];
  }

  void reset() {
    phase.value = QuizPhase.intro;
    currentIndex.value = 0;
    selectedOption.value = -1;
    scores.clear();
    recommendation.value = null;
    mlRecommendation.value = null;
  }
}
