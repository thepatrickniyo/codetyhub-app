class LessonModel {
  const LessonModel({
    required this.title,
    required this.duration,
    required this.body,
    this.codeSnippet,
    this.codeLanguage = 'python',
  });

  final String title;
  final String duration;
  /// Rich text explanation shown in the lesson body.
  final String body;
  /// Optional code block to display below the body.
  final String? codeSnippet;
  final String codeLanguage;
}
