import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/extra_question.dart';
import '../data/repositories/group_repository.dart';
import '../data/repositories/match_repository.dart';
import 'scoring_rules.dart';

class ScoringBreakdown {
  final int matchPoints;
  final int extraPoints;

  const ScoringBreakdown({
    required this.matchPoints,
    required this.extraPoints,
  });

  int get totalPoints => matchPoints + extraPoints;
}

class ScoringService {
  final _matchRepo = MatchRepository();
  final _groupRepo = GroupRepository();
  final _db = FirebaseFirestore.instance;

  Future<int> calcularPontos({
    required String groupId,
    required String userId,
    required String cupId,
  }) async {
    final breakdown = await calcularDetalhado(
      groupId: groupId,
      userId: userId,
      cupId: cupId,
    );
    return breakdown.totalPoints;
  }

  Future<ScoringBreakdown> calcularDetalhado({
    required String groupId,
    required String userId,
    required String cupId,
  }) async {
    int matchPoints = 0;
    int extraPoints = 0;

    final groupMatches = await _matchRepo.fetchGroupMatches(cupId);
    final finished = groupMatches
        .where((m) =>
            m.phase == 'group' &&
            m.finished &&
            m.officialHomeGoals != null &&
            m.officialAwayGoals != null)
        .toList();

    if (finished.isNotEmpty) {
      final predictions = await _groupRepo.fetchAllPredictions(groupId, userId);
      for (final match in finished) {
        final pred = predictions[match.id];
        if (pred == null) continue;
        matchPoints += _calcMatchPoints(
          match.officialHomeGoals!,
          match.officialAwayGoals!,
          pred.homeGoals,
          pred.awayGoals,
        );
      }
    }

    final questionsSnap = await _db
        .collection('cups')
        .doc(cupId)
        .collection('extra_questions')
        .orderBy('order')
        .get();

    final questions = questionsSnap.docs
        .map((d) => ExtraQuestion.fromFirestore(d.id, d.data()))
        .where((q) => q.correctAnswer != null && q.correctAnswer!.isNotEmpty)
        .toList();

    if (questions.isNotEmpty) {
      final extras = await _groupRepo.fetchAllExtraPredictions(groupId, userId);
      for (final q in questions) {
        final pred = extras[q.id];
        if (pred != null) {
          extraPoints += ScoringRules.extraPoints(
            order: q.order,
            answer: pred.answer,
            correct: q.correctAnswer!,
          );
        }
      }
    }

    return ScoringBreakdown(
      matchPoints: matchPoints,
      extraPoints: extraPoints,
    );
  }

  int _calcMatchPoints(int oh, int oa, int ph, int pa) =>
      ScoringRules.matchPoints(
        officialHomeGoals: oh,
        officialAwayGoals: oa,
        predictedHomeGoals: ph,
        predictedAwayGoals: pa,
      );
}
