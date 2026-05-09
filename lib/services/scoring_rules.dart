class ScoringRules {
  const ScoringRules._();

  static int matchPoints({
    required int officialHomeGoals,
    required int officialAwayGoals,
    required int predictedHomeGoals,
    required int predictedAwayGoals,
  }) {
    if (officialHomeGoals == predictedHomeGoals &&
        officialAwayGoals == predictedAwayGoals) {
      return 13;
    }

    final officialSign = officialHomeGoals.compareTo(officialAwayGoals);
    final predictedSign = predictedHomeGoals.compareTo(predictedAwayGoals);
    if (officialSign == predictedSign) return 6;

    if (officialHomeGoals == predictedHomeGoals ||
        officialAwayGoals == predictedAwayGoals) {
      return 2;
    }

    return 0;
  }

  static int extraPoints({
    required int order,
    required String answer,
    required String correct,
  }) {
    if (order == 4 || order == 5 || order == 6) {
      final answerSet = answer
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toSet();
      final correctSet = correct
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toSet();
      return answerSet.intersection(correctSet).length * pointsForOrder(order);
    }

    return answer.trim().toLowerCase() == correct.trim().toLowerCase()
        ? pointsForOrder(order)
        : 0;
  }

  static int pointsForOrder(int order) {
    const table = {
      1: 7,
      2: 7,
      3: 7,
      4: 10,
      5: 15,
      6: 20,
      7: 20,
      8: 25,
      9: 30,
      10: 40,
      11: 30,
      12: 20,
      13: 20,
      14: 20,
      15: 20,
      16: 25,
    };
    return table[order] ?? 0;
  }
}
