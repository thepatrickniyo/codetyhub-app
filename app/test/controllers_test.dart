import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:codetyhub_app/app/controllers/auth_controller.dart';
import 'package:codetyhub_app/app/controllers/course_controller.dart';
import 'package:codetyhub_app/app/controllers/gamification_controller.dart';
import 'package:codetyhub_app/app/controllers/home_controller.dart';
import 'package:codetyhub_app/app/controllers/nav_controller.dart';
import 'package:codetyhub_app/app/controllers/pathway_controller.dart';
import 'package:codetyhub_app/app/controllers/quiz_controller.dart';
import 'package:codetyhub_app/app/data/auth_service.dart';
import 'package:codetyhub_app/app/data/mock_data.dart';
import 'package:codetyhub_app/app/models/pathway_model.dart';
import 'package:codetyhub_app/app/models/quiz_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    await GetStorage.init('ControllersTestContainer');
  });

  setUp(() {
    Get.reset();
  });

  group('NavController Tests', () {
    test('changePage updates index', () {
      final nav = Get.put(NavController());
      expect(nav.currentIndex.value, equals(0));

      nav.changePage(2);
      expect(nav.currentIndex.value, equals(2));
    });
  });

  group('HomeController Tests', () {
    test('filteredPathways filters by title or description query', () {
      final home = Get.put(HomeController());
      expect(home.filteredPathways.length, equals(MockData.pathways.length));

      home.updateSearch('nlp');
      expect(home.filteredPathways.length, equals(1));
      expect(home.filteredPathways.first.id, equals('nlp'));

      home.updateSearch('Unknown Query String');
      expect(home.filteredPathways, isEmpty);

      home.updateSearch('');
      expect(home.filteredPathways.length, equals(MockData.pathways.length));
    });
  });

  group('GamificationController Tests', () {
    test('GamificationController XP, level math, and lesson completion', () {
      Get.put<GetStorage>(GetStorage('ControllersTestContainer'));
      final gamification = Get.put(GamificationController());

      expect(gamification.level, isA<int>());
      expect(gamification.xpDisplay.contains('XP'), isTrue);
      expect(gamification.rankDisplay, equals('#12'));
      expect(gamification.riskBand, equals('LOW'));
      expect(gamification.riskScore, equals(0.0));
      expect(gamification.mlInterventions, isEmpty);

      final initialXp = gamification.xp.value;
      gamification.completeLesson('ml-1:0', 'ml-1');

      expect(gamification.completedLessons.contains('ml-1:0'), isTrue);
      expect(gamification.xp.value, greaterThan(initialXp));
      expect(gamification.lastXpAward.value, equals(50));
      expect(gamification.showXpToast.value, isTrue);
    });
  });

  group('CourseController Tests', () {
    test('Lesson unlock status and completion calculations', () {
      Get.put<GetStorage>(GetStorage('ControllersTestContainer'));
      Get.put(GamificationController());

      final course = MockData.pathways.first.courses.first;
      final courseCtrl = Get.put(CourseController(course: course, pathwayId: 'ml-fundamentals'));

      expect(courseCtrl.isLessonUnlocked(0), isTrue);
      expect(courseCtrl.isLessonUnlocked(1), isFalse);
      expect(courseCtrl.courseProgress, equals(0.0));

      courseCtrl.completeCurrentLesson();
      expect(courseCtrl.isLessonCompleted(0), isTrue);
      expect(courseCtrl.isLessonUnlocked(1), isTrue);
      expect(courseCtrl.courseProgress, greaterThan(0.0));

      courseCtrl.selectLesson(1);
      expect(courseCtrl.currentLesson.value, equals(1));

      if (courseCtrl.lessons.length > 3) {
        courseCtrl.selectLesson(3);
        expect(courseCtrl.currentLesson.value, equals(1));
      }
    });
  });

  group('PathwayController Tests', () {
    test('Initializes with default pathway and getters', () {
      Get.put<GetStorage>(GetStorage('ControllersTestContainer'));
      final pathwayCtrl = Get.put(PathwayController());

      expect(pathwayCtrl.pathway, isNotNull);
      expect(pathwayCtrl.courses, isNotEmpty);
      expect(pathwayCtrl.mlSkillRecommendations, isEmpty);
      expect(pathwayCtrl.mlCompletionPct, equals(0.0));
      expect(pathwayCtrl.masteredSkills, isEmpty);
    });
  });

  group('QuizController Tests', () {
    test('Quiz state flow: startQuiz, selectOption, nextQuestion, reset', () async {
      Get.put<GetStorage>(GetStorage('ControllersTestContainer'));
      final quiz = Get.put(QuizController());

      expect(quiz.phase.value, equals(QuizPhase.intro));
      expect(quiz.totalQuestions, greaterThan(0));
      expect(quiz.currentQuestion, isA<QuizQuestion>());

      quiz.startQuiz();
      expect(quiz.phase.value, equals(QuizPhase.question));
      expect(quiz.currentIndex.value, equals(0));
      expect(quiz.progress, greaterThan(0.0));

      quiz.selectOption(0);
      expect(quiz.selectedOption.value, equals(0));

      await quiz.nextQuestion();
      expect(quiz.currentIndex.value, equals(1));

      quiz.recommendation.value = MockData.getPathwayById('ml-fundamentals');
      expect(quiz.recommendationReason, contains('ML Fundamentals'));

      quiz.recommendation.value = MockData.getPathwayById('deep-learning');
      expect(quiz.recommendationReason, contains('Deep Learning'));

      quiz.recommendation.value = MockData.getPathwayById('nlp');
      expect(quiz.recommendationReason, contains('NLP'));

      quiz.recommendation.value = MockData.getPathwayById('computer-vision');
      expect(quiz.recommendationReason, contains('Computer Vision'));

      quiz.recommendation.value = MockData.getPathwayById('generative-ai');
      expect(quiz.recommendationReason, contains('Generative AI'));

      quiz.recommendation.value = MockData.getPathwayById('mlops');
      expect(quiz.recommendationReason, contains('MLOps'));

      quiz.reset();
      expect(quiz.phase.value, equals(QuizPhase.intro));
    });
  });

  group('AuthController Tests', () {
    test('signUp, login, and logout state management', () async {
      final storage = GetStorage('ControllersTestContainer');
      await storage.erase();
      final authService = AuthService(storage);
      final authCtrl = Get.put(AuthController(authService));

      expect(authCtrl.isLoggedIn, isFalse);
      expect(authCtrl.user.value, isNull);

      final success = await authCtrl.signUp(
        name: 'Charlie',
        email: 'charlie@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(authCtrl.isLoggedIn, isTrue);
      expect(authCtrl.user.value?.email, equals('charlie@example.com'));

      await authCtrl.logout();
      expect(authCtrl.isLoggedIn, isFalse);

      final loginSuccess = await authCtrl.login(
        email: 'charlie@example.com',
        password: 'password123',
      );
      expect(loginSuccess, isTrue);
      expect(authCtrl.isLoggedIn, isTrue);

      final failedLogin = await authCtrl.login(
        email: 'charlie@example.com',
        password: 'wrongpassword',
      );
      expect(failedLogin, isFalse);
      expect(authCtrl.errorMessage.value, isNotEmpty);
    });
  });
}
