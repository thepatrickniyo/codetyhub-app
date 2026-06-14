import 'package:get/get.dart';

import '../data/lesson_data.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import 'gamification_controller.dart';

class CourseController extends GetxController {
  CourseController({required this.course, required this.pathwayId});

  final CourseModel course;
  final String pathwayId;

  late final List<LessonModel> lessons;
  final RxInt currentLesson = 0.obs;
  final RxBool showContent = true.obs;

  GamificationController get _gamification => Get.find<GamificationController>();

  bool isLessonCompleted(int index) {
    final key = '${course.id}:$index';
    return _gamification.completedLessons.contains(key);
  }

  bool isLessonUnlocked(int index) {
    if (index == 0) return true;
    return isLessonCompleted(index - 1);
  }

  double get courseProgress {
    if (lessons.isEmpty) return 0;
    final done = lessons.asMap().keys.where(isLessonCompleted).length;
    return done / lessons.length;
  }

  void selectLesson(int index) {
    if (!isLessonUnlocked(index)) return;
    currentLesson.value = index;
    showContent.value = true;
  }

  void completeCurrentLesson() {
    final key = '${course.id}:${currentLesson.value}';
    _gamification.completeLesson(key, course.id);

    // Check if all lessons done → complete the course
    final allDone = lessons.asMap().keys.every(isLessonCompleted);
    if (allDone) {
      _gamification.completeCourse(course.id);
    }

    // Auto-advance to next lesson
    final next = currentLesson.value + 1;
    if (next < lessons.length) {
      Future.delayed(const Duration(milliseconds: 400), () {
        currentLesson.value = next;
      });
    }
  }

  @override
  void onInit() {
    super.onInit();
    lessons = LessonData.getLessons(course.id);
  }
}
