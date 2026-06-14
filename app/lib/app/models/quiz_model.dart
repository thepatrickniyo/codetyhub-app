/// A single quiz question.
///
/// Each answer option carries a [scores] map that maps a pathway ID
/// (e.g. 'ml-fundamentals') to the number of points that answer contributes
/// toward that pathway's recommendation score.
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.hint,
    required this.options,
    required this.optionScores,
  });

  final String question;

  /// Short contextual hint shown beneath the question.
  final String hint;

  /// Exactly 4 answer strings.
  final List<String> options;

  /// One score map per option. Keys are pathway IDs.
  final List<Map<String, int>> optionScores;
}
