import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:codetyhub_app/app/controllers/gamification_controller.dart';
import 'package:codetyhub_app/app/data/mock_data.dart';
import 'package:codetyhub_app/app/widgets/course_card.dart';
import 'package:codetyhub_app/app/widgets/pathway_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    await GetStorage.init('CardsTestContainer');
  });

  setUp(() {
    Get.reset();
  });

  group('Card Widgets Tests', () {
    testWidgets('PathwayCard renders title and details', (WidgetTester tester) async {
      final pathway = MockData.pathways.first;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: PathwayCard(pathway: pathway),
          ),
        ),
      );

      expect(find.text(pathway.title), findsOneWidget);
      expect(find.text(pathway.description), findsOneWidget);
    });

    testWidgets('CourseCard renders course info', (WidgetTester tester) async {
      Get.put<GetStorage>(GetStorage('CardsTestContainer'));
      Get.put(GamificationController());

      final course = MockData.pathways.first.courses.first;

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CourseCard(
              course: course,
              index: 0,
              accentColor: Colors.blue,
              pathwayId: 'ml-fundamentals',
            ),
          ),
        ),
      );

      expect(find.text(course.title), findsOneWidget);
      expect(find.text(course.description), findsOneWidget);
    });
  });
}
