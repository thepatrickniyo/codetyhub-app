class CourseModel {
  const CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.level,
    required this.lessons,
    required this.rating,
  });

  final String id;
  final String title;
  final String description;
  final String duration;
  final String level;
  final int lessons;
  final double rating;
}
