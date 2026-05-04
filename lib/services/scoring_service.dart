import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/match.dart';
import '../data/models/prediction.dart';
import '../data/models/extra_prediction.dart';
import '../data/models/extra_question.dart';
import '../data/repositories/group_repository.dart';
import '../data/repositories/match_repository.dart';

class ScoringService {
  final _matchRepo = MatchRepository();
  final _groupRepo = GroupRepository();
  final _db = FirebaseFirestore.instance;

  Future<int> calcularPontos({
    required String groupId,
    required String userId,
    required String cupId,
  }) async {
    int total = 0;

    final matches = await _matchRepo.fetchGroupMatches(cupId);
    final finished = matches.where((m) => m.finished).toList();

    if (finished.isNotEmpty) {
      final predictions = await _groupRepo.fetchAllPredictions(groupId, userId);
      for (final match in finished) {
        final pred = predictions[match.id];
        if (pred != null) total += _calcMatchPoints(match, pred);
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
        if (pred != null) total += _calcExtraPoints(q, pred);
      }
    }

    return total;
  }

  int _calcMatchPoints(Match match, Prediction pred) {
    final oh = match.officialHomeGoals!;
    final oa = match.officialAwayGoals!;
    final ph = pred.homeGoals;
    final pa = pred.awayGoals;

    if (oh == ph && oa == pa) return 13;

    final officialSign = oh.compareTo(oa);
    final predSign = ph.compareTo(pa);
    if (officialSign == predSign) return 6;

    if (oh == ph || oa == pa) return 2;

    return 0;
  }

  int _calcExtraPoints(ExtraQuestion question, ExtraPrediction pred) {
    final correct = question.correctAnswer!;
    final answer = pred.answer;
    final order = question.order;

    if (order == 4 || order == 5 || order == 6) {
      return _calcListPoints(order, answer, correct);
    }

    if (answer.trim().toLowerCase() == correct.trim().toLowerCase()) {
      return _pointsForOrder(order);
    }
    return 0;
  }

  int _calcListPoints(int order, String answer, String correct) {
    final answerSet =
        answer.split(',').map((s) => s.trim().toLowerCase()).toSet();
    final correctSet =
        correct.split(',').map((s) => s.trim().toLowerCase()).toSet();
    final matches = answerSet.intersection(correctSet).length;
    return matches * _pointsForOrder(order);
  }

  int _pointsForOrder(int order) {
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
