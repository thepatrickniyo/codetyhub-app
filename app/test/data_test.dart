import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:codetyhub_app/app/data/app_config.dart';
import 'package:codetyhub_app/app/data/auth_service.dart';
import 'package:codetyhub_app/app/data/lesson_data.dart';
import 'package:codetyhub_app/app/data/mock_data.dart';
import 'package:codetyhub_app/app/data/quiz_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    await GetStorage.init('DataTestContainer');
  });

  group('AppConfig Tests', () {
    test('bridgeUrl and devBearerToken getters', () {
      expect(bridgeUrl, isA<String>());
      expect(devBearerToken('user123'), equals('DEV-user123-codetyhub'));
    });
  });

  group('Mock Data Providers Tests', () {
    test('mockPathways returns non-empty list of pathways', () {
      expect(MockData.pathways, isNotEmpty);
      expect(MockData.pathways.first.courses, isNotEmpty);
    });

    test('mockLeaderboard returns top entries', () {
      expect(MockData.leaderboard, isNotEmpty);
      expect(MockData.leaderboard.first.rank, equals(1));
    });

    test('LessonData.getLessons returns lessons', () {
      final lessons = LessonData.getLessons('ml-1');
      expect(lessons, isNotEmpty);
    });

    test('QuizData.questions returns placement questions', () {
      expect(QuizData.questions, isNotEmpty);
      expect(QuizData.questions.first.options.length, equals(4));
    });
  });

  group('AuthService Tests', () {
    test('signUp creates a user and stores session', () async {
      final storage = GetStorage('DataTestContainer');
      await storage.erase();
      final auth = AuthService(storage);

      expect(auth.isLoggedIn, isFalse);
      expect(auth.currentUser, isNull);

      final user = await auth.signUp(
        name: 'Alice',
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(user.name, equals('Alice'));
      expect(user.email, equals('alice@example.com'));
      expect(auth.isLoggedIn, isTrue);
      expect(auth.currentUser?.email, equals('alice@example.com'));
    });

    test('signUp throws error on duplicate email', () async {
      final storage = GetStorage('DataTestContainer');
      await storage.erase();
      final auth = AuthService(storage);

      await auth.signUp(
        name: 'Alice',
        email: 'alice@example.com',
        password: 'password123',
      );

      expect(
        () async => await auth.signUp(
          name: 'Alice Clone',
          email: 'ALICE@EXAMPLE.COM',
          password: 'otherpassword',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('login succeeds with correct credentials and fails on wrong credentials', () async {
      final storage = GetStorage('DataTestContainer');
      await storage.erase();
      final auth = AuthService(storage);

      await auth.signUp(
        name: 'Bob',
        email: 'bob@example.com',
        password: 'secretpassword',
      );

      await auth.logout();
      expect(auth.isLoggedIn, isFalse);

      final loggedIn = await auth.login(
        email: 'bob@example.com',
        password: 'secretpassword',
      );
      expect(loggedIn.email, equals('bob@example.com'));
      expect(auth.isLoggedIn, isTrue);

      expect(
        () async => await auth.login(
          email: 'bob@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
