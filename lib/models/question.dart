class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String hint;

  const Question({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.hint,
  });
}
