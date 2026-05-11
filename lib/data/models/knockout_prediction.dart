class KnockoutPrediction {
  final String slotId;
  final String userId;
  final int? homeGoals;
  final int? awayGoals;
  final String? winner; // teamId do vencedor explícito
  final DateTime savedAt;

  const KnockoutPrediction({
    required this.slotId,
    required this.userId,
    this.homeGoals,
    this.awayGoals,
    this.winner,
    required this.savedAt,
  });

  factory KnockoutPrediction.fromFirestore(
      String slotId, Map<String, dynamic> data) {
    return KnockoutPrediction(
      slotId: slotId,
      userId: data['user_id'] ?? '',
      homeGoals: data['home_goals'] as int?,
      awayGoals: data['away_goals'] as int?,
      winner: data['winner'] as String?,
      savedAt: data['saved_at'] != null
          ? (data['saved_at'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'user_id': userId,
        if (homeGoals != null) 'home_goals': homeGoals,
        if (awayGoals != null) 'away_goals': awayGoals,
        if (winner != null) 'winner': winner,
        'saved_at': savedAt,
      };
}
