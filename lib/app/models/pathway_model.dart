import 'course_model.dart';

class PathwayModel {
  const PathwayModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.colorIndex,
    required this.courses,
    required this.totalHours,
  });

  final String id;
  final String title;
  final String description;
  final String icon;
  final int colorIndex;
  final List<CourseModel> courses;
  final int totalHours;

  int get courseCount => courses.length;
}
