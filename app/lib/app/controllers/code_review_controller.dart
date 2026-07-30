import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../data/ml_service.dart';
import '../models/ml_models.dart';
import 'gamification_controller.dart';

class CodeReviewController extends GetxController {
  final MlService _mlService = MlService();

  final RxBool isLoading = false.obs;
  final Rx<CodeReviewResponse?> evaluationResult = Rx<CodeReviewResponse?>(null);
  final RxString errorMessage = ''.obs;
  final RxString selectedSkillNode = 'linear_regression'.obs;

  static const List<Map<String, String>> availableSkillNodes = [
    {'id': 'linear_regression', 'label': 'Linear Regression & Machine Learning'},
    {'id': 'python_basics', 'label': 'Python Basics & Algorithm Foundations'},
    {'id': 'data_structures', 'label': 'Data Structures & Arrays'},
    {'id': 'transformers_intro', 'label': 'Transformers & CodeBERT NLP'},
    {'id': 'sql_basics', 'label': 'SQL & Relational Database Queries'},
    {'id': 'docker_basics', 'label': 'Docker & Containerization'},
  ];

  /// Convert standard GitHub Gist URL to its raw content download URL
  String convertToRawGistUrl(String gistUrl) {
    var trimmed = gistUrl.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('/raw')) return trimmed;

    // Convert https://gist.github.com/username/gist_id -> https://gist.githubusercontent.com/username/gist_id/raw
    if (trimmed.contains('gist.github.com/')) {
      final clean = trimmed.replaceAll('https://gist.github.com/', '').replaceAll('http://gist.github.com/', '');
      final parts = clean.split('/');
      if (parts.length >= 2) {
        return 'https://gist.githubusercontent.com/${parts[0]}/${parts[1]}/raw';
      }
    }

    // Direct raw github user content
    if (trimmed.contains('raw.githubusercontent.com')) return trimmed;

    return trimmed;
  }

  /// Fetch code from GitHub Gist URL and run CodeBERT fine-tuned evaluation
  Future<void> submitGistForReview({
    required String studentId,
    required String skillNode,
    required String gistUrl,
  }) async {
    isLoading.value = true;
    errorMessage.value = '';
    evaluationResult.value = null;

    try {
      final rawUrl = convertToRawGistUrl(gistUrl);
      if (rawUrl.isEmpty) {
        throw Exception('Please enter a valid GitHub Gist URL.');
      }

      // 1. Fetch raw code from Gist
      final response = await http.get(Uri.parse(rawUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch code from GitHub Gist (HTTP ${response.statusCode}). Ensure the Gist URL is public.');
      }

      final codeText = response.body;
      if (codeText.trim().isEmpty) {
        throw Exception('The fetched GitHub Gist code is empty.');
      }

      // 2. Submit code to Fine-Tuned CodeBERT microservice
      final result = await _mlService.evaluateCode(
        studentId: studentId,
        skillNode: skillNode,
        codeText: codeText,
      );

      if (result != null) {
        evaluationResult.value = result;

        // Update real-time VSS score, award XP, and trigger PostgreSQL sync
        if (Get.isRegistered<GamificationController>()) {
          final gami = Get.find<GamificationController>();
          gami.recordCodeReviewEvaluation(
            newVssScore: result.vss,
            skillNode: skillNode,
            leaderboardRank: result.leaderboardRank,
          );
        }
      } else {
        throw Exception('Evaluation service returned no result. Ensure backend services are running.');
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  /// Reset the evaluation state to allow submitting a new Gist URL
  void resetSubmission() {
    evaluationResult.value = null;
    errorMessage.value = '';
    isLoading.value = false;
  }
}
