enum ExtraQuestionType { team, player }

class ExtraQuestion {
  final String id;
  final String question;
  final ExtraQuestionType type;
  final int order;
  final String? positionFilter;
  final String? teamFilter;
  final String? correctAnswer;

  const ExtraQuestion({
    required this.id,
    required this.question,
    required this.type,
    required this.order,
    this.positionFilter,
    this.teamFilter,
    this.correctAnswer,
  });

  factory ExtraQuestion.fromFirestore(String id, Map<String, dynamic> data) {
    return ExtraQuestion(
      id: id,
      question: data['question'] ?? '',
      type: data['type'] == 'team'
          ? ExtraQuestionType.team
          : ExtraQuestionType.player,
      order: data['order'] ?? 0,
      positionFilter: data['position_filter'],
      teamFilter: data['team_filter'],
      correctAnswer: data['correct_answer'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'question': question,
      'type': type == ExtraQuestionType.team ? 'team' : 'player',
      'order': order,
      if (positionFilter != null) 'position_filter': positionFilter,
      if (teamFilter != null) 'team_filter': teamFilter,
      if (correctAnswer != null) 'correct_answer': correctAnswer,
    };
  }
}
