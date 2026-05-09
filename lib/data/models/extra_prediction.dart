class ExtraPrediction {
  final String questionId;
  final String userId;
  final String answer;
  final DateTime savedAt;
  const ExtraPrediction({
    required this.questionId,
    required this.userId,
    required this.answer,
    required this.savedAt,
  });
  factory ExtraPrediction.fromFirestore(
      String questionId, Map<String, dynamic> data) {
    final savedAt = data['saved_at'];
    return ExtraPrediction(
      questionId: questionId,
      userId: data['user_id'] ?? '',
      answer: data['answer'] ?? '',
      savedAt: savedAt != null ? (savedAt as dynamic).toDate() : DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'answer': answer,
      'saved_at': savedAt,
    };
  }
}
