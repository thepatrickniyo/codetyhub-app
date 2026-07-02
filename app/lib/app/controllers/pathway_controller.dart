import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../data/app_config.dart';
import '../data/mock_data.dart';
import '../data/ml_service.dart';
import '../models/course_model.dart';
import '../models/ml_models.dart';
import '../models/pathway_model.dart';

class PathwayController extends GetxController {
  late final PathwayModel pathway;

  /// Live skill recommendations from the ML pathway engine.
  final Rx<PathwayRecommendResponse?> mlRecommendation = Rx<PathwayRecommendResponse?>(null);
  final RxBool isLoadingMl = false.obs;

  late final MlService _ml;

  @override
  void onInit() {
    super.onInit();

    // Resolve pathway from route params
    final id = Get.parameters['id'] ?? '';
    pathway = MockData.getPathwayById(id) ?? MockData.pathways.first;

    // Set up ML service with current user token
    final storage = Get.find<GetStorage>();
    final user = storage.read<Map<dynamic, dynamic>>('current_user');
    final userId = user?['id']?.toString() ?? 'anonymous';
    _ml = MlService(
      baseUrl: bridgeUrl,
      bearerToken: devBearerToken(userId),
    );

    // Fetch live ML skill recommendations for this pathway
    _loadMlRecommendations(userId);
  }

  List<CourseModel> get courses => pathway.courses;

  /// Top ML-recommended skill IDs for the current pathway context.
  List<SkillRecommendation> get mlSkillRecommendations =>
      mlRecommendation.value?.recommendations ?? [];

  /// ML graph completion percentage for this student.
  double get mlCompletionPct => mlRecommendation.value?.completionPct ?? 0.0;

  /// Skills the ML engine has marked as mastered.
  List<String> get masteredSkills => mlRecommendation.value?.mastered ?? [];

  Future<void> _loadMlRecommendations(String studentId) async {
    isLoadingMl.value = true;
    try {
      // Build a starter IKP seeded from the pathway's skill domain
      final starterIkp = _buildStarterIkp(pathway.id);

      final result = await _ml.recommendPathway(
        studentId: studentId,
        ikpScores: starterIkp,
        topN: 8,
        includeCollaborative: true,
      );

      if (result != null) {
        mlRecommendation.value = result;
        print('[PathwayController] Loaded ${result.recommendations.length} ML skill recs '
            'for pathway "${pathway.id}" — completion: ${result.completionPct}%');
      }
    } catch (e) {
      print('[PathwayController] Failed to load ML recommendations: $e');
    } finally {
      isLoadingMl.value = false;
    }
  }

  /// Seed the IKP with starter proficiency scores matching the pathway's domain.
  /// This gives the ML engine enough context to generate relevant recommendations.
  Map<String, double> _buildStarterIkp(String pathwayId) {
    const domainSeeds = <String, Map<String, double>>{
      'ml-fundamentals': {
        'python_basics': 0.80,
        'data_types': 0.75,
        'control_flow': 0.70,
        'numpy_basics': 0.50,
        'linear_regression': 0.20,
      },
      'deep-learning': {
        'python_basics': 0.90,
        'numpy_basics': 0.80,
        'linear_regression': 0.70,
        'neural_networks': 0.30,
      },
      'nlp': {
        'python_basics': 0.85,
        'control_flow': 0.80,
        'nlp_basics': 0.25,
      },
      'computer-vision': {
        'python_basics': 0.85,
        'numpy_basics': 0.70,
        'computer_vision': 0.20,
      },
      'generative-ai': {
        'python_basics': 0.90,
        'neural_networks': 0.60,
        'transformers': 0.30,
      },
      'mlops': {
        'python_basics': 0.85,
        'linear_regression': 0.65,
        'ml_deployment': 0.15,
      },
    };
    return domainSeeds[pathwayId] ?? {'python_basics': 0.7};
  }

  /// Manually refresh ML recommendations (e.g., after completing a course).
  Future<void> refreshRecommendations() async {
    final storage = Get.find<GetStorage>();
    final user = storage.read<Map<dynamic, dynamic>>('current_user');
    final userId = user?['id']?.toString() ?? 'anonymous';
    await _loadMlRecommendations(userId);
  }
}
