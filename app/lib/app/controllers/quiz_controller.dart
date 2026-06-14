import 'package:get/get.dart';

import '../data/mock_data.dart';
import '../data/quiz_data.dart';
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
    // Simulate ML processing delay
    await Future.delayed(const Duration(milliseconds: 2800));

    // Find the pathway with the highest accumulated score
    String bestId = scores.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    recommendation.value =
        MockData.getPathwayById(bestId) ?? MockData.pathways.first;
    phase.value = QuizPhase.result;
  }

  void reset() {
    phase.value = QuizPhase.intro;
    currentIndex.value = 0;
    selectedOption.value = -1;
    scores.clear();
    recommendation.value = null;
  }
}
