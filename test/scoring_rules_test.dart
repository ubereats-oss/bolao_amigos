import 'package:bolao_copa/services/scoring_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScoringRules.matchPoints', () {
    test('returns 13 for exact score', () {
      expect(
        ScoringRules.matchPoints(
          officialHomeGoals: 2,
          officialAwayGoals: 1,
          predictedHomeGoals: 2,
          predictedAwayGoals: 1,
        ),
        13,
      );
    });

    test('returns 6 for correct winner only', () {
      expect(
        ScoringRules.matchPoints(
          officialHomeGoals: 3,
          officialAwayGoals: 1,
          predictedHomeGoals: 2,
          predictedAwayGoals: 0,
        ),
        6,
      );
    });

    test('returns 2 for one exact team score with wrong result', () {
      expect(
        ScoringRules.matchPoints(
          officialHomeGoals: 1,
          officialAwayGoals: 2,
          predictedHomeGoals: 1,
          predictedAwayGoals: 0,
        ),
        2,
      );
    });

    test('returns 0 when no scoring rule matches', () {
      expect(
        ScoringRules.matchPoints(
          officialHomeGoals: 0,
          officialAwayGoals: 2,
          predictedHomeGoals: 3,
          predictedAwayGoals: 1,
        ),
        0,
      );
    });
  });

  group('ScoringRules.extraPoints', () {
    test('scores normalized single answer', () {
      expect(
        ScoringRules.extraPoints(
          order: 1,
          answer: ' Brasil ',
          correct: 'brasil',
        ),
        7,
      );
    });

    test('scores list answers by intersection', () {
      expect(
        ScoringRules.extraPoints(
          order: 5,
          answer: 'bra, arg, fra',
          correct: 'arg, esp, bra',
        ),
        30,
      );
    });
  });
}
