class QuizQuestion {
  final int id;
  final int position;
  final String question;
  final List<String> options;

  const QuizQuestion({
    required this.id,
    required this.position,
    required this.question,
    required this.options,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    final rawOptions = (map['options'] as List? ?? const []).cast<dynamic>();
    return QuizQuestion(
      id: (map['id'] as num).toInt(),
      position: (map['position'] as num).toInt(),
      question: (map['question'] ?? map['question_text'] ?? '').toString(),
      options: rawOptions.map((e) => e.toString()).toList(growable: false),
    );
  }
}

class QuizSession {
  final String status;
  final int currentPosition;
  final int correctCount;
  final int wrongCount;
  final int pointsEarned;
  final bool flagged;
  final List<QuizQuestion> questions;

  const QuizSession({
    required this.status,
    required this.currentPosition,
    required this.correctCount,
    required this.wrongCount,
    required this.pointsEarned,
    required this.flagged,
    required this.questions,
  });

  bool get isCompleted => status == 'completed';

  factory QuizSession.fromMap(Map<String, dynamic> map) {
    final rawQuestions = (map['questions'] as List? ?? const []).cast<dynamic>();
    return QuizSession(
      status: (map['status'] ?? 'active').toString(),
      currentPosition: ((map['current_position'] ?? 1) as num).toInt(),
      correctCount: ((map['correct_count'] ?? 0) as num).toInt(),
      wrongCount: ((map['wrong_count'] ?? 0) as num).toInt(),
      pointsEarned: ((map['points_earned'] ?? 0) as num).toInt(),
      flagged: map['flagged'] == true,
      questions: rawQuestions
          .map((e) => QuizQuestion.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false),
    );
  }
}

class AnswerResult {
  final bool isCorrect;
  final int correctIndex;
  final int correctCount;
  final int wrongCount;
  final int pointsEarned;
  final int nextPosition;
  final bool completed;
  final bool flagged;

  const AnswerResult({
    required this.isCorrect,
    required this.correctIndex,
    required this.correctCount,
    required this.wrongCount,
    required this.pointsEarned,
    required this.nextPosition,
    required this.completed,
    required this.flagged,
  });

  factory AnswerResult.fromMap(Map<String, dynamic> map) => AnswerResult(
        isCorrect: map['is_correct'] == true,
        correctIndex: ((map['correct_index'] ?? -1) as num).toInt(),
        correctCount: ((map['correct_count'] ?? 0) as num).toInt(),
        wrongCount: ((map['wrong_count'] ?? 0) as num).toInt(),
        pointsEarned: ((map['points_earned'] ?? 0) as num).toInt(),
        nextPosition: ((map['current_position'] ?? 1) as num).toInt(),
        completed: map['completed'] == true,
        flagged: map['flagged'] == true,
      );
}

class LeaderboardEntry {
  final int rank;
  final String username;
  final int points;
  final int correct;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.username,
    required this.points,
    required this.correct,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) => LeaderboardEntry(
        rank: ((map['rank'] ?? 0) as num).toInt(),
        username: (map['username'] ?? 'Player').toString(),
        points: ((map['points'] ?? 0) as num).toInt(),
        correct: ((map['correct'] ?? 0) as num).toInt(),
        isCurrentUser: map['is_current_user'] == true,
      );
}
